# Szacunek kosztów zmiennych – Tamitu (MVP)

Stan: **2026-11-18 (ARCH-01)**, autor: architect. Poprzednia wersja: 2026-11-15 (po G2; scenariusze A/B/C – historia w sekcji 10). **To szacunek, nie wycena.**

> **Status cen modeli (2026-11-18):** stawki tokenów odczytane bezpośrednio z oficjalnej strony cennika Google Cloud (źródło i data w sekcji 1.1) dla kandydatów z ADR-0001 Aneks B pkt 3. **Do weryfikacji w P3-10:** (1) kurs PLN/USD i VAT, (2) SKU w Cloud Billing (rzeczywista stawka w rozliczeniu, w tym mechanizm promocji 3.8 Flash – sekcja 1.1, uwaga c), (3) tokeny rzeczywiste (wejście, wyjście, **myślenie**) – pomiar w teście ARCH-01 (`docs/architecture/arch-01-gemini-test.md`). Do tego czasu liczby służą do porównania modeli i rzędu wielkości budżetu.

Kurs przyjęty: **4,0 PLN za 1 USD** (zaokrąglenie ostrożne; **do weryfikacji w P3-10**). Ceny nie zawierają VAT.

## 1. Założenia
- Wejście do modelu (prompt systemowy + dane): ok. **1 000 tokenów** (do potwierdzenia pomiarem ARCH-01).
- Wyjście: punkt planu ≈ 80 tokenów (nazwa, miejscowość, opis, godzina, JSON); tytuł dnia ≈ 20.
  - **Typowy:** 5 dni, tempo umiarkowane (5 punktów/dzień) ≈ 2 100 tokenów.
  - **Duży:** 14 dni umiarkowane ≈ 5 900.
  - **Maksymalny:** 14 dni intensywne (7 punktów/dzień) ≈ 8 100 (limit `maxOutputTokens` 10 000).
- **Myślenie (thinking):** tabele w sekcjach 2–4 liczą wyjście **bez** tokenów myślenia. Tokeny myślenia są rozliczane jak wyjście („Text output (response and reasoning)"). `gemini-3.5-flash`, `-3.5-flash-lite`, `-3.1-flash-lite` pozwalają ustawić `thinkingLevel=MINIMAL`; **`gemini-3.8-flash` – najniżej `LOW`** (MINIMAL niedostępne). Narzut na każde 1 000 tokenów myślenia – sekcja 2, kolumna ostatnia; liczba tokenów myślenia – **do weryfikacji** testem ARCH-01.
- Ponowienia: średnio +10% prób; maksimum 2 próby na generowanie.
- **Punkt końcowy:** żaden kandydat nie jest wymieniony jako dostępny w `europe-west4`; oczekiwany punkt to multi-region **`eu`** (Aneks B pkt 2, potwierdza test ARCH-01). Oba (`europe-west4`, `eu`) rozliczane są stawką **„Non-global"** – stosujemy ją we wszystkich tabelach. `global` (tańszy o ok. 10%) jest zakazany (ADR-0001).
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
| Pułap globalny: 50 generowań/dobę, maksymalne plany, 2 próby, 30 dób | 205 USD (≈ 822 PLN) | 246 USD (≈ 982 PLN) | 68 USD (≈ 271 PLN) | 41 USD (≈ 164 PLN) |
| To samo, plany typowe z 10% ponowień | 31 USD (≈ 125 PLN) | 37 USD (≈ 148 PLN) | 10 USD (≈ 40 PLN) | 6,2 USD (≈ 25 PLN) |

Myślenie zwiększa każdy wiersz o (tokeny myślenia / 1 000) × kolumna „+1 000 tok. myślenia" z sekcji 2 na próbę.
Wnioski:
- Dla klasy Flash **jedno konto przy pełnym nadużyciu limitu 5/dobę (≈ 82–98 PLN/mies.) wyczerpuje budżet prod 100 PLN**; pułap globalny 50/dobę z planami typowymi (125–148 PLN) też go przekracza. Twarde ograniczenia: `budgetGuard` (ADR-0003) i spend cap `aiplatform` prod 80 PLN / dev 15 PLN (ADR-0014, proponowany). Rekomendacja do decyzji właściciela w P3-09/P3-10: przy wyborze klasy Flash rozważyć **limit globalny 20–30/dobę** w fazie testów; przy Flash-Lite obecne limity mieszczą się w budżecie.
- Dla Flash-Lite pułapy są poniżej budżetu prod poza nadużyciem całego limitu globalnego planami maksymalnymi.

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
- **Test ARCH-01** (8 sond + 20 wywołań, 4 modele × 5 przypadków, jednorazowo, dev): najgorszy przypadek ok. 4,7 PLN, oczekiwany 1–3 PLN; limit 6 PLN, skrypt zatrzymuje się po 5 PLN szacunku (`arch-01-gemini-test.md` sekcja 3).
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
Budżety zatwierdzone przez właściciela (Q3, 2026-11-15; ustawia właściciel): dev 20 PLN, prod 100 PLN, alerty 50/90/100%, automatyczne wyłączenie AI przy 100% prod, limit na konto 5/dobę (doba kalendarzowa Europe/Warsaw, Q5), limit globalny 50/dobę, `maxInstances` 10, `maxOutputTokens` 10 000, kwoty Vertex ograniczone w konsoli. Dodatkowo alert na wyczerpanie limitu globalnego i przegląd limitów przed wydaniem publicznym (ADR-0002, Aneks A pkt 5). Spend cap `aiplatform` (prod 80 / dev 15 PLN) – ADR-0014, **proponowany**. Klasa modelu: start od Flash, wybór ostateczny po ewaluacji w fazie 3 (Q4); rekomendacja zależna od wyników – `arch-01-gemini-test.md` sekcja 7.

## 9. Koszt wynikający z decyzji G2
Czwarte konto usług, sprawdzanie istnienia użytkownika (jedno wywołanie Admin API na żądanie), handler wyjątków i dodatkowy alert nie zmieniają kosztów w istotny sposób (pula bezpłatna). SQLCipher zwiększa rozmiar APK, nie koszt zmienny.

## 10. Historia
- **2026-11-18 (ARCH-01):** scenariusze A/B/C zastąpione kandydatami z ADR-0001 Aneks B pkt 3; ceny z oficjalnej strony cennika (stawki „Non-global"); dodane: myślenie (3.8 Flash min. `LOW`), buforowanie wyłączone (B-1), koszt testu ARCH-01, wnioski o pułapach dla klasy Flash. Ostrzeżenie „ceny niezweryfikowane" zastąpione statusem z listą weryfikacji w P3-10.
- **2026-11-15 (po G2):** scenariusze A 0,30/2,50 USD (2.5 Flash – wycofany 2026-10-20), B 1,50/7,50 (nowsza Flash; promocja 0,75/3,75 do 2026-12-31 – odpowiada 3.8 Flash „Global"), C 0,10/0,40 (Flash-Lite 2.x – wycofany); kurs 4,0 PLN/USD. Skrót w ADR-0001 („Szacunek kosztów") pozostaje historyczny – zatwierdzonego ADR nie zmieniamy; aktualne liczby są w tym pliku.
