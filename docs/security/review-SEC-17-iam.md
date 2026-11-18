# SEC-17: przegląd IAM środowisk dev/prod po P3-03 + O5 (buforowanie Vertex AI)

- Data: 2026-11-18 · Autor (rola): security · Zadanie: SEC-17 (T28), pytanie O5, SEC-15 poz. 4
- Podstawa: `.farm/runbooks/P3-03-firebase.md` (etapy 4–10), `.farm/log/2026-11-18/0011-orchestrator-P3-03.md`,
  `.farm/requests/GH-010-wif-deploy.md`, ADR-0001 (pkt 5, SEC-15), ADR-0002 (Aneks A pkt 6), ADR-0003 (Aneks A),
  kod `backend/functions/src/` (stan `main` 0a111ff), `docs/security/personal-data-register.md` v0.3.
- Metoda: przegląd dokumentacji konfiguracji i kodu. **Security nie miał dostępu do konsoli ani `gcloud`** –
  stan w chmurze przyjęty z runbooka; punkty oznaczone „sprawdzić" wymagają odczytu przez właściciela
  (polecenia podane). Żadnych zmian w chmurze nie wykonano.
- To nie jest porada prawna. Punkty [PRAWNIK] / [WŁAŚCICIEL] wymagają decyzji człowieka.

## 1. Podsumowanie

| Poziom | Liczba | Kiedy usunąć |
|---|---|---|
| Bloker | 2 | B-1 przed pierwszym wywołaniem Vertex AI (P3-05); B-2 przed realnymi danymi (`allowRealData=true`) |
| Wysoka | 5 | przed pierwszym wdrożeniem z Vertex (P3-05) / przed GH-010 |
| Średnia | 4 | przed realnymi danymi lub przed prod |
| Niska | 8 | porządkowe, przy okazji |

Werdykt: **konfiguracja P3-03 jest poprawna co do zasady** (konto per funkcja, brak kluczy JSON wymuszony
zasadą organizacji, sekret z dostępem na poziomie sekretu, `fn-budget` bez Auth i sekretu, Firestore `deny all`,
logi w UE). Role predefiniowane są jednak szersze niż minimum z ADR-0002 Aneks A pkt 6 (W-1, W-2, Ś-1).
Pierwsze wdrożenie funkcji **bez wywołań Vertex** (stub modelu) i z danymi syntetycznymi może iść przed
poprawkami W-1..W-2; wywołanie Vertex – dopiero po B-1 i W-1.

Co jest dobrze (nie zmieniać):
- `iam.disableServiceAccountKeyCreation` egzekwowane; 0 kluczy zarządzanych przez użytkownika.
- `secretAccessor` na sekrecie `UID_HASH_PEPPER` (nie na projekcie), replikacja tylko `europe-west4`; `fn-budget` bez dostępu.
- `fn-budget` bez ról Auth (zgodnie z Aneksem A pkt 6).
- Tokeny debug App Check tylko w dev, wartości poza repo; brak tokenów w prod.
- `_Default` wyłączony, kubełek `tamitu-logs` 30 dni w `europe-west4`; brak Data Access audit logs.

## 2. Ustalenia

### Blokery

**B-1. Domyślne buforowanie danych Gemini (implicit caching) zapisuje dane na dysku do 24 h – wyłączyć w dev i prod (O5).**
- Stan: wg aktualnej dokumentacji Google buforowanie jest **domyślnie włączone** dla obsługiwanych modeli Gemini
  i ma dwie warstwy: w pamięci (wejścia, wyjścia, dane pochodne; region obsługujący żądanie) oraz **trwałą**
  („durable": reprezentacje pochodne wejść, **przechowywane w spoczynku**, szyfrowanie domyślne Google, bez CMEK).
  Obie warstwy: usunięcie najpóźniej po 24 h, zakres – tylko nasz projekt, nieużywane do trenowania (źródła 1, 2).
- Rejestr D6 i ADR zakładały „w pamięci, do 24 h" – to już nieaktualne (dochodzi zapis w spoczynku).
  Sprzeczne z D6 („po naszej stronie brak zapisu"; polityka nie może obiecywać braku zapisu u dostawcy) i z S5.
- Poprawka (właściciel, oba projekty, **przed pierwszym wywołaniem Vertex**): wyłączyć całe buforowanie
  (`disableCache: true` wyłącza warstwę w pamięci i trwałą; ustawienie projektu dotyczy wszystkich regionów).
  Wymaga roli `roles/aiplatform.admin` (Owner ją obejmuje). Polecenie w sekcji 4.1.
- Uzupełnienie w kodzie (P3-05, mobile-dev; do wymagań przeglądu PR): nie tworzyć jawnych cache
  (`cachedContents`), nie włączać „request-response logging" (BigQuery), nie używać groundingu Google
  Search (Google przechowuje zapytania do 3 dni) ani Google Maps (prompt i wynik 30 dni) – obu nie da się
  wyłączyć (źródło 1). Rola niestandardowa z W-1 technicznie blokuje tworzenie jawnych cache przez `fn-ai-plan`.
- Koszt (zasada 10): utrata zniżki za trafienia w cache niejawny. Prompt ~1 000 tokenów wejścia, plany
  spersonalizowane – wpływ pomijalny; do odnotowania w `docs/architecture/costs.md` (architect).

**B-2. Monitoring nadużyć: Google może zapisywać prompty do 90 dni – nie da się tego wyłączyć po naszej stronie [WŁAŚCICIEL][PRAWNIK].**
- Stan: dla modeli Google na Vertex AI prompty **mogą być logowane** (gdy klasyfikatory oznaczą możliwe
  naruszenie zasad), przechowywane **do 90 dni** w regionie/multiregionie projektu, bez CMEK. Dotyczy klientów,
  których korzystanie z Google Cloud regulują **Google Cloud Platform Terms of Service** (warunki online);
  klienci z umową **Google Cloud Master Agreement** są domyślnie wyłączeni (źródło 3). TadeCode korzysta
  z konta rozliczeniowego w okresie próbnym, akceptacja warunków w konsoli – najpewniej warunki online
  (do potwierdzenia przez właściciela). Strona nie opisuje trybu wniosku o wyjątek dla modeli Google.
- Skutek: SEC-15 poz. 4 nie może być „potwierdzona" jako brak retencji. Wg ADR-0001 Aneks A pkt 1(a) wymagana
  jest **jawna decyzja właściciela z oceną ryzyka** albo zmiana podstawy umownej (Master Agreement – rozmowa
  z Google; poza zasięgiem MVP).
- Poprawka: (1) właściciel potwierdza rodzaj umowy (konsola → Billing / warunki); (2) wpis w rejestrze D6
  (zrobione w tym PR – v0.4) i w polityce prywatności/zgodzie AI („dostawca może przechowywać treść
  zapytania do 90 dni wyłącznie w celu wykrywania nadużyć"); (3) decyzja właściciela przy SEC-15;
  (4) [PRAWNIK]: czy to mieści się w CDPA i jak opisać w polityce. **Bloker tylko dla `allowRealData=true`.**

### Wysoka

**W-1. `fn-ai-plan`: `roles/aiplatform.user` jest dużo szersza niż „wywołanie modelu".**
- Rola pozwala m.in. tworzyć zadania (custom jobs), punkty końcowe, zbiory danych, jawne cache i konfigurację
  logowania żądań. Przejęcie `generatePlan` (np. podatna zależność) = uruchamianie płatnych zasobów GPU/TPU
  i ominięcie B-1. Dokumentacja Vertex wskazuje uprawnienie do wysyłania promptów:
  `aiplatform.endpoints.predict` (źródło 4) i zaleca role niestandardowe.
- Poprawka: rola niestandardowa `tamitu.vertexInvoker` = `aiplatform.endpoints.predict` w obu projektach,
  przypisana `fn-ai-plan`; usunąć `roles/aiplatform.user` (sekcja 4.2). Test w dev przy P3-05: jeśli
  `PERMISSION_DENIED` wskaże inne uprawnienie, **dopisać je do roli niestandardowej**, nie wracać do `aiplatform.user`.

**W-2. `fn-account`: `roles/firebaseauth.admin` pozwala zmieniać konfigurację Auth.**
- Rola obejmuje `firebaseauth.*`: m.in. `configs.update` (włączenie innych dostawców logowania, np.
  e-mail/anonimowe – sprzeczne z ADR-0004), `configs.getSecret`, `users.create`, `users.update`, `users.sendEmail`
  (źródło 5). `deleteAccount` potrzebuje tylko `users.get` (weryfikacja `checkRevoked`) i `users.delete`.
- Poprawka: rola niestandardowa `tamitu.authUserDeleter` = `firebaseauth.users.get`, `firebaseauth.users.delete`;
  zamiast `roles/firebaseauth.admin` (sekcja 4.2). Test E2E usuwania konta (SEC-07) w dev potwierdza wystarczalność.

**W-3. Trwałe poświadczenia Owner w CLI na maszynie, na której pracują agenci.**
- Etapy 3–5, 8, 10 wykonano „z terminala za zgodą właściciela": `gcloud`/`firebase` są zalogowane kontem
  właściciela (Owner obu projektów, w tym prod). Token odświeżania leży w profilu użytkownika i jest dostępny
  dla każdego procesu tej maszyny, w tym sesji agentów. ADR-0003: „agenci i deweloperzy nie mają poświadczeń prod".
- Poprawka (właściciel): (a) po zakończeniu sesji administracyjnej `gcloud auth revoke <konto>` i `firebase logout`
  (logowanie od nowa przy następnej operacji); (b) w Cloud Identity/Workspace ustawić dla Google Cloud
  **częstotliwość ponownego uwierzytelnienia** (Admin console → Security → Google Cloud session control,
  np. 8–16 h, z kluczem sprzętowym); (c) operacje w prod – tylko polecenia czytane i uruchamiane przez
  właściciela; agenci przygotowują polecenia, nie wykonują ich w prod. Do zapisania w dokumentacji
  operacyjnej (ADR-0003 Aneks A pkt 4).

**W-4. WIF (GH-010): warunek na nazwie repozytorium i gałęzi jest za słaby dla prod.**
- `assertion.repository == 'tadecode/tamitu'` opiera się na nazwie (zmiana nazwy organizacji/repo, ponowne
  użycie nazwy); bez `job_workflow_ref` token prod może uzyskać **dowolny workflow** uruchomiony na `main`
  lub w środowisku `prod`. Dla dev warunek dopuszcza każdą gałąź (w tym gałęzie agentów) i każdy workflow.
- Poprawka (Steward, przy realizacji GH-010):
  - mapowanie: `google.subject=assertion.sub`, `attribute.repository_id`, `attribute.repository_owner_id`,
    `attribute.ref`, `attribute.environment`, `attribute.workflow=assertion.job_workflow_ref`;
  - warunek **dev**: `assertion.repository_id=='<ID>' && assertion.repository_owner_id=='<ID_ORG>' && assertion.ref=='refs/heads/main'`;
  - warunek **prod**: jak dev **oraz** `assertion.environment=='prod' && assertion.job_workflow_ref=='tadecode/tamitu/.github/workflows/deploy.yml@refs/heads/main'`;
  - `roles/iam.workloadIdentityUser` na `ci-deployer` tylko dla `principal://…/subject/repo:tadecode/tamitu:environment:prod`
    (prod) lub `principalSet://…/attribute.repository_id/<ID>` (dev) – **nie** dla całej puli (`/*`);
  - GitHub: środowisko `prod` z wymaganym zatwierdzeniem właściciela i regułą „deployment branches: main";
    workflow bez `pull_request_target`; `permissions: id-token: write` tylko w zadaniu wdrożenia.
  - ID repo i organizacji (liczby, nie sekrety): `gh api repos/tadecode/tamitu --jq '.id, .owner.id'`.

**W-5. Domyślne konta usług projektu – sprawdzić, czy nie mają `roles/editor`; nie dawać nikomu `actAs` na nich.**
- Dla nowych projektów Google domyślnie nadaje kontu Compute Engine (`<numer>-compute@developer…`)
  rolę Editor, chyba że organizacja egzekwuje `iam.automaticIamGrantsForDefaultServiceAccounts`. To konto
  służy też jako domyślne konto budowania Cloud Functions 2. gen. Funkcja wdrożona bez `serviceAccount`
  (SEC-20) dostałaby Editor.
- Poprawka (właściciel, odczyt + ewentualna zmiana; sekcja 4.4): jeśli konto Compute ma `roles/editor`, zastąpić je
  `roles/cloudbuild.builds.builder` (wymagane do budowania funkcji), ewentualnie `roles/logging.logWriter`
  i `roles/artifactregistry.writer`. `ci-deployer` (GH-010) **nie dostaje** `iam.serviceAccountUser` na koncie
  Compute – wtedy wdrożenie bez `serviceAccount` kończy się błędem (techniczne wymuszenie SEC-20).

### Średnia

**Ś-1. `roles/datastore.user` daje każdej funkcji pełny zapis i usuwanie całej bazy.**
- IAM Firestore nie rozróżnia kolekcji, ale rozróżnia operacje. Kod: `recordConsent` czyta `config/runtime`
  i zgody, tworzy dokument (`tx.create`) – nigdy nie nadpisuje ani nie usuwa; `generatePlan` czyta i zapisuje
  `usage*`; `budgetGuard` aktualizuje `config/runtime`; usuwa tylko `deleteAccount`.
- Poprawka (przed realnymi danymi; sekcja 4.2): role niestandardowe bez `datastore.entities.delete`:
  - `tamitu.fsConsentWriter` (`fn-consent`): `datastore.entities.get`, `.list`, `.create` – **bez `update`**:
    przejęta funkcja nie zmieni istniejących dowodów zgód (integralność D3);
  - `tamitu.fsUsageWriter` (`fn-ai-plan`): `get`, `list`, `create`, `update`;
  - `tamitu.fsConfigUpdater` (`fn-budget`): `get`, `update`;
  - `fn-account`: `roles/datastore.user` bez zmian (potrzebuje `delete`, `list` dla `recursiveDelete`).
  Uprawnienia transakcji/odczytu metadanych potwierdzić testem w dev (`PERMISSION_DENIED` podaje brakujące
  uprawnienie); pełną listę roli predefiniowanej: `gcloud iam roles describe roles/datastore.user`.

**Ś-2. `roles/firebaseauth.viewer` (`fn-ai-plan`, `fn-consent`) – szersza niż `users.get`.**
- Rola zawiera `firebaseauth.users.get`, ale też `firebaseauth.configs.get`, `firebase.clients.list`,
  `resourcemanager.projects.list` (źródło 5). Nie zawiera `users.list` ani `configs.getSecret` – ryzyko niewielkie.
- Poprawka (razem z W-2, jeden wysiłek): rola `tamitu.authUserReader` = `firebaseauth.users.get` dla obu kont.

**Ś-3. Role `ci-deployer` (GH-010) do zawężenia przed użyciem w prod.**
- Efektywne uprawnienia CI = suma ról `fn-*` (CI może wdrożyć kod działający jako `fn-account`). Ryzyko
  rezydualne akceptowalne tylko przy W-4.
- `roles/run.admin` pozwala zmieniać IAM usług (np. upublicznić `budgetguard`); `roles/artifactregistry.writer`
  i `roles/cloudbuild.builds.editor` są używane przez konto budowania, a nie przez wdrażającego – prawdopodobnie zbędne.
- Poprawka (Steward): start od `roles/cloudfunctions.developer`, `roles/firebaserules.admin`,
  `roles/datastore.indexAdmin`, `roles/secretmanager.viewer`, `iam.serviceAccountUser` na 4 kontach `fn-*`;
  próbne wdrożenie w dev, dodawanie ról tylko wskazanych przez błąd, każda dodana rola – wpis w GH-010.
  `run.admin` w prod tylko, jeśli Firebase CLI wymaga go do ustawienia publicznego wywołania callable;
  alternatywa: ustawienie `invoker` przy pierwszym wdrożeniu przez właściciela.

**Ś-4. Klucze API: prod Android bez ograniczeń, klucze Browser bez ograniczeń.**
- Klucze API Firebase nie są sekretami (są w APK), ale bez ograniczeń można ich używać z dowolnego miejsca
  do 27 API Firebase (nadużycie limitów, wyliczanie konfiguracji). Ograniczenie Android (pakiet + SHA-1) opiera
  się na nagłówkach, które da się podrobić – **właściwą kontrolą jest App Check**; ograniczenia kluczy to druga warstwa.
- Poprawka (właściciel):
  - prod Android: teraz zawęzić **listę API** (jak dev po teście, N-1); ograniczenie aplikacji (pakiet + SHA-1) –
    razem z SHA klucza wydań (runbook „Czego nie zrobiono" #2);
  - Browser (dev, prod): **najpierw ograniczyć** (referrer `https://tamitu-<env>-tadecode.firebaseapp.com/*`,
    `https://tamitu-<env>-tadecode.web.app/*` + tylko `identitytoolkit`, `securetoken`), sprawdzić logowanie
    Google na urządzeniu w dev; jeśli działa – **usunąć** klucz Browser w dev, po tygodniu bez błędów w prod.
    Nie usuwać od razu: Firebase Auth używa go w obsłudze przekierowań (`/__/auth/handler`).

### Niska

- **N-1.** Klucz Android dev: po teście na urządzeniu (P3-04) zawęzić listę API do faktycznie używanych
  (kandydaci: `identitytoolkit`, `securetoken`, `firebaseinstallations`, `firebaseappcheck`); żaden klucz nie
  może mieć `aiplatform` ani `generativelanguage` w liście API.
- **N-2.** Wyłączyć nieużywane API, zwłaszcza zakazane ADR-0001: `generativelanguage.googleapis.com`
  (Gemini Developer API) i `firebasevertexai.googleapis.com` (Firebase AI Logic) – sprawdzić, że są wyłączone;
  opcjonalnie `firebasehosting`, `firebaseremoteconfig*` (runbook #11).
- **N-3.** App Check: włączyć egzekwowanie dla **Firestore** w konsoli w obu projektach (klient nie używa
  Firestore, więc nic się nie zepsuje; obrona na wypadek otwarcia reguł). Dla Functions egzekwowanie w kodzie
  (ADR-0002) – bez zmian. Prod (Play Integrity): przy rejestracji wymagać „Play recognized" i integralności
  urządzenia (ustawienia dostawcy w App Check).
- **N-4.** Tokeny debug App Check: przegląd listy co kwartał i przy zmianie maszyny; token `owner-laptop`
  usunąć przy wymianie laptopa; w prod lista musi być pusta (sprawdzać przy każdej bramce wydania).
- **N-5.** Po pierwszym wdrożeniu (test odbioru, runbook #1): `budgetguard` **bez** `allUsers`/`allAuthenticatedUsers`
  w `run.invoker` (tylko `fn-budget`), callable – `allUsers` (wymagane przez protokół, uwierzytelnienie
  w kodzie). Polecenie w sekcji 4.4. Sprawdzić też, że logi funkcji trafiają do `tamitu-logs` bez
  `roles/logging.logWriter` na kontach `fn-*` (logi stdout zbiera platforma).
- **N-6.** `iam.allowedPolicyMemberDomains = allowAll` – potrzebne dla `allUsers` na callable, ale pozwala też
  omyłkowo nadać rolę dowolnemu kontu Google. Rozważyć zasadę zarządzaną `iam.managed.allowedPolicyMembers`
  (domena firmy + `allUsers`) – do sprawdzenia przez właściciela, czy jest dostępna w organizacji.
- **N-7.** Logi: kubełek `_Required` (logi audytu administracyjnego, 400 dni) ma lokalizację `global` i zawiera
  e-mail i IP właściciela jako wykonawcy operacji – dane zespołu, nie użytkowników (rejestr D18). Ustawić
  domyślną lokalizację logów organizacji `europe-west4` dla przyszłych projektów:
  `gcloud logging settings update --organization=<ORG_ID> --storage-location=europe-west4`.
- **N-8.** Rozbieżność dokumentów: runbook (etap 0) pisze „repo publiczne", `CLAUDE.md` – „prywatne" (por. SEC-25).
  Runbook zawiera tylko identyfikatory jawne z natury (ID projektów, App ID, odciski SHA są w APK), więc bez
  wpływu na bezpieczeństwo; zapis do ujednolicenia przez orkiestratora.

## 3. Mapa: Aneks A pkt 6 → stan → cel

| Konto | Minimum (ADR-0002 Aneks A pkt 6) | Stan (runbook) | Cel po poprawkach |
|---|---|---|---|
| `fn-ai-plan` | Vertex; Firestore: odczyt `config`, zgód, zapis `usage*`; odczyt użytkownika Auth; sekret | `aiplatform.user`, `datastore.user`, `firebaseauth.viewer`, `secretAccessor` (sekret) | `tamitu.vertexInvoker`, `tamitu.fsUsageWriter`, `tamitu.authUserReader`, `secretAccessor` |
| `fn-consent` | zapis `users/{uid}/consents`; odczyt Auth; sekret | `datastore.user`, `firebaseauth.viewer`, `secretAccessor` | `tamitu.fsConsentWriter`, `tamitu.authUserReader`, `secretAccessor` |
| `fn-account` | usuwanie `users/{uid}`, `usage/{uid}`; usuwanie użytkowników Auth; sekret | `datastore.user`, `firebaseauth.admin`, `secretAccessor` | `datastore.user`, `tamitu.authUserDeleter`, `secretAccessor` |
| `fn-budget` | zapis `config/runtime.aiEnabled`; bez Auth | `datastore.user` | `tamitu.fsConfigUpdater`; `run.invoker` tylko na `budgetguard` (przy P3-09) |

## 4. Poprawki do wykonania przez właściciela (polecenia)

Zasady: każde polecenie najpierw w `tamitu-dev-tadecode`, test, potem `tamitu-prod-tadecode`. `$p` = ID projektu.
Polecenia nie zawierają sekretów. Agenci ich nie wykonują (W-3).

### 4.1 B-1 – wyłączenie buforowania Vertex AI (PowerShell)
```
$p='tamitu-dev-tadecode'; $h=@{Authorization="Bearer $(gcloud auth print-access-token)"; 'x-goog-user-project'=$p}
$u="https://us-central1-aiplatform.googleapis.com/v1/projects/$p/cacheConfig"
Invoke-RestMethod -Method Patch -Uri $u -Headers $h -ContentType 'application/json' -Body (@{name="projects/$p/cacheConfig"; disableCache=$true} | ConvertTo-Json)
Invoke-RestMethod -Method Get -Uri $u -Headers $h   # oczekiwane: disableCache = True
```
Adres `us-central1` jest podany w dokumentacji Google dla tego ustawienia (konfiguracja projektu, bez danych
użytkowników; obowiązuje we wszystkich regionach). Wynik (data, `disableCache=True` w obu projektach) wpisać
do runbooka, etap 9, i do SEC-15 poz. 4.

### 4.2 W-1, W-2, Ś-1, Ś-2 – role niestandardowe
```
$p='tamitu-dev-tadecode'; $sa={ param($n) "serviceAccount:$n@$p.iam.gserviceaccount.com" }
gcloud iam roles create tamitu.vertexInvoker   --project=$p --title="Tamitu Vertex invoker"    --stage=GA --permissions=aiplatform.endpoints.predict
gcloud iam roles create tamitu.authUserReader  --project=$p --title="Tamitu Auth user reader"  --stage=GA --permissions=firebaseauth.users.get
gcloud iam roles create tamitu.authUserDeleter --project=$p --title="Tamitu Auth user deleter" --stage=GA --permissions=firebaseauth.users.get,firebaseauth.users.delete
gcloud iam roles create tamitu.fsConsentWriter --project=$p --title="Tamitu Firestore consent writer" --stage=GA --permissions=datastore.entities.get,datastore.entities.list,datastore.entities.create
gcloud iam roles create tamitu.fsUsageWriter   --project=$p --title="Tamitu Firestore usage writer"   --stage=GA --permissions=datastore.entities.get,datastore.entities.list,datastore.entities.create,datastore.entities.update
gcloud iam roles create tamitu.fsConfigUpdater --project=$p --title="Tamitu Firestore config updater" --stage=GA --permissions=datastore.entities.get,datastore.entities.update
```
Przypisanie (wzór; `add` przed `remove`, żeby nie było przerwy w działaniu):
```
gcloud projects add-iam-policy-binding $p --member=(& $sa fn-ai-plan) --role=projects/$p/roles/tamitu.vertexInvoker --condition=None
gcloud projects remove-iam-policy-binding $p --member=(& $sa fn-ai-plan) --role=roles/aiplatform.user --condition=None
```
Pary (dodaj → usuń):

| Konto | Dodaj | Usuń |
|---|---|---|
| `fn-ai-plan` | `tamitu.vertexInvoker`, `tamitu.authUserReader`, `tamitu.fsUsageWriter` | `roles/aiplatform.user`, `roles/firebaseauth.viewer`, `roles/datastore.user` |
| `fn-consent` | `tamitu.authUserReader`, `tamitu.fsConsentWriter` | `roles/firebaseauth.viewer`, `roles/datastore.user` |
| `fn-account` | `tamitu.authUserDeleter` | `roles/firebaseauth.admin` |
| `fn-budget` | `tamitu.fsConfigUpdater` | `roles/datastore.user` |

Kolejność: W-1 i W-2 przed P3-05 (wywołanie Vertex, usuwanie konta); Ś-1 i Ś-2 przed realnymi danymi.
Po każdej zmianie w dev – testy E2E funkcji (qa); błąd `PERMISSION_DENIED` → dopisać wskazane uprawnienie do roli
(`gcloud iam roles update … --add-permissions=…`), nie przywracać roli predefiniowanej. Zmianę opisać w runbooku, etap 5.

### 4.3 W-4 – WIF
Realizuje Steward w GH-010 wg W-4 (warunki, wiązanie `principal`/`principalSet`, środowisko `prod`).
Security sprawdza konfigurację przed pierwszym wdrożeniem prod z CI.

### 4.4 Odczyty kontrolne (W-5, N-5)
```
gcloud projects get-iam-policy $p --flatten="bindings[].members" --format="table(bindings.role,bindings.members)"
gcloud resource-manager org-policies describe iam.automaticIamGrantsForDefaultServiceAccounts --project=$p --effective
gcloud iam service-accounts list --project=$p
gcloud secrets get-iam-policy UID_HASH_PEPPER --project=$p
gcloud run services get-iam-policy budgetguard --region=europe-west4 --project=$p   # po wdrożeniu P3-09
```
Oczekiwane: tylko właściciel z `roles/owner`; konta `fn-*` wyłącznie z ról z tabeli w sekcji 3; konto Compute
bez `roles/editor`; konta usług Google (service agents) – bez zmian; brak `allUsers` poza callable.
Wynik (bez adresów e-mail) – do runbooka, etap 5.

## 5. O5 – wniosek

- **Zgodność z wymaganiami:** domyślne buforowanie **nie jest zgodne** z D6 („brak zapisu po naszej stronie"
  + minimalizacja u dostawcy) i z opisem planowanym w polityce – wg obecnej dokumentacji obejmuje także warstwę trwałą
  (zapis w spoczynku, do 24 h). Da się je wyłączyć w całości per projekt (B-1).
- **Propozycja zamknięcia O5:** wyłączyć (`disableCache=true`) w dev i prod przed pierwszym wywołaniem
  Vertex (P3-05) – wykonuje właściciel; w kodzie bez jawnych cache, groundingu i logowania żądań;
  `fn-ai-plan` z rolą `tamitu.vertexInvoker` (W-1).
- **Pozostaje otwarte (nowe pytanie):** monitoring nadużyć – możliwy zapis promptów do 90 dni dla klientów
  na warunkach online (B-2); decyzja właściciela + [PRAWNIK] w SEC-15 poz. 4.

## 6. Źródła (sprawdzone 2026-11-18; strony nie podają daty aktualizacji)
1. Google Cloud, „Zero data retention" (Vertex AI / Gemini Enterprise Agent Platform):
   https://docs.cloud.google.com/vertex-ai/generative-ai/docs/vertex-ai-zero-data-retention – buforowanie
   w pamięci i trwałe, 24 h, `cacheConfig`/`disableCache`, retencja groundingu, request-response logging.
2. Google Cloud, „Data governance": https://docs.cloud.google.com/vertex-ai/generative-ai/docs/data-governance –
   brak trenowania bez zgody; dane z cache nieużywane do trenowania.
3. Google Cloud, „Abuse monitoring": https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/abuse-monitoring –
   logowanie promptów do 90 dni, Terms of Service vs Master Agreement.
4. Google Cloud, „Access control" (generative AI): https://docs.cloud.google.com/vertex-ai/generative-ai/docs/access-control
   oraz https://docs.cloud.google.com/vertex-ai/docs/general/access-control – `aiplatform.endpoints.predict`, role niestandardowe.
5. Google Cloud IAM, role Firebase Authentication: https://docs.cloud.google.com/iam/docs/roles-permissions/firebaseauth.
6. Google Cloud, „Context caching overview": https://docs.cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview –
   jawny cache tylko na żądanie (domyślny TTL 60 min); „aby uniknąć retencji – wyłączyć cache niejawny i nie tworzyć jawnych".

Uwaga: lista uprawnień `roles/datastore.user` nie została pobrana ze strony Google (strona niedostępna) –
Ś-1 wymaga potwierdzenia `gcloud iam roles describe roles/datastore.user` i testu w dev.
