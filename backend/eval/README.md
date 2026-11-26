# Zestaw ewaluacyjny P3-05 (TAM-18)

**Co i po co:** sprawdza, czy prompt (domyślnie produkcyjny `plan-v1`, opcją `--prompt plan-v2` – wersja testowa
z TAM-95) z wybranym modelem daje poprawne plany
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

Opcje: `--prompt plan-v2` (domyślnie `plan-v1`; inna wartość niż znana wersja → odmowa startu),
`--model gemini-3.5-flash-lite` (zapasowy), `--only E03,E04`, `--lang pl`, `--location eu`.
Tryb `--paid` działa tylko na projekcie `tamitu-dev-tadecode` i tylko na punktach `eu` / `europe-west4`.
Token żyje ok. 1 h i nie jest nigdzie zapisywany.

## Wynik

- W konsoli: odsetek poprawnych w ≤ 2 próbach (próg **95%**), odsetek poprawnych w 1. próbie (wskaźnik ponowień),
  liczba planów z powtórzonym miejscem (`dup_place@dayN`, TAM-95; tylko ostrzeżenie, nie obniża wyniku),
  kody błędów walidacji, tokeny, czas, koszt.
- W `%TEMP%\tamitu-eval-p305\<znacznik czasu>\`: `results.csv` i plany (`E01-pl.json` …) do ręcznej oceny K3/K4
  (`docs/architecture/arch-01-gemini-test.md` sekcja 4.6). Po ocenie folder usunąć.
- Gdy wynik < 95% tylko z powodu liczby punktów – decyzja właściciela (`p3-05-wymagania-generowania.md` sekcja 7).

## Powtórzone miejsca (TAM-95)

**Co i po co:** w ocenie ręcznej TAM-88 (K4 c) to samo miejsce pojawiło się w dwóch dniach w 3 z 11 planów.
Prompt `plan-v2` jawnie tego zabrania, a walidator (przy każdym prompcie) wyłapuje proste przypadki i zapisuje kod
`dup_place@dayN` (N = późniejszy dzień) w polu `qualityWarnings` logu próby i w kolumnie `qualityWarnings` pliku
`results.csv`.

### `plan-v2` dopiero po płatnym teście

- **Produkcja używa `plan-v1`**, bo tylko on przeszedł płatną ewaluację (TAM-88: 38/40 = 95,0%, bez zapasu).
  Dłuższa instrukcja w `plan-v2` może zmienić rozkład innych błędów (liczba punktów, godziny), czego testy bez sieci
  nie pokażą (przegląd PR #148, uwaga 2).
- `plan-v2` włącza parametr wdrożenia `AI_PROMPT_VERSION=plan-v2` (plik `.env.<projekt>`). Brak, pusta lub nieznana
  wartość → `plan-v1` (fail-closed). Wersję faktycznie użytą widać w odpowiedzi (`promptVersion`) i w logu próby.
- Kolejność: zgoda właściciela → `node backend/eval/run-eval.mjs --paid --confirm-paid-run --prompt plan-v2
  --stop-pln 2.5` → ocena ręczna K4 c → decyzja właściciela → dopiero wtedy `AI_PROMPT_VERSION=plan-v2` w dev.
- **Szacunek kosztu testu `plan-v2`:** jak w tabeli wyżej dla `gemini-3.1-flash-lite`: ok. 0,70 PLN (1 próba),
  ok. 1,00 PLN (40% ponowień), najwyżej ok. 1,40 PLN (80 wywołań); sufit `--stop-pln 2.5`. Dłuższy prompt dodaje
  ok. 70 tokenów wejścia na wywołanie (poniżej 0,01 PLN na cały przebieg).

- **To ostrzeżenie, a nie błąd.** Plan z powtórzeniem jest nadal poprawny i nie powoduje ponowienia. Powód: każde
  ponowienie to drugie płatne wywołanie (ok. +100% kosztu tego generowania) i dłuższe czekanie, a QA uznało, że plan
  z powtórzeniem da się używać. Reguła może się też pomylić (dwa różne miejsca o podobnej nazwie), a błąd walidacji
  obniżałby wynik progu 95% (TAM-88 miał zerowy zapas). Gdy dane z dev pokażą, że powtórzeń jest dużo, można
  rozważyć zmianę na błąd – to decyzja kosztowa właściciela.
- **Jak działa reguła:** porównuje tylko punkty z tą samą miejscowością (`locality` po normalizacji). Nazwy po
  normalizacji (małe litery, bez znaków diakrytycznych i interpunkcji, bez dopisków typu „Market”, „Morning”, „The”,
  „Restauracja”, „Cafe”) są równe albo krótsza (co najmniej 2 słowa, nie same ogólne słowa) jest ciągłym fragmentem
  dłuższej. Przykład: „Campo de' Fiori” i „Campo de' Fiori Morning Market” w Rzymie.
- **Czego celowo nie liczy (przegląd PR #148, uwaga 1):** „Stare Miasto” w Gdańsku i w Toruniu (różne miejscowości);
  „Old Town” i „Old Town Hall”, „Central Park” i „Central Park Zoo”, „Muzeum Narodowe” i „Muzeum Narodowe –
  Sukiennice” (nazwa z samych ogólnych słów liczy się tylko przy równości); „Ristorante Da Enzo” i „Caffè Da Enzo”
  (restauracja i kawiarnia).
- **Licznik to górne oszacowanie.** Przed ewentualną zmianą ostrzeżenia na błąd (płatne ponowienie) trzeba ręcznie
  sprawdzić próbkę trafień. Nocleg wpisany jako punkt w dwóch dniach liczy się jako `dup_place`, a nie osobny kod.
- **Czego nie wyłapie:** nazw potocznych lub innych nazw tego samego miejsca („Fontana Pretoria” i „Piazza della
  Vergogna”). To wymagałoby wiedzy o miejscach; tu działa tylko prompt i ocena ręczna.
- **Koszt promptu:** reguła w `plan-v2` to ok. 70 tokenów wejścia więcej na wywołanie, czyli ułamek grosza na 40
  generowań; szacunek w tabeli wyżej się nie zmienia (zasada 10).

## Atrapa modelu dla emulatora Firebase (TAM-89)

**Co i po co:** testy `generatePlan` na emulatorach (rezerwacja i zwrot limitu na prawdziwym Firestore) potrzebują
modelu. Prawdziwego Vertex w emulatorze nie ma, więc funkcja wywołuje lokalną atrapę
`backend/functions/test/emulator/vertex-fake.mjs`. Atrapa odpowiada zawsze tak samo, bez sieci zewnętrznej,
bez kluczy i bez kosztów.

**Bezpieczeństwo (fail-closed):** zmienną `AI_ENDPOINT_OVERRIDE` funkcja przyjmuje tylko wtedy, gdy spełnione są
wszystkie warunki: `FUNCTIONS_EMULATOR=true`, projekt `demo-*` (taki projekt nie istnieje w Google Cloud) i adres
`http://127.0.0.1:<port>` albo `http://localhost:<port>`. W każdym innym przypadku (wdrożone dev i prod, inny host,
https, dane logowania w adresie) funkcja odpowiada `ai_unavailable` przed rezerwacją limitu. Nigdy nie przełącza
się wtedy po cichu na prawdziwy Vertex. W trybie atrapy funkcja nie pobiera tokenu konta usługi, tylko wysyła
stały napis `emulator-fake-token`. Opcjonalne `AI_ATTEMPT_TIMEOUT_MS` (100–45000, też tylko w emulatorze) skraca
czas oczekiwania na odpowiedź, żeby scenariusz przekroczenia czasu nie trwał 90 s. Testy: `ai-endpoint-override.test.ts`.

**Uruchomienie** (z katalogu głównego repozytorium, zawsze przez kolejkę farmy):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .farm/test-lock.ps1 -Resource firebase-emulators -Command "powershell -NoProfile -ExecutionPolicy Bypass -File backend/functions/test/emulator/run-emulator-tests.ps1"
```

Bez parametrów uruchamia test dymny `smoke.int.mjs`. Własne pliki podajesz przez `-Tests` (ścieżki względem
katalogu głównego, np. `-Tests tests/firebase-emulator/p3-05-generate-plan.int.mjs`). Skrypt ustawia zmienne
tylko w swoim procesie (`ENVIRONMENT=dev`, `ENFORCE_APP_CHECK=false`, `AI_MODEL_ID`, `AI_LOCATION=eu`,
`AI_ENDPOINT_OVERRIDE=http://127.0.0.1:8787`, `AI_ATTEMPT_TIMEOUT_MS=2000`). Gdy brakuje `.secret.local`, zapisuje
tam losowy testowy `UID_HASH_PEPPER` (plik ignorowany przez git). Buduje funkcje i uruchamia
`firebase emulators:exec --project demo-tamitu-qa --only auth,functions,firestore`. Java: jeśli `JAVA_HOME` nie
jest ustawione, skrypt bierze JBR z Android Studio.

**Sterowanie atrapą z testu.** Test sam uruchamia atrapę na porcie z `AI_ENDPOINT_OVERRIDE` (domyślnie 8787):

```js
import { startVertexFake } from "../../backend/functions/test/emulator/vertex-fake.mjs";
const fake = await startVertexFake({ port: 8787 }); // domyślnie "valid"
fake.enqueue("busy", "valid");  // kolejne wywołania: 429, potem poprawny plan, potem znowu domyślny
fake.setDefault("invalid");     // każde wywołanie bez scenariusza w kolejce
fake.calls;                     // [{ n, scenario, status, model, location, hints }]
fake.reset(); await fake.close();
```

Z innego procesu: `POST /__fake/control` z `{"reset":true,"default":"valid","queue":["busy"]}` i `GET /__fake/calls`.

| Scenariusz | Odpowiedź atrapy | Wynik `generatePlan` (domyślny scenariusz dla wszystkich wywołań) |
|---|---|---|
| `valid` | poprawny plan dla `dayTargets` z zapytania | sukces, 1 wywołanie |
| `invalid` | plan bez dni (błąd walidacji) | `ai_invalid_response`, 2 wywołania (drugie z listą błędów, `hints=true`) |
| `blocked` | `finishReason: SAFETY`, bez tekstu | `ai_invalid_response`, 1 wywołanie (bez ponowienia) |
| `busy` | HTTP 429 | `ai_busy` (`retryAfterSec: 60`), 3 wywołania, zwrot slotu ADR-0016 |
| `server_error` | HTTP 503 | `ai_unavailable`, 2 wywołania (przerwa 2–4 s) |
| `bad_body` | HTTP 200, treść nie jest JSON | `ai_unavailable`, 2 wywołania |
| `timeout` | brak odpowiedzi | `ai_unavailable`, 2 wywołania po `AI_ATTEMPT_TIMEOUT_MS` |
| `config_error` | HTTP 403 | `ai_unavailable`, 1 wywołanie (bez ponowienia) |

Wyniki w kolumnie po prawej sprawdza bez emulatora test `backend/functions/test/vertex-fake.test.ts`
(prawdziwy dostawca i prawdziwa pętla generowania, połączenie tylko przez 127.0.0.1).
