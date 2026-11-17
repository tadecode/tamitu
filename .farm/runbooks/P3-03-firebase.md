# Runbook P3-03: projekty Firebase/GCP dev i prod

- Zadanie: P3-03 · Prowadzi: orchestrator · Wykonuje: właściciel (konsola i własny terminal)
- Podstawa: ADR-0003 (+ Aneks A), ADR-0002 Aneks A pkt 6, ADR-0001, ADR-0004, ADR-0005, `docs/architecture/costs.md`, SEC-09, SEC-16, SEC-17, SEC-20
- Zasada: w tym pliku tylko identyfikatory (projekty, konta usług, kubełki). **Żadnych** haseł, kluczy, tokenów, danych karty, treści `google-services.json`.

## Identyfikatory (uzupełniane w trakcie)

| Element | dev | prod |
|---|---|---|
| ID projektu | `tamitu-dev-tadecode` | `tamitu-prod-tadecode` |
| Numer projektu | 660969630372 | 41324867505 |
| Konto rozliczeniowe (nazwa wyświetlana) | „Moje konto rozliczeniowe" (trial) | „Moje konto rozliczeniowe" (trial) |
| Organizacja / folder | organizacja firmy, bez folderu | organizacja firmy, bez folderu |
| Region | `europe-west4` | `europe-west4` |
| Pakiet Android | `pl.tadecode.tamitu.dev` | `pl.tadecode.tamitu` |

## Weryfikacja regionu (2026-11-17, przed utworzeniem Firestore)

| Usługa | `europe-west4` | Źródło |
|---|---|---|
| Firestore (regionalna) | dostępna | firebase.google.com/docs/firestore/locations |
| Cloud Run functions (2. gen.) | dostępne (Tier 1) | docs.cloud.google.com/functions/docs/locations |
| Wyzwalacz Pub/Sub (Eventarc) | dozwolony (tylko regiony pojedyncze) | docs.cloud.google.com/eventarc/docs/locations |
| Gemini Flash (Vertex AI) – przetwarzanie ML | **brak gwarancji NL**; `gemini-2.5-flash`, `-flash-lite` i nowsze Flash: gwarancja w granicach UE (multi-region `eu`) przy wywołaniu z regionu UE | docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/data-residency |

Wniosek: region `europe-west4` bez zmian. Korekta sformułowania ADR-0001 → pytanie O1 w `docs/open-questions.md`.

## Etapy

| # | Etap | Status | Data | Uwagi |
|---|---|---|---|---|
| 0 | Narzędzia (`gcloud`, `firebase-tools`, `keytool`), 2FA | zrobione | 2026-11-17 | Cloud SDK 594.0.0, Firebase CLI 15.36.0, Node 26, `keytool` z JBR Android Studio; domyślny projekt `gcloud` wyczyszczony (`--project` jawnie w każdym poleceniu) |
| 1 | Konto rozliczeniowe, Blaze, nazwy, organizacja | zrobione | 2026-11-17 | Konto rozliczeniowe istnieje, otwarte, profil płatności typu „Organizacja" (firma TadeCode, zweryfikowany 2026-11-14); **okres próbny** – kredyt ok. 1186 zł, koniec ok. 2027-02-15; organizacja Cloud Identity/Workspace domeny firmy istnieje (projekty pod organizacją, bez folderu); „My First Project" nieużywany przez Tamitu |
| 2 | Projekty dev/prod (bez Analytics) | zrobione | 2026-11-17 | Projekty z `gcloud projects create` w organizacji, rozliczenia podpięte (`gcloud billing projects link`), Firebase: dev przez konsolę (akceptacja warunków Firebase przez właściciela, Analytics i Gemini in Firebase wyłączone), prod `firebase projects:addfirebase`; nazwy „Tamitu Dev" / „Tamitu Prod" |
| 3 | Budżety 20/100 PLN, progi 50/90/100%, Pub/Sub `budget-alerts` | zrobione | 2026-11-17 | Budżety „tamitu-dev 20 PLN" i „tamitu-prod 100 PLN" (miesięczne, filtr na projekt, kredyty nieodliczane); prod + prognoza 100% i temat `budget-alerts`; „My First Project" odpięty od rozliczeń |
| 4 | Kubełek logów UE 30 dni, sink, wykluczenie `_Default` | zrobione | 2026-11-17 | Kubełek `tamitu-logs` (`europe-west4`, 30 dni), sink `tamitu-eu-sink`, sink `_Default` wyłączony; test wpisu: UE 1 / `_Default` 0 w obu projektach |
| 5 | Konta usług `fn-ai-plan`, `fn-consent`, `fn-account`, `fn-budget` | zrobione (bez wartości sekretu) | 2026-11-17 | `fn-ai` → **`fn-ai-plan`** (Google: ID konta 6–30 znaków; pytanie O2); sekret `UID_HASH_PEPPER` w `europe-west4` bez wersji – wartość dodaje właściciel |
| 6 | Auth (tylko Google), aplikacje Android, SHA-1/SHA-256 | zrobione (prod bez SHA) | 2026-11-17 | Google włączone w obu projektach (inni dostawcy wyłączeni); aplikacje Android zarejestrowane; SHA klucza debug tylko w dev; prod czeka na klucz wydań / Play App Signing |
| 7 | App Check (Play Integrity), tokeny debug poza repo | zrobione (dev); prod otwarte | 2026-11-17 | dev: Play Integrity zarejestrowane, token debug `owner-laptop` (wartość u właściciela w menedżerze haseł); API `firebaseappcheck`, `playintegrity` włączone w obu projektach; prod: rejestracja po SHA klucza wydań + Play Console |
| 8 | Firestore Native, reguły `deny all`, `config/runtime` | zrobione (bez indeksów/TTL) | 2026-11-17 | Bazy `(default)` w `europe-west4`, Native, PITR wyłączone, ochrona przed usunięciem w prod; reguły `deny all` z repo; `config/runtime` z bezpiecznymi wartościami; indeksy i TTL wstrzymane (O4) |
| 9 | Vertex AI API, warunki przetwarzania danych (właściciel) | w toku | 2026-11-18 | API `aiplatform` włączone (etap 5); Privacy & Security: organ nadzorczy – Polska (UODO); SCC nie potwierdzane (adres rozliczeniowy w UE); SEC-15 otwarte |
| 10 | `google-services.json` lokalnie i w CI | zrobione (CI – prośby GH-009, GH-010) | 2026-11-18 | Pliki lokalnie poza repo (`%USERPROFILE%.tamituirebase<env>`); klucz API Android dev ograniczony do pakietu + SHA-1; CI – sekrety przez Stewarda |

## Szczegóły etapów

### Etap 0 – narzędzia
- Google Cloud CLI (Windows): instalator ze strony cloud.google.com/sdk/docs/install, potem `gcloud init` (logowanie w przeglądarce).
- Firebase CLI: `npm install -g firebase-tools`, potem `firebase login`.
- `keytool`: `"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"`.
- Konto Google TadeCode: 2FA włączone (najlepiej klucz sprzętowy, T17).

### Uwagi do etapu 0
- Windows PowerShell blokował `npm.ps1` (zasady wykonywania skryptów). Właściciel ustawił sam `RemoteSigned` dla `CurrentUser`; alternatywa bez zmiany: `npm.cmd`, `firebase.cmd`.
- Okno uruchomione przez instalator Cloud SDK ma stary PATH – po instalacji otworzyć nowy terminal.
- Numer konta rozliczeniowego nie trafia do repozytorium (repo publiczne) – w dokumentach tylko nazwa wyświetlana.

### Uwagi do etapu 1
- **Okres próbny (trial):** podpięcie projektu do konta próbnego = plan Blaze; Functions, Firestore i Vertex AI zużywają kredyt (Gemini API z AI Studio nie – i tak nieużywany, ADR-0001). Po wyczerpaniu kredytu lub ok. **2027-02-15** Google zatrzymuje zasoby, jeśli konto nie przejdzie na wersję płatną. **Decyzja i kliknięcie „Przejdź na wersję płatną" – wyłącznie właściciel**, przed tą datą.
- Budżety (etap 3) liczone **bez odejmowania kredytów** (promocje), inaczej w trialu koszt netto = 0 i alerty SEC-09 nie zadziałają.
- „My First Project" (projekt startowy konsoli) jest podpięty do tego konta rozliczeniowego – do odpięcia lub usunięcia (decyzja właściciela), żeby nie mieszał się z budżetami.

### Uwagi do etapu 2
- Pierwsze `firebase projects:addfirebase` zwróciło 403 PERMISSION_DENIED mimo roli właściciela – przyczyna: niezaakceptowane warunki Firebase na koncie. Po akceptacji w konsoli (właściciel) CLI działa.
- Firebase włącza domyślnie API Hosting i Remote Config (`firebasehosting`, `firebaseremoteconfig*`). Usług nie konfigurujemy (ADR-0003: nie używamy); samo włączone API nie generuje kosztów. Wyłączenie API – opcjonalnie później.
- Google Analytics nie jest połączony (`analyticshub.googleapis.com` to BigQuery Analytics Hub, domyślne API GCP, nie GA).

### Etap 3 – budżety (wykonane z terminala za zgodą właściciela)
Włączone API: prod `billingbudgets`, `pubsub`, `cloudbilling`; dev `billingbudgets`. Temat: `projects/tamitu-prod-tadecode/topics/budget-alerts` (nazwa zgodna z `backend/functions/src/index.ts`).

| Budżet | Kwota | Zakres | Kredyty | Progi | Powiadomienia |
|---|---|---|---|---|---|
| `tamitu-dev 20 PLN` | 20 PLN / mies. | `tamitu-dev-tadecode` | `EXCLUDE_ALL_CREDITS` | 50/90/100% (koszt bieżący) | e-mail do administratorów konta rozliczeniowego (domyślni odbiorcy IAM) |
| `tamitu-prod 100 PLN` | 100 PLN / mies. | `tamitu-prod-tadecode` | `EXCLUDE_ALL_CREDITS` | 50/90/100% + 100% prognozy | e-mail jw. + Pub/Sub `budget-alerts` |

Polecenie (wzór; numer konta rozliczeniowego – z `gcloud billing accounts list`, poza repo). W PowerShellu regułę z przecinkiem trzeba ująć w apostrofy:
```
gcloud billing budgets create --billing-account=<KONTO> --billing-project=tamitu-prod-tadecode --display-name="tamitu-prod 100 PLN" --budget-amount=100PLN --filter-projects=projects/tamitu-prod-tadecode --credit-types-treatment=exclude-all-credits --calendar-period=month --threshold-rule=percent=0.5 --threshold-rule=percent=0.9 --threshold-rule=percent=1.0 '--threshold-rule=percent=1.0,basis=forecasted-spend' --notifications-rule-pubsub-topic=projects/tamitu-prod-tadecode/topics/budget-alerts
```
- `budgetGuard` (P3-09) nie jest wdrożony; temat istnieje, subskrypcji brak. Wdrożenie funkcji z kontem `fn-budget` (etap 5).
- Polecenia `gcloud billing …` z `--billing-project=<nasz projekt>` – wspólny limit zapytań klienta gcloud bywa wyczerpany (429).
- Kwoty zmienia wyłącznie właściciel (SEC-09).

### Etap 4 – logi (wykonane z terminala za zgodą właściciela)
W obu projektach:
```
gcloud logging buckets create tamitu-logs --project=<P> --location=europe-west4 --retention-days=30
gcloud logging sinks create tamitu-eu-sink logging.googleapis.com/projects/<P>/locations/europe-west4/buckets/tamitu-logs --project=<P> --log-filter="<filtr _Default>"
gcloud logging sinks update _Default --project=<P> --disabled
```
- Filtr sinka = filtr `_Default` (wszystko poza logami audytu administracyjnego – te idą do `_Required`, 400 dni, bez danych użytkowników).
- Wyłączenie sinka `_Default` zamiast filtra wykluczającego – ten sam skutek (nic nowego w `global`), prostsza konfiguracja.
- Zmiany sinków działają z opóźnieniem kilku minut (pierwsze testy: wpis nadal w `_Default`). Test po ok. 5 min: wpis `p3-03-acceptance-3` – kubełek UE 1, `_Default` 0 (dev i prod).
- **Otwarte:** test odbioru z Aneksu A pkt 1 (wywołanie funkcji → wpisy Cloud Run/Functions tylko w kubełku UE) – po pierwszym wdrożeniu.

### Etap 5 – konta usług i sekret (wykonane z terminala za zgodą właściciela)
| Konto (`<nazwa>@<projekt>.iam.gserviceaccount.com`) | Funkcja | Role w projekcie | Sekret `UID_HASH_PEPPER` |
|---|---|---|---|
| `fn-ai-plan` | `generatePlan` | `roles/aiplatform.user`, `roles/datastore.user`, `roles/firebaseauth.viewer` | `secretAccessor` |
| `fn-consent` | `recordConsent` | `roles/datastore.user`, `roles/firebaseauth.viewer` | `secretAccessor` |
| `fn-account` | `deleteAccount` | `roles/datastore.user`, `roles/firebaseauth.admin` | `secretAccessor` |
| `fn-budget` | `budgetGuard` | `roles/datastore.user` (bez Auth) | – |

- Włączone API (oba projekty): `iam`, `secretmanager`, `aiplatform`; prod dodatkowo `orgpolicy` (odczyt zasad).
- Sekret `UID_HASH_PEPPER`: replikacja `user-managed`, tylko `europe-west4`; dostęp na poziomie sekretu. **Brak wersji** – wartość dodaje właściciel lokalnie (poniżej), nigdy przez czat ani repo.
- Zasady organizacji: `iam.disableServiceAccountKeyCreation` egzekwowane (brak kluczy JSON – zgodne z ADR); `iam.allowedPolicyMemberDomains` = `allowAll` (callable mogą być publiczne). Kluczy zarządzanych przez użytkownika: 0.
- Ograniczenia do przeglądu (SEC-17): `roles/datastore.user` = cała baza (IAM Firestore bez rozróżnienia kolekcji) – zakres wynika z kodu; rozważenie ról niestandardowych – security.
- **Przy pierwszym wdrożeniu:** `roles/run.invoker` dla `fn-budget` na usłudze `budgetguard` (wyzwalacz Pub/Sub); `serviceAccount` w opcjach każdej funkcji (SEC-20, mobile-dev); wdrażający potrzebuje `iam.serviceAccountUser` na tych kontach (właściciel ma jako Owner; CI – WIF, Steward).

Dodanie wartości sekretu (właściciel, PowerShell, osobno dla każdego projektu – różne wartości; plik tymczasowy bez znaku nowej linii, usuwany od razu):
```
$p='tamitu-dev-tadecode'; $b=New-Object byte[] 32; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b); $f=New-TemporaryFile; [IO.File]::WriteAllText($f,[Convert]::ToBase64String($b)); gcloud secrets versions add UID_HASH_PEPPER --project=$p --data-file=$f; Remove-Item $f; $b=$null
```

### Etap 6 – Auth i aplikacje Android
- Konsola (właściciel): Authentication → Sign-in method → Google → Enable; nazwa publiczna „Tamitu Dev" / „Tamitu"; e-mail pomocy = adres firmowy (widoczny dla użytkowników – przed testami zewnętrznymi rozważyć adres grupy, np. `pomoc@`). Bez Identity Platform. Weryfikacja przez Identity Toolkit API: `google.com enabled=True`, e-mail/telefon/anonimowy wyłączone (oba projekty).
- Aplikacje (Firebase CLI, `firebase apps:create android`):

| Projekt | Pakiet | App ID | SHA |
|---|---|---|---|
| dev | `pl.tadecode.tamitu.dev` | `1:660969630372:android:48e4768c86542f081cd431` | klucz debug właściciela: SHA-1 `8A:D7:C9:89:34:B9:08:2A:D6:F8:E3:8E:E8:9F:5C:73:02:E5:40:DC`, SHA-256 `86:3E:63:16:32:49:2C:AC:E0:B9:47:E3:9A:D8:B7:45:12:7F:2A:0B:84:D8:B4:E5:F4:30:C2:87:1E:10:EF:58` |
| prod | `pl.tadecode.tamitu` | `1:41324867505:android:c983219aaa7a3c11449790` | **brak** – świadomie (nie dodajemy klucza debug do prod) |

- Odciski: `keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android` (hasło klucza debug jest standardowe, nie jest sekretem). Każdy deweloper/maszyna z innym kluczem debug → dodatkowy SHA w aplikacji dev (`firebase apps:android:sha:create <APP_ID> <SHA>`).
- **Otwarte (prod):** klucz wydań (upload key) i/lub Play App Signing – decyzja właściciela; wtedy SHA-1/SHA-256 do aplikacji prod. `build.gradle.kts` podpisuje dziś `release` kluczem debug (`TODO`).
- **Otwarte (mobile-dev):** w `android/` brak wtyczki Gradle `com.google.gms.google-services`; plik konfiguracyjny per flavor: `android/app/src/dev/google-services.json`, `android/app/src/prod/google-services.json` (niekomitowane, `.gitignore`). Identyfikator klienta web (`serverClientId`) – z tego pliku (`default_web_client_id`) albo `--dart-define`.

### Etap 7 – App Check
- dev (konsola, właściciel): App Check → Apps → `pl.tadecode.tamitu.dev` → Play Integrity (SHA-256 klucza debug z etapu 6) – „Registered". Fraud Defense (reCAPTCHA) – pominięte (podgląd, niepotrzebne na Androidzie).
- Token debug `owner-laptop` (Manage debug tokens) – **wartość tylko w menedżerze haseł właściciela**; do buildu lokalnie `--dart-define=TAMITU_APP_CHECK_DEBUG_TOKEN=...` (`lib/app/bootstrap.dart`); do CI – sekret repo przez Stewarda (prośba GH, etap 10). Nowy token na każdą maszynę/CI; usuwanie tokenów przy odejściu osoby/wycieku.
- Egzekwowanie w konsoli (Firestore/Functions) **niewłączone**: Functions egzekwują w kodzie (`ENFORCE_APP_CHECK`, ADR-0002 Aneks A pkt 3), Firestore ma `deny all`.
- **prod: brak tokenów debug (zakaz, ADR-0003 Aneks A pkt 2, SEC-16).** Rejestracja Play Integrity w prod – po SHA-256 klucza podpisującego i połączeniu aplikacji z projektem w Google Play Console (Play Console → Test and release → App integrity → Play Integrity API → link Cloud project). Otwarte.

### Etap 8 – Firestore (lokalizacja potwierdzona przez właściciela: „potwierdzam europe-west4")
```
gcloud firestore databases create --database=(default) --location=europe-west4 --type=firestore-native [--delete-protection | --no-delete-protection] --project=<P>
cd backend && firebase deploy --only firestore:rules --project=<P>
```
| Projekt | Lokalizacja | Typ | Ochrona przed usunięciem | PITR |
|---|---|---|---|---|
| dev | `europe-west4` | Native | wyłączona | wyłączone |
| prod | `europe-west4` | Native | **włączona** | wyłączone |

- Reguły: `backend/firestore.rules` (`allow read, write: if false`) wdrożone w obu projektach.
- **Nie wdrożono** `firestore:indexes` (indeks `consents` + polityki TTL `usage.updatedAt`, `usage_global.expireAt`) – pytanie O4 (TTL na `updatedAt` kasowałby licznik). Wdrożyć po poprawce, najpóźniej z P3-05: `firebase deploy --only firestore:indexes --project=<P>`.
- `.firebaserc` w repo ma nadal placeholdery – polecenia używają `--project=<ID>`; uzupełnienie aliasów (`dev`, `prod`) to zmiana w `backend/` (mobile-dev).
- Dokument `config/runtime` (oba projekty, zapis REST API jako właściciel):

| Pole | Wartość |
|---|---|
| `aiEnabled` | `false` |
| `allowRealData` | `false` (do SEC-15) |
| `testUids` | `[]` – UID właściciela dopisać ręcznie w konsoli po pierwszym logowaniu (dana osobowa, nie do repo) |
| `perUserDailyLimit` | `5` |
| `globalDailyLimit` | `50` |
| `policyVersionCurrent` | `privacy-v1` |
| `aiConsentVersionCurrent` | `ai-consent-v1` |

Zmiany `config/runtime` – tylko właściciel z 2FA (ADR-0002 Aneks A pkt 7, SEC-16).

### Etap 9 – Vertex AI i warunki (właściciel czyta i decyduje sam)
- Konsola → IAM & Admin → **Privacy & Security** (poziom organizacji): 2026-11-18 właściciel wybrał **organ nadzorczy: Polska (UODO)**.
- „Standardowe klauzule umowne" (przycisk dla klientów z adresem rozliczeniowym poza EMEA) – **nie potwierdzono**: adres rozliczeniowy w Polsce, umowa z Google Cloud EMEA; ewentualna wątpliwość → lista do prawnika (S1).
- Do odnotowania po lekturze właściciela: aneks o przetwarzaniu danych (CDPA), kontakty RODO, dokumentacja „data governance" Vertex (brak trenowania – ADR-0001 SEC-15 poz. 2), tabela „Data residency" (poz. 3, pytanie O1).
- SEC-15 **pozostaje otwarte** do potwierdzenia wszystkich pozycji listy z ADR-0001; `ALLOW_REAL_DATA=false`.
- 2026-11-18: lekturę CDPA, kontaktów RODO, „data governance" i „data residency" właściciel przełożył na później (pozycja 6 poniżej).

### Etap 10 – `google-services.json` i klucze API
- **Lokalnie (właściciel):** pliki poza repo, pobierane Firebase CLI:
  `firebase apps:sdkconfig android <APP_ID> --project=<P> -o "%USERPROFILE%\.tamitu\firebase\<dev|prod>\google-services.json"`;
  do buildu kopiowane do `android/app/src/<dev|prod>/google-services.json` (w `.gitignore`). Zawartość nigdy w czacie, repo ani logach.
- **CI:** `.farm/requests/GH-009-ci-firebase-config-secrets.md` (sekrety `GOOGLE_SERVICES_JSON_DEV/PROD`, `TAMITU_APP_CHECK_DEBUG_TOKEN_CI` tylko dev);
  wdrożenia: `.farm/requests/GH-010-wif-deploy.md` (WIF, `ci-deployer`, warunek repo/gałąź).
- **Klucze API** (utworzone przez Firebase; każdy ograniczony do 27 API Firebase):

| Projekt | Klucz | Ograniczenie aplikacji |
|---|---|---|
| dev | Android key (auto created by Firebase) | **`pl.tadecode.tamitu.dev` + SHA-1 klucza debug** (2026-11-18, REST `apikeys` z `updateMask=restrictions.androidKeyRestrictions` – lista API zachowana) |
| prod | Android key (auto created by Firebase) | brak – dodać razem z SHA klucza wydań |
| dev, prod | Browser key (auto created by Firebase) | brak; aplikacji web nie ma – propozycja usunięcia (decyzja security) |

- Zawężenie listy API klucza Android (np. `identitytoolkit`, `securetoken`, `firebaseinstallations`, `firebaseappcheck`) – po teście na urządzeniu (security).

## Czego nie zrobiono / do zrobienia później
| # | Co | Kto | Kiedy |
|---|---|---|---|
| 1 | Test odbioru logów na wdrożonej funkcji (ADR-0003 Aneks A pkt 1) | qa / owner | po pierwszym wdrożeniu (P3-05) |
| 2 | Klucz wydań lub Play App Signing → SHA w aplikacji prod, ograniczenie klucza API prod, Play Integrity w prod (+ połączenie projektu w Play Console) | owner, mobile-dev | przed testami prod / Play |
| 3 | Wtyczka Gradle `google-services`, aliasy `.firebaserc`, `serviceAccount` w opcjach funkcji (SEC-20, nazwa `fn-ai-plan` – O2) | mobile-dev | przed P3-05 / testem P3-04 na urządzeniu |
| 4 | Indeksy i TTL Firestore (`firestore:indexes`) po rozstrzygnięciu O4 | dba / mobile-dev | przed P3-05 |
| 5 | `roles/run.invoker` dla `fn-budget` na usłudze `budgetGuard` | owner / steward | przy wdrożeniu P3-09 |
| 6 | Lektura CDPA, kontakty RODO, data governance i data residency Vertex (SEC-15 poz. 2–3, O1); buforowanie Vertex (O5) | owner; security | przed realnymi danymi |
| 7 | UID właściciela w `config/runtime.testUids` | owner (konsola) | po pierwszym logowaniu |
| 8 | Decyzja o przejściu z okresu próbnego na konto płatne (Upgrade) | owner | przed 2027-02-16 |
| 9 | Sekrety CI (GH-009), WIF (GH-010) | steward | po PR mobile-dev z wtyczką / przed automatycznym wdrażaniem |
| 10 | Lista osób z dostępem do konsol Firestore/Auth (ADR-0003 Aneks A pkt 4): obecnie tylko właściciel | owner | dokumentacja operacyjna |
| 11 | Propozycje: usunięcie kluczy Browser, wyłączenie nieużywanych API Hosting/Remote Config, limit wydatków Vertex (O3) | security / architect | P3-09 |
