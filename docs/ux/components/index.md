# Biblioteka komponentów – Tamitu

- Status: szkic, wersja 0.1 (2026-11-16, ux, P3-14b krok 1)
- Zasada: **ekran składamy wyłącznie z komponentów z tej listy.** Brakuje komponentu → najpierw dodajemy
  go tutaj (z wariantami i stanami), potem używamy. Zmiana komponentu = przegląd wszystkich ekranów,
  które go używają, i wpis w `.farm/log/`.
- Komponenty odwołują się do **ról** i **tokenów** z `design-system.md` (nie do wartości), więc są
  łatwe do zmiany przy przyszłej zmianie marki (wybrany wariant: A „Lazur").
- Wszystkie komponenty to standardowe widgety Material 3 we Flutterze, z dwoma wyjątkami złożonymi
  z widgetów M3 (CMP-18 stan ekranu, CMP-20 punkt planu) – uzasadnienie w ich plikach.

## Konwencja kluczy l10n

Klucze ARB muszą być poprawnymi identyfikatorami Dart (gen_l10n, ADR-0006), więc **lowerCamelCase bez
kropek**: `<obszar><Element><Wariant>`, np. `commonRetry`, `planListEmptyTitle`, `tripFormLodgingHelper`.
Obszary: `common` (wspólne), `appBar`, `planList` (EK-04), `tripForm` (EK-05), `consent` (EK-02/03/06/13),
`generation` (EK-07), `plan` (EK-08), `route` (EK-09/10), `settings-02` (EK-12..15), `error` (EK-16).
Nazwy ostateczne uzgadnia ux z mobile-dev (pytanie UX8). W specyfikacjach komponentów podane są tylko
klucze **wspólne**; klucze ekranowe powstaną w `screens/` (krok 2).

## Katalog

| ID | Komponent | Odpowiednik M3 / Flutter | Główne użycie (ekrany) |
|---|---|---|---|
| CMP-01 | [Pasek górny](app-bar.md) | Top app bar (small) / `AppBar` | wszystkie ekrany poza EK-01 |
| CMP-02 | [Przycisk](button.md) | Common buttons / `FilledButton`, `FilledButton.tonal`, `OutlinedButton`, `TextButton` | wszystkie |
| CMP-03 | [Przycisk pływający rozszerzony](fab.md) | Extended FAB / `FloatingActionButton.extended` | EK-04 |
| CMP-04 | [Pole tekstowe](text-field.md) | Outlined text field / `TextFormField` | EK-05 |
| CMP-05 | [Pole wyboru z listy](dropdown-field.md) | Exposed dropdown menu / `DropdownMenu` | EK-05 (dni, liczba osób) |
| CMP-06 | [Pole daty i godziny](date-time-field.md) | Date picker, Time picker / `showDatePicker`, `showTimePicker` | EK-05 |
| CMP-07 | [Przyciski segmentowe](segmented-button.md) | Segmented button / `SegmentedButton` | EK-02 (język), EK-05, EK-09 |
| CMP-08 | [Chip filtra](filter-chip.md) | Filter chip / `FilterChip` | EK-05 (zainteresowania) |
| CMP-09 | [Pole zgody](consent-checkbox.md) | Checkbox + tekst / `CheckboxListTile` | EK-02, EK-03 |
| CMP-10 | [Lista jednokrotnego wyboru](radio-list.md) | Radio button / `RadioListTile` | EK-09, EK-12 (język) |
| CMP-11 | [Element listy](list-item.md) | List item / `ListTile` | EK-12, EK-13 |
| CMP-12 | [Karta](card.md) | Card (filled) / `Card.filled` | EK-04 (plan), EK-08 (podsumowanie) |
| CMP-13 | [Komunikat w treści](notice.md) | Banner (wariant w treści) / `Card` + ikona, tekst, akcje | EK-04, EK-05, EK-08, EK-09, EK-13 |
| CMP-14 | [Snackbar](snackbar.md) | Snackbar / `SnackBar` | potwierdzenia, „Cofnij" |
| CMP-15 | [Dialog](dialog.md) | Basic dialog / `AlertDialog` | EK-11, EK-14, anulowanie EK-07 |
| CMP-16 | [Arkusz dolny](bottom-sheet.md) | Modal bottom sheet / `showModalBottomSheet` | EK-09, wybór języka |
| CMP-17 | [Wskaźnik postępu i szkielet](progress.md) | Progress indicators / `LinearProgressIndicator`, `CircularProgressIndicator`; szkielet | EK-01, EK-04, EK-07, EK-15 |
| CMP-18 | [Stan ekranu](state-view.md) | złożony z M3 (ikona, tekst, przycisk) | puste, błąd, brak sieci, EK-16 |
| CMP-19 | [Zakładki dni](day-tabs.md) | Primary tabs (scrollable) / `TabBar` + `TabBarView` | EK-08 |
| CMP-20 | [Punkt planu](plan-item.md) | złożony z M3 (`ListTile`-podobny, znacznik pory) | EK-08 |

## Pokrycie ekranów (krok 2: specyfikacje w `../screens/`, makiety w `../mockups/`)

| Ekran | Komponenty |
|---|---|
| EK-01 Start | systemowy ekran powitalny, CMP-17, CMP-15 (dane wyczyszczone), CMP-18 (przerwane usuwanie konta) |
| EK-02 Ekran startowy | CMP-07 (język), CMP-13, CMP-09, CMP-02 |
| EK-03 Ponowna akceptacja | CMP-01, CMP-09, CMP-02 |
| EK-04 Lista planów | CMP-01, CMP-12, CMP-03, CMP-13, CMP-17 (szkielet), CMP-18, CMP-14 |
| EK-05 Formularz | CMP-01, CMP-04, CMP-05, CMP-06, CMP-07, CMP-08, CMP-02, CMP-13 |
| EK-06 Zgoda na AI | CMP-01, CMP-02 (równorzędne), CMP-13 |
| EK-07 Generowanie | CMP-17, CMP-02, CMP-15 |
| EK-08 Widok planu | CMP-01, CMP-12, CMP-13, CMP-19, CMP-20, CMP-15, CMP-14 |
| EK-09 Trasa | CMP-16, CMP-10, CMP-07, CMP-13, CMP-02, CMP-14 |
| EK-11 Usunięcie planu | CMP-15, CMP-14 |
| EK-12 Ustawienia | CMP-01, CMP-11, CMP-16/CMP-10 (język); ekran licencji – systemowy Fluttera |
| EK-13 Prywatność | CMP-01, CMP-11, CMP-13, CMP-02 |
| EK-14 Wylogowanie | CMP-15 |
| EK-15 Usunięcie konta | CMP-01, CMP-13, CMP-02, CMP-17 |
| EK-16 Komunikaty | CMP-18, CMP-13, CMP-14 |
