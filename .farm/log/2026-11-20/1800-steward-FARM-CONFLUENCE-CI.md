# 18:00  steward → orchestrator  |  FARM-CONFLUENCE-CI

- Zrobione: sekret repo `CONFLUENCE_TOKEN` ustawiony (token Farm Bota, bez wyświetlania). Workflow `.github/workflows/confluence.yml` publikuje zmienione dokumenty z `docs/` po merge'u do `main` oraz ręcznie (`workflow_dispatch` = wszystkie). Bez `pull_request`, `contents: read`, kolejka `confluence` bez anulowania, 15 min. Pierwszy push (`before` = zera) i `workflow_dispatch` publikują wszystko.
- Artefakty: `.github/workflows/confluence.yml`, `.farm/requests/FARM-CONFLUENCE-CI.md`, `docs/github-ops/log.md`.
- Decyzje: brak nowych; koszt ~1 min Actions na merge z dokumentami (darmowa pula).
- Do zrobienia przez odbiorcę: właściciel zatwierdza PR (CODEOWNERS); po merge'u Steward uruchamia raz `workflow_dispatch` i sprawdza statusy stron.
- Pytania/blokady: brak.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: FARM-CONFLUENCE-CI → review
- Zadania – nowe: brak
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak
