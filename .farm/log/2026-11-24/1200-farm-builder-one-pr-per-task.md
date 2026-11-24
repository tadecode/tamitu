# 12:00  farm-builder → orchestrator  |  FARM-ONE-PR

- Zrobione: jeden PR na zadanie (decyzja właściciela, 2026-11-24). Autor, recenzent i QA pracują kolejno w tym samym worktree, na jednej gałęzi. Raporty recenzji i QA są komentarzami w PR (szkic w `.farm/tmp/`, katalog ignorowany przez git), nie osobnymi PR-ami z plikami. Hook guard-paths liczy ścieżki w `.claude/worktrees/<nazwa>/` jak w zwykłym worktree, a ochrona kontraktów działa dalej. Naprawia to powtarzającą się blokadę zapisu w sesjach z kart.
- Artefakty: `.claude/agents/reviewer.md`, `qa.md`, `orchestrator.md`, `.farm/workflows/phases.md`, `handoff.md`, `.farm/hooks/guard-paths.ps1`, `test-guards.ps1` (nowe testy), `.github/pull_request_template.md`, `.gitignore`.
- Decyzje: QA nie commituje do gałęzi autora; brakujące testy zgłasza jako „zmiany wymagane”, bo push zdjąłby `review:ok`. Recenzent i QA nie tworzą wpisów w `.farm/log/`: przekazaniem jest komentarz z sekcją „Dla orkiestratora”. Dotychczasowe `docs/reviews/` i `docs/qa/` zostają jako archiwum.
- Do zrobienia przez odbiorcę: od kolejnego zadania uruchamiać recenzenta i QA w worktree autora (jawny `cwd`), kolejno, bez osobnych worktree `review-PR-*` / `qa-PR-*`; sekcję „Dla orkiestratora” czytać z `gh pr view <nr> --comments`.
- Pytania/blokady: brak.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: brak
- Zadania – nowe: brak
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak
