# Weryfikacja PR #112 na urządzeniu – MD-ICON (QA-PR-112)

- Autor (rola): qa · Data: 2026-11-20 · Gałąź raportu: `docs/qa-pr-112`
- Weryfikowany kod: PR #112 `feat/MD-ICON`, head `275537c6fb415b508773b3371dc9b557ac98a773`
- Norma: `docs/ux/icon-and-illustration.md` (pkt 2 ikona wariant A, pkt 3 ilustracja, pkt 4.4 sprawdzenie na urządzeniu); EK-02 v0.5 (`docs/ux/screens/ek-02.md`, „Układ”, „Zasoby graficzne”, „Dostępność”); OBS-DEV-1, OBS-DEV-2 (`docs/qa/verify-p3-04-dev.md`)
- Przegląd kodu: `docs/reviews/PR-112.md` (PR #113, `review:ok`)
- Dane: nie logowano się. Okno wyboru konta Google tylko otwarto i anulowano. Na potrzeby raportu wycięto z niego sam nagłówek (ikona i tytuł). Pełnego zrzutu okna nie oglądano, został usunięty. W raporcie nie ma adresu e-mail, nazwy konta, UID ani tokenów.

## 1. Środowisko

| Element | Stan |
|---|---|
| Urządzenie | telefon właściciela (OPPO, ColorOS, Android 13, 1080×2400, gęstość 408), USB. Każde użycie `adb` szło przez `.farm/test-lock.ps1 -Resource device`. Wygaszanie ekranu na czas testu 10 min, potem przywrócone do 15 s |
| Build PR | `flutter build apk --flavor dev --debug` z osobnego worktree (detached `275537c`, tylko do odczytu). `google-services.json` dev był kopiowany z katalogu właściciela tylko na czas buildu (`git check-ignore` potwierdzone, `git status` czysty), a potem usunięty razem z worktree. Zawartości nie odczytywano |
| APK (`aapt dump badging`, lista plików) | pakiet `pl.tadecode.tamitu.dev`, `minSdk 26`, etykieta „Tamitu Dev”. Zasoby ikony: `res/mipmap-anydpi-v26/ic_launcher.xml`, `res/drawable/ic_launcher_foreground.xml`, `res/drawable/ic_launcher_monochrome.xml`. **Brak** plików `mipmap-*dpi/ic_launcher.png` (logo Fluttera). Ilustracje: `assets/images/ek-02-illustration-light.svg` i `-dark.svg` |
| Pomiar | `screencap` (zrzuty wyłącznie poza repozytorium, w katalogu tymczasowym sesji; po teście usunięte), odczyt koloru pikseli ze zrzutów, `uiautomator dump` (drzewo dostępności EK-02), `dumpsys window` (fokus okna), `cmd uimode night` (motyw), `settings system font_scale` (skala tekstu) |
| Stan wyjściowy telefonu | aplikacja niezainstalowana, motyw systemu ciemny, skala tekstu 1.0 |

## 2. Wyniki

### ICON-01 – ikona w szufladzie aplikacji i w wyszukiwarce launchera

| Sprawdzenie | Wynik |
|---|---|
| szuflada (lista alfabetyczna) | ikona Tamitu w masce launchera ColorOS (zaokrąglony kwadrat), podpis „Tamitu Dev”. Logo Fluttera nie występuje |
| kolory w motywie jasnym (piksele zrzutu) | tło `#00696A` (spec `#006A6A`), druga fala `#4EB3B2` (spec `#4FB3B2`), trasa biała, znacznik koralowy z otworem w kolorze tła. Różnice ±1 wynikają z kompresji zrzutu |
| kolory w motywie ciemnym | tło `#005859`: ColorOS w trybie ciemnym przyciemnia ikony wszystkich aplikacji (zachowanie systemu, nie aplikacji). Kształt czytelny |
| geometria | znak mieści się w masce z zapasem, nic nie jest ucięte. Początek trasy (krótki odcinek z kropką) zgodny z `tamitu-icon-foreground.svg` |

**Zaliczony.**

### ICON-02 – ikona na ekranie głównym

Ikonę przeciągnięto z szuflady na ekran główny (ColorOS nie dodaje jej sam). Wynik: ikona w masce, podpis „Tamitu Dev”, czytelna na jasnozielonej tapecie właściciela. Skrót zniknął po odinstalowaniu aplikacji.

**Zaliczony.**

### ICON-03 – ikona tematyczna (warstwa monochromatyczna)

Warstwa `<monochrome>` jest w `ic_launcher.xml` w APK. Na telefonie nie włączano ikon tematycznych: launcher ColorOS ma własne style ikon, a ustawień ikon tematycznych Material You w tym teście nie szukano. Wyglądu ikony tematycznej nie sprawdzono.

**Nie sprawdzono na urządzeniu.** Do sprawdzenia przy okazji na Pixelu lub emulatorze z Pixel Launcher (Android 13+).

### ICON-04 – ekran powitalny systemu (Android 12+)

Zrzut tuż po uruchomieniu: ikona adaptacyjna Tamitu (tło `#006A6A`, znak) na środku białego ekranu powitalnego, bez logo Fluttera. Kolor tła ekranu powitalnego nie należy do zadania (`icon-and-illustration.md` pkt 4.4).

**Zaliczony.**

### ICON-05 – okno wyboru konta Google (OBS-DEV-2)

Na EK-02 zaznaczono zgodę i wybrano „Zaloguj przez Google”. Otworzyło się okno `GoogleSignInActivity`. W nagłówku jest ikona Tamitu (wariant A) i tekst „Wybierz konto – aby nadal używać aplikacji Tamitu Dev”.

**Zaliczony – OBS-DEV-2 zamknięte.**

### EK02-01 – ilustracja w motywie jasnym (OBS-DEV-1)

| Sprawdzenie | Wynik |
|---|---|
| treść | ilustracja dzienna „tam i tu”: dom na wzgórzu z drzewem, przerywana trasa `primary` do znacznika `tertiary`, morze z żaglówką, słońce nad horyzontem, wyspa z latarnią. Szary prostokąt (`_HeroPlaceholder`) nie występuje |
| wymiary | pełna szerokość kolumny, wysokość 366 px = 144 dp przy gęstości 408. Zaokrąglone rogi, bez cienia. Kadr „cover” do środka, wszystkie elementy ważnej treści widoczne |
| układ pozostałych elementów | przełącznik PL/EN, znak słowny, opis, komunikat o prywatności, zdanie o pełnoletności, zgoda, link, przycisk przyklejony do dołu, podpowiedź – bez zmian względem EK-02 v0.4.1 |

**Zaliczony – OBS-DEV-1 zamknięte.**

### EK02-02 – ilustracja w motywie ciemnym

Motyw systemu przełączony na ciemny przy otwartym EK-02 (zmiana na żywo), potem zimny start aplikacji w ciemnym motywie. Wynik: osobny wariant nocny (gwiazdy, księżyc, zapalone okno domu, promień latarni, trasa `#80D5D4`, znacznik `#FFB5A0`). Grafika nie jest przygaszana filtrem (zgodnie z v0.5). Kontrast tekstów nie zależy od grafiki.

**Zaliczony.**

### EK02-03 – duży tekst i język EN

| Wariant | Wynik |
|---|---|
| EN (przełącznik na ekranie), motyw ciemny | teksty EN, ilustracja bez zmian |
| skala tekstu 150% | wysokość ilustracji 243 px ≈ 96 dp, kadr przycięty u góry i u dołu. Dom, trasa, znacznik, latarnia i księżyc są widoczne |
| skala tekstu 200% | ilustracja ukryta, ekran zaczyna się od znaku słownego |

**Zaliczony.** Najwęższego ekranu (328 dp) nie sprawdzano na urządzeniu. Telefon ma ok. 423 dp szerokości, a kadr 328×144 dp jest pokazany w `mockups/icon-preview.html`.

### EK02-04 – dostępność ilustracji

W `uiautomator dump` drzewa dostępności EK-02 (PL, motyw jasny) nie ma żadnego węzła w obszarze ilustracji. Pierwsze węzły to przełącznik języka, a następnie „Tamitu” (nagłówek). Czytnik ekranu pomija grafikę. Kolejność fokusu jest zgodna z EK-02 „Dostępność”.

**Zaliczony.**

### SIGN-12 (regresja) – anulowanie wyboru konta z siecią

Zgoda zaznaczona → „Zaloguj przez Google” → okno wyboru → wstecz. Wynik: powrót na EK-02, snackbar „Logowanie anulowane.”, zgoda nadal zaznaczona. Brak komunikatu błędu i komunikatu o sieci.

**Zaliczony.** Pełnego logowania (wybór konta testowego przez właściciela) nie wykonano. PR nie zmienia kodu logowania, a przepływ do okna Google i anulowanie działa jak w `verify-pr-102.md`.

## 3. Błędy

Brak błędów.

Obserwacje (bez wpływu na werdykt):
- ICON-03: nie sprawdzono, jak ikona tematyczna wygląda na launcherze (warstwa jest w APK; ikona tematyczna ma kształt identyczny z pierwszym planem wg przeglądu).
- Ustalenie #2 z przeglądu (CI nie buduje flavoru `prod`) dalej otwarte. QA także budowało tylko `dev`.

## 4. Werdykt

**PR #112: PRZYJĘTE (`qa:ok`) dla head `275537c`.**

- Ikona wariant A w szufladzie, na ekranie głównym, na ekranie powitalnym systemu i w oknie wyboru konta Google. W APK nie ma logo Fluttera. OBS-DEV-2 zamknięte.
- Ilustracja EK-02 v0.5 w motywie jasnym (dzień) i ciemnym (noc), 144 / 96 dp, ukryta przy 200%, pominięta przez czytnik ekranu. OBS-DEV-1 zamknięte.
- Brak regresji EK-02 (PL i EN) ani anulowania logowania (SIGN-12).

## 5. Sprzątanie

- Telefon: `pl.tadecode.tamitu.dev` odinstalowana (razem ze skrótem na ekranie głównym). Przywrócono motyw ciemny (stan wyjściowy), skalę tekstu 1.0 i wygaszanie po 15 s. Pliki pomocnicze z `/sdcard` usunięte.
- Komputer: worktree buildu usunięty razem z kopią `google-services.json` i plikami APK. Zrzuty ekranu (tylko w katalogu tymczasowym sesji) usunięte.
- Firebase `dev`: nie logowano się, więc nie powstał nowy użytkownik. Tokenu App Check nie rejestrowano.
