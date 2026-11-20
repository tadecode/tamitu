# Backlog

**Zadania i statusy są w Jirze** (od 2026-11-20, projekt TAM):
https://tadecode.atlassian.net/jira/software/projects/TAM/boards/1

Tablica: To Do → In Progress → In Review → **Owner Review** (czeka na właściciela) → Done.
Zadanie ma czytelny tytuł (bez kodu), ID farmy w polu **Farm Id** (np. `P3-04`), role w polu **Agent role**,
przypisanie (właściciel, gdy czeka na Ciebie – kolumna Owner Review; w pozostałych Farm Bot), klucz Jiry (`TAM-12`),
etykiety ról (`rola:mobile-dev`), etykietę `zablokowane` przy blokadzie i epik wg prefiksu.

- **Czyta** każdy: `powershell -File .farm/jira/task.ps1 list` (albo `show <ID>` / `show TAM-12`).
  Wymaga tokena Farm Bota w Menedżerze poświadczeń (`.farm/atlassian/set-token.ps1 jira`).
- **Zmienia tylko orkiestrator** przez `.farm/jira/task.ps1` (`new`, `move`, `note`, `block`). Bez PR-ów.
- **Role** zgłaszają zmiany w sekcji „Dla orkiestratora” pliku przekazania (`.farm/workflows/handoff.md`).
- Gałąź i tytuł PR-a zaczynaj od klucza Jiry (np. `feat/TAM-12-...`, `TAM-12: ...`), żeby GitHub for Jira je powiązał.
- Treść (wymagania, ADR, specyfikacje, raporty, kod) zostaje w repo; zadanie linkuje do plików i PR-ów.

Historia: zadania zakończone przed 2026-11-20 zostały w Azure Boards (archiwum, tylko do odczytu):
https://dev.azure.com/tadecode/Tamitu/_boards/board/t/Tamitu%20Team/Issues .
Każde przeniesione zadanie ma w opisie link do swojej historii w Azure Boards.
Stan sprzed Azure Boards: [`docs/backlog.md` @ 77d2cc2](https://github.com/tadecode/tamitu/blob/77d2cc2/docs/backlog.md).
