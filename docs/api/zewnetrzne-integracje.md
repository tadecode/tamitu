# Kontrakty zewnętrzne i wewnętrzne – Tamitu (MVP)

Stan: 2026-11-15, wersja 0.2 (po G2), autor: architect. Kontrakt pośrednika: `posrednik-api.md`.

## 1. Google Maps (link; ADR-0007)
Brak API i klucza. Adres otwierany przez `url_launcher`:

```
https://www.google.com/maps/dir/?api=1&origin=<origin>&destination=<destination>&travelmode=<mode>
```
| Parametr | Źródło | Zasady |
|---|---|---|
| `destination` | `"{name}, {locality}, {trip.destination}"` z planu | kodowanie procentowe; tylko tekst z planu (nie URL od modelu) |
| `origin` | (a) `"{lodging}, {trip.destination}"`; (b) tekst poprzedniego punktu dnia; (c) `lat,lng` z jednorazowego odczytu (opcja A) | (c) tylko w pamięci, bez zapisu; (opcja C ADR-0007: parametr pomijany) |
| `travelmode` | `driving` (auto), `transit` (komunikacja), `walking` (pieszo) | wybór użytkownika, niezapisywany |
Wariant `origin` (c) obowiązuje (Q1 = A); wariant C (bez `origin`) jest testowany w fazie 3 i wejdzie tylko nowym ADR. Otwieranie: wyłącznie `LaunchMode.externalApplication`; test kodowania procentowego (`&`, `#`, `|`, `%`, nawiasy). Ograniczenie: długość URL < 2 048 znaków (obcinanie opisu nie dotyczy, bo w URL tylko nazwy). Testy: parametry `origin`, `destination`, `travelmode` (US-007); brak współrzędnych w jakimkolwiek zapisie.

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
| Manifest | `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` (opcja A); brak innych uprawnień; `allowBackup=false`; `dataExtractionRules`; `usesCleartextTraffic=false`; `<queries>` dla `https` VIEW |
| Test CI | porównanie listy uprawnień zmergowanego manifestu z listą dozwoloną |
| Sieć | tylko przez SDK Firebase (TLS); brak własnego klienta HTTP |
