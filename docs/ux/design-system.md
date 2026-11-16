# Design system Tamitu (Material 3)

- Status: wariant marki wybrany przez właściciela 2026-11-16: **A „Lazur"** (UX1). Wersja 0.2 (ux, P3-14b krok 2); tokeny wariantu B usunięte (opis w `brand.md`, aneks).
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
| onPrimary | `#FFFFFF` | `#003737` |
| primaryContainer | `#9CF1F0` | `#004F4F` |
| onPrimaryContainer | `#002020` | `#9CF1F0` |
| secondary | `#4A6363` | `#B0CCCB` |
| onSecondary | `#FFFFFF` | `#1B3534` |
| secondaryContainer | `#CCE8E7` | `#324B4B` |
| onSecondaryContainer | `#051F1F` | `#CCE8E7` |
| tertiary | `#8F4C38` | `#FFB5A0` |
| onTertiary | `#FFFFFF` | `#561F0F` |
| tertiaryContainer | `#FFDBD1` | `#723523` |
| onTertiaryContainer | `#3A0B01` | `#FFDBD1` |
| error | `#BA1A1A` | `#FFB4AB` |
| onError | `#FFFFFF` | `#690005` |
| errorContainer | `#FFDAD6` | `#93000A` |
| onErrorContainer | `#410002` | `#FFDAD6` |
| surface | `#F4FBFA` | `#0E1514` |
| onSurface | `#161D1D` | `#DDE4E3` |
| onSurfaceVariant | `#3F4948` | `#BEC9C8` |
| surfaceContainerLowest | `#FFFFFF` | `#090F0F` |
| surfaceContainerLow | `#EEF5F4` | `#161D1D` |
| surfaceContainer | `#E9EFEE` | `#1A2121` |
| surfaceContainerHigh | `#E3E9E9` | `#252B2B` |
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

- Zestaw: Material Symbols Outlined; grubość 400, grade 0, rozmiar optyczny 24.
- Rozmiary: 24 dp (standard), 18 dp (wewnątrz przycisku/chipa), 48 dp (stan pusty/błędu).
- Kolor: dziedziczy z roli treści (`onSurfaceVariant` w liście, `on…Container` w kontenerach).
- Ikona nigdy nie jest jedynym nośnikiem znaczenia: obok jest tekst albo etykieta dla TalkBack.
- Słownik ikon (nazwy Material Symbols):

| Znaczenie | Ikona |
|---|---|
| Nowa podróż | `add` |
| Ustawienia | `settings` |
| Wstecz | `arrow_back` |
| Usuń | `delete` |
| Trasa / otwórz w Google Maps | `directions`, `open_in_new` |
| Auto / komunikacja / pieszo | `directions_car`, `directions_transit`, `directions_walk` |
| Lot / przylot | `flight_land` |
| Nocleg | `hotel` |
| Moja lokalizacja | `my_location` |
| Informacja o AI | `auto_awesome` |
| Informacja | `info` |
| Ostrzeżenie | `warning` |
| Błąd | `error` |
| Brak sieci | `wifi_off` |
| Prywatność | `shield` |
| Język | `language` |
| Wyloguj | `logout` |
| Usuń konto | `person_remove` |
| Plany tylko na urządzeniu | `smartphone` |
| Limit dzienny | `schedule` |

## 9. Mapowanie na Fluttera (bez kodu)

| Token | Miejsce w motywie |
|---|---|
| Role kolorów (pkt 2) | `ColorScheme` (jasny i ciemny), wpisane jawnie |
| Typografia (pkt 3) | `TextTheme` (Roboto – domyślna, bez dodatkowych zasobów) |
| Kształty (pkt 5) | motywy komponentów (`FilledButtonThemeData`, `CardTheme`, `DialogTheme`, `InputDecorationTheme`…) |
| Odstępy (pkt 4) | stałe w kodzie (np. klasa z wartościami 4…48) – nazwy do uzgodnienia z mobile-dev |
| Ikony (pkt 8) | Material Symbols (zestaw ikon dołączony do aplikacji; bez pobierania z sieci) |

Szczegóły techniczne (nazwy klas, pakiety) decyduje mobile-dev/architekt; ux podaje tylko wartości.
