# 15:14  mobile-dev → orchestrator (dalej reviewer)  |  TAM-95 (P3-05-DEDUP), poprawki po przeglądzie PR #148
- Zrobione: poprawione 2 uwagi średnie i drobne z `docs/reviews/PR-148.md` (PR #149), w tej samej gałęzi i PR #148.
  **Domyślnym promptem w produkcji zostaje `plan-v1`**; `plan-v2` włącza tylko parametr `AI_PROMPT_VERSION=plan-v2`,
  a w eval opcja `--prompt plan-v2`. Reguła `dup_place` porównuje tylko punkty z tej samej miejscowości i nie daje
  fałszywych alarmów z przeglądu. 0 płatnych wywołań, `--paid` nie uruchamiany, bez wdrożeń, `.github/` i CI
  nietknięte. Ten wpis uzupełnia `1433-mobile-dev-TAM-95.md`; tam, gdzie się różnią, obowiązuje ten.
- Artefakty:
  - `backend/functions/src/prompt/plan-v1.ts` (przywrócony bez zmian z `main`), `src/prompt/plan-v2.ts` (tylko
    `SYSTEM_INSTRUCTION`), `src/prompt/index.ts` (nowy: `PROMPTS`, `DEFAULT_PROMPT`, `resolvePrompt`),
    `src/generate.ts` (opcja `prompt`, `promptVersion` w wyniku; logika ponowień bez zmian), `src/endpoints.ts`
    (`deps.prompt`, `promptVersion` z faktycznie użytego promptu), `src/index.ts` (`AI_PROMPT_VERSION`),
    `src/plan-validator.ts` (`placeKey`, `sameTokens`, `GENERIC_WORDS`, `VENUE_KIND`), `src/logger.ts` (komentarz
    o limicie);
  - testy: `test/plan-validator.test.ts`, `test/prompt.test.ts`, `test/generate.test.ts`,
    `test/generate-plan-flow.test.ts`, `test/eval-guard.test.ts`, `test/endpoints.test.ts`,
    `test/no-direct-logging.test.ts`;
  - `backend/eval/run-eval.mjs` (`--prompt`, kolumna `prompt`, etykieta licznika), `backend/eval/eval-guard.mjs`
    (`parsePromptVersion`), `backend/eval/README.md` (sekcja „`plan-v2` dopiero po płatnym teście”).
- Decyzje:
  - Uwaga 2: `AI_PROMPT_VERSION` – brak, pusta albo nieznana wartość (także `PLAN-V2`, `__proto__`) → `plan-v1`.
    Parametr nie jest ustawiony w żadnym pliku `.env`, więc wdrożenie tego PR-a nic nie zmienia w zachowaniu dev.
    W eval nieznana wartość `--prompt` → odmowa startu (jak inne opcje uruchamiacza), domyślnie `plan-v1`.
  - Uwaga 1 a: porównanie tylko przy tej samej znormalizowanej `locality`. Przypadki QA (E03-en, E17-pl) nadal łapane.
  - Uwaga 1 b: nazwa złożona z samych ogólnych słów („Old Town”, „Central Park”, „Muzeum Narodowe”, „Stare Miasto”)
    liczy się tylko przy równości, nie przy zawieraniu się w dłuższej. Nazwy z co najmniej jednym nieogólnym słowem
    (np. „Sultanahmet Koftecisi”) nadal mogą się zawierać w dłuższej – bez tego E17-pl nie byłby wyłapany.
  - Uwaga 1 c: słowa typu lokalu („Restauracja”, „Ristorante”, „Cafe”, „Caffè”, „Kawiarnia”) są usuwane z nazwy, ale
    zapamiętane; restauracja i kawiarnia o tej samej nazwie to dwa miejsca.
  - Uwaga 1 d (nocleg jako `dup_place`) i README: licznik opisany jako górne oszacowanie; osobnego kodu dla noclegu
    nie dodałem (walidator nie zna `trip.lodging`, a wpływ jest tylko na log).
  - Uwaga 4: (a) komentarz przy limicie 200 znaków, (b) test 14 dni z powtórzeniem w każdym dniu (13 kodów, ≤ 200
    znaków), (c) etykieta licznika: „…/N valid plans”, „upper estimate”.
  - Uwaga 3 (dokumenty architekta) bez zmian: zadanie P3-05-DEDUP-DOC po merge'u PR #147 i #148.
- Testy (bez urządzenia i sieci): `backend/functions` – `vitest` 350 testów zielone, `typecheck`, `lint`, `build` bez
  błędów. `run-eval.mjs --dry-run` z `plan-v1` i `--prompt plan-v2`: 40/40, 0 powtórzeń; `--prompt plan-v3` →
  odmowa (kod 2).
- Do zrobienia przez odbiorcę: reviewer – ponowny krótki przegląd PR #148 (zmiany od `dde1e67`).
- Pytania/blokady: brak.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-95: review (ponowny krótki przegląd, potem merge właściciela).
- Zadania – nowe: zamiast P3-05-EVAL-V2 z poprzedniego wpisu:
  - **P3-05-EVAL-V2** (qa, tylko po zgodzie właściciela): `node backend/eval/run-eval.mjs --paid --confirm-paid-run
    --prompt plan-v2 --stop-pln 2.5` i ocena ręczna K4 c. **Szacunek kosztu:** ok. 0,70 PLN przy 1 próbie,
    ok. 1,00 PLN przy 40% ponowień, najwyżej ok. 1,40 PLN (80 wywołań); sufit 2,5 PLN; mieści się w spend cap dev
    (15 PLN). Dłuższy prompt to < 0,01 PLN na przebieg. Nie zużywa limitu 25/dobę.
  - **P3-05-PROMPT-V2-ON** (owner/mobile-dev, po P3-05-EVAL-V2 ≥ 95% i decyzji właściciela): ustawić
    `AI_PROMPT_VERSION=plan-v2` w `.env.tamitu-dev-tadecode` (wdrożenie przez proces deploy).
- Pytania otwarte – nowe: **O-TAM95-1** (właściciel) bez zmian: czy i kiedy zlecić P3-05-EVAL-V2 (koszt wyżej)?
- Pytania otwarte – zamknięte: brak.
