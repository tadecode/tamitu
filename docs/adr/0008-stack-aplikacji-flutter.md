# ADR-0008: Stos technologiczny aplikacji i repozytorium

- Status: zatwierdzony (bramka G2, 2026-11-15; zatwierdził właściciel produktu)
- Data: 2026-11-15
- Autor (rola): architect
- Zadanie: P2-06 (vision: Flutter, Android; T16)
- Odpowiedzi właściciela uwzględnione: Q7 (SQLCipher w stosie), Q8 (minSdk 26), Q1 (`geolocator` pozostaje w stosie do decyzji po teście C). Uwagi Security 8-1..8-5: „Aneks A" na końcu.

## Kontekst
Narzucone: Flutter, Android, pakiet `pl.tadecode.tamitu`, Firebase/Google Cloud w UE. Wymagana prostota, minimalna liczba zależności (T16), testowalność, brak SDK analityki/reklam w MVP (D12).

## Rozważane opcje
- **Stan i nawigacja:** (1) Riverpod + go_router – testowalne DI, popularne, mało boilerplate'u; (2) Bloc – więcej kodu; (3) Provider/`setState` – za mało struktury. Wybór: **1**.
- **Backend:** (1) TypeScript na Node.js LTS (Firebase Functions 2. gen., najlepsze wsparcie emulatora i Admin SDK); (2) Python – wspierany, ale mniejsze wsparcie narzędzi Firebase. Wybór: **1**.
- **Układ repozytorium:** (1) `app/` (Flutter) + `backend/` (Firebase) w jednym repo; (2) dwa repozytoria – nadmiar. Wybór: **1**.

## Decyzja
**Aplikacja (`app/`):** Flutter stable (wersja przypięta w `pubspec`/CI przy P3-01), Dart; flavory `dev` i `prod`; architektura „feature-first" z warstwami `domain`/`data`/`presentation` (opis: `docs/architecture/overview.md`).
Dozwolone pakiety MVP (każdy dodatkowy = uzasadnienie w zadaniu, przegląd uprawnień i licencji, SEC-08):

| Cel | Pakiet | Uwagi (uprawnienia/dane) |
|---|---|---|
| Firebase | `firebase_core`, `firebase_auth`, `firebase_app_check`, `cloud_functions` | Bez Analytics/Crashlytics/Messaging |
| Logowanie Google | `google_sign_in` | ADR-0004 |
| Stan, nawigacja | `flutter_riverpod`, `go_router` | |
| Baza lokalna | `drift` + SQLCipher (`sqlcipher_flutter_libs` lub aktualny odpowiednik wg dokumentacji Drift) | ADR-0005 |
| Sekrety lokalne | `flutter_secure_storage` | Klucz bazy |
| Ustawienia | `shared_preferences` | Tylko dane niewrażliwe |
| Lokalizacja | `geolocator` | ADR-0007 |
| Linki | `url_launcher` | |
| i18n | `flutter_localizations`, `intl` | ADR-0006 |
| Identyfikatory | `uuid` | `requestId`, `tripId` |
| Testy | `flutter_test`, `integration_test`, `mocktail` | |

Zakazane w MVP: SDK reklamowe, analityczne, crash-reporting, `firebase_messaging`, mapy, własny klient HTTP (cały ruch sieciowy przez SDK Firebase, TLS wymuszony), pakiety dodające uprawnienia ponad ADR-0007.

**Backend (`backend/`):** `firebase.json`, `firestore.rules`, `firestore.indexes.json`, `functions/` (TypeScript, Node.js LTS, `firebase-admin`, `firebase-functions` v2, SDK Vertex AI/Gen AI w trybie Vertex, walidacja schematów np. `zod`; testy `vitest` + emulator Firebase). Konfiguracja środowisk przez aliasy projektów `dev`/`prod`.

**Jakość i bezpieczeństwo w CI (prośby do Stewarda):** `flutter analyze`, `flutter test`, testy funkcji i reguł w emulatorze, test listy uprawnień w manifeście, test kompletności tłumaczeń, skan sekretów (SEC-01), audyt zależności (SEC-08). Testy z prawdziwym modelem (ewaluacja) – ręcznie lub nocnie, z limitem liczby wywołań (`docs/architecture/costs.md`), na danych syntetycznych.

## Konsekwencje
**Pozytywne:** mała liczba zależności, spójny język po stronie serwera i testów emulatora, jasny podział repo.
**Negatywne:** dwa ekosystemy (Dart, TypeScript) – CI i narzędzia w obu; wersje pakietów wymagają utrzymania (T16).
**Koszty:** brak kosztów zmiennych; CI w darmowych minutach (poza zakresem ADR).
**Poza MVP:** reklamy (AdMob + CMP) i płatności (Google Play Billing) – każde wymaga osobnego ADR i analizy Security przed rozpoczęciem (R14, F1, F2); nie są tu decydowane.

## Aneks A (2026-11-15, przy zatwierdzeniu)
1. **Lockfile i powtarzalność (8-1, T16).** Wersje przypięte: `pubspec.lock` i `package-lock.json` w repozytorium; CI używa `npm ci` i `flutter pub get` zgodnie z lockfile (zadania P3-01, P3-02).
2. **Biblioteka SQLCipher (8-2).** Wybór konkretnego pakietu (`sqlcipher_flutter_libs` lub odpowiednik) w P3-06 wg kryteriów: aktualność, aktywne wydania, brak znanych luk, licencja.
3. **`geolocator` (8-3)** zależy od wyniku testu C (ADR-0007); przy zatwierdzeniu C usunąć z listy.
4. **Backend (8-4, 8-5).** Zależności backendu w audycie (SEC-08); lint zakazujący `console.log`; test CI na brak zależności `http`/`dio` i na `usesCleartextTraffic=false` (SEC-05).
