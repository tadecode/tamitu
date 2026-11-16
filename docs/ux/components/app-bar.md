# Komponent: CMP-01 Pasek górny

- Status: szkic
- Autor: ux · Data: 2026-11-16 · Wersja: 0.1
- Odpowiednik Material 3 / Flutter: Small top app bar / `AppBar` (w `Scaffold`)

## Cel
Pokazuje, gdzie użytkownik jest (tytuł), pozwala wrócić i daje dostęp do 1–2 działań ekranu.
Nie służy do: głównego działania ekranu (to przycisk/FAB w treści), komunikatów (CMP-13), wyszukiwania (poza MVP).

## Warianty
| Wariant | Kiedy użyć | Uwagi |
|---|---|---|
| Główny (bez wstecz) | EK-04 lista planów | tytuł „Twoje podróże" + ikona `settings-02` |
| Zagnieżdżony (ze wstecz) | wszystkie ekrany podrzędne | ikona `arrow-left-01` po lewej |
| Z menu | EK-08 | ikona `more-vertical` → menu z „Usuń plan" (destrukcyjne nie jako ikona na wierzchu) |
| Blokujący (bez wstecz) | EK-03, EK-07 | brak strzałki; wyjście tylko działaniami ekranu |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | tło `surface`, elevation 0 |
| Przewinięta treść | tło `surfaceContainer` (elevation 2), animacja short4 |
| Fokus / naciśnięty | warstwa stanu na ikonie (10%) |
| Nieaktywny | ikona działania nieaktywna 38% (np. menu w trakcie operacji) |
| Ładowanie | n/d (postęp w treści – CMP-17; wyjątek: cienki pasek liniowy pod paskiem w EK-15) |
| Błąd | n/d |

## Rozmiary i odstępy
Wysokość 64 dp; ikony 24 dp w celu 48 dp; margines tytułu 16 dp (bez wstecz) lub 4 dp za ikoną wstecz.

## Tokeny
Tło `surface` → `surfaceContainer` po przewinięciu; tytuł `titleLarge` `onSurface`; ikony `onSurfaceVariant`;
kształt `shape-none`.

## Zachowanie
Tytuł w jednej linii, przy przepełnieniu wielokropek; pełny tytuł zawsze dostępny dla TalkBack i powtórzony
w treści (np. nazwa celu podróży w karcie podsumowania EK-08). Przy skali tekstu 200% wysokość paska rośnie.
Wstecz systemowe = ikona wstecz (wyjątki w `layout.md` pkt 3).

## Dostępność
- Etykieta dla TalkBack: tytuł jako nagłówek (`header`); ikony z etykietami „Wstecz", „Ustawienia", „Więcej opcji".
- Cel dotyku 48 dp; kolejność fokusu: wstecz → tytuł → działania.
- Kontrast: onSurface/surface ≥ 14:1, onSurfaceVariant/surface ≥ 7,8:1 (jasny i ciemny motyw).
- Skalowanie tekstu do 200%: tytuł się nie ucina (dwie linie dozwolone przy 200%).

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `commonBack` | Wstecz | Back |
| `commonSettings` | Ustawienia | Settings |
| `commonMoreOptions` | Więcej opcji | More options |

## Użycie
Wszystkie ekrany poza EK-01; wzorce: lista i szczegóły, formularz.
