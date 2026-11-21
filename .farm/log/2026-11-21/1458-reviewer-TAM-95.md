# 14:58  reviewer → orchestrator (dalej owner, mobile-dev, architect)  |  TAM-95 (P3-05-DEDUP), PR #148
- Zrobione: przegląd PR #148 (head `dde1e67`): prompt `plan-v2` z zakazem powtórzeń i ostrzeżenie `dup_place@dayN`
  w logu. Rekomendacja **DO AKCEPTACJI**; ustalenia: bloker 0, wysoka 0, średnia 2, drobna 2. Etykieta `review:ok`.
  Bez płatnych wywołań i wdrożeń; kodu PR nie uruchamiano lokalnie (CI backend zielone, 328 testów).
- Artefakty: `docs/reviews/PR-148.md`, komentarz w PR #148.
- Decyzje: brak. Prompt injection bez regresji, logi bez treści, `promptVersion` spójny w kodzie i `backend/eval/`,
  „ostrzeżenie zamiast błędu” uzasadnione kosztowo, brak konfliktu plików z PR #147 (TAM-96).
- Do zrobienia przez odbiorcę:
  - owner: merge wg uznania; przed bramką wydania zdecydować O-TAM95-1 (płatny przebieg `plan-v2`, ustalenie 2).
  - mobile-dev (niewymagane do merge'u): reguła `dup_place` porównuje tylko nazwę, bez `locality`, i łapie ogólne
    prefiksy („Old Town” / „Old Town Hall”) – zawyża licznik; poprawić przed ewentualną zmianą ostrzeżenia na błąd
    (ustalenie 1).
  - architect: P3-05-DEDUP-DOC dopiero po merge'u PR #147 i #148 (te same dokumenty); w O-TAM18-2 nazwa „plan-v2”
    jest już zajęta (ustalenie 3).
- Pytania/blokady: brak.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-95: bez zmian (review → owner po decyzji właściciela o merge'u).
- Zadania – nowe: **P3-05-DEDUP-LOC** (mobile-dev, niski priorytet, przed zmianą `dup_place` na błąd): porównywać
  punkty tylko w tej samej `locality`, testy negatywne (to samo „Old Town” w dwóch miastach, „Old Town” / „Old Town
  Hall”), README eval – licznik jako górne oszacowanie. Zależy od: merge PR #148.
- Pytania otwarte – nowe: brak (O-TAM95-1 zgłosił już mobile-dev).
- Pytania otwarte – zamknięte: brak.
