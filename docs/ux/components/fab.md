# Komponent: CMP-03 Przycisk pływający rozszerzony

- Status: szkic
- Autor: ux · Data: 2026-11-16 · Wersja: 0.1
- Odpowiednik Material 3 / Flutter: Extended FAB / `FloatingActionButton.extended`

## Cel
Główne działanie ekranu listy: „Nowa podróż" na EK-04. Zawsze w zasięgu kciuka.
Nie służy do: działań na innych ekranach (tam CMP-02), działań destrukcyjnych.

## Warianty
| Wariant | Kiedy użyć | Uwagi |
|---|---|---|
| Rozszerzony (ikona + tekst) | domyślnie | `add-01` + „Nowa podróż" |
| Zwinięty (sama ikona) | nie używamy w MVP | tekst pomaga nowym użytkownikom; przy przewijaniu FAB **nie** zwija się |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | `primaryContainer` / `onPrimaryContainer`, elevation 3 |
| Fokus / naciśnięty | warstwa stanu 10%, elevation 3 |
| Nieaktywny | nie występuje: „Nowa podróż" zawsze dostępna (limit sprawdzany przy generowaniu – macierz EK-04) |
| Ładowanie | n/d |
| Błąd | n/d |

W stanie pustym EK-04 FAB jest **ukryty**, a to samo działanie pokazuje CMP-18 jako przycisk wypełniony
(jedno główne działanie na ekranie).

## Rozmiary i odstępy
Wysokość 56 dp; wnętrze 16 dp, ikona 24 dp, odstęp ikona–tekst 12 dp; 16 dp od prawej i dolnej krawędzi obszaru bezpiecznego.

## Tokeny
`primaryContainer`, `onPrimaryContainer`; tekst `labelLarge`; kształt `shape-l`; elevation 3.

## Zachowanie
Pojawia się z animacją skali (medium2) przy wejściu na ekran. Snackbar wyświetla się nad FAB.
Długi tekst PL mieści się (do ~20 znaków); przy skali 200% FAB rośnie w pionie.

## Dostępność
- Etykieta dla TalkBack: „Nowa podróż" (przycisk).
- Cel 56 dp; w kolejności fokusu ostatni (po liście).
- Kontrast onPrimaryContainer/primaryContainer ≥ 7,2:1.
- Skalowanie do 200%: tekst zawija się, nie zasłania ostatniej karty (dolny odstęp listy = wysokość FAB + 16 dp).

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `planListNewTrip` | Nowa podróż | New trip |

## Użycie
EK-04; wzorzec lista i szczegóły.
