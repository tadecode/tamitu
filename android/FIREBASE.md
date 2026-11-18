# Konfiguracja Firebase dla Androida (`google-services.json`)

Repozytorium jest publiczne – plików `google-services.json` **nie commitujemy** (`.gitignore`
w korzeniu i w `android/`). Zgodnie z runbookiem `.farm/runbooks/P3-03-firebase.md` (etap 10)
**źródłem** plików jest katalog właściciela poza repo: `%USERPROFILE%\.tamitu\firebase\<dev|prod>\`.
Do buildu plik się **kopiuje** do katalogu flavoru; zawartość nigdy w czacie, repo ani logach.

## Pliki per flavor

| Flavor | Pakiet | Projekt Firebase | `APP_ID` (runbook, etap 6) | Źródło (poza repo) | Kopia do buildu |
|---|---|---|---|---|---|
| `dev` | `pl.tadecode.tamitu.dev` | `tamitu-dev-tadecode` | `1:660969630372:android:48e4768c86542f081cd431` | `%USERPROFILE%\.tamitu\firebase\dev\google-services.json` | `android/app/src/dev/google-services.json` |
| `prod` | `pl.tadecode.tamitu` | `tamitu-prod-tadecode` | `1:41324867505:android:c983219aaa7a3c11449790` | `%USERPROFILE%\.tamitu\firebase\prod\google-services.json` | `android/app/src/prod/google-services.json` |

`APP_ID` to publiczny identyfikator aplikacji Firebase (jest w APK), nie sekret.

### 1. Pobranie do katalogu źródłowego (właściciel, Firebase CLI, raz na środowisko)

```powershell
firebase apps:sdkconfig android 1:660969630372:android:48e4768c86542f081cd431 --project=tamitu-dev-tadecode -o "$env:USERPROFILE\.tamitu\firebase\dev\google-services.json"
firebase apps:sdkconfig android 1:41324867505:android:c983219aaa7a3c11449790 --project=tamitu-prod-tadecode -o "$env:USERPROFILE\.tamitu\firebase\prod\google-services.json"
```

### 2. Kopia do buildu (przed `flutter build`/`flutter run`)

```powershell
Copy-Item "$env:USERPROFILE\.tamitu\firebase\dev\google-services.json" android\app\src\dev\
Copy-Item "$env:USERPROFILE\.tamitu\firebase\prod\google-services.json" android\app\src\prod\
```

Po skopiowaniu: `git status` – plik **nie może** się pojawić na liście (`git check-ignore -v
android/app/src/dev/google-services.json` pokazuje regułę). Po testach kopię można usunąć.

## Jak działa build

- Wtyczka `com.google.gms.google-services` (4.5.0) jest stosowana zawsze; z pliku flavoru generuje
  zasoby (`google_app_id`, `default_web_client_id`, klucz API), z których korzysta
  `Firebase.initializeApp()` (`lib/app/bootstrap.dart`).
- **Brak pliku = błąd buildu** (`missingGoogleServicesStrategy = ERROR`) – lokalnie i w CI, żeby nie
  powstał po cichu APK bez konfiguracji.
- **Jedyny wyjątek (SEC-33):** jawna właściwość Gradle
  `-P tamitu.allowMissingGoogleServices=true` (np. `flutter build apk --debug -P tamitu.allowMissingGoogleServices=true`)
  zamienia błąd na ostrzeżenie. Służy kontroli „czy się składa” w CI (do czasu GH-009) i demo
  `TAMITU_FAKE_BACKEND`. Taki APK nie zaloguje się do Firebase. **Build wydaniowy z tą flagą jest
  odrzucany** – wydanie zawsze wymaga prawdziwego pliku. SEC-35: kontrola patrzy na **graf zadań**
  Gradle (czy zaplanowano `process<Flavor>ReleaseGoogleServices`), a nie na nazwy z wiersza poleceń,
  więc obejmuje też zadania zbiorcze (`assemble`, `build`, `bundle`) i flagę ustawioną w
  `~/.gradle/gradle.properties` lub `ORG_GRADLE_PROJECT_…`.
  Zmienna środowiskowa `CI` nie ma już wpływu (przegląd PR #70, ustalenie #1).
- Pliki w CI z sekretów repo – prośba GH-009 (Steward); flaga w kroku CI – prośba GH-011.
- `serverClientId` dla Google Sign-In: `default_web_client_id` z pliku albo
  `--dart-define=TAMITU_GOOGLE_SERVER_CLIENT_ID=...` (patrz `lib/app/bootstrap.dart`).

## Emulatory Firebase (QA13, tylko `dev` debug)

Aplikację `dev` w buildzie debug można skierować na lokalne emulatory (Auth, Functions; Firestore
używają funkcje w emulatorze – aplikacja nie łączy się z Firestore bezpośrednio):

```powershell
cd backend; npx firebase emulators:start --project demo-tamitu --only "auth,functions,firestore"
flutter run --flavor dev --debug --dart-define=TAMITU_USE_FIREBASE_EMULATORS=true -P tamitu.allowMissingGoogleServices=true
```

- Projekt emulatorów **musi** być `demo-*` (domyślnie `demo-tamitu`, zmiana:
  `--dart-define=TAMITU_EMULATOR_PROJECT_ID=demo-...` – ta sama nazwa w `--project`). Aplikacja używa
  wtedy osobnej aplikacji Firebase (`tamitu-emulators`) z zastępczymi opcjami `demo-*`, a **nie**
  `google-services.json` – nie łączy się z `tamitu-dev-tadecode`, a plik nie jest potrzebny (stąd `-P`).
- Funkcje w emulatorze jak w raporcie QA P3-04 r3: `ENVIRONMENT=dev`, `ALLOW_REAL_DATA=false`,
  `ENFORCE_APP_CHECK=false`, testowy `UID_HASH_PEPPER` w `backend/functions/.secret.local` (ignorowany).
- Testy z emulatorami/urządzeniem uruchamiaj przez `.farm/test-lock.ps1` (zasób wspólny).

- Host domyślny `10.0.2.2` (emulator Androida → komputer). Telefon przez USB: `adb reverse tcp:9099 tcp:9099`
  i `adb reverse tcp:5001 tcp:5001`, potem `--dart-define=TAMITU_FIREBASE_EMULATOR_HOST=127.0.0.1`.
- Ruch bez TLS jest dozwolony **tylko** w wariancie `devDebug` i tylko do `10.0.2.2`, `127.0.0.1`,
  `localhost` (`android/app/src/devDebug/`); `prod` i `release` dalej blokują cleartext.
- Logowanie: zamiast wyboru konta Google aplikacja loguje się do emulatora Auth fałszywym
  poświadczeniem Google (`EmulatorAuthGateway`, dostawca `google.com`, `sub` fałszywego tokenu
  `--dart-define=TAMITU_EMULATOR_TEST_SUB=...`, domyślnie `qa-emulator-user`). Żadnych prawdziwych kont.
- **`sub` to nie UID** (BUG-QA13-UID): `sub` wyznacza konto Google w emulatorze
  (`providerUserInfo.rawId`), a UID (`localId`, 28 znaków) nadaje emulator losowo. Ten sam `sub`
  dostaje ten sam UID tylko w obrębie jednej sesji emulatora (albo między sesjami przy
  `--import`/`--export-on-exit`). Do `config/runtime.testUids` wpisuj UID odczytany z emulatora,
  nie wartość `sub` (Emulator UI jest wyłączone w `backend/firebase.json`; odczyt przez REST emulatora,
  `localId` przy `rawId` = Twój `sub`):

  ```powershell
  (Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/projects/demo-tamitu/accounts:query" -Headers @{ Authorization = "Bearer owner" } -ContentType "application/json" -Body '{"returnUserInfo":true}').userInfo | Select-Object localId, @{ n = "sub"; e = { $_.providerUserInfo[0].rawId } }
  ```

  Stały UID przez plik importu emulatora (`--import`) – możliwa przyszła zmiana (nie wdrożona).
- App Check nie jest aktywowany w trybie emulatorów (emulator Functions go nie weryfikuje, a
  aktywacja łączyłaby się z produkcyjną usługą App Check).
- Flaga w `prod` lub w buildzie release/profile przerywa start aplikacji (`StateError`); łączenie
  z `TAMITU_FAKE_BACKEND` również.
