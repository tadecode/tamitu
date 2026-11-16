# Szablon kontraktu roli

Nowa rola = plik `.claude/agents/<nazwa>.md`:

```
---
name: <nazwa-kebab-case>
description: <kiedy używać tej roli – jedno zdanie>
tools: <minimalny zestaw narzędzi>
model: <haiku | sonnet | opus; patrz „Dobór modelu">
---

# <Rola>

## Misja
## Wejścia
## Wyjścia
## Uprawnienia        (katalogi, które może zmieniać)
## Czego nie robi
## Definicja ukończenia
## Eskalacja
```

## Dobór modelu
Drogi model tam, gdzie błąd jest drogi, a decyzja rzadka; tańszy tam, gdzie pracy jest dużo i jest powtarzalna.

| Model | Role | Kiedy |
|---|---|---|
| `opus` | architect, security, reviewer | decyzje trudne do cofnięcia, wyłapywanie błędów innych |
| `sonnet` | analyst, ux, mobile-dev, qa, dba, data-analyst; sesje orkiestratora i Stewarda | większość pracy, według jasnych zasad |
| `haiku` | role mechaniczne (np. przyszły publisher) | czynności bez oceny merytorycznej |
| `fable` | żadna domyślnie | tylko na decyzję właściciela, np. po dwóch nieudanych próbach architekta |

Orkiestrator nie zmienia modelu roli sam; zmiana przydziału to zmiana pliku roli (PR, zatwierdza właściciel).
Model głównej sesji orkiestratora wybiera właściciel w aplikacji; Steward startuje z `--model sonnet` (`start-steward.ps1`).

## Role planowane po pilocie
DevOps/Mobile DevOps (CI, podpisywanie, dystrybucja testowa), Technical Writer (dokumentacja, changelog).
(UX/UI, DBA, analityk danych i Reviewer są już w szablonie: `.claude/agents/ux.md`, `dba.md`, `data-analyst.md`, `reviewer.md`.)
