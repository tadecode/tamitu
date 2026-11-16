# Komponent: CMP-16 Arkusz dolny

- Status: szkic
- Autor: ux · Data: 2026-11-16 · Wersja: 0.1
- Odpowiednik Material 3 / Flutter: Modal bottom sheet / `showModalBottomSheet` (z uchwytem przeciągania)

## Cel
**Wybór** blisko kciuka, w kontekście bieżącego ekranu: wybór trasy do punktu (EK-09: punkt startowy +
tryb + „Otwórz w Google Maps"), wybór języka (EK-12).
Nie służy do: treści głównej, długich tekstów, formularzy z wieloma polami.

## Warianty
| Wariant | Kiedy użyć | Uwagi |
|---|---|---|
| Wybór z działaniem | EK-09 | tytuł (nazwa punktu), CMP-10 (start), CMP-07 (tryb), CMP-13 (informacje), CMP-02 wypełniony na dole |
| Prosty wybór | język | tytuł + CMP-10; wybór zamyka arkusz |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | `surfaceContainerLow`, uchwyt `onSurfaceVariant` 32×4 dp, `scrim` 32% za arkuszem |
| Fokus / naciśnięty | na elementach wewnątrz |
| Nieaktywny | n/d |
| Ładowanie | pobieranie lokalizacji: przycisk główny w stanie ładowania + „Anuluj" (rezygnacja z oczekiwania) |
| Błąd | CMP-13 wariant ostrzeżenia w arkuszu (np. „Nie udało się ustalić pozycji. Wybierz start z planu.") |

## Rozmiary i odstępy
Pełna szerokość (compact), maks. 640 dp (medium+); wysokość wg treści, maks. 90% ekranu, potem przewijanie;
wnętrze 16 dp (24 dp nad tytułem po uchwycie); przycisk główny 16 dp od dołu obszaru bezpiecznego.

## Tokeny
`surfaceContainerLow`; tytuł `titleLarge`; kształt `shape-xl` (tylko górne rogi); elevation 1.

## Zachowanie
Otwiera się animacją medium2 od dołu; zamyka: przeciągnięcie w dół, dotknięcie tła, wstecz.
Nie zagnieżdżamy arkuszy w arkuszach. Wybór zapamiętany tylko na czas otwarcia arkusza (tryb trasy nie jest zapisywany – model danych).

## Dostępność
- Etykieta dla TalkBack: fokus na tytule; uchwyt ma etykietę „Zamknij arkusz" i działanie zamknięcia (przeciąganie nie jest jedyną drogą).
- Cel dotyku elementów 48 dp.
- Kontrast: treść na `surfaceContainerLow` ≥ 7,3:1 (onSurfaceVariant), ≥ 13,2:1 (onSurface).
- Skalowanie do 200%: arkusz rozwija się do 90% i przewija.

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `commonCloseSheet` | Zamknij arkusz | Close sheet |

## Użycie
EK-09, EK-12; wzorzec arkusz dolny do wyboru.
