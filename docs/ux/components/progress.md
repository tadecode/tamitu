# Komponent: CMP-17 Wskaźnik postępu i szkielet

- Status: szkic
- Autor: ux · Data: 2026-11-16 · Wersja: 0.2 (2026-11-24, TAM-98: wariant „Liniowy określony – odliczanie”)
- Odpowiednik Material 3 / Flutter: Progress indicators / `LinearProgressIndicator`, `CircularProgressIndicator` (nieokreślone); szkielet – prostokąty `surfaceContainerHighest` w kształcie docelowej treści (bez dodatkowego pakietu)

## Cel
Pokazuje, że coś trwa. **Szkielet**, gdy znany jest układ (lista planów, widok planu); **wskaźnik**, gdy
układ nieznany lub operacja jest „czynnością" (generowanie, usuwanie konta).
Nie służy do: fałszywego procentu postępu (czas generowania nieznany – macierz EK-07).

## Warianty
| Wariant | Kiedy użyć | Uwagi |
|---|---|---|
| Szkielet | EK-04 wczytanie listy (3 karty-szkielety), EK-08 wczytanie planu | tylko jeśli wczytanie > 300 ms (bez migotania) |
| Liniowy nieokreślony | EK-07 generowanie (z tekstem), EK-15 usuwanie konta | na pełną szerokość treści, z tekstem nad nim |
| Liniowy określony – odliczanie | EK-07 stan `ai_busy`: czas do automatycznego ponowienia (`screens/ek-07-ai-busy.md`) | `LinearProgressIndicator(value:)` = pozostały czas / całość; pasek się **opróżnia** co 1 s; pokazuje czas, nie postęp pracy, więc nie łamie zasady „bez fałszywego procentu”; zawsze z tekstem odliczania nad nim; szerokość tekstu CMP-18 (maks. 320 dp) |
| Kołowy nieokreślony | w przycisku (CMP-02 ładowanie), EK-01 jeśli ustalanie sesji > 500 ms | 20 dp w przycisku, 48 dp samodzielnie |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | wskaźnik: `primary` na torze `surfaceContainerHighest`; szkielet: `surfaceContainerHighest` |
| Fokus / naciśnięty | n/d |
| Nieaktywny | n/d |
| Ładowanie | to jest stan ładowania |
| Błąd | wskaźnik znika, pojawia się CMP-18 lub CMP-13 |

## Rozmiary i odstępy
Liniowy: wysokość 4 dp, kształt `shape-full`; szkielet: kształt i odstępy jak docelowy komponent.

## Tokeny
`primary`, `surfaceContainerHighest`; animacja nieokreślona M3; szkielet z delikatnym pulsowaniem nieprzezroczystości (1,5 s) – wyłączane przy „usuń animacje".

## Zachowanie
EK-07: tekst główny „Układamy plan…" i pomocniczy „To może potrwać do 2 minut", co ~10 s zmienia się tekst
pomocniczy (bez zdradzania treści planu), pod spodem „Anuluj" (CMP-02 outlined). Opóźnienie pokazania
wskaźnika 300 ms (krótkie operacje nie migoczą).

## Dostępność
- Etykieta dla TalkBack: „Wczytywanie" / „Generowanie planu, trwa"; zmiana tekstu pomocniczego ogłaszana uprzejmie, nie częściej niż co 10 s; szkielet ukryty przed TalkBack (ogłaszane „Wczytywanie").
- Cel dotyku n/d.
- Kontrast: primary na torze surfaceContainerHighest ≥ 4,3:1 (próg 3:1 dla elementu interfejsu; najgorszy przypadek: jasny 4,35).
- Skalowanie do 200%: teksty zawijają się.

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `commonLoadingLabel` | Wczytywanie | Loading |
| `generationTitle` | Układamy plan… | Building your plan… |
| `generationMayTakeTime` | To może potrwać do 2 minut | This may take up to 2 minutes |

## Użycie
EK-01, EK-04, EK-07, EK-08, EK-09, EK-15; wzorzec ładowanie.
