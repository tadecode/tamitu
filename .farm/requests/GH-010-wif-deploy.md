# GH-010: wdrożenia z CI do Firebase/GCP przez Workload Identity Federation (bez kluczy JSON)

- Zgłasza (rola): orchestrator (P3-03) · Data: 2026-11-18 · Powiązane zadanie/PR: P3-03 / #66; ADR-0002 Aneks A pkt 6, ADR-0003, SEC-17, SEC-20
- Typ: secret + ci-change (konfiguracja GCP po stronie właściciela/Stewarda)
- Status: open  (ustawia Steward)

## Potrzeba
ADR-0003: „wdrożenia z CI przez Workload Identity Federation (Steward, bez kluczy JSON)". Organizacja GCP egzekwuje
`iam.disableServiceAccountKeyCreation`, więc klucze JSON i tak są niemożliwe. Potrzebny jest mechanizm wdrożenia funkcji i reguł
Firestore z GitHub Actions. **Nie pilne:** pierwsze wdrożenia (P3-05) może wykonać właściciel lokalnie; WIF przed automatycznym wdrażaniem.

## Szczegóły
1. Per projekt (`tamitu-dev-tadecode`, `tamitu-prod-tadecode`):
   - Pula WIF `github` + dostawca OIDC `tamitu-repo` (`https://token.actions.githubusercontent.com`), **warunek atrybutu**:
     `assertion.repository == 'tadecode/tamitu'` oraz dla prod `assertion.ref == 'refs/heads/main'` (i środowisko `prod`).
   - Konto usług wdrażające `ci-deployer@<projekt>.iam.gserviceaccount.com` z minimalnymi rolami do przeglądu przez security (SEC-17), np.:
     `roles/cloudfunctions.developer`, `roles/run.admin` (2. gen.), `roles/firebaserules.admin`, `roles/datastore.indexAdmin`,
     `roles/iam.serviceAccountUser` **tylko na kontach** `fn-ai-plan`, `fn-consent`, `fn-account`, `fn-budget` (nie na poziomie projektu),
     `roles/artifactregistry.writer`, `roles/cloudbuild.builds.editor`, `roles/secretmanager.viewer` (metadane sekretu przy deployu).
   - `roles/iam.workloadIdentityUser` dla podmiotu puli na `ci-deployer`.
2. GitHub: zmienne (nie sekrety) `GCP_WIF_PROVIDER_DEV/PROD`, `GCP_DEPLOYER_SA_DEV/PROD`; workflow wdrożeniowy `deploy.yml`
   (`permissions: id-token: write, contents: read`), ręczny lub po merge do `main`; prod tylko ze środowiska `prod` z akceptacją właściciela.
3. Wdrożenie zależy od SEC-20 (`serviceAccount` w opcjach funkcji) i pytania O2 (`fn-ai-plan`).

## Warunki z przeglądu SEC-17 (dopisał orchestrator 2026-11-18; `docs/security/review-SEC-17-iam.md`)
Poniższe zastępują pkt 1 powyżej, jeśli się różnią.
- **W-4 (WIF, warunek za słaby dla prod).** Nazwa repozytorium nie wystarcza (zmiana nazwy, ponowne użycie).
  - Mapowanie atrybutów: `google.subject=assertion.sub`, `attribute.repository_id`, `attribute.repository_owner_id`, `attribute.ref`, `attribute.environment`, `attribute.workflow=assertion.job_workflow_ref`.
  - Warunek **dev**: `assertion.repository_id=='<ID>' && assertion.repository_owner_id=='<ID_ORG>' && assertion.ref=='refs/heads/main'`.
  - Warunek **prod**: jak dev **oraz** `assertion.environment=='prod' && assertion.job_workflow_ref=='tadecode/tamitu/.github/workflows/deploy.yml@refs/heads/main'`.
  - `roles/iam.workloadIdentityUser` na `ci-deployer` tylko dla `principal://…/subject/repo:tadecode/tamitu:environment:prod` (prod) lub `principalSet://…/attribute.repository_id/<ID>` (dev), **nie** dla całej puli (`/*`).
  - GitHub: środowisko `prod` z wymaganym zatwierdzeniem właściciela i regułą „deployment branches: main”; workflow bez `pull_request_target`; `permissions: id-token: write` tylko w zadaniu wdrożenia. ID repo i organizacji (liczby, nie sekrety): `gh api repos/tadecode/tamitu --jq '.id, .owner.id'`.
- **Ś-3 (role `ci-deployer` do zawężenia przed prod).** Efektywne uprawnienia CI = suma ról `fn-*`; ryzyko akceptowalne tylko przy W-4.
  - Start od: `roles/cloudfunctions.developer`, `roles/firebaserules.admin`, `roles/datastore.indexAdmin`, `roles/secretmanager.viewer`, `iam.serviceAccountUser` na 4 kontach `fn-*`.
  - `roles/run.admin`, `roles/artifactregistry.writer`, `roles/cloudbuild.builds.editor` – prawdopodobnie zbędne (używa ich konto budowania); `run.admin` w prod tylko, jeśli Firebase CLI wymaga go do publicznego wywołania callable (alternatywa: `invoker` ustawiony przy pierwszym wdrożeniu przez właściciela).
  - Próbne wdrożenie w dev, dodawanie ról tylko wskazanych przez błąd, każda dodana rola = wpis w tej prośbie.
- **W-5 (powiązane):** `ci-deployer` **nie dostaje** `iam.serviceAccountUser` na koncie Compute – wdrożenie bez `serviceAccount` ma kończyć się błędem (techniczne wymuszenie SEC-20).

## Wpływ
Koszty: brak (WIF bez opłat). · Bezpieczeństwo/RODO: brak długoterminowych poświadczeń; zakres ograniczony do repo/gałęzi. · Ryzyko: zbyt szerokie role `ci-deployer` – przegląd security (SEC-17) przed użyciem w prod.

## Odpowiedź Stewarda
2026-11-18 Steward: prośba zgodna z polityką; decyzja właściciela (czat): najpierw tylko dev, wdrożenia ręczne.
Dane (odczyt `gh api`): `repository_id=1458544274`, `repository_owner_id=148259836` (właściciel to konto użytkownika, nie organizacja).
Wykonane: workflow `.github/workflows/deploy.yml` (PR `chore/ci-gh-010-deploy-dev`): `workflow_dispatch`, wybór `firestore:rules` / `firestore:indexes` / `functions`, tylko projekt `tamitu-dev-tadecode`, tylko z `main`, `id-token: write` wyłącznie w jobie wdrożeniowym, bez `pull_request_target`, `google-github-actions/auth@v3`, `firebase-tools@15.34.2`.
Czeka (właściciel, GCP): pula WIF `github`, dostawca `tamitu-repo` z warunkiem repo/właściciel/`refs/heads/main`, konto `ci-deployer`, powiązanie `workloadIdentityUser` na `principalSet` po `repository_id`, role startowe wg Ś-3, bez `serviceAccountUser` na koncie Compute (W-5).
Czeka (Steward, po potwierdzeniu GCP): zmienne Actions `GCP_WIF_PROVIDER_DEV`, `GCP_DEPLOYER_SA_DEV`; próbne wdrożenie reguł w dev; każda dodana rola = wpis tutaj.
2026-11-18 Steward (aktualizacja, dev wykonane): PR #84 zmergowany. GCP dev skonfigurowane na polecenie właściciela (dostawca `tamitu-repo`, `ci-deployer`, powiązanie po `repository_id`, role: `cloudfunctions.developer`, `firebaserules.admin`, `datastore.indexAdmin`, `secretmanager.viewer`; bez `serviceAccountUser` na koncie Compute). Zmienne Actions ustawione. Wdrożenie próbne `firestore:rules` do dev: run 44353627132 `success` (pierwsza próba padła, bo dostawca nie istniał). Nie dodano `iam.serviceAccountUser` na kontach `fn-*` ani `run.admin`/`artifactregistry.writer`/`cloudbuild.builds.editor`; dodajemy dopiero przy próbnym wdrożeniu `functions`, każda rola jako wpis tutaj.
Otwarte: próba `firestore:indexes` i `functions` w dev (czeka na SEC-20/O2/P3-05), zawężenie ról przed prod (Ś-3), konfiguracja prod wg W-4. Status: approved (dev done).
Prod: poza zakresem tej odpowiedzi (osobny krok po próbie w dev, z warunkami W-4 dla prod i zatwierdzeniem w środowisku `prod`).
