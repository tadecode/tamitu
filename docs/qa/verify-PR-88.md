# Weryfikacja QA – PR #88: SEC-35 (blokada flagi google-services na grafie zadań) + BUG-QA13-UID

- Data: 2026-11-18 · Rola: qa · PR: tadecode/tamitu#88, gałąź `feat/SEC-35`
- **Zweryfikowany head: `ab79e0edc30e78655935f5f3d04c7970db1f4264`** (sprawdzone `gh pr view 88 --json headRefOid` przed nadaniem etykiety)
- Wejścia: `docs/reviews/PR-77.md`, `docs/qa/verify-PR-77.md` (BUG-1), `docs/reviews/PR-88.md` (gałąź `docs/review-PR-88`, rekomendacja „do akceptacji”), `.farm/log/2026-11-18/1824-mobile-dev-SEC-35.md`
- Środowisko: Windows 10, Flutter 3.50.0 stable, JBR z Android Studio (`JAVA_HOME`), firebase-tools (emulator Auth). Kod PR w osobnym worktree `--detach` tylko do odczytu; **bez `google-services.json`** (żaden plik nie był tworzony, kopiowany ani wypisywany).
- **Werdykt: PRZYJĘTE** → etykieta `qa:ok`.

## 1. Zakres zmian w `lib/features/` (bramka `review-gate` traktuje to jako „ekrany”)

| Przypadek | Wynik | Dowód |
|---|---|---|
| 1a Diff w `lib/features/` | **zaliczony** | `git diff origin/main...ab79e0e -- lib/features` → tylko `lib/features/auth/data/emulator_auth_gateway.dart`, 1 linia `///` usunięta, 4 linie `///` dodane; zero zmian kodu wykonywalnego |
| 1b Widżety, teksty UI, l10n | **zaliczony** | brak zmian w `lib/l10n/` i plikach `*.arb`; pozostałe pliki PR: `lib/app/firebase_emulators.dart` (tylko komentarz `///`), `android/`, `test/`, `.farm/log/` |

Wniosek: PR nie zmienia ekranów; `qa:ok` jest tu formalnością bramki (zbyt szeroka reguła – GH-012).

## 2. SEC-35 – blokada flagi `tamitu.allowMissingGoogleServices`

Wszystkie polecenia w `android/` (Gradle) lub w katalogu głównym (flutter) kodu PR, bez pliku `google-services.json`.

| Przypadek | Polecenie | Oczekiwane | Wynik |
|---|---|---|---|
| S-1 debug z flagą | `flutter build apk --debug -P tamitu.allowMissingGoogleServices=true` | APK | **zaliczony** – `Built build\app\outputs\flutter-apk\app-dev-debug.apk`, exit 0 |
| S-2 | `gradlew assembleProdRelease --dry-run -Ptamitu.allowMissingGoogleServices=true` | błąd SEC-35 | **zaliczony** – `BUILD FAILED`, komunikat `(SEC-33/SEC-35)`, „Release tasks in the graph: :app:processProdReleaseGoogleServices” |
| S-3 | `gradlew assembleRelease --dry-run -P…=true` | błąd | **zaliczony** – j.w., zadania Dev i Prod Release w grafie |
| S-4 | `gradlew bundleRelease --dry-run -P…=true` | błąd | **zaliczony** |
| S-5 zadania zbiorcze | `gradlew assemble --dry-run -P…=true`, `gradlew build --dry-run -P…=true` | błąd | **zaliczony** (oba) – powtórka B-3 z `assemble`, o którą prosił mobile-dev |
| S-6 flaga ze zmiennej środowiskowej | `ORG_GRADLE_PROJECT_tamitu.allowMissingGoogleServices=true gradlew assembleDevRelease --dry-run` | błąd | **zaliczony** – `BUILD FAILED`, SEC-35 |
| S-7 j.w. debug | `ORG_GRADLE_PROJECT_…=true gradlew assembleDevDebug --dry-run` | OK | **zaliczony** – `BUILD SUCCESSFUL` |
| S-8 debug z `-P` | `gradlew assembleDevDebug --dry-run -P…=true` | OK | **zaliczony** |
| S-9 pełny build release przez flutter | `flutter build apk --release --flavor prod -P …=true` | błąd SEC-35 | **zaliczony** – exit 1, komunikat SEC-35 |
| S-10 kontrola: release bez flagi | `gradlew assembleProdRelease --dry-run` | blokada nie działa (flaga wyłączona) | **zaliczony** – `BUILD SUCCESSFUL` w `--dry-run`; brak pliku zgłasza dopiero samo zadanie `process…GoogleServices` (strategia `ERROR`), które `--dry-run` pomija – zachowanie bez flagi bez zmian względem `main` (B-1 w `verify-PR-77.md`) |

## 3. Testy automatyczne

| Przypadek | Wynik | Dowód |
|---|---|---|
| T-1 `flutter test` (head PR) | **zaliczony** | `All tests passed!` – **138/138**, exit 0 (w tym nowy test „google-services flag is guarded on the task graph” w `test/android_manifest_test.dart` i test listy dozwolonych zestawów źródeł bez cleartext w `test/app/firebase_emulators_test.dart`) |
| T-2 CI PR | **zielone** poza `review-gate` (wg raportu recenzenta; oczekuje etykiet) | `docs/reviews/PR-88.md` |

## 4. BUG-QA13-UID – komentarze vs rzeczywiste zachowanie emulatora Auth

Próba wykonana przez `.farm/test-lock.ps1 -Resource firebase-emulators`, `firebase emulators:exec --project demo-tamitu --only auth` (z `backend/` kodu PR), skrypt `docs/qa/scripts/verify-PR-88-uid.mjs` (wypisuje tylko długości, wartości logiczne i testowe `sub`).

| Przypadek | Wynik | Dowód |
|---|---|---|
| U-1 UID ≠ `sub` | **zgodne z komentarzem** | `signInWithIdp` (`providerId=google.com`, `sub=qa-emulator-user`) → 200, `localId` 28 znaków, `localId == sub` → `false` |
| U-2 ten sam `sub` = ten sam UID w jednej sesji | **zgodne** | 2. logowanie tym samym `sub` → ten sam `localId` (`true`) |
| U-3 inny `sub` = inny UID | **zgodne** | `qa-other-user` → inny `localId` |
| U-4 `sub` w `providerUserInfo.rawId`; polecenie z `android/FIREBASE.md` | **zgodne** | `accounts:query` z `Authorization: Bearer owner`, `returnUserInfo:true` → 200, 2 konta, `rawId` = odpowiednio `qa-emulator-user`/`qa-other-user`, `localId` = UID z logowania |
| U-5 brak innych twierdzeń „`sub` = UID” | **zgodne** | `git grep` po `lib/`, `android/`, `test/` na head PR – brak; `FIREBASE.md:78` mówi teraz „`sub` fałszywego tokenu” |

Komentarze w `lib/app/firebase_emulators.dart:56-59` i `lib/features/auth/data/emulator_auth_gateway.dart:20-23` oraz `android/FIREBASE.md` opisują zachowanie zgodnie z pomiarem. BUG-1 z `verify-PR-77.md` – **zamknięty**.

## 5. Błędy

Brak nowych błędów. Ustalenia recenzenta (#1–#3, drobne, opcjonalne) nie są podważone; QA nie ma ich dowodów przeciwnych. Uwaga do ustalenia #1 recenzenta: negatywne przypadki S-2…S-9 są dziś potwierdzone tylko ręcznie (tu i u mobile-dev) – krok CI z oczekiwanym błędem nadal byłby wartościowy (opcjonalna prośba do Stewarda).

## 6. Czego nie sprawdzono

- Uruchomienie aplikacji na urządzeniu/emulatorze Androida wobec emulatora Auth (brak AVD z akceleracją i telefonu) – UID sprawdzony przez REST emulatora tym samym fałszywym tokenem `google.com`, nie przez `FirebaseAuth` w aplikacji. Pokrywa to istniejące zadanie „QA P3-04 na urządzeniu”.
- Stałość UID między sesjami przy `--import`/`--export-on-exit` (komentarz to tylko wzmianka; funkcja niewdrożona).
- Hipoteza recenzenta #2 (`gradlew test`/`lint` z flagą też odrzucane) – nie uruchamiano; nie dotyczy kryteriów SEC-35.
- Ścieżka z flagą w `~/.gradle/gradle.properties` – nie modyfikowano globalnej konfiguracji maszyny; ten sam mechanizm `providers.gradleProperty` potwierdzono dla `-P` i `ORG_GRADLE_PROJECT_*`.
- Buildy nie były wykonywane w CI w wariancie „bez sekretu” (w PR sekret był dostępny) – lokalny S-1 odpowiada temu krokowi.

## 7. Werdykt

**PRZYJĘTE** (head `ab79e0e`). SEC-35: każda testowana ścieżka release z flagą (`-P` i `ORG_GRADLE_PROJECT_*`, zadania pojedyncze i zbiorcze, `flutter build apk --release`) kończy się błędem SEC-35, debug z flagą buduje się. `flutter test` 138/138. BUG-QA13-UID: komentarze zgodne z pomiarem na emulatorze Auth. Zmiana w `lib/features/` to wyłącznie komentarz. Merge – decyzja właściciela.
