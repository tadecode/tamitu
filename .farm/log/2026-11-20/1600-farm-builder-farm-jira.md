# 16:00  farm-builder → orchestrator  |  FARM-JIRA

- Zrobione: zadania farmy przeniesione z Azure Boards do Jiry (projekt TAM, decyzja właściciela 2026-11-20). Nowe narzędzie `.farm/jira/task.ps1` (te same polecenia co dotąd, działa też z kluczem `TAM-n`), tokeny Farm Bota w Menedżerze poświadczeń (`.farm/atlassian/set-token.ps1`). Zmigrowano 60 otwartych zadań i 10 epików, bez niezgodności w statusach, blokadach i epikach; zakończone zostały w Azure Boards jako archiwum. Zasady farmy przepięte na Jirę, w `CLAUDE.md` dodano zasadę 13 (Jira i Confluence: tokeny tylko w Menedżerze poświadczeń, Confluence pisany prosto dla ludzi, strony tylko archiwizujemy, nie usuwamy).
- Artefakty: `.farm/jira/`, `.farm/atlassian/`, `docs/backlog.md`, `CLAUDE.md`, `.claude/agents/orchestrator.md`, `.claude/agents/mobile-dev.md`, `.farm/workflows/handoff.md`, `.farm/workflows/phases.md`, `.github/pull_request_template.md`; usunięte `.farm/ado/`.
- Decyzje: Jira zastępuje Azure Boards (właściciel, 2026-11-20). Statusy: To Do / In Progress / In Review / Owner Review / Done (skróty bez zmian). Confluence: przestrzeń Tamitu z sekcjami Wymagania, ADR, Architektura, Security, UX, Przekazania; publikacja z CI jednokierunkowo — osobne zadanie.
- Do zrobienia przez odbiorcę: używać `.farm/jira/task.ps1` zamiast `.farm/ado/task.ps1`; w briefach podawać klucz `TAM-n` (gałąź i tytuł PR-a). Zadanie testowe TAM-2 (FARM-JIRA-TEST) jest w Done — zostaje jako ślad testu.
- Pytania/blokady: aplikacja „GitHub for Jira” niezainstalowana (właściciel/Steward, osobny krok).

## Dla orkiestratora (zadania i pytania)
- Zadania – status: brak
- Zadania – nowe: FARM-JIRA-GH (instalacja GitHub for Jira w organizacji tadecode, tylko repo tamitu; właściciel/steward); FARM-CONFLUENCE-CI (publikacja docs/ do Confluence po merge'u, jednokierunkowo, historia PR-ów na stronie; steward + farm-builder); FARM-CONFLUENCE-HANDOFF (przekazania agentów w Confluence zamiast `.farm/log/`; farm-builder)
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak
