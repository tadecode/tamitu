# 17:35  mobile-dev → reviewer, orchestrator  |  TAM-119 (REL-MD-1)

- Zrobione: wdrożony ADR-0019 pkt 3 w `android/app/build.gradle.kts`. `prodRelease` podpisuje konfiguracją
  `upload` (klucz przesyłania właściciela). Klucz debug nie jest już używany w `prodRelease`.
  1. **Skąd wartości:** cztery wartości (`tamitu.upload.storeFile|storePassword|keyAlias|keyPassword`) z właściwości
     Gradle (`%USERPROFILE%\.gradle\gradle.properties`, `-P`, `ORG_GRADLE_PROJECT_…`) albo ze zmiennych
     `TAMITU_UPLOAD_STORE_FILE|STORE_PASSWORD|KEY_ALIAS|KEY_PASSWORD`. W repo nie ma haseł, aliasów ani ścieżek.
  2. **Podpis per flavor:** `buildTypes.release.signingConfig = null`; `dev` → `debug`, `prod` →
     `findByName("upload")` (konfiguracja powstaje tylko przy komplecie wartości i istniejącym pliku). Typ builda ma
     pierwszeństwo w AGP, więc debug i profile (oba flavory) zostają na kluczu debug.
  3. **Brak konfiguracji = błąd buildu.** Kontrola w `gradle.taskGraph.whenReady` (wzór SEC-35): jeśli w grafie jest
     zadanie `(assemble|bundle|package|sign)ProdRelease…`, build kończy się `GradleException` z listą braków (bez
     ścieżki i haseł). Inne buildy, w tym krok CI `flutter build apk --debug`, nie wymagają konfiguracji.
  4. **`.gitignore`:** sprawdzony, bez zmian (`*.jks`, `*.keystore`, plik właściwości klucza, `google-services.json`
     w korzeniu i w `android/`).
  5. **Flavor prod:** bez zmian w kodzie. Build `prod` bierze `android/app/src/prod/google-services.json` (spoza repo,
     `android/FIREBASE.md`). Brak pliku nadal daje błąd (ERROR, SEC-33/35).
- Testy: `flutter analyze` bez uwag; `flutter test` 395/395 (nowy `test/android_release_signing_test.dart`, 5 testów:
  release bez podpisu, prod tylko `upload`, wartości wyłącznie z właściwości lub środowiska, kontrola grafu,
  `.gitignore`). Sprawdzenia w Gradle (lokalnie, JDK z Android Studio):
  - `flutter build appbundle --flavor prod --release` bez konfiguracji → **BUILD FAILED** z komunikatem „prodRelease
    must be signed with the upload key (ADR-0019)…” i listą 4 braków;
  - komplet wartości, ale plik nie istnieje → błąd „the file given in … does not exist”;
  - `:app:signingReport`: `prodRelease` → `Config: none`; `devRelease`, `*Debug`, `*Profile` → `debug`;
    z kompletem wartości (atrapa: istniejący plik tekstowy, **bez generowania klucza**) `prodRelease` → `Config: upload`;
  - `:app:assembleDebug -P tamitu.allowMissingGoogleServices=true --dry-run` → BUILD SUCCESSFUL (ścieżka CI).
  Pozytywnego podpisu prawdziwym kluczem nie sprawdzałem (zakaz generowania klucza): to zrobi właściciel w TAM-125.
- Artefakty: `android/app/build.gradle.kts`, `android/RELEASE.md` (nowy), `test/android_release_signing_test.dart`
  (nowy).
- Decyzje: `devRelease` zostaje na kluczu debug zgodnie z ADR-0019 pkt 3 i planem (sekcja „Podpisywanie”, MD-1:
  „`devRelease` bez zmian”). Brief sesji mówił „nigdy klucz debug w release”; trzymam się zatwierdzonego ADR, bo
  `devRelease` (inny pakiet `…tamitu.dev`) służy QA i nie trafia do Play. Zmiana wymagałaby nowego ADR.
- Pytania/blokady: brak.

## Dla orkiestratora

- Status TAM-119: kod gotowy, PR otwarty; czeka na recenzję (reviewer). QA nie jest potrzebne (bez ekranów); pełną
  weryfikację z prawdziwym kluczem robi właściciel w TAM-125 (REL-MD-3).
- Właściciel tworzy lokalnie (opis w `android/RELEASE.md`): plik klucza przesyłania w `%USERPROFILE%\.tamitu\signing\`,
  cztery wpisy `tamitu.upload.*` w `%USERPROFILE%\.gradle\gradle.properties`, `google-services.json` prod
  (`android/FIREBASE.md`).
- Dla TAM-125: opisać w instrukcji `:app:signingReport` (oczekiwane `Config: upload`) i ukośniki `/` w ścieżce
  w `gradle.properties`. Wariant `prodProfile` też używa klucza debug (nie dla Play).
- Nowe zadania: brak.
