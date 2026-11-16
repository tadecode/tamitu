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
| Z linkiem do dokumentu | akceptacja polityki | link „politykę prywatności" w treści otwiera przeglądarkę w języku interfejsu (ikona `link-square-02` po linku) |

## Stany
| Stan | Wygląd i zachowanie |
|---|---|
| Domyślny | **niezaznaczony zawsze na start** (RODO; nigdy nie zapamiętujemy zaznaczenia między wersjami) |
| Zaznaczony | pole `primary` ze znacznikiem `onPrimary` (rysuje go widget Checkbox – nie ikona z zestawu); przycisk logowania staje się aktywny |
| Fokus / naciśnięty | warstwa stanu 10% wokół pola |
| Nieaktywny | w trakcie logowania (po dotknięciu „Zaloguj") |
| Ładowanie | n/d |
| Błąd | n/d – brak zaznaczenia nie jest błędem; przycisk nieaktywny z powodem widocznym bezpośrednio nad nim |

## Rozmiary i odstępy
Pole 18 dp w celu 48 dp; tekst `bodyLarge` z wcięciem 16 dp za polem; **cały wiersz (pole + tekst bez linku) jest celem dotyku**; link ma własny cel dotyku min. 48 dp wysokości (odstęp od reszty tekstu przez podział linii, jeśli trzeba).

## Tokeny
Obrys pola `onSurfaceVariant` (niezaznaczone), `primary` (zaznaczone); tekst `onSurface`; link `primary` z podkreśleniem.

## Zachowanie
Dotknięcie wiersza przełącza; dotknięcie linku tylko otwiera dokument (nie zaznacza).
- **Zmiana języka interfejsu zdejmuje zaznaczenie** – akceptacja dotyczy tekstu, który był widoczny (P-3, raport security P3-14c).
- Zaznaczenie żyje tylko w pamięci ekranu: **nie przeżywa zamknięcia aplikacji ani zabicia procesu**; po anulowaniu logowania u Google zostaje tylko w bieżącej sesji ekranu.
- Rekord tymczasowy (`shared_preferences`: `version`, `lang`, `acceptedAt`) powstaje **dopiero przy dotknięciu „Zaloguj"** i jest **czyszczony, jeśli logowanie się nie uda** (anulowanie, błąd, brak sieci); po udanym logowaniu → `recordConsent(privacy_policy)`.

## Dostępność
- Etykieta dla TalkBack: **ten sam tekst co widoczny** („Potwierdzam zapoznanie się z polityką prywatności i akceptuję ją, pole wyboru, niezaznaczone") – bez skrótów i form rodzajowych (P-2); link osobno: „Polityka prywatności, link, otwiera przeglądarkę".
- Cel dotyku 48 dp dla wiersza i linku.
- Kontrast: onSurface/surface ≥ 14:1; primary/surface ≥ 5,4:1; obrys pola onSurfaceVariant/surface ≥ 7,8:1.
- Skalowanie do 200%: tekst zawija się; pole wyrównane do pierwszej linii.

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `consentPolicyCheckbox` | Potwierdzam zapoznanie się z {policyLink} i akceptuję ją | I confirm I have read and accept the {policyLink} |
| `consentPolicyLink` | polityką prywatności | Privacy Policy |

**Jeden klucz i jeden tekst** w CMP-09, EK-02 i EK-03 (dowód akceptacji dotyczy jednego tekstu przypisanego do wersji; P-2). Forma neutralna, bez rodzaju. Brzmienie ostateczne [PRAWNIK] (S16, UX6); zmiana tekstu PL lub EN = nowa wersja polityki/akceptacji.

## Użycie
EK-02, EK-03; wzorzec zgody i uprawnienia.
