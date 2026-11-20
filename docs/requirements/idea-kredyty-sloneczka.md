# Pomysł: przedpłacone kredyty „słoneczka" zamiast subskrypcji (analiza wstępna)

- Zadanie: **AN-CREDITS** (Azure Boards, work item 194), autor: analyst, stan: **2026-11-20, szkic do dyskusji**
- Źródło: pomysł właściciela z 2026-11-20 – zamiast subskrypcji użytkownik kupuje przedpłacone kredyty „słoneczka" o określonej ważności i zużywa je na generowanie planów przez AI.
- Motywacja właściciela: (1) ceny tokenów mogą wzrosnąć, a właściciel nie chce do usługi dopłacać; (2) planer podróży jest używany epizodycznie (kilka razy w roku), więc subskrypcja słabo pasuje.
- **Realizacja po MVP.** Dokument nie zmienia zakresu MVP (`scope.md`), ADR ani rejestru danych. Liczby to szacunek do porównań, nie cennik.
- Wejścia: `docs/vision.md` (model biznesowy), `docs/requirements/scope.md` (sekcja „Później"), `docs/architecture/costs.md` (stan 2026-11-20), ADR-0002 (limity, rezerwacja slotu, Q12), ADR-0014 (limit globalny 25/dobę, spend cap), `docs/security/personal-data-register.md`.

## 0. Najważniejsze wnioski

1. **Model ma sens ekonomiczny przy klasie Flash-Lite**: koszt AI jednego „słoneczka" (≈ plan typowy) to ok. 0,02–0,05 PLN, a przychód netto z paczki ok. 0,21–0,35 PLN – marża ok. 85–90% i zapas na **co najmniej ok. 4–7-krotny wzrost cen tokenów** (największa paczka; mniejsze więcej). Przy klasie Flash (od 2027) zapas spada do ok. 1,4–2,3× – wtedy ceny paczek trzeba podnieść albo przelicznik oprzeć na Flash-Lite.
2. **Słoneczko to jednostka usługi („1 plan typowy"), a nie tokenów.** Ryzyko wzrostu cen tokenów dla sprzedanych kredytów zostaje po stronie TadeCode; ogranicza je marża, ważność 12 miesięcy, mały rozmiar paczek i zmiana cen tylko dla nowych zakupów. Czy można zmienić przelicznik dla już kupionych słoneczek – pytanie do prawnika (P-L5).
3. **Limity dzienne zostają jako bezpiecznik**, ale limit globalny 25/dobę jest nie do pogodzenia ze sprzedażą: płacący użytkownik zablokowany przez cudzy ruch to reklamacja. Przed sprzedażą limit globalny trzeba przeskalować do budżetu i liczby opłaconych słoneczek (to już wymaga przegląd z ADR-0002 Aneks A pkt 5b).
4. **Kluczowe kwestie prawne** (wygasanie przedpłaconych środków, odstąpienie od umowy dla treści cyfrowych, saldo przy usunięciu konta, retencja zapisów transakcji) trzeba rozstrzygnąć przed implementacją – dołączyć do pakietu pytań do prawnika razem z SEC-30.
5. **Nowe dane osobowe**: historia zakupów i księga salda powiązane z UID (nowe pozycje rejestru, prawdopodobnie z dłuższą retencją niż obecne dane) – do oceny przez Security.

## 1. Model

### 1.1 Przelicznik „plan = N słoneczek"

Zasada: użytkownik płaci za **wynik** (wygenerowany plan), nie za tokeny ani model. Wybór modelu pozostaje decyzją techniczną (ADR-0001) i nie jest widoczny w cenie.

| Rozmiar planu (liczba dni) | Słoneczka | Uzasadnienie (wyjście modelu, `costs.md` sekcja 1) |
|---|---|---|
| 1–5 dni | **1** | do ok. 2 900 tokenów wyjścia (5 dni, tempo intensywne) |
| 6–10 dni | **2** | do ok. 5 800 tokenów |
| 11–14 dni | **3** | do ok. 8 100 tokenów (maks. plan, `maxOutputTokens` 10 000) |

- Tempo zwiedzania nie zmienia ceny (prostota komunikacji); różnica kosztu tempa mieści się w marży.
- Ponowienie techniczne (2. próba po złym schemacie, ADR-0002) **nie** kosztuje użytkownika dodatkowo.
- Wariant „plan premium" (wyższa klasa modelu, np. Flash, za 2× słoneczek) – możliwy później; **na start nie** (pytanie OC9).
- Funkcje późniejsze (np. przegenerowanie jednego dnia) – osobna, mniejsza stawka do ustalenia, np. 1 słoneczko.

### 1.2 Koszt AI jednego słoneczka

Na podstawie `costs.md` (stawki „Non-global", kurs 4,0 PLN/USD, bez VAT). „Najdroższy w paśmie" = plan o największym koszcie na słoneczko, czyli 5 dni w tempie intensywnym (≈ 2 900 tokenów wyjścia, 1 słoneczko).

| Model | Oczekiwany: plan typowy, +10% ponowień | Ostrożny: najdroższy w paśmie, +10% ponowień, +1 000 tokenów myślenia | Skrajny: najdroższy w paśmie, 2 próby, +1 000 tokenów myślenia na próbę |
|---|---|---|---|
| `gemini-3.1-flash-lite` | 0,017 PLN | 0,030 PLN | 0,054 PLN |
| `gemini-3.5-flash-lite` | 0,026 PLN | 0,048 PLN | 0,088 PLN |
| `gemini-3.8-flash` (od 2027-01-01) | 0,084 PLN | 0,149 PLN | 0,270 PLN |
| `gemini-3.5-flash` | 0,099 PLN | 0,177 PLN | 0,322 PLN |

Koszty infrastruktury (Functions, Firestore, weryfikacja zakupu) przy tej skali ≈ 0,001 PLN na operację – pomijalne (`costs.md` sekcja 5). **Do weryfikacji** po pomiarze tokenów w ARCH-01 i P3-10.

### 1.3 Paczki i orientacyjne ceny

Założenia przychodu netto (do weryfikacji przez właściciela/księgowość):
- cena w Google Play jest ceną **brutto z VAT 23%** (Google Play rozlicza VAT od sprzedaży konsumentom w UE);
- prowizja Google Play **15%** (program dla małych deweloperów do 1 mln USD przychodu rocznie – **wymaga zapisania się**; bez programu 30%) liczona od ceny bez VAT;
- poza rachunkiem: podatek dochodowy, ZUS, koszty stałe (konto Play, prawnik, domena).

Wzór: netto = brutto / 1,23 × 0,85.

| Paczka (robocze nazwy) | Słoneczka | Cena brutto | Netto dla TadeCode | Netto / słoneczko | Marża przy 3.1 Flash-Lite (ostrożny) | Marża przy 3.8 Flash (ostrożny) | Zapas na wzrost cen (3.1 / 3.5 Flash-Lite, ostrożny) |
|---|---|---|---|---|---|---|---|
| Start | 10 | 4,99 zł | 3,45 zł | 0,345 zł | 91% | 57% | 11× / 7× |
| Podróżnik | 30 | 11,99 zł | 8,29 zł | 0,276 zł | 89% | 46% | 9× / 6× |
| Obieżyświat | 100 | 29,99 zł | 20,72 zł | 0,207 zł | 86% | 28% | 7× / 4× |

- „Zapas na wzrost cen" = ile razy mogą wzrosnąć ceny tokenów, zanim koszt ostrożny zrówna się z przychodem netto. Przy 3.8 Flash zapas to ok. 1,4–2,3× – za mało, jeśli plany miałyby trafiać do klasy Flash.
- Wskazówka dla właściciela: **najmniejsza paczka powinna wystarczyć na jedną podróż** (np. 2–3 plany z przegenerowaniem), największa nie powinna być większa niż roczne zużycie aktywnego użytkownika (ogranicza ryzyko z sekcji 2.1).
- Ceny w Play Console ustawia się per kraj; dla innych walut Google proponuje przeliczenie – do ustalenia przy wydaniu poza PL.

### 1.4 Darmowy próg na start

- Propozycja: **5 słoneczek jednorazowo** po pierwszym zalogowaniu i akceptacji polityki (ok. 5 planów typowych), **ważne 3 miesiące**.
- Koszt na konto: ok. 0,09–0,15 PLN przy Flash-Lite (ostrożnie), ok. 0,75 PLN przy 3.8 Flash. Przy 1 000 nowych kont/mies.: ok. 90–150 PLN/mies. (Flash-Lite) – istotne przy obecnym budżecie prod 100 PLN; budżet trzeba przeliczyć przed wydaniem publicznym.
- Alternatywa: mały odnawialny przydział (np. 2 słoneczka miesięcznie, bez kumulacji) – lepiej pasuje do „planera epizodycznego", ale jest droższy i bardziej podatny na farmy kont. Decyzja: OC3.
- Ochrona przed farmami kont: przydział tylko dla konta z ważną atestacją App Check / Play Integrity; jeden przydział na UID (nie da się go odnowić usunięciem i ponownym założeniem konta – do potwierdzenia, bo to wymaga zachowania śladu po usuniętym koncie, por. P-L4).

### 1.5 Ważność

- Propozycja: **12 miesięcy od daty zakupu, osobno dla każdej paczki**; darmowe słoneczka 3 miesiące.
- Zużycie w kolejności **najwcześniej wygasających** (najpierw darmowe, potem najstarsze paczki).
- Informacja o dacie ważności: przy zakupie, na ekranie salda i (opcjonalnie) przypomnienie przed wygaśnięciem – kanał do ustalenia (w MVP brak powiadomień push).
- Dopuszczalność wygasania przedpłaconych kredytów w PL/UE – **pytanie do prawnika P-L1**; jeśli wygasanie budzi wątpliwości, wariant awaryjny: dłuższa ważność (24 miesiące) lub ważność liczona od ostatniego zakupu/użycia.

### 1.6 Relacja do obecnych limitów (ADR-0002, ADR-0014)

| Warstwa | Dziś (MVP, testy) | Z kredytami (propozycja) |
|---|---|---|
| Saldo słoneczek | – | Nowa, pierwsza bramka biznesowa: brak salda → komunikat i zachęta do zakupu, bez wywołania modelu |
| Limit na konto | 5 generowań/dobę (Europe/Warsaw) | Zostaje jako ochrona przed nadużyciem (przejęte konto, błąd klienta). Propozycja: **5/dobę dla kont bez zakupu, 15/dobę dla kont z zakupem** (OC6). Liczy generowania, nie słoneczka |
| Limit globalny | 25/dobę (ADR-0014 Aneks A pkt 3) | **Nie może zostać na 25/dobę przy sprzedaży.** Każde generowanie jest opłacone z góry, więc limit globalny staje się bezpiecznikiem awaryjnym (atak, błąd), a nie budżetowym; wartość skalowana do budżetu i opłaconego salda w obiegu (przegląd ADR-0002 Aneks A pkt 5b) |
| `budgetGuard`, spend cap | Wyłączają AI przy 100% budżetu / capu | Zostają; zatrzymanie AI blokuje też płacących – budżet i cap trzeba ustawić z zapasem nad przewidywanym zużyciem opłaconym, a komunikat „AI chwilowo niedostępne" nie pobiera słoneczek |
| Zwrot przy błędzie | Slot wraca przy błędzie systemu; nie wraca po anulowaniu, gdy model ruszył (Q12) | Słoneczko **pobierane dopiero po skutecznym dostarczeniu planu** (rezerwacja → zatwierdzenie); błąd systemu, `ai_unavailable` i anulowanie przed odbiorem → brak pobrania. Różni się od Q12 dla limitu dziennego – do decyzji (OC7) |

## 2. Ryzyka

### 2.1 Wzrost cen tokenów a już sprzedane kredyty

Zobowiązanie TadeCode = niewykorzystane, niewygasłe słoneczka × koszt ostrożny. Przykład: 10 000 słoneczek w obiegu × 0,048 PLN (3.5 Flash-Lite) ≈ 480 PLN; po 3-krotnym wzroście cen ≈ 1 440 PLN – nadal poniżej przychodu netto z ich sprzedaży (≈ 2 070–3 450 PLN).

Mechanizmy ochrony (do wyboru, nie wykluczają się):
1. **Marża jako bufor** – cena paczki tak, by zapas na wzrost cen wynosił min. 3–4× przy modelu domyślnym (sekcja 1.3).
2. **Ważność 12 miesięcy** – ogranicza czas ekspozycji; ceny modeli Vertex zmieniają się zwykle przy nowych generacjach, a modele mają znane daty wycofania (`costs.md` 1.1).
3. **Zmiana cen i przelicznika tylko dla nowych zakupów** – nowe ceny paczek w Play Console w każdej chwili. Zmiana przelicznika dla już kupionych słoneczek – tylko jeśli dopuści to regulamin i prawo (P-L5); domyślnie zakładamy, że **nie**.
4. **Elastyczny wybór modelu** – przelicznik nie obiecuje konkretnego modelu; przy wzroście cen pośrednik może przejść na tańszy model spełniający próg jakości (reguła z ADR-0001 Aneks B).
5. **Rozsądny rozmiar paczek** – brak bardzo dużych paczek „hurtowych"; ewentualny limit salda (np. maks. 300 słoneczek na koncie).
6. **Monitoring kosztu na słoneczko** – metryka „koszt AI / pobrane słoneczko" (dla data-analyst) i alert przy przekroczeniu progu (np. 50% przychodu netto na słoneczko).
7. **Rezerwa** – w budżecie prod uwzględnić koszt pokrycia salda w obiegu (decyzja właściciela).

### 2.2 Nadużycia

| Ryzyko | Skutek | Ograniczenie (wymaganie, bez decyzji technicznej) |
|---|---|---|
| Farmy kont dla darmowego progu | Koszt AI bez przychodu | Mały próg, atestacja aplikacji, jeden przydział na UID, limit dzienny dla kont bez zakupu |
| Podrobione / powtórzone potwierdzenia zakupu | Słoneczka bez zapłaty | Weryfikacja każdego zakupu po stronie serwera w Google Play; jednokrotne zaliczenie zakupu (idempotencja po identyfikatorze zamówienia) |
| Zakup → zużycie → zwrot pieniędzy | Koszt AI bez przychodu | Obsługa unieważnionych zakupów (zwrot, chargeback): odjęcie słoneczek, saldo może spaść poniżej zera, blokada zakupu/generowania do wyrównania; powtarzalne przypadki – blokada konta (regulamin) |
| Manipulacja saldem w aplikacji | Darmowe generowania | Saldo wyłącznie po stronie serwera; aplikacja tylko wyświetla |
| Przejęte konto zużywa saldo | Strata użytkownika, reklamacja | Limit dzienny na konto; historia operacji widoczna dla użytkownika |
| Płatności odroczone (np. gotówka w kiosku) | Zaliczenie przed zapłatą | Zaliczenie słoneczek dopiero po potwierdzeniu płatności przez Google Play |

### 2.3 Zwroty

- W pierwszych 48 h zwrot zwykle obsługuje Google Play (użytkownik sam w Play); później deweloper w Play Console. Oba przypadki muszą odjąć słoneczka (powiadomienie Google o unieważnieniu).
- Prawo odstąpienia od umowy (14 dni) dla treści cyfrowych – wyłączone tylko przy wyraźnej zgodzie konsumenta na natychmiastowe spełnienie i potwierdzeniu utraty prawa (P-L2). Do ustalenia: czy dotyczy całej paczki, czy niewykorzystanej części.
- Reklamacja jakości planu (zły plan) – czy zwracamy słoneczko? Propozycja: ręcznie, przez wsparcie, bez automatu (OC10).
- Zwrot przy usunięciu konta – P-L4, OC8.

### 2.4 Pozostałe ryzyka

- **Model biznesowy w wizji**: `vision.md` zakłada reklamy + subskrypcję (plan jednorazowy, plan roczny). Kredyty zmieniają ten model – wymaga decyzji właściciela i aktualizacji wizji (OC5).
- **Dostępność usługi**: płacący użytkownik przy `ai_unavailable` (budżet, cap, awaria Vertex) – ryzyko reklamacji i ocen w sklepie.
- **Zasady Google Play**: treści cyfrowe w aplikacji muszą być sprzedawane przez Google Play Billing (lub dozwolone w EOG alternatywne rozliczenia); polityka dotycząca wirtualnej waluty i wygasania – do sprawdzenia przez architekta.
- **Księgowość i podatki**: rozpoznanie przychodu z przedpłat i wygasłych kredytów, rozliczenie z Google – poza zakresem farmy, do księgowej właściciela.
- **Małoletni**: zakupy przez dzieci – kontrola rodzicielska po stronie Google Play; regulamin i wiek użytkownika – P-L3.

## 3. Szkic user stories (później)

Szkic do dyskusji; po decyzji właściciela historyjki zostaną rozbite na pliki `US-NNN` wg `docs/_templates/user-story.md`. Wszystkie: **Priorytet: później (po MVP)**. Wartości (5 darmowych, 12 miesięcy itd.) to propozycje domyślne z sekcji 1.

### US-K01: Darmowe słoneczka na start
**Jako** nowy użytkownik **chcę** dostać kilka darmowych słoneczek, **aby** wypróbować generowanie planów bez płacenia.
- Dane osobowe: saldo i zapis przydziału powiązane z UID (nowa pozycja rejestru)
- **Given** konto zalogowane po raz pierwszy, z zaakceptowaną polityką **When** otwieram aplikację **Then** saldo wynosi 5 słoneczek z datą ważności 3 miesiące od przydziału.
- **Given** konto, które już otrzymało przydział **When** wyloguję się i zaloguję ponownie (także na innym urządzeniu) **Then** przydział nie jest przyznawany drugi raz.
- **Given** żądanie bez ważnej atestacji aplikacji **When** serwer przyznaje przydział **Then** przydział nie jest przyznany, a błąd jest zapisany w logu bez danych osobowych.

### US-K02: Zakup paczki słoneczek
**Jako** użytkownik **chcę** kupić paczkę słoneczek w Google Play, **aby** generować kolejne plany.
- Dane osobowe: identyfikator zamówienia, produkt, czas, status zakupu powiązane z UID
- **Given** lista paczek **When** otwieram ekran zakupu **Then** widzę liczbę słoneczek, cenę brutto z Google Play, ważność oraz informację o prawie odstąpienia (treść wg prawnika).
- **Given** zatwierdzona i opłacona transakcja w Google Play **When** serwer potwierdzi zakup **Then** saldo rośnie o liczbę słoneczek z paczki, z datą ważności 12 miesięcy od zakupu, a zakup jest oznaczony w Google Play jako zużyty.
- **Given** ten sam zakup zgłoszony ponownie (powtórzenie, druga instalacja) **When** serwer go weryfikuje **Then** słoneczka nie są doliczone drugi raz.
- **Given** potwierdzenie zakupu, którego Google Play nie potwierdza **When** serwer go weryfikuje **Then** saldo się nie zmienia, a użytkownik widzi komunikat o nieudanym zakupie.
- **Given** płatność odroczona (oczekująca) **When** zakup jest w stanie „oczekujący" **Then** saldo się nie zmienia, a użytkownik widzi „Płatność w toku"; po potwierdzeniu płatności słoneczka są doliczone.
- **Given** zakup zakończony, ale aplikacja zamknięta przed potwierdzeniem **When** użytkownik ponownie otworzy aplikację **Then** zakup zostaje dokończony i saldo zaktualizowane.

### US-K03: Saldo i historia
**Jako** użytkownik **chcę** widzieć saldo, daty ważności i historię operacji, **aby** wiedzieć, ile planów mogę jeszcze wygenerować.
- **Given** saldo w kilku pulach o różnej ważności **When** otwieram ekran salda **Then** widzę sumę oraz liczbę słoneczek z najbliższą datą wygaśnięcia.
- **Given** wykonane operacje (przydział, zakup, zużycie, zwrot, wygaśnięcie, korekta) **When** otwieram historię **Then** każda pozycja ma datę, rodzaj i liczbę słoneczek, bez treści planów.
- **Given** formularz podróży **When** wybieram liczbę dni **Then** przed generowaniem widzę koszt planu w słoneczkach i saldo po operacji.

### US-K04: Zużycie słoneczek przy generowaniu
**Jako** użytkownik **chcę**, żeby słoneczka były pobierane tylko za dostarczony plan, **aby** nie tracić ich na błędach.
- **Given** saldo ≥ koszt planu **When** plan zostanie wygenerowany i dostarczony **Then** saldo maleje o koszt planu (1/2/3 wg liczby dni), najpierw z puli najwcześniej wygasającej.
- **Given** saldo < koszt planu **When** naciskam „Generuj" **Then** model nie jest wywoływany, widzę brak słoneczek i przejście do zakupu.
- **Given** błąd systemu, `ai_unavailable` lub 2 nieudane próby **When** generowanie się kończy **Then** saldo jest bez zmian.
- **Given** anulowanie przez użytkownika przed dostarczeniem planu **When** generowanie się kończy **Then** saldo jest bez zmian (propozycja; OC7).
- **Given** dwa równoczesne żądania przy saldzie wystarczającym na jedno **When** oba trafiają do serwera **Then** realizowane jest tylko jedno, drugie dostaje „brak słoneczek".
- **Given** wyczerpany limit dzienny na konto lub globalny **When** naciskam „Generuj" **Then** obowiązuje dotychczasowy komunikat limitu (US-011), a saldo jest bez zmian.

### US-K05: Wygaśnięcie słoneczek
**Jako** użytkownik **chcę** wiedzieć, kiedy słoneczka wygasną, **aby** zdążyć je wykorzystać.
- **Given** pula, której data ważności minęła (doba Europe/Warsaw) **When** sprawdzam saldo lub generuję plan **Then** słoneczka z tej puli nie są liczone ani pobierane, a w historii jest wpis „wygaśnięcie" z liczbą słoneczek.
- **Given** pula wygasająca w ciągu 30 dni **When** otwieram ekran salda **Then** widzę ostrzeżenie z datą i liczbą słoneczek.
- **Given** ekran zakupu **When** przeglądam paczkę **Then** ważność jest podana przed zatwierdzeniem płatności.

### US-K06: Zwrot lub unieważnienie zakupu
**Jako** właściciel produktu **chcę**, żeby zwrot pieniędzy odejmował słoneczka, **aby** nie ponosić kosztu AI za niezapłacone plany.
- **Given** zakup zwrócony lub unieważniony w Google Play **When** serwer otrzyma informację o unieważnieniu **Then** saldo maleje o słoneczka z tej paczki (także poniżej zera), a w historii jest wpis „zwrot".
- **Given** saldo ujemne **When** naciskam „Generuj" **Then** model nie jest wywoływany, widzę informację o zaległym saldzie.

### US-K07: Usunięcie konta z niewykorzystanym saldem
**Jako** użytkownik **chcę** wiedzieć, co stanie się z moimi słoneczkami przy usunięciu konta, **aby** świadomie podjąć decyzję.
- **Given** saldo > 0 **When** rozpoczynam usuwanie konta (US-010) **Then** przed potwierdzeniem widzę liczbę niewykorzystanych słoneczek i skutek usunięcia (treść wg prawnika – P-L4).
- **Given** potwierdzone usunięcie konta **When** proces usuwania się kończy **Then** saldo i księga salda są usunięte lub zanonimizowane, z wyjątkiem zapisów transakcji, które trzeba przechowywać z mocy prawa (zakres i czas wg prawnika; RODO art. 17 ust. 3 lit. b).
- **Given** usunięte konto **When** ta sama osoba założy konto ponownie **Then** saldo nie jest przywracane (propozycja; OC8).
- Usuwanie konta **nigdy nie jest blokowane** saldem ani saldem ujemnym (spójnie z ADR-0011 pkt 4).

## 4. Pytania do prawnika (pakiet z SEC-30)

Dołączyć do tej samej konsultacji co SEC-30 (ostateczne teksty zgód, [PRAWNIK]) – jedna konsultacja, jeden koszt.

| # | Pytanie | Propozycja robocza |
|---|---|---|
| P-L1 | Czy w PL/UE można sprzedawać konsumentom przedpłacone kredyty na usługę cyfrową z terminem ważności (12 mies.), po którym przepadają bez zwrotu? Minimalna ważność, wymogi informacyjne, ryzyko klauzuli niedozwolonej? | 12 mies. od zakupu, jasno podane przed zakupem |
| P-L2 | Prawo odstąpienia od umowy (14 dni) dla treści/usług cyfrowych (ustawa o prawach konsumenta, dyrektywa 2011/83/UE): jaka treść zgody i potwierdzenia utraty prawa przy zakupie paczki; czy częściowe zużycie paczki zmienia sytuację; rola polityki zwrotów Google Play | Zgoda na natychmiastowe spełnienie przy zakupie; zwrot niewykorzystanej części w 14 dni – do oceny |
| P-L3 | Regulamin usługi: wymagane elementy (opis słoneczek, przelicznik, ważność, zwroty, reklamacje, zmiany cen, blokada przy nadużyciach, wiek użytkownika, prawo właściwe); relacja do warunków Google Play | Osobny regulamin Tamitu + odesłanie do warunków Google Play |
| P-L4 | Usunięcie konta z niewykorzystanym saldem (RODO art. 17): czy saldo może przepaść, czy trzeba je zwrócić lub zaproponować zwrot? Jakie zapisy transakcji wolno/trzeba zachować (art. 17 ust. 3 lit. b, przepisy podatkowe/rachunkowe) i jak długo, skoro sprzedawcą wobec konsumenta jest Google Play? Czy wolno zachować pseudonimowy ślad, by darmowy próg nie był przyznawany ponownie? | Przepada po wyraźnym ostrzeżeniu; zachowujemy tylko minimum zapisów transakcji |
| P-L5 | Czy regulamin może przewidywać zmianę przelicznika (plan = N słoneczek) dla już kupionych słoneczek, np. przy wzroście kosztów dostawcy? | Nie – zmiany tylko dla nowych zakupów |
| P-L6 | Dyrektywa 2019/770 (treści i usługi cyfrowe): odpowiedzialność za zgodność „planu" z umową, reklamacje jakości wygenerowanych planów (AI) | Reklamacja przez wsparcie, zwrot słoneczka uznaniowo |
| P-L7 | Czy niewykorzystane i wygasłe przedpłaty wymagają szczególnego ujęcia (podatki, VAT jako bon jednego przeznaczenia), skoro VAT rozlicza Google Play? | Do księgowej właściciela |

## 5. Wymagania techniczne do przekazania (bez decyzji)

### 5.1 Dla architekta (osobny ADR po MVP)

1. **Google Play Billing**: produkty jednorazowe **konsumowalne** (po jednym na paczkę), osobne zestawy w `dev` i `prod`; obsługa stanów zakupu (oczekujący, zakupiony), dokończenia zakupu po restarcie aplikacji, testy przez testerów licencyjnych Play. Zgodność z zasadami Play dla wirtualnej waluty i z alternatywnym rozliczeniem w EOG (jeśli dotyczy).
2. **Weryfikacja zakupu po stronie serwera**: pośrednik (Cloud Functions, region UE) sprawdza token zakupu w Google Play Developer API przed zaliczeniem słoneczek; idempotencja po identyfikatorze zamówienia/tokenie; potwierdzenie i zużycie zakupu w terminie wymaganym przez Google (inaczej automatyczny zwrot); obsługa powiadomień o zmianach (zwroty, unieważnienia) i okresowe uzgadnianie z listą unieważnionych zakupów.
3. **Księga salda**: zapis tylko przez serwer, tylko dopisywanie (przydział, zakup, rezerwacja, pobranie, zwolnienie, wygaśnięcie, zwrot, korekta); saldo wyliczane z księgi lub utrzymywane transakcyjnie razem z nią; pule z datą ważności, zużycie od najwcześniej wygasającej; doba wygaśnięcia w `Europe/Warsaw`; dopuszczalne saldo ujemne po zwrocie.
4. **Integracja z `generatePlan`**: rezerwacja słoneczek w tej samej transakcji co rezerwacja limitu (ADR-0002, krok 5), zatwierdzenie po walidacji wyniku, zwolnienie przy błędzie; współbieżność (dwa żądania, jedno saldo).
5. **Parametry w `config/runtime`**: przelicznik (pasma dni → słoneczka), darmowy próg i jego ważność, limity dzienne dla kont z zakupem i bez; zmiana bez wdrożenia.
6. **Limity i budżet**: przegląd limitu globalnego i budżetów przed sprzedażą (ADR-0002 Aneks A pkt 5b); zachowanie przy `budgetGuard` / spend cap bez pobierania słoneczek.
7. **Metryki kosztów**: koszt AI na pobrane słoneczko, słoneczka w obiegu i wygasające (zakres zdarzeń – data-analyst, zgodnie z RODO).
8. **Koszt (zasada 10)**: weryfikacja zakupów i księga – pule bezpłatne Functions/Firestore; prowizja Google Play 15/30% jako koszt sprzedaży.

### 5.2 Dla security

1. **Nowe konto usługi / uprawnienia** do Google Play Developer API (najmniejsze uprawnienia, bez kluczy w repozytorium).
2. **Model zagrożeń**: podrobione i powtórzone zakupy, manipulacja saldem, wyścigi przy pobieraniu, nadużycia zwrotów, farmy kont, przejęte konto.
3. **Reguły Firestore**: odczyt tylko własnego salda i historii, brak zapisu z klienta.
4. **Logowanie**: bez tokenów zakupu i identyfikatorów zamówień w pełnej postaci w logach (lista dozwolonych pól jak w ADR-0002).
5. **Rejestr danych osobowych** – nowe pozycje do oceny (**tylko wskazanie; rejestru nie zmieniam**, `docs/security/personal-data-register.md`):
   - **Zakupy**: UID, identyfikator zamówienia Google Play, token zakupu, produkt (paczka), czas, status (oczekujący/zakupiony/zwrócony), ewentualnie cena i waluta – cel: realizacja umowy, rozliczenia, obsługa zwrotów; podstawa i retencja do ustalenia (P-L4, P-L7); odbiorca: Google Play (już w D13 jako dystrybucja – rozszerzenie o płatności).
   - **Księga i saldo słoneczek**: UID, operacje z datami, pule i daty ważności – historia użycia usługi, dłuższa niż obecny licznik D10.
   - **Ślad przydziału darmowego progu** po usunięciu konta (jeśli prawnik dopuści, P-L4) – np. skrót identyfikatora.
   - Wpływ na istniejące pozycje: **D10** (licznik użycia – limity dzienne zależne od statusu zakupu), **D11** (logi – nowe kody wyników), **D13** (Google Play – rola w płatnościach), **D14** (wsparcie – reklamacje i zwroty), polityka prywatności i US-010 (usuwanie konta).
   - Dane płatnicze (karta, adres rozliczeniowy) **przetwarza wyłącznie Google Play**; Tamitu ich nie otrzymuje – do potwierdzenia.

### 5.3 Dla UX (później)

Ekrany: saldo i historia, zakup paczki, koszt planu w formularzu, brak słoneczek, płatność w toku, ostrzeżenie o wygasaniu, ostrzeżenie o saldzie przy usuwaniu konta. Nazwa „słoneczka" w EN do ustalenia (np. „suns") – PL/EN wg ADR-0006.

## 6. Otwarte pytania do właściciela (po MVP)

Wpisane do `docs/open-questions.md`, sekcja „Kredyty „słoneczka" (AN-CREDITS)": OC1–OC10. Skrót: przelicznik (OC1), paczki i ceny (OC2), darmowy próg (OC3), ważność (OC4), relacja do reklam i subskrypcji z wizji (OC5), limity dzienne dla płacących (OC6), anulowanie a pobranie (OC7), saldo przy usunięciu konta (OC8), plan premium (OC9), reklamacje jakości (OC10).

## 7. Następne kroki (po MVP, po decyzjach właściciela)

1. Decyzje właściciela OC1–OC10.
2. Konsultacja prawna P-L1–P-L7 razem z SEC-30.
3. Architekt: ADR „Kredyty i Google Play Billing" (sekcja 5.1); security: model zagrożeń i rejestr (sekcja 5.2).
4. Analityk: rozbicie US-K01–K07 na pliki `US-NNN`, aktualizacja `scope.md`; właściciel: aktualizacja modelu biznesowego w `vision.md`.
5. Data-analyst: metryki kosztu na słoneczko i ekonomii paczek.
