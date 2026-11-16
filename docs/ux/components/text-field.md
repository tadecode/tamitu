# Komponent: CMP-04 Pole tekstowe

- Status: szkic
- Autor: ux · Data: 2026-11-16 · Wersja: 0.1
- Odpowiednik Material 3 / Flutter: Outlined text field / `TextFormField` z `InputDecoration` (outlined)

## Cel
Wpisanie krótkiego tekstu: cel podróży, baza noclegowa, lotnisko, numer lotu (EK-05).
Nie służy do: wyboru z zamkniętej listy (CMP-05, CMP-07, CMP-08), daty i godziny (CMP-06), długich tekstów (brak w MVP).

## Warianty
| Wariant | Kiedy użyć | Uwagi |
|---|---|---|
| Wymagane | cel, nocleg, lotnisko (przy locie) | etykieta bez gwiazdki; pola opcjonalne oznaczone „(opcjonalnie)" – w formularzu przeważają wymagane |
| Opcjonalne | numer lotu | etykieta z dopiskiem „(opcjonalnie)" |
| Z podpowiedzią ochrony danych | nocleg | podpowiedź stała pod polem: „Nazwa obiektu lub dzielnica – nie wpisuj pełnego adresu prywatnego" |
| Z licznikiem | wszystkie z limitem (80/80/60/10 znaków) | licznik pokazuje się od 80% limitu |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | obrys `outline` 1 dp, etykieta `onSurfaceVariant` w polu |
| Fokus | obrys `primary` 2 dp, etykieta unosi się na obrys (`primary`) |
| Nieaktywny | obrys i tekst `onSurface` 38%/12% (nie używamy w MVP poza blokadą w trakcie generowania) |
| Ładowanie | n/d |
| Błąd | obrys `error` 2 dp, ikona `alert-circle` na końcu pola, komunikat pod polem `bodySmall` `error` zastępuje podpowiedź; walidacja **przy opuszczeniu pola** i przy „Generuj" (wtedy fokus przechodzi do pierwszego błędnego pola) |

## Rozmiary i odstępy
Wysokość 56 dp (rośnie przy skali tekstu); wnętrze 16 dp; podpowiedź/błąd 4 dp pod polem; między polami 16 dp; pełna szerokość minus marginesy.

## Tokeny
Tekst `bodyLarge` `onSurface`; etykieta `bodyLarge`→`bodySmall` (uniesiona); podpowiedź `bodySmall` `onSurfaceVariant`; błąd `error`; kształt `shape-xs`.

## Zachowanie
Klawiatura dopasowana (tekst, wielkie litery na początku dla nazw; numer lotu – wielkie litery, bez autokorekty).
Akcja klawiatury „Dalej" przechodzi do następnego pola. Pole przewijane nad klawiaturę. Niedozwolone znaki
(wg `docs/data/model-danych.md` pkt 1) – błąd przy polu z opisem dozwolonych, bez cichego usuwania.
Treść zachowana po powrocie z EK-06/EK-07.

## Dostępność
- Etykieta dla TalkBack: etykieta pola + „wymagane"/„opcjonalne" + podpowiedź; błąd ogłaszany po walidacji.
- Cel dotyku = całe pole (≥ 56 dp); kolejność fokusu zgodna z kolejnością wizualną.
- Kontrast: onSurface/surface ≥ 14:1; onSurfaceVariant/surface ≥ 8,8:1; error/surface ≥ 6,1:1; outline/surface ≥ 4,2:1.
- Skalowanie do 200%: etykieta i podpowiedź zawijają się; pole rośnie.

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `commonOptionalSuffix` | (opcjonalnie) | (optional) |
| `commonFieldRequiredError` | To pole jest wymagane | This field is required |
| `commonFieldTooLongError` | Maksymalnie {max} znaków | Maximum {max} characters |
| `commonFieldCharsError` | Dozwolone są litery, cyfry, spacja i znaki , . - ' ( ) / & | Allowed: letters, digits, space and , . - ' ( ) / & |

## Użycie
EK-05; wzorzec formularz.
