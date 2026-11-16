# Komponent: CMP-08 Chip filtra

- Status: szkic
- Autor: ux · Data: 2026-11-16 · Wersja: 0.1
- Odpowiednik Material 3 / Flutter: Filter chip / `FilterChip` w `Wrap`

## Cel
Wielokrotny wybór z zamkniętej listy: zainteresowania (11 pozycji, 0–5 wybranych) w EK-05.
Nie służy do: pojedynczego wyboru (CMP-07/CMP-10), działań, wolnego tekstu (brak w MVP).

## Warianty
| Wariant | Kiedy użyć | Uwagi |
|---|---|---|
| Grupa z limitem | zainteresowania | licznik „Wybrano {n} z 5" nad grupą |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | obrys `outlineVariant`, tekst `onSurfaceVariant` |
| Wybrany | tło `secondaryContainer`, tekst `onSecondaryContainer`, znacznik wyboru z lewej, rysowany przez `FilterChip` (znaczenie nie tylko kolorem) |
| Fokus / naciśnięty | warstwa stanu 10% |
| Nieaktywny | po wybraniu 5: niewybrane chipy 38% i niedostępne; komunikat przy liczniku „Możesz wybrać maks. 5" |
| Ładowanie | n/d |
| Błąd | n/d (limit wymuszony przez blokadę, nie przez błąd) |

## Rozmiary i odstępy
Wysokość 32 dp wizualnie, cel dotyku 48 dp (pionowo); wnętrze 12 dp (z ikoną 8 dp); odstęp poziomy i pionowy 8 dp; **zawijanie do kolejnych wierszy** (bez przewijania poziomego).

## Tokeny
`outlineVariant`, `secondaryContainer`, `onSecondaryContainer`; tekst `labelLarge`; kształt `shape-s`.

## Zachowanie
Dotknięcie przełącza wybór (animacja ikony short4). Kolejność chipów stała (wg listy z modelu danych).
Pusty wybór jest poprawny (= zwiedzanie ogólne) – podpowiedź: „Nie wybierzesz nic – zaplanujemy ogólne zwiedzanie".

## Dostępność
- Etykieta dla TalkBack: „Lokalne jedzenie, pole wyboru, zaznaczone"; nagłówek grupy z licznikiem.
- Cel dotyku 48 dp.
- Kontrast: onSecondaryContainer/secondaryContainer ≥ 7,2:1; onSurfaceVariant/surface ≥ 8,8:1. Obrys `outlineVariant` jest dekoracyjny – granicę celu wyznacza tekst (kryterium 1.4.11 spełnia tekst i ikona stanu).
- Skalowanie do 200%: chipy zawijają tekst i wiersze.

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `tripFormInterestsCounter` | Wybrano {count} z 5 | {count} of 5 selected |
| `tripFormInterestsMax` | Możesz wybrać maks. 5 | You can select up to 5 |
| `tripFormInterestsEmptyHelper` | Nie wybierzesz nic – zaplanujemy ogólne zwiedzanie | Select none for general sightseeing |

Etykiety 11 zainteresowań – w `screens/` (krok 2).

## Użycie
EK-05; wzorzec formularz.
