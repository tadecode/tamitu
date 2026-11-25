# Kontrakt API pośrednika (Cloud Functions callable)

Stan: 2026-11-21, wersja 0.6 (ponowienia po 429, nowy kod `ai_busy` bez zużycia limitu, jedno automatyczne ponowienie w aplikacji; TAM-96, ADR-0016 zatwierdzony warunkowo, w pełni od 2026-11-24 po TAM-97 – pkt 2 „Ponowienia po stronie serwera”, „Slot limitu i zwrot próby”, pkt 6, pkt 7); wcześniej 0.5 (zwrot próby i pole `slotReleased`, TAM-93/TAM-91), 0.4 (v0.2 zatwierdzona na G2 wraz z ADR-0002 i jego Aneksem A; v0.3 z ADR-0011 i v0.4 z ADR-0012, oba zatwierdzone przez właściciela 2026-11-16 – historia w pkt 7), autor: architect. ADR-0002, ADR-0011, ADR-0012. Schematy: `schemas/generate-plan.request.schema.json`, `schemas/generate-plan.response.schema.json`.
Region: `europe-west4`. Wywołanie przez SDK `cloud_functions` (callable): token ID Firebase i token App Check dołączane automatycznie. Format: JSON, UTF-8, `Content-Type: application/json`.

## 1. Zasady wspólne
- **Żądanie nie zawiera:** UID, e-maila, nazwy konta, lokalizacji (współrzędnych), numeru lotu, tokenów, danych rozliczeniowych. UID serwer bierze wyłącznie z zweryfikowanego tokenu.
- **Błędy:** serwer zwraca `HttpsError` z kodem technicznym i `details.code` (kod aplikacyjny z tabeli w pkt 6). Brak tekstów dla użytkownika i brak szczegółów technicznych (US-011); tłumaczenia w aplikacji.
- **Wersjonowanie:** pole `apiVersion` (liczba całkowita, obecnie 1) w żądaniu; niezgodna wersja → `unsupported_version` (z wyjątkiem `deleteAccount`, pkt 4).
- **Środowisko `dev`:** wyłącznie dane testowe – start funkcji z `ENVIRONMENT=dev` i `ALLOW_REAL_DATA=true` kończy się błędem inicjalizacji; w `dev` `config/runtime.allowRealData` jest ignorowane (ADR-0011 pkt 5, SEC-24).
- **`config/runtime`** (np. `policyVersionCurrent`) nie jest udostępniane klientowi; wersja polityki po stronie aplikacji to stała w kodzie (ADR-0011 pkt 1).
- **Czas:** daty `YYYY-MM-DD`, godziny `HH:MM` (24 h), strefa lokalna miejsca docelowego, bez przeliczania stref.
- **Logowanie:** zakaz logowania treści żądań i odpowiedzi; wyjątki logowane wyłącznie jako kod i klasa błędu, nigdy `error.message`/stos (ADR-0002, Aneks A pkt 2); kod i klasa spoza listy dozwolonych wzorców (kod `^[A-Za-z0-9_./:-]{1,60}$`, klasa – identyfikator do 60 znaków) logowane jako `unknown` (SEC-19).
- **Istnienie użytkownika:** `generatePlan` i `recordConsent` odrzucają token użytkownika usuniętego lub z unieważnionymi tokenami (`unauthenticated`), bez żadnego zapisu (ADR-0002, Aneks A pkt 1).
- **Doba limitu:** dzień kalendarzowy w strefie `Europe/Warsaw` (Q5); `resetAt` = najbliższa północ tej strefy, w UTC.
- Rozmiar żądania ≤ 4 KB; przekroczenie → `invalid_argument`.
- **Pola tekstowe** (`trip.destination`, `trip.lodging`, `trip.arrival.airport`) – „po oczyszczeniu” oznacza: obcięcie białych znaków na brzegach, normalizacja Unicode NFC, długość liczona po normalizacji; znaki kategorii Unicode `Cc` (sterujące), `Cf` (formatujące: zero-width, sterowanie kierunkiem, BOM, miękki dywiz), `Zl`, `Zp` (separatory wiersza i akapitu) → `invalid_argument` z `field` (SEC-21). Emoji i zwykłe spacje są dozwolone, ale emoji złożone ze znakiem ZWJ (U+200D) – odrzucane.

## 2. `generatePlan`
Wymaga: token ID (`sign_in_provider = google.com`), App Check, **aktualnej akceptacji `privacy_policy`** (ostatni rekord w wersji ≥ `config/runtime.policyVersionCurrent`), aktualnej zgody `ai_processing` (ostatni rekord `granted = true` w wersji ≥ `aiConsentVersionCurrent`), `aiEnabled = true`, wolnego limitu. Zgody sprawdzane w tej kolejności, przed rezerwacją limitu; wersje porównywane po numerze `N` z `privacy-vN` / `ai-consent-vN`; brak lub zły format wartości w `config/runtime` → fail-closed (`consent_required`, `privacy_policy`) (ADR-0012).

### Żądanie
```json
{
  "apiVersion": 1,
  "requestId": "7f0c2a9e-6f0e-4c3a-9a43-0b6c4a1f5d11",
  "planLanguage": "pl",
  "trip": {
    "destination": "Lizbona",
    "lodging": "Baixa, okolice Rossio",
    "days": 4,
    "arrival": {
      "mode": "flight",
      "date": "2027-03-12",
      "time": "18:10",
      "airport": "Lisbon Humberto Delgado (LIS)"
    }
  },
  "preferences": {
    "interests": ["monuments_history", "local_food"],
    "budget": "medium",
    "pace": "moderate",
    "partySize": 2
  },
  "testData": false
}
```
| Pole | Typ | Reguły |
|---|---|---|
| `apiVersion` | int | = 1 |
| `requestId` | string | UUID v4; do korelacji (w logach tylko skrót) |
| `planLanguage` | enum | `pl` \| `en` |
| `trip.destination` | string | 1–80 znaków po oczyszczeniu |
| `trip.lodging` | string | 1–80 znaków |
| `trip.days` | int | 1–14 |
| `trip.arrival.mode` | enum | `flight` \| `car` |
| `trip.arrival.date` | string | data, nie wcześniejsza niż „dziś − 2 dni" w strefie `Europe/Warsaw` (tolerancja na strefy UTC−12…UTC+14, ADR-0011 pkt 3) i nie późniejsza niż „dziś + 2 lata"; aplikacja waliduje ostrzej (od „wczoraj" w strefie urządzenia) |
| `trip.arrival.time` | string | `HH:MM` |
| `trip.arrival.airport` | string | wymagane przy `flight`, 1–60 znaków; zabronione przy `car` |
| `preferences.interests` | array | 0–5 unikalnych wartości z listy (`docs/data/model-danych.md`); inne wartości → `invalid_argument` |
| `preferences.budget` | enum | `low` \| `medium` \| `high` (brak → `medium`) |
| `preferences.pace` | enum | `relaxed` \| `moderate` \| `intense` (brak → `moderate`) |
| `preferences.partySize` | int | 1–10 (brak → 2) |
| `testData` | bool | opcjonalne, `true` tylko dla kont z `config/runtime.testUids` (warunek S5, ADR-0002); w aplikacji ze stałej kompilacji `TAMITU_TEST_DATA` – `dev` zawsze `true`, `prod` tylko buildy wewnętrzne do zamknięcia SEC-15 (ADR-0011 pkt 6) |

Nieznane pola są odrzucane (`invalid_argument`) – brak przypadkowego przesyłania danych.

### Odpowiedź 200
```json
{
  "apiVersion": 1,
  "requestId": "7f0c2a9e-6f0e-4c3a-9a43-0b6c4a1f5d11",
  "language": "pl",
  "promptVersion": "plan-v1",
  "days": [
    {
      "dayNumber": 1,
      "title": "Przyjazd i spokojny wieczór",
      "items": [
        { "startTime": "21:30", "name": "Time Out Market", "locality": "Lizbona", "description": "Kolacja z lokalnymi potrawami." }
      ]
    }
  ],
  "quota": { "limit": 5, "remainingToday": 3, "resetAt": "2026-11-16T23:00:00Z" }
}
```
Gwarancje po walidacji serwerowej: liczba dni = `trip.days`; `dayNumber` kolejne od 1; punktów w dniu: `relaxed` 2–3, `moderate` 4–5, `intense` 6–7 (dzień 1 może mieć mniej, także 0, wg bufora); **ostatni dzień (przy co najmniej 2 dniach): od 1 do górnej granicy tempa** (O-TAM4-1, zatwierdzone przez właściciela 2026-11-21); zakres dla każdego dnia liczy kod i przekazuje modelowi, `docs/architecture/p3-05-wymagania-generowania.md` sekcja 4; godziny rosnące w dniu; **dzień 1: wszystkie `startTime` ≥ przylot + bufor (3 h przy `flight`, 0 przy `car`, N6)**, a jeśli próg przekracza 22:00 – brak aktywności w dniu 1; teksty bez URL-i, znaczników i znaków sterujących, w długościach: `title` ≤ 80, `name` ≤ 100, `locality` ≤ 80, `description` ≤ 300; język odpowiedzi zgodny z `planLanguage`. Pola `startTime`, `name`, `locality` służą aplikacji do budowy linku Maps (`name, locality, destination`); model nie zwraca URL-i ani współrzędnych (T5).

### Błędy
| `details.code` | Kod HttpsError | Znaczenie | Dodatkowe `details` |
|---|---|---|---|
| `unauthenticated` | `unauthenticated` | brak/niepoprawny token lub dostawca ≠ google.com | – |
| `app_check_failed` | `failed-precondition` | brak/niepoprawny token App Check | – |
| `invalid_argument` | `invalid-argument` | błąd schematu/zbioru/długości | `field` (ścieżka pola, bez wartości) |
| `unsupported_version` | `failed-precondition` | niezgodna `apiVersion` | `minVersion` |
| `consent_required` | `failed-precondition` | brak aktualnej akceptacji polityki lub zgody AI (ADR-0012) | `consentType` ∈ {`privacy_policy`, `ai_processing`} |
| `limit_exceeded` | `resource-exhausted` | limit konta wyczerpany | `limit`, `resetAt` |
| `ai_unavailable` | `unavailable` | model niedostępny (w tym 429, jeśli w generowaniu była też próba płatna), limit globalny, `aiEnabled=false`, brak konfiguracji modelu, przekroczony czas | `slotReleased` (bool, zawsze od v0.5), `retryAfterSec` (opcjonalnie; od v0.6 serwer go tu nie wysyła) |
| `ai_busy` (od v0.6) | `unavailable` | AI chwilowo przeciążone: **wszystkie** wywołania modelu w tym generowaniu dostały HTTP 429, żadna próba nie była płatna (ADR-0016 pkt 6). Próba nie zużywa limitu (niżej) | `retryAfterSec` (int, zawsze; dziś 60), `slotReleased` (bool, zawsze) |
| `ai_invalid_response` | `internal` | odpowiedź niepoprawna po 2 próbach płatnych (blokada treści, np. `SAFETY`, kończy od razu, bez drugiej próby) | `slotReleased` (bool, zawsze od v0.5) |
| `test_data_only` | `permission-denied` | `ALLOW_REAL_DATA=false`, a konto/żądanie nie testowe; także fail-closed w prod przy `allowRealData=true` i `ENFORCE_APP_CHECK=false` (ADR-0002, Aneks A pkt 3) | – |
| `internal` | `internal` | nieoczekiwany błąd | – |

### Ponowienia po stronie serwera (v0.6, ADR-0016)
Co to znaczy dla użytkownika: gdy AI jest chwilowo przeciążone, serwer sam próbuje jeszcze raz i czeka przy tym kilka sekund. Plan może więc przyjść później niż zwykle (najdłużej ok. 100 s), ale rzadziej kończy się błędem.

- Na jedno generowanie przypada najwyżej **3 wywołania modelu**, w tym najwyżej **2 próby płatne**. Wywołanie zakończone HTTP 429 nie jest płatne, więc trzecie wywołanie jest możliwe tylko po 429.
- Przed ponowieniem po błędzie ponawianym (408, 429, 5xx, czas, sieć) serwer czeka losowo 2–4 s, a przed trzecim wywołaniem 4–8 s. Po złej odpowiedzi modelu ponawia od razu, z listą błędów.
- Budżet czasu generowania to 100 s. Kolejne wywołanie rusza tylko wtedy, gdy zostało ≥ 45 s. Timeout klienta (120 s) bez zmian.
- Jedno generowanie to zawsze jeden slot konta i jeden slot globalny, niezależnie od liczby wywołań. Zasady zwrotu niżej, w tym reguła 7 dla `ai_busy`.
- Gdy **wszystkie** wywołania skończyły się 429 (0 prób płatnych), wynik to `ai_busy` z `retryAfterSec = 60`. Każdy inny koniec bez planu, także mieszany (np. `timeout → 429 → 429`), działa jak dotąd: `ai_unavailable` albo `ai_invalid_response` według ostatniego błędu.
- Zgodność wstecz: `apiVersion` zostaje 1. Starsza aplikacja nie zna `ai_busy` i pokaże ogólny komunikat (`internal`, pkt 6), bez obietnicy zwrotu. To bezpieczne, a aplikacji publicznej jeszcze nie wydano.

### Slot limitu i zwrot próby
Co to znaczy dla użytkownika: gdy plan nie powstanie z naszej winy (AI niedostępne albo zła odpowiedź), zwykle oddajemy próbę, ale **najwyżej 2 razy na dobę**. Trzecia i kolejna taka awaria w tej samej dobie zużywa już limit konta. Wyjątek: chwilowe przeciążenie AI (`ai_busy`, od v0.6) nas nic nie kosztuje, więc nie zużywa limitu i nie liczy się do tych 2 zwrotów (reguła 7). Tak zdecydował właściciel 2026-11-21 (O-TAM18-3), bo każda nieudana próba i tak kosztuje wywołania modelu.

Reguły (serwer: `backend/functions/src/limits.ts`, `endpoints.ts`):
1. Slot konta (`usage/{uid}`) jest rezerwowany **przed** wywołaniem modelu (ADR-0002 krok 5). Błędy wykryte wcześniej (zgody, `aiEnabled=false`, brak konfiguracji modelu, limit globalny wyczerpany przy rezerwacji) slotu nie zużywają.
2. Po rezerwacji slot wraca **tylko** po `ai_unavailable` i `ai_invalid_response`, i tylko wtedy, gdy konto ma w tej dobie wolny zwrot: **najwyżej 2 zwroty na konto na dobę** (`MAX_RELEASES_PER_DAY = 2`, pole `usage/{uid}.released`, zerowane w nowej dobie). Od trzeciego takiego błędu w dobie próba zostaje wliczona do limitu.
3. Po `internal` slot **nie** wraca (nieoczekiwany błąd; kosztowo bezpieczniej).
4. Zwrot zmniejsza tylko `usage/{uid}.count`. **`usage_global` nigdy nie maleje**: licznik globalny jest bezpiecznikiem kosztu, a wywołania modelu zostały już opłacone (O-TAM18-1). Jedno konto zużywa więc najwyżej `perUserDailyLimit + 2` slotów globalnych na dobę (dziś 5 + 2 = 7).
5. Zwrot po północy nie przenosi slotu do nowej doby (`docs/data/schema/firestore-ttl-indexes.md` pkt 3.2).
6. Nieudany zapis zwrotu (błąd Firestore) nie zmienia kodu błędu dla aplikacji; slot zostaje zużyty.
7. **`ai_busy` (od v0.6, ADR-0016 pkt 8):** przeciążenie AI nas nic nie kosztuje (0 prób płatnych), więc slot konta **wraca zawsze** i **nie liczy się** do limitu 2 zwrotów z reguły 2. Wraca też slot globalny (`usage_global`). To wyjątek od reguły 4 z tego samego powodu: nie było płatnego wywołania. Bezpiecznik nadużyć: najwyżej **10** takich zwrotów na konto na dobę (`usage/{uid}.busyReleased`, zerowane z nową dobą). Od 11. `ai_busy` w dobie slot konta i globalny zostają zużyte (`slotReleased = false`). Regułę 5 i 6 stosuje się bez zmian.

Zabezpieczenia `ai_busy` przed nadużyciem: kod jest wyłącznie przy 0 próbach płatnych, czyli bez żadnej odpowiedzi modelu, więc nie da się nim dostać planu ani tokenów za darmo. Przyczynę ustala serwer ze statusu HTTP Vertex. Rezerwacja slotu zostaje przed wywołaniem modelu, więc konto z wyczerpanym limitem dostaje `limit_exceeded` bez wywołania modelu. Do tego bezpiecznik 10 na dobę, token ID, App Check i `maxInstances`.

**Pole `details.slotReleased`** (od v0.5; przy `ai_unavailable` i `ai_invalid_response` serwer wysyła je zawsze):
- `true` – ta próba **nie** zużyła limitu konta: slotu nie zarezerwowano (reguła 1) albo zwrot się udał (reguła 2);
- `false` – próba **została wliczona** do limitu: wyczerpany limit zwrotów w dobie, zwrot po północy albo nieudany zapis zwrotu.

Pole to jedna wartość logiczna: bez danych osobowych i bez stanu limitu. Aplikacja wybiera według niej tekst komunikatu (pkt 6). Brak pola (starszy serwer) oznacza „nie wiadomo”, więc aplikacja mówi, że próba **mogła** zostać wliczona. Starsza aplikacja ignoruje nieznane pole w `details`, więc zmiana jest zgodna wstecz, a `apiVersion` zostaje 1.

**Logi** (bez danych osobowych): wpis `generatePlan` ma pole `quotaRelease` ze stałym kodem: `released` (zwrot zapisany), `release_capped` (limit 2 zwrotów wyczerpany), `busy_released` i `busy_capped` (zwrot `ai_busy` zapisany / bezpiecznik 10 na dobę wyczerpany, od v0.6), `release_failed` (błąd zapisu zwrotu). Z tego właściciel widzi, jak często działa limit zwrotów (dane do przeglądu O-TAM18-3). Wpis `generatePlan.attempt` ma pole `validationErrors`: kody błędów walidacji odpowiedzi modelu, zbudowane przez serwer, rozdzielone przecinkiem, do 200 znaków (np. `items_count@day5`), bez treści odpowiedzi (`docs/architecture/p3-05-wymagania-generowania.md` sekcja 6).

Slot **nie** jest zwracany po anulowaniu przez użytkownika, jeśli wywołanie modelu już ruszyło (Q12). Callable nie ma przerwania żądania: anulowanie = porzucenie wyniku po stronie aplikacji (odpowiedź z tym `requestId` jest odrzucana, nic nie zapisujemy); żądanie na serwerze kończy się normalnie (ADR-0011). Timeout klienta: 120 s.

### Prompt (zasady, bez treści)
Instrukcje systemowe po angielsku w `systemInstruction`; dane użytkownika jako wartości w obiekcie JSON w osobnej turze, z poleceniem traktowania ich jako danych; wymuszony `responseSchema`; brak narzędzi; wersja promptu w `promptVersion`. Treść promptu w repozytorium (`backend/functions/src/prompt`), nie w kontrakcie.

## 3. `recordConsent`
Wymaga: token ID, App Check.

Żądanie:
```json
{
  "apiVersion": 1,
  "consentId": "0d8f1c1e-33b8-4a3e-bf4a-0a3d8c1f9e22",
  "type": "ai_processing",
  "granted": true,
  "policyVersion": "ai-consent-v1",
  "lang": "pl",
  "clientAt": "2026-11-15T10:12:03Z"
}
```
Odpowiedź 200: `{ "consentId": "...", "receivedAt": "2026-11-15T10:12:04Z" }`. Idempotentne po `consentId` (powtórne wysłanie nie tworzy duplikatu). Walidacja: `type` ∈ {`privacy_policy`, `ai_processing`}, `lang` ∈ {`pl`, `en`}, `policyVersion` – wzorzec `^(privacy|ai-consent)-v[1-9]\d{0,3}$`, prefiks zgodny z `type` (`privacy` ↔ `privacy_policy`, `ai-consent` ↔ `ai_processing`) i wersja z listy znanych w kodzie serwera, inaczej `invalid_argument` z `field: policyVersion` (ADR-0012, SEC-21), `clientAt` w przedziale ±24 h od czasu serwera (w przeciwnym razie zapisany czas serwera, pole `clientAt` oznaczone jako skorygowane). Błędy: `unauthenticated` (także użytkownik usunięty), `app_check_failed`, `invalid_argument`, `internal`. Wycofanie zgody (`granted=false`) aplikacja zapisuje przed potwierdzeniem w UI (ADR-0002, Aneks A pkt 4).

## 4. `deleteAccount`
Wymaga: token ID z `auth_time` ≤ 5 min, App Check. **Nie wymaga** `sign_in_provider = google.com` (usuwa wyłącznie konto z tokenu) i **nie zwraca** `unsupported_version` – przyjmuje każdą `apiVersion` ≥ 1, aby prawo do usunięcia nie zależało od wersji aplikacji ani dostawcy (ADR-0011 pkt 4). Aplikacja przed wywołaniem zawsze wykonuje ponowne uwierzytelnienie Google (ADR-0011 pkt 8). Żądanie: `{ "apiVersion": 1 }`. Odpowiedź 200: `{ "deleted": true }`. Kolejność: dane Firestore → użytkownik Auth → kontrolne powtórne usunięcie Firestore. Dowód zgód usuwany z kontem (Q9). Błędy: `reauth_required` (`failed-precondition`), `unauthenticated`, `app_check_failed`, `internal`. Idempotentne.

## 5. `budgetGuard` (wewnętrzna)
Wyzwalacz Pub/Sub z powiadomień budżetowych; brak publicznego punktu wejścia. Przy `costAmount ≥ budgetAmount` w projekcie prod ustawia `config/runtime.aiEnabled=false`. Bez danych użytkowników; konto usługi `fn-budget` bez dostępu do Auth.

## 6. Konwencje dla aplikacji
- Aplikacja mapuje `details.code` na klucze tłumaczeń; nieznany kod → `internal`.
- Błędy klienta (ADR-0011 pkt 2): `unavailable` **bez** `details.code` (błąd transportu) oraz `network-request-failed` (Auth/logowanie) → „brak sieci"; `deadline-exceeded` → „przekroczony czas". Brak sieci wykrywany po próbie – aplikacja nie używa detektora łączności ani `ACCESS_NETWORK_STATE`.
- Przed `generatePlan` aplikacja wysyła oczekujące rekordy zgód (`synced = 0`) (ADR-0012 pkt 5).
- `consent_required`: `consentType = privacy_policy` → EK-03, `ai_processing` → EK-06. Gdy aplikacja ma już zsynchronizowany rekord tego typu w wersji wbudowanej w aplikację → komunikat „Zaktualizuj aplikację" (bez pętli; ADR-0011 pkt 7, ADR-0012 pkt 5). Serwer podnosi `aiConsentVersionCurrent` dopiero po wydaniu aplikacji z nowym tekstem zgody.
- `limit_exceeded.resetAt` jest w UTC; aplikacja formatuje w czasie lokalnym (US-011).
- `ai_unavailable` i `ai_invalid_response`: tekst według `details.slotReleased`. `true` → „próba nie wlicza się do limitu”, `false` → „próba została wliczona” (z wyjaśnieniem, że zwracamy najwyżej 2 próby na dobę), brak pola → „próba mogła zostać wliczona”. Aplikacja nie obiecuje zwrotu bez `slotReleased = true`. Przy `internal` – bez obietnicy zwrotu.
- `ai_busy` (od v0.6, ADR-0016 pkt 10–14): komunikat o chwilowym przeciążeniu AI (np. „Nasz asystent AI jest chwilowo przeciążony. Spróbujemy ponownie za minutę.”, teksty PL/EN: UX), odliczanie od `retryAfterSec` (przyjmowane 30–120 s, inaczej 60 s), przycisk „Spróbuj teraz” i rezygnacja. Po odliczaniu aplikacja **raz** sama wywołuje `generatePlan` z tymi samymi danymi i nowym `requestId`, tylko gdy ekran jest na pierwszym planie. „Spróbuj teraz” zastępuje to ponowienie, a nie dodaje drugiego. Jeśli i ono się nie uda, zostaje sam przycisk, bez kolejnych automatów. Tekst o limicie według `slotReleased`, jak wyżej.
- Poza `ai_busy` brak automatycznych ponowień `generatePlan` w aplikacji (każde ponowienie zużywa slot limitu); ponowienie wyłącznie z decyzji użytkownika. `recordConsent` i `deleteAccount` są idempotentne i mogą być ponawiane automatycznie.

## 7. Historia zmian
- **v0.6 (2026-11-21, architect, TAM-96, ADR-0016 – zatwierdzony warunkowo, O-TAM96-1):** ponowienia po stronie serwera: najwyżej 3 wywołania modelu i najwyżej 2 próby płatne (wywołanie z 429 nie jest płatne), odczekanie 2–4 s i 4–8 s, budżet 100 s. Nowy kod `ai_busy` (wszystkie wywołania 429), z `retryAfterSec` = 60 i `slotReleased`; slot konta i globalny wracają poza limitem 2 zwrotów, bezpiecznik 10 na konto na dobę; kody logów `busy_released` i `busy_capped`. W aplikacji jedno automatyczne ponowienie po `ai_busy`. `apiVersion` 1; starsza aplikacja pokazuje przy `ai_busy` ogólny błąd. Implementacja: mobile-dev, po potwierdzeniu w Billing, że 429 nie jest rozliczane.
- **v0.5 (2026-11-21, architect, TAM-93/TAM-91):** zwrot slotu opisany zgodnie z kodem P3-05 i decyzją właściciela O-TAM18-3: najwyżej 2 zwroty na konto na dobę, bez zwrotu po `internal`, `usage_global` bez zwrotu. Nowe pole `details.slotReleased` przy `ai_unavailable` i `ai_invalid_response` (zgodne wstecz, `apiVersion` bez zmian; implementacja – mobile-dev). Kody `quotaRelease` i `validationErrors` w logach. Reguła ostatniego dnia zatwierdzona (O-TAM4-1).
- **v0.4.1 (2026-11-20, mobile-dev, TAM-58/59/60 – doprecyzowanie bez zmiany pól i kodów):** „po oczyszczeniu” dla pól tekstowych = NFC + odrzucenie `Cc`/`Cf`/`Zl`/`Zp` (SEC-21); lista dozwolonych wzorców kodu i klasy błędu w logach (SEC-19). Granice limitów z `config/runtime` (SEC-22) nie zmieniają kontraktu.
- **v0.4 (2026-11-16, ADR-0012 zatwierdzony przez właściciela; S17, SEC-26):** `generatePlan` egzekwuje aktualną akceptację `privacy_policy` (`consent_required`, `consentType=privacy_policy`); porównanie wersji „≥ bieżąca" dla obu zgód; wzorzec i lista znanych wersji w `recordConsent`; wysyłka oczekujących zgód przed `generatePlan`. Implementacja – mobile-dev (P3-04/P3-05).
- **v0.3 (2026-11-16, ADR-0011 zatwierdzony przez właściciela):** data przylotu „dziś − 2 dni" (Warsaw); `deleteAccount` bez wymogu dostawcy i bez `unsupported_version`; `dev` tylko dane testowe (SEC-24); mapowanie błędów klienta i pętli `consent_required`; `testData` ze stałej kompilacji; anulowanie = porzucenie wyniku; `config/runtime` niedostępne dla klienta. Implementacja w `backend/functions` – zadanie mobile-dev (`docs/architecture/przeglad-ekranow-p3-14c.md` pkt 5).
- **v0.2 (2026-11-15):** zatwierdzona na G2 (ADR-0002 z Aneksem A).
