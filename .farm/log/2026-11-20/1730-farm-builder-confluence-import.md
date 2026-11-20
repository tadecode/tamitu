# 17:30  farm-builder → orchestrator  |  FARM-CONFLUENCE-IMPORT

- Zrobione: publikator dokumentów do Confluence (`.farm/confluence/publish.mjs`, lokalnie `publish.ps1` z tokenem Farm Bota). Jednorazowo zaimportowano 98 dokumentów z `docs/` (wymagania, ADR, architektura z modelem danych i API, security z przeglądami, UX z komponentami i ekranami) do przestrzeni Tamitu. W sumie 110 stron, 0 błędów renderowania. Układy stron odtwarzają kod szablonów Confluence: ADR → DACI, US-* → Product requirements, komponenty UX → Design component; pozostałe strony mają układ ogólny. Każda strona ma baner „kopia z repo, zmiany przez PR” i tabelę „Historia zmian” z PR-ami z historii git.
- Artefakty: `.farm/confluence/` (publish.mjs, publish.ps1, package.json, package-lock.json).
- Decyzje: repo jest źródłem prawdy, a publikacja działa jednokierunkowo (właściciel, 2026-11-20). Strony rozpoznajemy po właściwości `tamitu-source` (ścieżka pliku), więc ponowna publikacja aktualizuje stronę zamiast tworzyć nową. Stron nie usuwamy.
- Do zrobienia przez odbiorcę: zaplanować FARM-CONFLUENCE-CI. Workflow po merge'u do `main` publikuje zmienione pliki z `docs/`. Steward dodaje sekret z tokenem `farm-confluence` i plik workflow.
- Pytania/blokady: makiety HTML i grafiki SVG z `docs/ux/` nie są jeszcze w Confluence (tylko linki w repo); osobny krok.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: brak
- Zadania – nowe: FARM-CONFLUENCE-ASSETS (grafiki SVG jako załączniki stron UX; farm-builder)
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak
