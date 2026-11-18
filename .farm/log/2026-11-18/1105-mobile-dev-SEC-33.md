# 11:05  mobile-dev → orchestrator, steward, reviewer, qa, security, owner  |  SEC-33 (+ O4-1, QA13, OBS-1, PR #70 #4 b/c)
- Zrobione (gałąź `feat/SEC-33`, jeden PR, 5 commitów):
  1. **SEC-33** – `android/app/build.gradle.kts`: obejście braku `google-services.json` tylko przez jawną właściwość `-P tamitu.allowMissingGoogleServices=true`; zmienna `CI` bez wpływu; flaga z zadaniem `release` → `GradleException`. Sprawdzone lokalnie: bez flagi `assembleDevDebug` = błąd „google-services.json is missing”; flaga + `--release` = błąd SEC-33; flaga + `--debug` (także z `CI=true`) = APK.
  2. **O4-1** – `backend/firestore.indexes.json`: TTL `usage` na `expireAt` (1:1 z pkt 5 dokumentu dba).
  3. **QA13** – przełącznik `--dart-define=TAMITU_USE_FIREBASE_EMULATORS=true` tylko w `dev` + debug (`StateError` w prod/release/profile i razem z `TAMITU_FAKE_BACKEND`); osobna aplikacja Firebase `tamitu-emulators` z opcjami projektu `demo-*` (nie łączy się z `tamitu-dev-tadecode`, nie potrzebuje `google-services.json`); Auth i Functions w emulatorze, bez App Check; adapter `EmulatorAuthGateway` (fałszywe poświadczenie Google akceptowane tylko przez emulator Auth, dostawca `google.com`); cleartext tylko w `android/app/src/devDebug` i tylko do `10.0.2.2`/`127.0.0.1`/`localhost`. Firestore: aplikacja nie ma klienta Firestore – emulatora Firestore używają funkcje w emulatorze (bez nowej zależności). Testy: reguły, konfiguracja, adapter, okablowanie, manifest.
  4. **OBS-1** – `logFailure`: `AppError` → `warn` (WARNING, bez stosu), `ERROR` tylko dla wyjątków spoza kontraktu oraz `internal`/`ai_invalid_response`. Test `logger-severity.test.ts`.
  5. **PR #70 #4 b/c** – `serviceAccountEmail()` przeniesione do testu (+ test reguły nazw kont); `android/FIREBASE.md` zgodny z runbookiem etap 10 (źródło `%USERPROFILE%\.tamitu\firebase\<env>\`, kopia, przykład prod z `APP_ID`), opis flagi `-P` i emulatorów.
- Testy lokalnie: `flutter analyze` – 0 problemów; `dart format` – bez zmian; `flutter test` – 136/136; `backend/functions`: `npm run lint` ✅, `npm run typecheck` ✅, `npm test` – 144/144 (8 plików).
- Artefakty: `android/app/build.gradle.kts`, `backend/firestore.indexes.json`, `lib/app/firebase_emulators.dart`, `lib/app/environment.dart`, `lib/app/bootstrap.dart`, `lib/features/auth/data/emulator_auth_gateway.dart`, `android/app/src/devDebug/**`, `backend/functions/src/logger.ts`, `backend/functions/src/service-accounts.ts`, `android/FIREBASE.md`, testy; prośba `.farm/requests/GH-011-ci-allow-missing-google-services-flag.md`.
- Decyzje: przełącznik nazwany `TAMITU_USE_FIREBASE_EMULATORS` (prefiks jak pozostałe `--dart-define`, propozycja QA); projekt emulatorów wymuszony `demo-*`; App Check nieaktywny w trybie emulatorów. Bez wpływu na koszty (brak nowych wywołań AI/chmury).
- Do zrobienia przez odbiorcę:
  - **steward (GH-011, przed scaleniem tego PR):** w `ci.yml` krok „Build APK (debug)” → `flutter build apk --debug -P tamitu.allowMissingGoogleServices=true`. Zgodne wstecz z `main` (obecny Gradle już honoruje właściwość). **Do tego czasu CI tego PR będzie czerwone w kroku buildu** – po scaleniu GH-011 ponownie uruchomić CI PR. Przy GH-009 flagę usunąć z joba z sekretami.
  - **reviewer:** przegląd po zielonym CI. **qa:** QA13 – uruchomienie aplikacji wobec emulatorów (`android/FIREBASE.md`, sekcja „Emulatory”) przez `.farm/test-lock.ps1`; na urządzeniu/AVD nie weryfikowałem (brak akceleracji AVD na tej maszynie).
  - **security:** ocena OBS-1 (podział WARNING/ERROR).
  - **owner:** po scaleniu O4-1 – O4-2 (`firebase deploy --only firestore:indexes` dev, potem prod).
- Pytania/blokady: brak; kolejność CI opisana wyżej.

## Dla orkiestratora (backlog i pytania)
- Backlog – status: SEC-33 → review (PR); O4-1 → review; QA13 → review (czeka na QA); OBS-1 → review (ocena security)
- Backlog – nowe zadania: GH-011 (steward, CI: jawna flaga `-P` w kroku buildu; przed scaleniem PR SEC-33)
- Pytania otwarte – nowe: brak
