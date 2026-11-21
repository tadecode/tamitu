# 14:00  architect → owner, orchestrator, mobile-dev  |  TAM-96 (P3-05-429)
- Zrobione: zaprojektowana odporność generowania na HTTP 429 z Vertex (raport QA TAM-88: 6 × 429, 2 generowania
  `ai_unavailable`, wynik 95,0% bez zapasu). Wybrany wariant: dłuższe odczekanie z rozrzutem (2–4 s, potem 4–8 s),
  trzecie wywołanie tylko po 429, najwyżej 2 próby płatne (429 bez tokenów), budżet czasu 100 s. Koszt ok. 0 PLN/mies.,
  pułapy i limity bez zmian. Alternatywy Vertex opisane i wycenione, nic nie włączone ani nie zamówione.
  Bez płatnych wywołań, bez zmian w kodzie, `.github/` i CI. Nie ruszałem reguł promptu i walidatora (TAM-95).
- Artefakty: `docs/adr/0016-odpornosc-na-429-vertex.md` (nowy, proponowany; uzupełnia ADR-0002 „Próby”),
  `docs/api/posrednik-api.md` v0.6, `docs/architecture/p3-05-wymagania-generowania.md` (sekcje 3, 5, 6),
  `docs/architecture/costs.md` (sekcja 0.1), `docs/open-questions.md` (O-TAM96-1, O-TAM96-2)
- Decyzje: ADR-0016 – proponowany, czeka na właściciela (O-TAM96-1)
- Do zrobienia przez odbiorcę:
  - owner: odpowiedzieć na O-TAM96-1 i O-TAM96-2; merge PR-a. Opcjonalnie (bez zmian, bez kosztu): odczyt konsoli
    Quotas dla Vertex AI w `tamitu-dev-tadecode`.
  - mobile-dev (po zatwierdzeniu O-TAM96-1): zadanie niżej.
- Pytania/blokady: implementacja czeka na O-TAM96-1.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-96: review (PR z dokumentami, czeka na właściciela)
- Zadania – nowe:
  - P3-05-429-IMPL: „Ponowienia po 429 według ADR-0016”, rola mobile-dev, zależności: O-TAM96-1 zatwierdzone;
    najlepiej po merge'u TAM-95, bo oba zmieniają `generate.ts`. Zakres (`backend/functions/src`):
    1. `generate.ts`: `MAX_CALLS = 3`, `MAX_BILLABLE_ATTEMPTS = 2` (429 nie jest płatne; każde inne zakończenie jest);
       odczekanie przed wywołaniem 2: losowo 2–4 s, przed wywołaniem 3: losowo 4–8 s (tylko po błędzie ponawianym;
       po złej odpowiedzi bez odczekania); budżet `GENERATION_BUDGET_MS = 100_000` od startu 1. wywołania, kolejne
       wywołanie tylko gdy zostało ≥ `ATTEMPT_TIMEOUT_MS` (45 s); lista błędów (`hints`) z ostatniej płatnej złej
       odpowiedzi przechodzi przez 429 (dziś jest kasowana); wynik końcowy według ostatniego błędu (kody bez zmian).
    2. Przy porażce, gdy ostatnie wywołanie dostało 429: `ai_unavailable` z `details.retryAfterSec = 60`
       (`posrednik-api.md` v0.6); `slotReleased` jak dotąd.
    3. Logi: `waitMs`, `billable` w `generatePlan.attempt`; `calls`, `stopReason`
       (`ok`/`invalid`/`config`/`max_billable`/`max_calls`/`time_budget`) we wpisie końcowym; tylko stałe kody i liczby.
    4. Testy jednostkowe (atrapa modelu, wstrzykiwany zegar, `sleep` i losowość): `429→429→ok`, `429→429→429`
       (3 wywołania, `retryAfterSec`), `invalid→429→ok` (hints w 3. wywołaniu), `timeout→429` (budżet nie pozwala
       na 3. wywołanie, `time_budget`), `timeout→timeout` i `invalid→invalid` (2 wywołania), `5xx→5xx` (bez 3.),
       400 (1 wywołanie), granice odczekania 2–4 i 4–8 s, blokada treści (bez zmian).
    5. Uruchamiacz ewaluacji korzysta z tej samej ścieżki – bez osobnych zmian. Bez płatnych wywołań w CI.
  - P3-05-429-MON (po TAM-90, rola data-analyst lub qa): po 7 dniach w dev policzyć z logów odsetek generowań
    zakończonych przez 429, odsetek 3. wywołań i p95 czasu; porównać z progiem O-TAM96-2.
  - (opcjonalnie, niski priorytet, ux): EK-05 może przy `retryAfterSec` podpowiedzieć „spróbuj za minutę”; dziś
    aplikacja pole ignoruje i to jest poprawne.
- Pytania otwarte – nowe: O-TAM96-1 (zatwierdzenie ADR-0016), O-TAM96-2 (próg powrotu do Priority PayGo) – do właściciela
- Pytania otwarte – zamknięte: brak
