# Konfiguracja Firebase dla Androida (`google-services.json`)

Repozytorium jest publiczne – plików `google-services.json` **nie commitujemy** (`.gitignore`
w korzeniu i w `android/`). Trzyma je właściciel poza repo (`%USERPROFILE%\.tamitu\firebase\<dev|prod>\`,
runbook `.farm/runbooks/P3-03-firebase.md`, etap 10).

## Gdzie położyć pliki

| Flavor | Pakiet | Projekt Firebase | Ścieżka |
|---|---|---|---|
| `dev` | `pl.tadecode.tamitu.dev` | `tamitu-dev-tadecode` | `android/app/src/dev/google-services.json` |
| `prod` | `pl.tadecode.tamitu` | `tamitu-prod-tadecode` | `android/app/src/prod/google-services.json` |

Pobranie (właściciel, Firebase CLI; `<APP_ID>` z tabeli etapu 6 w runbooku):

```
firebase apps:sdkconfig android <APP_ID> --project=tamitu-dev-tadecode -o android/app/src/dev/google-services.json
```

Przed `git add` sprawdź `git status` – plik nie może się pojawić na liście.

## Jak działa build

- Wtyczka `com.google.gms.google-services` (4.5.0) jest stosowana zawsze; z pliku flavoru generuje
  zasoby (`google_app_id`, `default_web_client_id`, klucz API), z których korzysta
  `Firebase.initializeApp()` (`lib/app/bootstrap.dart`).
- **Brak pliku = błąd buildu** (`missingGoogleServicesStrategy = ERROR`), żeby nie powstał po cichu
  APK bez konfiguracji.
- **Wyjątek:** w CI (`CI=true`) lub z `-Ptamitu.allowMissingGoogleServices=true` brak pliku daje tylko
  ostrzeżenie – kontrola „czy się składa” działa bez żadnej konfiguracji i kluczy. Taki APK nie
  zaloguje się do Firebase. Pliki w CI z sekretów repo – prośba GH-009 (Steward).
- `serverClientId` dla Google Sign-In: `default_web_client_id` z pliku albo
  `--dart-define=TAMITU_GOOGLE_SERVER_CLIENT_ID=...` (patrz `lib/app/bootstrap.dart`).
