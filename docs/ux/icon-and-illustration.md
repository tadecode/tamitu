# Ikona aplikacji i ilustracja EK-02 (UX-ICON)

- Status: **zatwierdzony przez właściciela 2026-11-19** („Zatwierdzam wariant A i ilustrację EK-02”): ikona wariant A, ilustracja EK-02 v0.5 (UX-ICON, OBS-DEV-1, OBS-DEV-2 z `docs/qa/verify-p3-04-dev.md`)
- Autor: ux · Data: 2026-11-19 · Wersja: 0.1
- Podgląd do akceptacji: [`mockups/icon-preview.html`](mockups/icon-preview.html) (ikona w maskach launcherów, na różnych tapetach, ikona tematyczna, warstwy ze strefą bezpieczną, szkic okna wyboru konta Google, wariant B, kadry ilustracji) oraz [`mockups/ek-02.html`](mockups/ek-02.html) (ilustracja na ekranie, jasny i ciemny motyw, skala 150%)
- Powiązane: `brand.md` pkt 5 (logo tymczasowe właściciela, kierunek ilustracji), `screens/ek-02.md`, pytanie UX2

## 1. Problem

| Obserwacja | Co widać na telefonie | Rozwiązanie |
|---|---|---|
| OBS-DEV-2 | domyślne logo Fluttera jako ikona launchera i w oknie Google „Wybierz konto, aby nadal używać aplikacji Tamitu Dev" | ikona adaptacyjna Tamitu (pkt 2) |
| OBS-DEV-1 | na EK-02 pusty szary prostokąt (`_HeroPlaceholder`) zamiast ilustracji | ilustracja „tam i tu" w wariancie jasnym i ciemnym (pkt 3) |

Okno wyboru konta Google bierze ikonę i nazwę aplikacji z systemu (ikona launchera) – osobny zasób nie jest potrzebny.

## 2. Ikona aplikacji

### 2.1 Koncepcja
Znak z tymczasowego logo właściciela (`assets/tamitu-mark.svg`): trasa łącząca dwa miejsca, fale morza i koralowy znacznik celu – „tam i tu". Kształty te same co w logo; na potrzeby małych rozmiarów:
- kreski pogrubione (trasa 5 → 5,5; fale 3,5 → 4 jednostki znaku), fale bez przezroczystości (pełne kolory – przeżywają przyciemnianie i warstwę monochromatyczną),
- kropka w znaczniku jako **otwór** (`fill-rule="evenodd"`), przez który widać tło – zawsze w kolorze tła, także w ikonie tematycznej.

### 2.2 Warianty (decyzja właściciela)

| Wariant | Tło | Znak | Ocena ux |
|---|---|---|---|
| **A – zatwierdzony (2026-11-19)** | `#006A6A` (primary, jasny motyw) | trasa `#FFFFFF`, fala 1 `#9CF1F0` (primaryContainer), fala 2 `#4FB3B2`, znacznik `#FFB5A0` (tertiary, ciemny motyw) | wyraźny na jasnych i ciemnych tapetach i w białym oknie Google; kolor marki rozpoznawalny w szufladzie aplikacji |
| B – odrzucony (historia decyzji) | `#F4FBFA` | kolory znaku z logo na jasne tło (`#006A6A`, `#8F4C38`) | najbliższy logo, ale na jasnych tapetach i w białym oknie Google kontur maski znika (1,05:1 do bieli) |

Kontrast elementów znaku do tła w A (WCAG, elementy graficzne – próg 3:1): trasa 6,42:1, znacznik 3,78:1, fala 1 4,97:1; fala 2 2,58:1 – świadomie słabsza (druga fala jest dekoracyjna, kształt ikony niosą trasa i znacznik). Ikona A na tapecie `#0E1514`: 2,88:1 – kształt maski rozpoznawalny, typowy poziom dla ikon w ciemnych kolorach marki.

### 2.3 Pliki źródłowe (`docs/ux/assets/`)

| Plik | Rola | Wymiary | Uwagi |
|---|---|---|---|
| `tamitu-icon-foreground.svg` | warstwa pierwszego planu ikony adaptacyjnej (wariant A) | viewBox 108×108 (= dp) | przezroczyste tło; treść w okręgu o promieniu ok. 30 dp wokół środka (54, 54) |
| `tamitu-icon-background.svg` | warstwa tła | 108×108 | jednolity `#006A6A`; w Androidzie lepiej jako kolor (`@color/ic_launcher_background`) niż jako grafika |
| `tamitu-icon-monochrome.svg` | warstwa monochromatyczna (Android 13+, ikony tematyczne) | 108×108 | jeden kolor (`#000000`); system bierze tylko kanał alfa i nadaje kolory z tapety |
| `tamitu-icon-full.svg` | ikona złożona, pełny kwadrat bez zaokrągleń | 108×108 (eksport 1024 i 512 px) | źródło PNG dla `flutter_launcher_icons` (`image_path`) i ikony w Google Play (512×512, PNG 32-bit); maskę nakłada system / Play |
| `tamitu-icon-alt-light-full.svg` | wariant B – odrzucony, zostaje jako historia decyzji; nie używać | 108×108 | po wyborze B ux przygotuje warstwy B (zmiana kolorów, geometria bez zmian) |

Wszystkie pliki: bez tekstu, filtrów, masek, obrazów rastrowych i odwołań zewnętrznych; same ścieżki, okręgi i prostokąty (konwertowalne do Android VectorDrawable).

### 2.4 Siatka i strefa bezpieczna (ikona adaptacyjna Androida)
- Warstwa: **108×108 dp**; widoczny obszar po masce: **72×72 dp** (środek); system może przesuwać warstwy o kilka dp (paralaksa) i stosuje różne maski (koło, zaokrąglony kwadrat, squircle, kropla).
- **Strefa bezpieczna: okrąg Ø 66 dp** w środku warstwy – cała treść znaku mieści się w Ø ok. 60 dp (zapas 3 dp na paralaksę i wygładzanie). Nie przesuwać ani nie powiększać znaku.
- Tło wypełnia całe 108×108 dp (bez marginesów i zaokrągleń).
- Warstwa monochromatyczna ma **tę samą geometrię** co pierwszy plan (te same współrzędne), żeby ikona tematyczna nie „skakała" względem zwykłej.

### 2.5 Rozmiary wyjściowe

| Cel | Rozmiar | Format |
|---|---|---|
| Ikona adaptacyjna (minSdk 26 – zawsze adaptacyjna) | 108 dp warstwa | VectorDrawable (zalecane) albo PNG na gęstości: mdpi 108, hdpi 162, xhdpi 216, xxhdpi 324, xxxhdpi 432 px na warstwę |
| Ikona tematyczna (API 33+) | jw. | `<monochrome>` w `ic_launcher.xml` |
| Google Play – ikona sklepu (później, przed publikacją) | 512×512 px | PNG 32-bit z `tamitu-icon-full.svg`, bez zaokrągleń i cieni |
| Źródło dla `flutter_launcher_icons` | 1024×1024 px | PNG z `tamitu-icon-full.svg` |

Starsze ikony PNG (`ic_launcher.png` z logo Fluttera w `mipmap-*dpi`) przy minSdk 26 nie są używane przez launcher, jeśli istnieje `mipmap-anydpi-v26/ic_launcher.xml`; należy je **zastąpić lub usunąć**, żeby logo Fluttera nie zostało w APK.

### 2.6 Nazwa pod ikoną i wersja `dev`
- Nazwa pod ikoną bez zmian: `app_name` – „Tamitu" (prod), „Tamitu Dev" (dev); to wystarcza do odróżnienia buildów.
- Propozycja ux: **ta sama ikona w `dev` i `prod`** (bez osobnej plakietki „DEV") – mniej zasobów; jeśli właściciel chce odróżnić ikonę dev, ux przygotuje wariant (np. tło `#4A6363`).

### 2.7 Teksty alternatywne
Ikona launchera nie ma własnego opisu – TalkBack czyta nazwę aplikacji (`app_name`). Do dokumentacji, sklepu i materiałów:

| Klucz (dokumentacja) | PL | EN |
|---|---|---|
| `altAppIcon` | Ikona Tamitu: biała trasa i fale morza prowadzą do koralowego znacznika celu na morskim tle. | Tamitu icon: a white route and sea waves leading to a coral destination pin on a sea-green background. |

## 3. Ilustracja EK-02 „tam i tu"

### 3.1 Koncepcja
Ogólne, bajkowe miejsce bez rozpoznawalnego miasta (`brand.md` pkt 5, decyzja właściciela 2026-11-17): **„tu"** – dom na zielonym wzgórzu z drzewem; **„tam"** – wyspa z latarnią; między nimi morze z żaglówką, słońce nisko nad horyzontem. Przerywana trasa w kolorze `primary` łączy dom ze znacznikiem celu w kolorze `tertiary` – motyw znaku z logo. Zastępuje tymczasową ilustrację z Lizboną (`ek-02-travel-hero.svg`, zostaje w repozytorium jako historia v0.3–v0.4).

| Wariant | Plik | Nastrój | Kolory marki |
|---|---|---|---|
| jasny | `assets/ek-02-illustration-light.svg` | dzień, ciepłe światło, słońce nad morzem | trasa `#006A6A`, znacznik `#8F4C38` / kropka `#FFDBD1` (jak `tamitu-mark.svg`) |
| ciemny | `assets/ek-02-illustration-dark.svg` | noc: gwiazdy, księżyc, zapalone okno i latarnia | trasa `#80D5D4`, znacznik `#FFB5A0` / kropka `#561F0F` (jak `tamitu-mark-dark.svg`) |

Wariant ciemny zastępuje przygaszanie jasnej grafiki (ok. 80% jasności) z EK-02 v0.4 – nie stosować filtra jasności w aplikacji.

### 3.2 Wymiary i kadr
- viewBox **1200×400** (3:1); ok. 4,5–5 KB na plik.
- Na ekranie: pełna szerokość kolumny × **144 dp** (96 dp przy skali tekstu ≥ 150%, ukryta przy 200%), dopasowanie **„cover", wyrównanie do środka** (`BoxFit.cover`, `Alignment.center`), promień `shape-l` (16 dp) nadaje widget – SVG nie ma własnych zaokrągleń.
- **Strefa ważnej treści: x 150–1050, y 50–350.** Sprawdzone kadry (podgląd pkt 6): 328×144 dp (najwęższy telefon – boki przycięte), 560×144 dp (maks. szerokość kolumny – przycięta góra i dół), 328×96 dp. Dom, trasa, znacznik, latarnia i słońce/księżyc są widoczne we wszystkich.

### 3.3 Wymagania techniczne (`flutter_svg`)
- Bez tekstu, filtrów (`feDropShadow`, `feGaussianBlur`), masek, obrazów rastrowych, czcionek i odwołań zewnętrznych.
- Użyte: ścieżki, prostokąty, okręgi, gradienty liniowe i radialny, `stroke-dasharray`, atrybut `opacity` (promień latarni w wariancie ciemnym) – obsługiwane przez `flutter_svg` 2.x.
- Brak cieni – zgodnie z akceptacją właściciela (2026-11-17).

### 3.4 Dostępność i tekst alternatywny
- W aplikacji ilustracja jest **dekoracyjna i wykluczona z semantyki** (TalkBack ją pomija) – bez zmian względem EK-02. Tekst nie leży na grafice, więc kontrast tekstu nie zależy od ilustracji.
- Opis do dokumentacji i materiałów (nie do aplikacji):

| Klucz (dokumentacja) | PL | EN |
|---|---|---|
| `altWelcomeIllustration` | Ilustracja: przerywana trasa prowadzi od domu na wzgórzu przez morze z żaglówką do znacznika celu na wyspie z latarnią. | Illustration: a dashed route leads from a house on a hill across the sea with a sailboat to a destination pin on an island with a lighthouse. |

## 4. Instrukcja dla mobile-dev (po zatwierdzeniu przez właściciela)

ux dostarcza źródła i specyfikację; pliki produkcyjne w `android/` i `assets/` aplikacji przygotowuje mobile-dev (`.claude/agents/ux.md`, „Uprawnienia").

Do implementacji: **wariant A**.

### 4.1 Ikona – zalecane: VectorDrawable, ręcznie (bez nowej zależności)
1. Android Studio → *New → Vector Asset → Local file (SVG)*: zaimportować `tamitu-icon-foreground.svg` → `res/drawable/ic_launcher_foreground.xml` i `tamitu-icon-monochrome.svg` → `res/drawable/ic_launcher_monochrome.xml`, rozmiar **108×108 dp** (bez skalowania). Sprawdzić, że otwór w znaczniku ma `android:fillType="evenOdd"`, a kreski `strokeLineCap="round"`.
2. Kolor tła: `res/values/ic_launcher_background.xml` → `<color name="ic_launcher_background">#006A6A</color>`.
3. `res/mipmap-anydpi-v26/ic_launcher.xml` (i ten sam plik jako `ic_launcher_round.xml`, jeśli manifest go używa):
   `<adaptive-icon>` z `<background android:drawable="@color/ic_launcher_background"/>`, `<foreground android:drawable="@drawable/ic_launcher_foreground"/>`, `<monochrome android:drawable="@drawable/ic_launcher_monochrome"/>`.
4. Usunąć lub zastąpić `mipmap-*dpi/ic_launcher.png` z logo Fluttera (pkt 2.5).
5. Manifest: `android:icon="@mipmap/ic_launcher"` bez zmian; obie odmiany (`dev`, `prod`) korzystają z `main/res`.

### 4.2 Ikona – alternatywa: `flutter_launcher_icons` (dev_dependency)
Gdy zespół woli generator: wyeksportować PNG z SVG (`tamitu-icon-full.svg` → 1024 px; `tamitu-icon-foreground.svg` i `tamitu-icon-monochrome.svg` → 432 px, przezroczyste tło) do katalogu źródłowego poza `res/`, w konfiguracji: `android: true`, `ios: false`, `image_path` (1024), `adaptive_icon_background: "#006A6A"`, `adaptive_icon_foreground`, `adaptive_icon_monochrome`, `min_sdk_android: 26`. Generator nie nadpisuje warstw przesunięciem – sprawdzić wynik z pkt 4.4. Wybór narzędzia należy do mobile-dev (koszt: zależność tylko w czasie budowania).

### 4.3 Ilustracja EK-02
1. Skopiować `ek-02-illustration-light.svg` i `ek-02-illustration-dark.svg` do zasobów aplikacji (np. `assets/images/`, nazwy bez zmian; komentarze w SVG można usunąć) i zarejestrować w `pubspec.yaml`.
2. W `welcome_screen.dart` zastąpić `_HeroPlaceholder` ilustracją: `SvgPicture.asset` (pakiet `flutter_svg` jest już w zależnościach), wybór pliku wg `Theme.of(context).brightness`, `fit: BoxFit.cover`, `alignment: Alignment.center`, w `ClipRRect` z promieniem `Radii.l`; zachować `ExcludeSemantics`, klucz `welcomeHero`, wysokości 144 / 96 dp i ukrycie przy 200% (EK-02 „Układ").
3. Tło pod grafiką na czas ładowania: `surfaceContainerHigh` (jak obecny placeholder), żeby nie było mignięcia.

### 4.4 Sprawdzenie (QA na urządzeniu)
- Launcher: ikona w masce urządzenia (ColorOS i Pixel), brak logo Fluttera; ikona tematyczna włączona (Android 13+) – kształt czytelny.
- Okno Google „Wybierz konto…" pokazuje ikonę Tamitu (zamyka OBS-DEV-2).
- Ekran powitalny systemu (Android 12+) używa ikony adaptacyjnej automatycznie – sprawdzić, że wygląda poprawnie (zmiana koloru tła ekranu powitalnego nie jest częścią tego zadania).
- EK-02: ilustracja w jasnym i ciemnym motywie, kadr na najwęższym ekranie, skala 150% (96 dp) i 200% (ukryta); TalkBack pomija grafikę (zamyka OBS-DEV-1).

## 5. Decyzje właściciela (2026-11-19, „Zatwierdzam wariant A i ilustrację EK-02”)
1. Ikona: **wariant A** (morskie tło `#006A6A`) – zatwierdzony.
2. Ilustracja EK-02 „tam i tu” w wariantach jasnym i ciemnym (zastępuje tymczasową z Lizboną) – zatwierdzona.
3. Ta sama ikona dla `dev` i `prod` (pkt 2.6) – bez osobnej decyzji; obowiązuje propozycja ux (jedna ikona).

Ikona opiera się na **tymczasowym** logo właściciela (UX2). Gdy powstanie logo ostateczne, ikonę trzeba przygotować ponownie wg tej samej siatki (pkt 2.4) – pliki i instrukcja pozostają aktualne.
