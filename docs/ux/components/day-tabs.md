# Komponent: CMP-19 Zakładki dni

- Status: szkic
- Autor: ux · Data: 2026-11-16 · Wersja: 0.1
- Odpowiednik Material 3 / Flutter: Primary tabs (przewijalne) / `TabBar` (isScrollable) + `TabBarView`

## Cel
Przełączanie dni planu w EK-08 (1–14 dni). Nie służy do: nawigacji między ekranami, filtrów.

## Warianty
| Wariant | Kiedy użyć | Uwagi |
|---|---|---|
| Stałe | 1–4 dni | zakładki równej szerokości |
| Przewijalne | 5–14 dni | przewijane poziomo (wyjątek od zasady jednej osi – to pasek wyboru, nie treść); aktywna zakładka zawsze widoczna |
| Jeden dzień | 1 dzień | **bez paska zakładek**; tytuł „Dzień 1" nad listą |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | etykieta „Dzień {n}" `onSurfaceVariant` |
| Aktywny | etykieta `primary`, wskaźnik 3 dp `primary` pod etykietą (znaczenie także wskaźnikiem – kształt) |
| Fokus / naciśnięty | warstwa stanu 10% |
| Nieaktywny | n/d |
| Ładowanie | n/d (plan wczytywany w całości – CMP-17 szkielet) |
| Błąd | n/d |

## Rozmiary i odstępy
Wysokość 48 dp; wnętrze poziome 16 dp; separator dolny `surfaceVariant`/`outlineVariant` 1 dp.

## Tokeny
`primary`, `onSurfaceVariant`, `outlineVariant`; tekst `labelLarge`; tło `surface`.

## Zachowanie
Dotknięcie zakładki lub przesunięcie treści w poziomie zmienia dzień (animacja medium2). Etykieta może mieć
drugi wiersz z datą dnia („12 maja"), jeśli zmieści się bez ucinania – decyzja w kroku 2. Pierwszy dzień
pokazuje na początku listy godzinę przylotu/przyjazdu (CMP-20 wariant „przylot").

## Dostępność
- Etykieta dla TalkBack: „Dzień 2, zakładka, 2 z 4, wybrana".
- Cel dotyku 48 dp.
- Kontrast: primary/surface ≥ 5,4:1; onSurfaceVariant/surface ≥ 7,8:1.
- Skalowanie do 200%: zakładki rosną i przechodzą w tryb przewijalny.

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `planDayTab` | Dzień {number} | Day {number} |

## Użycie
EK-08; wzorzec lista i szczegóły.
