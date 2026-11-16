# Komponent: CMP-18 Stan ekranu

- Status: szkic
- Autor: ux · Data: 2026-11-16 · Wersja: 0.1
- Odpowiednik Material 3 / Flutter: brak gotowego widgetu M3; złożony z `Icon` (48 dp), `Text` (headlineSmall, bodyMedium) i CMP-02. Uzasadnienie: M3 opisuje stany puste i błędy jako wzorzec, nie komponent; jeden wspólny układ zapewnia spójność katalogu komunikatów EK-16. Koszt: niski (jeden widget kompozytowy).

## Cel
Zastępuje treść ekranu, gdy nie ma czego pokazać: stan pusty (EK-04 bez planów), błąd wczytania (EK-04, EK-08),
brak sieci przy ekranie wymagającym sieci, błędy generowania (EK-16 po powrocie do EK-05 – tam jako CMP-13,
bo formularz zostaje), uszkodzona baza konta (EK-01, U12).
Nie służy do: błędów pojedynczych pól, chwilowych potwierdzeń.

## Warianty
| Wariant | Kiedy użyć | Ikona | Działanie |
|---|---|---|---|
| Pusty | brak danych | `luggage` lub `map` (decyzja w kroku 2) | jedno wypełnione („Nowa podróż") |
| Błąd | nie udało się wczytać/wykonać | `error` | tonalne „Spróbuj ponownie" + ewentualnie tekstowe „Wróć" |
| Brak sieci | ekran wymaga sieci | `wifi_off` | tonalne „Spróbuj ponownie" |
| Limit | limit dzienny wyczerpany (gdy pokazujemy na całym ekranie) | `schedule` | tekstowe „Wróć do planów" |
| Blokujący | wymagana aktualizacja (U3), baza niedostępna (U12) | `system_update` / `error` | wypełnione (np. „Zaktualizuj aplikację") + tekstowe alternatywy |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | wyśrodkowany pionowo w obszarze treści: ikona, tytuł, opis (powód + co zrobić), działanie |
| Fokus / naciśnięty | na przyciskach |
| Nieaktywny | n/d |
| Ładowanie | po „Spróbuj ponownie": przycisk w stanie ładowania |
| Błąd | wariant Błąd |

## Rozmiary i odstępy
Ikona 48 dp `onSurfaceVariant`; ikona–tytuł 16 dp; tytuł–opis 8 dp; opis–działanie 24 dp; szerokość tekstu maks. 320 dp (wyśrodkowany); 32 dp od góry obszaru treści, gdy ekran ma też komunikat CMP-13.

## Tokeny
Tytuł `headlineSmall` `onSurface`; opis `bodyMedium` `onSurfaceVariant`; ikona `onSurfaceVariant`.

## Zachowanie
Teksty bez szczegółów technicznych (kody błędów nie są pokazywane; mapowanie kodów API → komunikaty w `screens/ek-16`).
Opis zawsze mówi: co się stało + co można zrobić. Przy skali 200% przewija się z treścią.

## Dostępność
- Etykieta dla TalkBack: tytuł jako nagłówek; ikona dekoracyjna; po pojawieniu się stanu fokus przechodzi na tytuł.
- Cel dotyku przycisków 48 dp.
- Kontrast: onSurface/surface ≥ 14:1; onSurfaceVariant/surface ≥ 8,8:1.
- Skalowanie do 200%: przewijanie, bez ucinania.

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `errorGenericTitle` | Coś poszło nie tak | Something went wrong |
| `errorGenericBody` | Spróbuj ponownie za chwilę. Twoje dane są bezpieczne. | Please try again in a moment. Your data is safe. |
| `errorOfflineTitle` | Brak połączenia | You're offline |
| `errorOfflineBody` | Sprawdź połączenie z internetem i spróbuj ponownie. | Check your internet connection and try again. |

Pełny katalog komunikatów EK-16 – w `screens/` (krok 2).

## Użycie
EK-01, EK-04, EK-08, EK-15, EK-16; wzorce pusty stan, błąd z ponowieniem, brak sieci.
