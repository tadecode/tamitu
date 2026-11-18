# 16:30  steward → owner  |  GH-010 (dev, wdrożenia ręczne)
- Zrobione: przygotowany `.github/workflows/deploy.yml` (ręczne wdrożenie do dev przez WIF, tylko z `main`). Odczytane ID repozytorium i właściciela (liczby, nie sekrety). Składnia nie była uruchamiana w CI.
- Artefakty: .github/workflows/deploy.yml, .farm/requests/GH-010-wif-deploy.md, docs/github-ops/log.md
- Decyzje: właściciel (czat): najpierw tylko dev, wdrożenia ręczne.
- Do zrobienia przez odbiorcę:
  - owner: skonfigurować GCP dev (pula WIF, dostawca z warunkiem, `ci-deployer`, powiązanie, role Ś-3); otworzyć PR `chore/ci-gh-010-deploy-dev` i zatwierdzić; potwierdzić Stewardowi, że GCP gotowe
  - steward: po potwierdzeniu ustawić zmienne Actions i wykonać próbne wdrożenie reguł do dev
- Pytania/blokady: workflow `workflow_dispatch` pojawi się w Actions dopiero po merge do `main`.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: brak
- Zadania – nowe: brak
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak
