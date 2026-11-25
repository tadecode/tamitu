# Pierwsze wdrożenie funkcji do `dev` – plan (TAM-84)

- Data: 2026-11-20 · Autor (rola): architect · Zadanie: TAM-84 (epik EP-INFRA)
- Dla: właściciela (wykonuje polecenia) i orkiestratora
- Podstawa: kod `backend/functions/src/` (stan `main` 0b68004), `backend/firebase.json`,
  `.github/workflows/deploy.yml`, `docs/security/review-SEC-17-iam.md`, runbook `.farm/runbooks/P3-03-firebase.md`,
  ADR-0002, ADR-0003, ADR-0011, ADR-0014, `docs/qa/QA-P3-04-DEV-2.md`.
- Stan chmury sprawdzony 2026-11-20 **tylko poleceniami odczytu** (`list`, `describe`, `get-iam-policy`). Niczego nie zmieniano.
- **Aktualizacja 2026-11-25 (TAM-103, architect):** wdrożenie `generatePlan` (TAM-90) – sekcja 2, 3.3, **5.2**
  (kroki), **5.3** (włączanie i wyłączanie AI w dev), **5.4** (przebieg 2026-11-25), sekcja 6. Źródła: wpis
  `.farm/log/2026-11-25/0820-mobile-dev-TAM-90.md`, recenzja i raport QA w PR #166. Bez zmian w chmurze.

> **Stan na 2026-11-25:** w `dev` działają `recordConsent` (TAM-84) i `generatePlan` (TAM-90, z modelem AI).
> Sekcje 1, 3.1–3.5 i 4 opisują pierwsze wdrożenie (`recordConsent`) i zostają jako historia; kroki dla
> `generatePlan` są w sekcji 5.2.

## 1. W skrócie

**Co i po co.** Wdrażamy do projektu `tamitu-dev-tadecode` **tylko jedną funkcję: `recordConsent`** (zapis
zgody). To wystarczy, żeby QA mogło na telefonie sprawdzić zapis zgody (QA-P3-04-DEV-2, TAM-34).
Pozostałe trzy funkcje czekają – nie są potrzebne do tego testu, a każda z nich ma jeszcze otwarte warunki.

**Kto.** Pierwsze wdrożenie robi **właściciel ręcznie ze swojego komputera** (jest Ownerem projektu).
Wdrożenie z CI (`deploy.yml`) na razie się nie nadaje – szczegóły w sekcji 4.3.

**Ile to kosztuje.** Praktycznie **0 zł** – wszystko mieści się w darmowych pulach Google (sekcja 7).

**Co trzeba zrobić przed wdrożeniem (3 rzeczy blokujące):**

| # | Co | Kto | Dlaczego |
|---|---|---|---|
| B1 | Nadać domyślnemu kontu Compute rolę `roles/cloudbuild.builds.builder` | właściciel (1 polecenie) | To konto **buduje** funkcję, a dziś nie ma żadnej roli – budowanie się nie uda |
| B2 | Poprawić `predeploy` w `backend/firebase.json`, żeby działał w Windows | mobile-dev (mały PR) | Obecny zapis `"$RESOURCE_DIR"` działa tylko w Linuksie/macOS; na Windows `firebase deploy` się wywróci |
| B3 | Dodać do repo plik `backend/functions/.env.tamitu-dev-tadecode` z `ENVIRONMENT=dev` i wyjątek w `.gitignore` | mobile-dev (ten sam PR co B2; decyzja właściciela O-TAM84-1: „W repo”) | Bez niego funkcja uzna, że działa w **prod** (zasada „fail-closed" w `config.ts`) |

App Check na telefonie testowym: decyzja właściciela – token debug dla QA (sekcja 3.4, O-TAM84-2).

## 2. Które funkcje wdrażamy

| Funkcja | Wdrażamy teraz? | Uzasadnienie |
|---|---|---|
| `recordConsent` | **TAK** | Jedyna potrzebna do testu zgody (SIGN-11, CONS-01, RECON-03, AIC-04). Kod gotowy (P3-04, testy zielone). Nie woła AI. Konto `fn-consent` ma potrzebne role i dostęp do sekretu. Zapisuje tylko dane kont testowych (dev = tylko dane testowe, ADR-0011 pkt 5). |
| `deleteAccount` | **NIE** (razem z P3-08) | Kod po sprawdzeniu tokenu zwraca `not_implemented` (P3-08) – w teście nic by nie dał. Konto `fn-account` ma dziś szeroką rolę `roles/firebaseauth.admin` (SEC-17 W-2 – do zawężenia **przed** wdrożeniem). Wdrożyć razem z P3-08 i po W-2. |
| `generatePlan` | **TAK (TAM-90, wdrożone 2026-11-25)** | Warunki O4-2, B-1, W-1 i TAM-93 spełnione przed wdrożeniem (sprawdził orkiestrator 2026-11-25). Zmienne AI w pliku `.env` (sekcja 3.3), kroki w sekcji 5.2, przebieg w 5.4. Poniżej – uzasadnienie z 2026-11-20, dlaczego czekała. **Historia (2026-11-20): NIE** (razem z P3-05). Kod P3-05 jest w `main` (PR #136, #138), ale bez zmiennych `AI_MODEL_ID` i `AI_LOCATION` funkcja odpowiada `ai_unavailable` przed rezerwacją limitu (fail-closed): nie woła Vertex AI, nie zapisuje `usage/{uid}` i nic nie kosztuje. Wdrożenie wystawiłoby publicznie funkcję działającą jako `fn-ai-plan`, która ma szeroką rolę `roles/aiplatform.user` (SEC-17 W-1). Spend cap 15 PLN chroni koszt, ale nie zastępuje B-1 (wyłączenie buforowania Vertex) i W-1. **Zanim ktoś ustawi zmienne AI** (P3-05-CFG, TAM-90), muszą być spełnione: **O4-2** (polityki TTL na `usage.expireAt` i `usage_global.expireAt` wdrożone w dev, bo od tej chwili funkcja zapisuje licznik D10), **B-1** (`disableCache=true`) i **W-1** (zawężenie roli `fn-ai-plan`), a także TAM-93 (komunikat o zwrocie próby w aplikacji zgodny z limitem 2 zwrotów na dobę). |
| `budgetGuard` | **NIE w dev** (nigdy) | ADR-0014 Aneks A: w `dev` nie ma `budgetGuard`, ochronę daje spend cap. W dev nie ma też tematu `budget-alerts` ani włączonego Eventarc – wdrożenie i tak by się nie udało albo włączyłoby dodatkowe API. |

Ważne: **nigdy** nie uruchamiać samego `firebase deploy` ani `firebase deploy --only functions` – to wdraża
wszystkie cztery funkcje (w tym `budgetGuard`), a samo `firebase deploy` także reguły i indeksy. Zawsze
`--only functions:<nazwa>` – jedna funkcja naraz (`functions:recordConsent` albo `functions:generatePlan`).

## 3. Gotowość kodu i konfiguracji

### 3.1 Kod funkcji (`backend/functions/src/index.ts`) – stan: gotowy

| Sprawdzenie | Wynik |
|---|---|
| `serviceAccount` w opcjach każdej funkcji (SEC-20) | OK – `serviceAccountFor()` daje `fn-consent@` (CLI dopisuje `<projekt>.iam.gserviceaccount.com`); żadna funkcja nie działa jako konto domyślne |
| Region | OK – `europe-west4` dla wszystkich funkcji |
| `maxInstances` | OK – callable 10, `budgetGuard` 1; `minInstances` nieustawione = 0 (brak kosztu w spoczynku) |
| Pamięć / czas | 512 MiB, 120 s – w porządku dla dev |
| App Check | sprawdzany w kodzie (`requireAppCheck`), włączony domyślnie; wyłącza go tylko `ENFORCE_APP_CHECK=false` |
| Dane realne | `ALLOW_REAL_DATA=true` w dev blokuje start funkcji (ADR-0011 pkt 5) – dobrze |
| Sekret | `UID_HASH_PEPPER` (`defineSecret`) – do skrótu UID w logach |
| Region Firestore | baza `(default)` w `europe-west4` – sprawdzone |

### 3.2 Pliki Firebase CLI

- `backend/firebase.json` – jest, źródło `functions`, `predeploy`: `npm ci` + `npm run build`.
  **Problem (B2):** polecenia używają `"$RESOURCE_DIR"`. Firebase CLI uruchamia je przez `cmd.exe` na Windows,
  który nie rozwija `$ZMIENNA` – `npm ci` szuka katalogu o nazwie `$RESOURCE_DIR` i kończy się błędem.
  Poprawka (mobile-dev, jedna linia, działa też w CI na Linuksie; CLI uruchamia `predeploy` z katalogu `backend`):
  ```json
  "predeploy": ["npm --prefix functions ci", "npm --prefix functions run build"]
  ```
- `.firebaserc` – **nie ma** i nie jest potrzebny: w każdym poleceniu podajemy `--project tamitu-dev-tadecode`
  (tak robi też `deploy.yml`). Mniejsze ryzyko pomyłki dev/prod niż alias domyślny.
- `firebase.json` → `ignore` pomija `test`, `node_modules`, `*.local` – w porządku.

### 3.3 Parametry środowiska (B3)

Funkcja czyta trzy zmienne (`config.ts`, wszystkie „fail-closed"):

| Zmienna | Wartość w dev | Co, jeśli brak |
|---|---|---|
| `ENVIRONMENT` | `dev` | funkcja uzna się za **prod** |
| `ENFORCE_APP_CHECK` | `true` (decyzja właściciela, sekcja 3.4) | `true` |
| `ALLOW_REAL_DATA` | `false` | `false` |

Firebase CLI przy wdrożeniu do projektu `X` czyta plik `backend/functions/.env.X`. Wartości **nie są
sekretami**. **Decyzja właściciela (2026-11-20, O-TAM84-1: „W repo”):** plik `backend/functions/.env.tamitu-dev-tadecode`
jest w repozytorium, a `.gitignore` (który dziś blokuje wszystkie `.env.*`) dostaje wyjątek
`!backend/functions/.env.tamitu-dev-tadecode`. Zmianę robi mobile-dev w tym samym PR-ze co poprawkę B2.
Treść pliku:
```
ENVIRONMENT=dev
ENFORCE_APP_CHECK=true
ALLOW_REAL_DATA=false
```
W pliku nigdy nie ma sekretów (sekrety tylko w Secret Managerze). Ten sam plik posłuży później wdrożeniom z CI.

**Zmienne modelu AI (TAM-90, 2026-11-25).** `generatePlan` czyta dodatkowo dwie zmienne (`ai.ts`, `parseAiConfig`,
też „fail-closed”):

| Zmienna | Wartość w dev | Co, jeśli brak lub zła wartość |
|---|---|---|
| `AI_MODEL_ID` | `gemini-3.1-flash-lite` (ADR-0001 Aneks C pkt 1; musi być na liście `ALLOWED_MODEL_IDS`) | `ai_unavailable` bez wywołania modelu i bez zużycia limitu |
| `AI_LOCATION` | `eu` (ADR-0001 Aneks B i C pkt 3; host `aiplatform.eu.rep.googleapis.com`; nigdy `global`) | jak wyżej |
| `AI_PROMPT_VERSION` | **nie ustawiamy** – domyślnie `plan-v1` | – |

**Stan pliku w repo (od PR #166):** trzy linie – `ENVIRONMENT=dev`, `AI_MODEL_ID=gemini-3.1-flash-lite`,
`AI_LOCATION=eu`. `ENFORCE_APP_CHECK` i `ALLOW_REAL_DATA` **nie są** w pliku i działają z wartości domyślnych
(`true` i `false`), czyli tak samo jak w tabeli wyżej. Treść pliku z 2026-11-20 (wyżej) to plan; obowiązuje stan z repo.

Zmienne `.env` decydują, **którym** modelem i gdzie funkcja może generować. To, **czy** w ogóle woła model, decyduje
dokument Firestore `config/runtime` (`aiEnabled`, `testUids`) – sekcja 5.3.

### 3.4 App Check na telefonie testowym

`recordConsent` odrzuca wywołanie bez ważnego tokenu App Check (`app_check_failed`). Aplikacja instalowana
z komputera (nie ze Sklepu Play) zwykle nie przejdzie Play Integrity, więc telefon potrzebuje **tokenu debug**.

- **Decyzja właściciela (2026-11-20, O-TAM84-2: „Token debug QA”):** w dev zostaje `ENFORCE_APP_CHECK=true`
  (dev zachowuje się jak prod), a QA dostaje token debug: nowy token „qa-phone" w konsoli Firebase → App Check →
  Manage debug tokens; wartość tylko w menedżerze haseł, build z `--dart-define=TAMITU_APP_CHECK_DEBUG_TOKEN=...`;
  po teście token usunąć (SEC-UIDLOG, rejestr D18).
- Odrzucona alternatywa: `ENFORCE_APP_CHECK=false` w dev (nie testowalibyśmy App Check).

### 3.5 Sekret `UID_HASH_PEPPER`

Odczyt z 2026-11-20: sekret ma **wersję 1 w stanie `enabled`** (czyli wartość już jest – wbrew notatce
„bez wartości"); dostęp `secretAccessor` mają `fn-consent`, `fn-account`, `fn-ai-plan`, nie ma `fn-budget` – zgodnie z SEC-17.

- Właściciel potwierdza, że wersja 1 to losowa wartość (min. 32 bajty), nie tymczasowa. Jeśli nie –
  dodać nową wersję i wyłączyć starą (sekcja 5, krok 1, wariant).
- Wartość **nigdy** w repo, logach ani czacie. Bez wersji sekretu Firebase CLI zatrzyma wdrożenie.

## 4. Uprawnienia i wymagania bezpieczeństwa

### 4.1 Kto wdraża i jakie ma uprawnienia

| Tożsamość | Potrzebuje | Stan (odczyt 2026-11-20) |
|---|---|---|
| Właściciel (wdrażający) | wdrożenie funkcji, `iam.serviceAccountUser` na `fn-consent` i na koncie budującym, ustawienie IAM usługi Cloud Run (`allUsers` → `run.invoker`) | **OK** – `roles/owner` obejmuje wszystko |
| Konto budujące = domyślne konto Compute (`<numer>-compute@developer…`) – potwierdzone `gcloud builds get-default-service-account` | `roles/cloudbuild.builds.builder` (zapis logów budowania, obrazów do Artifact Registry) | **BRAK – blokuje (B1).** Organizacja wymusza `iam.automaticIamGrantsForDefaultServiceAccounts` (dobrze – konto nie ma `roles/editor`), więc konto nie ma żadnej roli |
| Stare konto Cloud Build (`<numer>@cloudbuild…`) | – | ma `cloudbuild.builds.builder`, ale nie jest domyślnym kontem budującym; zostawiamy |
| `fn-consent` (funkcja w działaniu) | Firestore, odczyt użytkownika Auth, sekret | OK – `datastore.user`, `firebaseauth.viewer`, `secretAccessor` na sekrecie |
| Agent usługi Cloud Functions (`gcf-admin-robot`) | rola agenta | OK – `cloudfunctions.standardServiceAgent` |

B1 to dokładnie poprawka z SEC-17 W-5 („zamiast Editor – `cloudbuild.builds.builder`"), więc nie rozszerzamy
niczego ponad uzgodnione minimum. Konto Compute **nie** służy jako konto działania żadnej funkcji (SEC-20).

### 4.2 Wymagania z SEC-17 / SEC-31: co blokuje dev teraz, a co może poczekać

| Pozycja | Blokuje wdrożenie `recordConsent` w dev? | Kiedy |
|---|---|---|
| W-5 (konto Compute) | **Tak, częściowo** – brak `editor` sprawdzony (OK); brakuje `cloudbuild.builds.builder` → B1 | teraz |
| N-5 (`run.invoker`) | **Tak – kontrola po wdrożeniu**: callable `allUsers`, nic więcej | zaraz po wdrożeniu (sekcja 5, krok 6) |
| W-3 (poświadczenia Ownera w CLI na maszynie agentów) | Nie blokuje, ale **zalecane**: wdrożenie wykonuje właściciel; po sesji `gcloud auth revoke` i `firebase logout` | przy tym wdrożeniu |
| B-1 (buforowanie Vertex), W-1 (`fn-ai-plan`) | Nie – `generatePlan` nie jest wdrażany, AI nie jest wołane | przed P3-05 – **spełnione przed wdrożeniem `generatePlan` (2026-11-25)** |
| W-2 (`fn-account`) | Nie – `deleteAccount` nie jest wdrażany | przed P3-08 |
| B-2 (monitoring nadużyć Google), Ś-1 (zawężenie Firestore dla `fn-consent`), Ś-2, Ś-4, N-1…N-4, N-6, N-7 | Nie – dev ma tylko dane testowe | przed realnymi danymi / prod |
| W-4, Ś-3 (CI/WIF, role `ci-deployer`) | Nie – nie wdrażamy przez CI | przed wdrożeniem z CI (sekcja 4.3) |

### 4.3 Dlaczego nie przez CI (`deploy.yml`) tym razem

Workflow `deploy.yml` z WIF już istnieje (GH-010, wdrożył reguły i indeksy), ale do funkcji się nie nadaje:
1. opcja `functions` wdraża **wszystkie** funkcje, w tym `budgetGuard` (w dev zakazany) i `generatePlan`;
2. `ci-deployer` nie ma `iam.serviceAccountUser` na kontach `fn-*` ani na koncie Compute (sprawdzone – brak powiązań)
   → wdrożenie zakończy się błędem `actAs`;
3. `ci-deployer` ma `cloudfunctions.developer`, które nie pozwala ustawić `allUsers` jako wywołującego
   (Firebase CLI robi to dla callable) – SEC-17 Ś-3 przewiduje, że przy pierwszym wdrożeniu robi to właściciel;
4. tryb `--non-interactive` przy pierwszym wdrożeniu przerywa się na pytaniu o zasady czyszczenia obrazów.

Nowe zadanie dla Stewarda (po tym wdrożeniu): w `deploy.yml` opcja `functions:recordConsent` zamiast całego
`functions`, `iam.serviceAccountUser` dla `ci-deployer` tylko na potrzebnych kontach `fn-*` i na koncie Compute
(lub osobne konto budujące) – zgodnie z SEC-17 Ś-3 i W-5.

## 5. Kroki wdrożenia (właściciel, PowerShell)

Wszystkie polecenia dotyczą **wyłącznie** `tamitu-dev-tadecode`. Żadne nie zawiera sekretów.
Firebase CLI w wersji ≥ 15.34 (`firebase --version`), Node 22.

- 5.1 – pierwsze wdrożenie `recordConsent` (TAM-84, 2026-11-20; wykonane);
- 5.2 – wdrożenie `generatePlan` (TAM-90, 2026-11-25; wykonane, kroki do powtórzenia przy kolejnych wdrożeniach);
- 5.3 – włączanie i wyłączanie AI w dev (`config/runtime`);
- 5.4 – faktyczny przebieg wdrożenia `generatePlan` 2026-11-25.

### 5.1 `recordConsent` (TAM-84)

**Krok 0 – przygotowanie (raz)**
```powershell
$p = 'tamitu-dev-tadecode'
gcloud auth login            # konto właściciela
firebase login --reauth
cd C:\Repository\tamitu       # katalog na gałęzi main, po merge'u PR-a z B2 i B3
git pull
```

**Krok 1 – sekret (tylko sprawdzenie)**
```powershell
gcloud secrets versions list UID_HASH_PEPPER --project=$p     # oczekiwane: wersja w stanie enabled
```
Wariant, jeśli wersja 1 nie jest losowa: `firebase functions:secrets:set UID_HASH_PEPPER --project $p`
(CLI zapyta o wartość; wkleić losowe ≥ 32 bajty z menedżera haseł), potem
`gcloud secrets versions disable 1 --secret=UID_HASH_PEPPER --project=$p`.

**Krok 2 – B1: rola dla konta budującego**
```powershell
$build = gcloud builds get-default-service-account --project=$p --format="value(serviceAccountEmail)"
$build = $build -replace '^projects/[^/]+/serviceAccounts/', ''
gcloud projects add-iam-policy-binding $p --member="serviceAccount:$build" --role=roles/cloudbuild.builds.builder --condition=None
```
Wynik (bez numerów kont) – do runbooka P3-03, etap 5.

**Krok 3 – B3: parametry środowiska (plik z repo)**
```powershell
Get-Content backend\functions\.env.tamitu-dev-tadecode
```
Oczekiwane: `ENVIRONMENT=dev`, `ENFORCE_APP_CHECK=true` (decyzja O-TAM84-2), `ALLOW_REAL_DATA=false`.
Jeśli pliku nie ma – PR mobile-dev z B2/B3 nie jest jeszcze w `main`; **nie wdrażać** i nie tworzyć pliku ręcznie.

**Krok 4 – kontrola przed wdrożeniem**
```powershell
cd backend\functions; npm ci; npm run lint; npm run typecheck; npm test; cd ..\..
gcloud run services list --project=$p --region=europe-west4   # oczekiwane: pusto
```

**Krok 5 – wdrożenie tylko `recordConsent`**
```powershell
cd backend
firebase deploy --only functions:recordConsent --project tamitu-dev-tadecode
```
- Przy pytaniu o **cleanup policy** dla obrazów (Artifact Registry) – przyjąć **1 dzień** (domyślne). To
  ogranicza koszt przechowywania obrazów.
- Jeśli CLI zapyta o włączenie dodatkowego API (np. Eventarc) – **przerwać** (Ctrl+C) i zgłosić; dla
  `recordConsent` nie powinno być takiej potrzeby.
- Jeśli budowanie zgłosi brak uprawnień konta budującego – sprawdzić krok 2 (nie nadawać `roles/editor`).

**Krok 6 – kontrola po wdrożeniu**
```powershell
# a) funkcja działa jako fn-consent, w europe-west4, max 10 instancji, ENVIRONMENT=dev
gcloud functions describe recordConsent --region=europe-west4 --project=$p --format="yaml(state,serviceConfig.serviceAccountEmail,serviceConfig.maxInstanceCount,serviceConfig.environmentVariables)"
# b) tylko jedna usługa Cloud Run
gcloud run services list --project=$p --region=europe-west4
# c) N-5: wywołać może allUsers (wymóg protokołu callable; logowanie sprawdza kod) – i nic więcej
gcloud run services get-iam-policy recordconsent --region=europe-west4 --project=$p
# d) IAM projektu i sekretu bez nowych, nieoczekiwanych wpisów (porównać z sekcją 4.1)
gcloud projects get-iam-policy $p --flatten="bindings[].members" --format="table(bindings.role,bindings.members)"
gcloud secrets get-iam-policy UID_HASH_PEPPER --project=$p
# e) próba bez logowania – oczekiwany błąd "unauthenticated" (HTTP 401), żadnych danych
$url = gcloud functions describe recordConsent --region=europe-west4 --project=$p --format="value(url)"
try { Invoke-RestMethod -Method Post -Uri $url -ContentType 'application/json' -Body '{"data":{}}' } catch { $_.Exception.Response.StatusCode; $_.ErrorDetails.Message }
```
Oczekiwane: (a) `ACTIVE`, `fn-consent@…`, `10`, `ENVIRONMENT: dev`; (c) jedna rola `roles/run.invoker` dla `allUsers`.

**Krok 7 – logi bez danych osobowych**
```powershell
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="recordconsent"' --project=$p --freshness=1h --limit=20 --format=json
```
Sprawdzić: wpisy funkcji zawierają tylko `uidHash`, kod wyniku, rozmiar żądania – **bez** UID, e-maila,
tokenu, treści żądania. Logi żądań platformy mogą zawierać IP i user agent – to oczekiwane i opisane
w rejestrze (D11). Logi trafiają do kubełka `tamitu-logs` (`europe-west4`, 30 dni) przez sink `tamitu-eu-sink`.
Po teście QA na telefonie – ten sam odczyt jeszcze raz (już z prawdziwym wywołaniem).

**Krok 8 – zamknięcie sesji (SEC-17 W-3)**
```powershell
gcloud auth revoke    # konto właściciela
firebase logout
```
Następnie wpis (data, wynik kroków 6–7, bez adresów e-mail i numerów kont) do runbooka P3-03 i do
`docs/github-ops/log.md` (Steward/orkiestrator), a orkiestrator ponownie zleca QA-P3-04-DEV-2.

### 5.2 `generatePlan` (TAM-90)

**Co i po co.** `generatePlan` tworzy plan podróży modelem Gemini (Vertex AI, punkt `eu`). To jedyna funkcja, która
**kosztuje za każde wywołanie modelu** (ok. 1 grosz za plan), dlatego ma więcej kontroli niż `recordConsent`.
Wdrażamy **tylko** `generatePlan` – nigdy całe `functions` (poszedłby też `budgetGuard`, w dev zakazany).
Schemat jak w 5.1; uzupełniony o uwagi recenzji PR #166 (pełne kontrole IAM, odczyt `fn_error`, szybka blokada
w sekcji 6) i o krok `config/runtime` z raportu QA (krok 5).

**Warunki wstępne** (sprawdzone 2026-11-25; przy kolejnym wdrożeniu potwierdzić jednym spojrzeniem): TTL `ACTIVE`
na `usage.expireAt` i `usage_global.expireAt` (O4-2), `disableCache=true` w Vertex (B-1), `fn-ai-plan` tylko
z rolami `tamitu.vertexInvoker`, `tamitu.authUserReader`, `tamitu.fsUsageWriter` (W-1).

**Krok 0 – przygotowanie**
```powershell
$p = 'tamitu-dev-tadecode'
gcloud auth login            # konto właściciela
firebase login --reauth
cd C:\Repository\tamitu       # katalog na gałęzi main
git pull
```

**Krok 1 – plik środowiska (z repo)**
```powershell
Get-Content backend\functions\.env.tamitu-dev-tadecode
```
Oczekiwane: `ENVIRONMENT=dev`, `AI_MODEL_ID=gemini-3.1-flash-lite`, `AI_LOCATION=eu`, bez `AI_PROMPT_VERSION`
(sekcja 3.3). Brak linii AI = zmiany TAM-90 nie ma w `main`: **nie wdrażać** i nie dopisywać ręcznie.

**Krok 2 – kontrola przed wdrożeniem**
```powershell
cd backend\functions; npm ci; npm run lint; npm run typecheck; npm test; cd ..\..
gcloud run services list --project=$p --region=europe-west4   # pierwsze wdrożenie: tylko recordconsent
```

**Krok 3 – wdrożenie tylko `generatePlan`**
```powershell
cd backend
firebase deploy --only functions:generatePlan --project tamitu-dev-tadecode
```
- Cleanup policy dla obrazów: **1 dzień**.
- Pytanie o włączenie dodatkowego API: **przerwać** (Ctrl+C) i zgłosić.
- CLI może wypisać, że konto `fn-ai-plan` ma dostęp do sekretu `UID_HASH_PEPPER` (funkcja używa sekretu do skrótu UID
  w logach). To oczekiwane – dostęp nadano wcześniej (sekcja 3.5); kontrola 4d potwierdza, że nic nie doszło.

**Krok 4 – kontrola po wdrożeniu**
```powershell
# a) konto fn-ai-plan, europe-west4, max 10 instancji, zmienne ENVIRONMENT/AI_MODEL_ID/AI_LOCATION
gcloud functions describe generatePlan --region=europe-west4 --project=$p --format="yaml(state,serviceConfig.serviceAccountEmail,serviceConfig.maxInstanceCount,serviceConfig.environmentVariables)"
# b) usługi Cloud Run: recordconsent i generateplan (żadnej innej)
gcloud run services list --project=$p --region=europe-west4
# c) N-5: wywołać może allUsers (wymóg callable; logowanie, App Check i zgody sprawdza kod) – i nic więcej
gcloud run services get-iam-policy generateplan --region=europe-west4 --project=$p
# d) PEŁNA polityka IAM projektu i sekretu – bez nowych, nieoczekiwanych wpisów (porównać z SEC-17 sekcja 3)
gcloud projects get-iam-policy $p --flatten="bindings[].members" --format="table(bindings.role,bindings.members)"
gcloud secrets get-iam-policy UID_HASH_PEPPER --project=$p
# e) wywołanie bez logowania: oczekiwany "unauthenticated" (HTTP 401), bez wywołania modelu
$url = gcloud functions describe generatePlan --region=europe-west4 --project=$p --format="value(url)"
try { Invoke-RestMethod -Method Post -Uri $url -ContentType 'application/json' -Body '{"data":{}}' } catch { $_.Exception.Response.StatusCode; $_.ErrorDetails.Message }
```
Oczekiwane:
- (a) `ACTIVE`, `fn-ai-plan@…`, `10`, `ENVIRONMENT: dev`, `AI_MODEL_ID: gemini-3.1-flash-lite`, `AI_LOCATION: eu`;
- (c) jedna rola `roles/run.invoker` dla `allUsers`;
- (d) `fn-ai-plan` tylko z `tamitu.vertexInvoker`, `tamitu.authUserReader`, `tamitu.fsUsageWriter`; żadne inne konto
  (np. domyślne konto Compute) nie dostało nowej roli; na sekrecie `secretAccessor` mają tylko `fn-consent`,
  `fn-account`, `fn-ai-plan`. Każdy nowy wpis – zgłosić security, przed testem z telefonu;
- (e) `Unauthorized` / `unauthenticated`.

**Krok 5 – przed pierwszym testem: `config/runtime` w dev (właściciel, konsola)**
Bez tego kroku pierwsze wywołanie kończy się `test_data_only` albo `ai_unavailable` (bez kosztu, ale test jest
stracony – tak było 2026-11-25, sekcja 5.4). Ustawienie: sekcja 5.3, „Włączenie AI dla konta testowego”.

**Krok 6 – pierwszy test: 1 plan z telefonu**
Telefon testowy z tokenem debug App Check (sekcja 3.4), konto testowe z kroku 5, zgoda na AI udzielona w aplikacji.
Jeden krótki plan (np. 2 dni). Koszt: ok. 1 grosz (`gemini-3.1-flash-lite`); limit 25 wywołań na dobę, spend cap 15 PLN.

| Wynik | Znaczenie |
|---|---|
| plan na ekranie (EK-08) | działa |
| komunikat „Tworzenie planów jest chwilowo niedostępne” + w logu `test_data_only` | konta nie ma w `testUids` (sekcja 5.3) |
| ten sam komunikat + w logu `ai_unavailable` bez `configError` | `aiEnabled` nie jest `true` (sekcja 5.3) |
| `ai_unavailable` z `configError` | zmienne AI nie dotarły albo są złe – wróć do kroku 4a |
| `ai_busy` | przeciążenie modelu (ADR-0016) – spróbować później, to nie błąd wdrożenia |

**Krok 7 – logi bez danych osobowych (`fn_event` i `fn_error`)**
```powershell
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="generateplan" AND jsonPayload.message=("fn_event" OR "fn_error")' --project=$p --freshness=1h --limit=20 --format=json
```
Odczyt obejmuje także `fn_error`, bo tylko tam widać przyczynę nieudanej próby (`errorCode`, `configError`,
`stopReason`) – i tam też trzeba sprawdzić, że nie ma danych osobowych. Sprawdzić:
- pola tylko z listy w `backend/functions/src/logger.ts` (`fn`, `result`, `uidHash`, `outcome`, `errorCode`, `aiModel`,
  `aiLocation`, `modelVersion`, `promptVersion`, `tokensIn`/`tokensOut`/`tokensThought`, `billable`, `calls`,
  `stopReason`, `durationMs` itp.);
- **brak** UID, e-maila, tokenu, celu podróży, nazw miejsc z formularza, treści promptu i odpowiedzi modelu;
- przy udanym teście: `outcome=ok`, `calls=1`, `aiLocation=eu`, `promptVersion=plan-v1`, `billable=true`;
- w Firestore powstał dokument licznika w `usage` z `expireAt` (TTL), a `usage_global` ma licznik dnia.
Logi żądań platformy mogą mieć IP i user agent (oczekiwane, rejestr D11).

**Krok 8 – decyzja o AI i zamknięcie sesji**
- Jeśli w najbliższym czasie nie ma testów: **wyłączyć AI w dev** (`aiEnabled=false`, sekcja 5.3). Funkcja zostaje
  wdrożona, ale nie woła modelu i nic nie kosztuje.
- Token debug App Check z testu: zostawić na dalsze testy albo usunąć w konsoli (sekcja 3.4).
```powershell
gcloud auth revoke    # konto właściciela
firebase logout
```
Wynik (data, kroki 4–7, bez e-maili, numerów kont i UID) do runbooka P3-03 i do `docs/github-ops/log.md`.

### 5.3 Włączanie i wyłączanie AI w dev (`config/runtime`)

**Co i po co.** Dokument Firestore `config/runtime` w projekcie `tamitu-dev-tadecode` to **wyłącznik AI bez
wdrażania**. `generatePlan` czyta go przy **każdym** żądaniu, więc zmiana działa od następnego wywołania. Zmienia go
**tylko właściciel w konsoli Firebase** (2FA; ADR-0002 Aneks A pkt 7). Agenci go nie zmieniają.

Dwa pola decydują o wywołaniu modelu (kolejność sprawdzeń w `endpoints.ts`):

| Pole | Typ | Rola | Gdy nie pasuje |
|---|---|---|---|
| `testUids` | tablica tekstów (UID) | w dev funkcja przyjmuje tylko żądania z `testData=true` od kont z tej listy (ADR-0011 pkt 5, SEC-24) | `test_data_only` – przed limitem i przed modelem, 0 zł |
| `aiEnabled` | wartość logiczna (boolean) | główny wyłącznik AI | `ai_unavailable` (`slotReleased=true`) – przed limitem i przed modelem, 0 zł |

Brak dokumentu albo brak pola = bezpieczne wartości domyślne: `aiEnabled=false`, `testUids=[]` (`config.ts`).

**Włączenie AI dla konta testowego (przed pierwszym testem)**
1. Firebase Console → projekt `tamitu-dev-tadecode` → **Authentication → Users**: znaleźć konto testowe i skopiować
   **User UID** (kolumna UID; nie e-mail).
2. **Firestore Database → Data** → kolekcja `config` → dokument `runtime`:
   - pole `testUids` (typ **array**): dodać element typu **string** z tym UID (istniejących wpisów nie usuwać);
   - pole `aiEnabled` (typ **boolean**): `true`. Uwaga: tekst `"true"` (typ string) **nie** włącza AI – kod wymaga
     wartości logicznej.
3. Zapisać. Bez wdrażania i bez restartu funkcji.

UID konta testowego to dana osobowa (ADR-0002 Aneks A pkt 7, ADR-0011): wpisuje go **tylko właściciel w konsoli**.
**Nigdy** w repozytorium, dzienniku `.farm/log`, Jirze, Confluence, PR-ach ani w rozmowie z agentem. W raportach
pisać tylko „`testUids` ma N wpisów”.

**Wyłączenie AI w dev (zatrzymanie kosztów)**
1. Firestore → `config/runtime` → `aiEnabled` = `false` (boolean) → zapisać.
2. Od następnego żądania `generatePlan` odpowiada `ai_unavailable` **bez wywołania modelu i bez zużycia limitu**;
   aplikacja pokazuje komunikat „Tworzenie planów jest chwilowo niedostępne”. Funkcja zostaje wdrożona, więc
   ponowne włączenie to znowu `aiEnabled=true`.
3. Wpis w `testUids` może zostać (sam nic nie kosztuje). Usunąć go, gdy konto testowe przestaje być używane albo
   jest usuwane.
4. Sprawdzenie bez kosztu: odczytać pole w konsoli. Nie trzeba wołać funkcji.

| Potrzeba | Co zrobić | Szybkość | Koszt modelu po zmianie |
|---|---|---|---|
| Przerwa w testach, koniec dnia | `aiEnabled=false` | od następnego żądania | 0 |
| Podejrzany ruch, ktoś spoza zespołu woła funkcję | zdjąć `allUsers` z usługi `generateplan` (sekcja 6) | kilka sekund | 0, funkcja w ogóle nie odpowiada (403) |
| Koniec testów na dłużej | `aiEnabled=false`, a potem ewentualnie usunięcie funkcji (sekcja 6) | – | 0 |

Ochrony, które działają niezależnie od `aiEnabled`: limit 25 wywołań na dobę dla całej aplikacji (`usage_global`),
limit dzienny konta, spend cap Vertex AI 15 PLN, `maxInstances: 10`.

### 5.4 Przebieg wdrożenia `generatePlan` 2026-11-25

Wykonał właściciel ze swojego komputera według kroków z wpisu `0820-mobile-dev-TAM-90.md` (pierwowzór sekcji 5.2).
Bez numerów kont i UID.

| Etap | Wynik |
|---|---|
| Wdrożenie (`--only functions:generatePlan`) | udane. Firebase CLI sam sprawdził i potwierdził, że `fn-ai-plan` ma dostęp do sekretu `UID_HASH_PEPPER` (dostęp był nadany wcześniej, sekcja 3.5) |
| Kontrola po wdrożeniu | `ACTIVE`, konto `fn-ai-plan`, max **10** instancji, invoker: `allUsers` z `roles/run.invoker`; wywołanie bez logowania: **401** (`unauthenticated`, bez wywołania modelu) |
| Pierwsza próba z telefonu (QA) | `test_data_only`, bez wywołania modelu: w `config/runtime` lista `testUids` była pusta, a `aiEnabled=false`. Procedura nie miała tego kroku – dlatego dodany krok 5 i sekcja 5.3 |
| Poprawka | właściciel dopisał UID konta testowego do `testUids` i ustawił `aiEnabled=true` w konsoli |
| Druga próba – **pierwszy plan z AI** | plan na EK-08 po ok. 3 s; **1 wywołanie modelu**, **955** tokenów wejścia i **546** wyjścia (myślenie 0), `aiLocation=eu`, `promptVersion=plan-v1`; koszt ok. 1 grosza |
| Logi (`fn_event` + `fn_error`) | tylko pola z listy `logger.ts`, `uidHash` zamiast UID; bez e-maili, celu podróży i treści promptu/odpowiedzi (raport QA w PR #166) |

Nie sprawdzono jeszcze dokumentów `usage` i `usage_global` (krok 7, ostatni punkt) – opcjonalne zadanie QA, bez
wywołań modelu. Otwarte decyzje właściciela po teście: czy `aiEnabled=true` i token debug App Check zostają w dev.

## 6. Jak cofnąć

| Sytuacja | Polecenie | Skutek |
|---|---|---|
| Szybko zablokować wywołania (np. podejrzany ruch) | `gcloud run services remove-iam-policy-binding recordconsent --region=europe-west4 --project=$p --member=allUsers --role=roles/run.invoker` | funkcja zostaje, ale nikt z zewnątrz jej nie wywoła (HTTP 403); powrót: `add-iam-policy-binding` z tymi samymi parametrami |
| Wrócić do poprzedniej wersji kodu (po kolejnym wdrożeniu) | `gcloud run revisions list --service=recordconsent --region=europe-west4 --project=$p`, potem `gcloud run services update-traffic recordconsent --to-revisions=<poprzednia>=100 --region=europe-west4 --project=$p` | ruch na starą wersję w kilka sekund |
| Usunąć funkcję całkowicie | `firebase functions:delete recordConsent --region europe-west4 --project tamitu-dev-tadecode` | usuwa funkcję i usługę Cloud Run; dane zgód w Firestore zostają (to dane testowe) |
| **`generatePlan`: najszybsza blokada** (podejrzany ruch, niespodziewany koszt) | `gcloud run services remove-iam-policy-binding generateplan --region=europe-west4 --project=$p --member=allUsers --role=roles/run.invoker` | w kilka sekund nikt z zewnątrz nie wywoła funkcji (HTTP 403), więc nie ma też wywołań modelu; powrót: `add-iam-policy-binding` z tymi samymi parametrami. Bez zmian w repo i bez wdrażania |
| `generatePlan`: wyłączyć samo AI, funkcja odpowiada | `config/runtime.aiEnabled=false` w konsoli (sekcja 5.3) | od następnego żądania `ai_unavailable` bez modelu i bez zużycia limitu |
| `generatePlan`: wrócić do poprzedniej wersji kodu | jak wyżej dla `recordConsent`, usługa `generateplan` | ruch na starą wersję w kilka sekund |
| `generatePlan`: usunąć funkcję | `firebase functions:delete generatePlan --region europe-west4 --project tamitu-dev-tadecode` | usuwa funkcję i usługę Cloud Run; liczniki `usage` wygasną same (TTL) |
| Cofnąć B1 | `gcloud projects remove-iam-policy-binding $p --member="serviceAccount:$build" --role=roles/cloudbuild.builds.builder --condition=None` | kolejne wdrożenia funkcji przestaną się budować |

## 7. Koszt (szacunek)

Darmowe pule Google są liczone miesięcznie na konto rozliczeniowe; `europe-west4` należy do tańszej grupy
regionów (tier 1). Ceny i pule – wg cennika Google na dzień wdrożenia (do potwierdzenia przy fakturze).

| Usługa | Zużycie w teście (szacunek) | Darmowa pula / mies. | Koszt |
|---|---|---|---|
| Cloud Run (funkcja) | dziesiątki–setki wywołań, każde < 1 s; 0 instancji w spoczynku | 2 mln żądań, 180 tys. vCPU-s, 360 tys. GiB-s | 0 zł |
| Cloud Build | 1–3 budowania × ok. 2–4 min | 2 500 min budowania | 0 zł |
| Artifact Registry | 1 obraz (ok. 0,2–0,4 GB), czyszczenie po 1 dniu | 0,5 GB | 0 zł (w najgorszym razie grosze) |
| Secret Manager | 1 wersja, dostęp przy uruchomieniu instancji | 6 wersji, 10 tys. odczytów | 0 zł |
| Firestore | kilka–kilkadziesiąt zapisów | 20 tys. zapisów, 50 tys. odczytów dziennie | 0 zł |
| Cloud Logging | kilka MB | 50 GiB na projekt | 0 zł |
| Vertex AI | `recordConsent`: **brak wywołań**. `generatePlan` (od 2026-11-25): ok. 1 grosz za plan; pułap: 25 wywołań na dobę i spend cap 15 PLN; 0 zł przy `aiEnabled=false` | – | grosze |

**Razem: ~0 zł.** Budżet dev 20 PLN z alertami działa dalej. Uwaga: spend cap 15 PLN obejmuje tylko
Vertex AI – nie chroni Cloud Run/Functions (świadoma decyzja ADR-0014 Aneks A pkt 1); tu ochroną są
`maxInstances: 10`, darmowe pule i alerty budżetu.

## 8. Ryzyka

| Ryzyko | Prawdopodobieństwo / skutek | Co robimy |
|---|---|---|
| Funkcja publiczna (`allUsers`) – ktoś z internetu ją wywołuje | średnie / mały (koszt ~0, odrzucenie przed zapisem: brak tokenu → `unauthenticated`, brak App Check → `app_check_failed`) | `maxInstances: 10`, alerty budżetu, szybka blokada (sekcja 6) |
| Wdrożenie „za dużo" (wszystkie funkcje lub reguły) przez pomyłkę w poleceniu | niskie / średni (`budgetGuard`, `generatePlan` z szerokimi rolami) | tylko `--only functions:recordConsent`; kontrola 6b |
| Funkcja działa jako `prod` (brak pliku `.env`) | niskie po B3 (plik w repo) / mały (zła etykieta środowiska) | krok 3, kontrola 6a |
| Firebase CLI sam dopisze uprawnienia (np. dostęp do sekretu, rola dla konta) | niskie / mały | kontrola 6d; każde nowe powiązanie – zgłosić security |
| Poświadczenia Ownera zostają na komputerze, na którym pracują agenci (W-3) | średnie / wysoki (dostęp do prod) | krok 8 |
| `fn-consent` ma szerszą rolę Firestore niż potrzeba (Ś-1) | niskie / mały w dev (tylko dane testowe) | poprawka przed realnymi danymi (SEC-31) |
| Obrazy w Artifact Registry rosną | niskie / mały | cleanup policy 1 dzień (krok 5) |

## 9. Później (poza TAM-84)

- ~~`generatePlan` – z P3-05; zmienne AI dopiero po O4-2, B-1 i W-1 (sekcja 2); ten sam schemat (`--only functions:generatePlan`).~~
  **Zrobione 2026-11-25 (TAM-90)** – sekcja 5.2–5.4.
- `deleteAccount` – z P3-08, po W-2.
- `budgetGuard` – tylko w prod (P3-09), z `run.invoker` dla `fn-budget` i bez `allUsers` (N-5).
- Wdrożenia z CI – po zadaniu dla Stewarda z sekcji 4.3.
- Prod – osobny plan, po przejściu wszystkich punktów SEC-17 „przed realnymi danymi".
