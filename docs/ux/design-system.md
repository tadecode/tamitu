# Design system Tamitu (Material 3)

- Status: wariant marki wybrany przez właściciela 2026-11-16: **A „Lazur"** (UX1). Wersja 0.2 (ux, P3-14b krok 2); tokeny wariantu B usunięte (opis w `brand.md`, aneks).
- Wersja 0.3 (2026-11-16): jasny motyw przyciemniony – tła z tonu ok. 98 na ok. 93 (uwaga właściciela: „jasna wersja jest za biala razi po oaczach za mocno”); `secondaryContainer` przyciemniony, by komunikaty odcinały się od tła. Ciemny motyw bez zmian.
  nigdy do wartości (hex, px). Zero wartości „na oko".

## 1. Fundament

- **Material 3** (Material Design 3) – motyw aplikacji zbudowany na `ThemeData` z `useMaterial3: true`.
- **Schemat kolorów wpisany jawnie** (wszystkie role z pkt 2 jako stałe), a nie generowany w czasie działania
  z koloru bazowego: generator Fluttera (`ColorScheme.fromSeed`) może dać wartości różne od sprawdzonych tu
  pod kątem kontrastu. Kolor bazowy (seed) podajemy dla porządku i dla narzędzi projektowych.
- **Dwa motywy:** jasny i ciemny; wybór wg ustawienia systemu (propozycja UX4).
- **Kolory dynamiczne Androida wyłączone** (propozycja UX3).
- Nazwy tokenów = nazwy ról M3 (`primary`, `onSurfaceVariant`…) i stylów tekstu M3 (`titleMedium`…),
  aby developer mapował je 1:1 na `ColorScheme` i `TextTheme`.

## 2. Kolory – role M3

### 2.1 Role kolorów – wariant A „Lazur" (seed `#006A6A`)

| Rola | Jasny | Ciemny |
|---|---|---|
| primary | `#006A6A` | `#80D5D4` |
| onPrimary | `#EEF4F3` | `#003737` |
| primaryContainer | `#9CF1F0` | `#004F4F` |
| onPrimaryContainer | `#002020` | `#9CF1F0` |
| secondary | `#4A6363` | `#B0CCCB` |
| onSecondary | `#FFFFFF` | `#1B3534` |
| secondaryContainer | `#C4E2E1` | `#324B4B` |
| onSecondaryContainer | `#051F1F` | `#CCE8E7` |
| tertiary | `#8F4C38` | `#FFB5A0` |
| onTertiary | `#FFFFFF` | `#561F0F` |
| tertiaryContainer | `#FFDBD1` | `#723523` |
| onTertiaryContainer | `#3A0B01` | `#FFDBD1` |
| error | `#BA1A1A` | `#FFB4AB` |
| onError | `#FFFFFF` | `#690005` |
| errorContainer | `#FFDAD6` | `#93000A` |
| onErrorContainer | `#410002` | `#FFDAD6` |
| surface | `#E6EDEC` | `#0E1514` |
| onSurface | `#161D1D` | `#CFD6D5` |
| onSurfaceVariant | `#3F4948` | `#BEC9C8` |
| surfaceContainerLowest | `#FFFFFF` | `#090F0F` |
| surfaceContainerLow | `#DFE6E5` | `#161D1D` |
| surfaceContainer | `#DAE1E0` | `#1A2121` |
| surfaceContainerHigh | `#D5DCDB` | `#252B2B` |
| surfaceContainerHighest | `#DDE4E3` | `#303636` |
| outline | `#6F7979` | `#889392` |
| outlineVariant | `#BEC9C8` | `#3F4948` |
| inverseSurface | `#2B3231` | `#DDE4E3` |
| onInverseSurface | `#ECF2F1` | `#2B3231` |
| inversePrimary | `#80D5D4` | `#006A6A` |
| scrim / shadow | `#000000` | `#000000` |

### 2.2 Znaczenie ról w Tamitu (wspólne dla wariantów)

| Znaczenie | Role | Przykład |
|---|---|---|
| Główne działanie ekranu (jedno) | primary / onPrimary | „Generuj plan", „Zaloguj przez Google" |
| Ważne, ale drugorzędne | primaryContainer, secondaryContainer | FAB „Nowa podróż", przycisk tonalny |
| Wybór (zaznaczony) | secondaryContainer / onSecondaryContainer | wybrany chip zainteresowania, segment „Lot" |
| Informacja (neutralna) | secondaryContainer + ikona `info` | „Plan stworzony przez AI…", „Plany są tylko na tym urządzeniu" |
| Akcent podróżniczy (oszczędnie) | tertiary, tertiaryContainer | godzina przylotu/przyjazdu, znacznik pory dnia |
| Ostrzeżenie / błąd / destrukcja | error, errorContainer + ikona | błąd pola, „Usuń konto", baner braku sieci przy akcji |
| Tło ekranu | surface | |
| Karty, arkusze, dialogi (warstwy) | surfaceContainerLow … Highest | karta planu: Low; arkusz dolny: Low; dialog: High; pola są outlined (tło = tło rodzica) |
| Tekst główny / pomocniczy | onSurface / onSurfaceVariant | tytuł / data, podpowiedź pola |
| Obrysy | outline (interaktywne), outlineVariant (dekoracyjne separatory) | obrys pola i checkboxa / separator listy |
| Snackbar | inverseSurface, onInverseSurface, inversePrimary (akcja) | „Plan usunięto · Cofnij" |

Brak osobnej roli „sukces" (zielony): potwierdzenia przekazuje snackbar z tekstem; w wariancie A zieleń
myliłaby się z primary. Ostrzeżenia, które nie są błędem, używają `secondaryContainer` z ikoną `warning`
(np. „Wylogowanie: plany zostają na urządzeniu").

### 2.3 Warstwy stanu (state layers) M3
Nakładka koloru treści (`on…`) o nieprzezroczystości: najechanie 8%, fokus 10%, naciśnięcie 10%,
przeciąganie 16%. Element nieaktywny: treść `onSurface` 38%, kontener `onSurface` 12%.
Wartości standardowe M3, bez zmian.

## 3. Typografia

Skala M3 (rozmiar / wysokość linii w sp, grubość). Wszystkie rozmiary w **sp** – skalują się z ustawieniem
systemu do 200%.

| Styl | Rozmiar / linia | Grubość | Krój | Użycie w Tamitu |
|---|---|---|---|---|
| displaySmall | 36 / 44 | 400 | Roboto | znak słowny na ekranie startowym (EK-02) |
| headlineMedium | 28 / 36 | 400 | Roboto | tytuł ekranu pełnoekranowego stanu (rzadko) |
| headlineSmall | 24 / 32 | 400 | Roboto | tytuł dialogu, tytuł stanu pustego/błędu |
| titleLarge | 22 / 28 | 400 | Roboto | tytuł w pasku górnym |
| titleMedium | 16 / 24 | 500 | Roboto | tytuł karty planu, nagłówek sekcji formularza, nazwa punktu planu |
| titleSmall | 14 / 20 | 500 | Roboto | nagłówek grupy w Ustawieniach |
| bodyLarge | 16 / 24 | 400 | Roboto | treść zgód, opis punktu planu, tekst w polu |
| bodyMedium | 14 / 20 | 400 | Roboto | tekst pomocniczy, opis w liście, komunikaty |
| bodySmall | 12 / 16 | 400 | Roboto | podpowiedź i błąd pod polem, licznik znaków |
| labelLarge | 14 / 20 | 500 | Roboto | przyciski, zakładki dni, segmenty |
| labelMedium | 12 / 16 | 500 | Roboto | chipy, znacznik godziny |
| labelSmall | 11 / 16 | 500 | Roboto | odznaki (rzadko; nie dla treści istotnej) |

Zasady: najmniejszy tekst z treścią istotną = bodySmall 12 sp; brak wersalików w treści (tylko etykiety
krótsze niż 3 słowa mogą mieć wielką literę na początku – zwykła pisownia zdaniowa); maks. ~70 znaków
w linii na szerszych oknach (`layout.md`).

## 4. Odstępy

Skala 4 dp, rytm 8 dp. Dozwolone wartości (tokeny):

| Token | dp | Typowe użycie |
|---|---|---|
| `space-1` | 4 | odstęp ikona–tekst w małych elementach, tekst pod polem |
| `space-2` | 8 | między chipami, między przyciskami w grupie, min. odstęp celów dotyku |
| `space-3` | 12 | wnętrze chipa/segmentu, między wierszami w karcie |
| `space-4` | 16 | **margines ekranu**, wnętrze karty, między polami formularza |
| `space-6` | 24 | między sekcjami, wnętrze dialogu |
| `space-8` | 32 | duże przerwy (np. nad stanem pustym) |
| `space-12` | 48 | przerwa przed głównym działaniem na ekranach pełnej treści, wysokość celu dotyku |

## 5. Kształty (promienie)

| Token M3 | dp | Komponenty |
|---|---|---|
| `shape-none` | 0 | pasek górny, pełnoekranowe arkusze |
| `shape-xs` | 4 | snackbar, pole tekstowe (outlined), menu |
| `shape-s` | 8 | chip, odznaka godziny |
| `shape-m` | 12 | karta, komunikat (notice) |
| `shape-l` | 16 | FAB rozszerzony |
| `shape-xl` | 28 | dialog, arkusz dolny (górne rogi) |
| `shape-full` | pełne | przyciski, przyciski segmentowe, przełączniki |

## 6. Wysokość (elevation)

M3 rozróżnia warstwy przede wszystkim **kolorem kontenera (tonal)**, cień tylko tam, gdzie element unosi się nad treścią.

| Poziom | dp | Komponenty |
|---|---|---|
| 0 | 0 | tło, karty (filled), pola, pasek górny w spoczynku |
| 1 | 1 | arkusz dolny (modalny) |
| 2 | 3 | pasek górny po przewinięciu treści (zmiana koloru na surfaceContainer) |
| 3 | 6 | FAB, dialog, snackbar, menu |
| 4–5 | 8–12 | nie używamy |

## 7. Ruch (motion)

- Krzywe M3: standard `cubic-bezier(0.2, 0, 0, 1)`; emphasized decelerate `cubic-bezier(0.05, 0.7, 0.1, 1)` (wejście), emphasized accelerate `cubic-bezier(0.3, 0, 0.8, 0.15)` (wyjście).
- Czasy: short2 100 ms (stany przycisków), short4 200 ms (chip, checkbox), medium2 300 ms (snackbar, arkusz), medium4 400 ms (przejście między ekranami), long2 500 ms (maks.).
- Przejście między ekranami: domyślne dla Androida (M3 „shared axis" / przejście predykcyjne wstecz).
- **Ustawienie systemowe „usuń animacje" wyłącza animacje dekoracyjne**; wskaźniki postępu pozostają (informacja).

## 8. Ikony

- **Zestaw: Hugeicons, darmowy zestaw „Stroke Rounded" (Free)** – decyzja właściciela 2026-11-16 (UX14: „tak zastapić odrazu”); zastępuje Material Symbols. Tylko zestaw darmowy, **bez Pro**.
- **Licencja (sprawdzona 2026-11-16 przez ux u źródeł, UX15):** zestaw darmowy (Stroke Rounded, 6000+ ikon) i pakiet Flutter `hugeicons` (4.4.0, zweryfikowany wydawca hugeicons.com) są na **licencji MIT** – użycie komercyjne w aplikacji zamkniętej dozwolone, bez kont i kluczy. Warunki: (1) dołączyć noty MIT do ekranu licencji open source aplikacji – **obie**, bo się różnią: „Copyright (c) 2025 Hugeicons" (repozytorium) i „Copyright (c) 2024 Halal Labs" (pakiet Flutter); (2) nie udostępniać ikon użytkownikom jako osobnego zestawu do pobrania; (3) nie sugerować poparcia przez Hugeicons (znak towarowy poza licencją). Zestaw Pro – osobna, płatna umowa; nie używamy. Źródła: pub.dev/packages/hugeicons, github.com/hugeicons/hugeicons (LICENSE.md, packages/flutter/LICENSE), hugeicons.com/license-agreement (wersja z 14.09.2026).
- **Do potwierdzenia przez architekta:** wpis zależności w ADR-0008, sprawdzenie, że pakiet nie zawiera ikon Pro (archiwum pakietu nie było przeglądane), wykonalność podmian z pkt 8.1. Makiety nadal używają własnych, uproszczonych odpowiedników (pliki ikon nie trafiają do dokumentacji).
- Styl: kreska 1,5 dp, zaokrąglone zakończenia i narożniki, bez wypełnienia; siatka 24 dp. Stan aktywny (np. wybrany segment) sygnalizuje kontener i znacznik `tick-02`, nie wypełniona wersja ikony (zestaw Free jej nie zapewnia w tym stylu).
- Rozmiary: 24 dp (standard), 18 dp (wewnątrz przycisku/chipa), 48 dp (stan pusty/błędu). Przy 18 dp kreska 1,5 dp jest cienka – kontrast ikony liczony jak dla elementu interfejsu (≥ 3:1) jest spełniony kolorem (`onSurfaceVariant`/`surface` 7,8:1), ale qa sprawdza czytelność na urządzeniu.
- Kolor: dziedziczy z roli treści (`onSurfaceVariant` w liście, `on…Container` w kontenerach).
- Ikona nigdy nie jest jedynym nośnikiem znaczenia: obok jest tekst albo etykieta dla TalkBack.
- Słownik ikon. **Znaczenie** (pierwsza kolumna) jest stałym identyfikatorem w specyfikacjach; nazwy Hugeicons to propozycja z katalogu Free – mobile-dev potwierdza dokładną nazwę (sufiks, np. `-01`/`-02`) w katalogu przy implementacji, bez zmiany znaczenia.

| Znaczenie | Hugeicons Free (Stroke Rounded) | Dawniej (Material Symbols) |
|---|---|---|
| Nowa podróż | `add-01` | `add` |
| Ustawienia | `settings-02` | `settings` |
| Wstecz | `arrow-left-01` | `arrow_back` |
| Więcej opcji | `more-vertical` | `more_vert` |
| Usuń | `delete-02` | `delete` |
| Trasa | `route-02` | `directions` |
| Otwórz na zewnątrz (Maps, polityka) | `link-square-02` | `open_in_new` |
| Auto / komunikacja / pieszo | `car-01`, `bus-01`, `walking` | `directions_car`, `directions_transit`, `directions_walk` |
| Lot / przylot | `airplane-landing-01` | `flight_land` |
| Nocleg | `bed-double` | `hotel` |
| Moja lokalizacja | `gps-01` | `my_location` |
| Informacja o AI | `sparkles` | `auto_awesome` |
| Informacja | `information-circle` | `info` |
| Ostrzeżenie | `alert-02` | `warning` |
| Błąd | `alert-circle` | `error` |
| Brak sieci | `wifi-off-01` | `wifi_off` |
| Prywatność | `shield-01` | `shield` |
| Język | `globe-02` | `language` |
| Wyloguj | `logout-01` | `logout` |
| Usuń konto | `user-remove-01` | `person_remove` |
| Plany tylko na urządzeniu | `smart-phone-01` | `smartphone` |
| Limit dzienny, godzina | `clock-01` | `schedule` |
| Data | `calendar-03` | `calendar_today` |
| Rozwiń listę | `arrow-down-01` | `arrow_drop_down` |
| Wybrane (segment) | `tick-02` | `check` |
| Stan pusty listy planów | `luggage-01` | `luggage` |
| Aktualizacja aplikacji | `reload` | `system_update` |

### 8.1 Ikony wbudowane w widgety Material 3

Część widgetów M3 rysuje własne ikony Material. Zasada: **podmieniamy w motywie lub parametrze tam, gdzie Flutter na to pozwala; tam, gdzie nie – zostaje wyjątek** (spójność ważniejsza niż własny kod widgetów).

| Widget (komponent) | Wbudowany element | Decyzja |
|---|---|---|
| `AppBar` – przycisk wstecz (CMP-01) | ikona strzałki | **podmiana** w motywie (ikona przycisku wstecz) na `arrow-left-01` |
| `DropdownMenu` (CMP-05) | strzałka rozwijania | **podmiana** parametrem ikony końcowej na `arrow-down-01` |
| `SegmentedButton` (CMP-07) | znacznik wybranego segmentu | **podmiana** (ikona wybranego) na `tick-02` |
| `Checkbox` (CMP-09), `FilterChip` (CMP-08) | znacznik zaznaczenia | **bez zmian** – to rysowany kształt, nie ikona z zestawu; wygląda neutralnie |
| `Radio` (CMP-10) | kółko | bez zmian (rysowany kształt) |
| `PopupMenuButton` / menu (EK-08) | „więcej" | **podmiana** ikony na `more-vertical` |
| `showDatePicker` (CMP-06) | strzałki miesięcy, przełącznik kalendarz/klawiatura | **wyjątek**: zostają ikony Material (brak prostej podmiany w motywie); widoczne tylko w oknie wybieraka |
| `showTimePicker` (CMP-06) | przełącznik tarcza/klawiatura | **wyjątek**: jak wyżej |
| Okna systemu Android (uprawnienia, wybór konta Google) | – | nie nasze ekrany |

Gdyby architekt uznał podmianę za zbyt kosztowną w którymś miejscu, dopisujemy go do wyjątków (bez zmiany specyfikacji ekranów – znaczenie ikony zostaje).

## 9. Mapowanie na Fluttera (bez kodu)

| Token | Miejsce w motywie |
|---|---|
| Role kolorów (pkt 2) | `ColorScheme` (jasny i ciemny), wpisane jawnie |
| Typografia (pkt 3) | `TextTheme` (Roboto – domyślna, bez dodatkowych zasobów) |
| Kształty (pkt 5) | motywy komponentów (`FilledButtonThemeData`, `CardTheme`, `DialogTheme`, `InputDecorationTheme`…) |
| Odstępy (pkt 4) | stałe w kodzie (np. klasa z wartościami 4…48) – nazwy do uzgodnienia z mobile-dev |
| Ikony (pkt 8) | Hugeicons Free Stroke Rounded – pakiet do potwierdzenia przez architekta (UX15); zestaw dołączony do aplikacji, bez pobierania z sieci; podmiany w motywach wg pkt 8.1 |

Szczegóły techniczne (nazwy klas, pakiety) decyduje mobile-dev/architekt; ux podaje tylko wartości.
