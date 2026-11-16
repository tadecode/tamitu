# Komponent: CMP-07 Przyciski segmentowe

- Status: szkic
- Autor: ux · Data: 2026-11-16 · Wersja: 0.1
- Odpowiednik Material 3 / Flutter: Segmented button (jednokrotny wybór) / `SegmentedButton`

## Cel
Wybór jednej z 2–3 krótkich, równorzędnych opcji, widocznych naraz.
Nie służy do: więcej niż 3 opcji (CMP-10 lub CMP-05), wielokrotnego wyboru (CMP-08), działań (CMP-02).

## Warianty
| Wariant | Kiedy użyć | Uwagi |
|---|---|---|
| 2 opcje z ikoną | sposób dojazdu: Lot (`flight_land`) / Auto (`directions_car`) – EK-05; język interfejsu PL / EN – EK-02 | wymagane pole bez wartości domyślnej: żaden segment nie jest wybrany na start (dojazd) |
| 3 opcje | budżet (niski/średni/wysoki), tempo (spokojne/umiarkowane/intensywne), język planu – EK-05; tryb trasy (auto/komunikacja/pieszo) – EK-09 | domyślne z modelu danych: średni, umiarkowane, język UI |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny (niewybrany) | obrys `outline`, tekst `onSurface` |
| Wybrany | tło `secondaryContainer`, tekst `onSecondaryContainer`, ikona `check` przed tekstem (znaczenie nie tylko kolorem) |
| Fokus / naciśnięty | warstwa stanu 10% |
| Nieaktywny | 38% (np. tryb trasy bez sieci – nie: tryb można wybrać offline, blokowane jest dopiero otwarcie map) |
| Ładowanie | n/d |
| Błąd | brak wyboru w wymaganym polu: tekst błędu pod komponentem `bodySmall` `error` + ikona `error` |

## Rozmiary i odstępy
Wysokość 40 dp wizualnie, cel dotyku 48 dp; pełna szerokość wiersza, segmenty równej szerokości; etykieta sekcji (titleSmall) 8 dp nad komponentem.

## Tokeny
Obrys `outline`; wybrany `secondaryContainer`/`onSecondaryContainer`; tekst `labelLarge`; kształt `shape-full`.

## Zachowanie
Dotknięcie wybiera segment (animacja short4). Długie etykiety PL (np. „Intensywne", „Komunikacja") zawijają się
do 2 linii. **Przy skali tekstu ≥ 150% lub gdy etykiety się nie mieszczą, komponent z 3 opcjami przechodzi
w CMP-10 (lista jednokrotnego wyboru)** – ta sama semantyka, inny układ. Opis poziomów (np. tempo: „4–5 miejsc
dziennie") jako tekst pomocniczy pod komponentem dla wybranej opcji.

## Dostępność
- Etykieta dla TalkBack: „Tempo, Umiarkowane, wybrane, 2 z 3".
- Cel dotyku 48 dp; fokus po kolei przez segmenty.
- Kontrast onSecondaryContainer/secondaryContainer ≥ 7,2:1; outline/surface ≥ 4,2:1.
- Skalowanie do 200%: przejście na CMP-10.

## Teksty
Klucze ekranowe (wartości: `arrivalMode`, `budget`, `pace`, `planLanguage`, `travelMode`) – w `screens/` (krok 2).

## Użycie
EK-02, EK-05, EK-09; wzorzec formularz.
