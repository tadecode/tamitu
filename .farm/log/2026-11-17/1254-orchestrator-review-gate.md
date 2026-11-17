# 12:54  orchestrator → owner, steward  |  review-gate (bramka przeglądu i QA)
- Zrobione: po incydencie PR #57 (merge mimo werdyktu „zmiany wymagane” z #58, #59) przygotowano wniosek o bramkę etykiet i zmiany narzędzi ról (decyzja właściciela 2026-11-17). Sprawdzono hooki: `qa` (lista zakazów) może już ustawiać etykiety, `reviewer` (lista dozwolonych) nie – `gh pr edit` i testy (`flutter test`, `npm`) wymagają zmiany hooka. Opisano bramkę w `phases.md` jako stan docelowy.
- Artefakty: .farm/requests/GH-008-review-qa-gate.md, .farm/requests/FARM-007-reviewer-qa-tools.md, .farm/workflows/phases.md
- Decyzje: do właściciela – wyjątek Dependabot w bramce; ryzyko uruchamiania kodu z PR przez reviewera (`npm ci --ignore-scripts`); czy iść od razu w osobne konto reviewer (alternatywa 2 w GH-008). Bramka z etykietami jest proceduralna (to samo konto bota).
- Do zrobienia przez odbiorcę: steward – GH-008 (etykiety `review:ok|changes`, `qa:ok|changes`, `ui`; workflow `review-gate`; wymagana kontrola na `main`); owner – FARM-007 (`guard-bash-allow.ps1`, `reviewer.md`, `qa.md`, testy w `test-guards.ps1`); do czasu wdrożenia właściciel nadaje etykiety ręcznie
- Pytania/blokady: brak

## Dla orkiestratora (backlog i pytania)
- Backlog – status: brak
- Backlog – nowe zadania: GH-008 (steward), FARM-007 (owner, pliki chronione) – do wpisania po merge
- Pytania otwarte – nowe: brak (decyzje powyżej w tym wpisie i w GH-008)
- Pytania otwarte – zamknięte: brak
