# 18:15  farm-builder → orchestrator  |  FARM-CONFLUENCE-ASSETS

- Zrobione: publikator Confluence wgrywa teraz załączniki. Grafiki SVG wspomniane w dokumencie pokazuje jako obrazki. Makiety HTML dołącza do pobrania i robi z nich zrzuty PNG przeglądarką bez okna (lokalnie Edge, w CI google-chrome): wersja polska jasna i ciemna oraz angielska jasna. Na stronach UX doszła sekcja „Podgląd i załączniki”. Opublikowano 17 stron UX (ekrany EK-01…EK-16, marka, ikona) i 83 załączniki, 0 błędów. Pliki .svg/.html podane na wejściu publikator zamienia na dokumenty, które je wspominają.
- Artefakty: `.farm/confluence/publish.mjs`.
- Decyzje: właściciel 2026-11-20: makiety HTML jako załącznik, zrzuty PNG i grafiki SVG w Confluence.
- Do zrobienia przez odbiorcę: w workflow `confluence.yml` (PR #122, Steward) rozszerzyć filtr plików na `\.(md|svg|html)$`. Wtedy zmiana samej makiety lub grafiki też odświeży stronę.
- Pytania/blokady: brak.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: FARM-CONFLUENCE-ASSETS → review (ten PR)
- Zadania – nowe: brak
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak
