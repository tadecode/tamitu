# 09:31  mobile-dev → orchestrator  |  TAM-18 (P3-05), poprawki po przeglądzie PR #136
- Zrobione: poprawiłem 4 uwagi średnie i 5 drobnych z `docs/reviews/PR-136.md` (PR #137). Wszystko jest na tej samej
  gałęzi i w tym samym PR-ze (#136). Testy: 309 zielonych (vitest), `tsc`, `eslint` i `build` bez błędów.
  W tej pracy było 0 płatnych wywołań, a `.github/` i CI zostały nietknięte.
- Artefakty: `backend/functions/src/{prompt/plan-v1,limits,endpoints,index,generate,plan-validator,ai}.ts`,
  `backend/eval/{eval-guard.mjs,run-eval.mjs,README.md}`, testy `backend/functions/test/{prompt,quota,generate-plan-flow,
  eval-guard,generate,plan-validator,ai}.test.ts`, `test/helpers/fakes.ts`.

## Co poprawiono
| # | Uwaga | Poprawka |
|---|---|---|
| 1 (śr.) | `dayTargets[N]` w prompcie numerowane od 1, a tablica JSON od 0 | Prompt odwołuje się do wpisu po `dayNumber`, a nie po pozycji w tablicy. Test pilnuje, że w prompcie nie ma `dayTargets[`. Wersja zostaje `plan-v1`, bo ewaluacja jeszcze się nie odbyła |
| 2 (śr.) | Zwrot slotu pozwala jednemu kontu wyczerpać limit globalny | Wybrałem wariant bezpieczniejszy kosztowo, w granicach kontraktu: **najwyżej 2 zwroty na konto i dobę** (`MAX_RELEASES_PER_DAY`, pole `usage/{uid}.released`). Kolejne błędy zużywają już limit własny konta. `usage_global` nadal nie maleje. Jedno konto zużyje więc najwyżej `perUserDailyLimit + 2` = 7 slotów globalnych na dobę, a nie 25. Testy jednostkowe i test przepływu |
| 8 (dr.) | Zwrot po `internal` wykracza poza listę z kontraktu | Slot wraca tylko po `ai_unavailable` i `ai_invalid_response`, czyli dokładnie według `posrednik-api.md` |
| 10 (dr.) | `usageFromDoc` bez testu | Funkcja przeniesiona do `limits.ts` i przetestowana, także dla zniekształconego `released` |
| 3 (śr.) | Bezpiecznik 2,5 PLN dało się wyłączyć (NaN, przecinek, nieznany model) | `eval-guard.mjs`: przyjmuje `2.5` i `2,5`, wartość musi być w zakresie (0; 2,5], flaga bez wartości jest odrzucana, a model spoza cennika powoduje odmowę. Uruchamiacz przerywa (kod 2) w **każdym** trybie. Limit działa teraz jako **sufit**: generowanie startuje tylko wtedy, gdy jego najgorszy wariant się mieści. Próby bez danych o tokenach (przekroczenie czasu, 5xx) doliczamy według szacunku. 19 testów |
| 5 (dr.) | Ponowienie po `SAFETY` i innych blokadach | Ponawiamy tylko `MAX_TOKENS` i `OTHER`. Pozostałe przypadki kończą od razu z `ai_invalid_response`, bez drugiego płatnego wywołania |
| 6 (dr.) | Wąskie wykrywanie gołych domen | Wykrywamy dowolną domenę ze ścieżką oraz domeny ogólne i europejskie (tylko małe litery, żeby „square.It” nie dawało fałszywego alarmu). Test fałszywych alarmów |
| 7 (dr.) | 429 ponawiane natychmiast | Przed ponowieniem po 429/5xx/przekroczeniu czasu czekamy 1–2 s z losowym rozrzutem. Mieści się w 120 s funkcji |
| 9 (dr.) | `AI_MODEL_ID` przyjmuje dowolny `gemini-*` | Lista dozwolonych: `gemini-3.1-flash-lite` i `gemini-3.5-flash-lite` (Aneks C) |
| 4 (śr.) | Dokumenty RODO i wdrożenia | Poza uprawnieniami mobile-dev (`docs/security/`, `docs/architecture/`), więc nie edytowałem. Zgłoszenia niżej |

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-18: review. **Potrzebny jest ponowny krótki przegląd** PR #136, bo kod zmienił się po
  recenzji. Etykiety `review:ok` nie zdejmowałem.
- Zadania – nowe / zmienione:
  - **P3-05-CFG** (owner/GitHub Steward), uzupełnienie do wpisu `0850-mobile-dev-TAM-18.md`:
    dodanie `AI_MODEL_ID=gemini-3.1-flash-lite` i `AI_LOCATION=eu` do `.env.tamitu-dev-tadecode` **zależy od**:
    O4-2 (polityki TTL `usage.expireAt` i `usage_global.expireAt` wdrożone w dev), B-1 (`disableCache=true`)
    i W-1 (rola `roles/aiplatform.user` dla `fn-ai-plan`). Uzasadnienie: z tymi zmiennymi wdrożenie zaczyna zapisywać
    `usage/{uid}` (D10) i wywoływać Vertex. Bez nich funkcja odpowiada `ai_unavailable` (fail-closed).
  - **SEC (security)**: `docs/security/personal-data-register.md` D10. Po merge'u zmienić adnotację „P3-05 jeszcze nie
    zapisuje `usage`” na „P3-05 zapisuje `usage/{uid}`: `day`, `count`, `released` (liczba zwrotów slotu w dobie),
    `updatedAt`, `expireAt`”. Pole `released` to licznik techniczny, nie nowa kategoria danych. Retencja jak D10 (TTL O4-b).
  - **ARCH/DBA (architect lub dba)**: `docs/data/model-danych.md` (tabela `usage/{uid}`) oraz
    `docs/data/schema/firestore-ttl-indexes.md` pkt 3.2. Do dopisania pole `released` (zerowane w nowej dobie,
    najwyżej 2 zwroty na dobę) i to, że zwrot nie zmniejsza `usage_global`. Pole nie potrzebuje indeksu.
  - **ARCH (P3-05-DOC)**: `docs/architecture/deploy-dev-functions.md`, wiersz `generatePlan`: warunki O4-2, B-1 i W-1
    przed ustawieniem zmiennych AI. `posrednik-api.md` (pkt 2, „Slot limitu”): najwyżej 2 zwroty na konto i dobę,
    bez zwrotu po `internal`, `usage_global` bez zwrotu. `p3-05-wymagania-generowania.md` sekcja 3 pkt 3: kody
    ponawiane to 408, 429, 5xx, przekroczenie czasu i sieć, z odczekaniem 1–2 s. Blokady (`SAFETY` i pokrewne)
    nie są ponawiane.
- Pytania otwarte – nowe:
  - O-TAM18-3 (architect/owner): czy limit 2 zwrotów na dobę jest właściwy? Alternatywa z przeglądu to brak zwrotu po
    `ai_invalid_response` z błędami `*_url_markup` / `*_chars`. Wybrałem limit zwrotów, bo jest prostszy, nie zależy
    od treści odpowiedzi i ogranicza koszt także przy innych błędach.
- Pytania otwarte – zamknięte: O-TAM18-1 (czy zwrot zmniejsza `usage_global`). Pozostaje „nie”, a nadużycie
  ogranicza limit zwrotów. Do potwierdzenia przez architekta w ramach O-TAM18-3.
- Bez zmian (świadomie): uwaga 10, czyli test transakcji Firestore na emulatorze, zostaje w P3-05-EMU (qa).
