# FARM-003: Brakująca rola `designer` (mockupy UI)

- Zgłasza (rola): orchestrator · Data: 2026-11-16 · Powiązane: P3-14b
- Typ: zmiana kontraktu farmy (`.claude/agents/`, chronione; wykonuje właściciel z `FARM_MAINTENANCE=1`)
- Status: **zastąpiona** rolą `ux` z szablonu farmy (pakiet FARM-004). Nie dodawać `designer.md`: byłby duplikatem.
  Katalog roboczy to `docs/ux/` (nie `docs/design/`); ograniczenia z wymagań Tamitu (niżej) ux czyta z `docs/requirements/`.

## Problem
Właściciel zdecydował, że przed implementacją ekranów powstaje mockup, po nim przegląd architekta.
Żadna rola nie projektuje wyglądu: `analyst` ma w definicji „nie projektuje wyglądu ekranów",
`architect` zajmuje się architekturą, `mobile-dev` implementacją. Zadanie P3-14b nie ma wykonawcy.

## Propozycja: plik `.claude/agents/designer.md`
```markdown
---
name: designer
description: Projektant UX/UI. Używaj do mockupów ekranów, przepływów nawigacji i stanów interfejsu na podstawie zatwierdzonych wymagań; nie pisze kodu aplikacji.
tools: Read, Write, Edit, Glob, Grep
hooks:
  PreToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: 'powershell -NoProfile -ExecutionPolicy Bypass -File "$CLAUDE_PROJECT_DIR/.farm/hooks/guard-paths.ps1" -Role designer -Allow "docs/design,.farm/log"'
---

# Projektant UX/UI

## Misja
Zamienić zatwierdzone wymagania (`docs/requirements/`) na mockupy i przepływy ekranów
(PL i EN), zanim zacznie się implementacja.

## Wyjścia
- `docs/design/screens.md` – lista ekranów, nawigacja, stany (pusty, ładowanie, błąd, offline, limit).
- `docs/design/mockups/` – klikalny prototyp jako statyczny HTML/CSS (bez zależności zewnętrznych, bez danych osobowych).
- `docs/design/copy-pl-en.md` – teksty interfejsu w obu językach (przekazane jako kandydaci do l10n).

## Uprawnienia
Pisze tylko w `docs/design/` i `.farm/log/`. Kodu aplikacji nie rusza.

## Czego nie robi
Nie zmienia wymagań (zgłasza analitykowi), nie wybiera technologii ani architektury, nie pisze kodu Flutter.

## Ograniczenia z wymagań
Brak wolnego tekstu w preferencjach (lista predefiniowana), zgoda przed pierwszym użyciem AI,
etykieta noclegu bez pełnego adresu, komunikaty o limicie 5 planów dziennie.

## Definicja ukończenia
Każda historyjka US-001..011 ma ekran lub jawną adnotację „bez UI"; stany brzegowe pokryte; lista
pytań do analityka/architekta spisana.

## Eskalacja
Sprzeczność z wymaganiami lub ADR → pytanie do orkiestratora z propozycją.
```

## Do wykonania przez właściciela
1. Dodać plik `.claude/agents/designer.md` (opcjonalnie dopasować uprawnienia).
2. Sprawdzić, czy `guard-paths.ps1` akceptuje nową rolę (parametr `-Role`) i czy `docs/design/` nie wymaga wpisu w CODEOWNERS.
3. Dopisać rolę do `CLAUDE.md`/`docs/github.md`, jeśli wymieniają listę ról (np. lista agentów ról w `docs/github.md`).

## Wpływ
Koszty: brak (rola działa tylko na żądanie). Bezpieczeństwo: zakres zapisu ograniczony do `docs/design/`;
RODO: mockup używa wyłącznie danych wymyślonych.
