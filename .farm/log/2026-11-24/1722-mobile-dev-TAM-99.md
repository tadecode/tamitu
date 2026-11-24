# 17:22  mobile-dev → orchestrator, reviewer, qa, owner  |  TAM-99 (P3-05-429-IMPL)
- Zrobione: implementacja ADR-0016 i `posrednik-api.md` v0.6. **Backend:** najwyżej 3 wywołania modelu i 2 próby płatne
  (429 nie jest płatne), odczekanie 2–4 s przed wywołaniem 2 i 4–8 s przed 3 (z rozrzutem), budżet 100 s (kolejne wywołanie
  tylko przy ≥ 45 s zapasu), lista błędów walidacji przechodzi przez 429. Same 429 → `ai_busy` (`unavailable`,
  `retryAfterSec = 60`, `slotReleased`); przy `ai_busy` wraca slot konta i `usage_global`, bez zwiększania `released`,
  bezpiecznik `busyReleased` ≤ 10 na dobę. Logi: `waitMs`, `billable` (wpis `generatePlan.attempt`), `calls`, `stopReason`
  (wpis `generatePlan`), `quotaRelease` `busy_released`/`busy_capped`; tylko liczby i stałe kody. `AI_PROMPT_VERSION`
  (plan-v1/plan-v2, TAM-95) działa bez zmian. **Aplikacja:** mapowanie `ai_busy`, kontroler stanu i widok EK-07
  „asystent AI przeciążony” (stany A–E ze specyfikacji), teksty `.arb` dokładnie ze specyfikacji (ICU plural).
- Artefakty: `backend/functions/src/{generate,limits,endpoints,index,errors,logger,handler,ai}.ts`,
  `backend/functions/test/{generate,generate-plan-flow,quota,endpoints}.test.ts`, `backend/functions/test/helpers/fakes.ts`;
  `lib/core/errors/{app_failure,failure_messages}.dart`, `lib/core/ui/{components,tokens}.dart` (CMP-02 tonalny, slot
  `detail` w CMP-18), `lib/features/generation/application/ai_busy_controller.dart`,
  `lib/features/generation/presentation/ai_busy_view.dart`, `lib/l10n/*`, `test/core/ai_busy_failure_test.dart`,
  `test/features/generation/ai_busy_view_test.dart`
- Decyzje (implementacyjne, w granicach ADR-0016; do wiadomości recenzenta):
  1. Wynik mieszany według **ostatniego** błędu (pkt 7): `zła odpowiedź → 429 → 429` daje `ai_unavailable`, nie
     `ai_invalid_response`.
  2. Gdy same 429 skończą się na budżecie czasu (praktycznie niemożliwe: 429 przychodzi w ok. 1 s), wynik to nadal `ai_busy`
     (0 prób płatnych), a log ma `stopReason=time_budget`, żeby monitoring widział budżet. W pozostałych przypadkach `ai_busy`
     ma `stopReason=busy`.
  3. Zwrot `ai_busy` po północy: jak reguła 5 – nic nie zapisujemy, `slotReleased=false`, log `release_stale_day`.
     Nieudany zapis zwrotu: kod `ai_busy` zostaje, `slotReleased=false`, `release_failed` (reguła 6).
  4. Zwrot globalny zmniejsza `usage_global/{dzień rezerwacji}` (najniżej do 0) w tej samej transakcji co `usage/{uid}`;
     brak dokumentu globalnego = nic nie tworzymy.
  5. Aplikacja: wstecz systemowe w stanie C (ponawianie) nic nie robi – dialog anulowania CMP-15 należy do ekranu EK-07,
     którego jeszcze nie ma (niżej).
- Testy: backend `npm test` 376/376 zielone (atrapa modelu, wstrzykiwany zegar, `sleep` i losowość; przypadki z dziennika
  architekta 1500-TAM-96: `429→429→ok`, `429×3` → `ai_busy` i zwrot konta + globalny bez `released`, 11. `ai_busy` →
  `slotReleased=false`, `invalid→429→ok` z listą błędów, `timeout→429→429` → `ai_unavailable` ze zwykłym zwrotem,
  `timeout→429` przy budżecie → `time_budget`, `timeout→timeout`, `invalid→invalid`, `5xx→5xx`, 400, granice odczekania,
  zwrot po północy), `typecheck` i `lint` czyste. Aplikacja `flutter test` 213/213, `flutter analyze` bez uwag; testy
  widgetowe na fałszywym zegarze: odliczanie i etykieta TalkBack, pasek, automat po 60 s, brak drugiego automatu, „Spróbuj
  teraz” zastępuje automat, podwójne dotknięcie, stany B/D/E, tło przed i po terminie (także zamrożone timery), ogłoszenia
  45/30/15 s, wstecz, 200% tekstu, PL/EN, jasny/ciemny. Bez urządzenia, bez płatnych wywołań i wdrożeń; `.github/` i CI bez zmian.
- Do zrobienia przez odbiorcę: reviewer – przegląd PR-a; owner – **merge dopiero po TAM-97** (Billing: czy 429 jest
  płatne). Jeśli 429 okaże się płatne, PR wraca do decyzji właściciela (ADR-0016 „Kolejność”).
- Pytania/blokady: **ekranów EK-05 (formularz) i EK-07 (generowanie) nie ma jeszcze w `lib/`** – w aplikacji nie ma
  wywołania `generatePlan`. Stan `ai_busy` jest więc gotowym do osadzenia kontrolerem i widokiem (`AiBusyController` +
  `AiBusyView`), przetestowanym w izolacji. Podłączenie do EK-07 (pasek „Nowa podróż”, nowy `requestId` przy ponowieniu,
  przejście do EK-08/EK-05, dialog CMP-15 w stanie C, rotacja tekstów EK-07) należy do zadania implementującego EK-07.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-99: review (PR do `main`; **merge po TAM-97**)
- Zadania – nowe:
  - (do zadania EK-07 / generowania planu, mobile-dev, zależność: TAM-99) „Podłączyć `AiBusyView` w EK-07”: przy
    `FailureKind.aiBusy` z `generatePlan` pokazać `AiBusyView` w EK-07, `retry` = `generatePlan` z tymi samymi danymi
    i nowym `requestId`, `onSuccess` → EK-08, `onFailure` → mapowanie EK-16 (EK-05), CMP-15 w stanie C. Jeśli takie zadanie
    już istnieje – dopisać ten punkt do jego kryteriów.
  - security (opcjonalnie, jak w dzienniku architekta): pole `busyReleased` w opisie D10 rejestru, jeśli rejestr wymienia
    pola `usage/{uid}`.
  - architect (opcjonalnie): w `posrednik-api.md` dopisać, że wynik mieszany idzie za ostatnim błędem (decyzja 1 wyżej)
    i że `stopReason=time_budget` może towarzyszyć `ai_busy` (decyzja 2).
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak
