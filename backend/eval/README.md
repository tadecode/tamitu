# Zestaw ewaluacyjny P3-05 (TAM-18)

**Co i po co:** sprawdza, czy prompt produkcyjny `plan-v1` z wybranym modelem daje poprawne plany
w co najmniej 95% przypadków (ADR-0001 pkt 2). Używa tej samej ścieżki kodu co funkcja `generatePlan`
(prompt, `responseSchema`, walidator, jedna ponowna próba), więc wynik mówi o prawdziwym zachowaniu aplikacji.

**Uruchomienie na prawdziwym modelu kosztuje pieniądze** i wymaga zgody właściciela. Agenci uruchamiają tylko
tryby bez sieci (`--estimate`, `--dry-run`).

## Zawartość

- `cases.json` – 20 fikcyjnych podróży (1–14 dni, trzy tempa, lot i auto, przypadki brzegowe dnia 1:
  próg dokładnie 22:00, 21:59, pusty dzień 1). Każdy przypadek idzie po polsku i po angielsku = **40 generowań**.
  Bez danych osobowych; daty przylotu liczone względem dnia uruchomienia.
- `run-eval.mjs` – uruchamiacz (Node 22, bez dodatkowych zależności).

## Koszt (szacunek, cennik z `docs/architecture/costs.md` sekcja 0)

| Model | 1 próba na generowanie | ok. 40% ponowień | najgorszy przypadek (80 wywołań) |
|---|---|---|---|
| `gemini-3.1-flash-lite` | ok. 0,70 PLN | ok. 1,00 PLN | ok. 1,40 PLN |
| `gemini-3.5-flash-lite` (zapasowy) | ok. 1,15 PLN | ok. 1,60 PLN | ok. 2,30 PLN |

Wywołań: od 40 do 80. `--stop-pln` (domyślnie i najwyżej **2,5 PLN**; przyjmuje `2.5` i `2,5`) to **sufit**:
kolejne generowanie startuje tylko wtedy, gdy nawet jego najgorszy wariant (2 próby × szacunek × 1,5) zmieści się
w limicie. Koszt liczy się z tokenów zwróconych przez Vertex, a próbę bez danych o tokenach (przekroczenie czasu,
5xx) doliczamy po szacunku. Wartość nieliczbowa, spoza zakresu (0; 2,5], flaga bez wartości albo model spoza
cennika → uruchamiacz odmawia startu (fail-closed, w każdym trybie). Logikę sprawdza `eval-guard.mjs`, a testy są w
`backend/functions/test/eval-guard.test.ts`. Przebieg mieści się w spend cap dev (15 PLN). Uruchamiacz wywołuje Vertex
bezpośrednio z konta właściciela, z pominięciem funkcji, więc **nie** zużywa limitu 25/dobę w Firestore
(spend cap dev nadal obowiązuje).

## Kroki (właściciel, po zgodzie)

```powershell
npm --prefix backend/functions ci
npm --prefix backend/functions run build
node backend/eval/run-eval.mjs                      # szacunek, bez sieci
node backend/eval/run-eval.mjs --dry-run            # sprawdzenie uruchamiacza, bez sieci
gcloud auth login                                   # konto z dostępem do tamitu-dev-tadecode
$env:VERTEX_ACCESS_TOKEN = gcloud auth print-access-token
node backend/eval/run-eval.mjs --paid --confirm-paid-run --stop-pln 2.5
Remove-Item Env:VERTEX_ACCESS_TOKEN
```

Opcje: `--model gemini-3.5-flash-lite` (zapasowy), `--only E03,E04`, `--lang pl`, `--location eu`.
Tryb `--paid` działa tylko na projekcie `tamitu-dev-tadecode` i tylko na punktach `eu` / `europe-west4`.
Token żyje ok. 1 h i nie jest nigdzie zapisywany.

## Wynik

- W konsoli: odsetek poprawnych w ≤ 2 próbach (próg **95%**), odsetek poprawnych w 1. próbie (wskaźnik ponowień),
  kody błędów walidacji, tokeny, czas, koszt.
- W `%TEMP%\tamitu-eval-p305\<znacznik czasu>\`: `results.csv` i plany (`E01-pl.json` …) do ręcznej oceny K3/K4
  (`docs/architecture/arch-01-gemini-test.md` sekcja 4.6). Po ocenie folder usunąć.
- Gdy wynik < 95% tylko z powodu liczby punktów – decyzja właściciela (`p3-05-wymagania-generowania.md` sekcja 7).
