# Komponent: CMP-06 Pole daty i godziny

- Status: szkic
- Autor: ux · Data: 2026-11-16 · Wersja: 0.2 (2026-11-25, TAM-102: układ zależny od szerokości okna, fokus po zamknięciu wybieraka)
- Odpowiednik Material 3 / Flutter: Date picker (modal), Time picker (dial/input) / `showDatePicker`, `showTimePicker`; pole wyzwalające: `TextFormField` tylko do odczytu

## Cel
Wybór daty i godziny przylotu/przyjazdu (EK-05). Dwa pola: data i godzina (na telefonie jedno pod drugim).
Nie służy do: zakresów dat (poza MVP).

## Warianty
| Wariant | Kiedy użyć | Uwagi |
|---|---|---|
| Data | data przylotu/przyjazdu | zakres od wczoraj do +2 lata (U10); dni spoza zakresu nieaktywne w kalendarzu |
| Godzina | godzina przylotu/przyjazdu | format wg języka interfejsu (24 h dla PL, wg ustawienia systemu dla EN) |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | pole jak CMP-04 z ikoną `calendar-03` / `clock-01`, bez wartości |
| Fokus / naciśnięty | otwiera modalny wybierak M3 (kalendarz / tarcza godzin z przełącznikiem na wpisywanie) |
| Nieaktywny | jak CMP-04 |
| Ładowanie | n/d |
| Błąd | jak CMP-04: „Podaj datę przylotu", „Data musi być między {od} a {do}" |

## Rozmiary i odstępy
Pola jak CMP-04. Okno compact (< 600 dp, telefon): **zawsze jedno pod drugim**, każde na pełną szerokość. Okno medium/expanded (≥ 600 dp): obok siebie, każde pół szerokości kolumny (odstęp 16 dp), a od skali tekstu 150% jedno pod drugim. Etykieta nigdy nie jest ucinana wielokropkiem (TAM-102: „Godzina przylotu” przy 16 sp nie mieści się w połowie szerokości telefonu). Wybieraki – rozmiary M3.

## Tokeny
Jak CMP-04; wybieraki: `surfaceContainerHigh`, wybrany dzień `primary`/`onPrimary`, dziś obrys `primary`, kształt `shape-xl`.

## Zachowanie
Wartość wpisana w polu w formacie lokalnym (PL: „12 maja 2027", EN: „May 12, 2027"; godzina „14:30" / „2:30 PM").
Data i godzina oznaczają czas lokalny w miejscu docelowym – podpowiedź pod polem godziny: „Czas lokalny w miejscu docelowym".
Etykiety zależne od trybu dojazdu: „Data przylotu"/„Data przyjazdu" (lot/auto).
Po zamknięciu wybieraka (wybór lub anulowanie) fokus wraca na pole, które go otworzyło, a nie na ostatnie pole tekstowe formularza; klawiatura się nie otwiera (TAM-102).

## Dostępność
- Etykieta dla TalkBack: „Data przylotu, wymagane, nie wybrano, dotknij dwukrotnie, aby wybrać"; wybieraki M3 mają wbudowaną obsługę TalkBack i tryb wpisywania z klawiatury.
- Cel dotyku pola ≥ 48 dp.
- Kontrast jak CMP-04; wybrany dzień onPrimary/primary ≥ 6,4:1.
- Skalowanie do 200%: wybierak przechodzi w tryb wpisywania, gdy kalendarz się nie mieści (zachowanie M3).

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `commonLocalTimeHelper` | Czas lokalny w miejscu docelowym | Local time at your destination |
| `commonDateRangeError` | Data musi być między {from} a {to} | Date must be between {from} and {to} |

## Użycie
EK-05; wzorzec formularz.
