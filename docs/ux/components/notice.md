# Komponent: CMP-13 Komunikat w treści

- Status: szkic
- Autor: ux · Data: 2026-11-16 · Wersja: 0.1
- Odpowiednik Material 3 / Flutter: Banner (wariant osadzony w treści) / `Card.filled` z ikoną, tekstem i opcjonalnymi przyciskami tekstowymi. Uzasadnienie: `MaterialBanner` przykleja się do paska górnego i nie przewija się z treścią; tu potrzebny jest komunikat jako część treści. Koszt: niski (złożenie z widgetów M3).

## Cel
Trwała, kontekstowa informacja na ekranie, która **nie znika sama**: informacja o AI (EK-08), „plany tylko
na tym urządzeniu" (EK-04, EK-13), brak sieci przy funkcji wymagającej sieci (EK-05, EK-09), przybliżony
punkt startu (EK-09), ostrzeżenie o nieodwracalności (EK-15).
Nie służy do: potwierdzeń chwilowych (CMP-14), błędów całego ekranu (CMP-18), błędów pól (CMP-04).

## Warianty
| Wariant | Kiedy użyć | Wygląd |
|---|---|---|
| Informacja | AI, plany na urządzeniu, czas lokalny | `secondaryContainer` / `onSecondaryContainer`, ikona `info` lub `auto_awesome` (AI) |
| Ostrzeżenie | brak sieci przy akcji, przybliżony punkt, skutki wylogowania | `secondaryContainer`, ikona `warning` / `wifi_off`, tytuł pogrubiony |
| Błąd / zagrożenie | nieodwracalne usunięcie konta, limit wyczerpany | `errorContainer` / `onErrorContainer`, ikona `error` / `schedule` |

Znaczenie przenosi **ikona + tytuł + tekst**, kolor tylko wzmacnia.

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | ikona 24 dp, tytuł opcjonalny (`titleSmall`), tekst `bodyMedium`, 0–2 przyciski tekstowe na dole po prawej |
| Fokus / naciśnięty | tylko na przyciskach |
| Nieaktywny | n/d |
| Ładowanie | n/d |
| Błąd | wariant „Błąd" |

## Rozmiary i odstępy
Pełna szerokość minus marginesy 16 dp; wnętrze 16 dp; ikona–tekst 16 dp; 16 dp pod komunikatem do treści; min. wysokość wg treści.

## Tokeny
Wg wariantu; `titleSmall`, `bodyMedium`; kształt `shape-m`; elevation 0.

## Zachowanie
Pozycja stała: pod paskiem górnym, nad treścią (przewija się z treścią). Komunikat o AI w EK-08 **nie da się
zamknąć** (wymaganie). Komunikat „plany tylko na urządzeniu" w EK-04 można zamknąć („Rozumiem") – decyzja w kroku 2.
Komunikat o braku sieci pojawia się/znika automatycznie wraz ze stanem sieci (animacja medium2), ogłaszany przez TalkBack.

## Dostępność
- Etykieta dla TalkBack: tytuł + tekst; ikona dekoracyjna (pomijana), bo znaczenie niesie tekst; zmiana stanu sieci ogłaszana (live region, uprzejmie).
- Cel dotyku przycisków 48 dp.
- Kontrast: onSecondaryContainer/secondaryContainer ≥ 7,2:1; onErrorContainer/errorContainer ≥ 7,2:1.
- Skalowanie do 200%: tekst zawija się, przyciski pod tekstem.

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `planAiNotice` | Plan stworzyła AI i może zawierać błędy. Sprawdź godziny otwarcia przed wyjściem. | This plan was created by AI and may contain mistakes. Check opening hours before you go. |
| `planListDeviceOnlyNotice` | Plany są zapisane tylko na tym urządzeniu. Po odinstalowaniu aplikacji lub zmianie telefonu nie będą dostępne. | Plans are stored only on this device. They won't be available after uninstalling the app or changing your phone. |
| `commonOfflineNotice` | Brak połączenia z internetem. Ta funkcja wymaga sieci. | No internet connection. This feature needs a network. |
| `commonGotIt` | Rozumiem | Got it |

Teksty komunikatów o AI i o planach na urządzeniu – do potwierdzenia przez security (wzorce z privacy-checklist).

## Użycie
EK-04, EK-05, EK-08, EK-09, EK-13, EK-15, EK-16; wzorce brak sieci, zgody, błąd.
