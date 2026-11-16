# Komponent: CMP-09 Pole zgody

- Status: szkic – **wymaga przeglądu security** (ekrany zgód)
- Autor: ux · Data: 2026-11-16 · Wersja: 0.1
- Odpowiednik Material 3 / Flutter: Checkbox z etykietą / `CheckboxListTile` (etykieta z linkiem jako tekst wzbogacony)

## Cel
Świadome potwierdzenie zapoznania z polityką prywatności przed logowaniem (EK-02) i po zmianie wersji (EK-03).
**Nie służy do zgody na AI** – ta ma dwa równorzędne przyciski (EK-06, CMP-02 outlined ×2), bo odmowa
musi być tak samo łatwa jak zgoda.

## Warianty
| Wariant | Kiedy użyć | Uwagi |
|---|---|---|
| Z linkiem do dokumentu | akceptacja polityki | link „politykę prywatności" w treści otwiera przeglądarkę w języku interfejsu (ikona `open_in_new` po linku) |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | **niezaznaczony zawsze na start** (RODO; nigdy nie zapamiętujemy zaznaczenia między wersjami) |
| Zaznaczony | pole `primary` z ikoną `check` `onPrimary`; przycisk logowania staje się aktywny |
| Fokus / naciśnięty | warstwa stanu 10% wokół pola |
| Nieaktywny | w trakcie logowania (po dotknięciu „Zaloguj") |
| Ładowanie | n/d |
| Błąd | n/d – brak zaznaczenia nie jest błędem; przycisk nieaktywny z powodem widocznym bezpośrednio nad nim |

## Rozmiary i odstępy
Pole 18 dp w celu 48 dp; tekst `bodyLarge` z wcięciem 16 dp za polem; **cały wiersz (pole + tekst bez linku) jest celem dotyku**; link ma własny cel dotyku min. 48 dp wysokości (odstęp od reszty tekstu przez podział linii, jeśli trzeba).

## Tokeny
Obrys pola `onSurfaceVariant` (niezaznaczone), `primary` (zaznaczone); tekst `onSurface`; link `primary` z podkreśleniem.

## Zachowanie
Dotknięcie wiersza przełącza; dotknięcie linku tylko otwiera dokument (nie zaznacza). Zaznaczenie nie jest
zapisywane, dopóki logowanie się nie uda (rekord lokalny tymczasowy wg privacy-checklist).

## Dostępność
- Etykieta dla TalkBack: „Zapoznałem się z polityką prywatności, pole wyboru, niezaznaczone"; link osobno: „Polityka prywatności, link, otwiera przeglądarkę".
- Cel dotyku 48 dp dla wiersza i linku.
- Kontrast: onSurface/surface ≥ 14:1; primary/surface ≥ 6,1:1; obrys pola onSurfaceVariant/surface ≥ 8,8:1.
- Skalowanie do 200%: tekst zawija się; pole wyrównane do pierwszej linii.

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `consentPolicyCheckbox` | Zapoznałem(-am) się z {policyLink} i akceptuję ją | I have read and accept the {policyLink} |
| `consentPolicyLink` | polityką prywatności | Privacy Policy |

Treść ostateczna [PRAWNIK] (privacy-checklist: akceptacja = potwierdzenie zapoznania); forma rodzajowa „(-am)" do decyzji (UX6).

## Użycie
EK-02, EK-03; wzorzec zgody i uprawnienia.
