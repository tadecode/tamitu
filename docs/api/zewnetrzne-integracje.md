# Kontrakty zewnętrzne i wewnętrzne – Tamitu (MVP)

Stan: 2026-11-15, wersja 0.2 (po G2), autor: architect. Kontrakt pośrednika: `posrednik-api.md`.

## 1. Google Maps (link; ADR-0007, lokalizacja wg ADR-0017)
Brak API i klucza. Adres otwierany przez `url_launcher`:

```
https://www.google.com/maps/dir/?api=1&destination=<destination>&travelmode=<mode>[&origin=<origin>]
```
| Parametr | Źródło | Zasady |
|---|---|---|
| `destination` | `"{name}, {locality}, {trip.destination}"` z planu | kodowanie procentowe; tylko tekst z planu (nie URL od modelu); zawsze z nazwą i miejscowością, nigdy same współrzędne (TAM-24) |
| `origin` | start „Moja lokalizacja”: **pominięty** (Mapy ustawiają „Twoja lokalizacja”); „Nocleg”: `"{lodging}, {trip.destination}"`; „Poprzedni punkt”: `"{name}, {locality}, {trip.destination}"` poprzedniego punktu | tylko tekst z planu; nigdy współrzędne; bez pustego `origin=` (ADR-0017) |
| `travelmode` | `driving` (auto), `transit` (komunikacja), `walking` (pieszo) | wybór użytkownika, niezapisywany |
Obowiązuje wariant C (ADR-0017, Q1 = C, 2026-11-25): aplikacja nie odczytuje pozycji. Budowa przez `Uri.https(...)`. Otwieranie: wyłącznie `LaunchMode.externalApplication`; test kodowania procentowego (`&`, `#`, `|`, `%`, nawiasy). Ograniczenie: długość URL < 2 048 znaków (obcinanie opisu nie dotyczy, bo w URL tylko nazwy). Testy: brak `origin` przy „Moja lokalizacja”, `origin` jako tekst przy noclegu i poprzednim punkcie, `destination`, każdy `travelmode` (US-007). Google otrzymuje w linku tylko cel, tryb i ewentualnie tekst startu (D8), bez pozycji telefonu.

## 2. Firebase Auth / Google Sign-In (ADR-0004)
- Klient: `google_sign_in` → token Google → `FirebaseAuth.signInWithCredential(GoogleAuthProvider.credential(idToken))`.
- Konfiguracja na środowisko: klient OAuth „web" (serverClientId), odciski SHA-1/SHA-256 (debug, klucz uploadu, klucz podpisu Google Play), plik konfiguracyjny Firebase dla flavoru.
- Serwer: weryfikacja tokenu ID przez callable; używane pola tokenu: `uid`, `firebase.sign_in_provider`, `auth_time`. E-mail i nazwa z tokenu nie są odczytywane ani logowane. Funkcje zapisujące dodatkowo sprawdzają istnienie użytkownika (`checkRevoked`, ADR-0002 Aneks A pkt 1); wymaga uprawnienia odczytu użytkownika Auth dla `fn-ai-plan` i `fn-consent`.
- Logowanie SDK: w konfiguracji logowania `onCall` zakaz logowania `data.*` żądań i treści wyjątków (przegląd Security, pkt 9; ADR-0002 Aneks A pkt 2).

## 3. Vertex AI (ADR-0001, wywoływane tylko z `generatePlan`)
- Autoryzacja: konto usługi `fn-ai-plan` (ADR-0014; domyślne poświadczenia aplikacji, bez klucza), rola `roles/aiplatform.user`.
- Punkt końcowy regionalny `europe-west4` albo multi-region `eu` (stała środowiskowa; start odmawiany przy innej wartości; przetwarzanie ML w granicach UE, bez gwarancji NL – ADR-0001 Aneks B); model z konfiguracji `AI_MODEL_ID` (start od klasy Flash, Q4).
- Żądanie: `systemInstruction` (angielski), `contents` (dane użytkownika jako JSON), `generationConfig`: `responseMimeType=application/json`, `responseSchema` (struktura jak w `generate-plan.response.schema.json`, tylko `language` i `days`), `temperature≈0.7`, `maxOutputTokens=10000`, thinking wyłączone/minimalne; brak `tools`, brak groundingu.
- Zakaz: wysyłania pól spoza kontraktu żądania (UID, e-mail, lokalizacja, numer lotu).
- Timeout próby 45 s; maks. 2 próby; błędy 429/5xx → `ai_unavailable`.

## 4. Firestore (wewnętrzne)
Reguły `deny all` (`firestore.rules`): `rules_version = '2'; service cloud.firestore { match /databases/{db}/documents { match /{document=**} { allow read, write: if false; } } }`. Dostęp wyłącznie Admin SDK. Struktura kolekcji: `docs/data/model-danych.md`.

Konta usług (ADR-0002, Aneks A pkt 6; ADR-0014): `fn-ai-plan`, `fn-consent`, `fn-account`, `fn-budget` – po jednym na funkcję.

## 5. Budżety (wewnętrzne)
Budżet GCP → temat Pub/Sub → `budgetGuard`. Komunikat zawiera kwoty i nazwę budżetu, bez danych użytkowników.

## 6. Kontrakt aplikacja ↔ system Android
| Obszar | Zasada |
|---|---|
| Manifest | tylko `INTERNET` (ADR-0017: brak uprawnień lokalizacji); brak innych uprawnień; `allowBackup=false`; `dataExtractionRules`; `usesCleartextTraffic=false`; `<queries>` dla `https` VIEW |
| Test CI | porównanie listy uprawnień zmergowanego manifestu z listą dozwoloną (`{INTERNET}`); brak `LOCATION` w manifeście; `<queries>` zawiera `VIEW` + `https`; brak `geolocator` w `pubspec.lock` |
| Sieć | tylko przez SDK Firebase (TLS); brak własnego klienta HTTP |
