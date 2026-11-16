# Komponent: CMP-10 Lista jednokrotnego wyboru

- Status: szkic
- Autor: ux · Data: 2026-11-16 · Wersja: 0.1
- Odpowiednik Material 3 / Flutter: Radio button w elemencie listy / `RadioListTile` (w grupie)

## Cel
Wybór jednej opcji, gdy opcje potrzebują opisu albo jest ich więcej niż 3: punkt startowy trasy (EK-09),
język interfejsu w Ustawieniach (EK-12: System / Polski / English). Zastępuje CMP-07 przy dużej skali tekstu.
Nie służy do: wielokrotnego wyboru, działań.

## Warianty
| Wariant | Kiedy użyć | Uwagi |
|---|---|---|
| Jednolinijkowy | język | |
| Z opisem (2 linie) | punkt startowy: „Nocleg · Hotel Przykładowy (punkt przybliżony)", „Poprzedni punkt dnia · …", „Moja lokalizacja · jednorazowo, wymaga zgody" | opis `bodyMedium` `onSurfaceVariant` |
| Z opcją niedostępną | „Moja lokalizacja" po trwałej odmowie uprawnienia | pozycja nieaktywna + opis, jak zmienić w ustawieniach systemu |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | pole radiowe `onSurfaceVariant` |
| Wybrany | pole `primary` (pełne koło w środku – znaczenie kształtem, nie tylko kolorem) |
| Fokus / naciśnięty | warstwa stanu na całym wierszu |
| Nieaktywny | wiersz 38%, opis powodu czytelny (opis zostaje w kontraście `onSurfaceVariant`) |
| Ładowanie | n/d |
| Błąd | n/d |

## Rozmiary i odstępy
Wiersz min. 56 dp (jedna linia) / 72 dp (z opisem); pole 20 dp w celu 48 dp; wcięcia 16 dp.

## Tokeny
`primary`, `onSurfaceVariant`, `onSurface`; tytuł `bodyLarge`, opis `bodyMedium`.

## Zachowanie
Dotknięcie wiersza wybiera. Wybór w arkuszu dolnym (CMP-16) nie zamyka arkusza, jeśli są dalsze wybory
(EK-09: start + tryb); zamyka, jeśli to jedyny wybór (język).

## Dostępność
- Etykieta dla TalkBack: „Moja lokalizacja, jednorazowo, wymaga zgody, przycisk opcji, niewybrany, 3 z 3".
- Cel dotyku: cały wiersz.
- Kontrast: onSurface/surface ≥ 14:1; onSurfaceVariant/surface ≥ 8,8:1.
- Skalowanie do 200%: tytuł i opis zawijają się.

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `settingsLanguageSystem` | Język systemu | System language |
| `settingsLanguagePolish` | Polski | Polski |
| `settingsLanguageEnglish` | English | English |

Nazwy języków zawsze w ich własnym języku.

## Użycie
EK-09, EK-12; wzorzec arkusz dolny do wyboru.
