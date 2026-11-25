# ADR-0016: Odporność generowania na przeciążenie Vertex (HTTP 429)

- Status: **zatwierdzony** (właściciel, 2026-11-21, O-TAM96-1: „TAK, z rozszerzeniem”; warunek spełniony
  2026-11-24, TAM-97). Billing pokazał dokładnie tyle tokenów, ile dały 38 odpowiedzi z TAM-88, więc wywołania
  z 429 nie są rozliczane (sekcja „Warunek: 429 nic nie kosztuje”, punkt (c)). Do 2026-11-24: zatwierdzony warunkowo.
- Data: 2026-11-21
- Autor (rola): architect
- Zadanie: TAM-96 (P3-05-429), na podstawie raportu `docs/qa/QA-TAM-88-eval.md` (sekcje 2 i 2.1)
- Uzupełnia (nie zastępuje): ADR-0002, wiersz „Próby” w tabeli decyzji („maks. 2 wywołania modelu na 1 generowanie”).
  Pozostała treść ADR-0002 obowiązuje bez zmian. ADR-0001 (model, punkt `eu`) bez zmian.

## W skrócie

Gdy Vertex odpowiada „przeciążony” (HTTP 429), serwer czeka dłużej (2–4 s, potem 4–8 s, z losowym rozrzutem).
Może też spróbować **trzeci raz**, ale tylko wtedy, gdy wcześniej przyszedł 429. **Płatnych prób jest nadal najwyżej 2.**
Gdy **wszystkie** wywołania skończą się 429, serwer zwraca nowy kod **`ai_busy`**, a próba **nie zużywa limitu dziennego**.
Aplikacja pokazuje wtedy komunikat z odliczaniem 60 s, **raz** ponawia sama i daje przycisk „Spróbuj teraz”.
Całe generowanie na serwerze mieści się w 100 s (limit funkcji to 120 s), a czekanie minutowe odbywa się w aplikacji.
Dodatkowy koszt: **0 PLN**, pod warunkiem że 429 nie jest rozliczane. Właściciel sprawdzi to w Billing.
Płatnych opcji Vertex (Priority PayGo, przydział przepustowości) nie włączamy.

## Kontekst

- Ewaluacja TAM-88 (2026-11-21): 38/40 = 95,0%, czyli dokładnie próg ADR-0001 pkt 2. Model nie zwrócił ani jednej
  złej odpowiedzi. Obie porażki to HTTP 429 w obu próbach (E07-en, E08-pl). Razem było 6 wywołań z 429 w 4 generowaniach,
  wszystkie w ok. 4-minutowym oknie na początku przebiegu. W tym samym oknie poprawne odpowiedzi przychodziły wolniej
  (20–41 s zamiast 2–14 s).
- Dla Gemini na Vertex w trybie pay-as-you-go nie ma stałego przydziału na projekt. Model działa we współdzielonej
  puli (dynamic shared quota). Kod 429 oznacza **chwilowy tłok w puli**, a nie wyczerpany limit projektu. Google zaleca
  ponawianie z narastającym odczekaniem (exponential backoff). Podniesienie limitu w konsoli Quotas tu nie pomoże.
- Stan kodu (`backend/functions/src/generate.ts`, `ai.ts`): najwyżej 2 wywołania. Po 408/429/5xx/przekroczeniu czasu/błędzie
  sieci jest jedno ponowienie po 1–2 s. Limit próby to 45 s (`ATTEMPT_TIMEOUT_MS`), a limit funkcji i timeout klienta to 120 s.
- Ograniczenia:
  - **koszt:** właściciel nie chce niespodziewanych kosztów chmury (zasada 10 CLAUDE.md);
  - **dane:** zostajemy w UE (ADR-0001 Aneks B: punkt `eu`, nigdy `global`);
  - **limity:** limit dzienny i zwrot slotu działają według `posrednik-api.md` pkt 2 (O-TAM18-3);
  - **UX:** EK-07 pokazuje nieokreślony postęp, a tekst zmienia się co 10 s. Czekanie do 120 s jest przewidziane.

## Rozważane opcje

| # | Opcja | Plusy | Minusy | Koszt |
|---|---|---|---|---|
| 1 | **Bez zmian** (2 wywołania, 1–2 s) | zero pracy | w oknie przeciążenia 2 szybkie 429 pod rząd kończą generowanie (TAM-88: 2 z 40); zapas ponad próg zerowy | 0 |
| 2 | **Dłuższe odczekanie z narastaniem, nadal 2 wywołania** | proste | tylko 1 dodatkowa szansa | 0 |
| 3 | **Opcja 2 + trzecie wywołanie tylko po 429, najwyżej 2 próby płatne, budżet czasu** | 2 dodatkowe szanse w krótkim tłoku; pułap kosztu bez zmian | sekundy nie wystarczą na przeciążenie trwające minuty | 0* |
| 3+ | **Opcja 3 + kod `ai_busy` bez zużycia limitu + jedno automatyczne ponowienie w aplikacji po 60 s** (wybrana, decyzja właściciela) | krótki tłok obsługuje serwer, a dłuższy (minuta) aplikacja; użytkownik nie traci próby; jasny komunikat | nowy kod błędu, zmiana w aplikacji i UX, licznik nadużyć | 0* |
| 4 | **Ponowienia w aplikacji bez ograniczeń** | dłuższe okno | każde wywołanie zużywa slot; ryzyko pętli i nadużyć | slot i limit globalny |
| 5 | **Model zapasowy po 429** (np. `gemini-3.5-flash-lite`) | może inna pula | drugi model do utrzymania i ewaluacji (ADR-0001 pkt 2), inna stawka; nie wiadomo, czy pula jest osobna | płatna ewaluacja + inna stawka |
| 6 | **Priority PayGo** | mniej 429 bez stałej opłaty | wyższa stawka za każdy token; dostępność dla `gemini-3.1-flash-lite` w `eu` niepotwierdzona | dopłata do każdego tokena (sekcja „Alternatywy Vertex”) |
| 7 | **Provisioned Throughput** | odporność na tłok w puli | stała opłata, min. 1 tydzień, bez anulowania | rząd tysięcy PLN tygodniowo |
| 8 | **Punkt `global`** | zwykle mniej 429 | dane mogą wyjść poza UE: wykluczone (ADR-0001 Aneks B, RODO) | 0, ale niedopuszczalne |
| 9 | **Inny punkt regionalny w UE** | inna pula | `europe-west4` nie obsługuje modelu (417); inne nietestowane | płatny test |

\* pod warunkiem z sekcji „Warunek: 429 nic nie kosztuje”.

## Decyzja

Opcja 3+. Zasady (normatywne, implementacja: mobile-dev):

### A. Serwer: ponowienia (`backend/functions/src/generate.ts`, `ai.ts`)

1. **Rodzaje wywołań.** Wywołanie zakończone **HTTP 429** to „wywołanie odrzucone”. Każde inne wywołanie jest
   „próbą płatną”, także wtedy, gdy model mógł policzyć tokeny, a my nie dostaliśmy wyniku: odpowiedź 200 (poprawna
   lub niepoprawna), przekroczenie czasu, błąd sieci, 408, 5xx, `bad_body`. Liczymy ostrożnie, bo nie zawsze wiadomo,
   czy Vertex naliczył tokeny.
2. **Limity na jedno generowanie:** najwyżej **3 wywołania modelu** i najwyżej **2 próby płatne**. Trzecie wywołanie
   jest więc możliwe tylko wtedy, gdy co najmniej jedno z dwóch pierwszych skończyło się 429. Przykłady:
   `429 → 429 → próba`, `429 → zła odpowiedź → próba z listą błędów`, `zła odpowiedź → 429 → próba z listą błędów`,
   `timeout → 429 → próba`. Bez trzeciego wywołania: `timeout → timeout`, `zła odpowiedź → zła odpowiedź`, `5xx → 5xx`.
3. **Odczekanie przed ponowieniem** po każdym błędzie ponawianym (408, 429, 5xx, timeout, sieć, `bad_body`):
   - przed wywołaniem 2: losowo **2–4 s**;
   - przed wywołaniem 3: losowo **4–8 s**;
   - rozkład jednostajny (podstawa × [1, 2], podstawa 2 s i 4 s). Łącznie najwyżej 12 s czekania.
   Po złej odpowiedzi (walidacja, `MAX_TOKENS`, `OTHER`) **bez** odczekania, jak dziś. Nie czytamy nagłówka `Retry-After`
   ani treści błędu (zostaje zasada z `p3-05-wymagania-generowania.md` sekcja 3 pkt 3).
4. **Budżet czasu generowania: 100 s**, liczony od startu pierwszego wywołania. Kolejne wywołanie (po odczekaniu) rusza
   tylko wtedy, gdy do końca budżetu zostało **co najmniej 45 s** (pełny limit próby). Jeśli nie, generowanie kończy się
   od razu kodem wynikającym z ostatniego błędu, a log dostaje `stopReason=time_budget`. Limit jednej próby zostaje 45 s.
   Rachunek dla najgorszego przypadku: 45 s (timeout) + 4 s + ok. 1 s (429) + 8 s daje 58 s. Zostaje 42 s, czyli mniej niż
   45 s, więc trzeciego wywołania nie ma. Dzisiejsza ścieżka 45 + 4 + 45 = 94 s mieści się w 100 s. Do limitu funkcji
   i klienta (120 s) zostaje ≥ 15 s na zgody, rezerwację i zwrot slotu, zimny start i sieć.
5. **Lista błędów walidacji przechodzi przez 429.** Jeśli płatna próba dała złą odpowiedź, a następne wywołanie
   dostało 429, kolejna próba nadal dostaje listę błędów (dziś lista jest kasowana po każdym błędzie ponawianym).
   Treść listy i reguły walidatora się nie zmieniają.

### B. Serwer: wynik i nowy kod `ai_busy`

6. **`ai_busy`** zwracamy **tylko wtedy, gdy wszystkie wywołania w tym generowaniu skończyły się 429** (0 prób płatnych).
   W praktyce to 3 × 429 w ok. 10–15 s. Kod HttpsError `unavailable`, `details.code = "ai_busy"`,
   `details.retryAfterSec = 60`, `details.slotReleased` (bool).
7. Każdy inny koniec bez planu działa jak dotąd, według ostatniego błędu: błąd ponawiany daje `ai_unavailable`,
   a zła odpowiedź daje `ai_invalid_response`. Dotyczy to także przypadków mieszanych, np. `timeout → 429 → 429`
   albo `zła odpowiedź → 429 → 429`. Była w nich próba płatna, więc nie są `ai_busy` i działają według zwykłych zasad
   zwrotu (najwyżej 2 na dobę). `retryAfterSec` przy `ai_unavailable` nie wysyłamy.
8. **Slot przy `ai_busy`** (zmiana w `limits.ts`; `posrednik-api.md` pkt 2):
   - slot konta (`usage/{uid}.count`) **wraca zawsze** i **nie liczy się** do limitu 2 zwrotów na dobę (`released`);
   - slot globalny (`usage_global`) **też wraca**. Licznik globalny chroni przed kosztem, a w `ai_busy` żadna próba
     nie była płatna. Bez tego każde przeciążenie, razem z automatycznym ponowieniem, zjadałoby 2 sloty z 25 dziennych
     dla całej aplikacji. Zwrot jest wyjątkiem od reguły 4 z `posrednik-api.md` pkt 2, uzasadnionym tym samym
     kryterium kosztu (O-TAM18-1);
   - **bezpiecznik nadużyć:** najwyżej **10 zwrotów `ai_busy` na konto na dobę** (`usage/{uid}.busyReleased`,
     zerowane z nową dobą). Od 11. `ai_busy` w dobie slot konta i globalny zostają zużyte, a odpowiedź ma
     `slotReleased=false`. Uczciwy użytkownik nie dojdzie do tego progu, bo ma 1 ponowienie automatyczne
     i ręczne przyciski;
   - log `quotaRelease`: nowe kody `busy_released` i `busy_capped`.
9. **Dlaczego to jest bezpieczne przed nadużyciem:**
   - `ai_busy` jest wyłącznie przy **0 próbach płatnych**. Nie da się nim „wyprosić” planu ani tokenów za darmo,
     bo każda odpowiedź modelu (także zła) jest próbą płatną i wyklucza `ai_busy`;
   - rezerwacja slotu jest nadal **przed** wywołaniem modelu (ADR-0002 krok 5). Konto z wyczerpanym limitem dostaje
     `limit_exceeded` przed jakimkolwiek wywołaniem, a zwrot `ai_busy` nie podnosi limitu ponad `perUserDailyLimit`;
   - bezpiecznik 10 na konto na dobę, `maxInstances` 10, token ID i App Check ograniczają spam w czasie przeciążenia
     (koszt takiego spamu to tylko czas funkcji, bez tokenów);
   - przyczynę `ai_busy` ustala serwer na podstawie statusu HTTP z Vertex. Klient nie ma na nią wpływu.

### C. Aplikacja (EK-07 i ekran błędu generowania, `lib/`)

10. Przy `ai_busy` aplikacja pokazuje komunikat (szczegóły i teksty PL/EN: zadanie UX), np. **„Nasz asystent AI jest
    chwilowo przeciążony. Spróbujemy ponownie za minutę.”**, z **odliczaniem** od `retryAfterSec` (przyjąć 30–120 s,
    brak lub wartość spoza zakresu = 60 s), przyciskiem **„Spróbuj teraz”** i możliwością rezygnacji (powrót do formularza).
11. **Jedno automatyczne ponowienie:** po zakończeniu odliczania aplikacja raz sama wywołuje `generatePlan` z tymi
    samymi danymi formularza i **nowym** `requestId`. „Spróbuj teraz” w trakcie odliczania zastępuje to automatyczne
    ponowienie, a nie dodaje drugiego. Automat działa tylko wtedy, gdy ekran jest na pierwszym planie. Jeśli aplikacja
    jest w tle po zakończeniu odliczania, po powrocie użytkownik widzi sam przycisk (UX może to doprecyzować).
12. Jeśli i to ponowienie skończy się `ai_busy` (albo innym błędem), zostaje **sam przycisk** „Spróbuj teraz”,
    **bez kolejnych automatów** i bez odliczania. Licznik „1 automat” dotyczy jednego wysłania formularza.
13. Czekanie minutowe odbywa się **w aplikacji**, nie na serwerze, bo funkcja ma limit 120 s, a czas funkcji kosztuje.
    To wyjątek od zasady „brak automatycznych ponowień `generatePlan`” (`posrednik-api.md` pkt 6), tylko dla `ai_busy`.
    Jest bezpieczny, bo `ai_busy` nie zużywa limitu (pkt 8).
14. Tekst przy `ai_busy` może mówić „próba nie wlicza się do limitu”, gdy `slotReleased = true`. Zasada z
    `posrednik-api.md` pkt 6 zostaje: bez `slotReleased = true` aplikacja nie obiecuje zwrotu.

### D. Logi

15. Bez danych osobowych: wpis `generatePlan.attempt` dostaje `waitMs` (odczekanie przed tym wywołaniem)
    i `billable` (bool według pkt 1). Wpis końcowy dostaje `calls` (1–3) i `stopReason`
    (`ok`, `invalid`, `config`, `busy`, `max_billable`, `max_calls`, `time_budget`) oraz kody `quotaRelease` z pkt 8.
    Aplikacja nie wysyła nowych zdarzeń analitycznych.

### Dlaczego serwer czeka tylko sekundy

Okno przeciążenia w TAM-88 trwało ok. 4 minut. Funkcja ma 120 s i płacimy za jej czas, więc minut na serwerze nie
przeczekamy. Serwer łapie **krótkie** szczyty (sekundy), a aplikacja jedno **dłuższe** (60 s, bez kosztu).
Przy przeciążeniu dłuższym niż ok. 1,5 minuty użytkownik dostaje przycisk i nie traci próby.

### Oczekiwany efekt (szacunek, nie pomiar)

W oknie przeciążenia TAM-88 ok. 6 z ok. 18 wywołań dostało 429 (ok. 1/3). Jeśli wywołania są w przybliżeniu niezależne,
dziś porażka to 2 × 429, czyli ok. 1/9 generowań w oknie. Po zmianie na serwerze porażka to 3 × 429, czyli ok. 1/27,
a ponowienie w aplikacji po 60 s zmniejsza to dalej. To przybliżenie, bo 429 w tym samym oknie nie są niezależne.
Zweryfikuje je pomiar w dev, bez specjalnego płatnego testu.

## Warunek: 429 nic nie kosztuje

### (a) Co mówi dokumentacja Google (stan 2026-11-21)

- Vertex AI rozlicza modele Gemini **za przetworzone tokeny** wejścia i wyjścia (cennik Vertex AI, `costs.md` sekcja 1.1).
  Odpowiedź 429 przychodzi bez kandydata i bez `usageMetadata`, więc nie ma w niej tokenów do rozliczenia.
- Dokumentacja błędu 429 dla Vertex (Error code 429, API errors) opisuje 429 jako odrzucenie żądania z braku przepustowości
  („Resource exhausted, please try again later”) i zaleca ponawianie z backoffem. **O rozliczaniu nic nie mówi.**
- Najbliższe wprost wyrażone źródło to FAQ rozliczeń **Gemini API** (Google AI, `ai.google.dev/gemini-api/docs/billing`,
  „Am I charged for failed requests?”). Mówi ono, że żądania zakończone błędem 400 lub 500 nie są rozliczane, choć liczą
  się do limitu. To inna usługa niż Vertex i nie wymienia 429 wprost.
- **Wniosek:** Google nie pisze wprost, że Vertex nie rozlicza 429. Źródła są pośrednie, więc rozstrzyga sprawdzenie
  w Billing, czyli warunek właściciela.

### (b) Sprawdzenie w Billing na danych z TAM-88 (wykonuje właściciel, bez kosztu)

**Dane z raportu QA** (`docs/qa/QA-TAM-88-eval.md` sekcja 2), model `gemini-3.1-flash-lite`, punkt `eu`, projekt
`tamitu-dev-tadecode`, przebieg 2026-11-21 ok. 13:38–13:47 CET:
- 44 wywołania: **38 z odpowiedzią** (tokeny znane) i **6 z 429** (tokeny nieznane, Vertex ich nie zwrócił);
- tokeny wejścia z 38 odpowiedzi: **38 534**; tokeny wyjścia: **55 131**; myślenie: **0**.

**Czego się spodziewać:**

| Hipoteza | Wejście (SKU „input”) | Wyjście (SKU „output”) |
|---|---|---|
| **429 nie jest rozliczane** (warunek spełniony) | ok. **38 534** | ok. **55 131** |
| 429 rozliczane za wejście | ok. **44 600** (38 534 + 6 × ok. 1 014, średnia z raportu; zakres ok. 43 500–46 000) | ok. 55 131 (429 nie ma wyjścia) |

Różnica dotyczy **tylko liczby tokenów wejścia** (ok. 6 000, czyli ok. 16%). W kwocie to ok. 0,007 PLN, czyli poniżej
dokładności raportu. **Dlatego porównujemy ilość (usage) w SKU, a nie koszt.**

**Kroki w konsoli:**
1. Odczekać co najmniej 24 h od przebiegu (dane rozliczeń spływają z opóźnieniem).
2. Billing → konto rozliczeniowe → **Reports**: zakres dat **21.11.2026–21.11.2026**, filtr **Projects** =
   `tamitu-dev-tadecode`, **Services** = Vertex AI, **Group by = SKU**. Zanotować SKU modelu
   `gemini-3.1-flash-lite` (Gemini 3.1 Flash Lite, wejście tekstowe i wyjście tekstowe; stawka „Non-global”/regionalna).
3. Żeby zobaczyć **ilość** (nie tylko koszt), filtrować do **jednego SKU** naraz (Reports pokazuje wtedy usage z jednostką)
   albo otworzyć **Cost table** dla tego samego zakresu, projektu i usługi i odczytać kolumny **Usage** i **Usage unit**
   dla tych SKU. Jednostkę (np. tokeny, 1 000 tokenów albo milion tokenów) przeliczyć na tokeny.
4. **Strefa czasowa:** raporty rozliczeń liczą doby w czasie pacyficznym (PT). Przebieg TAM-88 (04:38–04:47 PT) wypada
   21.11. Test ARCH-01 (2026-11-21 ok. 01:40 CET, czyli 20.11 ok. 16:40 PT) powinien wypaść **20.11**. Jeśli raport pokazuje
   inną strefę i 21.11 zawiera też ARCH-01, od wyniku odjąć ARCH-01 dla `gemini-3.1-flash-lite`: 5 wywołań, ok. **3 620**
   tokenów wejścia i ok. **9 090** wyjścia (`arch-01-gemini-test.md` sekcja 6), plus kilka sond o małym rozmiarze.
5. **Kontrola czystości danych:** najpierw porównać **wyjście**. Jeśli wyjście ≈ 55 131 (±2%), w tej dobie nie było innych
   wywołań tego modelu i porównanie wejścia jest wiarygodne. Jeśli wyjście jest wyraźnie większe, były inne wywołania
   (np. ręczne w dev). Wtedy wynik jest niejednoznaczny: zanotować liczby i przekazać architektowi.
6. **Ocena wejścia:**
   - **≤ 40 000** tokenów: 429 **nie jest rozliczane**, warunek spełniony, ADR-0016 zatwierdzony w pełni;
   - **≥ 43 000** tokenów: 429 **jest rozliczane**. Architekt przelicza koszt (szacunkowo ok. 0,1 grosza za każde 429,
     tylko za wejście) i właściciel decyduje, czy zostawić 3. wywołanie i zwrot slotów przy `ai_busy`;
   - pomiędzy: niejednoznaczne. Pomocniczo: Monitoring → Metrics Explorer, metryki Vertex AI dla modeli wydawcy
     (liczba wywołań według kodu odpowiedzi i liczba tokenów) w oknie 13:38–13:47 CET 21.11. Oczekiwane: 6 wywołań z 429
     i tokeny tylko dla 38 wywołań. To nie jest dowód rozliczenia, tylko spójności liczb. W razie wątpliwości:
     pytanie do wsparcia Google Cloud.
7. Wynik (dwie liczby: wejście i wyjście z Billing, oraz jednostka) właściciel wpisuje w odpowiedzi do O-TAM96-1.

### (c) Wynik sprawdzenia (2026-11-24, TAM-97)

| | Billing (SKU `gemini-3.1-flash-lite`, 21.11.2026, `tamitu-dev-tadecode`) | Suma z 38 odpowiedzi (QA TAM-88) |
|---|---|---|
| Tokeny wejścia | **38 534** | 38 534 |
| Tokeny wyjścia | **55 131** | 55 131 |

- Kontrola czystości (krok 5): wyjście zgadza się co do tokena, więc w tej dobie nie było innych wywołań modelu
  i porównanie wejścia jest wiarygodne.
- Ocena (krok 6): wejście 38 534 ≤ 40 000 i równe sumie z samych odpowiedzi. Gdyby 429 było rozliczane, wejście
  wyniosłoby ok. 44 600. **6 wywołań z 429 nie zostało rozliczonych – warunek spełniony.**
- Skutek: pułapy kosztów z `costs.md` bez zmian; merge implementacji (sekcja „Kolejność”) odblokowany.

### Kolejność

- Dokumenty (ten ADR, kontrakt v0.7) i specyfikację UX można przygotować od razu.
- Implementację (mobile-dev) można zacząć od razu, ale **merge do `main` dopiero po potwierdzeniu warunku (b)**.
  Jeśli 429 okaże się rozliczane, przed merge'em wraca to do decyzji właściciela.

## Koszt

- **Tokeny:** jeśli warunek (b) się potwierdzi, wywołanie z 429 nie kosztuje nic. Płatnych prób jest nadal najwyżej 2,
  więc **pułapy z `costs.md` (sekcje 0 i 4) się nie zmieniają**.
- **Cloud Functions:** do 12 s czekania i ok. 1 s na każde 429, tylko w generowaniach z 429. Przy 512 MiB to ułamek grosza.
  Ponowienie w aplikacji to nowe wywołanie funkcji, ale bez tokenów przy kolejnym 429. W skali testów mieści się w darmowym limicie.
- **Limity dzienne:** `ai_busy` nie zużywa slotu konta ani globalnego (do 10 razy na konto na dobę). Pozostałe błędy działają bez zmian.
- **Razem: ok. 0 PLN/mies.**

## Alternatywy Vertex (nie włączamy, nic nie zamawiamy)

Ceny orientacyjne z 2026-11-21 (dokumentacja Google o 429 i opcjach zużycia oraz cenniki zewnętrzne). Przed jakąkolwiek
decyzją trzeba je sprawdzić w oficjalnym cenniku Vertex AI i w Cloud Billing.

| Opcja | Jak działa | Koszt dla Tamitu | Ocena |
|---|---|---|---|
| **Priority PayGo** | nagłówek w żądaniu oznacza ruch jako priorytetowy; mniej odrzuceń w tłoku | wyższa stawka za **każdy** token (wysokość dopłaty i dostępność dla `gemini-3.1-flash-lite` w `eu` do potwierdzenia). Przykład: przy dopłacie 50–100% normalne użycie rośnie z ok. 12 do 18–24 PLN/mies., a pułap nadużycia z ok. 82 do 123–164 PLN/mies., czyli powyżej spend cap prod 80 PLN | odłożone; O-TAM96-2 |
| **Provisioned Throughput** | stały, zarezerwowany przydział (GSU) dla modelu i lokalizacji; nadwyżka dostaje 429 albo jest liczona po stawce PayGo | najkrótszy okres to 1 tydzień, bez anulowania. Według cenników zewnętrznych ok. 7 USD za GSU-godzinę (`global`, okres 1 tydzień), czyli ok. 1 200 USD ≈ **4 800 PLN tygodniowo** za 1 GSU (ok. 20 000 PLN/mies.). Stawka dla punktu regionalnego/`eu` może być inna | odrzucone: setki razy więcej niż cały budżet AI (12 PLN/mies.) |
| **Punkt `global`** | routing do dowolnego regionu Google | bez dopłaty | wykluczone (dane poza UE; ADR-0001 Aneks B) |
| **Inny punkt w UE** (regionalny) | inna pula | płatny test dostępności i jakości, nowy ADR | odłożone; `europe-west4` nie obsługuje modelu (417) |
| **Wyższy poziom użycia (usage tier) Standard PayGo** | Google przydziela wyższy próg tokenów/min wg wydatków z ostatnich 30 dni | nie da się „kupić” bez większych wydatków | nie dotyczy przy naszej skali |
| **Podniesienie limitu w Quotas** | – | 0 | nie dotyczy: dla tych modeli nie ma stałego limitu projektu, a 429 wynika z tłoku w puli |

## Pomiar i próg ponownej oceny

W dev (po TAM-90) i później w prod liczyć z logów (bez danych osobowych):
- odsetek generowań zakończonych `ai_busy` (`stopReason=busy`) oraz `ai_unavailable` z ostatnim błędem 429,
- odsetek generowań z co najmniej jednym 429 i odsetek wywołań nr 3,
- liczba `busy_capped` (czy bezpiecznik kiedykolwiek działa),
- czas generowania (mediana, p95) w generowaniach z 429.

Propozycja progu (O-TAM96-2, otwarte): jeśli w ciągu 7 dni **więcej niż 5%** generowań (przy co najmniej 40 generowaniach)
kończy się `ai_busy` albo `ai_unavailable` przez 429, architekt przygotuje wycenę Priority PayGo do decyzji właściciela.

## Konsekwencje

- **Pozytywne:** odporność na krótkie szczyty tłoku (serwer) i na minutowe przeciążenie (aplikacja). Użytkownik
  nie traci próby przez przeciążenie. Pułapy kosztów bez zmian, jeśli warunek (b) się potwierdzi.
- **Negatywne:** nowy kod błędu, zmiany w aplikacji i UX, nowe pole `usage/{uid}.busyReleased`, wyjątki od reguły
  „brak automatycznych ponowień” i od reguły „`usage_global` nie maleje”. W najgorszym przypadku po stronie serwera
  użytkownik czeka ok. 100 s (dziś ok. 92 s). Przy `ai_busy` dochodzi do 60 s odliczania z jasnym komunikatem.
- **Zgodność wstecz:** `apiVersion` zostaje 1. Starsza aplikacja nie zna `ai_busy` i pokaże ogólny komunikat błędu
  (`posrednik-api.md` pkt 6: nieznany kod → `internal`), bez obietnicy zwrotu. To bezpieczne i akceptowalne, bo nie ma
  wydanej publicznie wersji aplikacji, a serwer i aplikacja wchodzą razem.
- **Ryzyka:** przeciążenie dłuższe niż ok. 1,5 minuty nadal kończy się przyciskiem. Część wyceny alternatyw opiera się
  na źródłach zewnętrznych (do weryfikacji). Jeśli 429 jest jednak rozliczane, decyzja wraca do właściciela (warunek (b)).
- **Dane osobowe:** brak nowych rodzajów danych. `busyReleased` to licznik w istniejącym dokumencie `usage/{uid}`
  (rejestr D10). Security dopisuje pole do opisu D10, jeśli rejestr wymienia pola. Nowe pola logów to liczby i stałe kody.
- **Ewaluacja (ADR-0001 pkt 2):** kolejne przebiegi użyją logiki serwera (A–B), bo uruchamiacz używa tej samej ścieżki
  co `generatePlan`. Ponowienie z aplikacji (C) nie dotyczy uruchamiacza. Płatnej powtórki TAM-88 nie planujemy.

## Historia

- 2026-11-21: propozycja (ponowienia po 429, budżet 100 s, `retryAfterSec` przy `ai_unavailable`).
- 2026-11-21: decyzja właściciela O-TAM96-1 „TAK, z rozszerzeniem”: warunek braku kosztu 429 (sekcja „Warunek”),
  nowy kod `ai_busy` bez zużycia limitu i z zabezpieczeniem przed nadużyciem, jedno automatyczne ponowienie w aplikacji
  po 60 s. `retryAfterSec` przeniesione z `ai_unavailable` do `ai_busy`. Zatwierdzenie warunkowe.
- 2026-11-24 (TAM-97): Billing – 38 534 tokeny wejścia i 55 131 wyjścia, dokładnie tyle co z 38 odpowiedzi; 429 nie jest
  rozliczane. Warunek spełniony.
- 2026-11-25 (TAM-103, architect): status zmieniony na **zatwierdzony**, dopisany punkt (c). Treść decyzji bez zmian.
