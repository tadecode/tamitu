# Komponent: CMP-05 Pole wyboru z listy

- Status: szkic
- Autor: ux · Data: 2026-11-16 · Wersja: 0.1
- Odpowiednik Material 3 / Flutter: Exposed dropdown menu (outlined) / `DropdownMenu`

## Cel
Wybór jednej wartości z uporządkowanej listy liczb: liczba dni (1–14), liczba osób (1–10) w EK-05.
Wygląda jak pole tekstowe (spójność formularza). Nie służy do: 2–3 opcji (CMP-07), wielu wyborów (CMP-08), tekstu.

## Warianty
| Wariant | Kiedy użyć | Uwagi |
|---|---|---|
| Bez wartości (wymagane) | liczba dni | brak domyślnej – świadomy wybór (wymagane pole) |
| Z wartością domyślną | liczba osób (2) | pokazuje wartość domyślną z modelu danych |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | jak CMP-04, ikona `arrow-down-01` na końcu |
| Fokus / rozwinięte | obrys `primary`, menu pod polem (`surfaceContainer`, elevation 3), wybrana pozycja wyróżniona `secondaryContainer` |
| Nieaktywny | jak CMP-04 |
| Ładowanie | n/d |
| Błąd | jak CMP-04 („Wybierz liczbę dni") |

## Rozmiary i odstępy
Pole jak CMP-04; pozycje menu 48 dp; menu maks. 5,5 pozycji wysokości (widać, że przewija się); szerokość pola: pół szerokości wiersza (dwa pola obok siebie: dni | osoby), przy skali tekstu ≥ 150% – jedno pod drugim.

## Tokeny
Jak CMP-04; menu `surfaceContainer`, `shape-xs`, elevation 3; pozycja `bodyLarge`.

## Zachowanie
Dotknięcie otwiera menu; wybór zamyka. Bez wpisywania z klawiatury (tylko lista – mniej błędów).
Przewijanie menu do bieżącej wartości.

## Dostępność
- Etykieta dla TalkBack: „Liczba dni, wymagane, nie wybrano" / „Liczba osób, 2"; menu jako lista z wyborem.
- Cel dotyku pola i pozycji ≥ 48 dp.
- Kontrast jak CMP-04.
- Skalowanie do 200%: pola jedno pod drugim.

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `commonSelectRequiredError` | Wybierz wartość | Select a value |

## Użycie
EK-05; wzorzec formularz.
