# Pierwsze wdrożenie funkcji do `dev` – plan (TAM-84)

- Data: 2026-11-20 · Autor (rola): architect · Zadanie: TAM-84 (epik EP-INFRA)
- Dla: właściciela (wykonuje polecenia) i orkiestratora
- Podstawa: kod `backend/functions/src/` (stan `main` 0b68004), `backend/firebase.json`,
  `.github/workflows/deploy.yml`, `docs/security/review-SEC-17-iam.md`, runbook `.farm/runbooks/P3-03-firebase.md`,
  ADR-0002, ADR-0003, ADR-0011, ADR-0014, `docs/qa/QA-P3-04-DEV-2.md`.
- Stan chmury sprawdzony 2026-11-20 **tylko poleceniami odczytu** (`list`, `describe`, `get-iam-policy`). Niczego nie zmieniano.

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
| B3 | Utworzyć lokalnie plik `backend/functions/.env.tamitu-dev-tadecode` z `ENVIRONMENT=dev` | właściciel (lub mały PR, pytanie O-TAM84-1) | Bez niego funkcja uzna, że działa w **prod** (zasada „fail-closed" w `config.ts`) |

App Check na telefonie testowym: decyzja właściciela – token debug dla QA (sekcja 3.4, O-TAM84-2).

## 2. Które funkcje wdrażamy

| Funkcja | Wdrażamy teraz? | Uzasadnienie |
|---|---|---|
| `recordConsent` | **TAK** | Jedyna potrzebna do testu zgody (SIGN-11, CONS-01, RECON-03, AIC-04). Kod gotowy (P3-04, testy zielone). Nie woła AI. Konto `fn-consent` ma potrzebne role i dostęp do sekretu. Zapisuje tylko dane kont testowych (dev = tylko dane testowe, ADR-0011 pkt 5). |
| `deleteAccount` | **NIE** (razem z P3-08) | Kod po sprawdzeniu tokenu zwraca `not_implemented` (P3-08) – w teście nic by nie dał. Konto `fn-account` ma dziś szeroką rolę `roles/firebaseauth.admin` (SEC-17 W-2 – do zawężenia **przed** wdrożeniem). Wdrożyć razem z P3-08 i po W-2. |
| `generatePlan` | **NIE** (razem z P3-05) | Dziś to „zaślepka" (`stubModel` → `not_implemented`), więc nie woła Vertex AI i nic nie kosztuje – ale też nic nie daje. Wdrożenie wystawiłoby publicznie funkcję działającą jako `fn-ai-plan`, która ma szeroką rolę `roles/aiplatform.user` (SEC-17 W-1). Spend cap 15 PLN chroni koszt, ale nie zastępuje B-1 (wyłączenie buforowania Vertex) i W-1. Wdrożyć z P3-05, po: B-1 (`disableCache=true`), W-1, ARCH-01-RUN (wybór modelu). |
| `budgetGuard` | **NIE w dev** (nigdy) | ADR-0014 Aneks A: w `dev` nie ma `budgetGuard`, ochronę daje spend cap. W dev nie ma też tematu `budget-alerts` ani włączonego Eventarc – wdrożenie i tak by się nie udało albo włączyłoby dodatkowe API. |

Ważne: **nigdy** nie uruchamiać samego `firebase deploy` ani `firebase deploy --only functions` – to wdraża
wszystkie cztery funkcje (w tym `budgetGuard`), a samo `firebase deploy` także reguły i indeksy. Zawsze
`--only functions:recordConsent`.

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
sekretami**, ale `.gitignore` blokuje wszystkie pliki `.env.*`, więc dziś plik trzeba utworzyć lokalnie
(polecenie w sekcji 5, krok 3). Na stałe lepiej mieć go w repo – pytanie O-TAM84-1.

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
| B-1 (buforowanie Vertex), W-1 (`fn-ai-plan`) | Nie – `generatePlan` nie jest wdrażany, AI nie jest wołane | przed P3-05 |
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

**Krok 0 – przygotowanie (raz)**
```powershell
$p = 'tamitu-dev-tadecode'
gcloud auth login            # konto właściciela
firebase login --reauth
cd C:\Repository\tamitu       # katalog na gałęzi main, po merge'u poprawki B2
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

**Krok 3 – B3: parametry środowiska (plik lokalny, ignorowany przez git)**
```powershell
Set-Content -Encoding ascii backend\functions\.env.tamitu-dev-tadecode "ENVIRONMENT=dev`nENFORCE_APP_CHECK=true`nALLOW_REAL_DATA=false"
```
(`ENFORCE_APP_CHECK=true` – decyzja właściciela O-TAM84-2.)

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

## 6. Jak cofnąć

| Sytuacja | Polecenie | Skutek |
|---|---|---|
| Szybko zablokować wywołania (np. podejrzany ruch) | `gcloud run services remove-iam-policy-binding recordconsent --region=europe-west4 --project=$p --member=allUsers --role=roles/run.invoker` | funkcja zostaje, ale nikt z zewnątrz jej nie wywoła (HTTP 403); powrót: `add-iam-policy-binding` z tymi samymi parametrami |
| Wrócić do poprzedniej wersji kodu (po kolejnym wdrożeniu) | `gcloud run revisions list --service=recordconsent --region=europe-west4 --project=$p`, potem `gcloud run services update-traffic recordconsent --to-revisions=<poprzednia>=100 --region=europe-west4 --project=$p` | ruch na starą wersję w kilka sekund |
| Usunąć funkcję całkowicie | `firebase functions:delete recordConsent --region europe-west4 --project tamitu-dev-tadecode` | usuwa funkcję i usługę Cloud Run; dane zgód w Firestore zostają (to dane testowe) |
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
| Vertex AI | **brak wywołań** | – | 0 zł |

**Razem: ~0 zł.** Budżet dev 20 PLN z alertami działa dalej. Uwaga: spend cap 15 PLN obejmuje tylko
Vertex AI – nie chroni Cloud Run/Functions (świadoma decyzja ADR-0014 Aneks A pkt 1); tu ochroną są
`maxInstances: 10`, darmowe pule i alerty budżetu.

## 8. Ryzyka

| Ryzyko | Prawdopodobieństwo / skutek | Co robimy |
|---|---|---|
| Funkcja publiczna (`allUsers`) – ktoś z internetu ją wywołuje | średnie / mały (koszt ~0, odrzucenie przed zapisem: brak tokenu → `unauthenticated`, brak App Check → `app_check_failed`) | `maxInstances: 10`, alerty budżetu, szybka blokada (sekcja 6) |
| Wdrożenie „za dużo" (wszystkie funkcje lub reguły) przez pomyłkę w poleceniu | niskie / średni (`budgetGuard`, `generatePlan` z szerokimi rolami) | tylko `--only functions:recordConsent`; kontrola 6b |
| Funkcja działa jako `prod` (brak pliku `.env`) | średnie bez B3 / mały (zła etykieta środowiska) | krok 3, kontrola 6a |
| Firebase CLI sam dopisze uprawnienia (np. dostęp do sekretu, rola dla konta) | niskie / mały | kontrola 6d; każde nowe powiązanie – zgłosić security |
| Poświadczenia Ownera zostają na komputerze, na którym pracują agenci (W-3) | średnie / wysoki (dostęp do prod) | krok 8 |
| `fn-consent` ma szerszą rolę Firestore niż potrzeba (Ś-1) | niskie / mały w dev (tylko dane testowe) | poprawka przed realnymi danymi (SEC-31) |
| Obrazy w Artifact Registry rosną | niskie / mały | cleanup policy 1 dzień (krok 5) |

## 9. Później (poza TAM-84)

- `generatePlan` – z P3-05, po B-1, W-1, ARCH-01-RUN; ten sam schemat (`--only functions:generatePlan`).
- `deleteAccount` – z P3-08, po W-2.
- `budgetGuard` – tylko w prod (P3-09), z `run.invoker` dla `fn-budget` i bez `allUsers` (N-5).
- Wdrożenia z CI – po zadaniu dla Stewarda z sekcji 4.3.
- Prod – osobny plan, po przejściu wszystkich punktów SEC-17 „przed realnymi danymi".
