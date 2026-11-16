# Komponent: CMP-12 Karta

- Status: szkic
- Autor: ux · Data: 2026-11-16 · Wersja: 0.1
- Odpowiednik Material 3 / Flutter: Filled card / `Card.filled` (z `InkWell` dla wariantu klikalnego)

## Cel
Grupuje informacje o jednej rzeczy: plan na liście (EK-04), podsumowanie danych podróży w widoku planu (EK-08).
Nie służy do: komunikatów (CMP-13), pojedynczych ustawień (CMP-11), dekoracji.

## Warianty
| Wariant | Kiedy użyć | Uwagi |
|---|---|---|
| Plan (klikalna) | EK-04 | tytuł: cel podróży (`titleMedium`); linia 2: „{n} dni · lot/auto" z ikoną; linia 3: „Utworzono {data}" (`bodyMedium` `onSurfaceVariant`). Cała karta otwiera EK-08 |
| Podsumowanie podróży (statyczna) | EK-08 nad zakładkami dni | wiersze z ikonami: `bed-double` nocleg, `airplane-landing-01`/`car-01` przylot/przyjazd z datą i godziną (godzina w `tertiary`) |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | tło `surfaceContainerLow` (na `surface`), elevation 0 |
| Fokus / naciśnięty | warstwa stanu 10% na całej karcie (wariant klikalny) |
| Nieaktywny | n/d |
| Ładowanie | szkielet w kształcie karty (CMP-17) |
| Błąd | n/d (błąd listy – CMP-18) |

## Rozmiary i odstępy
Szerokość: pełna minus marginesy 16 dp; wnętrze 16 dp; między wierszami 4 dp; między kartami 8 dp; min. wysokość wariantu klikalnego 72 dp.

## Tokeny
`surfaceContainerLow`, `onSurface`, `onSurfaceVariant`, `tertiary` (godzina przylotu); `titleMedium`, `bodyMedium`; kształt `shape-m`; elevation 0.

## Zachowanie
Długi cel podróży zawija się do 2 linii, potem wielokropek (pełna nazwa w EK-08 i dla TalkBack).
Cel podróży wyświetlany w języku, w jakim został wpisany (treść użytkownika, nie tłumaczymy).
Daty wg lokalizacji interfejsu. Brak przeciągania/przesuwania kart w MVP (usuwanie przez EK-08 → EK-11).

## Dostępność
- Etykieta dla TalkBack: jedna etykieta całej karty: „Lizbona, 4 dni, lot, utworzono 12 maja 2027, przycisk".
- Cel dotyku: cała karta (≥ 72 dp).
- Kontrast (najgorszy przypadek, jasny i ciemny motyw wariantu A): onSurface/surfaceContainerLow ≥ 13,2:1; onSurfaceVariant/surfaceContainerLow ≥ 7,3:1; tertiary/surfaceContainerLow ≥ 5,0:1.
- Skalowanie do 200%: karta rośnie, brak ucinania poza tytułem > 2 linii.

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `planListDays` | {count, plural, =1{1 dzień} other{{count} dni}} | {count, plural, =1{1 day} other{{count} days}} |
| `planListCreatedOn` | Utworzono {date} | Created {date} |

## Użycie
EK-04, EK-08; wzorzec lista i szczegóły.
