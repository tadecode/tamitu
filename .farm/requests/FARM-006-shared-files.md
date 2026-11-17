# FARM-006 – wspólne pliki: dziennik, backlog, pytania (propozycja dla właściciela)

Status: propozycja. Data: 2026-11-17. Autor: orchestrator.

Decyzja właściciela z 2026-11-17 („tak"): ograniczyć konflikty w PR-ach. Konwencja dziennika (jeden wpis = jeden plik)
oraz zasada „backlog i pytania zmienia tylko orkiestrator po merge” są opisane w `.farm/workflows/handoff.md` i `phases.md`
(wchodzą tym PR-em). Pliki chronione (`.claude/`, `CLAUDE.md`, `.farm/hooks/`) musi zmienić właściciel – poniżej dokładne zmiany.
Do czasu ich wprowadzenia obowiązuje okres przejściowy z `handoff.md`.

## 1. `CLAUDE.md`

**Zasada 2** – obecnie: „Przekazanie = zapisany plik. Wynik pracy zapisujesz w `docs/` lub w kodzie, nie tylko w odpowiedzi. Wpis o przekazaniu dodaj do `.farm/log/` wg `.farm/workflows/handoff.md`.”

Proponowane: „Przekazanie = zapisany plik. Wynik pracy zapisujesz w `docs/` lub w kodzie, nie tylko w odpowiedzi. Wpis o przekazaniu
tworzysz jako **osobny plik** `.farm/log/<RRRR-MM-DD>/<HHMM>-<rola>-<zadanie>.md` wg `.farm/workflows/handoff.md`; nie edytujesz cudzych wpisów.
Zmianę statusu zadania, nowe zadania i pytania zgłaszasz w sekcji „Dla orkiestratora” tego pliku; `docs/backlog.md` i `docs/open-questions.md`
zmienia tylko orkiestrator, po merge.”

**Zasada 12** – obecne zdanie: „Pliki wspólne (`docs/backlog.md`, dziennik) edytuj małymi, osobnymi wpisami, żeby równoległe PR-y nie kolidowały.”

Proponowane: „Plików wspólnych nie edytujesz: dziennik to osobne pliki (zasada 2), a `docs/backlog.md` i `docs/open-questions.md` aktualizuje tylko orkiestrator po merge.”

**Zasada 9** (definicja ukończenia) – „wpis w backlogu i dzienniku” → „wpis przekazania w `.farm/log/` ze zgłoszeniem zmian backlogu (backlog uzupełnia orkiestrator)”. (Łączy się ze zmianą z FARM-005; przy wprowadzaniu obu połączyć brzmienie.)

## 2. `-Allow` w `.claude/agents/*.md` (hook `guard-paths.ps1`)

Usunąć `docs/backlog.md` i `docs/open-questions.md` z listy `-Allow` ról:

| Plik | Usunąć |
|---|---|
| `security.md` | `docs/backlog.md,docs/open-questions.md` |
| `qa.md` | `docs/backlog.md,docs/open-questions.md` |
| `mobile-dev.md` | `docs/backlog.md,docs/open-questions.md` |
| `analyst.md` | `docs/open-questions.md` |
| `architect.md` | `docs/open-questions.md` |
| `ux.md` | `docs/open-questions.md` |
| `data-analyst.md` | `docs/open-questions.md` |
| `dba.md` | `docs/open-questions.md` |
| `reviewer.md` | (brak – bez zmian) |

`.farm/log` zostaje w `-Allow` wszystkich ról (podkatalogi są obejmowane prefiksem; do sprawdzenia w `guard-paths.ps1`, czy dopasowanie jest po prefiksie).
W sekcjach „Uprawnienia”/„Wyjścia” tych ról zamienić „backlog/open-questions” na „zgłoszenie w pliku przekazania”.
`orchestrator.md` – bez zmian (ma już prawo zapisu), w „Sposób pracy” dodać krok „po merge przenieś zgłoszenia z `.farm/log/` do backlogu i pytań”.
Po zmianie dodać przypadki do `.farm/hooks/test-guards.ps1` (np. mobile-dev zapis `docs/backlog.md` → blokada; `.farm/log/2026-11-17/x.md` → dozwolone).

## 3. Opcjonalnie: `.github/pull_request_template.md`

Linia „Dokumentacja i `docs/backlog.md` zaktualizowane, wpis w `.farm/log/`” → „Dokumentacja zaktualizowana, wpis przekazania w `.farm/log/<data>/` (zmiany backlogu zgłoszone orkiestratorowi)”. Plik objęty CODEOWNERS `/.github/`.

## Ryzyka
- Backlog bywa nieaktualny do czasu zbiorczego PR orkiestratora; źródłem prawdy o statusie jest wtedy plik przekazania.
- Orkiestrator staje się wąskim gardłem backlogu – PR zbiorczy raz dziennie lub po serii merge wystarcza.
- Brak zmian w hookach zablokuje role (zapis do backlogu), jeśli `-Allow` usuniemy przed wejściem nowych zasad – kolejność: najpierw ten PR, potem FARM-006.
