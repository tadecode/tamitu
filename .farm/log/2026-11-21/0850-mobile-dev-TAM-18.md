# 08:50  mobile-dev → orchestrator  |  TAM-18 (P3-05)
- Zrobione: funkcja `generatePlan` w backendzie działa od początku do końca na atrapie modelu. Kod liczy zakres punktów
  dla każdego dnia (`dayTargets`: dzień 1 od 0 z progiem przylotu, dni środkowe pełne tempo, ostatni dzień od 1).
  Wysyła je modelowi razem z promptem `plan-v1` i uproszczonym `responseSchema` (bez zagnieżdżonych limitów).
  Pełny walidator sprawdza odpowiedź; przy błędzie jest jedna ponowna próba z listą błędów, a przy 400 ponowienia
  nie ma. Doszła rezerwacja i zwrot limitu dziennego (`usage`, `usage_global`, `expireAt` wg O4-b). Logi zawierają
  tylko metadane. Zestaw ewaluacyjny PL/EN (20 × 2) jest gotowy, ale **nie był uruchamiany na prawdziwym modelu**.
  W tej pracy było 0 płatnych wywołań: bez Vertex, bez wdrożenia, bez emulatorów.
- Artefakty: `backend/functions/src/{plan-targets,plan-validator,generate,ai,limits,endpoints,index,logger,handler}.ts`,
  `backend/functions/src/prompt/plan-v1.ts`, testy w `backend/functions/test/` (`plan-targets`, `plan-validator`, `prompt`,
  `ai`, `generate`, `quota`, `generate-plan-flow`, `helpers/fakes.ts`), `backend/eval/{cases.json,run-eval.mjs,README.md}`.
  Wynik: 283 testy zielone (vitest), `tsc`, `eslint` i `build` bez błędów.
- Decyzje (techniczne, w granicach ADR, bez nowego ADR):
  1. Vertex AI wywołujemy przez REST (`fetch` z Node 22). Token pochodzi z konta usługi funkcji (ADC z `firebase-admin`).
     Nie dochodzi żadna nowa zależność npm ani klucz.
  2. Konfiguracja modelu jest w zmiennych `AI_MODEL_ID` i `AI_LOCATION`, z zasadą fail-closed. Przyjmujemy tylko
     `eu` i `europe-west4` oraz identyfikatory `gemini-*`. Gdy brak konfiguracji, funkcja zwraca `ai_unavailable`
     (w logu `configError=ai_config_invalid`) jeszcze przed rezerwacją limitu. Nie ma domyślnego modelu w kodzie.
  3. Zwrot slotu dotyczy tylko `usage/{uid}`, a `usage_global` nie maleje. Licznik globalny jest bezpiecznikiem
     kosztów, a wywołania modelu i tak zostały opłacone (`firestore-ttl-indexes.md` pkt 3.2 mówi tylko o `usage`).
     Slot wraca przy `ai_unavailable`, `ai_invalid_response` i `internal`.
  4. Do ponowienia kwalifikują się 408, 429, 5xx, przekroczenie czasu (45 s na próbę) i błąd sieci. Wszystkie
     pozostałe kody (400, 403, 404, 417) traktujemy jako błąd konfiguracji, bez ponowienia. Treści błędu z Vertex
     nie czytamy ani nie logujemy.
  5. Heurystyki języka ze słów funkcyjnych (ADR-0002 krok 8) **nie** ma. Walidator sprawdza pole `language`,
     tak jak wymaga `p3-05-wymagania-generowania.md` sekcja 5. Heurystyka bez danych z ewaluacji groziłaby
     fałszywymi odrzuceniami (nazwy własne). Pytanie O-TAM18-2 poniżej.
- Do zrobienia przez odbiorcę: patrz „Dla orkiestratora". Zakres był za duży na jeden PR, dlatego testy na
  emulatorze i ewaluacja na modelu idą osobno (poniżej).
- Pytania/blokady: płatna ewaluacja czeka na zgodę właściciela (koszt poniżej). Konfiguracja `.env` czeka na
  właściciela lub Stewarda. Hook farmy blokuje odczyt plików `.env`, więc ich nie zmieniałem.

## Szacunek kosztu ewaluacji (do zgody właściciela)
- 20 przypadków × PL/EN = **40 generowań, od 40 do 80 wywołań** `gemini-3.1-flash-lite` (punkt `eu`, projekt dev).
- Koszt wg `costs.md` sekcja 0: ok. **0,70 PLN** przy 1 próbie na generowanie, ok. **1,00 PLN** przy 40% ponowień
  (tyle było w ARCH-01), najwyżej **1,40 PLN**. Uruchamiacz sam przerywa po przekroczeniu 2,5 PLN (`--stop-pln`).
- Gdyby trzeba było użyć zapasowego `gemini-3.5-flash-lite`: ok. 1,15 / 1,60 / 2,30 PLN.
- Kwoty mieszczą się w spend cap dev (15 PLN). Limitu 25/dobę ewaluacja nie zużywa, bo wywołuje Vertex z konta
  właściciela, z pominięciem funkcji. Kroki opisuje `backend/eval/README.md`. Uruchamia właściciel, z tokenem
  z `gcloud auth print-access-token`, którego nie zapisujemy w żadnym pliku.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-18: review (PR z kodem i testami jednostkowymi). Ewaluacja na prawdziwym modelu i testy
  na emulatorze to osobne zadania (niżej). TAM-18 można zamknąć po ich zakończeniu albo zostawić otwarte do tego czasu.
- Zadania – nowe:
  - **P3-05-EVAL**: „Pełna ewaluacja P3 na `gemini-3.1-flash-lite` (40 generowań, ok. 1 PLN)", rola: owner
    (uruchomienie) + qa (ocena K1–K4 i raport). Zależy od: merge tego PR-a i zgody właściciela na koszt.
  - **P3-05-EMU**: „Testy `generatePlan` na emulatorach Firebase: rezerwacja `usage/{uid}` z `expireAt` typu Timestamp,
    zwrot slotu, dokument z wczoraj = 0, limit 5/25, kolejność zgody → limit", rola: qa (katalog `tests/` jest poza
    uprawnieniami mobile-dev). Uruchamiane przez `.farm/test-lock.ps1`. Do testu potrzebna jest atrapa Vertex
    w emulatorze, a bez niej funkcja kończy na `ai_unavailable` przed rezerwacją. Propozycja: mobile-dev doda
    zmienną `AI_ENDPOINT_OVERRIDE`, przyjmowaną **tylko** przy `FUNCTIONS_EMULATOR=true` i hoście `127.0.0.1`.
    Zależy od: merge tego PR-a.
  - **P3-05-CFG**: „Dodać `AI_MODEL_ID=gemini-3.1-flash-lite` i `AI_LOCATION=eu` do `backend/functions/.env.tamitu-dev-tadecode`
    (później prod)", rola: owner/GitHub Steward. Bez tego wdrożona funkcja odpowiada `ai_unavailable`
    (fail-closed). Wdrożenie do dev to krok płatny tylko przy wywołaniach, a koszt wyliczono wyżej.
  - **P3-05-DOC** (architect): w `posrednik-api.md` reguła ostatniego dnia przestała być propozycją, bo właściciel
    zatwierdził ją 2026-11-21. Do dopisania: kody walidacji w logach (sekcja 6 wymagań) i to, że zwrot slotu nie
    zmniejsza `usage_global`. Stary szkic `generate-plan.response.schema.json` zostaje jako schemat serwerowy,
    bez zmian.
- Pytania otwarte – nowe:
  - O-TAM18-1 (architect/owner): czy zwrot slotu ma też zmniejszać `usage_global`? Obecnie nie zmniejsza, bo to
    bezpiecznik kosztu (decyzja 3).
  - O-TAM18-2 (architect): heurystyka języka PL/EN (ADR-0002 krok 8). Czy jest potrzebna w MVP, skoro jest
    `language` + `responseSchema`? Propozycja: decydować po ewaluacji. Jeśli pomyłki języka się pojawią, dodać
    prostą heurystykę w `plan-v2`.
- Pytania otwarte – zamknięte: brak (O-TAM4-1, czyli reguła ostatniego dnia, jest już zaimplementowana zgodnie
  z decyzją właściciela z 2026-11-21).
