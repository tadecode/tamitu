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
UX/UI (`docs/ux/`), DBA (`docs/data/`, migracje), DevOps/Mobile DevOps
(CI, podpisywanie, dystrybucja testowa), Reviewer (przegląd zmian),
Technical Writer (dokumentacja, changelog).
