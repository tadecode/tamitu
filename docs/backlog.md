# Backlog

**Zadania i statusy są w Azure Boards** (od 2026-11-18):
https://dev.azure.com/tadecode/Tamitu/_boards/board/t/Tamitu%20Team/Issues

Tablica Kanban: Do zrobienia → W pracy (agent) → Przegląd i QA → **Czeka na Ciebie** → Gotowe.
Zadanie ma ID w tytule (np. `P3-04: …`), tag `bk:<ID>`, tagi ról (`rola:mobile-dev`) i rodzica-epik wg prefiksu.

- **Czyta** każdy: `powershell -File .farm/ado/task.ps1 list` (albo `show <ID>`); wymaga `az login`.
- **Zmienia tylko orkiestrator** przez `.farm/ado/task.ps1` (`new`, `move`, `note`, `block`). Bez PR-ów.
- **Role** zgłaszają zmiany w sekcji „Dla orkiestratora” pliku przekazania (`.farm/workflows/handoff.md`).
- Treść (wymagania, ADR, specyfikacje, raporty, kod) zostaje w repo; zadanie na tablicy linkuje do plików i PR-ów.

Stan sprzed migracji: [`docs/archive/backlog-2026-11-18.md`](archive/backlog-2026-11-18.md) (nie aktualizować).
