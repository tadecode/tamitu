# ADR-0012: Egzekwowanie wersji polityki prywatności (i zgody AI) po stronie serwera w `generatePlan`

- Status: proponowany (do zatwierdzenia przez właściciela; S17, SEC-26)
- Data: 2026-11-16
- Autor (rola): architect
- Zadanie: S17 / SEC-26 (przegląd security ekranów, ustalenie blokujące B-1: `docs/security/reviews/2026-11-16-p3-14c-ekrany.md`); US-003, T30
- Uzupełnia: ADR-0005 (Decyzja pkt 3: „`generatePlan` sprawdza, że ostatnia zgoda `ai_processing` jest nadana dla bieżącej wersji") i ADR-0011 (pkt 1 i 7). Żaden zatwierdzony punkt nie jest zmieniany: rozszerzamy sprawdzenie serwera o politykę prywatności i doprecyzowujemy porównanie wersji. Zastępuje fragment ADR-0011 pkt 1 „`config/runtime.policyVersionCurrent` pozostaje wyłącznie po stronie serwera (rezerwa na przyszłe egzekwowanie)" – egzekwowanie wchodzi teraz.

## Kontekst
US-003: bez akceptacji aktualnej polityki prywatności nie można korzystać z funkcji AI. Dziś pilnuje tego tylko aplikacja (EK-01 porównuje stałą wersji wbudowaną w aplikację z lokalnym rekordem – ADR-0011 pkt 1). Serwer sprawdza w `generatePlan` wyłącznie zgodę `ai_processing`. Security (B-1) wskazał, że zmodyfikowany lub błędny klient może więc wysłać dane do AI bez akceptacji aktualnej polityki, a serwer tego nie zatrzyma.

Uwaga do opisu B-1: scenariusz „EK-01 pomija sprawdzenie bez sieci" dotyczył pierwotnej specyfikacji EK-01 (wersja z `config/runtime`, pomijana offline). Po zatwierdzeniu ADR-0011 pkt 1 sprawdzenie w aplikacji jest lokalne i działa także offline, więc ta ścieżka obejścia w uczciwym kliencie nie istnieje. Brak kontroli serwerowej pozostaje jednak luką (obrona w głąb, klient niezaufany – T30).

Dodatkowy problem ujawniony przy projektowaniu: porównanie „wersja rekordu = wersja bieżąca" (równość) tworzy wyścig przy zmianie wersji. Użytkownik, który zaktualizował aplikację i zaakceptował `privacy-v2`, zanim właściciel przestawi konfigurację serwera z `privacy-v1`, zostałby odrzucony. To samo dotyczy zgody AI.

## Rozważane opcje
1. **Serwer sprawdza w `generatePlan` także ostatni rekord `privacy_policy`; wersje numerowane, porównanie „≥ bieżąca"; nowe wersje znane serwerowi przed wydaniem aplikacji.** Domyka lukę, bez nowych funkcji i nowych danych, koszt ≈ 1 odczyt Firestore na generowanie.
2. Tylko klient (stan obecny, ADR-0011 pkt 1). Najprościej, ale nie spełnia B-1.
3. Osobna funkcja `getConsentStatus` wywoływana przy starcie. Dodatkowe wywołanie i koszt przy każdym starcie, praca offline gorsza, a i tak trzeba by egzekwować w `generatePlan`. Odrzucone.
4. Egzekwowanie także w `recordConsent`/`deleteAccount`. Odrzucone: te funkcje służą właśnie do akceptacji polityki i do usunięcia konta (ADR-0011 pkt 4) i muszą działać bez aktualnej akceptacji.

## Decyzja
**Opcja 1.**
1. **Format wersji:** `privacy-v<N>` i `ai-consent-v<N>`, `N` – liczba całkowita 1–9999 (wzorzec `^(privacy|ai-consent)-v[1-9]\d{0,3}$`). Porównanie po `N` w ramach typu.
2. **Lista znanych wersji w kodzie serwera** (`backend/functions`, stała obok schematów; realizuje też SEC-21 „lista znanych wersji"). `recordConsent` odrzuca wersję spoza listy (`invalid_argument`, `field: policyVersion`). Nowa wersja trafia na listę i jest wdrażana **przed** wydaniem aplikacji z nowym tekstem.
3. **`generatePlan`, krok 3 (zgody), w kolejności:**
   a. ostatni rekord `privacy_policy` (po `receivedAt`) musi istnieć i mieć `N ≥ N(config/runtime.policyVersionCurrent)`; inaczej `consent_required` z `details.consentType = "privacy_policy"`;
   b. ostatni rekord `ai_processing` musi mieć `granted = true` i `N ≥ N(config/runtime.aiConsentVersionCurrent)`; inaczej `consent_required` z `consentType = "ai_processing"` (doprecyzowanie ADR-0005 pkt 3: „bieżąca wersja" = co najmniej bieżąca).
   Oba odczyty korzystają z istniejącego indeksu (`type` rosnąco, `receivedAt` malejąco); brak nowych indeksów i kolekcji.
4. **`config/runtime`:** `policyVersionCurrent` i `aiConsentVersionCurrent` w nowym formacie (start: `privacy-v1`, `ai-consent-v1`). Brak lub zły format → fail-closed: `generatePlan` zwraca `consent_required` (`privacy_policy`) i loguje kod konfiguracji (bez danych). Wartości nadal niedostępne dla klienta (ADR-0011 pkt 1).
5. **Aplikacja:**
   - Przed `generatePlan` wysyła oczekujące rekordy zgód (`synced = 0`; rozszerza ADR-0011 pkt 10), więc `consent_required` nie wynika z opóźnionej synchronizacji.
   - `consent_required` + `consentType = privacy_policy` → EK-03; `ai_processing` → EK-06.
   - Jeśli aplikacja ma już zsynchronizowany rekord danego typu w wersji wbudowanej, a serwer nadal zwraca `consent_required` → „Zaktualizuj aplikację" (bez pętli; ADR-0011 pkt 7 rozszerzony na oba typy).
   - EK-01 bez zmian względem ADR-0011 pkt 1 (sprawdzenie lokalne, także offline). Dodatkowe sprawdzenie „przy pierwszej akcji sieciowej w sesji" nie jest potrzebne: serwer odrzuca każde `generatePlan`, a odpowiedź prowadzi do EK-03.
6. **Procedura zmiany polityki (właściciel):**
   1. dopisanie wersji do listy w backendzie i wdrożenie;
   2. wydanie aplikacji z nowym tekstem i stałą;
   3. po decyzji właściciela (np. po okresie aktualizacji) ustawienie `policyVersionCurrent` na nową wersję.
   
   Do kroku 3 starsze aplikacje działają; po nim ich użytkownicy dostają „Zaktualizuj aplikację". Ta sama procedura dotyczy `aiConsentVersionCurrent`. Wpis w `.farm/log` przy każdej zmianie.
7. **Testy (emulator):** brak rekordu polityki → `consent_required/privacy_policy`, bez rezerwacji limitu; rekord `N` < bieżącej → odrzucenie; rekord `N` > bieżącej → przyjęcie; analogicznie dla AI; zły format konfiguracji → fail-closed; `recordConsent` z nieznaną wersją → `invalid_argument`; kolejność: sprawdzenie zgód przed rezerwacją limitu (ADR-0002, kroki 3–5).

## Konsekwencje
**Pozytywne:** US-003 egzekwowane po stronie serwera (B-1 zamknięte po implementacji); brak wyścigu przy zmianie wersji; wspólny mechanizm dla obu zgód; brak nowych danych, funkcji i uprawnień.
**Negatywne / ryzyka:** nowa wersja wymaga wdrożenia backendu przed wydaniem aplikacji (krok procedury – ryzyko pomyłki łagodzi test `recordConsent` z nieznaną wersją); użytkownicy starych wersji aplikacji tracą generowanie po kroku 3 procedury (zamierzone).
**Koszty (CLAUDE.md pkt 10):** +1 odczyt Firestore na `generatePlan` (rekord `privacy_policy`), w darmowej puli (50 tys. odczytów/dobę); odrzucenie następuje przed rezerwacją limitu i wywołaniem modelu, więc koszt AI bez zmian. `docs/architecture/costs.md` bez zmian (pozycja Firestore „ok. 3 odczyty" → ok. 4, pomijalne).
**Dane osobowe:** brak nowych kategorii; odczyt istniejących rekordów D3.
**Do wykonania po zatwierdzeniu:** kontrakt `docs/api/posrednik-api.md` v0.4 (projekt w pkt 8), `docs/data/model-danych.md` (format wersji w `config/runtime`); mobile-dev – implementacja w P3-04/P3-05 (SEC-26, SEC-21); ux – EK-16: mapowanie `consentType` (EK-03 / EK-06) i komunikat aktualizacji dla obu typów.
