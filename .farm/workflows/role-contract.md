# Szablon kontraktu roli

Nowa rola = plik `.claude/agents/<nazwa>.md`:

```
---
name: <nazwa-kebab-case>
description: <kiedy używać tej roli – jedno zdanie>
tools: <minimalny zestaw narzędzi>
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

## Role planowane po pilocie
DevOps/Mobile DevOps (CI, podpisywanie, dystrybucja testowa), Technical Writer (dokumentacja, changelog).
(UX/UI, DBA, analityk danych i Reviewer są już w szablonie: `.claude/agents/ux.md`, `dba.md`, `data-analyst.md`, `reviewer.md`.)
