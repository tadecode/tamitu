# 16:25  mobile-dev → reviewer, orchestrator  |  TAM-58 (SEC-19), TAM-59 (SEC-21), TAM-60 (SEC-22)
- Zrobione: poprawki P-2, P-4, P-5 z przeglądu security 2026-11-16 w `backend/functions`: lista dozwolonych wzorców kodu/klasy błędu w logach (inaczej `unknown`, bez obcinania); pola tekstowe – NFC i odrzucenie znaków Unicode `Cc`/`Cf`/`Zl`/`Zp`; parsowanie `config/runtime` wydzielone z `index.ts` do `config.ts` (`parseRuntimeConfig`) z granicami limitów (1–20 na konto, 1–100 globalnie; poza zakresem → 5 / 25). `policyVersion` (wzorzec + lista znanych wersji) było już wdrożone przy P3-04 – dodane tylko przypadki testowe. Testy (210), lint, typecheck i build zielone lokalnie.
- Artefakty: `backend/functions/src/errors.ts`, `src/schemas.ts`, `src/config.ts`, `src/index.ts`, `test/errors.test.ts` (nowy), `test/schemas.test.ts`, `test/config.test.ts`, `docs/api/posrednik-api.md` (v0.4.1 – doprecyzowanie, bez zmiany pól i kodów), `docs/open-questions.md` (O-SEC22-1).
- Decyzje: granice limitów przyjęte roboczo (ADR ich nie określa) – pytanie O-SEC22-1. Skutek uboczny SEC-21: emoji złożone ze znakiem ZWJ (np. rodzina, flagi tęczowe) w nazwie celu/noclegu → `invalid_argument` (kategoria `Cf`).
- Do zrobienia przez odbiorcę: reviewer – przegląd PR; orkiestrator – przeniesienie pytania i zadania niżej.
- Pytania/blokady: brak blokad.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-58, TAM-59, TAM-60: review
- Zadania – nowe: walidacja formularza planu w aplikacji (P3-05) powinna odrzucać te same znaki (`Cc`/`Cf`/`Zl`/`Zp`) i liczyć długość po NFC, żeby poprawny formularz nie dostawał `invalid_argument` – mobile-dev, przy P3-05
- Pytania otwarte – nowe: O-SEC22-1 (granice `perUserDailyLimit`/`globalDailyLimit`) – architect, owner; wpis już w `docs/open-questions.md`
- Pytania otwarte – zamknięte: brak
