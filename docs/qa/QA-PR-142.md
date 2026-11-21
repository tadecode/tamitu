# Weryfikacja PR #142 – komunikaty po `slotReleased` (TAM-94)

- Autor (rola): qa · Data: 2026-11-21 · Gałąź raportu: `docs/qa-PR-142`
- Weryfikowany kod: PR #142 `feat/TAM-94-slot-released`, head `774c5aa812d71fc1ad7118278883c43e67934381`
- Norma: tabela tekstów zaakceptowana przez właściciela bez zmian (`.farm/log/2026-11-21/0948-architect-TAM-93.md`, „Proponowane teksty komunikatów”); kontrakt `docs/api/posrednik-api.md` v0.5 („Slot limitu i zwrot próby”, pkt 6)
- Przegląd kodu: `docs/reviews/PR-142.md` (PR #143, `review:ok`)
- Koszty: 0 płatnych wywołań, bez wdrożeń, bez Vertex, bez emulatora i urządzenia. Dane osobowe: brak.

## Werdykt

**Przyjęte** (`qa:ok`). Wszystkie 12 przypadków (2 kody × 3 warianty × PL/EN) pokazuje dokładnie zaakceptowany tekst.
`errorTimeoutBody` i teksty dla `internal` się nie zmieniły. Długie teksty PL i EN nie są ucinane na małym ekranie,
także przy powiększonej czcionce. Testy bez urządzenia są zielone. Nie znaleziono błędów.

## Co i po co

Gdy generowanie planu się nie uda, serwer zwraca próbę najwyżej 2 razy na dobę. Pole `details.slotReleased` mówi
aplikacji, czy ta próba wróciła. Aplikacja ma na tej podstawie pokazać jeden z 3 tekstów: „nie wlicza się”
(`true`), „została wliczona” (`false`) albo „mogła zostać wliczona” (brak pola, np. starszy serwer). QA sprawdza,
czy użytkownik zobaczy dokładnie tekst zaakceptowany przez właściciela i czy ten tekst mieści się na ekranie.

## 1. Środowisko

| Element | Stan |
|---|---|
| Kod PR | osobny worktree tylko do odczytu, detached `774c5aa` (z `git fetch origin pull/142/head`); po testach usunięty |
| Flutter | `flutter test`, `flutter analyze`, `flutter gen-l10n` (Windows, bez urządzenia) |
| Backend | `npm test` (vitest) i `tsc --noEmit` w `backend/functions` |
| Porównanie tekstów | skrypt `docs/qa/scripts/pr-142-compare-texts.js`: czyta tabelę z wpisu architekta i porównuje łańcuchy znak po znaku z `lib/l10n/app_*.arb` z PR-a |
| Mieszczenie się tekstów | tymczasowy test widgetowy `docs/qa/scripts/pr-142-fit_test.dart.txt` (uruchomiony w kopii PR-a, nie dodany do zestawu, bo nowe klucze istnieją dopiero po merge'u) |

## 2. Wynik 12 przypadków

Kolumna „Tekst” = porównanie łańcucha z tabeli architekta z `.arb` z PR-a (znak po znaku). Kolumna „Wybór” = czy
dla danej wartości `details.slotReleased` aplikacja pokazuje ten klucz (`failure_messages.dart` + testy widgetowe
`test/core/slot_released_message_test.dart`, które wyszukują dokładny tekst na ekranie).

| # | Kod błędu | `slotReleased` | Klucz | Język | Tekst | Wybór |
|---|---|---|---|---|---|---|
| 1 | `ai_unavailable` | `true` | `errorAiUnavailableBody` | PL | zgodny | OK |
| 2 | `ai_unavailable` | `true` | `errorAiUnavailableBody` | EN | zgodny | OK |
| 3 | `ai_unavailable` | `false` | `errorAiUnavailableCountedBody` | PL | zgodny | OK |
| 4 | `ai_unavailable` | `false` | `errorAiUnavailableCountedBody` | EN | zgodny | OK |
| 5 | `ai_unavailable` | brak | `errorAiUnavailableMaybeBody` | PL | zgodny | OK |
| 6 | `ai_unavailable` | brak | `errorAiUnavailableMaybeBody` | EN | zgodny | OK |
| 7 | `ai_invalid_response` | `true` | `errorAiInvalidBody` | PL | zgodny | OK |
| 8 | `ai_invalid_response` | `true` | `errorAiInvalidBody` | EN | zgodny | OK |
| 9 | `ai_invalid_response` | `false` | `errorAiInvalidCountedBody` | PL | zgodny | OK |
| 10 | `ai_invalid_response` | `false` | `errorAiInvalidCountedBody` | EN | zgodny | OK |
| 11 | `ai_invalid_response` | brak | `errorAiInvalidMaybeBody` | PL | zgodny | OK |
| 12 | `ai_invalid_response` | brak | `errorAiInvalidMaybeBody` | EN | zgodny | OK |

**12/12 zaliczone.** Dodatkowo:

- Wartość inna niż prawdziwy `bool` (`"true"`, `1`) daje wariant „mogła zostać wliczona”, czyli aplikacja nie obiecuje
  zwrotu bez pewności (`test/core/app_failure_test.dart`, test „promise of a give-back appears only with
  slotReleased = true”).
- Tytuł we wszystkich 12 przypadkach to bez zmian `errorGenerateTitle`.
- Wygenerowane `lib/l10n/app_localizations_*.dart` odpowiadają `.arb`: `flutter gen-l10n` + `dart format` nie
  zmienia żadnego pliku w PR-ze.
- Serwer wysyła pole pod tą samą nazwą, której szuka aplikacja (`details.slotReleased` obok `details.code`):
  `endpoints.ts` (`AppError(e.appCode, { ...e.details, slotReleased })`) i testy
  `backend/functions/test/generate-plan-flow.test.ts` (`true` przed rezerwacją i po zwrocie, `false` przy 3.
  błędzie w dobie, po północy i przy nieudanym zapisie).

## 3. Teksty, które nie miały się zmienić

Porównanie wszystkich kluczy `.arb` między `main` (`0663244`) a PR-em: zmieniły się **tylko** 6 kluczy z tabeli,
w obu językach (2 zmienione, 4 nowe, każdy z opisem `@…`).

| Tekst | Wynik |
|---|---|
| `errorTimeoutBody` PL/EN | bez zmian |
| `internal` → `errorGenericTitle` / `errorGenericBody` PL/EN | bez zmian; `internal` nie dostaje `slotReleased` (test aplikacji i backendu) |
| `errorGenerateTitle`, `errorLimit*`, pozostałe | bez zmian |

## 4. Czy długie teksty mieszczą się na ekranie

Komunikat pokazuje komponent CMP-18 `StateView` (`lib/core/ui/components.dart`): tekst bez `maxLines` i bez
`overflow`, w `SingleChildScrollView`, szerokość najwyżej 320 dp. Z budowy nie da się go więc uciąć, a przy braku
miejsca ekran się przewija.

Sprawdzone testem widgetowym (72 kombinacje): 12 przypadków × ekrany 320×568 dp i 360×640 dp × skala tekstu 1.0,
1.3 i 2.0, z paskiem aplikacji i dwoma przyciskami pod tekstem (jak na prawdziwym ekranie błędu). Dla każdej
kombinacji:

- brak wyjątku przepełnienia (`RenderFlex overflowed`),
- `didExceedMaxLines = false` i pełna wysokość akapitu (tekst nie jest ucięty),
- tekst mieści się w szerokości ekranu,
- po przewinięciu do końca dół tekstu i ostatni przycisk są na ekranie.

**72/72 zaliczone.** Przy skali 1.0 i 1.3 najdłuższy tekst (PL „wliczona”, 165 znaków) zajmuje 220 i 364 dp
wysokości na ekranie 320×568, więc mieści się bez przewijania. Przy skali 2.0 (16 kombinacji, głównie warianty
„wliczona”) tekst jest wyższy niż ekran i trzeba przewinąć; nic nie jest ucięte. To samo działo się już przed PR-em
z dotychczasowymi tekstami. Uwaga: czcionka testowa Fluttera ma szerokie, kwadratowe znaki, więc wynik jest
ostrożniejszy niż na telefonie.

Podglądu na emulatorze ani telefonie nie robiono. W aplikacji nie ma jeszcze ekranu generowania planu, który
pokazuje te błędy (`failureMessage` wywołują dziś tylko testy), a wywołanie tych błędów na żywo wymagałoby
serwera i Vertex. Test widgetowy na komponencie CMP-18 jest tu wystarczający.

## 5. Testy automatyczne (head `774c5aa`)

| Zestaw | Wynik |
|---|---|
| `flutter test` | 178/178 zielone |
| w tym `slot_released_message_test.dart`, `app_failure_test.dart`, `l10n_keys_test.dart` | 25/25 zielone |
| `flutter analyze` | bez uwag |
| `backend/functions`: `npm test` | 314/314 zielone |
| `backend/functions`: `tsc --noEmit` | bez błędów |
| CI w PR-ze | `flutter`, `backend`, `conventions`, `secrets`, `farm-guards` zielone; `review-gate` czeka na `qa:ok` |

## 6. Błędy i uwagi

Błędów nie znaleziono. Dwie drobne uwagi z przeglądu kodu (`docs/reviews/PR-142.md`) dotyczą dokumentacji
i jednego zdania w tekście, który właściciel już zaakceptował; QA ich nie powtarza i nie blokuje nimi PR-a.

## Czego nie sprawdzono

- Wyglądu na prawdziwym telefonie i czytnika ekranu (brak ekranu w aplikacji, który pokazuje te błędy). Warto
  to sprawdzić przy zadaniu, które doda ekran generowania planu.
- Działania z prawdziwym serwerem i Vertex (zakaz płatnych wywołań i wdrożeń; logika serwera pokryta testami
  jednostkowymi i przeglądem kodu).
