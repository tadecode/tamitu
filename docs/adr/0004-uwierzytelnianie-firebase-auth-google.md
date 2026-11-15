# ADR-0004: Uwierzytelnianie – Firebase Auth (tylko Google), sesja, usuwanie konta

- Status: zatwierdzony (bramka G2, 2026-11-15; zatwierdził właściciel produktu)
- Data: 2026-11-15
- Autor (rola): architect
- Zadanie: P2-04 (US-001, US-002, US-010, pyt. 8, N9; T6, T14)
- Odpowiedzi właściciela uwzględnione: Q9 (dowód zgód usuwany razem z kontem; pytanie do prawnika [PRAWNIK] pozostaje otwarte – ewentualna zmiana wyłącznie nowym ADR). Uwagi Security 2-1/4-1, 4-2, 4-3: „Aneks A" na końcu.

## Kontekst
MVP: logowanie wyłącznie przez Google, brak haseł i trybu gościa, tylko dorośli. Później dojdą Facebook, Apple, Microsoft (poza MVP). Wymagane: zgody przed logowaniem (US-003), trwała sesja, wylogowanie, usunięcie konta w aplikacji z ponownym uwierzytelnieniem i bez pozostawiania danych (US-010).

## Rozważane opcje
| # | Opcja | Plusy | Minusy |
|---|---|---|---|
| 1 | **Firebase Auth + `google_sign_in` (Credential Manager)** | Natywny wybór konta, jeden token ID, gotowe odświeżanie, łatwe dodanie kolejnych dostawców | Wymaga odcisków SHA i identyfikatora klienta web na każde środowisko |
| 2 | Firebase Auth `signInWithProvider(GoogleAuthProvider)` (przeglądarka) | Mniej zależności | Gorszy UX (przekierowanie przez przeglądarkę) |
| 3 | Własny OAuth/OIDC + własny backend sesji | Pełna kontrola | Dużo kodu i ryzyka; sprzeczne z „najprościej" – **odrzucone** |
| 4 | Identity Platform / inny dostawca tożsamości | Więcej funkcji | Zbędne w MVP |

## Decyzja
**Opcja 1.** Szczegóły:
- **Zakresy:** tylko podstawowe uwierzytelnienie (bez dodatkowych zakresów OAuth). Aplikacja używa wyłącznie `uid`; e-mail i nazwa z SDK nie są zapisywane, logowane ani wyświetlane (D1). Uwaga: Firebase Auth przechowuje e-mail/nazwę konta po swojej stronie – nie do uniknięcia.
- **Kolejność ekranów:** ekran startowy z informacją o prywatności i zgodą na politykę (checkbox niezaznaczony, przycisk logowania nieaktywny do akceptacji; US-003) → logowanie Google → `recordConsent` (przesłanie zapisanej lokalnie zgody; ADR-0005) → ekran główny. Zgoda na AI jest osobna i pytana przy pierwszym generowaniu oraz w Ustawieniach (N5).
- **Sesja:** zarządza SDK (token ID ok. 1 h, odświeżanie w tle; token odświeżający w pamięci aplikacji na urządzeniu, D2). Aplikacja nie przechowuje tokenów własnoręcznie. Router reaguje na strumień `idTokenChanges` (zalogowany/niezalogowany). Aplikacja startuje zalogowana po restarcie (US-001).
- **Wylogowanie (US-002):** `GoogleSignIn.signOut()` + `FirebaseAuth.signOut()`, zamknięcie bazy lokalnej bieżącego konta; **plany zostają na urządzeniu** (N3) w pliku bazy przypisanym do konta (ADR-0005), niewidoczne po zalogowaniu innego.
- **Weryfikacja po stronie serwera:** każde wywołanie funkcji niesie token ID; dozwolony tylko `sign_in_provider == google.com`.
- **Usunięcie konta (US-010):** funkcja `deleteAccount` (callable):
  1. wymaga świeżego logowania: `auth_time` ≤ 5 min, inaczej błąd `reauth_required` → aplikacja prosi o ponowne logowanie Google i ponawia;
  2. usuwa rekursywnie `users/{uid}` (zgody) i `usage/{uid}` w Firestore, następnie użytkownika Auth (Admin SDK `deleteUser`), po czym wykonuje **kontrolne, powtórne usunięcie** tych dokumentów (Aneks A ADR-0002, pkt 1); operacja idempotentna, kolejność od danych do konta, aby błąd w środku dało się powtórzyć;
  3. aplikacja przed wywołaniem zapisuje znacznik „usuwanie w toku" (w bezpiecznym magazynie), po sukcesie kasuje lokalną bazę konta i dane lokalne, wylogowuje i wraca na ekran startowy; po przerwaniu (np. zabicie aplikacji) przy następnym starcie dokańcza lokalne czyszczenie;
  4. bez internetu: komunikat, brak częściowego usunięcia (US-010).
  Logi ze skrótem UID wygasają w 30 dni (S7). Dowód zgód po usunięciu konta: **usuwany razem z kontem (decyzja właściciela, Q9)**; jeśli prawnik zażąda przechowywania [PRAWNIK, S3], `deleteAccount` zapisze zapseudonimizowany rekord (HMAC UID) w osobnej kolekcji – zmiana w kolejnym ADR.
- **Ponowne logowanie tym samym kontem Google po usunięciu** tworzy nowego użytkownika (nowy UID), bez danych (US-010).
- **Rozszerzalność:** dodanie dostawców (Facebook/Apple/Microsoft) = konfiguracja Firebase + przyciski + zmiana dozwolonych `sign_in_provider` w funkcjach; wymaga aktualizacji rejestru (F6) i oceny (Apple obowiązkowe na iOS, R9).

## Konsekwencje
**Pozytywne:** brak haseł; mało własnego kodu; spójne z weryfikacją tokenu w pośredniku (T6).
**Negatywne:** zależność od Google/Firebase (R7); konfiguracja odcisków SHA-1/SHA-256 dla debug, klucza uploadu i klucza podpisu Google Play (App Signing) w obu środowiskach.
**Koszty:** Auth Google bezpłatnie do 50 tys. MAU; funkcja usuwania w puli bezpłatnej.
**Dane osobowe:** D1, D2; lokalizacja danych Auth do potwierdzenia (SEC-10, ADR-0003). Test E2E: usunięcie → ponowne logowanie = nowy użytkownik (SEC-07).

## Aneks A (2026-11-15, przy zatwierdzeniu)
1. **Stary token po usunięciu konta (2-1/4-1, T24).** Serwer sprawdza istnienie użytkownika przed zapisem i wykonuje kontrolne powtórne usunięcie – normatywnie w Aneksie A ADR-0002 (pkt 1). Aplikacja po sukcesie `deleteAccount` natychmiast kończy sesję lokalnie (`signOut`), więc legalny klient nie wysyła starego tokenu.
2. **Q9 / US-010 (4-2).** Domyślne usunięcie dowodu zgód z kontem jest zgodne z S3 („okres po usunięciu: [PRAWNIK]"). Tekst US-010 sugerujący zachowanie „minimalnego serwerowego dowodu zgód" wymaga uzgodnienia przez Analityka (architekt nie zmienia requirements). Jeśli prawnik zażąda archiwum, nowy ADR zastępujący ten punkt musi spełnić minimalne wymagania Security: osobna kolekcja zapisywana tylko przez `deleteAccount`; HMAC UID z osobnym pieprzem niż w logach; typ, wartość, wersja, język, znaczniki czasu; stały, krótki okres z TTL wskazany w polityce; brak dostępu klientów; informacja w ekranie usuwania konta; rozszerzony test E2E.
3. **Komunikat przy wylogowaniu (4-3, T9).** Wymaganie dla Analityka/UI: komunikat PL/EN „Twoje plany zostają na tym urządzeniu; usuń je w Ustawieniach lub usuń konto". Decyzja N3 bez zmian.
4. **Polityka prywatności (4-4).** Rekord `privacy_policy` jest dowodem zapoznania (obowiązek informacyjny, art. 13), nie zgodą w rozumieniu art. 6 ust. 1 lit. a; nazewnictwo techniczne bez zmian, sformułowanie w UI potwierdza [PRAWNIK] (SEC-14).
