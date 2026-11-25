# QA TAM-24 (P3-11): link Google Maps bez punktu startowego (wariant C)

- Rola: qa · Data: 2026-11-25 · Zadanie: [TAM-24](https://tadecode.atlassian.net/browse/TAM-24)
- Pytanie: Q1 (`docs/open-questions.md`), ADR-0007 (Aneks A pkt 2), ekrany EK-09 i EK-10, US-007
- **Rekomendacja: wariant C dla MVP** (link bez `origin` przy starcie „Moja lokalizacja”). Tamitu nie potrzebuje
  wtedy żadnego uprawnienia lokalizacji ani ekranu EK-10. Decyzja należy do właściciela; zmiana wymaga ADR zastępującego.

## Po co ten test

Właściciel wybrał dokładną lokalizację (wariant A), ale chciał najpierw sprawdzić prostszy wariant C. W wariancie C
Tamitu nie odczytuje pozycji telefonu. Otwiera tylko link do Google Maps bez punktu startowego, a Mapy same biorą
bieżącą pozycję. Test miał odpowiedzieć, czy to naprawdę działa na telefonie i co widzi użytkownik, gdy Mapy nie
mają dostępu do lokalizacji.

## Jak testowano

- Telefon: OnePlus CPH2145, Android 13, Google Maps 26.47 (domyślna aplikacja dla linków `google.com/maps`).
- Bez kodu aplikacji: link otwierany intencją systemową, tak samo jak zrobi to `url_launcher`
  w trybie `externalApplication`:
  `adb shell am start -a android.intent.action.VIEW -d "https://www.google.com/maps/dir/?api=1&destination=<cel>&travelmode=<tryb>"`.
- Dostęp do telefonu przez `.farm/test-lock.ps1 -Resource device`. Skrypty były w `.farm/tmp/tam24/` (poza repozytorium).
- Wynik odczytywany z tekstu interfejsu (`uiautomator dump`): pole startu, cel, wybrany tryb, aktywne okno.
  **Bez zrzutów ekranu.** Surowe zrzuty tekstu zawierały prywatne dane z konta Google na telefonie (zapisane miejsca,
  historia) i zostały usunięte zaraz po analizie. Raport nie podaje pozycji telefonu, adresów, odległości ani czasów
  przejazdu.
- Cele (publiczne obiekty): „Zamek Królewski na Wawelu, Kraków”, te same współrzędne bez nazwy, „Zamek Królewski
  w Warszawie, Plac Zamkowy 4, Warszawa”. Fikcyjny nocleg do porównania: „Hotel Bristol, Warszawa”.
- Stan telefonu przed testem i po nim: lokalizacja włączona, Mapy z uprawnieniem do lokalizacji.
  Na czas scenariuszy 4 i 5 lokalizację wyłączono albo odebrano Mapom uprawnienie. Potem przywrócono stan
  sprzed testu (`cmd location set-location-enabled true`, `pm grant` dla FINE/COARSE/BACKGROUND) i sprawdzono go
  przez `dumpsys package`.
- Bez wywołań modelu AI i bez kosztów (Maps URLs nie wymaga klucza API).

## Wyniki

### 1. Wariant C: bez `origin`, Mapy mają dostęp do lokalizacji

| Cel | Tryb | Start w Mapach | Cel w Mapach | Trasa | Wynik |
|---|---|---|---|---|---|
| Wawel (nazwa, miasto) | `driving` | „Twoja lokalizacja” | Zamek Królewski na Wawelu | tak, z wariantami, przycisk „Rozpocznij” | ✅ |
| Wawel (nazwa, miasto) | `transit` | „Twoja lokalizacja” | Zamek Królewski na Wawelu | tak, połączenia z godzinami odjazdu | ✅ |
| Wawel (nazwa, miasto) | `walking` | „Twoja lokalizacja” | Zamek Królewski na Wawelu | tak, przycisk „Rozpocznij” | ✅ |
| Zamek w Warszawie (nazwa, adres) | `transit` | „Twoja lokalizacja” | Zamek Królewski w Warszawie | tak | ✅ |
| Wawel (nazwa + współrzędne w jednym tekście) | `walking` | „Twoja lokalizacja” | Zamek Królewski na Wawelu | tak | ✅ |
| Wawel (same współrzędne) | `driving` | „Twoja lokalizacja” | **pobliski inny obiekt** (apartament przy tym samym adresie) | tak, ale do innej nazwy | ⚠️ |

Wnioski:
- Każdy tryb (`driving`, `transit`, `walking`) otwiera się od razu jako trasa, z zaznaczonym trybem i startem
  „Twoja lokalizacja”. Użytkownik nie musi nic wpisywać.
- `destination` jako tekst „nazwa, miejscowość” działa najlepiej. To już obowiązuje (ADR-0007). Same współrzędne
  mogą pokazać jako cel sąsiedni obiekt o innej nazwie. Nie używać ich jako jedynego celu.
- Z startem „Twoja lokalizacja” Mapy od razu oferują nawigację („Rozpocznij”).

### 2. Porównanie: z `origin` = nocleg (punkt startowy dnia)

| Tryb | Start w Mapach | Cel | Trasa | Wynik |
|---|---|---|---|---|
| `driving` | „Bristol” (rozpoznany z tekstu) | Zamek Królewski w Warszawie | tak; przycisk „Podgląd” zamiast „Rozpocznij” | ✅ |
| `transit` | „Bristol” | Zamek Królewski w Warszawie | tak; przy krótkim dystansie Mapy podpowiadają też pieszo i hulajnogę | ✅ |
| `walking` | „Bristol” | Zamek Królewski w Warszawie | tak; „Podgląd” | ✅ |

Starty „Nocleg” i „Poprzedni punkt dnia” z EK-09 działają tak samo w obu wariantach (A i C), bo to tekst z planu,
a nie pozycja telefonu. Gdy start nie jest bieżącą pozycją, Mapy pokazują podgląd trasy, a nie nawigację. To
zachowanie Map, nie błąd.

### 3. Lokalizacja w telefonie wyłączona (bez `origin`)

| Krok | Co widzi użytkownik | Wynik |
|---|---|---|
| Otwarcie linku (`driving`, `walking`, `transit`) | Okno usług Google: „Aby kontynuować, urządzenie musi skorzystać z ustawienia Dokładność lokalizacji”, przyciski „Nie, dziękuję” / „Włącz” | ✅ czytelne, to okno Google, nie Tamitu |
| „Nie, dziękuję” | Ekran trasy Map z ustawionym celem i pustym startem „Wybierz lokalizację początkową” (do wyboru: wyszukiwanie, zapisane miejsca, historia, punkt na mapie) | ✅ cel zachowany, użytkownik sam wybiera start |
| „Włącz” | nie testowano (zmieniłoby ustawienia telefonu) | – |

### 4. Mapy bez uprawnienia do lokalizacji (bez `origin`)

| Krok | Co widzi użytkownik | Wynik |
|---|---|---|
| Otwarcie linku (`driving`, `transit`, `walking`) | Systemowa prośba Androida **dla aplikacji Mapy**: „Zezwolić aplikacji Mapy na dostęp do lokalizacji urządzenia?” (Dokładna / Przybliżona; Podczas używania aplikacji / Tylko tym razem / Nie zezwalaj) | ✅ prośbę obsługują Mapy, nie Tamitu |
| „Nie zezwalaj” | Mapy pokazują wybór punktu startowego („Wybierz miejsce na mapie”, zapisane miejsca, historia) | ✅ użytkownik może podać start ręcznie |
| Ponowne otwarcie linku po odmowie | Od razu wybór punktu startowego, bez kolejnej prośby | ✅ bez zapętlenia |
| „Podczas używania” / „Tylko tym razem” | nie testowano osobno (to stan z scenariusza 1) | – |

### 5. Przeglądarka zamiast aplikacji Map

Link otwarty jawnie w Chrome (`-p com.android.chrome`) i tak trafił do aplikacji Mapy (Chrome przekazuje linki
`google.com/maps` do zainstalowanej aplikacji). Wynik jak w scenariuszu 1. **Przypadku „telefon bez aplikacji Map”
nie sprawdzono**, bo wymagałby wyłączenia Map w telefonie (trwała zmiana). Ryzyko jest niskie: Mapy są
preinstalowane na urządzeniach z usługami Google, a strona `google.com/maps` sama prosi przeglądarkę o lokalizację.
Do sprawdzenia przy teście wydania na emulatorze bez Map, jeśli właściciel uzna to za potrzebne.

## Czego wymaga każdy wariant od Tamitu

| Obszar | Wariant C (link bez `origin`) | Wariant A (dokładna lokalizacja) |
|---|---|---|
| Uprawnienia w manifeście | brak (tylko `INTERNET` i `<queries>` dla `VIEW https`) | `ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION`, test listy uprawnień w CI |
| Pakiety | `url_launcher` | `url_launcher` + `geolocator` (weryfikacja manifestu po dodaniu, T16) |
| Ekrany | EK-09 z opisem `routeFromMyLocationHintC`; **EK-10 wypada** | EK-09 ze stanami „Ustalamy pozycję…”, odmowa, odmowa trwała, brak pozycji, „Anuluj”; EK-10 |
| Odczyt pozycji | brak; start „Moja lokalizacja” = link bez `origin` | jednorazowy `getCurrentPosition` (10 s), anulowanie, porzucanie wyniku |
| Dane osobowe | Tamitu nie przetwarza lokalizacji (wpis D7 wypada) | D7: współrzędne w pamięci, testy braku zapisu (SEC-12) |
| Google Play | brak deklaracji lokalizacji w Data Safety (za Tamitu) | Data Safety i uzasadnienie uprawnienia (SEC-13) |
| Polityka prywatności | link do Google Maps (D8: cel, nocleg); lokalizację obsługuje Google w swojej aplikacji | jak C, plus opis przekazania współrzędnych Google w linku (T12) |
| Testy | budowa URL bez `origin` (test jednostkowy), ręczne otwarcie w Mapach | jak C, plus uprawnienia, odmowa, „tylko przybliżona”, limit czasu, anulowanie, brak zapisu |
| Ryzyko | prośbę o lokalizację pokazują Mapy, poza kontrolą Tamitu; teksty ekranu informują o tym | wrażliwe uprawnienie, więcej kodu i stanów błędów |

Różnica dla użytkownika: w A zgodę na lokalizację daje Tamitu (EK-10 i prośba systemowa), a w C daje ją Mapom
(zwykle już ją mają). Wynik jest ten sam: trasa z bieżącej pozycji. W C dochodzi jedna korzyść: Mapy oferują
od razu nawigację.

## Rekomendacja

**Wariant C dla MVP.** Spełnia wizję („link z bieżącej lokalizacji albo z punktu startowego; auto, komunikacja,
pieszo”). Działa w każdym trybie. Gdy brak zgody lub lokalizacji, Mapy obsługują to same i zachowują cel. Tamitu nie
musi prosić o wrażliwe uprawnienie, więc znikają EK-10, `geolocator`, D7, SEC-12 i część SEC-13. Zgadza się to też
z rekomendacją security. Warunek: start w linku i cel jako tekst „nazwa, miejscowość”, nie same współrzędne.

Zastrzeżenia: test na jednym telefonie (Android 13, Mapy 26.47); nie sprawdzono telefonu bez aplikacji Map ani
przycisku „Włącz” w oknie lokalizacji.

## Co dalej (do decyzji właściciela)

1. Właściciel: decyzja Q1 – przejście z A na C.
2. Po zgodzie, architect: ADR zastępujący część „lokalizacja” ADR-0007 (opcja C; zostają: format linku, `destination` jako
   tekst, `externalApplication`, `<queries>`, minSdk). Wynik testu jako aneks do ADR-0007 (Aneks A pkt 2).
3. analyst: US-007 i S6 (scope.md) – „Moja lokalizacja” bez uprawnienia w Tamitu.
4. ux: EK-09 – stan „Wariant C” jako domyślny, usunięcie stanów odczytu pozycji i odmowy; EK-10 do archiwum; U11 do zamknięcia.
5. security: rejestr danych – D7 wypada; privacy-checklist (uprawnienie, Data Safety).
