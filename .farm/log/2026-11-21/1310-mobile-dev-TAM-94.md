# 13:10  mobile-dev → orchestrator (dalej reviewer, architect)  |  TAM-94 (P3-05-SLOTMSG-DEV)
- Zrobione: serwer wysyła `details.slotReleased` przy `ai_unavailable` i `ai_invalid_response` (kontrakt
  `posrednik-api.md` v0.5), a log `generatePlan` ma pole `quotaRelease` ze stałym kodem (uwaga N2 z
  `docs/reviews/PR-138.md`). Aplikacja czyta to pole i pokazuje 1 z 3 tekstów dla każdego kodu: „nie wlicza się”,
  „została wliczona” albo „mogła zostać wliczona”. Teksty PL/EN są skopiowane 1:1 z tabeli w
  `.farm/log/2026-11-21/0948-architect-TAM-93.md` (zaakceptowane przez właściciela). 0 płatnych wywołań, bez wdrożeń,
  `.github/` i CI nietknięte.
- Artefakty:
  - serwer: `backend/functions/src/limits.ts` (`ReleaseOutcome`, `planReleaseOutcome`; `planRelease` zostaje jako
    nakładka), `src/index.ts` (`releaseQuota` zwraca wynik), `src/endpoints.ts` (`slotReleased`, `RELEASE_LOG`),
    `src/errors.ts` (`details` może mieć wartość logiczną);
  - testy serwera: `test/generate-plan-flow.test.ts`, `test/quota.test.ts`, `test/helpers/fakes.ts`,
    `test/consents.test.ts` (tylko typ);
  - aplikacja: `lib/core/errors/app_failure.dart` (`AppFailure.slotReleased`), `lib/core/errors/failure_messages.dart`,
    `lib/l10n/app_pl.arb`, `lib/l10n/app_en.arb` (+ wygenerowane `app_localizations*.dart`);
  - testy aplikacji: `test/core/slot_released_message_test.dart` (widgetowe), `test/core/app_failure_test.dart`.
- Decyzje:
  - `slotReleased = true`: błąd przed rezerwacją (`aiEnabled=false`, brak konfiguracji modelu, limit globalny) albo
    udany zwrot. `false`: limit 2 zwrotów wyczerpany, zmiana doby przed zwrotem albo błąd zapisu zwrotu. Przy
    `internal` pola nie ma (zgodnie z kontraktem).
  - Aplikacja przyjmuje tylko prawdziwą wartość logiczną; inny typ lub brak pola = „mogła zostać wliczona”
    (kontrakt: bez `slotReleased = true` nie obiecujemy zwrotu).
  - Kody `quotaRelease`: `released`, `release_capped`, `release_failed` jak w kontrakcie, plus
    **`release_stale_day`** (zwrot po północy, reguła 5). Kontrakt v0.5 tego przypadku nie nazywa; bez osobnego kodu
    nie dałoby się go odróżnić w logach od braku zwrotu. To stała bez danych osobowych (pole jest już na liście
    dozwolonych w `logger.ts`). Do dopisania w kontrakcie przez architekta (niżej).
  - Opisy `@…` dodałem w obu plikach `.arb` (w `app_pl.arb` po polsku). Generator bierze opisy z szablonu
    `app_en.arb`; w `app_pl.arb` są tylko dla tłumacza.
  - Zmieniłem też istniejące teksty `errorAiUnavailableBody` i `errorAiInvalidBody` („do limitu” → „do dzisiejszego
    limitu”), bo tak stoi w zaakceptowanej tabeli.
- Testy (bez urządzenia): `backend/functions` – `vitest` 17 plików, 314 testów zielone; `typecheck`, `lint`, `build`
  bez błędów. Flutter – `flutter test` 178 testów zielone, `flutter analyze` bez uwag. Nowe testy: 3. błąd w dobie
  → `slotReleased=false` i `quotaRelease` `released`, `released`, `release_capped`; błąd przed rezerwacją → `true`
  bez próby zwrotu; zwrot po północy → `false`, `release_stale_day`; nieudany zapis → `false`, `release_failed`;
  widgetowe: 3 warianty × 2 kody × PL/EN z dokładnym tekstem z tabeli.
- Do zrobienia przez odbiorcę: reviewer – przegląd PR-a; architect – dopisać `release_stale_day` do listy kodów
  `quotaRelease` w `posrednik-api.md` pkt 2 (albo zdecydować inaczej, wtedy poprawię kod).
- Pytania/blokady: brak.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-94: review (PR otwarty, czeka na przegląd i merge właściciela). Po merge'u TAM-90
  (P3-05-CFG) nie jest już blokowane przez TAM-94; nadal zależy od O4-2, B-1, W-1.
- Zadania – nowe: **P3-05-SLOTMSG-DOC** (architect): dopisać kod `release_stale_day` w `docs/api/posrednik-api.md`
  pkt 2 „Logi” (zwrot po północy, reguła 5). Zależy od: merge tego PR-a. Mała zmiana, bez wpływu na aplikację.
  TAM-93 można przenieść do done po merge'u tego PR-a.
- Pytania otwarte – nowe: brak.
- Pytania otwarte – zamknięte: brak.
