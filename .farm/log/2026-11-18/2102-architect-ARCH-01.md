# 21:02  architect → owner, orchestrator, security, mobile-dev, qa  |  ARCH-01
- Zrobione: sprawdzono w dokumentacji Google (2026-11-18) kandydatów Gemini 3.x z ADR-0001 Aneks B pkt 3 (status GA, daty wycofania, regiony, poziomy myślenia) i przeliczono `costs.md` z oficjalnego cennika (stawki „Non-global"). Przygotowano procedurę testu dla właściciela (PowerShell/REST, 4 modele × 5 fikcyjnych przypadków PL/EN, limit 6 PLN), tabelę wyników i rekomendację zależną od wyników.
- Artefakty: docs/architecture/arch-01-gemini-test.md (nowy), docs/architecture/costs.md (v2026-11-18)
- Decyzje: brak nowych ADR; ADR-0001 i Aneks B bez zmian (Aneks B pkt 2 już przewiduje punkt `eu`). Ustalenia:
  - **Żaden kandydat (`gemini-3.5-flash`, `-3.8-flash`, `-3.5-flash-lite`, `-3.1-flash-lite`) nie ma `europe-west4` na liście dostępności** – oczekiwany punkt: multi-region `eu` (`aiplatform.eu.rep.googleapis.com`); potwierdza sonda w teście.
  - `gemini-3.8-flash` nie obsługuje `thinkingLevel=MINIMAL` (najniżej LOW) – płatne tokeny myślenia; pozostali – MINIMAL.
  - Ceny Non-global (USD/1 mln, wej./wyj.): 3.8 Flash 0,825/4,125 do 2026-12-31, potem 1,65/8,25; 3.5 Flash 1,65/9,90; 3.5 Flash-Lite 0,33/2,75; 3.1 Flash-Lite 0,275/1,65. Plan typowy: 0,015–0,090 PLN.
  - Klasa Flash ok. 3,4–4× droższa od dawnego szacunku (2.5 Flash): pełne nadużycie limitu 5/dobę przez jedno konto ≈ 82–98 PLN/mies. (prawie cały budżet prod); pełna ewaluacja 4 modeli ≈ 20 PLN (cały budżet dev).
- Do zrobienia przez odbiorcę:
  - owner – wykonać test z `docs/architecture/arch-01-gemini-test.md` (warunek: `disableCache=True` w dev – SEC-17 B-1/SEC-31), wypełnić tabelę z sekcji 6 (np. w komentarzu do PR lub w pliku przekazania) i wskazać model wg sekcji 7; w P3-09/P3-10 rozważyć limit globalny 20–30/dobę przy klasie Flash;
  - security – SEC-15 poz. 3 i 8 dla wybranego modelu (punkt `eu`, daty wycofania z sekcji 1 procedury);
  - mobile-dev (P3-05) – `thinkingLevel` zamiast `thinkingBudget` (przestarzały dla Gemini 3+); lokalizacja Vertex `eu` (host `aiplatform.eu.rep.googleapis.com`), jeśli test potwierdzi brak `europe-west4`;
  - qa – w planie ewaluacji uwzględnić koszt z `costs.md` sekcja 6 (najtańsze modele najpierw, 1–2 modele dziennie).
- Pytania/blokady: brak blokad dla PR. Do weryfikacji w P3-10: kurs PLN/USD i VAT, SKU w Cloud Billing, mechanizm promocji 3.8 Flash („50% credits back" – czy budżety widzą cenę standardową).

## Źródła (odczyt 2026-11-18)
- https://cloud.google.com/vertex-ai/generative-ai/pricing – tabela „Gemini 3 – Standard", stawki Global/Non-global, „Text output (response and reasoning)".
- https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/3-8-flash (oraz `3-5-flash`, `3-5-flash-lite`, `3-1-flash-lite`) – „Supported regions", status, daty wycofania.
- https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/locations – host multi-regionu `eu`.
- https://docs.cloud.google.com/vertex-ai/generative-ai/docs/thinking – poziomy myślenia per model.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: ARCH-01: review (po merge: owner – wykonanie testu)
- Zadania – nowe: ARCH-01-RUN, „Test modeli Gemini 3.x w dev wg `arch-01-gemini-test.md` + tabela wyników", owner, zależy od: SEC-31 (B-1 `disableCache=True` w dev); wynik → wybór `AI_MODEL_ID` przed P3-05 i wpis do runbooka P3-03 (Aneks B pkt 4)
- Pytania otwarte – nowe: O-ARCH01-1, „Przy klasie Flash: obniżyć limit globalny do 20–30/dobę w fazie testów (pułap ok. 125–148 PLN/mies. przy 50/dobę > budżet prod 100 PLN)?", do: owner (P3-09/P3-10)
- Pytania otwarte – zamknięte: brak
