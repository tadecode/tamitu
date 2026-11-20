# 14:45  architect → owner, orchestrator, security, qa  |  ARCH-01 (kolejność Flash-Lite)
- Zrobione: zapisano decyzję właściciela z 2026-11-20 („najpierw Flash-Lite w ARCH-01, może wystarczy do prostych rzeczy"; przekazał orkiestrator). Procedura ARCH-01 jest teraz dwuetapowa: etap A – `gemini-3.1-flash-lite`, `gemini-3.5-flash-lite` (MINIMAL); etap B – `gemini-3.8-flash` (LOW) tylko, gdy żaden Flash-Lite nie wystarczy; `gemini-3.5-flash` poza testem. Dodano kryterium „wystarczy" (K1 kontrakt 5/5, K2 C3 < 40 s, K3 0 miejsc wymyślonych, K4 język/zainteresowania/brak powtórzeń/geografia/konkretne opisy). Przeliczono koszt testu.
- Artefakty: docs/architecture/arch-01-gemini-test.md (sekcje 0, 2 W5, 3, 4.1, 4.2, 4.5, 4.6, 6, 7), docs/architecture/costs.md (sekcje 6, 8, 10), docs/adr/0001-model-ai-gemini-vertex.md (Aneks B pkt 7)
- Decyzje: preferencja startowa Flash-Lite zapisana jako **pkt 7 Aneksu B ADR-0001**. Aneks B jest jeszcze proponowany, ale pkt 7 oznaczono jako rozstrzygnięty przez właściciela. Zmienia odpowiedź Q4 tylko w zakresie kolejności i modelu startowego; reguła wyboru (najtańszy z ≥ 95%, GA) jest bez zmian. Koszt testu w wariancie najgorszym: etap A ok. 0,9 PLN, A+B ok. 2,6 PLN (wcześniej 4,7 PLN); oczekiwany: A ok. 0,2–0,4 PLN. Limit testu 3 PLN (wcześniej 6), stop skryptu 1,5 PLN (A) / 2,5 PLN (A+B).
- Do zrobienia przez odbiorcę:
  - owner – ARCH-01-RUN wg nowej kolejności: etap A, ocena K1–K4 (sekcja 4.6, ok. 10 min na model), etap B tylko przy „nie" dla obu Flash-Lite; warunek W5: zużycie Vertex AI w dev ≤ 12 PLN (cap 15 PLN).
  - security – SEC-15 poz. 3 i 8 najpierw dla Flash-Lite (`3.1-flash-lite` ma najwcześniejsze wycofanie, ≥ 2027-05-07).
  - qa – pełna ewaluacja P3: najpierw Flash-Lite, kryterium K1–K4 jako próg dopuszczenia modelu startowego.
- Pytania/blokady: brak.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: brak (ARCH-01-RUN bez zmian zależności; zmienia się tylko procedura)
- Zadania – nowe: brak
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak
