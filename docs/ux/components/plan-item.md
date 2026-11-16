# Komponent: CMP-20 Punkt planu

- Status: szkic
- Autor: ux · Data: 2026-11-16 · Wersja: 0.2 (znacznik godziny zamiast pory dnia – kontrakt API zwraca `startTime`)
- Odpowiednik Material 3 / Flutter: brak gotowego widgetu; złożony z `ListTile`-podobnego układu (tekst, ikona), znacznika godziny (tekst `labelMedium` w `tertiaryContainer`) i `IconButton`/`TextButton` „Trasa". Uzasadnienie: plan to oś czasu (godziny), a `ListTile` nie ma znacznika czasu i działania drugorzędnego z etykietą. Koszt: niski (kompozycja widgetów M3).

## Cel
Jeden punkt dnia w planie (EK-08): orientacyjna godzina (`startTime`), nazwa miejsca, miejscowość, krótki opis, wejście do trasy (EK-09).
Nie służy do: edycji punktu (poza MVP), mapy (poza MVP).

## Warianty
| Wariant | Kiedy użyć | Uwagi |
|---|---|---|
| Punkt | domyślnie | znacznik godziny („ok. 15:00"), nazwa `titleMedium`, miejscowość `bodyMedium` `onSurfaceVariant`, opis `bodyMedium`, przycisk „Trasa" (`directions`) |
| Przylot / przyjazd | pierwszy element dnia 1 | ikona `flight_land`/`directions_car`, tekst „Przylot 14:30 · lotnisko LIS" z godziną w `tertiary`; bez przycisku trasy |
| Dzień bez punktów | dzień 1 przy późnym przylocie | tylko wariant przylotu + tekst „Dziś tylko dojazd do noclegu" – **nie** jako błąd |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | na `surface`, punkty połączone pionową linią osi czasu `outlineVariant` (dekoracyjna) |
| Fokus / naciśnięty | dotknięcie wiersza = dotknięcie „Trasa" (jeden cel główny); warstwa stanu na całym wierszu |
| Nieaktywny | „Trasa" bez sieci: przycisk aktywny, ale po dotknięciu komunikat (CMP-13 w arkuszu), bo wybór startu działa offline |
| Ładowanie | szkielet (CMP-17) |
| Błąd | n/d |

## Rozmiary i odstępy
Wnętrze 16 dp; znacznik godziny: wysokość 24 dp, wnętrze 8 dp, `shape-s`; między punktami 8 dp; przycisk „Trasa" cel 48 dp, wyrównany do prawej pod opisem.

## Tokeny
Znacznik: `tertiaryContainer`/`onTertiaryContainer`, `labelMedium`; nazwa `titleMedium` `onSurface`; opis `bodyMedium` `onSurfaceVariant`; oś `outlineVariant`; przycisk tekstowy `primary`.

## Zachowanie
Treść punktu (nazwa, opis) w **języku planu** – może różnić się od języka interfejsu; etykiety (prefiks godziny, „Trasa") w języku interfejsu. Opis zawija się bez limitu linii (to treść główna). Kolejność punktów wg godziny (rosnąco – gwarancja API). Godzina jest orientacyjna (prefiks „ok."/„approx."), bo plan tworzy AI.

## Dostępność
- Etykieta dla TalkBack: „Około 15:00. Oceanarium, Lizbona. {opis}. Przycisk: Trasa do Oceanarium"; język treści planu oznaczony (TalkBack przeczyta z właściwą wymową).
- Cel dotyku 48 dp.
- Kontrast: onTertiaryContainer/tertiaryContainer ≥ 7,2:1; onSurfaceVariant/surface ≥ 8,8:1; oś – dekoracyjna.
- Skalowanie do 200%: wszystko się zawija; znacznik godziny nad nazwą.

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `planRoute` | Trasa | Directions |
| `planRouteTo` | Trasa do {place} | Directions to {place} |
| `planArrivalFlight` | Przylot {time} | Arrival {time} |
| `planArrivalCar` | Przyjazd {time} | Arrival {time} |
| `planDayOnlyArrival` | Dziś tylko dojazd do noclegu | Today: just getting to your accommodation |
| `planItemTime` | ok. {time} | approx. {time} |

## Użycie
EK-08; wzorzec lista i szczegóły.
