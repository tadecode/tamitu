# QA-P3-04-DEV-2 – zapis zgody end-to-end na urządzeniu (TAM-34)

- Autor (rola): qa · Data: 2026-11-20 · Gałąź raportu: `docs/TAM-34-qa-consent-e2e`
- Zadanie: TAM-34 (Jira; Farm Id QA-P3-04-DEV-2)
- **Testowany kod: `main` @ `ecb7281`** (aplikacja), funkcja `recordConsent` w `tamitu-dev-tadecode` wdrożona
  2026-11-20 (TAM-84, `docs/architecture/deploy-dev-functions.md`)
- Norma: `docs/qa/test-plan-p3-04.md` – SIGN-11 (strona serwera), CONS-01, RECON-03, AIC-04; poprzednio
  `docs/qa/verify-p3-04-dev.md` (sekcja „nie sprawdzono”)
- **Werdykt: PRZYJĘTE CZĘŚCIOWO – 2 z 4 przypadków zaliczone, 2 niewykonalne na tym buildzie (blokady
  opisane w sekcji 4), 0 nowych błędów.** Zapis zgody na politykę prywatności działa od aplikacji przez
  App Check i `recordConsent` do Firestore `dev`.

Poprzednia wersja tego raportu (2026-11-20, `main` @ `966170d`) miała werdykt „ZABLOKOWANE” – funkcje nie
były wtedy wdrożone. Blokada została zdjęta przez TAM-84/85/86.

## 1. Środowisko

| Element | Stan |
|---|---|
| Urządzenie | OPPO (ColorOS, Android 13) przez USB; każde użycie `adb` przez `.farm/test-lock.ps1 -Resource device` |
| Build | `flutter build apk --flavor dev --debug --dart-define=TAMITU_APP_CHECK_DEBUG_TOKEN=…`, pakiet `pl.tadecode.tamitu.dev`, instalacja `install -r` + `pm clear` (czysty start) |
| `google-services.json` | skopiowany z katalogu właściciela tylko na czas buildu (`git check-ignore` potwierdził ignorowanie), po teście usunięty; zawartości nie odczytywano |
| App Check | token debug „qa-phone” (decyzja O-TAM84-2) czytany wyłącznie ze zmiennej środowiskowej użytkownika i przekazany do buildu; wartości nie wyświetlano ani nie zapisywano |
| Backend `dev` | `recordConsent` (`europe-west4`, konto `fn-consent`), `ENFORCE_APP_CHECK=true`, `config/runtime.allowRealData=false` |
| Konto | „konto testowe właściciela”; wybór konta w oknie Google wykonał właściciel. W raporcie brak e-maila, nazwy konta, UID, `consentId` i tokenów |
| Weryfikacja serwera | tylko odczyt: `docs/qa/scripts/consents-dev-summary.ps1` (zapytanie collection group `consents` przez REST Firestore + `gcloud logging read` dla `service_name="recordconsent"`); skrypt nie wypisuje ścieżek dokumentów ani identyfikatorów |
| Dowody | zrzut ekranu po restarcie (EK-04) obejrzany i usunięty, poza repo; zrzutów okna wyboru konta nie robiono |

Stan przed testem (punkt odniesienia): w Firestore `dev` **0** dokumentów `consents`; w logach `recordconsent`
wyłącznie test dymny z wdrożenia (HTTP 401, `fn_error`/`unauthenticated`).

## 2. Przebieg

1. Czysta instalacja → EK-02 → właściciel zaznacza zgodę, „Zaloguj przez Google”, wybiera konto testowe → EK-04.
2. Odczyt serwera (Firestore + logi) – sekcja 3.
3. Odczyt danych aplikacji (`run-as`, tylko nazwy plików / obecność klucza) – wpis tymczasowy.
4. `am force-stop` + ponowny start → EK-04; po ok. 1 min ponowny odczyt logów (czy aplikacja nie ponawia wysyłki).

## 3. Wyniki przypadków

| Przypadek | Wynik | Dowód |
|---|---|---|
| **SIGN-11** (strona serwera: dokument `users/{uid}/consents/{consentId}`) | **zaliczony** | Firestore: 1 dokument w 1 użytkowniku (wcześniej 0). Pola dokładnie: `type=privacy_policy`, `policyVersion=privacy-v1`, `granted=true`, `lang=pl`, `clientAt=2026-11-20T22:17:53Z`, `receivedAt=2026-11-20T22:18:03.136Z` – bez e-maila, nazwy i innych pól. Logi `recordconsent`: żądanie HTTP 200 (22:18:02Z) i wpis `fn_event`, `fn=recordConsent`, `result=ok`, `uidHash` obecny (skrót HMAC, nie UID). Przy `ENFORCE_APP_CHECK=true` – App Check z tokenem debug przyjęty (brak `app_check_failed`) |
| **CONS-01** (`synced=1`, `received_at`, usunięcie wpisu tymczasowego) | **zaliczony (pośrednio)** | (a) wpis tymczasowy usunięty: magazyn `FlutterSharedPreferences` aplikacji pusty (0 B), klucz `pendingPolicyAcceptance` nieobecny; (b) `synced=1`: po zabiciu procesu i ponownym starcie aplikacja otwiera EK-04 i **nie** wysyła ponownie `recordConsent` (brak nowych żądań w logach serwera `recordconsent` po restarcie) – a rekord `synced=0` byłby ponawiany przy starcie (CONS-03, sprawdzone w QA-P3-04-DEV). Bezpośredni odczyt `consents_local` niemożliwy: baza konta jest zaszyfrowana (SQLCipher, klucz w Keystore) – to zamierzone. `received_at` w wierszu lokalnym nie odczytany (ta sama przyczyna); pokrywa go test jednostkowy CONS-01 |
| **RECON-03** (`privacy-v2` po `privacy-v1`) | **niewykonalny – blokada** | Serwer zna tylko `privacy-v1` (`backend/functions/src/consents.ts`, `KNOWN_VERSIONS`), a w aplikacji wersja jest stałą `AppConstants.privacyPolicyVersion='privacy-v1'` (nie `--dart-define`). Test wymaga zmiany kodu w obu miejscach i wdrożenia – poza rolą QA. Sekcja 4 |
| **AIC-04** (`ai_processing`, `ai-consent-v1`, `synced=1`) | **niewykonalny – blokada** | EK-06 (`/ai-consent`) nie ma wejścia z interfejsu: EK-04 to zaślepka, brak deep linku (manifest ma tylko intencję LAUNCHER); wejście powstaje w P3-05 (EK-05/EK-07). Serwer obsługuje `ai-consent-v1`, więc po dodaniu wejścia test jest wykonalny bez zmian w backendzie. Sekcja 4 |

Dodatkowo potwierdzone przy okazji:
- **API-10 (część realna):** wywołanie z ważnym tokenem App Check przy wymuszeniu po stronie funkcji – przyjęte.
  Wywołanie bez logowania – 401 (test dymny z wdrożenia).
- **GATE-07:** restart → od razu EK-04, bez EK-02.
- **PRIV (logi serwera):** w logach `recordconsent` tylko pola z listy dozwolonych (`fn`, `result`, `uidHash`, …);
  brak UID, e-maila i treści żądania.

Nowe błędy: **brak** (BUG-DEV-n nie zgłaszam).

## 4. Co blokuje RECON-03 i AIC-04 (propozycje zadań)

1. **AIC-04** – po dodaniu wejścia do EK-06 (P3-05: EK-05 formularz → EK-06) QA powtarza: „Zgadzam się” →
   dokument `ai_processing`/`ai-consent-v1` w Firestore, `fn_event result=ok`, brak ponowienia po restarcie.
   Alternatywa wcześniejsza (decyzja orkiestratora/właściciela): test integracyjny `integration_test/` na
   urządzeniu, który nawiguje do `/ai-consent` – wymaga dodania `integration_test` do `pubspec.yaml` (mobile-dev).
2. **RECON-03** – potrzebny build testowy z `privacy-v2`: (a) backend zna `privacy-v2` (procedura ADR-0012
   pkt 6: najpierw serwer, potem aplikacja), wdrożony do `dev`; (b) build aplikacji z `privacy-v2` – najprościej
   przez nadpisanie wersji w buildzie `dev` (`--dart-define`, tylko flavor dev) albo osobna gałąź testowa
   (mobile-dev + architekt; zmiana tekstu polityki nie jest potrzebna, ale test odcisku AIC-10 musi to dopuścić).
   Do tego czasu RECON-03 pokrywają testy jednostkowe/widżetowe (P3-04 r3).

## 5. Sprzątanie (OWNER-CLEANUP-DEV)

Do wykonania przez właściciela po przyjęciu raportu (bez identyfikatorów w repo i czacie):

1. **Token debug App Check „qa-phone”** – usunąć w konsoli Firebase: App Check → aplikacja
   `pl.tadecode.tamitu.dev` → Manage debug tokens → „qa-phone” (chyba że zostaje na potrzeby AIC-04/RECON-03 –
   wtedy usunąć po nich).
2. **Zmienna środowiskowa** – usunąć u siebie:
   `[Environment]::SetEnvironmentVariable('TAMITU_APP_CHECK_DEBUG_TOKEN', $null, 'User')`
3. **Dane testowe w `dev`** (opcjonalnie): użytkownik „konto testowe właściciela” w Firebase Auth `dev`
   (Authentication → Users) oraz jego dokument zgody w Firestore (`users/<uid>/consents`, 1 dokument
   `privacy_policy`) i dokument `users/<uid>`, jeśli powstał. Uwaga: jeśli konto zostaje do AIC-04, zostawić też
   dokument zgody na politykę – bez niego `recordConsent(ai_processing)` zwróci `consent_required`.
4. **Telefon** (opcjonalnie): odinstalować `pl.tadecode.tamitu.dev` (APK zawiera token debug wkompilowany przez
   `--dart-define`; po usunięciu tokenu z konsoli przestaje on działać), wyłączyć „Wyłącz monitorowanie
   uprawnień” i „Nie przeszkadzać”, jeśli były włączone na test.

Stan (2026-11-20): pkt 1 i 2 **wykonane** przez właściciela. Usunięcie zmiennej QA potwierdziło odczytem
(zmienna pusta). Skutek: AIC-04 i RECON-03 będą wymagały nowego tokenu debug. Pkt 3 i 4 – otwarte.

Po stronie QA: `google-services.json` usunięty z worktree, zrzut ekranu usunięty, poza odczytem nie zmieniano
niczego w projekcie `dev` (dane powstały wyłącznie przez normalne użycie aplikacji).
