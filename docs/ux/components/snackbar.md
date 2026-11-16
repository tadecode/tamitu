# Komponent: CMP-14 Snackbar

- Status: szkic
- Autor: ux · Data: 2026-11-16 · Wersja: 0.1
- Odpowiednik Material 3 / Flutter: Snackbar / `SnackBar` (przez `ScaffoldMessenger`)

## Cel
Krótka, chwilowa informacja o wyniku działania, z opcjonalnym jednym działaniem: „Plan usunięto · Cofnij"
(jeśli cofanie zostanie przyjęte – `patterns.md` pkt 7), „Zgoda na AI wycofana", „Logowanie anulowane",
„Nie udało się otworzyć map".
Nie służy do: informacji, które użytkownik musi przeczytać (CMP-13), błędów blokujących (CMP-18), pytań (CMP-15).

## Warianty
| Wariant | Kiedy użyć | Uwagi |
|---|---|---|
| Sam tekst | potwierdzenie | 1 linia |
| Z działaniem | „Cofnij", „Spróbuj ponownie" | przycisk tekstowy `inversePrimary` |
| Dwuliniowy | dłuższy tekst PL | maks. 2 linie; dłuższe treści → CMP-13 |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | `inverseSurface`, tekst `onInverseSurface` |
| Fokus / naciśnięty | warstwa stanu na przycisku |
| Nieaktywny | n/d |
| Ładowanie | n/d |
| Błąd | ten sam wygląd (tekst mówi, co się stało); bez czerwieni |

## Rozmiary i odstępy
Wysokość 48 dp (1 linia) / 68 dp (2 linie); margines 16 dp od krawędzi i nad FAB; wnętrze 16 dp.

## Tokeny
`inverseSurface`, `onInverseSurface`, `inversePrimary`; `bodyMedium`; kształt `shape-xs`; elevation 3.

## Zachowanie
Czas wyświetlania: 4 s bez działania, **10 s z działaniem**; przy włączonym TalkBack lub ustawieniu
„czas na działanie" Androida – do zamknięcia przez użytkownika. Nowy snackbar zastępuje poprzedni.
Przesunięcie w bok zamyka. Wejście/wyjście medium2.

## Dostępność
- Etykieta dla TalkBack: tekst ogłaszany automatycznie (live region); działanie osiągalne fokusem.
- Cel dotyku działania 48 dp.
- Kontrast: onInverseSurface/inverseSurface ≥ 10:1; inversePrimary/inverseSurface ≥ 4,9:1.
- Skalowanie do 200%: 2 linie + działanie pod tekstem.

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `commonUndo` | Cofnij | Undo |

## Użycie
EK-02, EK-04, EK-08, EK-13; wzorce powiadomienia, potwierdzenie działania destrukcyjnego.
