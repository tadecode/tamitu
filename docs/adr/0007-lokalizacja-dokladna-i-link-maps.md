# ADR-0007: Lokalizacja dokładna, link Google Maps i minimalna wersja Androida

- Status: zatwierdzony (bramka G2, 2026-11-15; zatwierdził właściciel produktu)
- Data: 2026-11-15
- Autor (rola): architect
- Zadanie: P2-06 (pyt. 4, S6, US-007, pyt. 7; T11, T12, T5, SEC-05, SEC-12, SEC-13; założenie A4)
- Odpowiedzi właściciela uwzględnione: **Q1 = opcja A z testem opcji C w fazie 3** (wdrażamy dokładną lokalizację; wariant C sprawdzany na urządzeniu w P3-07 i ewentualnie upraszczamy – zmiana tylko nowym ADR zastępującym; Security rekomendował C), **Q8 = minSdk 26**. Uwagi Security 7-1, 7-2, 7-4: „Aneks A" na końcu.

## Kontekst
Decyzje właściciela: lokalizacja tylko do linku trasy, na żądanie, na pierwszym planie, bez tła i „w pobliżu" (pyt. 4); **dokładność: dokładna** (S6). Link Google Maps z trasą bez osadzania mapy i bez klucza API (vision, A4). Min. API Androida ustala architekt (pyt. 7).

## Rozważane opcje (lokalizacja)
| # | Opcja | Plusy | Minusy |
|---|---|---|---|
| A | **Uprawnienie dokładnej lokalizacji (`ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION`), jednorazowy odczyt, współrzędne w `origin` linku** | Zgodne z S6 i US-007; trasa z dokładnego punktu | Uprawnienie wrażliwe: Data Safety, uzasadnienie w Play (SEC-13), D7, testy braku persystencji (SEC-12); plugin lokalizacji |
| B | Tylko przybliżona (`ACCESS_COARSE_LOCATION`) | Mniejsza wrażliwość | Sprzeczne z S6 |
| C | **Bez uprawnienia: link bez `origin`** – wg dokumentacji Maps URLs przy braku `origin` Google Maps wykorzystuje bieżącą lokalizację użytkownika (we własnej aplikacji, z jej zgodą) | Zero danych lokalizacyjnych w Tamitu; zero uprawnień; brak D7/SEC-12/SEC-13; najprostsze i najbezpieczniejsze | Zmienia zatwierdzony kierunek (S6, kryteria US-007 o parametrze `origin` ze współrzędnymi); zachowanie przy braku zgody w Maps/przeglądarce poza naszą kontrolą; wymaga testu na urządzeniach |

## Decyzja
**Wdrażamy opcję A zgodnie z zatwierdzonym S6 i US-007 (decyzja właściciela, Q1).** Opcja C (link bez `origin`) pozostaje kandydatem do uproszczenia: **w fazie 3 (P3-07) przeprowadzić test C na urządzeniu** (z aplikacją Maps i bez niej; z uprawnieniem lokalizacji w Maps i bez; przeglądarka) i przedstawić wynik właścicielowi. Jeśli test pozytywny i właściciel zdecyduje o przejściu na C – **nowy ADR zastępujący ten punkt** oraz zmiana US-007/S6 przez Analityka; wtedy wypadają: uprawnienia lokalizacji, `geolocator`, D7, SEC-12, część SEC-13 i T12. Do czasu takiej decyzji obowiązuje pełna specyfikacja opcji A poniżej.

### Specyfikacja opcji A
- **Manifest:** `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` (od Androida 12 aplikacja żądająca dokładnej lokalizacji musi zadeklarować i zażądać także przybliżonej – użytkownik może przyznać tylko przybliżoną; odpowiedź na uwagę rejestru D7). **Brak** `ACCESS_BACKGROUND_LOCATION`, usług pierwszoplanowych lokalizacji, `FOREGROUND_SERVICE_LOCATION`. Sprawdzenie zmergowanego manifestu w CI (test: lista uprawnień równa liście dozwolonych).
- **Moment prośby:** dopiero po wyborze startu „moja lokalizacja" w widoku punktu; wcześniej ekran z wyjaśnieniem celu (PL/EN, tekst z `privacy-checklist.md` pkt 2). Odmowa lub tylko przybliżona: aplikacja działa, trasa z punktu startowego planu (US-007).
- **Odczyt:** pakiet `geolocator`, **pojedynczy** `getCurrentPosition` (wysoka dokładność, limit czasu ok. 10 s); **zakaz** `getLastKnownPosition`, strumieni pozycji, usług w tle i buforowania. Współrzędne żyją tylko w zmiennej lokalnej do zbudowania adresu URL, nie trafiają do stanu aplikacji (provider), bazy, logów, zrzutów stanu, wyjątków ani żądań do pośrednika/AI. Link ze współrzędnymi **nie jest zapisywany w planie**; budowany przy każdym dotknięciu. Test automatyczny/inspekcja: brak persystencji (SEC-12).
- **Weryfikacja pluginu:** po dodaniu pakietu sprawdzić zmergowany manifest i brak dodatkowych uprawnień; `AD_ID` usunięty.

### Link Google Maps (bez klucza API – A4 potwierdzone)
Format Maps URLs: `https://www.google.com/maps/dir/?api=1&origin=<..>&destination=<..>&travelmode=<driving|transit|walking>`; parametry kodowane procentowo, długość URL < 2 048 znaków.
- `destination`: tekst „nazwa, miejscowość, cel podróży" z danych planu (nie URL od modelu – T5; walidator serwera odrzuca URL-e).
- `origin`: baza noclegowa (tekst „nocleg, cel"), poprzedni punkt dnia (tekst) albo współrzędne `lat,lng` (opcja A, tylko bieżąca chwila).
- Tryby: auto = `driving`, komunikacja = `transit`, pieszo = `walking`.
- Otwarcie: `url_launcher`, tryb zewnętrznej aplikacji (Google Maps), przy braku – przeglądarka (US-007). Android 11+: deklaracja `<queries>` dla intencji `VIEW` https.
- Brak Maps SDK, Places ani Geocoding API; koszt Maps = 0, brak klucza do wycieku (T2). Użycie API (np. geokodowanie) wymaga nowego ADR i wpisu w rejestrze (D8).

### Minimalna wersja Androida
**`minSdk` = 26 (Android 8.0) – zatwierdzone przez właściciela (Q8).** Uzasadnienie: obejmuje zdecydowaną większość aktywnych urządzeń; spełnia wymagania Firebase, Credential Manager i Play Integrity z zapasem; upraszcza kod (java.time bez desugaringu, kanały, szyfrowanie Keystore). Alternatywa 24 – tylko jeśli właściciel poda grupę docelową na starszych telefonach (koszt: desugaring i dodatkowe testy). `targetSdk` zgodny z aktualnym wymogiem Google Play dla nowych aplikacji (sprawdzić w chwili zadania P3-01; w chwili pisania co najmniej Android 15/16 – do weryfikacji).

## Konsekwencje
**Pozytywne:** brak kosztów Maps i kluczy; jasne granice danych lokalizacji.
**Negatywne:** opcja A utrzymuje uprawnienie wrażliwe i obowiązki Play/RODO (R12); po otwarciu linku Google (odrębny administrator) dostaje dokładną pozycję (ryzyko rezydualne, T12 – opisać w polityce).
**Koszty:** 0.
**Dane osobowe:** D7 (tylko w pamięci), D8 (nazwy w URL); brak zapisu i transmisji do naszych usług.

## Aneks A (2026-11-15, przy zatwierdzeniu)
1. **Zawartość linku i ślad po stronie Google (7-1, 7-2, D8).** `origin` może zawierać nocleg (`"{lodging}, {trip.destination}"`), poprzedni punkt dnia lub współrzędne; Google Maps otrzymuje więc cel, nocleg/punkty i ewentualnie współrzędne. Ślad może powstać w historii przeglądarki (fallback), historii aktywności Google i innej aplikacji obsługującej link https – poza kontrolą Tamitu; opisać w polityce i w tekście wyjaśnienia przed prośbą o uprawnienie. Link otwierany **wyłącznie** w trybie zewnętrznej aplikacji (`LaunchMode.externalApplication`), bez zapisu w historii aplikacji; test.
2. **Test C w fazie 3 (Q1).** Wynik testu (scenariusze, urządzenia, werdykt) zapisać jako aneks do tego ADR; rekomendację Security (opcja C) uwzględnić w ocenie.
3. **Przy opcji A obowiązują:** SEC-12 (test braku persystencji), SEC-13 (Data Safety, uzasadnienie uprawnienia w Google Play), D7, T12 (ryzyko rezydualne średnio-niskie), weryfikacja zmergowanego manifestu po dodaniu `geolocator` (T16), `AD_ID` usunięty.
