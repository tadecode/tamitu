# Komponent: CMP-02 Przycisk

- Status: szkic
- Autor: ux · Data: 2026-11-16 · Wersja: 0.1
- Odpowiednik Material 3 / Flutter: Common buttons / `FilledButton`, `FilledButton.tonal`, `OutlinedButton`, `TextButton` (opcjonalnie z ikoną)

## Cel
Uruchamia działanie. Hierarchia przez styl: na ekranie **jeden** przycisk wypełniony.
Nie służy do: nawigacji między ekranami listy (to element listy/karta), wyboru wartości (CMP-07/08/10).

## Warianty
| Wariant | Kiedy użyć | Uwagi |
|---|---|---|
| Wypełniony (filled) | główne działanie ekranu: „Zaloguj przez Google", „Generuj plan", „Otwórz w Google Maps" | `primary` / `onPrimary`; maks. 1 na ekran |
| Tonalny (tonal) | ważne drugorzędne: „Spróbuj ponownie" w stanie błędu | `secondaryContainer` / `onSecondaryContainer` |
| Obrysowany (outlined) | alternatywa równorzędna lub drugorzędna: „Anuluj generowanie"; **pary równorzędne w zgodach** (EK-06) | obrys `outline`, tekst `primary` |
| Tekstowy (text) | najmniej ważne: działania w dialogu i snackbarze, „Polityka prywatności" | tekst `primary` |
| Destrukcyjny | „Usuń plan", „Usuń konto" (potwierdzenie) | wypełniony `error`/`onError` **tylko** w dialogu/ekranie potwierdzenia; poza nim outlined z tekstem `error` i ikoną `delete-02` |
| Z ikoną | gdy ikona pomaga rozpoznać działanie (`route-02`, `link-square-02`) | ikona 18 dp przed tekstem; tekst zawsze obecny |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | jak wariant |
| Fokus / naciśnięty | warstwa stanu 10% koloru treści; efekt fali (ripple) |
| Nieaktywny | treść `onSurface` 38%, kontener `onSurface` 12%; np. „Zaloguj" przed akceptacją polityki. Obok **musi** być widoczny powód (np. niezaznaczona zgoda bezpośrednio nad przyciskiem) |
| Ładowanie | tekst zastąpiony wskaźnikiem kołowym 20 dp w kolorze treści; szerokość przycisku bez zmian; przycisk nieaktywny (blokada podwójnego dotknięcia – EK-02) |
| Błąd | n/d (błąd pokazuje CMP-13/CMP-14/CMP-18, nie przycisk) |

## Rozmiary i odstępy
Wysokość 40 dp wizualnie, **cel dotyku 48 dp**; wnętrze poziome 24 dp (z ikoną: 16 dp przed ikoną);
min. szerokość 64 dp; przyciski na pełną szerokość w formularzach i ekranach zgód (margines 16 dp);
odstęp między przyciskami 8 dp.

## Tokeny
Kształt `shape-full`; tekst `labelLarge`; kolory wg wariantu (wyżej); elevation 0.

## Zachowanie
Tekst w zdaniu rozkazującym, krótki (do ~3 słów; PL dłuższe – sprawdzić). Przy braku miejsca tekst **zawija
się** do 2 linii (wysokość rośnie), nie ucina się. Para przycisków poziomo w dialogu; gdy się nie mieści
(PL, skala 200%) – pionowo, potwierdzający na górze. Animacja stanu short2.

## Dostępność
- Etykieta dla TalkBack: tekst przycisku; w stanie ładowania „<tekst>, trwa…" (np. „Logowanie, trwa…").
- Cel dotyku 48 dp; odstęp 8 dp.
- Kontrast: onPrimary/primary ≥ 6,4:1; onError/error ≥ 6,4:1; primary/surface ≥ 6,1:1 (tekstowy/outlined).
- Skalowanie tekstu do 200%: zawijanie, brak ucinania.

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `commonRetry` | Spróbuj ponownie | Try again |
| `commonCancel` | Anuluj | Cancel |
| `commonOk` | OK | OK |
| `commonDelete` | Usuń | Delete |
| `commonLoading` | Trwa… | In progress… |

## Użycie
Wszystkie wzorce; ekrany EK-02..EK-16.
