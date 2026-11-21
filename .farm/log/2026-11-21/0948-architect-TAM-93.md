# 09:48  architect → orchestrator (dalej ux, mobile-dev)  |  TAM-93 (P3-05-SLOTMSG), TAM-91 (P3-05-DOC)
- Zrobione: kontrakt `posrednik-api.md` (v0.5) opisuje teraz zwrot próby tak, jak działa kod i jak zdecydował właściciel
  (O-TAM18-3): najwyżej 2 zwroty na konto na dobę, bez zwrotu po `internal`, `usage_global` nigdy nie maleje. Doszło
  pole błędu `details.slotReleased`, żeby aplikacja mówiła prawdę, czy próba wróciła. Uzupełniłem też dokumenty z TAM-91:
  reguła ostatniego dnia zatwierdzona, kody `validationErrors` i `quotaRelease` w logach, warunki O4-2/B-1/W-1 przed
  zmiennymi AI, lista ponawianych błędów Vertex, pole `usage.released` w modelu danych. Kodu i plików `.arb` nie zmieniałem.
  0 płatnych wywołań, `.github/` i CI nietknięte.
- Artefakty: `docs/api/posrednik-api.md` (pkt 2 „Błędy”, nowy „Slot limitu i zwrot próby”, pkt 6, pkt 7 v0.5),
  `docs/architecture/deploy-dev-functions.md` (sekcja 2 wiersz `generatePlan`, sekcja 9),
  `docs/architecture/p3-05-wymagania-generowania.md` (sekcja 3 pkt 3, sekcja 4), `docs/data/model-danych.md` (v0.7,
  `usage/{uid}`), `docs/data/schema/firestore-ttl-indexes.md` (v0.3, pkt 3.1, 3.2).
- Decyzje: nowe pole `details.slotReleased` (bool) przy `ai_unavailable` i `ai_invalid_response`. Wybrałem wariant (b)
  z recenzji PR #138 (N1), a nie złagodzenie tekstu, bo jest prawdziwy i tani. To rozszerzenie zgodne wstecz
  (`apiVersion` zostaje 1), więc bez nowego ADR; opis w historii kontraktu. `true` = próba nie zużyła limitu (slotu nie
  zarezerwowano albo zwrot się udał), `false` = próba wliczona. Brak pola = „mogła zostać wliczona”. Koszt: zero.
- Do zrobienia przez odbiorcę: ux akceptuje lub poprawia teksty niżej, potem mobile-dev wdraża (zadanie niżej).
- Pytania/blokady: brak.

## Proponowane teksty komunikatów (do akceptacji ux)

Dziś `errorAiUnavailableBody` i `errorAiInvalidBody` (`lib/l10n/app_pl.arb:65-66`, `app_en.arb:85-86`) zawsze mówią
„Ta próba nie wlicza się do limitu”. Propozycja: 3 warianty dla każdego kodu, wybierane po `details.slotReleased`.
Wariant „wliczona” nie podaje liczby wykorzystanych prób, bo odpowiedź błędu jej nie niesie.

| Klucz (propozycja) | Kiedy | PL | EN |
|---|---|---|---|
| `errorAiUnavailableBody` (zmiana) | `ai_unavailable`, `slotReleased = true` | Usługa AI jest chwilowo niedostępna. Ta próba nie wlicza się do dzisiejszego limitu. Spróbuj ponownie za chwilę. | The AI service is temporarily unavailable. This attempt doesn't count towards today's limit. Please try again shortly. |
| `errorAiUnavailableCountedBody` (nowy) | `ai_unavailable`, `slotReleased = false` | Usługa AI jest chwilowo niedostępna. Ta próba została wliczona do dzisiejszego limitu, bo nieudane próby zwracamy najwyżej 2 razy dziennie. Spróbuj ponownie później. | The AI service is temporarily unavailable. This attempt counted towards today's limit, because we give back failed attempts at most twice a day. Please try again later. |
| `errorAiUnavailableMaybeBody` (nowy) | `ai_unavailable`, brak pola | Usługa AI jest chwilowo niedostępna. Ta próba mogła zostać wliczona do dzisiejszego limitu. Spróbuj ponownie za chwilę. | The AI service is temporarily unavailable. This attempt may have counted towards today's limit. Please try again shortly. |
| `errorAiInvalidBody` (zmiana) | `ai_invalid_response`, `slotReleased = true` | AI zwróciło niepełny plan, więc go nie zapisaliśmy. Ta próba nie wlicza się do dzisiejszego limitu. Spróbuj ponownie. | The AI returned an incomplete plan, so we didn't save it. This attempt doesn't count towards today's limit. Please try again. |
| `errorAiInvalidCountedBody` (nowy) | `ai_invalid_response`, `slotReleased = false` | AI zwróciło niepełny plan, więc go nie zapisaliśmy. Ta próba została wliczona do dzisiejszego limitu, bo nieudane próby zwracamy najwyżej 2 razy dziennie. | The AI returned an incomplete plan, so we didn't save it. This attempt counted towards today's limit, because we give back failed attempts at most twice a day. |
| `errorAiInvalidMaybeBody` (nowy) | `ai_invalid_response`, brak pola | AI zwróciło niepełny plan, więc go nie zapisaliśmy. Ta próba mogła zostać wliczona do dzisiejszego limitu. Spróbuj ponownie. | The AI returned an incomplete plan, so we didn't save it. This attempt may have counted towards today's limit. Please try again. |

`errorTimeoutBody` („mogła zostać wliczona”) i teksty `internal` bez zmian: nie obiecują zwrotu.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-93: review (kontrakt i teksty gotowe; zostaje implementacja, niżej). TAM-91: review
  (wszystkie punkty zrobione w tym PR-ze, także `docs/data/`, bo jest w uprawnieniach architekta). Oba można zamknąć
  po merge'u tego PR-a, a TAM-93 przenieść do done dopiero po zadaniu mobile-dev, jeśli tak wolisz.
- Zadania – nowe:
  - **P3-05-SLOTMSG-UX** (ux): przegląd i akceptacja 6 tekstów z tabeli wyżej (PL/EN, ton i długość). Zależy od: merge
    tego PR-a. Zasada „ux przed mobile-dev”; jeśli ux nie ma uwag, wystarczy krótka notka.
  - **P3-05-SLOTMSG-DEV** (mobile-dev): (1) backend `endpoints.ts`: w błędach `ai_unavailable` i `ai_invalid_response`
    dodać `details.slotReleased` (`true`, gdy błąd przed rezerwacją albo `releaseQuota` faktycznie zmniejszył `count`;
    `false`, gdy `planRelease` zwrócił `undefined` lub zapis zwrotu się nie udał). `releaseQuota` musi więc zwracać
    wynik (np. `"released" | "capped" | "stale_day"`). (2) Log `quotaRelease`: `released` / `release_capped` /
    `release_failed` (uwaga N2 z `docs/reviews/PR-138.md`). (3) Aplikacja: odczyt `details.slotReleased` i wybór
    tekstu wg tabeli; nowe klucze w `app_pl.arb` i `app_en.arb` z opisami `@…`. (4) Testy: jednostkowe backendu
    (3. błąd w dobie → `slotReleased=false`, błąd przed rezerwacją → `true`) i widgetowe dla 3 wariantów tekstu.
    Zależy od: P3-05-SLOTMSG-UX. Blokuje: P3-05-CFG (TAM-90).
  - Zależności TAM-90 (P3-05-CFG): O4-2, B-1, W-1 i P3-05-SLOTMSG-DEV (`deploy-dev-functions.md` sekcja 2).
- Pytania otwarte – nowe: brak.
- Pytania otwarte – zamknięte: O-TAM18-3 (limit 2 zwrotów na dobę – zostaje, decyzja właściciela 2026-11-21);
  O-TAM18-1 (zwrot nie zmniejsza `usage_global` – potwierdzone, kontrakt pkt 2 reguła 4); O-TAM4-1 (reguła ostatniego
  dnia – zatwierdzona 2026-11-21, w kontrakcie bez dopisku „propozycja”).
