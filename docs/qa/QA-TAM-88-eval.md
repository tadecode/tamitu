# QA TAM-88 (P3-05-EVAL): ewaluacja generowania planów na `gemini-3.1-flash-lite`

**W skrócie:** model przeszedł próg ADR-0001 pkt 2 **na granicy: 38/40 = 95,0%** (próg ≥ 95%). Obie porażki
to **HTTP 429** (Vertex odrzucił wywołanie z braku przepustowości), a nie zła odpowiedź modelu. Każda odpowiedź, którą
model zwrócił (38), przeszła walidację **za pierwszym razem**. Koszt rzeczywisty: **ok. 0,41 PLN** według tokenów
(0,51 PLN w liczeniu ostrożnym uruchamiacza). W ręcznej ocenie treść jest realna: nie znalazłem wymyślonych miejsc.
Problemem jest powtarzanie tego samego miejsca w dwóch dniach (3 z 11 ocenionych planów). **Rekomendacja:** model
spełnia próg i może być modelem w dev (TAM-90). Duplikaty miejsc i odporność na 429 warto naprawić osobnymi zadaniami
(niżej). **Decyzja właściciela (2026-11-21, O-TAM88-1): wynik 95,0% przyjęty jako zaliczenie progu, bez przebiegu
kontrolnego; `gemini-3.1-flash-lite` zostaje modelem dla dev (TAM-90).**

## 1. Przebieg

| Pole | Wartość |
|---|---|
| Data, godzina | 2026-11-21, ok. 13:38–13:47 (CET), jeden przebieg |
| Zgoda | właściciel 2026-11-21 (koszt ok. 0,70–1,40 PLN, sufit 2,5 PLN); jeden przebieg `--paid --stop-pln 2.5`, bez powtórek |
| Projekt, punkt | `tamitu-dev-tadecode`, `eu` (`aiplatform.eu.rep.googleapis.com`) |
| Model | `gemini-3.1-flash-lite`, `thinkingLevel=MINIMAL`, prompt produkcyjny `plan-v1` (ta sama ścieżka co `generatePlan`) |
| Zestaw | `eval-p3-05-v1`: 20 fikcyjnych przypadków × PL/EN = 40 generowań, najwyżej 2 próby każde |
| Kod | `main` z `8800da3`; `npm ci` i `npm run build` w `backend/functions` bez błędów |
| Przed przebiegiem | szacunek: 0,70 PLN (1 próba), 0,98 PLN (40% ponowień), najgorzej 1,40 PLN. `--dry-run` (atrapa, bez sieci): 40/40 |
| Token | ustawiony i usunięty w jednym poleceniu PowerShell; nie zapisany nigdzie |

## 2. Wynik liczbowy

| Miara | Wynik |
|---|---|
| **Poprawne w ≤ 2 próbach** | **38/40 = 95,0%** (próg 95%) |
| Poprawne w 1. próbie | 36/40 = 90,0% (ponowienia 10%) |
| Odpowiedzi modelu poprawne w walidacji | **38/38 = 100%**, wszystkie w 1. próbie z odpowiedzią |
| Kody błędów walidacji | **brak** (0 × liczba punktów, godziny, dzień 1, długości, URL, schemat) |
| Błędy wywołań | **HTTP 429 × 6 prób** w 4 generowaniach: E02-pl i E03-en udane w 2. próbie; **E07-en i E08-pl: 429 dwa razy → `ai_unavailable`** |
| Tokeny (38 udanych) | wejście 38 534 (śr. 1 014), wyjście 55 131 (śr. 1 451), myślenie **0** |
| Czas | łącznie 505 s; mediana 8,5 s, średnia 13,1 s, max 40,7 s na generowanie |
| Plan najdłuższy (E03, 14 dni intensywnie) | PL: 29,1 s, 1 próba, 5 509 tokenów wyj.; EN: 40,6 s (429 + ponowienie), 4 961 tokenów |
| **Koszt** | **ok. 0,41 PLN** z tokenów zwróconych przez Vertex. Uruchamiacz pokazał **0,513 PLN**, bo 6 prób z 429 liczy ostrożnie po szacunku (ok. 0,11 PLN), a takie próby zwykle nie są płatne. Kwotę w Billing (D+1) potwierdza właściciel |

Przebieg dotyczy liczby punktów: **zero** błędów „za mało punktów”. W ARCH-01 C3 ten błąd był główny. Prompt i walidacja
P3-05 go usunęły: E03 (14 dni intensywnie) ma 6 punktów w każdym środkowym dniu w obu językach.

### 2.1 Opóźnienia i 429

Błędy 429 i wolne odpowiedzi wystąpiły razem, na początku przebiegu (E02–E08, ok. 4 min). W tym czasie 9 generowań
z jedną próbą trwało 20–41 s, także dla krótkich planów (E04: 2 dni, 25 s). W ARCH-01 najdłuższe wywołanie trwało 13 s.
Od E09 do końca czasy wróciły do normy (2–12 s). To wygląda na chwilowy brak przepustowości współdzielonej puli Vertex
w `eu`, a nie na cechę modelu. Ryzyko dla aplikacji:
- E05-en trwało **40,7 s** w jednej próbie, a limit próby to 45 s (`ATTEMPT_TIMEOUT_MS`). Dwie takie próby z przerwą
  nadal mieszczą się w limicie funkcji 120 s, ale z małym zapasem.
- Przy 429 użytkownik dostaje `ai_unavailable`, a próba jest zwracana (`slotReleased`). Nie traci limitu, ale nie dostaje planu.

## 3. Ocena ręczna K1–K4 (`arch-01-gemini-test.md` sekcja 4.6)

### 3.1 Dobór próbki

Wszystkie 38 planów sprawdziłem automatycznie (walidator K1, te same nazwy w dwóch dniach, prosty test języka).
Ręcznie przeczytałem **11 z 38 planów (29%)**, PL 6 i EN 5, wybranych według ryzyka:

| Plan | Powód wyboru |
|---|---|
| E03-pl, E03-en | najcięższy profil (14 dni, intensywnie, 5 zainteresowań), kształt porażki ARCH-01 C3; najwięcej miejsc (76–77) |
| E20-pl | 14 dni, wieś i region (Toskania): ryzyko wymyślonych lokali |
| E13-en | 12 dni, region z wieloma miejscowościami (Sycylia) |
| E17-pl | 9 dni, 5 zainteresowań, miasto spoza UE (Stambuł), 14 różnych dzielnic |
| E05-pl | góry, rodzina, sezon (przyjazd za 90 dni, czyli w lutym) |
| E11-en | małe miasto (Szklarska Poręba): największe ryzyko wymyślonych atrakcji |
| E16-pl | pusty dzień 1 (przyjazd 22:30) i mały region |
| E07-pl | próg dnia 1 dokładnie 22:00, życie nocne |
| E04-en, E15-en | pusty dzień 1 (20:30 + 3 h) i próg 21:59 |

Pozostałe 27 planów (typowe 2–8 dni, ten sam wzorzec) przejrzałem tylko automatycznie. Wątpliwe miejsca sprawdziłem
wyszukiwarką (same nazwy miejsc, bez innych danych).

### 3.2 Wyniki

| # | Wynik | Uwagi |
|---|---|---|
| K1 kontrakt | **tak** (38/38 odpowiedzi) | schemat, liczba dni, punkty wg tempa, godziny rosnące, dzień 1 od progu (E07: 22:00, E15: 21:59), pusty dzień 1 (E04, E16), długości, brak URL. Odpowiedzi kończyły się bez błędu |
| K2 wydajność | **tak, z uwagą** | E03-pl (odpowiednik C3) 29,1 s < 40 s; myślenie 0 tokenów. Uwaga: E03-en 40,6 s z ponowieniem po 429; opóźnienia z 2.1 |
| K3 fakty | **tak** | **0 miejsc wymyślonych** w 11 planach. Wątpliwe (najwyżej 1 na plan): E03-pl „Ristorante Roma Antica” (nie znalazłem lokalu o tej nazwie; jest podobna „Antica Roma”); E13-en jaskinie Addaura (miejsce istnieje, ale nie jest udostępnione zwiedzającym); E17-pl „Muzeum Chora” (dziś to meczet Kariye, nazwa nieaktualna); E05-pl Jaskinia Mroźna (otwarta sezonowo, a wyjazd jest w lutym). Sprawdzone i istniejące: Dinopark i Chybotek (Szklarska Poręba), Osteria Antico Travaglio (Monteriggioni) i inne |
| K4 użyteczność | **nie** (pkt c) | (a) język: **bez wyjątku** zgodny (11 ręcznie, 38 automatycznie). (b) każde zainteresowanie pojawia się: **tak** w 11/11. (c) **to samo miejsce w dwóch dniach: 3 z 11** (szczegóły niżej). (d)–(e) uwagi w 3 z 11 planów (limit: 1 z 5, czyli ok. 2 z 11) |

Te same miejsca w dwóch dniach (K4 c). Proste porównanie nazw ich nie wyłapuje, bo model zmienia nazwę:
- **E03-en:** „Campo de' Fiori” (dzień 6) i „Campo de' Fiori Morning Market” (dzień 14).
- **E13-en:** „Fontana Pretoria” (dzień 8) i „Piazza della Vergogna” (dzień 12): to ten sam plac, a druga nazwa jest potoczna.
- **E17-pl:** „Restauracja Sultanahmet Koftecisi” (dzień 1) i „Tarihi Sultanahmet Koftecisi Selim Usta” (dzień 2): ten sam lokal.
- Na granicy, nie liczone: E03-pl i E03-en mają Panteon i „Piazza della Rotonda” (plac przed Panteonem) jako osobne punkty.

Uwagi (d)–(e):
- **E20-pl:** 5 punktów ogólnych, bez konkretnego miejsca: „Agroturystyka pod Sieną” (nocleg jako atrakcja), „Winiarnia lokalna
  w Montalcino”, „Sklep z serami Pienza”, „Piknik w winnicach Chianti”, „Widokowy punkt obserwacyjny”.
- **E17-pl:** punkty ogólne („Restauracje w Ortakoy”, „Restauracja Balat”, „Zakupy pamiątek”, „Wypożyczalnia rowerów”).
  Dzień 5: Emirgan (daleko na północ) i powrót do Ortaköy na kolację, czyli przeskok tam i z powrotem.
- **E13-en:** dzień 7 w Isola delle Femmine to 4 słabe punkty (miasto, plaża, ogólna „Trattoria del Porto”, „Torre di avvistamento”).
- Drobne: E05-pl ma nazwy bez polskich znaków („Krupowki”, „Gubalowka”, „Dolina Koscieliska”), choć opisy je mają.
  E03-pl, dzień 12: Hard Rock Cafe przy zainteresowaniu „lokalne jedzenie”.

Co działało bez zarzutu: liczba punktów we wszystkich dniach (także w ostatnich, które w ARCH-01 były za krótkie),
puste i późne dni 1, język, sensowny podział długich planów na okolice (Rzym, Palermo, Toskania, Stambuł), sensowne
wycieczki dzienne (Monreale, Cefalù, Val d'Orcia, Wyspy Książęce).

**Werdykt 4.6:** K1 tak, K2 tak, K3 tak, **K4 nie** (powtórzone miejsca w 3 z 11 planów). Według sekcji 4.6 to jest
próg dopuszczenia modelu startowego, a właściciel wybrał już `gemini-3.1-flash-lite` (ADR-0001 Aneks C). O wyborze
końcowym decyduje pełna ewaluacja (ADR-0001 pkt 2), więc K4 traktuję jako błąd jakości do naprawy, a nie jako odrzucenie modelu.
Plan z powtórzonym miejscem nadal da się używać i nie wprowadza w błąd. Zalecana poprawka niżej.

## 4. Rekomendacja

1. **ADR-0001 pkt 2: próg spełniony.** 38/40 = 95,0% ≥ 95%. Model nie zwrócił ani jednej niepoprawnej odpowiedzi
   (38/38 w 1. próbie). Obie porażki to brak przepustowości Vertex (429), więc inny model by ich nie usunął.
   **Rekomenduję `gemini-3.1-flash-lite` jako model dev (TAM-90)**, gdy spełnione będą pozostałe warunki z
   `deploy-dev-functions.md` (O4-2, B-1, W-1). Model zapasowy i etap B (3.8 Flash) nie są potrzebne.
   Pytanie o liczbę punktów z `p3-05-wymagania-generowania.md` sekcja 7 nie dotyczy tego wyniku, bo nie było błędów liczby punktów.
2. **Zapas jest zerowy.** Przy kolejnym 429 wynik spadłby poniżej progu. Dlatego właściciel decydował (O-TAM88-1),
   czy przyjmuje wynik, czy chce osobnego przebiegu kontrolnego (nowa zgoda, ok. 0,4–0,5 PLN).
   **Odpowiedź właściciela 2026-11-21: wynik 38/40 = 95,0% przyjęty jako zaliczenie progu ADR-0001 pkt 2, bez testu
   kontrolnego. `gemini-3.1-flash-lite` zostaje modelem dla dev (TAM-90).** Zalecenia z pkt 3 i 4 są w Jirze jako
   P3-05-DEDUP (powtórzone miejsca) i P3-05-429 (odporność na przeciążenie).
3. **Duplikaty miejsc (K4 c):** proponuję zadanie dla `plan-v2`: zakaz powtórzeń w prompcie oraz sprawdzenie
   w walidatorze (normalizacja nazw, np. „X” i „X Market”). Pełne wyłapanie nazw potocznych („Piazza della Vergogna”)
   wymagałoby wiedzy o miejscach, więc w MVP wystarczy prompt i prosta reguła.
4. **429 i opóźnienia:** proponuję zadanie: sprawdzić limity i przydział Vertex w `eu` dla `tamitu-dev-tadecode`
   (konsola Quotas), mierzyć udział `ai_unavailable` z kodem 429 w dev i rozważyć dłuższą przerwę przed ponowieniem
   po 429. Dziś to 1–2 s, a chwilowe ograniczenie trwało ok. 4 min. Każda zmiana kosztowa wymaga zgody (zasada 10).
5. **O-TAM18-2 (heurystyka języka):** w 38 planach nie znalazłem pomyłki języka. Wniosek dla architekta: w MVP heurystyka
   nie jest potrzebna.
6. **Punkty ogólne (K4 e)**, np. „Winiarnia lokalna”, „Zakupy pamiątek”: niski priorytet, można je dopisać do zadania z pkt 3 (prompt `plan-v2`).

## 5. Sprzątanie i dane

- Folder `%TEMP%\tamitu-eval-p305\<znacznik>` z planami i `results.csv` usunięty po ocenie. Folder z `--dry-run` też.
  Do repozytorium trafiają tylko liczby i uwagi z tego raportu.
- Przypadki są fikcyjne. Raport nie zawiera danych osobowych, tokenów ani treści odpowiedzi poza nazwami miejsc publicznych.
- Bez wdrożeń, bez zmian w `.github/` i CI. Płatne wywołania: jeden przebieg (44 próby, z tego 6 odrzuconych z kodem 429).
