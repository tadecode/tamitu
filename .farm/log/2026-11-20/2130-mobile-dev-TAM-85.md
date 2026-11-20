# 21:30  mobile-dev → orchestrator  |  TAM-85
- Zrobione: B2 – `predeploy` w `backend/firebase.json` na `npm --prefix functions ...` (bez zmiennej powłoki, działa w Windows i Linuksie). B3 – plik środowiska dev dla funkcji (`ENVIRONMENT=dev`) i wyjątek w `.gitignore` tylko dla niego. Lint, typecheck, testy i build backendu zielone lokalnie.
- Artefakty: `backend/firebase.json`, `.gitignore`, `backend/functions/.env.tamitu-dev-tadecode`
- Decyzje: brak (wykonanie O-TAM84-1 „W repo”)
- Do zrobienia przez orkiestratora: po CI i `review:ok` merge przez właściciela; potem odblokować krok wdrożenia z TAM-84 (PR #128).
- Pytania/blokady: brak

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-85: review
- Zadania – nowe: brak
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak
