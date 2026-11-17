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
| 4 | Kubełek logów UE 30 dni, sink, wykluczenie `_Default` | – | | |
| 5 | Konta usług `fn-ai`, `fn-consent`, `fn-account`, `fn-budget` | – | | |
| 6 | Auth (tylko Google), aplikacje Android, SHA-1/SHA-256 | – | | |
| 7 | App Check (Play Integrity), tokeny debug poza repo | – | | |
| 8 | Firestore Native, reguły `deny all`, `config/runtime` | – | | |
| 9 | Vertex AI API, warunki przetwarzania danych (właściciel) | – | | |
| 10 | `google-services.json` lokalnie i w CI | – | | |

## Szczegóły etapów

### Etap 0 – narzędzia
- Google Cloud CLI (Windows): instalator ze strony cloud.google.com/sdk/docs/install, potem `gcloud init` (logowanie w przeglądarce).
- Firebase CLI: `npm install -g firebase-tools`, potem `firebase login`.
- `keytool`: `"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"`.
- Konto Google TadeCode: 2FA włączone (najlepiej klucz sprzętowy, T17).

## Czego nie zrobiono / do zrobienia później
- Test odbioru logów (ADR-0003 Aneks A pkt 1) – po pierwszym wdrożeniu funkcji.

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
