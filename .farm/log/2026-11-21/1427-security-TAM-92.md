# 14:27  security → orchestrator  |  TAM-92 (P3-05-REG)
- Zrobione: Rejestr danych osobowych v0.8, pozycja D10 opisuje stan faktyczny po P3-05: `generatePlan` (PR #136, #138, #142) zapisuje `usage/{uid}` z polami `day`, `count`, `released`, `updatedAt`, `expireAt`. `released` to licznik techniczny zwrotów próby (najwyżej 2 na dobę), nie nowa kategoria danych; retencja bez zmian (TTL O4-b). Adnotację „P3-05 jeszcze nie zapisuje `usage`” zastąpiłem stanem faktycznym.
- Sprawdzone w kodzie (`backend/functions/src/limits.ts`, `index.ts`, `endpoints.ts`, `logger.ts`, `backend/firestore.indexes.json`):
  - `UsageWrite` = dokładnie `day`, `count`, `released`, `updatedAt`, `expireAt`; ten sam kształt przy rezerwacji i zwrocie. `expireAt` = `usageExpireAt(now)` (O4-b, 2 dni po końcu doby), zgodnie z rejestrem.
  - `usage_global/{day}`: tylko `count` i `expireAt` (now + 7 d), bez UID – zgodnie z rejestrem, brak nowych danych osobowych.
  - Brak innych kolekcji poza `users/{uid}/consents` (D3, bez zmian).
  - Logi: `logger.ts` przepuszcza tylko pola z listy dozwolonych; UID wyłącznie jako HMAC (`uidHash`). `quotaRelease` ma stałe kody (`released`, `release_capped`, `release_stale_day`, `release_failed`), bez UID, dnia ani treści. Danych osobowych w logach nie znalazłem.
  - Reguły TTL dla `usage.expireAt` i `usage_global.expireAt` są w `firestore.indexes.json`.
- **Rozbieżność:** rejestr mówi „całość usuwana z kontem (`deleteAccount`)”, a `deleteAccountCore` jeszcze nie usuwa `usage/{uid}` (`endpoints.ts`: `TODO P3-08`, zwraca `not_implemented`). Do czasu P3-08 dokument usuwa tylko TTL (do ok. 4 dni). Opisane w D10.
- Artefakty: `docs/security/personal-data-register.md`
- Decyzje: brak
- Do zrobienia przez odbiorcę: patrz niżej.
- Pytania/blokady: brak

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-92: review
- Zadania – nowe: brak nowych; przypomnienie do istniejących – (1) O4-2 (wdrożenie TTL w dev) powinno być wykonane przed włączeniem modelu w dev (TAM-90), bo od tego momentu `usage/{uid}` zawiera realne dane; adnotacja „TTL niewdrożony” zostaje do potwierdzenia wdrożenia w dev i prod. (2) P3-08 musi usuwać `usage/{uid}` w `deleteAccount` (jest w TODO); do tego czasu rejestr opisuje lukę.
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak
