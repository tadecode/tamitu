# 17:00  steward → owner  |  GH-010 (dev wykonane)
- Zrobione: zmienne Actions WIF dev; GCP dev (dostawca OIDC, `ci-deployer`, powiązanie, 4 role startowe) skonfigurowane na polecenie właściciela z jego konta `gcloud`; wdrożenie próbne `firestore:rules` do dev przeszło (run 44353627132).
- Artefakty: docs/github-ops/log.md, .farm/requests/GH-010-wif-deploy.md
- Decyzje: brak własnych; zakres dev i wdrożenia ręczne wg właściciela. Jedyna zmiana poza GitHubem: IAM w projekcie dev (za zgodą w czacie).
- Do zrobienia przez odbiorcę:
  - owner: zatwierdzić PR z dziennikiem; przy wdrożeniu `functions` dodać `iam.serviceAccountUser` na `fn-*` (nie na koncie Compute); prod osobno wg W-4 po SEC-17
  - steward: próba `firestore:indexes` po poprawce O4-1 i `functions` po P3-05
- Pytania/blokady: pula `github` istniała już w chwili tworzenia dostawcy (wcześniejsze `list` zwróciło 0); nieistotne dla działania.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: brak
- Zadania – nowe: brak
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak
