# 15:00  architect → owner, orchestrator, ux, mobile-dev  |  TAM-96 (P3-05-429), decyzja O-TAM96-1
- Zrobione: rozszerzenie PR #147 po decyzji właściciela O-TAM96-1 („TAK, z rozszerzeniem”, przekazanej przez orkiestratora).
  ADR-0016 jest zatwierdzony warunkowo i ma sekcję „Warunek: 429 nic nie kosztuje”: (a) źródła Google (wprost nikt nie
  pisze, że Vertex nie rozlicza 429; najbliższe jest FAQ Gemini API o błędach 400/500), (b) procedurę sprawdzenia w Billing
  na danych z TAM-88. Nowy kod `ai_busy` (tylko gdy wszystkie wywołania to 429, 0 prób płatnych): slot konta i globalny
  wracają poza limitem 2 zwrotów, z bezpiecznikiem 10 na konto na dobę. W aplikacji jedno automatyczne ponowienie po
  60 s z odliczaniem i „Spróbuj teraz”. `retryAfterSec` jest teraz tylko przy `ai_busy`. Bez płatnych wywołań, bez kodu,
  `.github/` i CI.
- Artefakty: `docs/adr/0016-odpornosc-na-429-vertex.md`, `docs/api/posrednik-api.md` v0.6, `docs/architecture/flows.md` (P3),
  `docs/architecture/p3-05-wymagania-generowania.md` (sekcja 3), `docs/architecture/costs.md` (sekcja 0.1),
  `docs/open-questions.md` (O-TAM96-1 odpowiedziane warunkowo; O-TAM96-2 otwarte)
- Decyzje: ADR-0016 zatwierdzony warunkowo (właściciel, 2026-11-21). Moja propozycja do potwierdzenia przy przeglądzie:
  zwrot także `usage_global` przy `ai_busy` i bezpiecznik 10/dobę (ADR-0016 pkt 8)
- Do zrobienia przez odbiorcę: zadania niżej.
- Pytania/blokady: merge implementacji czeka na wynik z Billing (owner).

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-96: review (PR #147, czeka na właściciela)
- Zadania – nowe (zastępują P3-05-429-IMPL z wpisu 1400):
  - **owner – P3-05-429-BILL „Sprawdzenie w Billing, czy 429 jest rozliczane”** (bez kosztu, najwcześniej 22.11):
    Billing → Reports, projekt `tamitu-dev-tadecode`, usługa Vertex AI, zakres 21.11–21.11, Group by = SKU; dla SKU
    `gemini-3.1-flash-lite` (wejście tekstowe, wyjście tekstowe) odczytać **ilość** (filtr na jedno SKU albo Cost table,
    kolumny Usage i Usage unit). Oczekiwane: wyjście ≈ 55 131 (kontrola, że nie było innych wywołań); wejście ≈ 38 534 →
    429 bez opłaty; ≈ 44 600 → 429 rozliczane. Granice: ≤ 40 000 OK, ≥ 43 000 rozliczane, pomiędzy niejednoznaczne.
    Jeśli raport nie jest w czasie PT i 21.11 obejmuje też ARCH-01, odjąć ok. 3 620 wej. i 9 090 wyj. Kwoty nie
    porównywać (różnica ok. 0,007 PLN). Wynik wpisać w O-TAM96-1. Szczegóły: ADR-0016 „Warunek”, procedura (b).
  - **ux – P3-05-429-UX „Ekran przeciążenia AI (`ai_busy`)”**, zależności: brak. Specyfikacja stanu błędu generowania
    dla `ai_busy` (EK-07 → stan błędu / EK-05, mapowanie w EK-16): tytuł i treść PL/EN (np. „Nasz asystent AI jest chwilowo
    przeciążony. Spróbujemy ponownie za minutę.”), odliczanie (format, dostępność: ogłaszanie najwyżej co 10–15 s),
    przycisk „Spróbuj teraz”, rezygnacja, stan po nieudanym automacie (sam przycisk, bez odliczania), zachowanie w tle,
    tekst o limicie według `slotReleased`. Jasny i ciemny motyw. Źródło: ADR-0016 pkt 10–14, `posrednik-api.md` pkt 6.
  - **mobile-dev – P3-05-429-IMPL „Backend `ai_busy` i backoff + aplikacja z odliczaniem”**, zależności: P3-05-429-UX
    (część aplikacji); najlepiej po merge'u TAM-95 (oba ruszają `generate.ts`); **merge do `main` po P3-05-429-BILL**.
    Backend (`backend/functions/src`):
    1. `generate.ts`: `MAX_CALLS = 3`, `MAX_BILLABLE_ATTEMPTS = 2` (429 nie jest płatne, każde inne zakończenie jest);
       odczekanie 2–4 s przed wywołaniem 2 i 4–8 s przed wywołaniem 3 (tylko po błędzie ponawianym); budżet
       `GENERATION_BUDGET_MS = 100_000`, kolejne wywołanie tylko gdy zostało ≥ 45 s; `hints` przechodzą przez 429.
    2. Wynik: same 429 (0 prób płatnych) → `AppError("ai_busy")`, `unavailable`, `details.retryAfterSec = 60`; inne
       przypadki bez zmian (`retryAfterSec` przy `ai_unavailable` nie wysyłać). Kod `ai_busy` w `errors.ts`.
    3. `limits.ts`/`endpoints.ts`: przy `ai_busy` zwrot slotu konta **i** `usage_global`, bez zwiększania `released`;
       licznik `usage/{uid}.busyReleased` (zerowany z dobą), najwyżej 10, potem `slotReleased=false`; kody
       `quotaRelease` `busy_released`/`busy_capped`; reguły 5–6 bez zmian.
    4. Logi: `waitMs`, `billable`, `calls`, `stopReason` (z `busy`).
    5. Testy (atrapa, wstrzykiwany zegar/`sleep`/losowość): `429→429→ok`; `429×3` → `ai_busy`, zwrot konta i globalnego,
       `released` bez zmian; 11. `ai_busy` w dobie → `slotReleased=false`; `invalid→429→ok` (hints); `timeout→429→429` →
       `ai_unavailable` (zwykły zwrot); `timeout→429` przy budżecie → `time_budget`; `timeout→timeout`, `invalid→invalid`,
       `5xx→5xx` (2 wywołania); 400 (1); granice odczekania; zwrot po północy (reguła 5).
    Aplikacja (`lib/`): mapowanie `ai_busy` (`app_failure.dart`), ekran według P3-05-429-UX, odliczanie od
    `retryAfterSec` (30–120, inaczej 60), **jedno** automatyczne ponowienie z nowym `requestId`, tylko na pierwszym
    planie; „Spróbuj teraz” zastępuje automat; po drugiej porażce sam przycisk; testy widgetowe (odliczanie przez fałszywy
    zegar, brak drugiego automatu, anulowanie). Bez płatnych wywołań w CI.
  - security (mały, opcjonalny): dopisać `busyReleased` do opisu D10 w rejestrze, jeśli rejestr wymienia pola `usage/{uid}`.
  - P3-05-429-MON (po TAM-90, data-analyst lub qa): bez zmian względem wpisu 1400, plus odsetek `ai_busy` i `busy_capped`.
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: O-TAM96-1 – odpowiedziane warunkowo (pełne zatwierdzenie po P3-05-429-BILL). O-TAM96-2 zostaje otwarte.
