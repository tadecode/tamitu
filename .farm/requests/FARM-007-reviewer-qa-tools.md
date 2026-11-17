# FARM-007 – narzędzia reviewer/qa i etykiety bramki (propozycja dla właściciela)

Status: propozycja. Data: 2026-11-17. Autor: orchestrator.

Powód: po incydencie PR #57 (zmergowany mimo werdyktu „zmiany wymagane”) powstaje bramka etykiet (`GH-008`). Reviewer nie może dziś
uruchomić testów (brak `flutter test`, `npm` na liście dozwolonych poleceń) ani ustawić etykiety (`gh pr edit` poza listą). Pliki
`.claude/` i `.farm/hooks/` są chronione – zmianę wprowadza właściciel (tryb `FARM_MAINTENANCE=1`).

## 1. `.farm/hooks/guard-bash-allow.ps1` – profil `reviewer`: dopisać do `$profiles.reviewer`

Tylko polecenia bez zapisu kodu. Zapis artefaktów budowania (`.dart_tool/`, `node_modules/`) jest skutkiem ubocznym i leży w ignorowanych
katalogach; kod z PR jest jednak wykonywany (testy), więc patrz „Ryzyko” poniżej.

```powershell
        # testy i analiza Flutter (flutter analyze i dart analyze już są wyżej)
        '^flutter\s+test(\s|$)',
        '^dart\s+format\s+(--set-exit-if-changed\s+)?--output=none(\s|$)',   # zastępuje obecny wzorzec dart format
        # backend (Cloud Functions) – wyłącznie w backend/functions
        '^npm\s+--prefix\s+backend/functions\s+ci$',
        '^npm\s+--prefix\s+backend/functions\s+run\s+(lint|typecheck|test)$',
        '^npx\s+--prefix\s+backend/functions\s+vitest\s+run(\s|$)',
        # etykiety bramki – tylko te cztery i tylko na PR o podanym numerze
        '^gh\s+pr\s+edit\s+\d+\s+--(add|remove)-label\s+(review|qa):(ok|changes)$'
```

Uwagi:
- Hook odrzuca `; & | < > ` $(` i wiele linii, więc `cd backend/functions && npm ci` nie przejdzie; stąd `npm --prefix backend/functions …`.
  `npx` nie ma `--prefix` w każdej wersji – jeśli nie działa, użyć `npm --prefix backend/functions run test` (skrypt `test` = `vitest run`),
  co i tak jest równoważne; wtedy wzorzec `npx … vitest` można pominąć. Do sprawdzenia w teście hooka.
- Wzorzec etykiety jest zakotwiczony i bez dodatkowych flag, więc `gh pr edit` nie zmieni tytułu, treści, bazy ani recenzentów.
  `--remove-label` potrzebny reviewerowi do zamiany `review:changes` ↔ `review:ok` przy ponownym przeglądzie.
- Dodać do `$deny.reviewer`: `'^npm\s+.*\s(install|i|publish|exec|run\s+(?!lint|typecheck|test))'` (jawna blokada reszty `npm`); lista dozwolonych i tak
  jest fail-closed, deny daje czytelny komunikat.
- Dodać przypadki do `.farm/hooks/test-guards.ps1` (CI `farm-guards`): dozwolone – każde z powyższych; zabronione – `gh pr edit 5 --title x`,
  `gh pr edit 5 --add-label bug`, `npm install`, `npm --prefix backend/functions run build`, `gh pr merge 5`, `gh label create review:ok`.

**Ryzyko:** `flutter test` i `npm ci`/vitest wykonują kod z PR (skrypty testów, `postinstall` zależności) na maszynie z sesją reviewera. To
dotychczasowa zasada „kod z PR wykonuje się tylko w CI” (`reviewer.md`, „Wejścia”) – zmiana świadoma. Łagodzenie: `npm ci --ignore-scripts`
(zamiast `npm ci`; wzorzec `^npm\s+--prefix\s+backend/functions\s+ci\s+--ignore-scripts$`), przegląd diffu **przed** uruchomieniem testów,
reviewer nie ma dostępu do sekretów (`.env`, klucze zablokowane), a wyniki testów z CI (`gh pr checks`) nadal są pierwszym źródłem. Alternatywa
o niższym ryzyku: reviewer czyta wyniki CI i nie uruchamia nic (stan obecny) – wtedy zostaje tylko etykieta (ostatnia linia wzorców).

`qa` korzysta z `guard-bash.ps1` (lista zakazów) i ma już `flutter`/`npm` oraz `gh pr edit --add-label` – **zmiana hooka nie jest potrzebna**,
tylko zapis instrukcji w `qa.md` (pkt 3).

## 2. `.claude/agents/reviewer.md`

a) „Wejścia”, ostatnia pozycja – zamienić:
> Wyniki CI: `gh pr checks <nr>`. Testów **nie uruchamiasz lokalnie** - kod z PR wykonuje się tylko w CI.

na:
> Wyniki CI: `gh pr checks <nr>`. Testy i analizę uruchamiasz lokalnie tylko poleceniami z listy dozwolonych (`flutter analyze`,
> `flutter test`, `dart format --set-exit-if-changed --output=none`; w `backend/functions`: `npm ci --ignore-scripts`, `npm run lint`,
> `npm run typecheck`, `npm run test`), **po** przeczytaniu diffu i bez zmian w kodzie. Wynik (zielony/czerwony, liczba testów)
> zapisujesz w raporcie; brak możliwości uruchomienia (narzędzie, urządzenie, emulator) odnotuj w „Czego nie sprawdzono”.

b) „Czego nie robi”, drugi punkt – zamienić „Nie uruchamia kodu z PR ani nie instaluje narzędzi.” na „Nie instaluje narzędzi; kod z PR
uruchamia wyłącznie przez testy i analizatory z listy dozwolonych.”

c) „Wyjścia” – dopisać:
> - **Etykieta bramki** (po komentarzu w PR): werdykt „do akceptacji” → `gh pr edit <nr> --add-label review:ok`; „zmiany wymagane” →
>   `gh pr edit <nr> --add-label review:changes`. Przy ponownym przeglądzie najpierw zdejmij poprzednią etykietę
>   (`--remove-label review:changes` / `review:ok`). Przed nadaniem etykiety sprawdź, że `gh pr view <nr> --json headRefOid` zgadza się
>   z SHA, który przeglądałeś (wpisz SHA w raporcie); jeśli head się zmienił – przejrzyj od nowa. Nie nadawaj `qa:*` ani etykiety `ui`.

d) „Uprawnienia” – dopisać: „`gh pr edit` tylko z flagą `--add-label`/`--remove-label` dla `review:ok` i `review:changes`.”

e) Nowa zasada: „**Jedna sesja = jeden PR.** Każdy przegląd to nowa sesja reviewer z czystym kontekstem, bez wiedzy z poprzedniego PR-a;
poprzednie raporty czytasz z `docs/reviews/`, nie z pamięci rozmowy. Ponowny przegląd tego samego PR (po poprawkach) to też nowa sesja.”

## 3. `.claude/agents/qa.md`

Dopisać w „Wyjścia” (i w `guard-paths` nic nie zmienia):
> - **Etykieta bramki** po raporcie QA dla PR z ekranami: kryteria spełnione → `gh pr edit <nr> --add-label qa:ok`; odrzucone →
>   `gh pr edit <nr> --add-label qa:changes` (zdejmij poprzednią etykietę przy ponownej weryfikacji). Sprawdź `headRefOid` jak reviewer.
>   Nie nadawaj `review:*`. Tylko te dwie etykiety i tylko `gh pr edit <nr> --add-label|--remove-label`; nie zmieniaj tytułu, treści ani bazy PR.
> - **Jedna sesja = jeden PR** (czysty kontekst, jak reviewer).

## 4. Instrukcja dla ról (do wklejenia do briefów orkiestratora)

Po pozytywnym werdykcie ustaw etykietę `review:ok` (reviewer) lub `qa:ok` (qa); po negatywnym `review:changes` / `qa:changes`.
Etykietę nadajesz dopiero po dodaniu komentarza z raportem do PR i po sprawdzeniu, że head PR-a się nie zmienił. Nowy push autora
zdejmuje `*:ok` (workflow `review-gate`), więc po poprawkach przegląd robi nowa sesja od początku. Jeśli polecenie jest zablokowane przez hook –
nie obchodź; zgłoś orkiestratorowi.

## 5. Kolejność wdrożenia
1. Steward: GH-008 (etykiety, workflow, wymagana kontrola).
2. Właściciel: ta propozycja (hook + `reviewer.md` + `qa.md` + testy w `test-guards.ps1`), w jednym PR-ze maintenance.
3. Do czasu zatwierdzenia punktu 2 etykiety nadaje właściciel ręcznie po przeczytaniu raportów.

## Uwaga
`CLAUDE.md` bez zmian (zasada 9 jest już w FARM-005); jeśli właściciel zechce, można dodać zdanie o bramce etykiet.
