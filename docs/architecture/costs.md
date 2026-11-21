# Szacunek kosztów zmiennych – Tamitu (MVP)

Stan: **2026-11-21 (TAM-4 / ARCH-01 – model wybrany: `gemini-3.1-flash-lite`, MINIMAL, `eu`; tokeny zmierzone)**, autor: architect. Poprzednie wersje: 2026-11-20 (SEC-09 – limit globalny 25/dobę, spend cap), 2026-11-18 (ARCH-01), 2026-11-15 (po G2; scenariusze A/B/C – historia w sekcji 10). **To szacunek, nie wycena.**

> **Status cen modeli (2026-11-18):** stawki tokenów odczytane bezpośrednio z oficjalnej strony cennika Google Cloud (źródło i data w sekcji 1.1) dla kandydatów z ADR-0001 Aneks B pkt 3. **Do weryfikacji w P3-10:** (1) kurs PLN/USD i VAT, (2) SKU w Cloud Billing (rzeczywista stawka w rozliczeniu, w tym mechanizm promocji 3.8 Flash – sekcja 1.1, uwaga c), (3) tokeny rzeczywiste (wejście, wyjście, **myślenie**) – pomiar w teście ARCH-01 (`docs/architecture/arch-01-gemini-test.md`). Do tego czasu liczby służą do porównania modeli i rzędu wielkości budżetu.

Kurs przyjęty: **4,0 PLN za 1 USD** (zaokrąglenie ostrożne; **do weryfikacji w P3-10**). Ceny nie zawierają VAT.

## 0. Wybrany model – `gemini-3.1-flash-lite` (decyzja właściciela 2026-11-21, ADR-0001 Aneks C)

**W skrócie:** jeden plan kosztuje typowo ok. **1,5 grosza**, najdłuższy ok. **5,5 grosza**. Przy obecnych limitach
(25 generowań na dobę dla całej aplikacji) normalne użycie to ok. **12 PLN miesięcznie** – poniżej spend cap dev
(15 PLN) i prod (80 PLN). Drogie jest tylko celowe nadużycie limitu najdłuższymi planami; zatrzymują je spend cap i `budgetGuard`.

Ustawienia: punkt `eu` (stawka „Non-global": 0,275 USD wejście / 1,65 USD wyjście za 1 mln tokenów), `thinkingLevel=MINIMAL`,
buforowanie wyłączone (bez zniżki za cache), `maxOutputTokens` 10 000, maks. 2 próby na generowanie.

**Pomiar ARCH-01 (2026-11-21, prompt testowy, 5 przypadków)** – założenia z sekcji 1 zostają, bo są ostrożniejsze:

| Wielkość | Założenie (sekcja 1) | Zmierzone (3.1 Flash-Lite) | Komentarz |
|---|---|---|---|
| Tokeny wejścia | 1 000 | 711–747 (śr. 724) | prompt produkcyjny P3-05 będzie dłuższy (docelowe liczby punktów na dzień) – zostawiamy 1 000 |
| Wyjście, plan typowy (5 dni, umiarkowane) | 2 100 | 1 495 (C5; ostatni dzień niepełny) | ok. 75 tokenów na punkt – zgodnie z założeniem 80 |
| Wyjście, plan maksymalny (14 dni intensywnie) | 8 100 | 5 180 (C3, ale za mało punktów: ok. 5 zamiast 6–7 dziennie) | po poprawce promptu bliżej 7 500–8 100 – zostawiamy 8 100 |
| Tokeny myślenia | „do zmierzenia" | **0** we wszystkich 5 wywołaniach | przy MINIMAL koszt myślenia pomijamy |
| Czas, plan maksymalny | 10–40 s | 13,1 s | |
| Koszt (szacunek z tokenów) | – | C5: 0,011 PLN; C3: 0,035 PLN; 5 wywołań razem: 0,063 PLN | |

**Koszt wybranego modelu** (wzór i założenia jak w sekcjach 2–4, bez myślenia):

| Pozycja | USD | PLN |
|---|---|---|
| Jedna próba – plan typowy (5 dni) | 0,0037 | **0,015** |
| Jedna próba – plan duży (14 dni umiarkowanie) | 0,0100 | 0,040 |
| Jedna próba – plan maksymalny (14 dni intensywnie) | 0,0136 | **0,055** |
| Miesiąc: 40 planów (5 testerów) | 0,16 | ≈ 0,7 |
| Miesiąc: 200 planów (20 testerów) | 0,82 | ≈ 3,3 |
| Miesiąc: 400 planów (100 użytkowników) | 1,65 | ≈ 6,6 |
| Pułap globalny 25/dobę, plany typowe, +10% ponowień, 30 dób | 3,1 | **≈ 12** |
| Pułap globalny 25/dobę, plany maksymalne, 2 próby, 30 dób (nadużycie) | 20 | ≈ 82 |
| Jedno konto, 5/dobę, plany maksymalne, 2 próby – doba / miesiąc | 0,14 / 4,1 | 0,55 / ≈ 16 |

Wnioski:
- **Dev (cap 15 PLN, budżet 20 PLN):** normalne testy (do 25 planów typowych dziennie) mieszczą się w capie przez cały
  miesiąc (≈ 0,4 PLN/dobę). Pełne nadużycie planami maksymalnymi (≈ 2,75 PLN/dobę) wyczerpie cap po ok. 5 dniach.
- **Prod (cap 80 PLN, budżet 100 PLN):** typowe użycie przy pełnym limicie globalnym ≈ 12 PLN/mies. Pełne nadużycie
  planami maksymalnymi ≈ 82 PLN – tuż powyżej capu 80 PLN; zatrzymuje je cap (z opóźnieniem, ADR-0014 F4) i `budgetGuard`.
- **Ponowienia:** w teście 2 z 5 odpowiedzi nie spełniły reguły liczby punktów. Gdyby tak zostało po P3-05, ponowień
  byłoby ok. 40% zamiast 10% – plan typowy ≈ 0,021 PLN zamiast 0,016 PLN (nadal pomijalnie). Ważniejsze są dłuższy czas
  oczekiwania i ryzyko `ai_invalid_response`. Odsetek ponowień – wskaźnik do śledzenia w P3-05 i pełnej ewaluacji.
- **Zapasowy `gemini-3.5-flash-lite`:** ok. 1,6× drożej wg cennika (w teście 1,9×, bo dłuższe odpowiedzi);
  pułap typowy ≈ 20 PLN/mies. (kolumny w sekcjach 2–4).
- Względem klasy Flash wybrany model jest ok. 5–6× tańszy. Zasada 10: decyzja **obniża** koszt; limity bez zmian.

## 1. Założenia
- Wejście do modelu (prompt systemowy + dane): ok. **1 000 tokenów** (do potwierdzenia pomiarem ARCH-01).
- Wyjście: punkt planu ≈ 80 tokenów (nazwa, miejscowość, opis, godzina, JSON); tytuł dnia ≈ 20.
  - **Typowy:** 5 dni, tempo umiarkowane (5 punktów/dzień) ≈ 2 100 tokenów.
  - **Duży:** 14 dni umiarkowane ≈ 5 900.
  - **Maksymalny:** 14 dni intensywne (7 punktów/dzień) ≈ 8 100 (limit `maxOutputTokens` 10 000).
- **Myślenie (thinking):** tabele w sekcjach 2–4 liczą wyjście **bez** tokenów myślenia. Tokeny myślenia są rozliczane jak wyjście („Text output (response and reasoning)"). `gemini-3.5-flash`, `-3.5-flash-lite`, `-3.1-flash-lite` pozwalają ustawić `thinkingLevel=MINIMAL`; **`gemini-3.8-flash` – najniżej `LOW`** (MINIMAL niedostępne). Narzut na każde 1 000 tokenów myślenia – sekcja 2, kolumna ostatnia; zmierzone w ARCH-01 (2026-11-21): **0** dla `3.1-flash-lite` i `3.5-flash-lite` przy MINIMAL; dla `3.8-flash` (LOW) nie mierzono (etap B pominięty).
- Ponowienia: średnio +10% prób; maksimum 2 próby na generowanie.
- **Punkt końcowy:** multi-region **`eu`** – **potwierdzone testem ARCH-01 2026-11-21** (`europe-west4`: błąd 417 dla obu Flash-Lite; ADR-0001 Aneks C pkt 3). Oba (`europe-west4`, `eu`) rozliczane są stawką **„Non-global"** – stosujemy ją we wszystkich tabelach. `global` (tańszy o ok. 10%) jest zakazany (ADR-0001).
- **Buforowanie wyłączone** (SEC-17 B-1, `disableCache=true`): brak zniżki „cached input" (0,1× ceny wejścia). Przy ok. 1 000 tokenów wejścia na plan wpływ jest pomijalny (wejście to 2–9% kosztu wywołania) – zgodnie z zasadą 10 odnotowane, bez zmiany szacunku.

### 1.1 Cennik kandydatów (USD za 1 mln tokenów, tryb Standard PayGo, kontekst ≤ 200 tys.)
| Model | Status, wycofanie | Wejście Global | Wejście **Non-global** | Wyjście Global | Wyjście **Non-global** |
|---|---|---|---|---|---|
| `gemini-3.8-flash` – promocja do 2026-12-31 (c) | GA, ≥ 2027-09-02 | 0,75 | **0,825** | 3,75 | **4,125** |
| `gemini-3.8-flash` – od 2027-01-01 | jw. | 1,50 | **1,65** | 7,50 | **8,25** |
| `gemini-3.5-flash` | GA, ≥ 2027-05-19 | 1,50 | **1,65** | 9,00 | **9,90** |
| `gemini-3.5-flash-lite` | GA, ≥ 2027-07-21 | 0,30 | **0,33** | 2,50 | **2,75** |
| `gemini-3.1-flash-lite` | GA, ≥ 2027-05-07 | 0,25 | **0,275** | 1,50 | **1,65** |

Źródło: Google Cloud, „Agent Platform Pricing" – https://cloud.google.com/vertex-ai/generative-ai/pricing (przekierowanie na `cloud.google.com/model-garden/pricing`), tabela „Gemini 3 – Standard", odczyt **2026-11-18** (strona renderowana skryptem; odczyt w przeglądarce). Status i daty wycofania: strony modeli `docs.cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/<model>` („Last updated 2026-11-18 UTC").
Uwagi:
- (a) Strona: stawki „Non-global" obowiązują dla modeli GA Gemini 3+ od 2026-07-01; „Price… ≤ 200K input tokens" i „> 200K" są dla tych modeli równe.
- (b) Opłata tylko za żądania z kodem 200; błędy 4xx/5xx nie są rozliczane (strona cennika).
- (c) Przypis przy cenie promocyjnej 3.8 Flash: „Promotional pricing provided through 50% credits back on net spend". **Do weryfikacji w P3-10**, czy rozliczenie idzie po cenie standardowej ze zwrotem w kredytach – wtedy budżety „kredyty nieodliczane" i spend cap (szacunek brutto, ADR-0014 F4) widzą cenę standardową. Dlatego w pułapach (sekcja 4) dla 3.8 Flash stosujemy cenę standardową.
- (d) Strona pokazuje też rodzinę „Gemini 4" – poza kandydatami Aneksu B (nie klasa Flash/Flash-Lite, bez danych o rezydencji w tym zadaniu); nie oceniana.

## 2. Koszt jednej próby generowania (stawki „Non-global", bez myślenia)
| Model | Typowy USD | Typowy PLN | Duży USD | Duży PLN | Maks. USD | Maks. PLN | +1 000 tok. myślenia PLN |
|---|---|---|---|---|---|---|---|
| `gemini-3.8-flash` (promocja do 2026-12-31) | 0,0095 | 0,038 | 0,0252 | 0,101 | 0,0342 | 0,137 | 0,017 |
| `gemini-3.8-flash` (od 2027-01-01) | 0,0190 | 0,076 | 0,0503 | 0,201 | 0,0685 | 0,274 | 0,033 |
| `gemini-3.5-flash` | 0,0224 | 0,090 | 0,0601 | 0,240 | 0,0818 | 0,327 | 0,040 |
| `gemini-3.5-flash-lite` | 0,0061 | 0,024 | 0,0166 | 0,066 | 0,0226 | 0,090 | 0,011 |
| `gemini-3.1-flash-lite` | 0,0037 | 0,015 | 0,0100 | 0,040 | 0,0136 | 0,055 | 0,007 |

Wzór: (1 000 × cena wejścia + tokeny wyjścia × cena wyjścia) / 10⁶. Przykład: 3.8 Flash z myśleniem LOW zużywającym 1 000 tokenów, plan typowy od 2027 = 0,076 + 0,033 ≈ 0,11 PLN.
Język polski zwykle zużywa więcej tokenów na ten sam sens niż angielski; założenia wyjścia mają ten zapas. Pomiar rzeczywisty (tokeny wejścia/wyjścia/myślenia, osobno PL i EN) – test ARCH-01, potem pełna ewaluacja (R15, US-011, N4).

## 3. Scenariusze miesięczne (plan typowy, +10% ponowień, bez myślenia)
| Scenariusz | Planów/mies. | 3.8 Flash (od 2027) | 3.5 Flash | 3.5 Flash-Lite | 3.1 Flash-Lite |
|---|---|---|---|---|---|
| 5 testerów × 8 planów | 40 | 0,83 USD (≈ 3,3 PLN) | 0,99 USD (≈ 3,9 PLN) | 0,27 USD (≈ 1,1 PLN) | 0,16 USD (≈ 0,7 PLN) |
| 20 testerów × 10 planów | 200 | 4,17 USD (≈ 17 PLN) | 4,94 USD (≈ 20 PLN) | 1,34 USD (≈ 5,4 PLN) | 0,82 USD (≈ 3,3 PLN) |
| 100 użytkowników × 4 plany | 400 | 8,35 USD (≈ 33 PLN) | 9,87 USD (≈ 39 PLN) | 2,69 USD (≈ 11 PLN) | 1,65 USD (≈ 6,6 PLN) |

3.8 Flash w promocji (do 2026-12-31): połowa kolumny „od 2027". Plany „duże" kosztują ok. 2,7 razy więcej niż typowe. **Zmiana względem 2026-11-15:** klasa Flash jest ok. 3,4–4× droższa od dawnego scenariusza A (2.5 Flash, wycofany); przy 200 planach/mies. to 17–20 PLN zamiast ok. 5 PLN – nadal w budżecie prod 100 PLN, ale **blisko budżetu dev 20 PLN**, jeśli w dev testuje się na skalę 200 planów.

## 4. Pułapy kosztowe (najgorszy przypadek, bez myślenia; 3.8 Flash po cenie standardowej)
| Pułap | 3.8 Flash | 3.5 Flash | 3.5 Flash-Lite | 3.1 Flash-Lite |
|---|---|---|---|---|
| Jedno konto, doba: 5 generowań × plan maksymalny × 2 próby | 0,68 USD (2,7 PLN) | 0,82 USD (3,3 PLN) | 0,23 USD (0,9 PLN) | 0,14 USD (0,55 PLN) |
| Jedno konto, miesiąc (30 dób, teoretycznie) | 20,5 USD (≈ 82 PLN) | 24,6 USD (≈ 98 PLN) | 6,8 USD (≈ 27 PLN) | 4,1 USD (≈ 16 PLN) |
| **Pułap globalny (obowiązujący): 25 generowań/dobę**, maksymalne plany, 2 próby, 30 dób | 103 USD (≈ 411 PLN) | 123 USD (≈ 491 PLN) | 34 USD (≈ 136 PLN) | 20 USD (≈ 82 PLN) |
| **To samo (25/dobę), plany typowe z 10% ponowień** | 15,7 USD (≈ 63 PLN) | 18,5 USD (≈ 74 PLN) | 5,0 USD (≈ 20 PLN) | 3,1 USD (≈ 12 PLN) |
| *Historycznie: 50/dobę, maksymalne plany, 2 próby, 30 dób* | *205 USD (≈ 822 PLN)* | *246 USD (≈ 982 PLN)* | *68 USD (≈ 271 PLN)* | *41 USD (≈ 164 PLN)* |
| *Historycznie: 50/dobę, plany typowe z 10% ponowień* | *31 USD (≈ 125 PLN)* | *37 USD (≈ 148 PLN)* | *10 USD (≈ 40 PLN)* | *6,2 USD (≈ 25 PLN)* |

Myślenie zwiększa każdy wiersz o (tokeny myślenia / 1 000) × kolumna „+1 000 tok. myślenia" z sekcji 2 na próbę.
Wnioski:
- **Decyzja właściciela 2026-11-20 (O-ARCH01-1, ADR-0014 Aneks A pkt 3): limit globalny 25/dobę** w fazie testów (dev i prod). Pułap przy planach typowych: klasa Flash ≈ 63–74 PLN/mies. – **poniżej spend cap prod 80 PLN i budżetu prod 100 PLN**; Flash-Lite ≈ 12–20 PLN.
- Pułap przy nadużyciu całego limitu globalnego planami maksymalnymi (Flash ≈ 411–491 PLN, 3.5 Flash-Lite ≈ 136 PLN, 3.1 Flash-Lite ≈ 82 PLN) nadal przekracza budżet prod – ten scenariusz zatrzymują twarde warstwy: spend cap `aiplatform` **prod 80 PLN / dev 15 PLN** (ADR-0014, zatwierdzony; z opóźnieniem F4, więc możliwa nadwyżka) i `budgetGuard` (tylko prod, ADR-0003). W `dev` (budżet 20 PLN, cap 15 PLN, bez `budgetGuard`) pułap typowy klasy Flash przy pełnym wykorzystaniu 25/dobę przez cały miesiąc (≈ 63–74 PLN) przekracza cap – w praktyce cap zatrzyma generowanie w dev po ok. 6–7 dniach takiego użycia (≈ 2,1–2,5 PLN/dobę); testy w dev planować z tym zapasem (sekcja 6).
- Dla klasy Flash **jedno konto przy pełnym nadużyciu limitu 5/dobę (≈ 82–98 PLN/mies.) nadal wyczerpuje cap prod 80 PLN** – limit globalny tego nie zmienia (dotyczy jednego konta); ogranicza to cap i przegląd limitów przed wydaniem publicznym (ADR-0002 Aneks A pkt 5b).

## 5. Pozostałe usługi (przy skali testowej)
| Usługa | Koszt | Uwagi |
|---|---|---|
| Cloud Functions 2. gen. | ≈ 0 | pula bezpłatna (2 mln wywołań, 180 tys. vCPU-s, 360 tys. GiB-s); jedno generowanie ≈ 20–40 s przy 512 MiB, rząd 0,001 PLN poza pulą |
| Firestore | ≈ 0 | ok. 3 odczyty i 3 zapisy na generowanie; pula 50 tys./20 tys. dziennie |
| Firebase Auth (Google) | 0 | do 50 tys. MAU |
| App Check / Play Integrity | 0 | pula standardowa Play Integrity (rząd 10 tys. atestacji dziennie, do weryfikacji) |
| Cloud Logging | ≈ 0 | metadane, pula 50 GiB; retencja 30 dni |
| Secret Manager | ≈ 0,06 USD/mies. | 1 sekret (pieprz do skrótu UID) |
| Artifact Registry / Cloud Build (wdrożenia funkcji) | ≈ 0–0,5 USD | pule bezpłatne, drobne opłaty za przechowywanie obrazów |
| Pub/Sub (budżet) | ≈ 0 | |
| Google Maps (link bez API) | 0 | brak Maps SDK, Places, Geocoding |
| **Razem stałe** | **ok. 0–3 PLN/mies.** | wymaga planu Blaze (karta) |

Pozycje tej sekcji nie były ponownie sprawdzane w ARCH-01 (stan 2026-11-15).
Koszty poza zakresem: konto Google Play (jednorazowa opłata), domena/strona polityki, porada prawna, reklamy/subskrypcje (po MVP).

## 6. Koszty testów i CI
- Standardowe testy CI używają atrapy modelu – 0 wywołań.
- **Test ARCH-01 – wykonany 2026-11-21:** etap A, 4 sondy + 10 wywołań, koszt szacunkowy **ok. 0,18 PLN** (3.1 Flash-Lite 0,063 PLN, 3.5 Flash-Lite 0,119 PLN); etap B pominięty. Koszt w Billing – do uzupełnienia przez właściciela (O-TAM4-3). Plan testu (dla porządku): (decyzja właściciela 2026-11-20: najpierw Flash-Lite; jednorazowo, dev, `arch-01-gemini-test.md` sekcja 3): **etap A** – `3.1-flash-lite` i `3.5-flash-lite` (MINIMAL), 4 sondy + 10 wywołań: najgorszy ok. 0,9 PLN, oczekiwany ok. 0,2–0,4 PLN; **etap B** (tylko gdy Flash-Lite nie wystarczy) – `3.8-flash` (LOW), 2 sondy + 5 wywołań: najgorszy ok. 1,7 PLN, oczekiwany ok. 0,6–1,0 PLN. Razem najgorszy ok. 2,6 PLN (wcześniej 4,7 PLN dla 4 modeli); limit testu 3 PLN, skrypt zatrzymuje się po 1,5 PLN (A) / 2,5 PLN (A+B). `3.5-flash` nie jest testowany.
- Ewaluacja pełna (min. 20 przypadków × PL/EN = 40 wywołań, mieszane długości, bez myślenia) na jeden model: 3.8 Flash ok. 1,8 USD (≈ 7,3 PLN), 3.5 Flash ok. 2,2 USD (≈ 8,8 PLN), 3.5 Flash-Lite ok. 0,6 USD (≈ 2,4 PLN), 3.1 Flash-Lite ok. 0,37 USD (≈ 1,5 PLN). **Przebieg dla wszystkich czterech ≈ 20 PLN – cały budżet dev.** Zasada: ewaluacja jednego–dwóch modeli dziennie (najtańsze najpierw), ręcznie lub przy zmianie promptu, **maks. 1 przebieg dziennie na model**, w projekcie `dev`, dane syntetyczne; przed przebiegiem sprawdzić zużycie budżetu dev; spend cap dev 15 PLN (ADR-0014) może zatrzymać ewaluację w trakcie miesiąca – planować przebiegi na początek miesiąca lub tymczasowo podnieść budżet (decyzja właściciela).

## 7. Co najmocniej zmienia koszt
1. Myślenie modelu: 3.8 Flash nie pozwala zejść poniżej `LOW`; każde 1 000 tokenów myślenia ≈ +0,033 PLN (3.8 Flash) na próbę – zmierzyć w ARCH-01.
2. Klasa modelu: Flash vs Flash-Lite – różnica ok. 3–6× (sekcja 2).
3. Koniec promocji 3.8 Flash 2026-12-31 – podwojenie stawki od 2027-01-01.
4. Liczba dni i tempo (liniowo wyjście).
5. Ponowienia przy złym schemacie/języku – limit 2 prób, jakość promptu.
6. Limit na konto i globalny (parametry w `config/runtime`) – sekcja 4.
7. Punkt `eu`/`europe-west4` vs `global`: +10% (świadomy koszt wymogu UE; `global` zakazany).

## 8. Alerty i wyłączniki (patrz ADR-0002, ADR-0003, ADR-0014)
Budżety zatwierdzone przez właściciela (Q3, 2026-11-15; ustawia właściciel): dev 20 PLN, prod 100 PLN, alerty 50/90/100%, automatyczne wyłączenie AI przy 100% prod, limit na konto 5/dobę (doba kalendarzowa Europe/Warsaw, Q5), limit globalny **25/dobę** (decyzja właściciela 2026-11-20, ADR-0014 Aneks A pkt 3; wcześniej 50 – Q3), `maxInstances` 10, `maxOutputTokens` 10 000, kwoty Vertex ograniczone w konsoli. Dodatkowo alert na wyczerpanie limitu globalnego i przegląd limitów przed wydaniem publicznym (ADR-0002, Aneks A pkt 5). Spend cap `aiplatform` (prod 80 / dev 15 PLN) – ADR-0014, **zatwierdzony 2026-11-20** (kwoty ostateczne). `budgetGuard` tylko w prod; w dev: cap + budżet 20 PLN z alertami e-mail (ADR-0014 Aneks A pkt 2). Model startowy: **`gemini-3.1-flash-lite`, MINIMAL, `eu`** (decyzja właściciela 2026-11-21, ADR-0001 Aneks C; wcześniej Aneks B pkt 7 – najpierw Flash-Lite; Q4 – start od Flash); wybór ostateczny potwierdza pełna ewaluacja w fazie 3.

## 9. Koszt wynikający z decyzji G2
Czwarte konto usług, sprawdzanie istnienia użytkownika (jedno wywołanie Admin API na żądanie), handler wyjątków i dodatkowy alert nie zmieniają kosztów w istotny sposób (pula bezpłatna). SQLCipher zwiększa rozmiar APK, nie koszt zmienny.

## 10. Historia
- **2026-11-21 (TAM-4 / ARCH-01):** dodana sekcja 0 – wybrany model `gemini-3.1-flash-lite` (MINIMAL, `eu`), pomiar tokenów i czasu z testu, koszt testu (ok. 0,18 PLN), wpływ ponowień. Punkt `eu` i myślenie 0 – potwierdzone. Stawki, kurs i założenia sekcji 1 bez zmian (ostrożniejsze niż pomiar).
- **2026-11-20 (SEC-09, ARCH-01):** koszt testu ARCH-01 przeliczony dla kolejności „najpierw Flash-Lite" (sekcja 6); limit globalny 50 → 25/dobę (O-ARCH01-1); pułapy w sekcji 4 przeliczone dla 25/dobę (wiersze dla 50/dobę zostawione jako historyczne); ADR-0014 zatwierdzony – spend cap prod 80 / dev 15 PLN ostateczne; `budgetGuard` tylko prod. Stawki i założenia bez zmian.
- **2026-11-18 (ARCH-01):** scenariusze A/B/C zastąpione kandydatami z ADR-0001 Aneks B pkt 3; ceny z oficjalnej strony cennika (stawki „Non-global"); dodane: myślenie (3.8 Flash min. `LOW`), buforowanie wyłączone (B-1), koszt testu ARCH-01, wnioski o pułapach dla klasy Flash. Ostrzeżenie „ceny niezweryfikowane" zastąpione statusem z listą weryfikacji w P3-10.
- **2026-11-15 (po G2):** scenariusze A 0,30/2,50 USD (2.5 Flash – wycofany 2026-10-20), B 1,50/7,50 (nowsza Flash; promocja 0,75/3,75 do 2026-12-31 – odpowiada 3.8 Flash „Global"), C 0,10/0,40 (Flash-Lite 2.x – wycofany); kurs 4,0 PLN/USD. Skrót w ADR-0001 („Szacunek kosztów") pozostaje historyczny – zatwierdzonego ADR nie zmieniamy; aktualne liczby są w tym pliku.
