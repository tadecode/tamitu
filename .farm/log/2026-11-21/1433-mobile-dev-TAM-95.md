# 14:33  mobile-dev → orchestrator (dalej reviewer, architect)  |  TAM-95 (P3-05-DEDUP)
- Zrobione: nowy prompt `plan-v2` (kopia `plan-v1` z jawną regułą „No repeats”: to samo miejsce najwyżej raz
  w całym planie, także pod inną, dłuższą lub potoczną nazwą; nocleg nigdy nie jest punktem). `promptVersion` =
  `plan-v2`; `plan-v1.ts` usunięty (żaden test go nie potrzebuje, zostaje w historii git). Walidator wykrywa proste
  powtórzenia po normalizacji nazw i zwraca kody `dup_place@dayN` jako **ostrzeżenie w logu** (nowe pole
  `qualityWarnings`, bez treści), bez ponowienia. Eval używa `plan-v2` przez wspólną ścieżkę `generate.ts`
  i pokazuje liczbę planów z powtórzeniem. 0 płatnych wywołań, bez wdrożeń, `.github/` i CI nietknięte,
  aplikacja i `.arb` bez zmian.
- Artefakty:
  - `backend/functions/src/prompt/plan-v2.ts` (dawny `plan-v1.ts`), `src/plan-validator.ts` (`placeNameTokens`,
    `isSamePlace`, `findRepeatedPlaces`, `warnings` w wyniku), `src/generate.ts` (pole `qualityWarnings` w
    `AttemptLog`, logika ponowień bez zmian), `src/logger.ts` (pole na liście dozwolonych, limit 200 znaków),
    `src/endpoints.ts` (tylko import);
  - testy: `test/plan-validator.test.ts` (przypadki z QA TAM-88 K4 c na danych syntetycznych), `test/generate.test.ts`,
    `test/prompt.test.ts`, `test/endpoints.test.ts`, `test/generate-plan-flow.test.ts`, `test/no-direct-logging.test.ts`;
  - `backend/eval/run-eval.mjs` (kolumna `qualityWarnings`, podsumowanie, unikalne nazwy w `--dry-run`),
    `backend/eval/README.md` (sekcja „Powtórzone miejsca”).
- Decyzje:
  - **Wariant: ostrzeżenie, nie błąd.** Każde ponowienie to drugie płatne wywołanie (ok. +100% kosztu generowania)
    i dłuższe czekanie użytkownika. Błąd walidacji liczyłby się też przeciw progowi 95%, a TAM-88 przeszedł z zerowym
    zapasem (38/40). QA ocenił, że plan z powtórzeniem da się używać i nie wprowadza w błąd. Prosta reguła może się
    pomylić przy dwóch różnych miejscach o podobnych nazwach. Główną poprawką jest prompt, a log daje dane z dev do
    ewentualnej zmiany na błąd (decyzja kosztowa właściciela).
  - Reguła: małe litery, bez znaków diakrytycznych (także ł, ı, ß), bez interpunkcji, bez dopisków („the”, „market”,
    „morning”, „evening”, „night”, „restaurant”, „ristorante”, „restaurante”, „restauracja”, „cafe”, „caffe”,
    „kawiarnia”, „visit”, „wizyta”). Powtórzenie = równe listy słów albo krótsza (co najmniej 2 słowa) jest ciągłym
    fragmentem dłuższej. Jednowyrazowe nazwy tylko przy równości („Vatican” i „Vatican Museums” to nie powtórzenie).
    Porównanie tylko między różnymi dniami; kod wskazuje późniejszy dzień.
  - Z przypadków QA reguła łapie E03-en („Campo de' Fiori” / „… Morning Market”) i E17-pl („Restauracja
    Sultanahmet Koftecisi” / „Tarihi Sultanahmet Koftecisi Selim Usta”). Nie łapie E13-en (nazwa potoczna
    „Piazza della Vergogna”): to wymaga wiedzy o miejscach, tu działa tylko prompt. Przypadek graniczny (Panteon
    i „Piazza della Rotonda”) celowo nie jest liczony, jak w raporcie QA.
  - Prompt nie pozwala na świadome „powrót do …”, więc reguła nie ma takiego wyjątku. Nocleg nie jest punktem planu.
  - Punkty ogólne (K4 e, „Zakupy pamiątek”) poza zakresem, żeby nie mieszać dwóch zmian w jednym porównaniu promptów.
  - Koszt (zasada 10): reguła to ok. 70 tokenów wejścia więcej na wywołanie (ułamek grosza na 40 generowań);
    ostrzeżenie nie dodaje wywołań.
- Testy (bez urządzenia i sieci): `backend/functions` – `vitest` 328 testów zielone, `typecheck`, `lint`, `build` bez
  błędów. `node backend/eval/run-eval.mjs --dry-run`: 40/40, 0 planów z powtórzeniem; tryb szacunku bez zmian.
  Trybu `--paid` nie uruchamiałem.
- Do zrobienia przez odbiorcę: reviewer – przegląd PR-a; architect – w `docs/api/posrednik-api.md` przykład
  `promptVersion` na `plan-v2` i opis pola logu `qualityWarnings` (pkt 2 „Logi”), w
  `docs/architecture/p3-05-wymagania-generowania.md` sekcja 6 dopisać to pole. Uwaga: TAM-96 (architekt) dotyczy
  ponowień po 429; ten PR nie zmienia logiki ponowień w `generate.ts`.
- Pytania/blokady: brak.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-95: review (PR otwarty, czeka na przegląd i merge właściciela).
- Zadania – nowe:
  - **P3-05-DEDUP-DOC** (architect): `posrednik-api.md` – przykład `promptVersion: "plan-v2"` i pole logu
    `qualityWarnings` (`dup_place@dayN`); `p3-05-wymagania-generowania.md` sekcja 6 – to samo pole. Zależy od: merge
    tego PR-a.
  - **P3-05-EVAL-V2** (qa, po zgodzie właściciela): płatny przebieg eval z `plan-v2` (ok. 0,70–1,40 PLN, sufit 2,5 PLN)
    i ocena ręczna K4 c, żeby sprawdzić, czy powtórzeń jest mniej, a wynik nadal ≥ 95%. Bez zgody nie uruchamiać.
- Pytania otwarte – nowe: **O-TAM95-1** (właściciel): czy i kiedy zlecić płatny przebieg porównawczy `plan-v2`
  (P3-05-EVAL-V2)?
- Pytania otwarte – zamknięte: brak.
