# Protokół przekazań

Każde przekazanie pracy między agentami to **osobny plik** w `.farm/log/` (decyzja właściciela 2026-11-17,
żeby równoległe PR-y nie kolidowały we wspólnych plikach).

## Konwencja pliku

```
.farm/log/<RRRR-MM-DD>/<HHMM>-<rola>-<zadanie>.md
```

- `<HHMM>` – godzina rozpoczęcia wpisu (24 h, bez dwukropka), `<rola>` – rola autora (kebab-case),
  `<zadanie>` – id zadania lub krótki slug (np. `p3-04`, `conflicts`). Przykład:
  `.farm/log/2026-11-17/1430-mobile-dev-p3-04.md`.
- **Jeden wpis = jeden plik.** Autor tworzy nowy plik i nigdy nie edytuje cudzych wpisów ani wspólnego
  pliku dnia. Poprawka własnego wpisu – tylko w tym samym PR-ze; później nowy wpis.
- Stare pliki `.farm/log/<RRRR-MM-DD>.md` (do 2026-11-17 włącznie) zostają jako archiwum; nie dopisujemy do nich.
  Dziennik dnia = zawartość katalogu `.farm/log/<RRRR-MM-DD>/` posortowana po nazwie.

## Format wpisu

```
# <HH:MM>  <od-roli> → <do-roli>  |  <id zadania>
- Zrobione: <1–3 zdania>
- Artefakty: <ścieżki plików>
- Decyzje: <lub „brak"; ważne → ADR>
- Do zrobienia przez odbiorcę: <konkretnie>
- Pytania/blokady: <lub „brak">

## Dla orkiestratora (zadania i pytania)
- Zadania – status: <ID: nowa kolumna (todo, doing, review, owner, done)> lub „brak"
- Zadania – nowe: <id, tytuł, rola, zależności> lub „brak"
- Pytania otwarte – nowe: <id, treść, do kogo> lub „brak"
- Pytania otwarte – zamknięte: <id i rozstrzygnięcie> lub „brak"
```

## Zadania i pytania otwarte (zmienia tylko orkiestrator)

**Zadania i statusy są w Azure Boards** (od 2026-11-18; `docs/backlog.md` tylko wskazuje tablicę).
Role nie piszą na tablicy ani w `docs/open-questions.md`: zmianę statusu, nowe zadania i nowe pytania
zgłaszają w sekcji „Dla orkiestratora” własnego pliku przekazania. Orkiestrator **po merge** PR-a roli
przenosi zgłoszenia zadań na tablicę (`.farm/ado/task.ps1`, bez PR-a), a pytania otwarte zbiorczo do
`docs/open-questions.md` małym PR-em. Do czasu przeniesienia źródłem prawdy są pliki przekazania.

Zmiana uprawnień ról (`-Allow` w `.claude/agents/*.md`) oraz `CLAUDE.md` (zasady 2 i 12) czeka na właściciela:
`.farm/requests/FARM-006-shared-files.md`.

## Okres przejściowy

Do czasu zatwierdzenia FARM-006 role mają jeszcze uprawnienia do `docs/open-questions.md`
(uprawnienia do `docs/backlog.md` zdjęte 2026-11-18 przy przejściu na Azure Boards).
PR-y otwarte w dniu 2026-11-17 (#53, #54, P3-04, ADR platformy) mogą dokończyć pracę w starym formacie
(wpis w `.farm/log/<data>.md`, edycja backlogu). Orkiestrator przy ich merge rozwiązuje konflikty i nie wymaga
przepisywania. Od zatwierdzenia FARM-006 wszystkie nowe wpisy – tylko w nowym formacie.

## Brief orkiestratora dla roli (zlecenie)

```
Cel: <co ma powstać>
Wejścia: <pliki do przeczytania>
Wyjście: <artefakt i ścieżka>
Definicja ukończenia: <kryteria>
Ograniczenia: <zakres uprawnień, czas, koszty>
```
