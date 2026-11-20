# 14:10  mobile-dev → reviewer, orchestrator  |  SEC-09-LIMIT25
- Zrobione: domyślny limit globalny generowań zmieniony z 50 na 25/dobę (ADR-0014 Aneks A pkt 3). `SAFE_RUNTIME_DEFAULTS.globalDailyLimit = 25`; fallbacki `globalDailyLimit` i `perUserDailyLimit` w `loadRuntime` (`index.ts`) korzystają teraz z `SAFE_RUNTIME_DEFAULTS` (jedno źródło prawdy, `perUserDailyLimit` bez zmiany wartości – 5). Nowy test wartości domyślnych w `config.test.ts`. Testy (146), lint, typecheck, build – zielone.
- Artefakty: backend/functions/src/config.ts, backend/functions/src/index.ts, backend/functions/test/config.test.ts
- Decyzje: brak (wykonanie ADR-0014 Aneks A pkt 3). `docs/api/posrednik-api.md` nie opisuje wartości domyślnej limitu globalnego – bez zmian; `docs/data/model-danych.md` już mówi 25. `limits.test.ts` (50 jako dane wejściowe `decideQuota`) bez zmian – logika nie zależy od wartości.
- Do zrobienia przez odbiorcę:
  - reviewer – przegląd PR (`review:ok`).
  - owner – merge; ustawienie `config/runtime.globalDailyLimit = 25` tam, gdzie dokument istnieje (SEC-09-CAP), bo wartość z Firestore ma pierwszeństwo nad domyślną.
- Pytania/blokady: brak. Zmiana nie dotyka UI – bez QA na telefonie. Nic nie wdrożono do Firebase.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: SEC-09-LIMIT25: review
- Zadania – nowe: brak
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak
