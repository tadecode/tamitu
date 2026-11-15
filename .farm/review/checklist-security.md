# Checklista: bezpieczeństwo i prywatność (aplikacja mobilna)

Źródła: OWASP MASVS/MASTG (zakres), RODO. Wersja 0.1. Zmienia ją właściciel
(tryb `FARM_MAINTENANCE=1`), recenzent tylko proponuje w `docs/reviews/lessons-proposed.md`.

## Sekrety i konfiguracja
- Klucze API, tokeny, hasła, pliki `google-services.json` z danymi poufnymi,
  klucze podpisywania w kodzie, logach, testach lub fixture'ach.
- Klucze po stronie klienta, które powinny być po stronie serwera
  (klucze modeli AI, klucze z limitem płatnym) - klient nie wywołuje płatnych API bez pośrednika/limitów.
- Tryb debug w buildach wydaniowych, wyłączona weryfikacja certyfikatów.

## Dane i prywatność (RODO)
- Nowe dane osobowe bez wpisu w `docs/security/personal-data-register.md`.
- Wysyłanie do modelu AI danych osobowych lub dokładnej lokalizacji bez minimalizacji/anonimizacji.
- Zgody (reklamy, identyfikatory reklamowe, lokalizacja) respektowane przed przetwarzaniem.
- Logi, analityka i raporty błędów bez danych osobowych.
- Możliwość usunięcia konta i danych.

## Uwierzytelnianie i sesja
- Tokeny w bezpiecznym magazynie (Keystore/SecureStorage), nie w SharedPreferences ani plikach.
- Obsługa wygaśnięcia i odwołania tokenów; brak własnego przechowywania haseł (zasada projektu).
- Reguły dostępu Firebase (Firestore/Storage) per użytkownik, brak reguł „allow all".

## Sieć
- Tylko HTTPS; brak `usesCleartextTraffic`, brak akceptowania wszystkich certyfikatów.
- Walidacja i limity danych z sieci; obsługa błędów bez ujawniania szczegółów.

## Platforma Android
- Minimalne uprawnienia w manifeście; komponenty `exported` świadomie.
- Deep linki i intenty: walidacja danych wejściowych.
- WebView: wyłączony dostęp do plików, brak wykonywania niezaufanego JS.
- Backup (`allowBackup`) świadomie ustawiony dla danych wrażliwych.

## Zależności
- Nowe paczki: utrzymywane, uzasadnione, bez znanych podatności (`osv-scanner`).
- Przypięte wersje, brak zależności z niezaufanych źródeł (git/URL).

## Wejście niezaufane i modele AI
- Odpowiedzi modelu traktowane jako dane niezaufane (brak wykonywania, walidacja formatu).
- Wstrzykiwanie instrukcji (prompt injection) przez dane użytkownika lub treści z sieci.
