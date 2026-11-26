# 08:15  architect → orchestrator  |  TAM-112 (P3-07-ADRFIX)
- Zrobione: ADR-0017 dostał Aneks 1 (2026-11-26): tryb dojazdu jest zapamiętywany lokalnie (decyzja właściciela UX11, EK-09 v0.4 z 2026-11-25), start nie. Aneks opisuje przechowywanie zgodnie z kodem w `main` (`shared_preferences`, klucz `routeTravelMode`, wartości `driving`/`transit`/`walking`, odczyt w bootstrapie z `try/catch`). Wiersz tabeli w pkt 1 odsyła do aneksu (stary tekst przekreślony, nie usunięty). Tę samą niespójność poprawiłem w `docs/api/zewnetrzne-integracje.md` i `docs/data/model-danych.md` (pola wejściowe i magazyn `shared_preferences`).
- Artefakty: `docs/adr/0017-trasa-maps-bez-lokalizacji-w-aplikacji.md`, `docs/api/zewnetrzne-integracje.md`, `docs/data/model-danych.md`
- Decyzje: tryb dojazdu to ustawienie funkcjonalne (jak `uiLanguage`), bez UID i bez powiązania z planem, nie wychodzi poza urządzenie inaczej niż w linku (D8). Nie jest nowym rodzajem danych osobowych, nowy wpis w rejestrze nie jest potrzebny. Kod, `docs/ux/` i `docs/security/` bez zmian. Koszty: 0.
- Do zrobienia przez odbiorcę: przegląd i merge PR-a przez właściciela.
- Pytania/blokady: brak.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-112: review (PR do `main`).
- Zadania – nowe: brak. Opcjonalnie dla security (bez blokady, przy najbliższej zmianie rejestru): dopisać „tryb dojazdu (EK-09)” do opisu ustawień lokalnych obok D16, dla spójności; nowy wiersz rejestru nie jest potrzebny.
- Uwaga dla mobile-dev (przy implementacji usuwania konta, P3-14c): usuwanie wpisów `shared_preferences` obejmuje też `routeTravelMode`.
- Pytania otwarte – nowe: brak.
- Pytania otwarte – zamknięte: brak.
