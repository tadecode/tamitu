# FARM-005 – krok przeglądu w definicji ukończenia (propozycja dla właściciela)

Status: propozycja. Data: 2026-11-17. Autor: orchestrator.

Decyzja właściciela z 2026-11-17 („Tak, włącz") jest już zapisana w `.farm/workflows/phases.md` (sekcja „Zasady")
i `docs/backlog.md`. `CLAUDE.md` jest plikiem chronionym, więc poniższą zmianę musi wprowadzić właściciel.

## Proponowana zmiana w `CLAUDE.md`, zasada 9

Obecnie: „Definicja ukończenia zadania: kod + testy zielone + zaktualizowana dokumentacja + wpis w backlogu i dzienniku."

Proponowane: „Definicja ukończenia zadania: kod + testy zielone + zaktualizowana dokumentacja + wpis w backlogu
i dzienniku. PR z kodem (Flutter, backend) dodatkowo: przegląd roli `reviewer` (`docs/reviews/PR-<nr>.md` + komentarz
w PR) przed zatwierdzeniem właściciela; zadania z ekranami: weryfikacja `qa` przed `done`. PR-y z samą dokumentacją
– bez reviewer."

## Uwaga
`handoff.md` i `role-contract.md` nie wymagają zmian (definicja ukończenia jest w `CLAUDE.md` i `phases.md`).
