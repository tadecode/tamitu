# Przepływy – Tamitu (MVP)

Stan: 2026-11-15 (po G2, ADR zatwierdzone; uwzględnione Aneksy A). Powiązane: `overview.md`, ADR-0002, 0004, 0005, 0007, `docs/api/posrednik-api.md`.

## 1. Pierwsze uruchomienie i logowanie (US-001, US-003)

```mermaid
sequenceDiagram
  actor U as Użytkownik
  participant A as Aplikacja
  participant G as Google Sign-In
  participant FA as Firebase Auth
  participant FN as recordConsent
  participant FS as Firestore

  U->>A: Uruchomienie
  A->>U: Ekran startowy, informacja o prywatności i AI, link do polityki (język UI)
  U->>A: Zaznacza zgodę na politykę (domyślnie puste)
  A->>A: Zapis lokalny zgody (wersja, język, czas) w prefs
  U->>A: Zaloguj przez Google
  A->>G: Wybór konta (Credential Manager)
  G-->>A: Token Google
  A->>FA: signInWithCredential
  FA-->>A: Użytkownik (UID), token ID
  A->>A: Otwarcie bazy konta (plik per UID, klucz z Keystore)
  A->>FN: recordConsent(privacy_policy, wersja, język, clientAt) + token + App Check
  FN->>FS: users/{uid}/consents/{id}
  FN-->>A: ok
  A->>U: Ekran główny (lista planów)
```
Błędy: anulowanie u dostawcy → powrót na ekran startowy bez błędu technicznego; brak sieci → komunikat i ponowienie; niepowodzenie `recordConsent` → kolejka ponowień (zgoda lokalna zachowana), a `generatePlan` zwróci `consent_required`, co wymusza synchronizację przed generowaniem.

## 2. Generowanie planu (US-004, US-005, US-006, US-011)

```mermaid
sequenceDiagram
  actor U as Użytkownik
  participant A as Aplikacja
  participant FN as generatePlan
  participant FS as Firestore
  participant V as Vertex AI (Gemini, UE)
  participant DB as Baza lokalna

  U->>A: Wypełnia formularz, zatwierdza
  A->>A: Walidacja i oczyszczanie pól, wartości domyślne (N11)
  alt brak zgody AI
    A->>U: Prośba o zgodę na AI (osobna), recordConsent(ai_processing)
  end
  A->>FN: generatePlan(requestId, dane bez UID/e-maila/lokalizacji/numeru lotu) + token ID + App Check
  FN->>FN: Token (checkRevoked: użytkownik istnieje), provider google.com, App Check
  FN->>FN: Walidacja schematu i zbiorów wartości
  FN->>FS: Zgoda AI aktualna? aiEnabled? allowRealData (+ ENFORCE_APP_CHECK)? limity (transakcja: konto 5/dobę kalendarzowo Europe/Warsaw, globalny 50)
  alt limit lub wyłącznik
    FN-->>A: limit_exceeded(resetAt) / ai_unavailable
    A->>U: Komunikat w języku UI
  else rezerwacja udana
    FN->>V: Prompt (instrukcje osobno, dane jako JSON), responseSchema
    V-->>FN: JSON planu
    FN->>FN: Walidacja: dni, punkty/dzień wg tempa, godziny pierwszego dnia (bufor 3 h lot / 0 auto), język, brak URL
    opt niepoprawny wynik (maks. 1 ponowienie)
      FN->>V: Druga próba
      V-->>FN: JSON
    end
    alt wynik poprawny
      FN-->>A: plan + remainingToday, resetAt
      A->>DB: Zapis planu i danych podróży (jedna transakcja)
      A->>U: Widok planu + informacja „plan stworzony przez AI, możliwe błędy"
    else po 2 próbach niepoprawny lub model niedostępny
      FN->>FS: Zwrot slotu limitu
      FN-->>A: ai_invalid_response / ai_unavailable
      A->>U: Komunikat, formularz zachowany
    end
  end
```
Anulowanie: aplikacja przerywa oczekiwanie i nic nie zapisuje lokalnie; slot limitu pozostaje zużyty, jeśli wywołanie modelu już ruszyło (ADR-0002, Q12 zatwierdzone). Dane formularza zostają w pamięci ekranu do powrotu.
Wycofanie zgody AI (ADR-0002, Aneks A pkt 4): aplikacja zapisuje `recordConsent(granted=false)` przed pokazaniem stanu „wycofano"; bez sieci – komunikat, generowanie zablokowane lokalnie do synchronizacji.

## 3. Link Google Maps (US-007)

```mermaid
sequenceDiagram
  actor U as Użytkownik
  participant A as Aplikacja (maps_link)
  participant OS as Android (uprawnienia)
  participant GM as Google Maps

  U->>A: Dotyka punktu planu
  A->>U: Wybór startu (nocleg / poprzedni punkt / moja lokalizacja) i trybu (auto, komunikacja, pieszo)
  alt start = moja lokalizacja
    A->>U: Wyjaśnienie celu (PL/EN)
    A->>OS: Prośba o uprawnienie (dokładna + przybliżona), pierwszy plan
    alt przyznano
      OS-->>A: Zgoda
      A->>OS: Jednorazowy odczyt pozycji (bez cache, bez last known)
      OS-->>A: lat,lng (tylko zmienna lokalna)
    else odmowa lub tylko przybliżona
      A->>U: Informacja; trasa z punktu startowego planu
    end
  end
  A->>A: Budowa URL maps/dir/?api=1&origin&destination&travelmode (bez zapisu)
  A->>GM: Otwarcie linku (aplikacja Maps lub przeglądarka)
  Note over A: Współrzędne odrzucone po zbudowaniu linku, nie w logach, planie, stanie
```
Uwaga: obowiązuje wariant A (Q1). Wariant C z ADR-0007 (bez `origin`, bez uprawnienia) pomija blok „moja lokalizacja" w całości; jest testowany na urządzeniu w fazie 3 (P3-07) i wejdzie wyłącznie nowym ADR. Link otwierany w trybie zewnętrznej aplikacji.

## 4. Usunięcie konta i danych (US-010)

```mermaid
sequenceDiagram
  actor U as Użytkownik
  participant A as Aplikacja
  participant FN as deleteAccount
  participant FS as Firestore
  participant FA as Firebase Auth
  participant DB as Dane lokalne

  U->>A: Ustawienia → Usuń konto → potwierdza ostrzeżenie
  alt brak sieci
    A->>U: Komunikat, nic nie usunięto
  else
    A->>A: Znacznik „usuwanie w toku" (secure storage)
    A->>FN: deleteAccount + token + App Check
    alt auth_time starsze niż 5 min
      FN-->>A: reauth_required
      A->>U: Prośba o ponowne zalogowanie Google
      A->>FN: deleteAccount (ponownie)
    end
    FN->>FS: Rekursywne usunięcie users/{uid}, usage/{uid}
    FN->>FA: deleteUser(uid)
    FN->>FS: Kontrolne powtórne usunięcie users/{uid}, usage/{uid} (wyścig z żądaniem w locie)
    FN-->>A: deleted
    A->>DB: Usunięcie pliku bazy konta, ustawień konta, znacznika
    A->>FA: signOut (lokalnie)
    A->>U: Ekran startowy
  end
```
Przerwanie po stronie serwera → ponowienie jest bezpieczne (idempotentne). Zabicie aplikacji po sukcesie serwera → przy starcie znacznik „w toku" wymusza dokończenie czyszczenia lokalnego. Logi techniczne (skrót UID) wygasają w 30 dni (S7). Dane innych kont na urządzeniu pozostają (N3). Dowód zgód jest usuwany razem z kontem (Q9). Wywołanie `recordConsent`/`generatePlan` starym tokenem po usunięciu zwraca `unauthenticated` i nie tworzy dokumentów (ADR-0002, Aneks A pkt 1).

## 5. Wylogowanie (US-002)
Aplikacja zamyka bazę bieżącego konta, wykonuje `signOut` Google i Firebase, wraca na ekran startowy. Plany zostają zaszyfrowane na urządzeniu w pliku konta (N3); drugie konto otwiera własny plik (US-008).
