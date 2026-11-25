# ADR-0017: Trasa w Google Maps bez lokalizacji w aplikacji (wariant C)

- Status: **zatwierdzony co do decyzji** (właściciel, 2026-11-25, Q1 = C: „wariant C dla MVP”). Szczegóły
  techniczne poniżej obowiązują od merge'u PR-a tego ADR.
- Data: 2026-11-25
- Autor (rola): architect
- Zadanie: TAM-107 (P3-07-ADR); podstawa: raport QA `docs/qa/QA-TAM-24-maps-bez-origin.md` (TAM-24, PR #172)
- **Zastępuje:** ADR-0007 w części „lokalizacja” (tabela opcji, sekcja „Decyzja”, „Specyfikacja opcji A”,
  wariant `origin` ze współrzędnymi, Aneks A pkt 3). **Nie zastępuje:** formatu linku Maps, `destination` jako
  tekstu, `externalApplication`, `<queries>`, braku Maps API i klucza, minimalnej wersji Androida (minSdk 26) –
  te części ADR-0007 obowiązują nadal, doprecyzowane niżej. Aneks A pkt 2 ADR-0007 (wynik testu C) wykonany
  w sekcji „Wynik testu” tego ADR.

## W skrócie
Przycisk „Moja lokalizacja” w Tamitu otwiera Google Maps **bez punktu startowego** w linku. Mapy same ustawiają
start „Twoja lokalizacja” i same proszą o zgodę, jeśli jej nie mają. Tamitu **nie prosi o uprawnienia lokalizacji,
nie odczytuje pozycji telefonu i nie przetwarza danych o lokalizacji**. Starty „Nocleg” i „Poprzedni punkt dnia”
działają jak dotąd (tekst z planu w parametrze `origin`).

## Kontekst
ADR-0007 wdrażał wariant A (dokładna lokalizacja: uprawnienia `ACCESS_FINE_LOCATION` i `ACCESS_COARSE_LOCATION`,
pakiet `geolocator`, jednorazowy odczyt, współrzędne w `origin`), z zastrzeżeniem, że wariant C zostanie sprawdzony
na telefonie w fazie 3 i może go zastąpić tylko nowy ADR. Security od początku rekomendował C (przegląd ADR, uwaga
7-4). Wariant A nie został jeszcze zaimplementowany: manifest ma tylko `INTERNET`, w `pubspec.yaml` nie ma
`geolocator`, a test `test/android_manifest_test.dart` już sprawdza brak uprawnień lokalizacji.

### Wynik testu (TAM-24, 2026-11-25)
Telefon z Androidem 13 i Google Maps 26.47; link otwierany intencją `VIEW`, tak jak zrobi to `url_launcher`.

| Scenariusz | Wynik |
|---|---|
| Bez `origin`, Mapy z dostępem do lokalizacji; `driving`, `transit`, `walking` | start „Twoja lokalizacja”, cel i tryb ustawione, trasa wyznaczona, od razu „Rozpocznij” (nawigacja) |
| `origin` = nocleg (tekst) | start rozpoznany z tekstu, trasa wyznaczona; Mapy pokazują „Podgląd” zamiast nawigacji (zachowanie Map) |
| Lokalizacja w telefonie wyłączona | okno usług Google „Włącz lokalizację”; po odmowie trasa z celem i pustym startem do wybrania |
| Mapy bez uprawnienia lokalizacji | systemowa prośba Androida **dla Map**; po odmowie wybór startu ręcznie; bez zapętlenia |
| Aplikacja Map wyłączona | link otwiera Google Maps w przeglądarce: start „Twoja lokalizacja”, cel i tryb zachowane |
| Cel jako same współrzędne | ⚠️ Mapy wskazały sąsiedni obiekt o innej nazwie; cel jako „nazwa, miejscowość” – poprawnie |

Ograniczenia testu: jeden telefon; nie sprawdzono przycisku „Włącz” w oknie lokalizacji ani pierwszej prośby
przeglądarki o lokalizację. Zachowanie przy braku zgody obsługuje Google, nie Tamitu.

## Rozważane opcje
| # | Opcja | Plusy | Minusy |
|---|---|---|---|
| A | Uprawnienia FINE + COARSE, jednorazowy odczyt `geolocator`, współrzędne w `origin` (ADR-0007) | Tamitu kontroluje punkt startu | Wrażliwe uprawnienie: Data Safety, uzasadnienie w Play (SEC-13), D7, testy braku zapisu (SEC-12), T12; dodatkowy pakiet (T16); ekran EK-10 i 5 stanów błędów w EK-09; więcej kodu i testów |
| B | Tylko przybliżona lokalizacja (COARSE) | Mniej wrażliwe niż A | Nadal uprawnienie, D7 i deklaracje Play; gorsza trasa niż C |
| **C** | **Link bez `origin` przy „Moja lokalizacja”; zero uprawnień** | Zero danych lokalizacji w Tamitu; brak D7, SEC-12, części SEC-13, T12, EK-10; mniej kodu; Mapy od razu proponują nawigację; zgodne z rekomendacją security; test na telefonie pozytywny | Prośbę o lokalizację i jej odmowę obsługują Mapy (poza kontrolą Tamitu); zachowanie przeglądarki przy pierwszej prośbie niesprawdzone |
| D | Inne aplikacje mapowe przez link `geo:` (systemowy wybór aplikacji) | Wybór aplikacji przez użytkownika | `geo:` przenosi tylko cel, bez trybu i trasy; **odłożone po MVP (TAM-106)**, ewentualnie jako opcja dodatkowa obok linku Google Maps, nie zamiennik |

## Decyzja
**Wariant C dla MVP.** Tamitu nie deklaruje i nie żąda żadnych uprawnień lokalizacji oraz nie odczytuje pozycji
urządzenia w żaden sposób. Start „Moja lokalizacja” = link Google Maps **bez parametru `origin`**.

### 1. Budowa linku (moduł `features/maps_link`)
```
https://www.google.com/maps/dir/?api=1&destination=<destination>&travelmode=<mode>[&origin=<origin>]
```
| Parametr | Wartość | Zasady |
|---|---|---|
| `api` | `1` | zawsze, pierwszy parametr |
| `destination` | `"{name}, {locality}, {trip.destination}"` z punktu planu | **zawsze tekst z nazwą i miejscowością**; nigdy same współrzędne (test TAM-24: trafiły w sąsiedni obiekt); nigdy URL od modelu (T5); plan nie zawiera współrzędnych (`generate-plan.response.schema.json`) |
| `travelmode` | `driving` (auto), `transit` (komunikacja), `walking` (pieszo) | wybór użytkownika, niezapisywany |
| `origin` | start „Moja lokalizacja”: **parametr pominięty**; „Nocleg”: `"{lodging}, {trip.destination}"`; „Poprzedni punkt dnia”: `"{name}, {locality}, {trip.destination}"` poprzedniego punktu | tylko tekst z planu; **nigdy współrzędne**; brak noclegu w planie → opcja „Nocleg” niedostępna (bez pustego `origin`) |

- Kodowanie: `Uri.https('www.google.com', '/maps/dir/', {...})` (kodowanie procentowe przez `Uri`, nie sklejanie
  tekstu); pusty parametr nie trafia do URL (brak `origin=`). Długość URL < 2 048 znaków (pola planu mają limity
  100 + 80 + cel, więc limit jest spełniony z zapasem).
- Otwarcie: `url_launcher`, `launchUrl(uri, mode: LaunchMode.externalApplication)`; bez aplikacji Map system
  otwiera przeglądarkę (sprawdzone w TAM-24). Gdy `launchUrl` zwróci `false` – komunikat z l10n (brak aplikacji
  do otwarcia linku); link nie jest zapisywany ani logowany.
- Domyślny start w EK-09 i teksty wyjaśniające (że zgodę na lokalizację daje Mapom użytkownik w Mapach) ustala UX
  (TAM-108); ten ADR nie zmienia `docs/ux/`.

### 2. Manifest Androida
- Uprawnienia: tylko `INTERNET`. **Brak** `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`,
  `ACCESS_BACKGROUND_LOCATION`, `FOREGROUND_SERVICE_LOCATION` i usług lokalizacji.
- `<queries>`: dopisać intencję `VIEW` dla `https` (wymagane od Androida 11 przez `url_launcher`, żeby
  `canLaunchUrl`/`launchUrl` widziały aplikację obsługującą link):
  ```xml
  <intent>
      <action android:name="android.intent.action.VIEW" />
      <data android:scheme="https" />
  </intent>
  ```
  Bez `QUERY_ALL_PACKAGES` i bez nazw pakietów (np. `com.google.android.apps.maps`) w `<queries>`.

### 3. Zależności
- **Bez pakietu `geolocator`** i innych pakietów lokalizacji (`location`, `permission_handler` w celu lokalizacji,
  Play Services Location). Dodanie takiego pakietu wymaga nowego ADR.
- `url_launcher` (już w `pubspec.yaml`) – jedyna zależność modułu.

### 4. Testy
- `test/android_manifest_test.dart` (istnieje): lista uprawnień = `{INTERNET}` w manifeście źródłowym
  i zmergowanym; test „no location permissions” zostaje i odwołuje się do ADR-0017. Dopisać: obecność `<queries>`
  z `VIEW` + `https`.
- Test pakietów (jednostkowy lub w CI): `pubspec.lock` nie zawiera `geolocator`.
- Testy jednostkowe budowy URL: start „Moja lokalizacja” → brak klucza `origin` w `Uri.queryParameters`; „Nocleg”
  i „Poprzedni punkt” → `origin` = oczekiwany tekst; każdy `travelmode`; kodowanie znaków `&`, `#`, `|`, `%`,
  nawiasy, polskie znaki; `destination` zawiera nazwę i miejscowość.
- Ręcznie (QA): otwarcie linku w Mapach w trzech trybach; zachowanie bez zgody Map opisuje TAM-24.

### 5. Co przekazujemy Google w linku (D8)
Link otwiera aplikacja lub strona Google Maps (Google jest tu odrębnym administratorem). W linku są: cel
(`destination`: nazwa punktu, miejscowość, cel podróży), tryb podróży oraz opcjonalnie start (`origin`: nazwa
noclegu z celem podróży albo poprzedni punkt dnia). **Nie ma współrzędnych ani pozycji telefonu.** Bieżącą pozycję
Mapy odczytują same, na podstawie zgody, którą użytkownik dał aplikacji Map lub przeglądarce, a nie Tamitu.
Ślad może powstać w historii aktywności Google lub w historii przeglądarki (fallback) – poza kontrolą Tamitu;
to ryzyko rezydualne opisuje polityka prywatności. Bez Maps SDK, Places i Geocoding API; brak klucza; koszt 0.

## Konsekwencje
**Pozytywne:** Tamitu nie przetwarza lokalizacji; brak wrażliwego uprawnienia, ekranu EK-10, stanów odczytu
pozycji i odmowy w EK-09; mniej kodu, testów i ryzyka przy przeglądzie Google Play; przy „Moja lokalizacja” Mapy
od razu proponują nawigację.

**Negatywne i ryzyka:** prośbę o lokalizację, jej odmowę i wyłączoną lokalizację obsługują Mapy lub przeglądarka
(poza kontrolą Tamitu; w teście zachowanie czytelne, cel zawsze zachowany). Przy starcie z noclegu lub poprzedniego
punktu Mapy pokazują podgląd zamiast nawigacji. Dokładność startu z noclegu zależy od tekstu (U14 – zaakceptowane).

**Koszty:** 0 (bez zmian; brak API Maps i chmury).

**Dane osobowe i zgodność:**
- **D7 (lokalizacja bieżąca) wypada z rejestru** – Tamitu jej nie przetwarza. D8 zostaje (tekst celu i startu
  w linku, bez współrzędnych).
- Odpadają: SEC-12 (test braku zapisu współrzędnych), część SEC-13 (uzasadnienie uprawnienia lokalizacji w Play),
  T12 po stronie Tamitu, T16 dla `geolocator`.
- Google Play: w Data Safety Tamitu **nie deklaruje** zbierania lokalizacji (ani przybliżonej, ani dokładnej);
  brak deklaracji uprawnień lokalizacji. Zmiany w rejestrze, modelu zagrożeń, `privacy-checklist.md` i polityce
  prywatności wykonuje security (zgłoszone orkiestratorowi w TAM-107).
- Wymagania: US-007 i S6 („dokładna lokalizacja”) do aktualizacji przez analityka – start „Moja lokalizacja” bez
  uprawnienia w Tamitu. EK-09/EK-10 – UX (TAM-108).

**Odrzucone / odłożone:** A i B – odrzucone (uprawnienie wrażliwe bez korzyści dla użytkownika wobec C). D (inne
aplikacje mapowe, `geo:`) – odłożone po MVP, zadanie TAM-106.

**Zmiana tej decyzji** (np. powrót do odczytu pozycji w Tamitu) wymaga nowego ADR, wpisu D7 w rejestrze i przeglądu
security.
