# 18:24  mobile-dev → orchestrator, reviewer, qa  |  SEC-35 (+ BUG-QA13-UID)
- Zrobione (gałąź `feat/SEC-35`, jeden PR, 2 commity):
  1. **SEC-35** (przegląd PR #77, ustalenia #1 i #3) – `android/app/build.gradle.kts`: blokada flagi `tamitu.allowMissingGoogleServices` dla release sprawdza **graf zadań** (`gradle.taskGraph.whenReady`, zadanie `:app:process<Flavor>ReleaseGoogleServices` w grafie), a nie `startParameter.taskNames`. Test cleartext/`network_security_config_emulators` przegląda teraz wszystkie zestawy `android/app/src/*` poza `devDebug` (lista dozwolonych; sprawdza też nazwę pliku, odwołanie w XML i `usesCleartextTraffic="true"`); nowy test strażnika w `test/android_manifest_test.dart`.
  2. **BUG-QA13-UID** – komentarze w `lib/app/firebase_emulators.dart`, `lib/features/auth/data/emulator_auth_gateway.dart` i `android/FIREBASE.md` opisują rzeczywiste zachowanie: `sub` → `providerUserInfo.rawId`, UID (`localId`, 28 znaków) nadaje emulator; ten sam `sub` = ten sam UID w jednej sesji. W `FIREBASE.md` polecenie odczytu UID przez REST emulatora (`accounts:query`, `Bearer owner`) do wpisania w `config/runtime.testUids`.
- Testy lokalnie: `dart format --set-exit-if-changed` ✅; `flutter analyze` – 0 problemów; `flutter test` – 138/138. Gradle (JBR Android Studio):
  - `flutter build apk --debug --flavor dev -P tamitu.allowMissingGoogleServices=true` → APK ✅;
  - z flagą `-P`: `assembleRelease`, `assembleProdRelease`, **`assemble`**, **`bundle`**, **`build`** (`--dry-run`) → `GradleException` SEC-35 ✅; `flutter build apk --release --flavor prod -P …` → błąd SEC-35 ✅;
  - flaga przez `ORG_GRADLE_PROJECT_tamitu.allowMissingGoogleServices=true`: `assembleDevRelease` → błąd ✅, `assembleDevDebug --dry-run` → OK ✅;
  - bez flagi `assembleDevDebug` → „File google-services.json is missing” ✅.
  - Emulator Auth (przez `.farm/test-lock.ps1 -Resource firebase-emulators`, projekt `demo-tamitu`): 2× `signInWithIdp` z `sub=qa-emulator-user` → ten sam losowy `localId` (28 znaków); `accounts:query` z `Bearer owner` → 200, `rawId=qa-emulator-user` – potwierdza BUG-1 z QA i polecenie z `FIREBASE.md`.
- Artefakty: `android/app/build.gradle.kts`, `android/FIREBASE.md`, `test/android_manifest_test.dart`, `test/app/firebase_emulators_test.dart`, `lib/app/firebase_emulators.dart`, `lib/features/auth/data/emulator_auth_gateway.dart`.
- Decyzje: kontrola na zadaniu `process*ReleaseGoogleServices` (dokładnie to zadanie, które z flagą tylko ostrzega), wcześniejsze sprawdzenie nazw z wiersza poleceń usunięte (jeden mechanizm). Stały UID przez import emulatora **nie** wdrożony (wymaga pliku eksportu w repo i weryfikacji dopasowania konta po `rawId`) – możliwa przyszła zmiana. Bez wpływu na koszty.
- Do zrobienia przez odbiorcę: **reviewer** – przegląd PR po zielonym CI (CI buduje debug z flagą bez sekretu – zgodne). **qa** – opcjonalnie powtórka B-3 z `gradlew assemble -P…` (oczekiwany błąd SEC-35).
- Pytania/blokady: brak. Uwaga środowiskowa: `gradlew` poza `flutter` wymaga `JAVA_HOME` (np. `C:\Program Files\Android\Android Studio\jbr`).

## Dla orkiestratora (zadania i pytania)
- Zadania – status: SEC-35: review (PR); BUG-QA13-UID: review (PR)
- Zadania – nowe: (opcjonalne, niski priorytet) „Stały UID testowy w emulatorze Auth przez `--import`” – mobile-dev, bez zależności; tylko jeśli QA potrzebuje stałego UID między sesjami
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak
