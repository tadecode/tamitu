# Protokół przekazań

Każde przekazanie pracy między agentami to wpis w `.farm/log/`
w pliku `YYYY-MM-DD.md` (nowe wpisy na końcu).

## Format wpisu

```
### HH:MM  <od-roli> → <do-roli>  |  <id zadania>
- Zrobione: <1–3 zdania>
- Artefakty: <ścieżki plików>
- Decyzje: <lub „brak"; ważne → ADR>
- Do zrobienia przez odbiorcę: <konkretnie>
- Pytania/blokady: <lub „brak">
```

## Brief orkiestratora dla roli (zlecenie)

```
Cel: <co ma powstać>
Wejścia: <pliki do przeczytania>
Wyjście: <artefakt i ścieżka>
Definicja ukończenia: <kryteria>
Ograniczenia: <zakres uprawnień, czas, koszty>
```
