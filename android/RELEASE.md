# Podpis wydania `prod` (klucz przesyłania, ADR-0019)

**Co i po co:** plik AAB dla Google Play (`prodRelease`) podpisujemy **kluczem przesyłania** właściciela.
Google trzyma klucz podpisu aplikacji (Play App Signing). Klucz przesyłania i hasła leżą **tylko u właściciela**,
poza repozytorium. Gradle czyta je z ustawień użytkownika albo ze zmiennych środowiskowych (TAM-119, REL-MD-1).

Pełna instrukcja (wygenerowanie klucza, build AAB, lista kontrolna, przesłanie do Play Console) to zadanie
TAM-125 (REL-MD-3). Tu jest tylko to, czego wymaga kod.

## Co właściciel tworzy u siebie (poza repo)

| Plik | Gdzie | Zawartość |
|---|---|---|
| Klucz przesyłania (`.jks`) | `%USERPROFILE%\.tamitu\signing\` (np. `tamitu-upload.jks`) | tworzy właściciel (`keytool`, TAM-125); kopia i hasła w menedżerze haseł firmy |
| Ustawienia Gradle użytkownika | `%USERPROFILE%\.gradle\gradle.properties` | cztery wpisy z tabeli niżej |
| `google-services.json` dla `prod` | źródło `%USERPROFILE%\.tamitu\firebase\prod\`, kopia do `android/app/src/prod/` na czas buildu | wg `android/FIREBASE.md` |

Żadnego z tych plików nie kopiujemy do repozytorium (`.gitignore` blokuje `*.jks`, `*.keystore`, pliki
z właściwościami klucza i `google-services.json`). Wartości nie trafiają do czatu, Jiry, Confluence ani logów.

## Wartości, których szuka Gradle

Każdą wartość można podać jako właściwość Gradle (`%USERPROFILE%\.gradle\gradle.properties`, `-P` albo
`ORG_GRADLE_PROJECT_…`) **albo** jako zmienną środowiskową. Właściwość Gradle ma pierwszeństwo.

| Właściwość Gradle | Zmienna środowiskowa | Znaczenie |
|---|---|---|
| `tamitu.upload.storeFile` | `TAMITU_UPLOAD_STORE_FILE` | pełna ścieżka do pliku klucza przesyłania |
| `tamitu.upload.storePassword` | `TAMITU_UPLOAD_STORE_PASSWORD` | hasło magazynu kluczy |
| `tamitu.upload.keyAlias` | `TAMITU_UPLOAD_KEY_ALIAS` | alias klucza (np. `tamitu-upload`) |
| `tamitu.upload.keyPassword` | `TAMITU_UPLOAD_KEY_PASSWORD` | hasło klucza |

W `gradle.properties` ścieżkę Windows zapisuj z ukośnikami `/` (np. `C:/Users/<ty>/.tamitu/signing/tamitu-upload.jks`),
bo `\` jest tam znakiem ucieczki. Zmienne środowiskowe przydadzą się na etapie 2 (build w CI, osobna decyzja).

## Jak działa build

- **`prodRelease`** (`flutter build appbundle --flavor prod --release`) podpisuje konfiguracją `upload`, gdy są
  wszystkie cztery wartości, a plik klucza istnieje.
- **Brak lub niepełna konfiguracja → błąd buildu** z listą brakujących wartości (bez ścieżek i haseł). Wariant
  `prodRelease` nie ma wtedy żadnej konfiguracji podpisu. **Nigdy nie wraca do klucza debug.** Kontrola patrzy
  na graf zadań Gradle (`assemble|bundle|package|sign` + `ProdRelease…`), więc obejmuje też zadania zbiorcze
  (`assemble`, `bundle`, `build`), tak jak SEC-35 dla `google-services.json`.
- **Bez zmian:** buildy debug i profile (oba flavory) oraz `devRelease` zostają na kluczu debug (ADR-0019 pkt 3;
  `devRelease` służy do testów QA i nie trafia do Play). Do tych buildów, ani do kroku CI „czy się składa”, nie
  trzeba żadnej konfiguracji podpisu.
- Sprawdzenie bez budowania: `cd android; .\gradlew :app:signingReport` – przy `Variant: prodRelease` powinno być
  `Config: upload` (z konfiguracją) albo `Config: none` (bez niej). Wynik pokazuje ścieżkę pliku klucza, więc nie
  wklejaj go do czatu ani logów.
- Strażnik w testach: `test/android_release_signing_test.dart`.
