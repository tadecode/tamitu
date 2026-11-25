# US-007: Link Google Maps z trasą do punktu planu

**Jako** użytkownik **chcę** jednym dotknięciem otworzyć w Google Maps trasę do punktu planu, **aby** łatwo tam dotrzeć.

- Priorytet: MVP
- Wersja: 2026-11-25 (TAM-110) – wariant C: Tamitu nie odczytuje lokalizacji (Q1 = C, ADR-0017; ekran EK-09 v0.4). Zastępuje wersję z dokładną lokalizacją w aplikacji (S6, ADR-0007).
- Dane osobowe: TAK – w linku do Google Maps trafiają tylko dane z planu: cel (nazwa punktu, miejscowość, cel podróży), tryb podróży i opcjonalnie start z planu jako tekst (nocleg albo poprzedni punkt dnia; rejestr D8). **Tamitu nie prosi o uprawnienia lokalizacji, nie odczytuje pozycji telefonu i nie przetwarza danych o lokalizacji** (brak D7). Bieżącą pozycję przy starcie „Moja lokalizacja” ustala Google Maps na podstawie zgody, którą użytkownik dał Mapom lub przeglądarce. Link nie jest zapisywany ani logowany.

## Kryteria akceptacji
- **AC1 – wybór startu i trybu.** **Given** widok planu (EK-08) **When** użytkownik dotyka punktu lub akcji „Trasa” **Then** widzi wybór (EK-09):
  - start, w tej kolejności: „Moja lokalizacja” (zawsze dostępna, **zaznaczona domyślnie przy każdym otwarciu**), „Poprzedni punkt dnia” (**ukryty przy pierwszym punkcie dnia**), „Nocleg” (**ukryty, gdy plan nie ma noclegu**); ukryta pozycja nie jest pokazywana jako nieaktywna;
  - tryb: auto / komunikacja / pieszo; **zapamiętany ostatni wybór** (jeden dla całej aplikacji, przy pierwszym użyciu „Komunikacja”); wybrany start nie jest zapamiętywany;
  - przy domyślnym starcie i zapamiętanym trybie wystarcza jedno dotknięcie „Otwórz w Google Maps”.
  (Testowalne: testy widgetowe – pozycje startu dla pierwszego i kolejnego punktu dnia, z noclegiem i bez; trwałość trybu po ponownym otwarciu arkusza i po restarcie aplikacji; start po ponownym otwarciu = „Moja lokalizacja”.)
- **AC2 – „Moja lokalizacja” bez lokalizacji w Tamitu.** **Given** start „Moja lokalizacja” **When** użytkownik potwierdza **Then** otwiera się link Google Maps **bez parametru `origin`**, a aplikacja **nie deklaruje żadnych uprawnień lokalizacji** (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, `FOREGROUND_SERVICE_LOCATION`), nie pokazuje prośby o lokalizację ani ekranu wyjaśnienia i nie używa pakietów lokalizacji. (Testowalne: test jednostkowy – brak klucza `origin` w `Uri.queryParameters`; test manifestu – uprawnienia = `{INTERNET}` w manifeście źródłowym i zmergowanym; `pubspec.lock` bez `geolocator`.) **[ZMIANA TAM-110: zastępuje dawne AC2, AC3, AC5 i AC7 – prośbę o uprawnienie, odmowę uprawnienia, współrzędne w `origin` i pobieranie lokalizacji na żądanie]**
- **AC3 – start z planu.** **Given** start „Nocleg” lub „Poprzedni punkt dnia” **When** użytkownik potwierdza **Then** `origin` zawiera tekst z planu: dla noclegu `"{nocleg}, {cel podróży}"`, dla poprzedniego punktu `"{nazwa}, {miejscowość}, {cel podróży}"`; nigdy współrzędne i nigdy pusty parametr `origin=`. (Testowalne: test jednostkowy budowy URL dla obu startów.)
- **AC4 – parametry linku.** **Given** wybrany start, cel i tryb **When** użytkownik potwierdza **Then** otwiera się Google Maps (aplikacja lub przeglądarka) z trasą do celu w wybranym trybie. (Testowalne: URL `https://www.google.com/maps/dir/?api=1&destination=…&travelmode=…[&origin=…]`; `travelmode` = `driving` / `transit` / `walking`; znaki specjalne i polskie litery zakodowane procentowo.)
- **AC5 – cel jako nazwa i miejscowość.** **Given** dowolny punkt planu **When** budowany jest link **Then** `destination` to tekst `"{nazwa}, {miejscowość}, {cel podróży}"`, **nigdy same współrzędne** ani adres URL pochodzący od modelu AI. (Testowalne: test jednostkowy – `destination` zawiera nazwę i miejscowość punktu, nie pasuje do wzorca współrzędnych.) **[NOWE TAM-110: w teście TAM-24 cel podany współrzędnymi wskazał sąsiedni obiekt; zastępuje dawne AC6 o punkcie bez rozpoznanej lokalizacji]**
- **AC6 – brak lokalizacji w tle.** **Given** aplikacja w manifeście **Then** nie deklaruje uprawnienia lokalizacji w tle ani usługi lokalizacji na pierwszym planie (testowalne: analiza manifestu). Szczególny przypadek AC2 – zostaje jako osobny test regresji.
- **AC7 – brak aplikacji Google Maps.** **Given** brak zainstalowanej lub wyłączona aplikacja Google Maps **Then** link otwiera się w przeglądarce z tym samym celem, startem i trybem.
- **AC8 – błąd otwarcia.** **Given** system nie otworzył linku (`launchUrl` zwraca `false`) **Then** użytkownik widzi komunikat (`routeOpenError`), arkusz EK-09 zostaje otwarty i można spróbować ponownie; link nie jest zapisywany ani logowany.

Mapa zmian numeracji (TAM-110): dawne AC1 → AC1 (zmienione), AC2 + AC3 + AC5 + AC7 → AC2, AC4 → AC4, AC6 → AC5 (zmienione), AC8 → AC6, AC9 → AC7; AC3 (start z planu) i AC8 (błąd otwarcia) – nowe, zgodnie z ADR-0017 i EK-09 v0.4.

## Uwagi / poza zakresem
- Bez osadzania mapy w aplikacji, bez podpowiedzi „w pobliżu”, bez lokalizacji w tle (decyzja właściciela, pyt. 4) i bez nawigacji krok po kroku.
- Lokalizacja: decyzja S6 (dokładna lokalizacja w aplikacji) zastąpiona decyzją Q1 = C (właściciel 2026-11-25, ADR-0017). Prośbę o lokalizację, jej odmowę i wyłączoną lokalizację w telefonie obsługuje Google Maps lub przeglądarka – poza kontrolą Tamitu (wynik testu: `docs/qa/QA-TAM-24-maps-bez-origin.md`).
- Brak sieci: Tamitu nie sprawdza połączenia przed otwarciem linku; brak sieci obsługuje Google Maps (ADR-0011 pkt 2, EK-09).
- Przy starcie z noclegu lub poprzedniego punktu Mapy pokazują podgląd trasy zamiast nawigacji (zachowanie Map). Start z noclegu jest przybliżony (U14).
- Link nie wymaga klucza Google Maps API (ADR-0007, ADR-0017; koszt 0).
- Inne aplikacje mapowe (`geo:`) – po MVP (TAM-106).
