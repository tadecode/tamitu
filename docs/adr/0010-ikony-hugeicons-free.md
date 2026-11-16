# ADR-0010: Ikony – Hugeicons Free (pakiet `hugeicons` + `flutter_svg`) za własnym widgetem `AppIcon`

- Status: zatwierdzony (właściciel produktu, 2026-11-16: „zatwierdzam ADR-0010 i ADR-0011”)
- Data: 2026-11-16
- Autor (rola): architect
- Zadanie: P3-14c (UX14, UX15; `docs/ux/design-system.md` pkt 8 i 8.1)
- Uzupełnia: ADR-0008 (lista dozwolonych pakietów MVP). ADR-0008 pozostaje bez zmian; ten ADR dopisuje dwie zależności i zasady ich użycia.

## Kontekst
Właściciel zdecydował, że interfejs używa darmowego zestawu Hugeicons „Stroke Rounded" zamiast Material Symbols (UX14, 2026-11-16: „tak zastapić odrazu”). UX sprawdził licencję (UX15) i poprosił architekta o: wpis zależności, sprawdzenie, czy pakiet nie zawiera ikon Pro, ocenę wpływu na APK i wykonalność podmian ikon wbudowanych w widgety Material 3. ADR-0008 wymaga dla każdego dodatkowego pakietu uzasadnienia, przeglądu uprawnień i licencji (T16, SEC-08).

Fakty ze źródeł (pub.dev `hugeicons` – strony pakietu, wersji, licencji, zmian i oceny; github.com/hugeicons/hugeicons – README, LICENSE.md, `packages/flutter`; hugeicons.com/license-agreement, wersja obowiązująca od 14.09.2026; odczyt 2026-11-16):

| Pytanie | Ustalenie |
|---|---|
| Wersja, wydawca | `hugeicons` 4.4.0 (ok. 2026-10-30), zweryfikowany wydawca hugeicons.com, 24 wydania stabilne; numeracja 4.x idzie za wersją biblioteki ikon, bez usuniętego API względem 1.x (changelog) |
| Licencja pakietu | MIT (pub.dev: „Copyright (c) 2024 Halal Labs") |
| Licencja zestawu Free | MIT (repozytorium: „Copyright (c) 2025 Hugeicons"); umowa licencyjna: ikony Free bez konta, klucza i opłat; warunek – zachować notę MIT |
| Zawartość | wyłącznie styl Stroke Rounded (changelog 4.4.0: 6 065 ikon). Zestaw Pro (10 stylów) jest dystrybuowany osobno (npm `@hugeicons-pro/*` z kluczem licencyjnym); na stronach pakietu Flutter brak ikon Pro |
| Reprezentacja | od 1.0.0 **SVG, nie czcionka ikon** (`IconData` usunięte); widget `HugeIcon(icon: HugeIcons.strokeRounded…, color:, size:, strokeWidth:)`; dane ikony jako `List<List<dynamic>>` |
| Zależności | `flutter`, `flutter_svg ^2.0.9` (przechodnio: `vector_graphics`, `xml`, `path_parsing` i in.) |
| Uprawnienia Androida | brak (biblioteki czysto Dart/Flutter) – do potwierdzenia testem manifestu |
| Rozmiar | pub.dev nie podaje; plik `lib/hugeicons.dart` jest bardzo duży (ok. 18 tys. elementów API). Wydawca deklaruje, że do aplikacji trafiają tylko użyte ikony – **deklaracja niezmierzona** |
| Kolor | `color` → `IconTheme.color` → `DefaultTextStyle.color` → `colorScheme.onSurface` (dziedziczenie ról z design systemu działa) |

## Rozważane opcje
1. **Pakiet `hugeicons` (SVG przez `flutter_svg`) za własnym widgetem `AppIcon`** – oficjalny pakiet wydawcy, aktualizowany, MIT; każda ikona jako stała Dart (nieużyte usuwa kompilator AOT). Minusy: dwie nowe zależności (`flutter_svg` z przechodnimi), parsowanie SVG w czasie działania, brak `IconData` (nie działa tam, gdzie Flutter wymaga `IconData`).
2. **Własna czcionka ikon wygenerowana z wybranych SVG Free (np. narzędziem typu IcoMoon/FlutterIcon) w `assets/`** – `IconData`, zgodność ze wszystkimi API, minimalny rozmiar (tylko ~30 ikon). Minusy: ręczny proces przy każdej nowej ikonie, ryzyko niespójności z katalogiem, utrzymanie po stronie zespołu.
3. **Ręcznie skopiowane pliki SVG (~30) do `assets/` + `flutter_svg`** – brak dużego pliku pakietu. Minusy: ręczna aktualizacja, nadal `flutter_svg`.
4. **Zostać przy Material Symbols** (rekomendacja ux przed UX14) – zero zależności. Sprzeczne z decyzją właściciela (UX14) – odrzucone.

Kryteria: zgodność z decyzją właściciela, licencja, uprawnienia (T16), rozmiar APK, utrzymanie, wymienialność.

## Decyzja
**Opcja 1**, z bezpiecznikami:
1. **Zależności dopisane do listy ADR-0008:** `hugeicons` (wersja przypięta w `pubspec.lock`, start od 4.4.0) i `flutter_svg` (przechodnio wymagane; przypięte lockfile). Obie w audycie zależności (SEC-08) i w Dependabot (ekosystem `pub`).
2. **Jedyny punkt użycia: własny widget `AppIcon`** (np. `lib/core/ui/app_icon.dart`) z enumem znaczeń z `design-system.md` pkt 8 („Nowa podróż", „Ustawienia", …) mapowanym na stałe `HugeIcons.strokeRounded…`. Ekrany nie importują `hugeicons` bezpośrednio (reguła w przeglądzie kodu; ewentualnie lint `depend_on_referenced_packages` + test grep). Skutek: wymiana zestawu (opcja 2, powrót do Material) = zmiana jednego pliku.
3. **Podmiany w widgetach M3 (pkt 8.1) – wykonalne bez własnych kopii widgetów**, bo te miejsca przyjmują `Widget`, nie `IconData`:
   | Miejsce | Mechanizm Fluttera |
   |---|---|
   | Przycisk wstecz `AppBar` | `ActionIconThemeData(backButtonIconBuilder: …)` w motywie (albo `leading` z `BackButton`/`IconButton`) |
   | `DropdownMenu` – strzałka | parametr `trailingIcon` (i `selectedTrailingIcon`) |
   | `SegmentedButton` – wybrany | parametr `selectedIcon` |
   | `PopupMenuButton` – „więcej" | parametr `icon` |
   | FAB, `IconButton`, `ListTile`, przyciski z ikoną, `Chip.avatar` | parametry typu `Widget` |
   Wyjątki zgodnie z ux: wybieraki daty i godziny (ikony Material wewnątrz okien), `Checkbox`/`Radio`/znacznik `FilterChip` (rysowane kształty). Gdyby jakiś parametr wymagał `IconData`, miejsce trafia do wyjątków bez zmiany specyfikacji ekranu (zasada z pkt 8.1).
4. **Ikony Pro wykluczone:** w P3-04 (pierwsze użycie) mobile-dev sprawdza w pobranym pakiecie (`.pub-cache`), że stałe mają wyłącznie prefiks `strokeRounded` i że nie ma zasobów wymagających klucza; wynik w opisie PR.
5. **Pomiar rozmiaru (warunek utrzymania decyzji):** w P3-04 porównanie `flutter build apk --release --analyze-size` (flavor `prod`, `arm64-v8a`) przed i po dodaniu pakietu. **Próg akceptacji: przyrost ≤ 1,0 MB** pobieranego APK. Przy przekroczeniu – przejście na opcję 2 (własna czcionka z ikon Free) za tym samym `AppIcon`, bez zmian ekranów; zapis wyniku jako aneks do tego ADR.
6. **Licencje:** ekran licencji open source (`showLicensePage`, wejście w Ustawieniach – zadanie ux dla EK-12). Nota pakietu (Halal Labs 2024) i `flutter_svg` trafiają tam automatycznie z `LicenseRegistry`; notę zestawu ikon (Hugeicons 2025, MIT z repozytorium) dodać jawnie przez `LicenseRegistry.addLicense`. Nie udostępniamy ikon jako zestawu do pobrania; nie używamy znaku Hugeicons w materiałach.
7. **Makiety i dokumentacja** nie zawierają plików ikon (jak dotąd); nazwy ikon z katalogu potwierdza mobile-dev przy implementacji (konwencja nazw: `HugeIcons.strokeRounded` + PascalCase nazwy z katalogu, np. `arrow-left-01` → `strokeRoundedArrowLeft01` – do sprawdzenia w pakiecie).

## Konsekwencje
**Pozytywne:** zgodność z decyzją właściciela; licencja MIT bez kont i kluczy; brak nowych uprawnień i ruchu sieciowego; wymienialność dzięki `AppIcon`.
**Negatywne / ryzyka:** dwie nowe zależności i ich przechodnie (T16) – łagodzone lockfile i audytem; rozmiar APK niezmierzony (próg i plan B w pkt 5); parsowanie SVG przy pierwszym rysowaniu ikony (pomijalne przy ~30 ikonach; qa obserwuje płynność listy planów); dwie różne noty MIT (rok i właściciel) – dołączamy obie.
**Koszty:** brak kosztów zmiennych (CLAUDE.md pkt 10 – bez wpływu); jednorazowo praca mobile-dev nad `AppIcon` i pomiarem.
**Dane osobowe:** brak wpływu.
