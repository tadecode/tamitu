# Weryfikacja PR #159 – stan EK-07 „Asystent AI chwilowo przeciążony” (TAM-99)

- Autor (rola): qa · Data: 2026-11-24 · Gałąź raportu: `docs/qa-PR-159`
- Weryfikowany kod: PR #159 `feat/TAM-99-ai-busy`, head `b26d8aa3b53f335dd8c207b8d9d79a377a53323d`
  (zawiera poprawkę z recenzji: `ai_busy` odebrane w tle nie uruchamia automatu)
- Norma: `docs/ux/screens/ek-07-ai-busy.md` v0.2 (teksty PL/EN zaakceptowane przez właściciela bez zmian,
  UX-TAM98-1 „TAK, bez automatu”), makieta `docs/ux/mockups/ek-07-ai-busy.html`
- Koszty: 0 płatnych wywołań, bez wdrożeń, bez Vertex, bez emulatora i urządzenia. Dane osobowe: brak.

## Werdykt

**Przyjęte** (`qa:ok`). Wszystkie stany ekranu (A, B, C, D, E) działają zgodnie ze specyfikacją, 13 tekstów
w PL i EN zgadza się znak po znaku ze specyfikacją (26/26), odmiana liczebników (ICU plural) jest poprawna,
odliczanie jest ogłaszane co 15 s, a nie co sekundę. Testy bez urządzenia są zielone: aplikacja 215/215,
backend 376/376, plus 19/19 dodatkowych testów QA. Błędów blokujących nie znaleziono. Jest jedna drobna uwaga
(Q-159-1) do załatwienia przy podłączaniu ekranu w TAM-101.

## Co i po co

Gdy asystent AI Google jest przeciążony, serwer zwraca kod `ai_busy`. Aplikacja zostaje wtedy na ekranie
generowania, odlicza minutę i raz sama ponawia próbę. Użytkownik może spróbować od razu albo wrócić do
formularza. QA sprawdza, czy użytkownik zawsze widzi właściwy stan i dokładnie zaakceptowany tekst oraz czy
aplikacja nie ponawia prób sama więcej niż raz (ani w tle, ani gdy limit nie został zwrócony).

**Ograniczenie:** `AiBusyView` nie jest jeszcze podłączony do ekranu EK-07, bo tego ekranu nie ma w aplikacji
(TAM-101). Weryfikacja odbyła się na testach widgetowych widoku osadzonego w atrapie ekranu z paskiem
„Nowa podróż”. Na urządzeniu z TalkBack trzeba to sprawdzić po TAM-101 (niżej, „Do sprawdzenia później”).

## 1. Środowisko

| Element | Stan |
|---|---|
| Kod PR | osobny worktree tylko do odczytu, detached `b26d8aa` (`git fetch origin pull/159/head`); po testach usunięty |
| Flutter | `flutter analyze` (bez uwag), `flutter test` (Windows, bez urządzenia) |
| Backend | `npm test` (vitest) i `tsc --noEmit` w `backend/functions` |
| Teksty | skrypt [`scripts/pr-159-compare-texts.js`](scripts/pr-159-compare-texts.js): czyta tabelę „Teksty” ze specyfikacji i porównuje znak po znaku z `lib/l10n/app_{pl,en}.arb` z PR-a |
| Testy QA | [`scripts/pr-159-qa_test.dart.txt`](scripts/pr-159-qa_test.dart.txt): 19 niezależnych testów (oczekiwane teksty przepisane ze specyfikacji, nie z kodu), uruchomione w kopii PR-a i nie dodane do zestawu |

## 2. Testy bez urządzenia

| Zestaw | Wynik |
|---|---|
| `flutter analyze` | bez uwag |
| `flutter test` (cały zestaw PR-a) | **215/215** zielone |
| testy QA (`pr-159-qa_test`) | **19/19** zielone |
| `npm test` (`backend/functions`) | **376/376** zielone (17 plików) |
| `tsc --noEmit` | bez błędów |

## 3. Stany ekranu

„PR” = test z zestawu PR-a (`test/features/generation/ai_busy_view_test.dart`), „QA” = test QA.

| # | Przypadek | Oczekiwane (spec) | Wynik | Dowód |
|---|---|---|---|---|
| S1 | A: odliczanie 60 s | tytuł, opis „…za minutę…” + zdanie o limicie, „Ponowna próba za 1:00”, pasek 1→0, „Spróbuj teraz”, „Wróć do formularza” | OK | PR (PL/EN × jasny/ciemny), PR tyknięcia co 1 s (0:42, pasek 42/60) |
| S2 | A: `retryAfterSec` 30 / 61 / 120 | „minutę” 0:30 / „2 minuty” 1:01 / „2 minuty” 2:00 | OK | QA, PR |
| S3 | `retryAfterSec` poza 30–120, ułamek, tekst, brak | 60 s | OK | QA (29, 121, „60”, 60.5, brak), PR |
| S4 | koniec odliczania na pierwszym planie | **jedno** automatyczne ponowienie (stan C, „Próbujemy ponownie…”) | OK | PR, QA |
| S5 | automat → znów `ai_busy` | stan B: „nadal jest przeciążony”, opis ręczny, bez odliczania i paska, brak drugiego automatu (180 s) | OK | PR, QA |
| S6 | B: kolejne „Spróbuj teraz” → `ai_busy` (×3) | za każdym razem B, nigdy odliczanie | OK | QA |
| S7 | „Spróbuj teraz” w A | zastępuje automat (1 wywołanie), potem brak automatu | OK | PR |
| S8 | podwójne dotknięcie „Spróbuj teraz” | 1 wywołanie; w C przycisku nie ma | OK | PR, QA |
| S9 | D: termin minął w tle, powrót | tytuł z A, „Gdy aplikacja była w tle…” + limit, bez odliczania, bez automatu | OK | PR, QA |
| S10 | D → „Spróbuj teraz” → `ai_busy` (`false`) | C, potem B z „została wliczona…” | OK | QA |
| S11 | powrót z tła przed terminem | odliczanie trwa od pozostałego czasu, automat raz | OK | PR (0:40) |
| S12 | zamrożone timery w tle, powrót po terminie | D, nigdy spóźniony automat | OK | PR |
| S13 | **`ai_busy` odebrane, gdy aplikacja już była w tle** (poprawka z recenzji) | brak automatu; termin w tle → D | OK | PR (`paused`), QA (tylko `inactive`, np. rozwinięty panel powiadomień) |
| S14 | jw., powrót w 59. s | odliczanie 0:01, automat raz w 60. s, potem brak drugiego | OK | PR (powrót w 20. s), QA (59. s) |
| S15 | odliczanie liczone od zegara monotonicznego | po 30 s bez tyknięć pokazuje 0:30 | OK | QA |
| S16 | E: `slotReleased = false` | tytuł z A, opis ręczny + „została wliczona…”, **bez odliczania i automatu** (UX-TAM98-1) | OK | PR (PL/EN), QA |
| S17 | E: brak `slotReleased` (także `"true"`, `1`) | jw. + „mogła zostać wliczona…” | OK | PR, `test/core/ai_busy_failure_test.dart` |
| S18 | E + tło + powrót | nadal E (nie D), bez automatu | OK | QA |
| S19 | zdanie o limicie w B/D dotyczy ostatniej odpowiedzi | E(`null`) → B(`true`) = „nie wlicza się” | OK | PR, QA (D→B `false`) |
| S20 | „Wróć do formularza” w A, B, D, E | powrót bez dialogu, zaplanowane ponowienie anulowane | OK | PR (A), QA (B, D, E) |
| S21 | wstecz systemowe w A, B, D, E | jak „Wróć do formularza” | OK | PR (A), QA (B, D, E) |
| S22 | wstecz w C | widok nie wraca (dialog CMP-15 należy do ekranu EK-07, TAM-101) | OK | QA |
| S23 | ponowienie: sukces / inny błąd / wyjątek | EK-08 / mapowanie EK-16 / błąd ogólny bez awarii | OK | PR |
| S24 | 200% tekstu, 360 dp (A i B) | bez przepełnienia, treść się przewija, „Wróć do formularza” przyklejony | OK | PR |

**24/24 zaliczone.**

## 4. Teksty

Skrypt porównania: **13 kluczy × 2 języki = 26/26 zgodnych znak po znaku** z tabelą „Teksty” specyfikacji.
Spośród istniejących tekstów zmienił się tylko ostatni wiersz `.arb` (dopisany przecinek); żadna treść nie
zmieniła się. Test `l10n_keys_test.dart` (te same klucze PL/EN, brak pustych) zielony.

Wyświetlane zdania złożone (opis + zdanie o limicie, sklejone spacją w kodzie, nie w tłumaczeniu) sprawdzone
na ekranie w PL i EN dla wszystkich trzech wariantów limitu (`true`, `false`, brak).

### ICU plural (QA, wygenerowane `AppLocalizations`)

| Liczba | PL `generationBusyCountdownA11y` | EN |
|---|---|---|
| 1 | Ponowna próba za 1 sekundę | Retrying in 1 second |
| 2, 3, 4 | … 2/3/4 sekundy | … 2/4 seconds |
| 5, 11, 12, 14, 15, 21 | … sekund | … 5 seconds |
| 22, 24, 42, 102 | … sekundy | – |
| 25, 30, 45, 59, 60, 112, 120 | … sekund | … 45 seconds |

| `{minutes}` | PL `generationBusyBodyAuto` | EN |
|---|---|---|
| 1 | Spróbujemy ponownie za minutę. | We'll try again in a minute. |
| 2 | … za 2 minuty. | … in 2 minutes. |
| 5 | … za 5 minut. | … in 5 minutes. |

Wszystkie zgodne. (W praktyce `{minutes}` to 1 lub 2, bo `retryAfterSec` jest w zakresie 30–120.)

## 5. Dostępność

| # | Wymaganie | Wynik | Dowód |
|---|---|---|---|
| D1 | odliczanie ogłaszane **co 15 s**, nie co sekundę; bez pierwszego i bez 0 (60 s: 45, 30, 15) | OK | PR (PL), QA (EN) |
| D2 | jw. dla 90 s: 75, 60, 45, 30, 15 | OK | QA |
| D3 | w chwili ponowienia ogłoszenie „Próbujemy ponownie…” / „Trying again…” | OK | PR, QA |
| D4 | ogłoszenia są uprzejme (polite) | OK | `SemanticsService.sendAnnouncement` z domyślnym `Assertiveness.polite` (przegląd kodu) |
| D5 | odliczanie nie jest regionem na żywo; etykieta słowami („Ponowna próba za 60 sekund”), nie „1:00” | OK | QA (`isLiveRegion = false`, brak etykiety „1:00”) |
| D6 | pasek ukryty przed TalkBack | OK | `ExcludeSemantics` (QA: brak węzła z czasem) |
| D7 | tytuł jest nagłówkiem | OK | QA (`isHeader`) |
| D8 | brak ogłoszeń odliczania w B, D, E | OK | QA |
| D9 | cyfry o stałej szerokości | OK | `FontFeature.tabularFigures()` (przegląd kodu) |
| D10 | cele dotyku min. 48 dp | OK | „Spróbuj teraz”: przycisk 40 dp, obszar dotyku 48 dp (domyślne `MaterialTapTargetSize.padded`); „Wróć do formularza”: `height: 48` (przegląd kodu) |

## 6. Uwagi

### Q-159-1 (drobna, nieblokująca): ogłoszenia odliczania także w tle

Kroki: stan A (`slotReleased = true`) → aplikacja w tle (`paused`) → czekać 60 s.
Wynik: aplikacja wysyła ogłoszenia „Ponowna próba za 45 / 30 / 15 sekund” (test QA „observation:
announcements while the app is in the background” je rejestruje). Oczekiwane: specyfikacja mówi „bez pracy
w tle”, a ogłoszenie aplikacji z tła mogłoby zostać przeczytane przez TalkBack w innej aplikacji. Czy Android
faktycznie je przeczyta, trzeba sprawdzić na urządzeniu. Propozycja: w kontrolerze nie zwiększać licznika
ogłoszeń, gdy aplikacja nie jest na pierwszym planie. Do zrobienia przy TAM-101 (podłączenie ekranu); nie
blokuje tego PR-a, bo widok nie jest jeszcze nigdzie użyty.

### Do sprawdzenia później (po TAM-101, na urządzeniu z TalkBack)

Tych punktów nie da się sprawdzić bez ekranu EK-07 w aplikacji:
1. Fokus TalkBack przechodzi na tytuł po wejściu w stan A/B/D/E (widok oznacza tytuł jako nagłówek, ale sam
   fokusu nie przenosi).
2. Stan C to pełny stan ładowania EK-07 (tytuł, rotacja tekstów, „Anuluj” z dialogiem CMP-15). Dziś widok
   pokazuje tylko wskaźnik i „Próbujemy ponownie…”, a resztę ma dać ekran EK-07 (decyzja 5 w dzienniku mobile-dev).
3. Nowe wysłanie formularza = nowy licznik automatu i nowy `requestId` przy ponowieniu (zadanie hosta).
4. Wygląd zgodny z makietą (odstępy, motyw ciemny, 200%) na prawdziwym urządzeniu oraz Q-159-1.

## 7. Backend (w zakresie QA)

`npm test` 376/376 i `tsc` czyste. Serwer wysyła `ai_busy` z `retryAfterSec` i `slotReleased` pod nazwami,
których szuka aplikacja (`endpoints.ts`: `AppError("ai_busy", { ...e.details, slotReleased })`); przy nieudanym
zwrocie lub po północy `slotReleased = false`, co w aplikacji daje stan E (bez automatu). Szczegóły logiki
backendu ocenia recenzja kodu (`docs/reviews/`).
