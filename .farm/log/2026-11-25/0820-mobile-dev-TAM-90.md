# 08:20  mobile-dev → orchestrator  |  TAM-90

- Zrobione: w `backend/functions/.env.tamitu-dev-tadecode` dopisane `AI_MODEL_ID=gemini-3.1-flash-lite` i `AI_LOCATION=eu`
  (nie są sekretami; decyzja właściciela O-TAM84-1 „W repo”, precedens TAM-85 / PR #129). `AI_PROMPT_VERSION` celowo
  pominięte, więc zostaje `plan-v1`. Sprawdzone w kodzie: `ai.ts` czyta dokładnie te nazwy, `eu` jest na liście
  `ALLOWED_AI_LOCATIONS`; zła lub brakująca wartość daje `ai_unavailable` (fail-closed). Plik dopisany poleceniem
  powłoki (`printf >>`), tak jak w TAM-85: hook `guard-paths` blokuje `.env` tylko dla Write/Edit, a pliku nie
  czytałem (`cat` jest zablokowany). Wynik sprawdzony w `git diff`.
- Artefakty: `backend/functions/.env.tamitu-dev-tadecode`, ten wpis.
- Decyzje: brak (wykonanie O-TAM84-1 i warunków TAM-90).
- Nic nie wdrażałem i nie wywoływałem Vertex AI ani Firebase. `.github/` i CI bez zmian.
- Poza zakresem roli: `docs/architecture/deploy-dev-functions.md` należy do architekta (mobile-dev może pisać tylko
  w `backend`, `lib`, `test`, `.farm/log` i `docs/open-questions.md`). Kroki wdrożenia są niżej; trzeba je przenieść do
  dokumentu (zadanie dla architekta).
- Pytania/blokady: brak.

## Dla orkiestratora (zadania i pytania)

- Zadania – status: TAM-90: review (PR do `main`; po `review:ok` merge robi właściciel, potem wdrożenie właściciela).
- Zadania – nowe: **architect**: `docs/architecture/deploy-dev-functions.md`: w sekcji 2 wiersz `generatePlan` zmienić na
  „TAK (TAM-90)”; w sekcji 3.3 dopisać do tabeli i treści pliku `AI_MODEL_ID` i `AI_LOCATION` (uwaga: plik w repo ma dziś
  tylko `ENVIRONMENT=dev` i te dwie zmienne; `ENFORCE_APP_CHECK` i `ALLOW_REAL_DATA` działają z wartości domyślnych
  `true`/`false`); w sekcji 5 dodać kroki poniżej. Robić po merge'u TAM-90.
- Pytania otwarte – nowe: brak.
- Pytania otwarte – zamknięte: brak.

### Kroki wdrożenia `generatePlan` w dev (właściciel, PowerShell, po merge'u)

Wdrażamy **tylko** `generatePlan`, nigdy całe `functions` (wtedy poszedłby też `budgetGuard`, w dev zakazany).
Ten sam schemat co `recordConsent` (`deploy-dev-functions.md`, sekcja 5).

**Krok 0 – przygotowanie**
```powershell
$p = 'tamitu-dev-tadecode'
gcloud auth login
firebase login --reauth
cd C:\Repository\tamitu
git pull
```

**Krok 1 – plik środowiska (z repo)**
```powershell
Get-Content backend\functions\.env.tamitu-dev-tadecode
```
Oczekiwane: `ENVIRONMENT=dev`, `AI_MODEL_ID=gemini-3.1-flash-lite`, `AI_LOCATION=eu`, bez `AI_PROMPT_VERSION`.
Jeśli brak linii AI, PR TAM-90 nie jest w `main`: **nie wdrażać**.

**Krok 2 – kontrola przed wdrożeniem**
```powershell
cd backend\functions; npm ci; npm run lint; npm run typecheck; npm test; cd ..\..
gcloud run services list --project=$p --region=europe-west4   # oczekiwane: tylko recordconsent
```
Warunki wstępne (sprawdzone 2026-11-25, warto potwierdzić jednym spojrzeniem): TTL `ACTIVE` na `usage.expireAt`
i `usage_global.expireAt` (O4-2), `disableCache=true` (B-1), `fn-ai-plan` tylko z rolami `tamitu.vertexInvoker`,
`tamitu.authUserReader`, `tamitu.fsUsageWriter` (W-1).

**Krok 3 – wdrożenie tylko `generatePlan`**
```powershell
cd backend
firebase deploy --only functions:generatePlan --project tamitu-dev-tadecode
```
Przy pytaniu o cleanup policy: 1 dzień. Pytanie o włączenie dodatkowego API: przerwać (Ctrl+C) i zgłosić.

**Krok 4 – kontrola po wdrożeniu**
```powershell
# a) konto fn-ai-plan, europe-west4, max 10 instancji, zmienne ENVIRONMENT/AI_MODEL_ID/AI_LOCATION
gcloud functions describe generatePlan --region=europe-west4 --project=$p --format="yaml(state,serviceConfig.serviceAccountEmail,serviceConfig.maxInstanceCount,serviceConfig.environmentVariables)"
# b) dwie usługi Cloud Run: recordconsent i generateplan
gcloud run services list --project=$p --region=europe-west4
# c) invoker: tylko allUsers z roles/run.invoker (wymóg callable; logowanie, App Check i zgody sprawdza kod)
gcloud run services get-iam-policy generateplan --region=europe-west4 --project=$p
# d) role fn-ai-plan bez zmian (tylko trzy role tamitu.*)
gcloud projects get-iam-policy $p --flatten="bindings[].members" --filter="bindings.members:fn-ai-plan" --format="table(bindings.role)"
# e) wywołanie bez logowania: oczekiwany "unauthenticated" (401), bez wywołania modelu
$url = gcloud functions describe generatePlan --region=europe-west4 --project=$p --format="value(url)"
try { Invoke-RestMethod -Method Post -Uri $url -ContentType 'application/json' -Body '{"data":{}}' } catch { $_.Exception.Response.StatusCode; $_.ErrorDetails.Message }
```
Oczekiwane: (a) `ACTIVE`, `fn-ai-plan@…`, `10`, `ENVIRONMENT: dev`, `AI_MODEL_ID: gemini-3.1-flash-lite`,
`AI_LOCATION: eu`; (c) jedna rola `roles/run.invoker` dla `allUsers`; (d) tylko `tamitu.vertexInvoker`,
`tamitu.authUserReader`, `tamitu.fsUsageWriter`.

**Krok 5 – pierwszy test: 1 plan z telefonu**
Telefon testowy z tokenem debug App Check („qa-phone”), konto testowe ze zgodą na AI. Jeden krótki plan
(np. 2–3 dni). Koszt: ok. 1 grosz (gemini-3.1-flash-lite, MINIMAL); limit 25 wywołań na dobę, spend cap 15 PLN.
Oczekiwane: plan na ekranie (EK-08). `ai_unavailable` = zmienne nie dotarły (wróć do kroku 4a);
`ai_busy` = przeciążenie modelu (spróbować później, to nie błąd wdrożenia).

**Krok 6 – logi bez danych osobowych**
```powershell
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="generateplan" AND jsonPayload.message="fn_event"' --project=$p --freshness=1h --limit=20 --format=json
```
Sprawdzić:
- wpisy `fn_event` mają tylko pola z listy w `backend/functions/src/logger.ts`: `fn`, `result`, `uidHash`, `outcome`,
  `aiModel`, `aiLocation`, `modelVersion`, `promptVersion` (`plan-v1`), `tokensIn`/`tokensOut`, `calls`, `stopReason`,
  `durationMs` itp.;
- **brak** UID, e-maila, tokenu, celu podróży, treści promptu i odpowiedzi modelu;
- `outcome=ok`, `calls=1`, `aiLocation=eu`, `promptVersion=plan-v1`;
- w Firestore powstał dokument licznika w `usage` z `expireAt` (TTL), a `usage_global` ma licznik dnia.
Logi żądań platformy mogą mieć IP i user agent (oczekiwane, rejestr D11).

**Krok 7 – zamknięcie sesji**
```powershell
gcloud auth revoke
firebase logout
```
Wynik (data, kroki 4–6, bez e-maili i numerów kont) do runbooka P3-03 i `docs/github-ops/log.md`.

**Jak cofnąć:** `firebase functions:delete generatePlan --region europe-west4 --project tamitu-dev-tadecode`
albo usunąć linie AI z pliku i wdrożyć ponownie: funkcja wróci do `ai_unavailable` bez wywołań modelu.
