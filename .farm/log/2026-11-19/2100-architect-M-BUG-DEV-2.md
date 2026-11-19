# 21:00  architect → owner, ux, orchestrator, qa  |  BUG-DEV-2 / M-BUG-DEV-2

- Zrobione: odpowiedź na M-BUG-DEV-2 (część architekta). Aktywne sprawdzenie DNS z PR #102 nie mieści się w literze ADR-0011 pkt 2 („z wyniku wywołania”, bez osobnego sprawdzenia sieci), więc zamiast cichego doprecyzowania – krótki ADR-0015 uzupełniający pkt 2 w wąskim zakresie (tylko po „anulowaniu” logowania Google, jedno zapytanie DNS, fail-safe na „anulowano”). Ocena prywatności, kosztów i niezawodności w ADR.
- Artefakty: `docs/adr/0015-sprawdzenie-dns-po-anulowaniu-logowania-google.md` (nowy, zatwierdzony przez właściciela 2026-11-19), `docs/open-questions.md` (sekcja „BUG-DEV-2 (PR #102)”).
- Decyzje: ADR-0015 – zatwierdzony przez właściciela 2026-11-19 („zatwierdzam ADR-0015”). Kod PR #102 zgodny z nim bez zmian. ADR-0011 nie zmieniany.
- Do zrobienia przez odbiorcę: UX – rozstrzygnąć komunikat przy anulowaniu w trybie samolotowym (CMP-13 vs „Logowanie anulowane.”). QA – po decyzjach: SIGN-13, SIGN-12 z siecią, SIGN-14, SIGN-15 i zaktualizowane oczekiwanie SIGN-12 #10. Security – do wiadomości (brak nowych danych, bez wpisu w rejestrze).
- Pytania/blokady: część UX M-BUG-DEV-2.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: brak (BUG-DEV-2 pozostaje w review do decyzji UX i `qa:ok`)
- Zadania – nowe: brak
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: M-BUG-DEV-2 – część architekta: ADR-0015 (zatwierdzony 2026-11-19); część UX nadal otwarta
