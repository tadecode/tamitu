# Weryfikacja PR #77 (SEC-33, O4-1, QA13, OBS-1)

- Autor (rola): qa · Data: 2026-11-18 · Gałąź raportu: `docs/qa-PR-77`
- Kod: `origin/feat/SEC-33` @ `48d50e3` (PR #77 z dołączonym `main` @ `db1b8c1`), sprawdzany w osobnym worktree tylko do odczytu (`git worktree add --detach`), usuniętym po weryfikacji.
- Zakres: QA13 (przełącznik emulatorów Firebase w `dev` debug), SEC-33 (brak `google-services.json` = błąd buildu), O4-1 (TTL `usage` na `expireAt`), OBS-1 (poziom logów błędów z kontraktu). Pozostała część PR (porządki SEC-20, `FIREBASE.md`) – tylko pod kątem zgodności z tym, co testowane.
- Dane: wyłącznie syntetyczne (emulator Auth, projekty `demo-tamitu-qa` / `demo-tamitu`), `ALLOW_REAL_DATA=false`. `google-services.json` kopiowane z katalogu właściciela tylko na czas buildów prod/dev release, nieodczytywane, `git status` czysty, po buildach usunięte.

## 1. Środowisko

| Element | Stan |
|---|---|
| Flutter | 3.50.0 stable |
| Node (host) | 26.13.1 (`engines.node` = 22 – emulator Functions ostrzega i używa 26) |
| Firebase CLI | 15.36.0; Java emulatorów: JBR z Android Studio |
| Android SDK | build-tools 36.0.0 (`aapt2`), AVD `Medium_Phone_API_37.0` |
| Urządzenie / AVD | **brak** – `emulator -accel-check`: „Android Emulator hypervisor driver is not installed on this machine"; `adb devices` – pusta lista |

## 2. Testy automatyczne (bez urządzenia)

| Przypadek | Wynik | Dowód |
|---|---|---|
| T-1 `flutter analyze` | **zaliczony** | „No issues found!" |
| T-2 `dart format --set-exit-if-changed lib test` | **zaliczony** | „Formatted 61 files (0 changed)" |
| T-3 `flutter test` (w tym `test/app/firebase_emulators_test.dart`, `test/features/auth/emulator_auth_gateway_test.dart`) | **zaliczony** | „+136: All tests passed!" |
| T-4 `backend/functions`: `npm ci`, `lint`, `typecheck`, `build` | **zaliczony** | eslint i `tsc --noEmit` bez błędów, build OK |
| T-5 `backend/functions`: `npm test` (vitest, w tym `logger-severity.test.ts`) | **zaliczony** | „Tests 144 passed (144)" |

## 3. Buildy i zawartość APK (SEC-33, QA13 – izolacja wariantów)

Zawartość manifestu: `aapt2 dump xmltree --file AndroidManifest.xml <apk>`; zasoby: `unzip -l` + `aapt2 dump resources`.

| Przypadek | Polecenie | Wynik | Dowód |
|---|---|---|---|
| B-1 dev debug bez pliku, bez flagi | `flutter build apk --debug --flavor dev` | **zaliczony** (oczekiwany błąd) | exit 1 po 12 s: „File google-services.json is missing." |
| B-2 dev debug bez pliku, z flagą + emulatory | `… --debug --flavor dev -P tamitu.allowMissingGoogleServices=true --dart-define=TAMITU_USE_FIREBASE_EMULATORS=true` | **zaliczony** | `√ Built … app-dev-debug.apk`; manifest: `debuggable=true`, `usesCleartextTraffic=false`, `networkSecurityConfig=@0x7f120002` → `xml/network_security_config_emulators` (w APK `res/xml/network_security_config_emulators.xml`) |
| B-3 release z flagą | `flutter build apk --release --flavor prod -P tamitu.allowMissingGoogleServices=true` | **zaliczony** (oczekiwany błąd) | exit 1 po 8 s: „tamitu.allowMissingGoogleServices=true is allowed only for debug/profile builds; … (SEC-33)." |
| B-4 prod release (z plikiem) + `--dart-define` emulatorów | `flutter build apk --release --flavor prod --dart-define=TAMITU_USE_FIREBASE_EMULATORS=true` | **zaliczony** | APK 66,6 MB; manifest `pl.tadecode.tamitu`: `usesCleartextTraffic=false`, **brak** atrybutu `networkSecurityConfig`; `dump resources` – brak zasobu `network_security*` |
| B-5 dev release (z plikiem) + `--dart-define` | `… --release --flavor dev …` | **zaliczony** | manifest `pl.tadecode.tamitu.dev`: `usesCleartextTraffic=false`, brak `networkSecurityConfig`, brak zasobu `network_security*` |
| B-6 prod debug (z plikiem) + `--dart-define` | `… --debug --flavor prod …` | **zaliczony** | manifest: `debuggable=true`, `usesCleartextTraffic=false`, brak `networkSecurityConfig`; `res/xml/` bez `network_security_config_emulators.xml` |
| B-7 sprzątanie | `git status --porcelain` po buildach | **zaliczony** | pusty; pliki `google-services.json` usunięte z `android/app/src/{dev,prod}` |

**`--dart-define` w prod / release:** flaga nie jest „ignorowana", tylko **odrzucana** – `assertFirebaseEmulatorsAllowed` (wywołane w `bootstrap.dart` przed `connectFirebaseEmulators`) rzuca `StateError` dla `flavor != dev` lub `!kDebugMode` oraz przy jednoczesnym `TAMITU_FAKE_BACKEND`. Pokryte testami jednostkowymi (`emulator switch rules`, `bootstrap guards the switch before using it`). Zachowania w uruchomionej aplikacji (B-4/B-5/B-6 → ekran błędu startu) nie sprawdzono – brak urządzenia. Niezależnie od tego warstwa sieci jest zamknięta: w B-4..B-6 cleartext jest zablokowany, więc nawet obejście guardu nie połączyłoby się z `http://10.0.2.2`.

## 4. Aplikacja `dev` debug wobec emulatorów (QA13, kliencka część I z P3-04)

| Przypadek | Wynik | Dowód |
|---|---|---|
| D-1 Start AVD / urządzenie | **niewykonany – blokada środowiska** (bez zmian od P3-04 r3) | `emulator -accel-check`: brak sterownika hypervisora; `adb devices` pusta. Instalacja sterownika / WHPX to zmiana systemowa – tylko właściciel |
| D-2 Kliencka część I odłożona z P3-04 (`verify-p3-04-r3.md` sekcja 3): GATE-07, SIGN-11, RECON-03, AIC-04, CONS-10 (`synced=1`), SES-04 (klient), SES-06 | **niewykonane** | wymagają uruchomionej aplikacji (D-1) |
| D-3 Logowanie fałszywym tokenem Google w emulatorze Auth (mechanizm `EmulatorAuthGateway`) | **zaliczony (REST, bez aplikacji)** | `accounts:signInWithIdp` z tym samym kształtem tokenu (`sub`, `email@example.com`, `email_verified`) i `providerId=google.com` → `providerId: google.com`, powtórne logowanie tym samym `sub` → ten sam użytkownik (`isNewUser: false`). To ta sama ścieżka, którą wywołuje `signInWithCredential(GoogleAuthProvider.credential(idToken: …))` |
| D-4 Twierdzenie „`sub` = UID w emulatorze" | **niezgodne → BUG-1** | ta sama próba: `localId` ma 28 znaków i **≠** `qa-emulator-user` |
| D-5 Backend w emulatorach na kodzie PR (regresja P3-04 r3) | **zaliczony** | `.farm/test-lock.ps1 -Resource firebase-emulators`, `firebase emulators:exec --project demo-tamitu-qa --only auth,functions,firestore 'node --test … tests/firebase-emulator/p3-04-record-consent.int.mjs'` (`ENVIRONMENT=dev`, `ALLOW_REAL_DATA=false`, `ENFORCE_APP_CHECK=false`, losowy pieprz w ignorowanym `.secret.local`) → **15/15**, `emulators:exec exit 0` |
| D-6 Porty i host w aplikacji vs `backend/firebase.json` | **zaliczony (przegląd)** | Auth 9099, Functions 5001 = `firebase.json`; host domyślny `10.0.2.2`, dozwolone tylko `10.0.2.2`/`127.0.0.1`/`localhost` – te same co w `network_security_config_emulators.xml` (B-2) |

Uwaga do D-5: pierwszy przebieg (równolegle z buildami Gradle, CPU pod pełnym obciążeniem) zawiesił się na `API-06b` z „functions: Failed to start functions … Failed to load function" przy zimnym starcie kolejnych workerów; przerwany, porty sprawdzone jako wolne. Powtórka na nieobciążonej maszynie – 15/15 (`API-06b` 17,5 s). Ocena: środowisko (obciążenie + Node 26 zamiast 22), nie kod – OBS-3.

## 5. O4-1 – indeksy i TTL

| Przypadek | Wynik | Dowód |
|---|---|---|
| O4-1a Zgodność 1:1 z `docs/data/schema/firestore-ttl-indexes.md` pkt 5 | **zaliczony** | blok JSON z pkt 5 sparsowany i porównany `util.isDeepStrictEqual` z `backend/firestore.indexes.json` → `true` |
| O4-1b Poprawność specyfikacji wg Firebase CLI | **zaliczony** | `FirestoreApi.validateSpec` z firebase-tools 15.36.0 → OK (1 indeks, `usage.expireAt ttl=true`, `usage_global.expireAt ttl=true`); kontrola negatywna (`"ttl": "x"`) → „Property "ttl" must be of type boolean" |
| O4-1c Emulator Firestore z `firebase.json` wskazującym plik indeksów | **zaliczony (ograniczony)** | emulator startuje bez błędu (D-5). Uwaga: emulator Firestore **nie ładuje ani nie waliduje** indeksów (0 wpisów „index" w `firestore-debug.log`), więc dowodem poprawności jest O4-1b, nie emulator |
| O4-1d Wdrożenie (`firebase deploy --only firestore:indexes`) | **poza zakresem** | O4-2, właściciel |

Uwaga: `backend/functions/src` dziś **nie zapisuje** dokumentów `usage` (brak `expireAt` w kodzie) – polityka TTL zacznie działać, gdy zapis liczników (P3-05) ustawi `expireAt` wg pkt 5 dokumentu dba. Do sprawdzenia przy P3-05, nie błąd tego PR.

## 6. OBS-1 – poziom logów

| Przypadek | Wynik | Dowód |
|---|---|---|
| OBS-1a Błędy z kontraktu jako WARNING, bez stosu | **zaliczony** | log emulatora z D-5: 27 wpisów `fn_error` – wszystkie `"severity":"WARNING"` (`invalid_argument` 13, `consent_required` 6, `unauthenticated` 4, `ai_unavailable` 2, `test_data_only` 1, `unsupported_version` 1); 0 wystąpień `at entryFromArgs`/`handler.js` (w r3: 27 wpisów ERROR ze stosem) |
| OBS-1b ERROR dla `internal` / `ai_invalid_response` / wyjątków spoza `AppError` | **zaliczony (jednostkowo)** | `test/logger-severity.test.ts` w vitest (T-5); w przebiegu emulatora brak takich zdarzeń (0 linii `ERROR`) |
| OBS-1c PRIV-04 bez regresji | **zaliczony** | klucze `fn_error`: `fn, result, uidHash, durationMs, requestBytes, errorClass, errorCode, days, configError` (+ `severity`, `message`); 0 adresów e-mail w logu |

## 7. Błędy

### BUG-1 (niski) – UID w emulatorze Auth to nie `sub` fałszywego tokenu

- Gdzie: `lib/app/firebase_emulators.dart` (komentarz `testSub`: „becomes the Firebase UID in the Auth emulator"), `lib/features/auth/data/emulator_auth_gateway.dart` („Subject of the fake token = UID in the emulator"), `android/FIREBASE.md` („UID testowy `--dart-define=TAMITU_EMULATOR_TEST_SUB=...`").
- Kroki: `firebase emulators:exec --project demo-tamitu --only auth` → `POST /identitytoolkit.googleapis.com/v1/accounts:signInWithIdp` z `id_token={"sub":"qa-emulator-user",…}`, `providerId=google.com` (dwukrotnie).
- Oczekiwane (wg dokumentacji): `localId == "qa-emulator-user"`. Rzeczywiste: `localId` losowy (28 znaków), stały tylko w obrębie jednej sesji emulatora; `sub` trafia do `providerUserInfo.rawId`.
- Skutek: tester wpisujący `qa-emulator-user` do `config/runtime.testUids` dostanie `test_data_only` na `generatePlan` (dev), a dane emulatora nie są powiązane z przewidywalnym UID. `recordConsent` działa niezależnie. Nie blokuje QA13.
- Propozycja (mobile-dev): poprawić komentarze i `FIREBASE.md` („`sub` wyznacza konto Google w emulatorze; UID nadaje emulator"), a do `testUids` – odczyt UID z aplikacji/emulatora lub `--import`/`--export-on-exit` emulatora dla stałego UID. Alternatywa: emulator przyjmuje własny `localId` przez `accounts:signUp`/`batchCreate` – decyzja mobile-dev.

### Obserwacje (nie blokują)

- **OBS-2 (CI):** check `flutter` w PR jest czerwony do czasu GH-011 (Steward, `-P tamitu.allowMissingGoogleServices=true` w `ci.yml`) – zgodnie z opisem PR; lokalnie B-1/B-2/B-3 potwierdzają oba zachowania.
- **OBS-3 (środowisko testów I):** Node hosta 26 vs `engines.node` 22; przy dużym obciążeniu CPU emulator Functions nie uruchamia kolejnych workerów („Failed to load function"). Zalecenie: testy emulatorów nie równolegle z buildami Gradle; docelowo Node 22 w CI (OBS-2 z r3).
- **OBS-4:** `ai_unavailable` jest teraz WARNING. Słusznie dla wyłącznika/limitu globalnego; gdyby kod zaczął go używać dla awarii dostawcy AI (P3-05), warto rozważyć ERROR – do oceny przy P3-05.

## 8. Werdykt

**Warunkowo przyjęte.**

- **SEC-33 – przyjęte:** brak pliku bez flagi = błąd (B-1), flaga działa tylko w debug (B-2), release z flagą odrzucony (B-3).
- **O4-1 – przyjęte:** plik 1:1 z dokumentem dba i poprawny wg walidatora Firebase CLI (O4-1a/b).
- **OBS-1 – przyjęte:** 27/27 błędów z kontraktu jako WARNING bez stosu, testy jednostkowe dla ERROR.
- **QA13 – przyjęte warunkowo:** izolacja wariantów potwierdzona na APK (cleartext i konfiguracja emulatorów tylko w `devDebug`, prod/release czyste), guard flagi pokryty testami, mechanizm logowania i backend w emulatorach działają. **Nie wykonano** uruchomienia aplikacji wobec emulatorów i klienckich przypadków I z P3-04 – brak AVD (akceleracja) i urządzenia; blokada środowiska, nie kodu. BUG-1 (niski, dokumentacja/komentarze) do poprawy, nie blokuje merge.

Warunek: przypadki D-1/D-2 przechodzą do istniejącego zadania „QA P3-04 na urządzeniu" (po akceleracji AVD lub z telefonem USB; dzięki QA13 już **bez** wdrożenia dev, tokenu App Check i konta Google). Po GH-011 i zielonym CI PR może iść do merge (decyzja Stewarda/właściciela).
