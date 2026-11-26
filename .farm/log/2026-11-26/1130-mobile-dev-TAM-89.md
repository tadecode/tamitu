# 11:30  mobile-dev → qa, reviewer, orchestrator  |  TAM-89 (P3-05-EMU), część backendowa

- Zrobione: `generatePlan` w emulatorze Firebase może wywołać lokalną atrapę Vertex zamiast prawdziwego modelu.
  Dzięki temu QA sprawdzi rezerwację i zwrot limitu na prawdziwym Firestore (emulator). Bez atrapy funkcja kończyła
  na `ai_unavailable` przed rezerwacją.
  1. **`AI_ENDPOINT_OVERRIDE`** (`ai.ts` `parseAiEndpointOverride`, `createPlanModel`). Funkcja przyjmuje ją tylko
     wtedy, gdy jednocześnie: `FUNCTIONS_EMULATOR=true`, projekt `demo-*` i adres `http://127.0.0.1` albo
     `http://localhost` bez loginu, zapytania i fragmentu. Warunek `demo-*` dodałem ponad propozycję z dziennika
     TAM-18. Taki projekt nie istnieje w Google Cloud, więc nawet podrobione `FUNCTIONS_EMULATOR` we wdrożeniu nie
     pomoże. Zasada fail-closed: zmienna ustawiona w złym miejscu wyłącza model (`ai_unavailable` przed rezerwacją,
     `configError=ai_config_invalid`). Funkcja nigdy nie przełącza się wtedy po cichu na prawdziwy Vertex.
     W trybie atrapy nie jest pobierany token ADC. Funkcja wysyła stały napis `emulator-fake-token`.
  2. **`AI_ATTEMPT_TIMEOUT_MS`** (100–45000 ms, tylko razem z ważnym override). Skraca czas próby, żeby scenariusz
     `timeout` trwał sekundy, a nie 2 × 45 s. W produkcji ustawienie tej zmiennej też wyłącza model (fail-closed).
  3. **Atrapa** `backend/functions/test/emulator/vertex-fake.mjs` (Node 22, bez zależności, nasłuch tylko na
     127.0.0.1). Akceptuje tylko `emulator-fake-token` (inny token → 401). Ma 8 scenariuszy, sterowanych z testu
     (`enqueue`, `setDefault`) albo przez HTTP (`/__fake/control`).
  4. **Uruchamiacz** `backend/functions/test/emulator/run-emulator-tests.ps1` ustawia zmienne tylko w swoim procesie,
     tworzy losowy testowy pieprz w ignorowanym `.secret.local`, buduje funkcje i uruchamia `emulators:exec` na
     `demo-tamitu-qa`. Opis: `backend/eval/README.md`, sekcja „Atrapa modelu dla emulatora Firebase”.
- Artefakty: `backend/functions/src/{ai,index}.ts`, `backend/functions/test/ai-endpoint-override.test.ts`,
  `backend/functions/test/vertex-fake.test.ts`, `backend/functions/test/emulator/{vertex-fake.mjs,vertex-fake.d.mts,smoke.int.mjs,run-emulator-tests.ps1}`,
  `backend/eval/README.md`.
- Testy: vitest 415/415 (w tym 39 nowych: strażnik override w dev i prod oraz 8 scenariuszy atrapy na prawdziwym
  dostawcy i pętli generowania), `tsc`, `eslint`, `build` bez błędów. Test dymny na emulatorach przez
  `.farm/test-lock.ps1 -Resource firebase-emulators`: **1/1**. Atrapa dostała 1 wywołanie, `usage/{uid}.count = 1`,
  a `expireAt` ma typ Timestamp. 0 płatnych wywołań, bez wdrożeń, bez zmian w `.github/` i CI.
- Pytania/blokady: brak. Zakres zgodny z ADR-0016 i ADR-0001 (dostawca za abstrakcją). Nowego ADR nie trzeba, bo
  zmiana działa tylko w emulatorze i nie zmienia kosztu (zasada 10).

## Dla orkiestratora
- Zadania – status: TAM-89 – część backendowa gotowa, PR **draft**. Następny krok: **qa** w tym samym worktree
  (`tamitu-wt\TAM-89-testy-emulatora`) i tym samym PR dopisuje testy emulatora w `tests/firebase-emulator/`.
  Po QA: recenzja, potem merge właściciela.
- Instrukcja dla QA:
  - Uruchamianie (z katalogu głównego): `.farm/test-lock.ps1 -Resource firebase-emulators -Command "powershell
    -NoProfile -ExecutionPolicy Bypass -File backend/functions/test/emulator/run-emulator-tests.ps1 -Tests
    tests/firebase-emulator/<plik>.int.mjs"`. Skrypt ustawia całą konfigurację funkcji, łącznie z atrapą.
  - Test sam uruchamia atrapę: `const fake = await startVertexFake({ port: 8787 })` (import z
    `backend/functions/test/emulator/vertex-fake.mjs`). `fake.enqueue(...)` ustawia scenariusze kolejnych wywołań,
    `fake.setDefault(...)` scenariusz domyślny, a `fake.calls` zwraca liczbę i statusy wywołań. `fake.reset()` czyści
    stan między testami. Przygotowanie użytkownika (Auth, `config/runtime`, dwie zgody) jest w `smoke.int.mjs`.
  - Scenariusze: `valid` (sukces), `invalid` (2 wywołania → `ai_invalid_response`), `blocked` (1 →
    `ai_invalid_response`), `busy` (3 × 429 → `ai_busy` i zwrot slotu ADR-0016), `server_error` / `bad_body` /
    `timeout` (2 → `ai_unavailable` i zwrot `released`), `config_error` (403, 1 → `ai_unavailable`).
    Mieszane przypadki przez kolejkę, np. `enqueue("busy","busy")` + domyślne `valid` = sukces po dwóch 429.
  - Uwaga: `server_error` i `busy` czekają 2–8 s między próbami (prawdziwy backoff ADR-0016). Jeden test `busy`
    trwa ok. 10 s.
- Zadania – nowe: brak.
- Pytania otwarte – nowe: brak.
