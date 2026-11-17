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

## Wpływ
Koszty: brak (WIF bez opłat). · Bezpieczeństwo/RODO: brak długoterminowych poświadczeń; zakres ograniczony do repo/gałęzi. · Ryzyko: zbyt szerokie role `ci-deployer` – przegląd security (SEC-17) przed użyciem w prod.

## Odpowiedź Stewarda
