# Weryfikacja QA: P3-04, runda 2 (PR tadecode/tamitu#61)

- Autor (rola): qa · Data: 2026-11-17 · Wersja: 1.0
- Przedmiot: PR #61 `feat/P3-04` „fix(P3-04): trwały zapis zgód (SQLCipher), App Check, BUG-1..6 (po #57, #58, #59)", head `b49f53f`
- Norma: plan testów `docs/qa/test-plan-p3-04.md` (109 przypadków), poprzednia weryfikacja `docs/qa/verify-p3-04.md` (runda 1, PR #57, werdykt: odrzucone)
- Sposób: przegląd kodu i testów PR (`git fetch origin pull/61/head:pr-61`, diff względem `origin/main`), uruchomienie testów bez urządzenia w osobnym, odłączonym worktree (`tamitu-wt/qa-PR-61-code`). Kod aplikacji nie był zmieniany.

## 1. Wynik testów

| Zestaw | Polecenie | Wynik |
|---|---|---|
| Analiza statyczna | `flutter analyze` | brak uwag |
| Flutter (U, W) | `flutter test` | **121 / 121 zielone** (runda 1: 94) |
| Backend (UB) | `npx vitest run` (`backend/functions`) | **117 / 117 zielone**, 6 plików (runda 1: 107) |
| CI PR #61 (head `b49f53f`) | GitHub Actions | `backend`, `conventions`, `farm-guards` – zielone; **`secrets` – czerwone** (N-1); `flutter` – w toku w chwili weryfikacji |
| Integracyjne (I), emulatory Firebase | – | **nie uruchomiono:** brak `integration_test/` i skryptu emulatora w PR; na maszynie brak Firebase CLI i Javy |
| Ręczne (M) na emulatorze Androida | – | **nie uruchomiono:** na maszynie brak skonfigurowanego AVD (`flutter emulators` – pusto), brak `adb` i `emulator` w `PATH`. Nie było czego uruchomić przez `.farm/test-lock.ps1 -Resource device`, więc test nie był rozpoczynany. |
| Testy eksploracyjne QA (własne, poza PR) | – | **nie wykonano:** hook farmy (`guard-paths.ps1`) zablokował zapis pliku testu w worktree z kodem PR (ścieżka poza projektem). Blokady nie obchodzono; wnioski oparte na testach PR i przeglądzie kodu. |

## 2. Potwierdzenie poprawek BUG-1..BUG-6

| Błąd | Status | Dowód |
|---|---|---|
| BUG-1 (poważny) – zgody tylko w pamięci, blokada startu offline | **naprawiony** | `consents_local` w zaszyfrowanej bazie konta (`lib/core/db/account_database.dart`, `account_databases.dart`, `SqliteConsentLocalStore`; Drift + SQLCipher, plik `tamitu_<sha256(uid)[0..16]>.db`, klucz 256 bit w `flutter_secure_storage`). `bootstrap.dart` używa `SqliteConsentLocalStore`, atrapa pamięciowa przeniesiona do `test/fakes/`. Testy: `restart_test` „BUG-1: after a restart OFFLINE with a stored acceptance -> EK-04 (US-001 AC4), and no new privacy_policy record is created" – nowy proces (nowe uchwyty bazy, serwis, kontroler) na tym samym katalogu i kluczu, serwer offline → `SessionReady`, na serwerze 1 rekord, 1 wywołanie; `account_database_test` – zapis w jednej instancji, odczyt w drugiej, plik zaszyfrowany (nagłówek ≠ `SQLite format 3`). |
| BUG-1 – brak nowego rekordu przy każdym restarcie | **naprawiony** | Start (`onSessionStart`) tylko przejmuje wpis tymczasowy, nie tworzy rekordu; przejęcie pomija `consentId` już zapisany (test „adopt never duplicates or overwrites…"). Test restartu sprawdza jeden restart; z kodu wynika, że kolejne restarty zachowują się tak samo (nie ma ścieżki tworzącej rekord poza EK-02/EK-03/EK-06). |
| BUG-2 (średni) – niewysłana zgoda nie jest dosyłana po restarcie | **naprawiony** | `onSessionStart` → `adoptStagedPolicy` przy każdym starcie, potem `syncPending` w tle. Testy: „BUG-2: sync failed, app killed -> next start with network sends it once and clears the staged entry" (ten sam `consentId`, `lang`; wpis tymczasowy usunięty), „BUG-2: killed between Google sign-in and adoption -> adopted at next start", „sign-out drops a staged entry: it never reaches the next account (QA5)" (rekord u1 zostaje w bazie u1 i jest dosłany przy jego kolejnym starcie). |
| BUG-3 (średni) – błąd sieci `google_sign_in` jako błąd ogólny | **naprawiony w kodzie, do potwierdzenia na urządzeniu** | `classifyGoogleSignInError`: `interrupted` i `unknownError` z opisem zawierającym „network/offline/internet" → `offline`. Test `google_sign_in_errors_test`. Heurystyka po opisie – rzeczywisty kod/opis z Credential Manager przy braku sieci trzeba potwierdzić na urządzeniu (SIGN-13). |
| BUG-4 (drobny) – `unsupported_version` w EK-03 | **naprawiony** | `UpdateAppView` (CMP-18, „Zaktualizuj aplikację" → Google Play) w EK-03 (z „Wyloguj", QA9) i EK-06. Testy: `reconsent_screen_test` „BUG-4…" (otwiera `AppConstants.playStoreUrl`, „Sign out" dostępne), `ai_consent_screen_test` „BUG-4… nothing stored". |
| BUG-5 (drobny) – komunikat w EK-02 nad polem zgody | **naprawiony** | `welcome_screen.dart`: `Notice` przeniesiony do sekcji dolnej, bezpośrednio nad przyciskiem. Test „BUG-5: the notice sits directly above the sign-in button". |
| BUG-6 (drobny) – zły odnośnik w komentarzu | **naprawiony** | `app_constants.dart` wskazuje `test/guards_test.dart`. |

Dodatkowo (spoza listy QA, z przeglądu PR #57): App Check aktywowany przed pierwszym wywołaniem callable (`environment_test`), atrapy backendu tylko w buildzie `dev` nie-release (`environment_test`), jedna synchronizacja w locie na konto (`consent_service_sync_test`), `idTokenChanges().distinct()`, nowe stany EK-01: utrata klucza → EK-03 „dane wyczyszczone", inny błąd otwarcia bazy → CMP-18 z ponowieniem (`gate_screen_test`, `restart_test`).

## 3. Macierz pokrycia planu (zmiany względem rundy 1)

Legenda jak w rundzie 1: **P** – pokryty testem automatycznym; **C** – częściowo; **B** – brak; **R** – ręczny, nie wykonany; **F** – wymaga projektu Firebase (P3-03); **N** – nie dotyczy P3-04. Wiersze niewymienione – bez zmian względem `verify-p3-04.md` sekcja 2.

| ID | Runda 1 | Runda 2 | Test w PR #61 / uwaga |
|---|---|---|---|
| GATE-02 | P | P | wzmocnione: „BUG-1: after a restart OFFLINE…" – także po restarcie procesu |
| GATE-04 | C | C | bez zmian: brak testu `privacy-v10` vs `privacy-v9` (logika `versionNumber` poprawna) |
| GATE-05 | C | **P** | „BUG-2: sync failed, app killed -> next start with network sends it once…" |
| GATE-07 | B | **C** | restart symulowany w teście U na prawdziwym SQLCipher (nowe uchwyty bazy, serwis, kontroler); brak testu I z emulatorem Auth i zabiciem procesu |
| GATE-08 | F | F | zachowanie pokryte testem U (BUG-1 offline); próba na urządzeniu z realnym logowaniem – P3-03 |
| CONS-01 | C | **P** | trwały `consents_local` (schemat v1 z `received_at`, `schema_meta`); „schema v1…", „upsert by id replaces…", „adopt -> local unsynced record; sync…" |
| CONS-03 | C | **P** | ponowienie po restarcie z tym samym `consentId`, `lang` (test BUG-2) |
| CONS-05 | B | **P** | „one sync in flight per account: concurrent callers share it", „EK-06 waits for the running sync…" |
| ERR-04 | C | **P** | `google_sign_in_errors_test` (z zastrzeżeniem z BUG-3: potwierdzenie na urządzeniu) |
| ERR-08 | C | **P** | `UpdateAppView`; test otwiera `AppConstants.playStoreUrl` |
| RECON-09 | C | **P** | `unauthenticated` → EK-02 + komunikat; `unsupported_version` → „Zaktualizuj aplikację", „Wyloguj" zostaje |
| SIGN-13 | C | C | klasyfikacja przetestowana; rzeczywisty błąd sieci Credential Manager do potwierdzenia na urządzeniu |
| RECON-03 | C | C | bez zmian: brak I; ścieżka „EK-03 → akceptacja → restart → bez EK-03" wynika z kodu, bez osobnego testu restartu |
| CONS-07 | B | B | bez zmian (QA6) |
| SES-04 | B | B | bez zmian (S18, QA8) |
| API-05..08, API-11 | C, C, B, C, B | bez zmian | mapowanie dokumentu wydzielone do czystych funkcji z testami (`consents.test.ts`), ale transakcje i reguły Firestore nadal bez emulatora |

### Podsumowanie

| Status | Runda 1 | Runda 2 |
|---|---|---|
| P – pokryty | 59 | **66** |
| C – częściowo | 22 | **17** |
| B – brak | 11 | **9** |
| R – ręczny, nie wykonany | 6 | 6 |
| F – wymaga Firebase (P3-03) | 5 | 5 |
| N – nie dotyczy P3-04 | 6 | 6 |
| **Razem** | 109 | 109 |

Pokrycie przypadków dotyczących P3-04 (103): **pełne 64% (66/103)** (runda 1: 57%), **pełne lub częściowe 81% (83/103)** (runda 1: 79%). Bez przypadków zależnych od Firebase (98): pełne 67%, z częściowymi 85%.

Pozostałe B (9): GATE-09, SIGN-07, SIGN-09, CONS-07, API-07, API-11, RECON-02, RECON-07, SES-04.

## 4. Nowe błędy i obserwacje

| ID | Waga | Opis | Kroki / dowód | Oczekiwane | Odwołanie |
|---|---|---|---|---|---|
| N-1 | **blokujący bramkę** (CI, nie aplikacja) | Kontrola `secrets` (gitleaks) czerwona na head `b49f53f`: reguła `generic-api-key` w `test/core/db/account_database_test.dart:10`, **commit `2357403`**. Literał klucza testowego usunięto w `408775e`, ale gitleaks skanuje historię gałęzi, więc kontrola pozostaje czerwona. | log zadania `secrets`, run 44082075764: „leaks found: 1", `Commit: 2357403e…` | zielone CI (kryterium „done" nr 2) – np. wpis odcisku w `.gitleaksignore` (fałszywy alarm: klucz testowy 0x00..0x1f) albo przepisanie historii gałęzi; decyzja mobile-dev/steward | plan sekcja 8 pkt 2; CLAUDE.md zasada 11 |
| N-2 | drobny (z przeglądu kodu, nie odtworzony testem) | Wylogowanie w trakcie trwającej synchronizacji: `onSignOut` → `closeAll()` czyści mapę otwartych baz, a rekord wracający z serwera zapisuje `_local.upsert(uid, …)` → `AccountDatabases.open(uid)` **otwiera bazę ponownie**. Baza poprzedniego konta zostaje otwarta po wylogowaniu, wbrew „zamknięcie bazy przy wylogowaniu" (ADR-0004, komentarz `closeAll`). Dane trafiają do właściwego konta, więc bez wycieku między kontami. | wolny `recordConsent` (np. `FakeConsentApi.gate`), wylogowanie przed odpowiedzią, potem sprawdzenie, że `AccountDatabases._open` znów zawiera uid | po wylogowaniu żadna baza konta nie jest otwarta (np. synchronizacja przerwana/zignorowana po `onSignOut` albo zamknięcie po jej zakończeniu) | ADR-0004, ADR-0005 pkt 1 |

Obserwacje (bez wagi błędu):
- O-1 (runda 1) rozwiązana: jedna synchronizacja w locie na konto.
- O-6: `SecureStorageDbKeyStore.read` traktuje **każdy** wyjątek odczytu jak utratę klucza i zapisuje nowy klucz; przy jednym kluczu na instalację oznacza to nieodwracalne wyczyszczenie baz wszystkich kont na urządzeniu także przy błędzie przejściowym. Zgodne z literą ADR-0005 Aneks A pkt 2 (unieważnienie Keystore), ale szerokie – do oceny przez security/architekta.
- O-7: wpis tymczasowy z przerwanego logowania (proces zabity przy otwartym oknie Google, sesja nie powstała) zostaje w `shared_preferences` do następnej próby logowania (nadpisywany przy niej). Bez danych osobowych (`consentId`, wersja, język, czas); nie może trafić na inne konto, bo każda próba zapisuje nowy wpis.
- O-8: rozmiar APK release prod arm64 +5,3 MB (`libsqlcipher.so`); alternatywa `sqlite3mc` – pytanie M8 do architekta (opis PR #61).
- O-2, O-3, O-4, O-5 z rundy 1 – bez zmian (QA7, QA12, QA8, QA2).

## 5. Werdykt

**Poprawki BUG-1..BUG-6: przyjęte** (BUG-3 – w kodzie, potwierdzenie na urządzeniu). Brak nowych błędów krytycznych i poważnych w kodzie aplikacji.

**P3-04 jako całość: odrzucone – niegotowe do `done`** (kryteria z sekcji 8 planu):
1. Kryterium 2 (CI zielone) – niespełnione: `secrets` czerwone (N-1). To jedyny punkt, który można usunąć bez nowego środowiska.
2. Kryterium 3 (testy I na emulatorach Firebase) – niespełnione: brak testów I w repozytorium oraz brak Firebase CLI i Javy na maszynie.
3. Kryterium 4 (lista M na emulatorze Androida) – niespełnione: brak AVD/adb na maszynie; test nie był uruchamiany.

To drugie odrzucenie P3-04 → **eskalacja do orkiestratora** (zasada roli qa). W obu rundach blokady w kodzie aplikacji zostały usunięte; obecne przeszkody to CI (N-1) i środowisko testowe (I, M). Orkiestrator/właściciel decyduje, czy:
- PR #61 wchodzi do `main` po naprawie N-1 i akceptacji reviewer, a P3-04 pozostaje w `review` do wykonania I i M; albo
- kryteria 3 i 4 zostają jawnie odłożone (np. do P3-03 / przygotowania maszyny z AVD, Javą i Firebase CLI) z zadaniem w backlogu.

Etykiety bramki (`qa:ok` / `qa:changes`, GH-008) – do czasu wdrożenia FARM-007 nadaje właściciel ręcznie; rekomendacja QA dla PR #61: `qa:changes` do czasu naprawy N-1; po zielonym CI – `qa:ok` dla zakresu poprawek, jeśli orkiestrator odłoży kryteria 3 i 4.

## 6. Do zrobienia przed rundą 3

- mobile-dev: N-1 (zielone `secrets`); N-2 (drobny – może być zadaniem w backlogu); opcjonalnie test GATE-04 (`v10` vs `v9`) i test „EK-03 → akceptacja → restart → EK-04" (RECON-03 na poziomie U).
- orkiestrator / właściciel: maszyna testowa z AVD (Android SDK, `adb`) oraz Javą i Firebase CLI (emulatory) – bez tego kryteria 3 i 4 nie są wykonalne; decyzja o odłożeniu.
- qa (po przygotowaniu środowiska): lista M z `verify-p3-04.md` sekcja 5 (`flutter run --flavor dev --dart-define=TAMITU_FAKE_BACKEND=true` przez `.farm/test-lock.ps1 -Resource device`), w tym powtórka GATE-07/GATE-08 (restart, tryb samolotowy) i SIGN-13 (BUG-3) na urządzeniu.
