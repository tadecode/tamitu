# Marka Tamitu – dwa warianty do wyboru

- Status: **zatwierdzony wariant A „Lazur"** – decyzja właściciela 2026-11-16 (UX1: „Wybieram wariant A"). Wariant B zostaje w dokumencie jako aneks (historia decyzji); nie jest używany.
- Autor: ux · Data: 2026-11-16 · Wersja: 0.1 · Zadanie: P3-14b krok 1
- Podgląd do porównania: [`mockups/brand-preview.html`](mockups/brand-preview.html) (otwórz w przeglądarce; oba warianty, jasny i ciemny motyw)

## 0. Punkt wyjścia

Materiałów marki brak (logo, kolory, czcionki). Decyzja właściciela: „niech ux zaproponuje dwa warianty".
Obie propozycje:

- opierają się wyłącznie na **Material 3** (gotowe widgety Fluttera, zero komponentów spoza M3 tylko „dla marki"),
- mają **jasny i ciemny motyw**, z kontrastem sprawdzonym wg WCAG 2.1 AA (pkt 4),
- wpinają się w **tę samą bibliotekę komponentów** (`components/`): komponenty opisują role kolorów
  (np. `primary`, `secondaryContainer`), nie konkretne wartości. Wybór wariantu zmienia tylko tokeny
  w `design-system.md`; ekranów nie trzeba projektować drugi raz,
- nie wymagają pobierania niczego z sieci w działającej aplikacji (czcionki dołączone do aplikacji,
  bez pobierania z Google Fonts w czasie działania – prywatność i tryb offline).

Nazwa produktu pochodzi od „tam i tu" – oba warianty grają tym motywem: **A** przez „tam" (morze, horyzont,
spokój podróży), **B** przez „tu" (ciepło miejsca, słońce, dachówki, lokalność).

---

## 1. Wariant A – „Lazur" (morski, spokojny, rzeczowy) – **wybrany**

### Charakter
Spokojny, czysty, budzący zaufanie. Morska zieleń kojarzy się z wodą, horyzontem i mapą, a jednocześnie
jest „neutralna" dla treści: plan dnia, zgody i komunikaty czyta się bez wrażenia reklamy. Ciepły akcent
koralowy (tertiary) dodaje podróżniczego charakteru w małych dawkach (oznaczenia godzin, wyróżnienia).
Ton: rzeczowy przewodnik – konkretnie, krótko, uprzejmie.

### Paleta
- **Kolor bazowy (seed) M3:** `#006A6A` (morska zieleń, ton 40)
- **Kolory kluczowe:** primary `#006A6A` · secondary `#4A6363` (szarozielony) · tertiary `#8F4C38` (koral/cegła) · error `#BA1A1A` (standard M3)
- **Neutralne:** lekko zielonkawe szarości (surface jasny `#E6EDEC` – przyciemniony 2026-11-16 na prośbę właściciela, wcześniej `#F4FBFA`; ciemny `#0E1514`)

| Rola | Jasny | Ciemny | Użycie w Tamitu |
|---|---|---|---|
| primary / onPrimary | `#006A6A` / `#FFFFFF` | `#80D5D4` / `#003737` | główne działanie (Generuj, Zaloguj), aktywna zakładka dnia, linki |
| primaryContainer / on | `#9CF1F0` / `#002020` | `#004F4F` / `#9CF1F0` | rozszerzony FAB „Nowa podróż", wyróżniona karta |
| secondaryContainer / on | `#C4E2E1` / `#051F1F` | `#324B4B` / `#CCE8E7` | wybrane chipy i segmenty, **komunikat informacyjny (np. o AI)** |
| tertiary / tertiaryContainer | `#8F4C38` / `#FFDBD1` | `#FFB5A0` / `#723523` | akcent: godzina przylotu, znacznik pory dnia |
| error / errorContainer | `#BA1A1A` / `#FFDAD6` | `#FFB4AB` / `#93000A` | błędy pól, baner błędu, działania destrukcyjne |
| surface / onSurface | `#E6EDEC` / `#161D1D` | `#0E1514` / `#DDE4E3` | tło ekranów, tekst |

Pełny zestaw ról (surfaceContainer*, outline, inverse*) – `design-system.md` pkt 2.

### Typografia
- **Roboto** (systemowa czcionka Androida i domyślna we Flutterze) dla wszystkich stylów skali M3.
- Koszt: 0 KB w aplikacji, pełne polskie znaki, bardzo dobra czytelność na małych ekranach.
- Charakter budowany kolorem i odstępami, nie krojem pisma.

### Kształty
Domyślna skala M3: xs 4 · s 8 · m 12 · l 16 · xl 28 dp; przyciski i chipy wyboru z pełnym zaokrągleniem
(pill) wg M3. Wrażenie: uporządkowane, „aplikacyjne".

### Ikonografia
**Hugeicons, darmowy zestaw Stroke Rounded** (kreska 1,5 dp, zaokrąglone zakończenia) – decyzja właściciela 2026-11-16 (UX14), zastępuje pierwotnie proponowane Material Symbols Outlined. Licencja i pakiet do potwierdzenia przez architekta (UX15). Zaokrąglona kreska łagodzi rzeczowy charakter wariantu A. Ikony zawsze z etykietą tekstową lub opisem dla TalkBack. Słownik i ikony wbudowane w widgety M3: `design-system.md` pkt 8.

### Przykładowe użycie
Lista planów na tle `surface`, plany jako karty `surfaceContainerLow` z tytułem miasta (titleMedium)
i datą (bodyMedium, `onSurfaceVariant`). „Nowa podróż" – rozszerzony FAB `primaryContainer`.
W widoku planu: pasek zakładek dni w `primary`, godzina przylotu oznaczona koralowym akcentem (`tertiary`),
informacja „Plan stworzony przez AI…" jako komunikat `secondaryContainer` z ikoną.

---

## 2. Wariant B – „Terakota" (ciepły, wakacyjny, przyjazny) – **odrzucony** (aneks)

### Charakter
Ciepły, słoneczny, „wakacyjny": terakota przypomina dachówki południowych miast, piasek i zachód słońca.
Bardziej wyrazisty i rozpoznawalny niż A, przyjaźniejszy w odbiorze, mniej „urzędowy". Chłodny niebieski
akcent (tertiary) jako przeciwwaga – niebo, woda. Ton: życzliwy towarzysz podróży – ciepło, ale konkretnie.

### Paleta
- **Kolor bazowy (seed) M3:** `#9B4419` (terakota, ton 40)
- **Kolory kluczowe:** primary `#9B4419` · secondary `#76574A` (ciepły brąz) · tertiary `#3F5F90` (błękit) · error `#BA1A1A`
- **Neutralne:** ciepłe, kremowe szarości (surface jasny `#FFF8F5`, ciemny `#1A120E`)

| Rola | Jasny | Ciemny | Użycie w Tamitu |
|---|---|---|---|
| primary / onPrimary | `#9B4419` / `#FFFFFF` | `#FFB692` / `#552000` | główne działanie, aktywna zakładka dnia, linki |
| primaryContainer / on | `#FFDBCB` / `#351000` | `#7A2E04` / `#FFDBCB` | rozszerzony FAB „Nowa podróż", wyróżniona karta |
| secondaryContainer / on | `#FFDBCF` / `#2C160C` | `#5C4034` / `#FFDBCF` | wybrane chipy i segmenty, komunikat informacyjny |
| tertiary / tertiaryContainer | `#3F5F90` / `#D6E3FF` | `#A9C7FF` / `#264777` | akcent: godzina przylotu, znacznik pory dnia |
| error / errorContainer | `#BA1A1A` / `#FFDAD6` | `#FFB4AB` / `#93000A` | błędy, działania destrukcyjne |
| surface / onSurface | `#FFF8F5` / `#221A16` | `#1A120E` / `#F1DFD8` | tło ekranów, tekst |

### Typografia
- **Nunito** (zaokrąglony krój bezszeryfowy, licencja SIL OFL 1.1, pełne polskie znaki) dla stylów
  display, headline i title (grubość 700 / 600).
- **Roboto** dla stylów body i label (czytelność długich tekstów: zgody, plan dnia).
- Koszt: czcionka **dołączona do aplikacji** jako zasób (ok. 2 pliki, rząd wielkości +0,3 MB APK);
  nie pobierać jej w czasie działania (pakiet pobierający z Google Fonts wysyłałby żądania do Google –
  sprzeczne z minimalizacją danych i trybem offline). Pytanie do architekta: UX5.

### Kształty
Bardziej miękka skala: xs 8 · s 12 · m 16 · l 24 · xl 32 dp; przyciski pill. Wrażenie: przyjazne, „miękkie".

### Ikonografia
**Material Symbols Rounded** (wypełnienie 0, grubość 400, rozmiar optyczny 24); fill 1 dla stanu aktywnego.
Zaokrąglone zakończenia pasują do Nunito.

### Przykładowe użycie
Kremowe tło `surface`, karty planów w `surfaceContainerLow` z większym promieniem (16 dp), nazwy miast
w Nunito. „Nowa podróż" – FAB w kolorze `primaryContainer` (jasna brzoskwinia). Godzina przylotu
oznaczona błękitnym akcentem (`tertiary`).

---

## 3. Porównanie

| Kryterium | A „Lazur" | B „Terakota" |
|---|---|---|
| Pierwsze wrażenie | spokojne, godne zaufania, „narzędzie" | ciepłe, wakacyjne, „przyjaciel" |
| Rozpoznawalność wśród aplikacji podróżniczych | średnia (turkus i niebieski są częste) | wyższa (ciepłe kolory rzadsze) |
| Odróżnienie działania od błędu | **bardzo dobre**: morska zieleń i czerwień błędu leżą naprzeciw siebie na kole barw | **słabsze**: terakota i czerwień błędu mają zbliżony odcień i tę samą jasność (ton 40); konieczne konsekwentne ikony i teksty przy błędach (i tak wymagane), większe ryzyko pomyłki „przycisk = ostrzeżenie" |
| Odróżnienie komunikatu informacyjnego od błędu | **dobre**: `secondaryContainer` `#C4E2E1` (miętowy) vs `errorContainer` `#FFDAD6` (różowy) | **słabe w jasnym motywie**: `secondaryContainer` `#FFDBCF` i `errorContainer` `#FFDAD6` są prawie identyczne – komunikat „Plan stworzyła AI" wygląda jak błąd (widać w podglądzie). Przy wyborze B trzeba by użyć innej roli dla informacji (np. `tertiaryContainer`, błękit) |
| Ekrany zgód, prywatności, usuwania konta | neutralne, nie wyglądają na reklamę | ciepłe, przyjazne; trzeba pilnować, by przycisk „Usuń konto" (error) nie zlewał się z primary |
| Czytelność długich tekstów | Roboto w całości | Roboto w treści, Nunito w tytułach – dobra |
| Koszt dla dewelopera | najniższy: domyślna typografia i kształty M3 | niewielki: dołączenie czcionki, własna skala kształtów w motywie |
| Rozmiar aplikacji | +0 | ok. +0,3 MB |
| Kontrast WCAG AA (pkt 4) | spełniony w obu motywach | spełniony w obu motywach |
| Ciemny motyw | chłodny, „nocny" | ciepły, brązowy; przyjemny wieczorem |

## 4. Kontrast (WCAG 2.1 AA)

Policzono współczynnik kontrastu wg wzoru WCAG (luminancja względna sRGB) dla par używanych w komponentach.
Próg: tekst 4,5:1, elementy interfejsu i duży tekst 3:1. **Wszystkie pary w obu wariantach i obu motywach spełniają próg.** Kolumna „A jasny” po przyciemnieniu jasnego motywu (2026-11-16); kolumny B – stan z dnia porównania (aneks).

| Para (tekst / tło) | Próg | A jasny | A ciemny | B jasny | B ciemny |
|---|---|---|---|---|---|
| onPrimary / primary (przycisk wypełniony) | 4,5 | 6,42 | 7,73 | 6,49 | 7,76 |
| onPrimaryContainer / primaryContainer (FAB) | 4,5 | 13,24 | 7,28 | 13,26 | 7,32 |
| onSecondaryContainer / secondaryContainer (chip, komunikat) | 4,5 | 12,53 | 7,25 | 13,27 | 7,28 |
| onTertiaryContainer / tertiaryContainer | 4,5 | 13,28 | 7,25 | 13,28 | 7,24 |
| onErrorContainer / errorContainer (baner błędu) | 4,5 | 13,26 | 7,24 | 13,26 | 7,24 |
| onError / error (przycisk destrukcyjny) | 4,5 | 6,46 | 7,72 | 6,46 | 7,72 |
| onSurface / surface (tekst główny) | 4,5 | 14,41 | 14,33 | 16,29 | 14,33 |
| onSurfaceVariant / surface (tekst pomocniczy) | 4,5 | 7,83 | 10,90 | 8,84 | 10,85 |
| onSurfaceVariant / surfaceContainerHighest (podpowiedź w polu) | 4,5 | 6,30 | 7,25 | 7,20 | 7,21 |
| onSurface / surfaceContainerLow (tekst na karcie) | 4,5 | 13,51 | 13,26 | 15,51 | 13,27 |
| primary / surface (przycisk tekstowy, link) | 4,5 | 5,41 | 10,90 | 6,18 | 10,87 |
| primary / surfaceContainerLow (link na karcie) | 4,5 | 5,07 | 10,09 | 5,88 | 10,07 |
| error / surface (tekst błędu pola) | 4,5 | 5,44 | 10,89 | 6,15 | 10,88 |
| tertiary / surface (akcent jako tekst) | 4,5 | 5,43 | 10,89 | 6,15 | 10,82 |
| inverseOnSurface / inverseSurface (snackbar) | 4,5 | 11,56 | 10,15 | 11,62 | 10,23 |
| inversePrimary / inverseSurface (akcja snackbara) | 4,5 | 7,73 | 4,98 | 7,76 | 5,04 |
| outline / surface (obrys pola, checkboxa) | 3,0 | 3,77 | 5,84 | 4,29 | 5,84 |
| onSurfaceVariant / surfaceContainerLow (opis na karcie, arkusz) | 4,5 | 7,35 | 10,08 | 8,41 | 10,05 |
| tertiary / surfaceContainerLow (godzina przylotu na karcie) | 4,5 | 5,09 | 10,08 | 5,85 | 10,02 |
| onSurfaceVariant / surfaceContainerHigh (treść dialogu) | 4,5 | 6,68 | 8,48 | 7,59 | 8,42 |
| error / surfaceContainerHigh (działanie destrukcyjne w dialogu) | 4,5 | 4,64 | 8,48 | 5,28 | 8,44 |
| primary / surfaceContainerHighest (pasek postępu na torze) | 3,0 | 4,35 | 7,26 | 5,04 | 7,22 |

Uwaga: primary i error mają w obu wariantach ten sam ton (współczynnik między nimi ok. 1,0), więc **jasność
ich nie odróżnia** – odróżnia je tylko odcień. W A odcienie są przeciwstawne, w B bliskie. Reguła wspólna
(`patterns.md`): błąd zawsze ma ikonę i tekst, nigdy sam kolor.

Kontrast trzeba ponownie sprawdzić po implementacji motywu (zrzuty ekranu) i wpisać do `accessibility.md`
(krok 2, przy ekranach).

## 5. Elementy wspólne obu wariantów

- **Kolory dynamiczne Androida (Material You) wyłączone** – propozycja (UX3): kolory z tapety zmieniłyby
  markę i unieważniły sprawdzony kontrast.
- **Motyw jasny/ciemny wg ustawienia systemu** – propozycja (UX4); bez przełącznika w Ustawieniach w MVP
  (EK-12 go nie przewiduje).
- **Ton komunikacji:** zwracamy się na „Ty" (PL) / „you" (EN), krótkie zdania, czasowniki w przyciskach
  („Generuj plan", „Usuń plan"), bez wykrzykników i żargonu technicznego; o danych i AI mówimy wprost.
  Propozycja do potwierdzenia (UX6).
- **Logo i ikona aplikacji:** brak. Do czasu dostarczenia przez właściciela: znak słowny „Tamitu"
  zapisany stylem headlineSmall w kolorze primary i tymczasowa ikona adaptacyjna (litera „T" w kolorze
  onPrimary na tle primary) – tylko do wersji testowych. Pytanie UX2.
- **Ilustracje:** brak w MVP; stany puste i błędy używają dużej ikony Material (48 dp) – zero kosztu,
  spójne z ikonografią. Pytanie UX7.

## 6. Rekomendacja ux: **Wariant A „Lazur"** – przyjęta przez właściciela 2026-11-16

Uzasadnienie:
1. **Bezpieczeństwo interakcji:** w aplikacji z działaniami nieodwracalnymi (usuwanie planu i konta) oraz
   zgodami odróżnienie „działania" od „błędu/zagrożenia" ma znaczenie. W A morska zieleń i czerwień są
   wyraźnie różne; w B terakota i czerwień błędu są blisko, a w jasnym motywie kontener informacji
   i kontener błędu są niemal tego samego koloru.
2. **Zaufanie przy danych osobowych i AI:** spokojna, chłodna paleta lepiej pasuje do ekranów zgód,
   prywatności i informacji „plan stworzony przez AI, możliwe błędy" – nie wygląda na reklamę.
3. **Najniższy koszt:** domyślna typografia i kształty M3, brak dodatkowych zasobów; szybsza implementacja
   P3-04/06/07.
4. **Podróżniczy charakter zachowany** dzięki koralowemu akcentowi (tertiary) i morskiej bazie.

Kiedy wybrać B: jeśli ważniejsza jest wyrazistość i rozpoznawalność marki w sklepie niż powyższe;
wtedy reguła „błąd = ikona + tekst + kolor" staje się krytyczna, przycisk „Usuń konto" poza ekranem
potwierdzenia wymaga wariantu outlined z ikoną, a komunikaty informacyjne przechodzą na `tertiaryContainer`
(błękit) – zmiana w CMP-13 i `design-system.md` pkt 2.3.

Możliwe też połączenie (do decyzji właściciela): paleta A z typografią Nunito z B – koszt jak w B.
