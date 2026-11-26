# 12:54  architect → mobile-dev, qa (przez orchestrator)  |  TAM-115 (P3-05-CONTENTION)
- Zrobione: decyzja w sprawie F-1 (QA TAM-89, PR #184) zapisana jako ADR-0018 (proponowany). Wybrany wariant:
  jawnie 3 próby transakcji limitu (ponowienia robi SDK Firestore) + po wyczerpaniu prób rezerwacji (ABORTED)
  kod `ai_busy` z `retryAfterSec = 60` i `slotReleased = true`. Bez shardów, bez zmian w modelu danych i w aplikacji.
  Kontrakt `posrednik-api.md` v0.7, `firestore-ttl-indexes.md` v0.4 (reguła 7 w pkt 3.2), tabela diagnostyki
  w `deploy-dev-functions.md`.
- Artefakty: `docs/adr/0018-rownoczesne-rezerwacje-limitu.md`, `docs/api/posrednik-api.md`,
  `docs/data/schema/firestore-ttl-indexes.md`, `docs/architecture/deploy-dev-functions.md`
- Decyzje: ADR-0018 (uzupełnia ADR-0016 pkt 6; ADR-0016 bez zmian). Uwaga z ponownego przeglądu PR #184
  (odrzucony `AI_ENDPOINT_OVERRIDE` logowany jako `ai_config_invalid`) **wchodzi do tego PR-a** jako osobny mały
  commit (ADR-0018 pkt 11–12). Koszt: 0 PLN (najgorszy przypadek odczytów Firestore maleje z 10 do 6 na rezerwację).
- Do zrobienia przez odbiorcę: mobile-dev i QA według sekcji niżej, w tym samym worktree i PR-ze.
- Pytania/blokady: brak. Zatwierdzenie ADR-0018: właściciel przy merge'u PR-a.

## Dla mobile-dev (krok 2, tylko `backend/functions/`)

Źródło zasad: ADR-0018 sekcje A–C i E. Aplikacja (`lib/`) bez zmian.

1. **`maxAttempts: 3`** w `reserveQuota`, `releaseQuota`, `releaseBusyQuota` (`src/index.ts`) przez nazwaną stałą
   (np. `QUOTA_TX_MAX_ATTEMPTS = 3` w `limits.ts`). Bez własnej pętli ponowień. Nie włączać `preferRest`.
2. **`isQuotaContention(e: unknown): boolean`** (czysta funkcja w `limits.ts`): `true` tylko dla `code === 10`
   (liczba, gRPC ABORTED) albo `code === 409`. Testy jednostkowe: 10, 409 → true; 14, 4, 13, 8, `"aborted"` (string),
   `undefined`, `null`, `Error` bez `code`, `AppError` → false.
3. **`generatePlanCore`** (`src/endpoints.ts`): wywołanie `deps.reserveQuota` w `try/catch`. Gdy
   `isQuotaContention(e)`: `ctx.stopReason = "contention"` i `throw new AppError("ai_busy", { retryAfterSec: 60, slotReleased: true })`
   (stała 60 wspólna z dotychczasowym `ai_busy`, bez duplikacji liczby). **Bez** wywołania `releaseQuota`/`releaseBusyQuota`,
   bez zmiany `busyReleased`, bez `quotaRelease`. Każdy inny błąd: `throw e` (dalej `internal`).
4. **`reserveTries`**: `reserveQuota` liczy uruchomienia funkcji transakcji (licznik na początku callbacku) i przekazuje
   liczbę do `ctx.reserveTries` także przy błędzie (np. przez parametr/callback w `Deps.reserveQuota` albo pole w wyniku
   i w błędzie, do wyboru autora, byle testowalne). Nowe pole w `HandlerContext` i `pick()` (`src/handler.ts`), liczba 1–3.
5. **Override (ADR-0018 pkt 11–12):** gdy model nie powstał, bo `parseAiEndpointOverride` dał `rejected` (przy poprawnym
   `AI_MODEL_ID`/`AI_LOCATION`), `ctx.configError = "ai_endpoint_override_rejected"`; inaczej jak dziś `ai_config_invalid`.
   Np. eksport z `ai.ts` czystej funkcji `modelConfigError(env): "ai_config_invalid" | "ai_endpoint_override_rejected" | undefined`,
   wyliczonej raz w `index.ts` i podanej przez `Deps`. Nigdy nie logować wartości URL-a/timeoutu. Odpowiedź bez zmian
   (`ai_unavailable`, `slotReleased = true`). Osobny commit.
6. **Testy jednostkowe** (`backend/functions/test/`): (a) `reserveQuota` rzuca `{ code: 10 }` → `ai_busy`,
   `details = { code: "ai_busy", retryAfterSec: 60, slotReleased: true }`, model nie wywołany, `releaseQuota` i
   `releaseBusyQuota` nie wywołane, log `stopReason=contention`, `reserveTries` obecne, brak `quotaRelease`;
   (b) `{ code: 409 }` → to samo; (c) `{ code: 14 }` → `internal`; (d) zwykła rezerwacja → `reserveTries = 1` w logu;
   (e) override odrzucony → `configError = ai_endpoint_override_rejected`, brak AI → `ai_config_invalid`, w logu brak URL-a.
7. **Dokumentacja:** sprawdzić, że kod zgadza się z `posrednik-api.md` v0.7; jeśli coś trzeba zmienić w kontrakcie,
   zgłosić architektowi (nie zmieniać w `docs/api/`).

## Dla QA (krok 3, `tests/firebase-emulator/p3-05-generate-plan.int.mjs`, `docs/qa/`)

1. **Usunąć** stałą `TEMP_TOLERATE_INTERNAL_UNTIL_TAM_115` i wszystkie jej użycia (komentarze `TEMPORARY (TAM-115)`,
   diagnostyka „F-1, tolerated TEMPORARILY”). `internal` nie może być dozwolonym kodem w EMU-16/17 (kryterium akceptacji).
2. **EMU-16** (jedno konto, 7 równoległych): dozwolone kody `ok`, `limit_exceeded`, `ai_busy`, `emu_transport`.
   Każde `ai_busy` ma `retryAfterSec === 60` i `slotReleased === true`. Gdy wszystko odpowiedziało:
   `ok + limit_exceeded + ai_busy === 7`, `count === ok.length`; gdy `ai_busy === 0`, nadal dokładnie 5 × ok i 2 × `limit_exceeded`.
   Gdy `ai_busy > 0`: `ok.length <= 5`, a `limit_exceeded <= 7 − 5` (dokładne liczby zależą od kolejności).
3. **EMU-17** (5 kont, 10 równoległych, 3 wolne sloty): dozwolone `ok`, `ai_unavailable`, `ai_busy`, `emu_transport`;
   każde `ai_busy` jak wyżej; gdy `ai_busy === 0`, dokładnie 3 × ok. Niezmienniki bezpieczeństwa bez zmian (liczniki =
   wywołania modelu = przyznane plany; `usage_global = start + suma kont`).
4. **Nowa asercja „kontencja nic nie zużywa”:** dla kont, których wszystkie odpowiedzi to `ai_busy` (z kontencji),
   `usage/{uid}` nie istnieje albo ma `count = 0` i `busyReleased` bez zmian (0). Wspólnie: liczba wywołań atrapy =
   liczba `ok` + błędów po rezerwacji (w tych testach atrapa zwraca `valid`, więc = `ok`).
5. **Diagnostyka zamiast tolerancji:** liczba `ai_busy` z kontencji w `t.diagnostic(...)` (bez wymogu, że wystąpi, bo
   emulator jest niedeterministyczny). Deterministyczne pokrycie mapowania dają testy jednostkowe mobile-dev (pkt 6a–c).
6. **Logi (opcjonalnie, jeśli test czyta logi emulatora):** przy `ai_busy` z kontencji `stopReason=contention`, `reserveTries=3`.
7. Raport jako komentarz w PR (zasada „Jeden PR na zadanie”); `docs/qa/QA-TAM-89-emulator.md` F-1 → oznaczyć jako
   naprawione w TAM-115 (nowy wpis/aneks raportu, bez przepisywania historii).

## Dla orchestratora (zadania i pytania)
- Zadania – status: TAM-115 – krok 1 (architect) zrobiony, draft PR; następnie mobile-dev (krok 2) w tym samym worktree,
  potem recenzja, potem QA (krok 3).
- Zadania – nowe: brak. Uwaga z ponownego przeglądu PR #184 (log odrzuconego override) wchodzi do TAM-115, nie trzeba
  osobnego zadania.
- Pytania otwarte – nowe: brak. Do zatwierdzenia przez właściciela przy merge'u: ADR-0018 (status „proponowany”).
- Pytania otwarte – zamknięte: brak.
