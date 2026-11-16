# Komponent: CMP-15 Dialog

- Status: szkic
- Autor: ux · Data: 2026-11-16 · Wersja: 0.1
- Odpowiednik Material 3 / Flutter: Basic dialog / `AlertDialog`

## Cel
Krótka decyzja, która przerywa pracę: potwierdzenie usunięcia planu (EK-11), wylogowania (EK-14),
anulowania generowania (EK-07). Nie służy do: długich treści (zgody – pełny ekran), wyborów z listy
(CMP-16), informacji bez decyzji (CMP-13/CMP-14).

## Warianty
| Wariant | Kiedy użyć | Uwagi |
|---|---|---|
| Potwierdzenie | wylogowanie, anulowanie generowania | tytuł-pytanie, treść ze skutkiem, przyciski tekstowe: „Anuluj" + działanie |
| Destrukcyjne | usunięcie planu | działanie potwierdzające w kolorze `error` (tekst), ikona `delete` nad tytułem |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | `surfaceContainerHigh`, elevation 3, tło za dialogiem `scrim` 32% |
| Fokus / naciśnięty | na przyciskach |
| Nieaktywny | n/d |
| Ładowanie | po potwierdzeniu krótkiej operacji (usuwanie planu, wylogowanie): przycisk potwierdzający w stanie ładowania (CMP-02), drugi nieaktywny; dialog zamyka się po sukcesie |
| Błąd | treść zastąpiona komunikatem błędu + „Spróbuj ponownie" / „Zamknij"; nic nie zmieniono (np. plan pozostaje) |

## Rozmiary i odstępy
Szerokość 280–560 dp; wnętrze 24 dp; ikona 24 dp, 16 dp nad tytułem; tytuł–treść 16 dp; treść–przyciski 24 dp; przyciski od prawej, 8 dp odstępu.

## Tokeny
`surfaceContainerHigh`, tytuł `headlineSmall` `onSurface`, treść `bodyMedium` `onSurfaceVariant`, przyciski tekstowe `primary` / `error`; kształt `shape-xl`.

## Zachowanie
Tytuł jako pytanie („Usunąć plan?"), przyciski z czasownikiem („Usuń", „Wyloguj"), nie „Tak/Nie".
Działanie bezpieczne („Anuluj") po lewej, potwierdzające po prawej. Dotknięcie poza dialogiem i wstecz = „Anuluj"
(poza stanem ładowania). Treść przewija się, jeśli jest długa (PL, 200%), przyciski zawsze widoczne.
Wejście medium2 (emphasized decelerate).

## Dostępność
- Etykieta dla TalkBack: fokus na tytule po otwarciu; dialog jest modalny (reszta niedostępna); wstecz zamyka.
- Cel dotyku przycisków 48 dp.
- Kontrast (najgorszy przypadek z 4 kombinacji wariant×motyw): onSurface/surfaceContainerHigh ≥ 11,1:1; onSurfaceVariant/surfaceContainerHigh ≥ 7,5:1; primary/surfaceContainerHigh ≥ 5,2:1; error/surfaceContainerHigh ≥ 5,2:1.
- Skalowanie do 200%: przyciski pionowo, treść przewijana.

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `commonClose` | Zamknij | Close |

Teksty dialogów – w `screens/` (krok 2).

## Użycie
EK-07, EK-11, EK-14; wzorzec potwierdzenie działania destrukcyjnego.
