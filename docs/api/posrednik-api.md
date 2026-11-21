# Kontrakt API pośrednika (Cloud Functions callable)

Stan: 2026-11-16, wersja 0.4 (v0.2 zatwierdzona na G2 wraz z ADR-0002 i jego Aneksem A; v0.3 z ADR-0011 i v0.4 z ADR-0012, oba zatwierdzone przez właściciela 2026-11-16 – historia w pkt 7), autor: architect. ADR-0002, ADR-0011, ADR-0012. Schematy: `schemas/generate-plan.request.schema.json`, `schemas/generate-plan.response.schema.json`.
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
Gwarancje po walidacji serwerowej: liczba dni = `trip.days`; `dayNumber` kolejne od 1; punktów w dniu: `relaxed` 2–3, `moderate` 4–5, `intense` 6–7 (dzień 1 może mieć mniej, także 0, wg bufora); **ostatni dzień (przy co najmniej 2 dniach): od 1 do górnej granicy tempa, nigdy pusty** (decyzja właściciela 2026-11-21, O-TAM4-1); dni od 2 do przedostatniego – pełny zakres tempa; zakres dla każdego dnia liczy kod i przekazuje modelowi, `docs/architecture/p3-05-wymagania-generowania.md` sekcja 4; godziny rosnące w dniu; **dzień 1: wszystkie `startTime` ≥ przylot + bufor (3 h przy `flight`, 0 przy `car`, N6)**, a jeśli próg przekracza 22:00 – brak aktywności w dniu 1; teksty bez URL-i, znaczników i znaków sterujących, w długościach: `title` ≤ 80, `name` ≤ 100, `locality` ≤ 80, `description` ≤ 300; język odpowiedzi zgodny z `planLanguage`. Pola `startTime`, `name`, `locality` służą aplikacji do budowy linku Maps (`name, locality, destination`); model nie zwraca URL-i ani współrzędnych (T5).

### Błędy
| `details.code` | Kod HttpsError | Znaczenie | Dodatkowe `details` |
|---|---|---|---|
| `unauthenticated` | `unauthenticated` | brak/niepoprawny token lub dostawca ≠ google.com | – |
| `app_check_failed` | `failed-precondition` | brak/niepoprawny token App Check | – |
| `invalid_argument` | `invalid-argument` | błąd schematu/zbioru/długości | `field` (ścieżka pola, bez wartości) |
| `unsupported_version` | `failed-precondition` | niezgodna `apiVersion` | `minVersion` |
| `consent_required` | `failed-precondition` | brak aktualnej akceptacji polityki lub zgody AI (ADR-0012) | `consentType` ∈ {`privacy_policy`, `ai_processing`} |
| `limit_exceeded` | `resource-exhausted` | limit konta wyczerpany | `limit`, `resetAt` |
| `ai_unavailable` | `unavailable` | model niedostępny, limit globalny, `aiEnabled=false`, przekroczony czas | `retryAfterSec` (opcjonalnie) |
| `ai_invalid_response` | `internal` | odpowiedź niepoprawna po 2 próbach | – |
| `test_data_only` | `permission-denied` | `ALLOW_REAL_DATA=false`, a konto/żądanie nie testowe; także fail-closed w prod przy `allowRealData=true` i `ENFORCE_APP_CHECK=false` (ADR-0002, Aneks A pkt 3) | – |
| `internal` | `internal` | nieoczekiwany błąd | – |

Slot limitu jest zwracany przy `ai_unavailable` i `ai_invalid_response`. **Nie** jest zwracany po anulowaniu przez użytkownika, jeśli wywołanie modelu już ruszyło (Q12). Callable nie ma przerwania żądania: anulowanie = porzucenie wyniku po stronie aplikacji (odpowiedź z tym `requestId` jest odrzucana, nic nie zapisujemy); żądanie na serwerze kończy się normalnie (ADR-0011). Timeout klienta: 120 s.

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
- Brak automatycznych ponowień `generatePlan` w aplikacji (każde ponowienie zużywa slot limitu); ponowienie wyłącznie z decyzji użytkownika. `recordConsent` i `deleteAccount` są idempotentne i mogą być ponawiane automatycznie.

## 7. Historia zmian
- **v0.4.1 (2026-11-20, mobile-dev, TAM-58/59/60 – doprecyzowanie bez zmiany pól i kodów):** „po oczyszczeniu” dla pól tekstowych = NFC + odrzucenie `Cc`/`Cf`/`Zl`/`Zp` (SEC-21); lista dozwolonych wzorców kodu i klasy błędu w logach (SEC-19). Granice limitów z `config/runtime` (SEC-22) nie zmieniają kontraktu.
- **v0.4 (2026-11-16, ADR-0012 zatwierdzony przez właściciela; S17, SEC-26):** `generatePlan` egzekwuje aktualną akceptację `privacy_policy` (`consent_required`, `consentType=privacy_policy`); porównanie wersji „≥ bieżąca" dla obu zgód; wzorzec i lista znanych wersji w `recordConsent`; wysyłka oczekujących zgód przed `generatePlan`. Implementacja – mobile-dev (P3-04/P3-05).
- **v0.3 (2026-11-16, ADR-0011 zatwierdzony przez właściciela):** data przylotu „dziś − 2 dni" (Warsaw); `deleteAccount` bez wymogu dostawcy i bez `unsupported_version`; `dev` tylko dane testowe (SEC-24); mapowanie błędów klienta i pętli `consent_required`; `testData` ze stałej kompilacji; anulowanie = porzucenie wyniku; `config/runtime` niedostępne dla klienta. Implementacja w `backend/functions` – zadanie mobile-dev (`docs/architecture/przeglad-ekranow-p3-14c.md` pkt 5).
- **v0.2 (2026-11-15):** zatwierdzona na G2 (ADR-0002 z Aneksem A).
