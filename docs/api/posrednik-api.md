# Kontrakt API pośrednika (Cloud Functions callable)

Stan: 2026-11-16, wersja 0.3 (v0.2 zatwierdzona na G2 wraz z ADR-0002 i jego Aneksem A; zmiany v0.3 z ADR-0011, zatwierdzonego przez właściciela 2026-11-16 – lista w pkt 7), autor: architect. ADR-0002, ADR-0011. Schematy: `schemas/generate-plan.request.schema.json`, `schemas/generate-plan.response.schema.json`.
Region: `europe-west4`. Wywołanie przez SDK `cloud_functions` (callable): token ID Firebase i token App Check dołączane automatycznie. Format: JSON, UTF-8, `Content-Type: application/json`.

## 1. Zasady wspólne
- **Żądanie nie zawiera:** UID, e-maila, nazwy konta, lokalizacji (współrzędnych), numeru lotu, tokenów, danych rozliczeniowych. UID serwer bierze wyłącznie z zweryfikowanego tokenu.
- **Błędy:** serwer zwraca `HttpsError` z kodem technicznym i `details.code` (kod aplikacyjny z tabeli w pkt 6). Brak tekstów dla użytkownika i brak szczegółów technicznych (US-011); tłumaczenia w aplikacji.
- **Wersjonowanie:** pole `apiVersion` (liczba całkowita, obecnie 1) w żądaniu; niezgodna wersja → `unsupported_version` (z wyjątkiem `deleteAccount`, pkt 4).
- **Środowisko `dev`:** wyłącznie dane testowe – start funkcji z `ENVIRONMENT=dev` i `ALLOW_REAL_DATA=true` kończy się błędem inicjalizacji; w `dev` `config/runtime.allowRealData` jest ignorowane (ADR-0011 pkt 5, SEC-24).
- **`config/runtime`** (np. `policyVersionCurrent`) nie jest udostępniane klientowi; wersja polityki po stronie aplikacji to stała w kodzie (ADR-0011 pkt 1).
- **Czas:** daty `YYYY-MM-DD`, godziny `HH:MM` (24 h), strefa lokalna miejsca docelowego, bez przeliczania stref.
- **Logowanie:** zakaz logowania treści żądań i odpowiedzi; wyjątki logowane wyłącznie jako kod i klasa błędu, nigdy `error.message`/stos (ADR-0002, Aneks A pkt 2).
- **Istnienie użytkownika:** `generatePlan` i `recordConsent` odrzucają token użytkownika usuniętego lub z unieważnionymi tokenami (`unauthenticated`), bez żadnego zapisu (ADR-0002, Aneks A pkt 1).
- **Doba limitu:** dzień kalendarzowy w strefie `Europe/Warsaw` (Q5); `resetAt` = najbliższa północ tej strefy, w UTC.
- Rozmiar żądania ≤ 4 KB; przekroczenie → `invalid_argument`.

## 2. `generatePlan`
Wymaga: token ID (`sign_in_provider = google.com`), App Check, aktualnej zgody `ai_processing`, `aiEnabled = true`, wolnego limitu.

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
Gwarancje po walidacji serwerowej: liczba dni = `trip.days`; `dayNumber` kolejne od 1; punktów w dniu: `relaxed` 2–3, `moderate` 4–5, `intense` 6–7 (dzień 1 może mieć mniej, także 0, wg bufora); godziny rosnące w dniu; **dzień 1: wszystkie `startTime` ≥ przylot + bufor (3 h przy `flight`, 0 przy `car`, N6)**, a jeśli próg przekracza 22:00 – brak aktywności w dniu 1; teksty bez URL-i, znaczników i znaków sterujących, w długościach: `title` ≤ 80, `name` ≤ 100, `locality` ≤ 80, `description` ≤ 300; język odpowiedzi zgodny z `planLanguage`. Pola `startTime`, `name`, `locality` służą aplikacji do budowy linku Maps (`name, locality, destination`); model nie zwraca URL-i ani współrzędnych (T5).

### Błędy
| `details.code` | Kod HttpsError | Znaczenie | Dodatkowe `details` |
|---|---|---|---|
| `unauthenticated` | `unauthenticated` | brak/niepoprawny token lub dostawca ≠ google.com | – |
| `app_check_failed` | `failed-precondition` | brak/niepoprawny token App Check | – |
| `invalid_argument` | `invalid-argument` | błąd schematu/zbioru/długości | `field` (ścieżka pola, bez wartości) |
| `unsupported_version` | `failed-precondition` | niezgodna `apiVersion` | `minVersion` |
| `consent_required` | `failed-precondition` | brak aktualnej zgody AI | `consentType` |
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
Odpowiedź 200: `{ "consentId": "...", "receivedAt": "2026-11-15T10:12:04Z" }`. Idempotentne po `consentId` (powtórne wysłanie nie tworzy duplikatu). Walidacja: `type` ∈ {`privacy_policy`, `ai_processing`}, `lang` ∈ {`pl`, `en`}, `policyVersion` ≤ 40 znaków, `clientAt` w przedziale ±24 h od czasu serwera (w przeciwnym razie zapisany czas serwera, pole `clientAt` oznaczone jako skorygowane). Błędy: `unauthenticated` (także użytkownik usunięty), `app_check_failed`, `invalid_argument`, `internal`. Wycofanie zgody (`granted=false`) aplikacja zapisuje przed potwierdzeniem w UI (ADR-0002, Aneks A pkt 4).

## 4. `deleteAccount`
Wymaga: token ID z `auth_time` ≤ 5 min, App Check. **Nie wymaga** `sign_in_provider = google.com` (usuwa wyłącznie konto z tokenu) i **nie zwraca** `unsupported_version` – przyjmuje każdą `apiVersion` ≥ 1, aby prawo do usunięcia nie zależało od wersji aplikacji ani dostawcy (ADR-0011 pkt 4). Aplikacja przed wywołaniem zawsze wykonuje ponowne uwierzytelnienie Google (ADR-0011 pkt 8). Żądanie: `{ "apiVersion": 1 }`. Odpowiedź 200: `{ "deleted": true }`. Kolejność: dane Firestore → użytkownik Auth → kontrolne powtórne usunięcie Firestore. Dowód zgód usuwany z kontem (Q9). Błędy: `reauth_required` (`failed-precondition`), `unauthenticated`, `app_check_failed`, `internal`. Idempotentne.

## 5. `budgetGuard` (wewnętrzna)
Wyzwalacz Pub/Sub z powiadomień budżetowych; brak publicznego punktu wejścia. Przy `costAmount ≥ budgetAmount` w projekcie prod ustawia `config/runtime.aiEnabled=false`. Bez danych użytkowników; konto usługi `fn-budget` bez dostępu do Auth.

## 6. Konwencje dla aplikacji
- Aplikacja mapuje `details.code` na klucze tłumaczeń; nieznany kod → `internal`.
- Błędy klienta (ADR-0011 pkt 2): `unavailable` **bez** `details.code` (błąd transportu) oraz `network-request-failed` (Auth/logowanie) → „brak sieci"; `deadline-exceeded` → „przekroczony czas". Brak sieci wykrywany po próbie – aplikacja nie używa detektora łączności ani `ACCESS_NETWORK_STATE`.
- `consent_required`, gdy aplikacja ma już zsynchronizowany rekord `ai_processing` w wersji wbudowanej w aplikację → komunikat „Zaktualizuj aplikację" (bez ponownego EK-06; ADR-0011 pkt 7). Serwer podnosi `aiConsentVersionCurrent` dopiero po wydaniu aplikacji z nowym tekstem zgody.
- `limit_exceeded.resetAt` jest w UTC; aplikacja formatuje w czasie lokalnym (US-011).
- Brak automatycznych ponowień `generatePlan` w aplikacji (każde ponowienie zużywa slot limitu); ponowienie wyłącznie z decyzji użytkownika. `recordConsent` i `deleteAccount` są idempotentne i mogą być ponawiane automatycznie.

## 7. Historia zmian
- **v0.3 (2026-11-16, ADR-0011 zatwierdzony przez właściciela):** data przylotu „dziś − 2 dni" (Warsaw); `deleteAccount` bez wymogu dostawcy i bez `unsupported_version`; `dev` tylko dane testowe (SEC-24); mapowanie błędów klienta i pętli `consent_required`; `testData` ze stałej kompilacji; anulowanie = porzucenie wyniku; `config/runtime` niedostępne dla klienta. Implementacja w `backend/functions` – zadanie mobile-dev (`docs/architecture/przeglad-ekranow-p3-14c.md` pkt 5).
- **v0.2 (2026-11-15):** zatwierdzona na G2 (ADR-0002 z Aneksem A).

## 8. Projekt zmian v0.4 (ADR-0012, status: proponowany – obowiązuje po zatwierdzeniu przez właściciela)
Źródło: S17 / SEC-26 (B-1 z przeglądu security ekranów). Do czasu zatwierdzenia obowiązują pkt 1–7.

| # | Miejsce | Zmiana |
|---|---|---|
| 8.1 | `generatePlan`, wymagania | dodatkowo: ostatni rekord `privacy_policy` w wersji ≥ `config/runtime.policyVersionCurrent`; inaczej `consent_required` z `details.consentType = "privacy_policy"` (sprawdzane przed zgodą AI i przed rezerwacją limitu) |
| 8.2 | `generatePlan`, zgoda AI | „aktualna zgoda" = ostatni rekord `ai_processing` z `granted = true` i wersją ≥ `aiConsentVersionCurrent` (porównanie numeru, nie równość) |
| 8.3 | `recordConsent`, `policyVersion` | wzorzec `^(privacy|ai-consent)-v[1-9]\d{0,3}$`, typ zgodny z prefiksem, wersja z listy znanych w kodzie serwera; inaczej `invalid_argument` (`field: policyVersion`) |
| 8.4 | `consent_required.details` | `consentType` ∈ {`privacy_policy`, `ai_processing`}; aplikacja: `privacy_policy` → EK-03, `ai_processing` → EK-06; przy zsynchronizowanym rekordzie w wersji aplikacji → „Zaktualizuj aplikację" |
| 8.5 | pkt 6, konwencje | przed `generatePlan` aplikacja wysyła oczekujące rekordy zgód (`synced = 0`) |
