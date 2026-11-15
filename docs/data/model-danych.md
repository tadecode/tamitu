# Model danych – Tamitu (MVP)

Stan: 2026-11-15, wersja 0.2 (po G2; ADR zatwierdzone), autor: architect (przegląd Security: `docs/security/przeglad-adr.md`). Powiązane: ADR-0005, `docs/security/personal-data-register.md` (kody D1..D16), `przechowywanie-i-retencja.md`, `docs/api/posrednik-api.md`.
Zasada: dane podróży tylko lokalnie; po stronie chmury wyłącznie zgody (D3), licznik (D10), konfiguracja (bez danych osobowych) i konto Auth (D1).

## 1. Wartości wyliczeniowe (wspólne dla aplikacji i serwera)
Identyfikatory stabilne, angielskie; etykiety w ARB (ADR-0006). **Wartości domyślne i zbiory poniżej zatwierdzone przez właściciela (Q6, 2026-11-15; N11 i S13 zamknięte): preferencje opcjonalne, zainteresowania wyłącznie z listy (bez wolnego tekstu).**

| Pole | Wartości | Domyślnie | Uwagi |
|---|---|---|---|
| `arrivalMode` | `flight`, `car` | – (wymagane) | |
| `interests[]` | `monuments_history`, `architecture`, `art_museums`, `nature_parks`, `beaches_water`, `local_food`, `active_sport`, `family_attractions`, `shopping`, `nightlife`, `relaxation` | pusta lista (ogólne zwiedzanie) | 0–5 pozycji, bez duplikatów; lista bez pozycji ujawniających religię, zdrowie, orientację (SEC-11, S13) |
| `budget` | `low`, `medium`, `high` | `medium` | Tylko poziomy, bez kwot |
| `pace` | `relaxed`, `moderate`, `intense` | `moderate` | Punktów dziennie: 2–3, 4–5, 6–7 |
| `partySize` | liczba całkowita 1–10 | 2 | Zatwierdzone (Q6) |
| `planLanguage` | `pl`, `en` | język UI | ADR-0006 |
| `days` | 1–14 | – (wymagane) | N2 |
| `travelMode` (link) | `driving`, `transit`, `walking` | wybór użytkownika | nie zapisywane |

Pola tekstowe (po oczyszczeniu: normalizacja Unicode NFC, usunięcie znaków sterujących i skrajnych spacji, zwinięcie białych znaków; dozwolone litery, cyfry, spacja i znaki `, . - ' ( ) / &`): `destination` ≤ 80 zn., `lodging` ≤ 80 zn. (etykieta/pomoc w UI, bez blokady: „Nazwa obiektu lub dzielnica (nie wpisuj pełnego adresu prywatnego)" – wymaganie dla Analityka/UI, przegląd Security 1-3; D4), `airport` ≤ 60 zn., `flightNumber` ≤ 10 zn. (tylko lokalnie).

## 2. Model lokalny (urządzenie)
### 2.1 Magazyny
| Magazyn | Zawartość | Szyfrowanie | Kopia zapasowa |
|---|---|---|---|
| Baza konta `tamitu_<sha256(uid)[0..16]>.db` (Drift + SQLCipher) | plany, dane podróży, preferencje, zgody lokalne | tak, AES-256, klucz w Keystore | wyłączona (`allowBackup=false`, `dataExtractionRules`) |
| `flutter_secure_storage` | klucz bazy; znacznik „usuwanie w toku" (skrót UID) | Keystore | wyłączona |
| `shared_preferences` | `uiLanguage` (`pl`/`en`/system), tymczasowa zgoda na politykę przed logowaniem (`version`, `lang`, `acceptedAt`), flagi UI | nie (brak danych podróży) | wyłączona |
| Firebase SDK (Auth) | token odświeżający, stan sesji (D2) | wg SDK | wyłączona |
| **Nigdzie** | lokalizacja, współrzędne, URL trasy ze współrzędnymi, prompty/odpowiedzi surowe | – | – |

### 2.2 Tabele bazy konta (schemat v1)
```
trips
  id              TEXT PK            -- uuid v4
  created_at      INTEGER NOT NULL   -- epoch ms UTC
  destination     TEXT NOT NULL
  lodging         TEXT NOT NULL
  days_count      INTEGER NOT NULL   -- 1..14
  arrival_mode    TEXT NOT NULL      -- flight | car
  arrival_date    TEXT NOT NULL      -- YYYY-MM-DD (lokalnie w miejscu docelowym)
  arrival_time    TEXT NOT NULL      -- HH:MM
  airport         TEXT NULL          -- wymagane gdy flight
  flight_number   TEXT NULL          -- tylko lokalnie, nigdy do AI
  interests       TEXT NOT NULL      -- JSON: lista identyfikatorów
  budget          TEXT NOT NULL
  pace            TEXT NOT NULL
  party_size      INTEGER NOT NULL
  plan_language   TEXT NOT NULL      -- pl | en
  prompt_version  TEXT NOT NULL      -- z odpowiedzi serwera (diagnostyka, nie dane osobowe)

plan_days
  trip_id     TEXT FK -> trips(id) ON DELETE CASCADE
  day_number  INTEGER NOT NULL
  title       TEXT NOT NULL
  PRIMARY KEY (trip_id, day_number)

plan_items
  id          INTEGER PK AUTOINCREMENT
  trip_id     TEXT NOT NULL
  day_number  INTEGER NOT NULL
  position    INTEGER NOT NULL
  name        TEXT NOT NULL
  locality    TEXT NOT NULL
  description TEXT NOT NULL
  start_time  TEXT NOT NULL          -- HH:MM
  FOREIGN KEY (trip_id, day_number) REFERENCES plan_days ON DELETE CASCADE
  UNIQUE (trip_id, day_number, position)

consents_local
  id             TEXT PK             -- uuid, ten sam co na serwerze (id rekordu)
  type           TEXT NOT NULL       -- privacy_policy | ai_processing
  granted        INTEGER NOT NULL    -- 0/1
  policy_version TEXT NOT NULL
  lang           TEXT NOT NULL
  client_at      INTEGER NOT NULL
  synced         INTEGER NOT NULL DEFAULT 0

schema_meta(version INTEGER)
```
Zapis planu: jedna transakcja (trip + dni + punkty); częściowy plan nie jest zapisywany (US-005). Usunięcie planu: `DELETE trips` (kaskada, US-009). Lista: `ORDER BY created_at DESC`. Migracje wersjonowane i testowane.

Mapowanie na rejestr: D4/D5 → `trips` (cel, daty, nocleg, lot), D9 → `plan_*`, D15 → `interests`, `budget`, `pace`, `party_size`, D16 → `plan_language`, D3 (lokalnie) → `consents_local`.

## 3. Model serwerowy (Firestore, region `europe-west4`, reguły `deny all`)
Wszystkie zapisy i odczyty wyłącznie z funkcji (Admin SDK); klient nie ma dostępu.

| Ścieżka | Pola | Rejestr | Retencja |
|---|---|---|---|
| `users/{uid}/consents/{consentId}` | `type` (`privacy_policy`\|`ai_processing`), `granted` (bool), `policyVersion` (string), `lang` (`pl`\|`en`), `clientAt` (timestamp), `receivedAt` (timestamp serwera) | D3 | do usunięcia konta; dowód usuwany z kontem (Q9; [PRAWNIK] do potwierdzenia, ewentualna zmiana nowym ADR). Brak TTL – tworzenie dokumentów dla nieistniejącego UID blokuje sprawdzenie istnienia użytkownika (ADR-0002, Aneks A pkt 1) |
| `usage/{uid}` | `day` (`YYYY-MM-DD`, Europe/Warsaw), `count` (int), `updatedAt` (timestamp, polityka TTL 30 dni) | D10 | jeden dokument na konto, nadpisywany co dobę; TTL 30 dni od ostatniej aktualizacji; kasowany z kontem |
| `usage_global/{day}` | `count`, `expireAt` (TTL 7 dni) | brak danych osobowych | 7 dni |
| `config/runtime` | `aiEnabled`, `allowRealData` (domyślnie `false`; zmienia wyłącznie właściciel wg procedury z Aneksu A ADR-0001), `perUserDailyLimit` (5), `globalDailyLimit` (50), `testUids[]` (UID właściciela do czasu SEC-15; dostęp tylko właściciel z 2FA), `policyVersionCurrent`, `aiConsentVersionCurrent` | brak danych osobowych (UID testowych kont właściciela) | stała |

Indeksy: `consents` – zapytanie „ostatnia zgoda danego typu": indeks złożony (`type` rosnąco, `receivedAt` malejąco) w `firestore.indexes.json`.

Firebase Auth (D1): rekord użytkownika (UID, e-mail, nazwa, dostawca) – zarządzany przez Google; aplikacja używa tylko UID.

Cloud Logging (D11): wyłącznie metadane (patrz ADR-0002), kubełek UE, 30 dni, `uidHash` = HMAC-SHA256(UID; pieprz z Secret Managera). Wyjątki logowane wyłącznie jako kod i klasa błędu (ADR-0002, Aneks A pkt 2). `uidHash` to pseudonimizacja, nie anonimizacja (2-3).

Vertex AI: brak zapisu po naszej stronie; warunki po stronie dostawcy – ADR-0001, SEC-15.

## 4. Przepływ danych a rejestr (podsumowanie)
| Dana | Urządzenie | Pośrednik (pamięć) | Firestore | Model AI | Logi | Google Maps |
|---|---|---|---|---|---|---|
| UID | sesja SDK, skrót w nazwie pliku | tak (z tokenu) | zgody, licznik | **nie** | tylko skrót | nie |
| E-mail, nazwa | nie zapisujemy | nie | nie | **nie** | nie | nie |
| Cel, daty, nocleg, lotnisko, godzina przylotu | baza | tak | nie | **tak** | nie | cel/nocleg jako tekst w linku |
| Preferencje, język planu | baza | tak | nie | **tak** | nie | nie |
| Numer lotu | baza (opcjonalny) | **nie** | nie | **nie** | nie | nie |
| Lokalizacja bieżąca | **nie zapisywana** | nie | nie | nie | nie | tak (`origin`, opcja A ADR-0007 – zatwierdzona, Q1; test C w fazie 3) |
| Zgody | baza + prefs (przed logowaniem) | tak | tak | nie | nie | nie |
| Plan wygenerowany | baza | tak (w odpowiedzi) | nie | tak (wynik) | nie | nazwy w linku |
