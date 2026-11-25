# 11:00  architect → orchestrator  |  TAM-103

- Zrobione: `docs/architecture/deploy-dev-functions.md` dogoniony do stanu po wdrożeniu `generatePlan` (TAM-90):
  sekcja 2 (`generatePlan` – TAK, wdrożone 2026-11-25), 3.3 (`AI_MODEL_ID`, `AI_LOCATION`, faktyczna treść pliku `.env`),
  5.2 (kroki tylko `--only functions:generatePlan` z 3 uwagami recenzji PR #166: pełna polityka IAM projektu
  i `gcloud secrets get-iam-policy UID_HASH_PEPPER`, odczyt `fn_event` + `fn_error`, szybka blokada przez zdjęcie
  `allUsers`/`roles/run.invoker` z `generateplan` w sekcji 6), 5.3 (nowa: `config/runtime.testUids` i `aiEnabled` –
  włączanie przed pierwszym testem i wyłączanie AI w dev), 5.4 (przebieg 2026-11-25, bez numerów kont i UID),
  sekcje 6, 7 i 9. ADR-0016: status **zatwierdzony** (warunek Billing spełniony 2026-11-24, TAM-97), dopisany
  punkt (c) z wynikiem. O-TAM96-1 oznaczone jako odpowiedziane. Wzmianki „zatwierdzony warunkowo” w `costs.md`,
  `flows.md`, `p3-05-wymagania-generowania.md` i nagłówku `posrednik-api.md` zaktualizowane (wpisy historii bez zmian).
- Artefakty: `docs/architecture/deploy-dev-functions.md`, `docs/adr/0016-odpornosc-na-429-vertex.md`,
  `docs/open-questions.md`, `docs/architecture/costs.md`, `docs/architecture/flows.md`,
  `docs/architecture/p3-05-wymagania-generowania.md`, `docs/api/posrednik-api.md`, ten wpis.
- Decyzje: brak nowych (ADR-0016 – tylko wykonanie warunku zatwierdzonego przez właściciela 2026-11-21).
- Bez zmian w chmurze, bez wywołań modelu, kod bez zmian. Zachowanie `aiEnabled`/`testUids` opisane na podstawie
  `backend/functions/src/config.ts` i `endpoints.ts` (odczyt przy każdym żądaniu; `aiEnabled` musi być boolean).
- Do zrobienia przez odbiorcę: reviewer – przegląd PR-a (tylko dokumenty); owner – merge.
- Pytania/blokady: brak.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-103: review (PR do `main`).
- Zadania – nowe: brak (opcjonalny odczyt `usage`/`usage_global` przez QA i ocena liczby punktów vs tempo zgłosił już
  raport QA w PR #166).
- Pytania otwarte – nowe: brak (decyzja, czy `aiEnabled=true` i token debug zostają w dev, jest już w raporcie QA
  PR #166; procedura wyłączenia: `deploy-dev-functions.md` sekcja 5.3).
- Pytania otwarte – zamknięte: O-TAM96-1 – zamknięte (Billing 2026-11-24: 38 534 / 55 131, 429 nierozliczane; ADR-0016 zatwierdzony).
