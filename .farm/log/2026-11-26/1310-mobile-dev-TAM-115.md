# 13:10  mobile-dev → reviewer, qa, orchestrator  |  TAM-115 (P3-05-CONTENTION), krok 2

- Zrobione: wdrożony ADR-0018 w `backend/functions/` (aplikacja bez zmian). Gdy kilka próśb o plan przychodzi
  naraz i transakcja limitu zostaje przerwana 3 razy, użytkownik dostaje `ai_busy` (odliczanie 60 s, automatyczne
  ponowienie), a nie ogólny błąd `internal`. Limit nie jest wtedy zużyty, model nie jest wywoływany.
  1. **3 próby** (`limits.ts`: `QUOTA_TX_MAX_ATTEMPTS = 3`, `runQuotaTransaction`). Wszystkie trzy transakcje limitu
     (`reserveQuota`, `releaseQuota`, `releaseBusyQuota` w `index.ts`) wywołują `runTransaction(fn, { maxAttempts: 3 })`.
     Ponowienia i odczekanie robi SDK, własnej pętli nie ma; `preferRest` nie włączony.
  2. **Kontencja → `ai_busy`** (`limits.ts` `isQuotaContention`: tylko liczbowy `code` 10 albo 409;
     `endpoints.ts` `generatePlanCore`): `AppError("ai_busy", { retryAfterSec: 60, slotReleased: true })`
     (stała `AI_BUSY_RETRY_AFTER_SEC` wspólna z 429). Bez `releaseQuota`/`releaseBusyQuota`, bez zmiany
     `busyReleased`, bez `quotaRelease`. Każdy inny błąd rezerwacji zostaje `internal`.
  3. **Logi** (tylko liczby i stałe kody): nowe pole `reserveTries` (ile razy SDK uruchomiło funkcję transakcji
     rezerwacji; licznik `onTry` przekazany do `Deps.reserveQuota`), przy kontencji `stopReason = contention`.
     `reserveTries` jest tylko, gdy generowanie doszło do rezerwacji (po zgodach i `aiEnabled`).
  4. **Uwaga z przeglądu PR #184** (osobny commit, ADR-0018 pkt 11–12): `ai.ts` `modelConfigError(env)`; odrzucony
     `AI_ENDPOINT_OVERRIDE` / `AI_ATTEMPT_TIMEOUT_MS` przy poprawnym `AI_MODEL_ID`/`AI_LOCATION` daje w logu
     `configError = ai_endpoint_override_rejected`, brak/niedozwolona konfiguracja AI nadal `ai_config_invalid`.
     Kod liczony raz w `index.ts`, podawany przez `Deps.modelConfigError`. Odpowiedź bez zmian (`ai_unavailable`,
     `slotReleased = true`), wartości URL-a ani timeoutu nie trafiają do logu.
- Testy: `npm run lint` OK, `npm run typecheck` OK, `npm test` 434/434 (19 plików). Nowe testy:
  `quota.test.ts` (`isQuotaContention`, `maxAttempts = 3`, sukces po 1–2 przerwanych próbach, wyczerpanie → nie więcej
  niż 3 uruchomienia), `generate-plan-flow.test.ts` (ABORTED 10 i 409 → `ai_busy` z `retryAfterSec = 60`,
  `slotReleased = true`, bez modelu i zwrotu, log `contention` + `reserveTries = 3`; kod 14 → `internal`; sukces po
  1–2 przerwanych próbach z wycofaniem zapisów → 1 slot, `reserveTries` 2–3; zwykła rezerwacja → `reserveTries = 1`;
  `configError` przy braku modelu), `ai-endpoint-override.test.ts` (`modelConfigError`).
  Emulator (EMU, przez `.farm/test-lock.ps1`, bez zmian w testach): `p3-05-generate-plan.int.mjs`
  17/17 OK (EMU-16 i EMU-17 zielone). W tym przebiegu emulator nie przerwał żadnej transakcji: 0 × `internal`,
  0 × `stopReason=contention`, wszystkie 63 rezerwacje z `reserveTries=1` (4 × `ai_busy` to scenariusze 429 z atrapy).
  Kontencja jest niedeterministyczna, więc ścieżkę `contention` pokrywają testy jednostkowe.
- Artefakty: `backend/functions/src/{limits,index,endpoints,handler,logger,ai}.ts`,
  `backend/functions/test/{quota,generate-plan-flow,ai-endpoint-override,endpoints}.test.ts`,
  `backend/functions/test/helpers/fakes.ts`
- Decyzje: brak nowych (wdrożenie ADR-0018). Kontrakt `posrednik-api.md` v0.7 zgodny z kodem, bez potrzeby zmian.
- Do zrobienia przez odbiorcę: recenzja (reviewer), potem QA według sekcji „Dla QA” w
  `.farm/log/2026-11-26/1254-architect-TAM-115.md` i niżej.
- Pytania/blokady: brak.

## Dla QA (krok 3, ten sam PR)

- Usuń tolerancję `TEMP_TOLERATE_INTERNAL_UNTIL_TAM_115` w `tests/firebase-emulator/p3-05-generate-plan.int.mjs`
  i asercje EMU-16/17 zmień dokładnie wg dziennika architekta (pkt 1–5). Ja tego pliku nie zmieniałem.
- Kontencja daje teraz `ai_busy` z `details = { code: "ai_busy", retryAfterSec: 60, slotReleased: true }`
  (HttpsError `unavailable`), więc `internal` nie powinien się już pojawiać. Wyjątek: inny kod gRPC niż ABORTED po
  3 próbach (np. 14 UNAVAILABLE, 4 DEADLINE_EXCEEDED) nadal daje `internal` (ADR-0018 pkt 5); jeśli emulator taki
  zwróci, zgłoś to jako znalezisko z `errorCode` z logu, nie dodawaj tolerancji.
- W logu funkcji emulatora: przy kontencji `errorCode=ai_busy`, `stopReason=contention`, `reserveTries=3`, brak
  `quotaRelease` i `calls`. Przy udanych generowaniach `reserveTries` 1–3.
- Kontencja nic nie zapisuje: konto, które dostało tylko `ai_busy` z kontencji, nie ma `usage/{uid}` albo ma
  `count = 0`, `busyReleased = 0`.
- Czas: rezerwacja czeka teraz najwyżej ok. 4 s (3 próby) zamiast do ok. 12 s, więc odpowiedzi `ai_busy` z kontencji
  powinny przychodzić szybciej niż dawne `internal` (ok. 18–23 s).

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-115 – krok 2 (mobile-dev) zrobiony, push na `fix/TAM-115-rownoczesne-prosby`, draft PR #185;
  następnie recenzja, potem QA (krok 3).
- Zadania – nowe: brak.
- Pytania otwarte – nowe: brak.
- Pytania otwarte – zamknięte: brak.
