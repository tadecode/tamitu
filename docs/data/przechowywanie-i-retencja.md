# Zasady przechowywania, retencji i usuwania danych – Tamitu (MVP)

Stan: 2026-11-18, wersja 0.3 (O4-b: retencja licznika D10 skrócona do ok. 3 dni od ostatniego użycia; uzasadnienie: `docs/security/personal-data-register.md`, sekcja „Retencja licznika użycia (D10, O4-b)”); wcześniej 0.2 (2026-11-15, po G2; ADR zatwierdzone), autor: architect (przegląd Security: `docs/security/przeglad-adr.md`). Źródła: `docs/security/personal-data-register.md` (0.2), `privacy-checklist.md` pkt 5–6, ADR-0003/0004/0005. Okresy oznaczone [PRAWNIK] czekają na poradę.

## 1. Retencja i miejsce
| Dane (rejestr) | Miejsce | Retencja | Usunięcie |
|---|---|---|---|
| Konto Auth (D1) | Firebase Auth (lokalizacja do weryfikacji, SEC-10) | do usunięcia konta | `deleteAccount` → Admin SDK `deleteUser` |
| Sesja/tokeny (D2) | urządzenie (SDK Firebase) | do wylogowania/usunięcia konta | `signOut`, usunięcie konta |
| Zgody (D3) | baza lokalna konta + Firestore (UE) | do usunięcia konta; dowód zgód usuwany z kontem (Q9; [PRAWNIK] do potwierdzenia) | `deleteAccount` (rekurencyjnie `users/{uid}`); lokalnie z plikiem bazy |
| Dane podróży, plany, preferencje, język (D4, D5, D9, D15, D16) | tylko baza lokalna konta (szyfrowana) | do usunięcia planu/konta/odinstalowania | usunięcie planu (kaskada) lub pliku bazy |
| Dane do AI (D6) | pamięć pośrednika w trakcie żądania; Vertex AI wg warunków dostawcy | po naszej stronie 0 | – (warunki dostawcy: SEC-15) |
| Lokalizacja | nie przetwarzana przez aplikację (ADR-0017; D7 do usunięcia z rejestru – security) | – | – |
| Nazwy w linku Maps (D8) | generowane na urządzeniu | 0 (link nie zapisywany ze współrzędnymi) | – |
| Licznik użycia (D10) | Firestore `usage/{uid}` | bieżąca doba; TTL do ok. 3 dni od ostatniego użycia + do ok. 24 h opóźnienia TTL (polityka TTL na polu `expireAt` = `max(resetAt(now) + 2 d, now + 2 d)`, `resetAt` = koniec doby Europe/Warsaw; decyzja O4 i O4-b – skrócenie z 30 dni zatwierdzone przez właściciela 2026-11-18; `model-danych.md` pkt 3) | `deleteAccount`; TTL |
| Logi (D11) | Cloud Logging, kubełek UE | 30 dni, bez treści, UID jako HMAC | wygasają automatycznie (do 30 dni po usunięciu konta – opisać w polityce) |
| Dane diagnostyczne (D12) | nie używane | – | – |
| Kontakt/wnioski (D14) | skrzynka tamitu@tadecode.pl | wg [PRAWNIK] | ręcznie |

## 2. Kolejność i zakres usunięcia konta (US-010, T14)
1. Aplikacja: komunikat o nieodwracalności, potwierdzenie, sprawdzenie sieci, znacznik „w toku".
2. `deleteAccount`: weryfikacja świeżego logowania (≤ 5 min) → `recursiveDelete(users/{uid})` → `delete(usage/{uid})` → `deleteUser(uid)` → **kontrolne powtórne** usunięcie `users/{uid}` i `usage/{uid}` (wyścig z żądaniem w locie). Funkcje zapisujące sprawdzają istnienie użytkownika, więc stary token (ważny do ok. 1 h) nie odtworzy danych (ADR-0002, Aneks A pkt 1).
3. Aplikacja: usunięcie pliku bazy konta (plany, preferencje, zgody lokalne), ustawień konta, znacznika; `signOut`. Klucz bazy (jeden na instalację) pozostaje, jeśli istnieją bazy innych kont; usuwany, gdy nie ma żadnej. **To usunięcie pliku, nie „crypto-shredding"** (ADR-0005, Aneks A pkt 1). Utrata klucza → stary plik jest usuwany (pkt 2 Aneksu).
4. Poza naszą kontrolą: logi (30 dni), konto Google użytkownika (nie dotykamy), Google Maps/Play (odrębni administratorzy).
5. Brak kopii zapasowych: Firestore bez PITR i kopii zaplanowanych; Android `allowBackup=false`. Jeśli kopie zostaną kiedyś włączone – aktualizacja tego dokumentu i polityki.

Test E2E (SEC-07): utwórz konto → zapisz zgody i wygeneruj plan (dane testowe) → usuń konto → sprawdź: brak użytkownika Auth, brak dokumentów `users/{uid}` i `usage/{uid}`, brak pliku bazy → **wywołaj `recordConsent` i `generatePlan` starym tokenem: odrzucone, brak nowych dokumentów** → zaloguj ponownie = nowy UID, pusta lista planów. Dodatkowo: utrata klucza bazy → stary plik skasowany; tymczasowy wpis zgody w `shared_preferences` usunięty po `recordConsent`.

## 3. Zasady dla deweloperów
- Nowe dane osobowe lub nowe miejsce zapisu = wpis w rejestrze (Security) i aktualizacja tego dokumentu, zanim trafią do kodu.
- Zakaz: logowania wartości pól, preferencji, promptów, odpowiedzi AI, tokenów, e-maila, współrzędnych (też debug); zapisu lokalizacji; wysyłania UID/e-maila/numeru lotu do AI.
- Dane testowe tylko syntetyczne w `dev`; w `prod` do czasu SEC-15 wyłącznie konta testowe właściciela (`ALLOW_REAL_DATA=false`). `ENFORCE_APP_CHECK=false` w prod tylko przy `ALLOW_REAL_DATA=false` (ADR-0002, Aneks A pkt 3).
- Logi: zakaz logowania `error.message`/stosu z danymi; test z ciągiem kontrolnym (ADR-0002, Aneks A pkt 2); konfiguracja sink/exclusion z testem odbioru (ADR-0003, Aneks A pkt 1).
- Zmiana architektury danych (np. plany w chmurze, F4) wymaga nowego ADR zastępującego ADR-0005 i aktualizacji D4, D5, D9, reguł Firestore i procedury usunięcia.
- Dostęp do danych na wniosek (N7/S9): procedura właściciela; po stronie chmury odnajdywanie danych po UID w Firestore i Auth (konsola) – brak eksportu w aplikacji.
