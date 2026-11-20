# 21:30  architect → owner, orchestrator, mobile-dev, steward  |  TAM-84
- Zrobione: plan pierwszego wdrożenia funkcji do `tamitu-dev-tadecode` – tylko `recordConsent` (odblokowuje QA-P3-04-DEV-2 / TAM-34); `generatePlan`, `deleteAccount`, `budgetGuard` – nie teraz (uzasadnienie w planie). Stan chmury sprawdzony tylko odczytem: domyślne konto budujące (Compute) nie ma żadnej roli – budowanie się nie uda bez `cloudbuild.builds.builder`; `predeploy` w `backend/firebase.json` nie działa na Windows; brak pliku `.env` dla dev → funkcja uznałaby się za prod; sekret `UID_HASH_PEPPER` ma już wersję 1 (enabled); `ci-deployer` nie ma `actAs` na `fn-*`, a `deploy.yml -f component=functions` wdrożyłby wszystkie funkcje – pierwsze wdrożenie ręcznie przez właściciela. Koszt ~0 zł.
- Artefakty: `docs/architecture/deploy-dev-functions.md`, `docs/open-questions.md` (O-TAM84-1, O-TAM84-2)
- Decyzje: brak nowych ADR (plan operacyjny w ramach ADR-0002, ADR-0003, ADR-0014, SEC-17)
- Do zrobienia przez odbiorcę:
  - mobile-dev: poprawka `predeploy` w `backend/firebase.json` (`npm --prefix functions ci`, `npm --prefix functions run build`) – blokuje wdrożenie z Windows;
  - owner: decyzje O-TAM84-1 i O-TAM84-2; potwierdzić, że wersja 1 sekretu jest losowa; wykonać kroki 0–8 z sekcji 5 planu (w tym rola `cloudbuild.builds.builder` dla konta budującego i `gcloud auth revoke` po sesji);
  - steward: (później) `deploy.yml` – opcja `functions:<nazwa>` zamiast całego `functions`, `iam.serviceAccountUser` dla `ci-deployer` tylko na potrzebnych kontach (SEC-17 Ś-3, W-5);
  - orchestrator: po wdrożeniu ponownie zlecić QA-P3-04-DEV-2.
- Pytania/blokady: O-TAM84-1, O-TAM84-2

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-84: review (PR z planem)
- Zadania – nowe:
  - „firebase.json: predeploy działający na Windows", mobile-dev, zależności: brak; blokuje wdrożenie z TAM-84
  - „Wdrożenie recordConsent do dev wg deploy-dev-functions.md", owner, zależności: poprzednie zadanie, O-TAM84-2
  - „deploy.yml: wdrażanie pojedynczej funkcji + actAs dla ci-deployer na wybranych fn-*", steward, zależności: wdrożenie ręczne zakończone, SEC-17 Ś-3/W-5
- Pytania otwarte – nowe: O-TAM84-1 (plik `.env` dev w repo?, owner/steward), O-TAM84-2 (App Check w dev: token debug vs wyłączenie, owner) – już wpisane do `docs/open-questions.md`
- Pytania otwarte – zamknięte: brak
