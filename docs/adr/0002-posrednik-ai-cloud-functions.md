# ADR-0002: Pośrednik AI – Cloud Functions (callable), limity, brak cache, App Check

- Status: zatwierdzony (bramka G2, 2026-11-15; zatwierdził właściciel produktu)
- Data: 2026-11-15
- Autor (rola): architect
- Zadanie: P2-02 (pyt. 2, US-005, US-011, SEC-03, SEC-06; T1, T3, T4, T5, T6, T7)
- Odpowiedzi właściciela uwzględnione: Q2 (ścieżka testowa Google Play; do tego czasu sideload tylko dev, dane testowe, App Check wyłączony), Q3 (limit globalny 50/dobę), Q5 (doba = dzień kalendarzowy Europe/Warsaw), Q12 (slot nie wraca po anulowaniu, jeśli model już ruszył). Uwagi Security 2-1, 2-2, 2-5, 2-6, 2-7: „Aneks A" na końcu (część normatywna; w razie rozbieżności z treścią wyżej obowiązuje Aneks A).

## Kontekst
Właściciel wybrał pośrednika między aplikacją a modelem (pyt. 2). Pośrednik musi: ukryć poświadczenia AI, uwierzytelnić wywołanie, egzekwować limit 5 generowań/konto/dobę (N4) po stronie serwera, ograniczać rozmiar wejścia/wyjścia, walidować wejście i odpowiedź modelu (w tym godzinę pierwszego dnia, US-006), nie logować treści i nie zapisywać promptów (D6, D11).

## Rozważane opcje
| # | Opcja | Plusy | Minusy |
|---|---|---|---|
| 1 | **Cloud Functions 2. gen. `onCall` (callable)** | Weryfikacja tokenu ID i App Check wbudowana w protokół; SDK `cloud_functions` w Flutterze; skalowanie do zera (koszt ~0 w teście); emulator lokalny; ta sama chmura i region | Zimny start (1–3 s); limit czasu 1 żądania (ustawiamy 120 s) |
| 2 | Cloud Functions `onRequest` (HTTP) | Pełna kontrola protokołu | Ręczna weryfikacja tokenu i App Check; więcej kodu = więcej błędów |
| 3 | Własny serwis w Cloud Run (kontener) | Elastyczność | Ciężar utrzymania, brak korzyści w MVP |
| 4 | Bez pośrednika (Firebase AI Logic) | Mniej kodu | Sprzeczne z decyzją właściciela; brak serwerowych limitów i walidacji |

## Decyzja
**Opcja 1: Cloud Functions 2. gen. (Node.js LTS, TypeScript), region `europe-west4`** (jak Vertex AI i Firestore, ADR-0003). Funkcje:

| Funkcja | Cel | Dostęp |
|---|---|---|
| `generatePlan` | Walidacja → limit → wywołanie modelu → walidacja odpowiedzi → zwrot planu | uwierzytelniony + App Check |
| `recordConsent` | Zapis minimalnego dowodu zgody (S3) | uwierzytelniony + App Check |
| `deleteAccount` | Usunięcie danych serwerowych i konta Auth (ADR-0004) | uwierzytelniony, świeże logowanie |
| `budgetGuard` | Wyłącznik kosztowy: Pub/Sub z budżetu → `aiEnabled=false` | wyzwalacz Pub/Sub, bez dostępu publicznego |

Kontrakt: `docs/api/posrednik-api.md`.

### Uwierzytelnianie i App Check
- Callable automatycznie weryfikuje token ID Firebase; funkcja dodatkowo wymaga `auth.token.firebase.sign_in_provider == "google.com"` (MVP, pyt. 8). Brak tokenu = odrzucenie (US-011).
- `enforceAppCheck` włączone (Play Integrity) w prod; `generatePlan` używa tokenów jednorazowych (`consumeAppCheckToken`) przeciw replay. W dev: dostawca debug. **Ryzyko:** instalacja APK spoza Google Play nie przejdzie atestacji Play Integrity – patrz „Konsekwencje".
- Parametr `ENFORCE_APP_CHECK` (per środowisko) umożliwia tryb monitorowania na czas pierwszych testów. **Ograniczony regułą sprzężenia z `ALLOW_REAL_DATA` (Aneks A, pkt 3).** Zgodnie z Q2: docelowo wewnętrzna ścieżka testowa Google Play (konto Play organizacji); do czasu jej dostępności sideload wyłącznie flavor `dev`, projekt `dev`, dane syntetyczne, App Check debug/wyłączony.

### Limity i bezpieczniki (wartości w `config/runtime`, zmieniane bez wdrożenia)
| Mechanizm | Wartość startowa | Uwagi |
|---|---|---|
| Limit na konto | 5 generowań na dobę (N4) | „Doba" = dzień kalendarzowy w strefie `Europe/Warsaw`; odnowienie o 00:00 (komunikat zawiera `resetAt`). Potwierdzone przez właściciela (Q5) |
| Limit globalny | 50 generowań na dobę (test; Q3 zatwierdzone) | Bezpiecznik kosztowy (T3); po przekroczeniu `ai_unavailable`; alert na wyczerpanie (Aneks A, pkt 5) |
| Wyłącznik | `aiEnabled` | Zmieniany ręcznie lub przez `budgetGuard` |
| Limit instancji | `maxInstances` = 10, 512 MiB, timeout 120 s | Ogranicza współbieżne koszty |
| Wejście | pola wg `docs/api/`: cel i nocleg ≤ 80 zn., lotnisko ≤ 60 zn., ≤ 5 zainteresowań z listy, dni 1–14; całe żądanie ≤ 4 KB | Kontrola tokenów wejściowych |
| Wyjście | `maxOutputTokens` 10 000, ≤ 7 punktów/dzień | Kontrola kosztu |
| Próby | maks. 2 wywołania modelu na 1 generowanie (1 ponowienie przy złym schemacie/języku/godzinach); limit czasu 45 s na próbę | US-005, R3 |

Rezerwacja limitu: transakcja Firestore (`usage/{uid}`, `usage_global/{dzień}`) **przed** wywołaniem modelu. Gdy generowanie kończy się błędem po stronie systemu (model niedostępny, odpowiedź niepoprawna po 2 próbach), slot jest zwracany. Anulowanie przez użytkownika po starcie wywołania **nie** zwraca slotu (koszt już poniesiony). Ponowna próba po zerwaniu sieci to nowe generowanie. Zachowanie zgodne z US-011; potwierdzone przez właściciela (Q12). Doprecyzowanie dla US-011 (Analityk): „po anulowaniu nic nie zapisano lokalnie, ale slot limitu mógł zostać zużyty".

### Cache
**Brak cache odpowiedzi AI po stronie serwera w MVP.** Powody: plany są wysoce spersonalizowane (niski współczynnik trafień), cache wymagałby zapisu treści promptów/odpowiedzi, co jest sprzeczne z rejestrem (D6: brak zapisu po naszej stronie) i zwiększałoby powierzchnię RODO. Redukcja kosztu: limity, krótki prompt, mały wynik, brak „myślenia". Lokalnie plany są zapisane (US-008), więc ponowne otwarcie nie kosztuje. Do rozważenia w przyszłości: cache klucza „cel+język" dla danych niewrażliwych (osobny ADR).

### Przetwarzanie żądania (kolejność)
1. Token + App Check (+ **sprawdzenie istnienia użytkownika** w funkcjach zapisujących, Aneks A pkt 1) → 2. Schemat i zbiory wartości (odrzucenie wartości spoza zbioru, T4) → 3. Zgoda AI (ostatni rekord `ai_processing` = `granted`, wersja bieżąca) → 4. `aiEnabled` i `ALLOW_REAL_DATA` (patrz niżej) → 5. Rezerwacja limitu → 6. Budowa promptu: instrukcje w `systemInstruction`, dane użytkownika jako wartości JSON w osobnej turze, oznaczone jako dane → 7. Wywołanie modelu (Vertex, konto usługi) → 8. Walidacja wyniku (schemat; liczba dni; punkty/dzień wg tempa; godziny rosnące; **pierwszy dzień nie wcześniej niż przylot + bufor 3 h lot / 0 auto, N6**; język odpowiedzi heurystyką słów funkcyjnych PL/EN; odrzucenie URL-i i znaczników; długości pól) → 9. Ewentualne 1 ponowienie → 10. Zwrot planu + `remainingToday`, `resetAt`.

`ALLOW_REAL_DATA` (parametr, domyślnie `false` w prod do czasu SEC-15): gdy `false`, pośrednik przyjmuje tylko żądania z flagą `testData=true` od kont na liście testowej (`config/runtime.testUids`, UID kont właściciela). Realizuje warunek S5 technicznie.

### Logowanie (T7, S7)
Wspólny wrapper loggera z listą dozwolonych pól: znacznik czasu, nazwa funkcji, `uidHash` (HMAC-SHA256 z tajemnicą w Secret Manager), kod wyniku, czas trwania, liczba prób, liczba dni, rozmiar żądania w bajtach. **Zakaz** logowania treści pól, promptów, odpowiedzi, tokenów, e-maila, współrzędnych. Reguła lint/test zabraniająca `console.log` poza wrapperem. Logi trafiają do kubełka w UE z retencją 30 dni (ADR-0003).

### Tożsamości (IAM, najmniejsze uprawnienia)
**Cztery konta usług, po jednym na funkcję** (Aneks A pkt 6 zastępuje pierwotny podział na dwa): `fn-ai`, `fn-consent`, `fn-account`, `fn-budget`. Brak kluczy JSON; wdrożenia z CI przez Workload Identity Federation (Steward).

## Konsekwencje
**Pozytywne:** brak sekretu AI w aplikacji i repozytorium (T1); limity i walidacja po stronie serwera (T3–T5); koszt stały ≈ 0 przy małym ruchu.
**Negatywne / ryzyka:** (1) opóźnienie i zimny start; (2) **Play Integrity a testy z APK spoza Play** – tester z sideloadowanym APK dostanie `app_check_failed`; rozwiązania: wewnętrzna ścieżka testowa Google Play (wymaga konta Play organizacji, formalności właściciela) albo okresowo `ENFORCE_APP_CHECK=false` na dev (T3 osłabione, limity per konto nadal działają) – decyzja właściciela; (3) transakcja limitu to jedyny zapis na żądanie (Firestore; koszt pomijalny); (4) budżet GCP nie jest twardym limitem (powiadomienia z opóźnieniem) – dlatego bezpieczniki wielowarstwowe.
**Koszt:** Cloud Functions ≈ 0 w darmowej puli (2 mln wywołań/mies.); koszt modelu – ADR-0001. Rozmiar wejścia ≤ 4 KB utrzymuje wejście ok. 1 000 tokenów.
**Dane osobowe:** pośrednik przetwarza D6 tylko w pamięci w trakcie żądania; zapisuje wyłącznie D3 (zgody) i D10 (licznik); logi D11 bez treści.

## Aneks A (2026-11-15, przy zatwierdzeniu): wymagania z przeglądu Security
Źródło: `docs/security/przeglad-adr.md` (Z-1 = 2-1, Z-2 = 2-2, Z-3 = 2-6 oraz 2-4, 2-5, 2-7). Aneks zostaje włączony do decyzji w momencie zatwierdzenia ADR (G2); późniejsze zmiany tylko nowym ADR.

1. **Istnienie użytkownika po usunięciu konta (T24).** Token ID pozostaje ważny do ok. 1 h po `deleteUser`. Funkcje zapisujące (`recordConsent`, `generatePlan`) przed jakimkolwiek zapisem weryfikują token z `checkRevoked` (`verifyIdToken(token, true)` na surowym tokenie z nagłówka żądania; alternatywnie odczyt użytkownika Admin SDK po UID). Użytkownik nieistniejący lub z unieważnionymi tokenami → `unauthenticated`, **bez zapisu jakiegokolwiek dokumentu**. Dodatkowo `deleteAccount` po usunięciu użytkownika Auth wykonuje **drugie, kontrolne** `recursiveDelete(users/{uid})` i `delete(usage/{uid})` (domyka wyścig z żądaniem w locie). Odrzucone: znacznik „usunięte" z TTL (dodatkowy dokument z UID, większa złożoność). Koszt: jedno wywołanie Admin API na żądanie (pomijalny). Test E2E (SEC-07) rozszerzony: wywołanie `recordConsent` i `generatePlan` ze starym tokenem po usunięciu nie tworzy dokumentów w `users/{uid}` ani `usage/{uid}`.
2. **Globalny handler wyjątków i logi poza wrapperem (T25).** Każda funkcja jest opakowana wspólnym handlerem: przechwytuje wszystkie wyjątki (także z walidatora schematu i SDK Vertex), loguje wyłącznie **kod i klasę błędu** (nigdy `error.message`, stosu ani obiektów odpowiedzi/żądania), zwraca klientowi `internal`. Walidator zwraca ścieżki pól bez wartości. Zakaz `console.*` i `functions.logger` poza wrapperem (lint + test). Test: żądanie z ciągiem kontrolnym w polach tekstowych (poprawne i niepoprawne, wywołujące błędy walidacji i atrapy modelu rzucającej wyjątek) – przeszukanie logów emulatora i projektu `dev` nie znajduje ciągu. Logi platformy (adres IP, user agent, czas) są poza wrapperem – opisane w polityce (D11). Sprawdzenie, czy Error Reporting kopiuje komunikaty poza kubełek UE: SEC-10; do czasu potwierdzenia Error Reporting nie jest włączane do analizy treści.
3. **Reguła sprzężenia `ENFORCE_APP_CHECK` i `ALLOW_REAL_DATA` (T27).** `ENFORCE_APP_CHECK=false` jest dozwolone tylko: (a) w `dev` z danymi syntetycznymi albo (b) w `prod` przy `ALLOW_REAL_DATA=false`. Egzekwowanie: (i) start funkcji w `prod` z `ENFORCE_APP_CHECK=false` i `allowRealData=true` kończy się odmową (błąd inicjalizacji); (ii) ponieważ `allowRealData` jest w `config/runtime` i może się zmienić bez wdrożenia, każde żądanie `generatePlan` w `prod` sprawdza tę parę i przy sprzecznej konfiguracji działa fail-closed (`test_data_only`); (iii) test jednostkowy obu ścieżek. Procedura przełączenia `allowRealData`: Aneks A ADR-0001.
4. **Wycofanie zgody AI (2-4, T30).** Wycofanie wymaga połączenia: aplikacja najpierw zapisuje `recordConsent(granted=false)` i dopiero po potwierdzeniu serwera pokazuje stan „wycofano" (lokalnie blokada generowania działa od razu); bez sieci aplikacja informuje, że wycofanie zostanie zakończone po odzyskaniu połączenia, a generowanie pozostaje zablokowane lokalnie. Tekst zgody mówi, że wycofanie działa od momentu zapisu.
5. **Limit globalny (2-5, T26, SEC-09).** (a) W fazie testów limit niski i parametryzowany (50/dobę, Q3). (b) **Przed wydaniem publicznym obowiązkowy przegląd** limitów: limit per UID i próg globalny skalowany do budżetu; rozważenie ograniczeń dla „nowych kont" lub zaproszeń – decyzja właściciela. (c) Alert (e-mail właściciela) przy wyczerpaniu limitu globalnego w dobie (sygnał ataku/DoS uczciwych użytkowników). (d) Koszt pułapu przy cenach niezweryfikowanych – `costs.md` sekcja 4.
6. **Role kont usług (2-7, T28) – zastępuje podział na dwa konta.** Konto per funkcja, brak kluczy JSON, WIF dla CI:

   | Konto | Funkcja | Uprawnienia (minimum) |
   |---|---|---|
   | `fn-ai` | `generatePlan` | `roles/aiplatform.user`; Firestore: odczyt `config`, odczyt zgód, zapis `usage`, `usage_global`; odczyt użytkownika Auth (sprawdzenie istnienia); sekret `uidHash` |
   | `fn-consent` | `recordConsent` | Firestore: zapis wyłącznie `users/{uid}/consents`; odczyt użytkownika Auth; sekret `uidHash` |
   | `fn-account` | `deleteAccount` | Firestore: usuwanie `users/{uid}`, `usage/{uid}`; usuwanie użytkowników Auth; sekret `uidHash` |
   | `fn-budget` | `budgetGuard` | Firestore: zapis `config/runtime.aiEnabled`; **bez dostępu do Auth** |

   Dokładne role IAM (predefiniowane lub niestandardowe) – zadanie P3-03; Firestore nie rozróżnia kolekcji w IAM, więc granularność wynika z podziału kodu i testu przeglądu uprawnień; do rozważenia role niestandardowe. Pieprz `uidHash` jest wspólny dla logów i **nie jest** używany do ewentualnego archiwum zgód (Q9, 2-3); rotacja przy podejrzeniu wycieku.
7. **Pozostałe uwagi Security:** `testUids` w `config/runtime` to dane osobowe właściciela – dostęp do konsoli tylko właściciel z 2FA (2-8); flaga `testData` nie jest zabezpieczeniem samym w sobie (2-9); test kodowania procentowego nazw w linku Maps i odrzucania sekwencji markdown-linków w odpowiedzi modelu (2-10, SEC-06).

## Odnośniki późniejsze (dopisane, treść ADR bez zmian)
- **2026-11-18 – ADR-0014 (proponowany):** konto usługi `fn-ai` → **`fn-ai-plan`** (Google wymaga ID konta 6–30 znaków; konto utworzone w P3-03 pod tą nazwą). Po zatwierdzeniu ADR-0014 nazwa `fn-ai-plan` obowiązuje zamiast `fn-ai` w sekcji „Tożsamości (IAM)" i w Aneksie A pkt 6; role bez zmian. Pytanie O2.
