# Komponent: CMP-11 Element listy

- Status: szkic
- Autor: ux · Data: 2026-11-16 · Wersja: 0.1
- Odpowiednik Material 3 / Flutter: List item (1–3 linie) / `ListTile`

## Cel
Wiersz w liście ustawień i informacji: pozycje Ustawień (EK-12), stan zgód z datą (EK-13).
Nie służy do: planów na liście głównej (CMP-12 karta – więcej treści, większy cel), punktów planu (CMP-20).

## Warianty
| Wariant | Kiedy użyć | Uwagi |
|---|---|---|
| Nawigacyjny | „Prywatność", „Język" | ikona wiodąca 24 dp, opcjonalnie wartość w drugiej linii („Polski"), ikona `arrow-right-01` nie jest wymagana w M3 – nie używamy |
| Zewnętrzny | „Polityka prywatności" | ikona końcowa `link-square-02` (otwiera przeglądarkę) |
| Informacyjny (bez działania) | „Zgoda na AI · wyrażona 12.05.2027" | bez warstwy stanu, nie jest celem dotyku |
| Destrukcyjny | „Usuń konto" | ikona i tekst `error`; na końcu listy, w osobnej grupie |
| Nagłówek grupy | „Konto", „Prywatność" | `titleSmall` `primary`, nie jest interaktywny |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | tło przezroczyste (na `surface`) |
| Fokus / naciśnięty | warstwa stanu 10% na całym wierszu |
| Nieaktywny | 38% + opis powodu w drugiej linii (np. „Niedostępne podczas generowania" – U8) |
| Ładowanie | n/d (działanie po dotknięciu prowadzi do ekranu/dialogu ze swoim stanem) |
| Błąd | n/d |

## Rozmiary i odstępy
Wysokość min. 56 dp (1 linia), 72 dp (2 linie), 88 dp (3 linie); wcięcia 16 dp; ikona wiodąca 24 dp, odstęp do tekstu 16 dp. Separator `outlineVariant` tylko między grupami.

## Tokeny
Tytuł `bodyLarge` `onSurface`; drugi wiersz `bodyMedium` `onSurfaceVariant`; ikony `onSurfaceVariant`; destrukcyjny `error`.

## Zachowanie
Cały wiersz jest celem dotyku. Długi tekst zawija się (maks. 3 linie, potem wielokropek – tylko dla wartości, nigdy dla tytułu).

## Dostępność
- Etykieta dla TalkBack: tytuł + drugi wiersz + rola („przycisk", „link, otwiera przeglądarkę"); nagłówki grup jako nagłówki.
- Cel dotyku ≥ 56 dp.
- Kontrast: onSurface/surface ≥ 14:1; onSurfaceVariant/surface ≥ 8,8:1; error/surface ≥ 6,1:1.
- Skalowanie do 200%: wiersz rośnie.

## Teksty
Klucze ekranowe – w `screens/` (krok 2).

## Użycie
EK-12, EK-13; wzorzec lista i szczegóły (ustawienia).
