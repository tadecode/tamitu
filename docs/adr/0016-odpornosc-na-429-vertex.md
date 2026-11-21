# ADR-0016: Odporność generowania na przeciążenie Vertex (HTTP 429)

- Status: proponowany (czeka na właściciela, pytanie O-TAM96-1)
- Data: 2026-11-21
- Autor (rola): architect
- Zadanie: TAM-96 (P3-05-429), na podstawie raportu `docs/qa/QA-TAM-88-eval.md` (sekcje 2 i 2.1)
- Uzupełnia (nie zastępuje): ADR-0002, wiersz „Próby” w tabeli decyzji („maks. 2 wywołania modelu na 1 generowanie”).
  Pozostała treść ADR-0002 obowiązuje bez zmian. ADR-0001 (model, punkt `eu`) bez zmian.

## W skrócie

Gdy Vertex odpowiada „przeciążony” (HTTP 429), serwer czeka dłużej (2–4 s, potem 4–8 s, z losowym rozrzutem).
Może też spróbować **trzeci raz**, ale tylko wtedy, gdy wcześniej przyszedł 429. Odrzucone wywołanie z 429 nie
zużywa tokenów, więc **płatnych prób jest nadal najwyżej 2**, a pułapy kosztów się nie zmieniają. Całe generowanie
ma budżet czasu 100 s, więc zmieści się w limicie funkcji (120 s). Dodatkowy koszt to **0 PLN**. Płatnych opcji Vertex
(Priority PayGo, przydział przepustowości) teraz nie włączamy.

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
| 2 | **Dłuższe odczekanie z narastaniem, nadal 2 wywołania** | proste; większa szansa, że tłok minie | tylko 1 dodatkowa szansa; po timeoucie i 429 nie ma już kolejnej | 0 |
| 3 | **Opcja 2 + trzecie wywołanie tylko po 429, nadal najwyżej 2 płatne próby, budżet czasu** (wybrana) | 2 dodatkowe szanse w tłoku; 429 nie zużywa tokenów, więc pułap kosztu bez zmian; mieści się w 120 s | trochę więcej logiki (licznik prób płatnych, budżet czasu); użytkownik w najgorszym razie czeka ok. 100 s zamiast ok. 92 s | 0 (sekcja „Koszt”) |
| 4 | **Ponowienie w aplikacji** (automatyczne drugie `generatePlan`) | dłuższe okno, minuty zamiast sekund | narusza kontrakt (`posrednik-api.md` pkt 6: brak automatycznych ponowień); każde wywołanie zużywa slot i limit globalny | slot i limit globalny |
| 5 | **Model zapasowy po 429** (np. `gemini-3.5-flash-lite`, może z innej puli) | inna pula przepustowości | drugi model do utrzymania i ewaluacji (ADR-0001 pkt 2), inny koszt tokenów, inne zachowanie promptu; nie wiadomo, czy pula jest osobna | płatna ewaluacja + inna stawka |
| 6 | **Priority PayGo** (żądania oznaczone jako priorytetowe) | mniej 429 bez stałej opłaty | wyższa stawka za każdy token, także bez przeciążenia; dostępność dla `gemini-3.1-flash-lite` w punkcie `eu` niepotwierdzona; podnosi pułap nadużycia | dopłata do każdego tokena (sekcja „Alternatywy Vertex”) |
| 7 | **Provisioned Throughput** (przydział przepustowości, GSU) | odporność na tłok w puli | stała opłata za okres (min. 1 tydzień), bez anulowania | rząd tysięcy PLN tygodniowo (sekcja „Alternatywy Vertex”) |
| 8 | **Punkt `global`** | zwykle mniej 429 | dane mogą być przetwarzane poza UE: wykluczone przez ADR-0001 Aneks B i RODO | 0, ale niedopuszczalne |
| 9 | **Inny punkt regionalny w UE** | inna pula | `europe-west4` nie obsługuje modelu (błąd 417, ARCH-01); inne regiony nietestowane, wymagają płatnego testu i nowego ADR | płatny test |

## Decyzja

Opcja 3. Zasady (normatywne, implementacja: mobile-dev, `backend/functions/src/generate.ts` i `ai.ts`):

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
6. **Wynik końcowy** (bez zmian w kodach): ostatni błąd decyduje. Błąd ponawiany daje `ai_unavailable`, a zła odpowiedź
   daje `ai_invalid_response`. Gdy generowanie kończy się z powodu 429 (ostatnie wywołanie dało 429), serwer dodaje
   `details.retryAfterSec = 60`. To pole jest już opcjonalne w kontrakcie, więc zmiana jest zgodna wstecz, a aplikacja
   może je dziś ignorować.
7. **Limity i sloty bez zmian.** Jedno generowanie to jeden slot konta i jeden slot globalny, niezależnie od liczby
   wywołań. Zwrot slotu po `ai_unavailable` działa jak dotąd (najwyżej 2 zwroty na konto na dobę, `usage_global` nie maleje).
   Mniej porażek przez 429 oznacza rzadsze zwroty.
8. **Aplikacja bez zmian.** Brak automatycznych ponowień `generatePlan` (`posrednik-api.md` pkt 6). Timeout klienta zostaje 120 s.
9. **Logi** (bez danych osobowych): wpis `generatePlan.attempt` dostaje `waitMs` (odczekanie przed tym wywołaniem)
   i `billable` (bool według pkt 1). Wpis końcowy dostaje `calls` (1–3) i `stopReason`
   (`ok`, `invalid`, `config`, `max_billable`, `max_calls`, `time_budget`). Z tego liczymy wskaźniki z sekcji „Pomiar”.

### Dlaczego nie dłużej niż kilka sekund

Okno przeciążenia w TAM-88 trwało ok. 4 minut. Tylu minut nie przeczekamy w jednym wywołaniu funkcji. Czekanie do 120 s
bez wyniku jest gorsze dla użytkownika niż jasny komunikat. Dlatego odczekanie łapie **krótkie** szczyty tłoku (sekundy).
Przy długim przeciążeniu użytkownik dostaje `ai_unavailable` z wskazówką „spróbuj za chwilę” i zwrotem próby.
Dłuższe przeczekiwanie dawałoby więcej tylko z opcjami 4–7, a te odrzucamy.

### Oczekiwany efekt (szacunek, nie pomiar)

W oknie przeciążenia TAM-88 ok. 6 z ok. 18 wywołań dostało 429 (ok. 1/3). Jeśli wywołania są w przybliżeniu niezależne,
dziś porażka to 2 × 429, czyli ok. 1/9 generowań w oknie. Po zmianie porażka to 3 × 429, czyli ok. 1/27 generowań,
a do tego dochodzą dłuższe przerwy. Dla przebiegu TAM-88 to średnio ok. 0,7 porażki zamiast 2, czyli wynik 39–40/40.
To przybliżenie: 429 w tym samym oknie nie są niezależne. Zweryfikuje je pomiar w dev, bez specjalnego płatnego testu.

## Koszt

- **Tokeny:** wywołanie z 429 jest odrzucane przed przetworzeniem i nie nalicza tokenów. Płatnych prób jest nadal
  najwyżej 2, więc **pułapy z `costs.md` (sekcje 0 i 4) się nie zmieniają**. Ryzyko: jeśli Vertex kiedyś naliczy coś za 429,
  sprawdzimy to w Billing. Wtedy najgorszy przypadek to 3 płatne wywołania, tylko w generowaniach z 429.
- **Cloud Functions:** do 12 s czekania i ok. 1 s na każde 429, tylko w generowaniach z 429. Przy 512 MiB to ułamek
  grosza na generowanie. W skali testów mieści się w darmowym limicie. **Dodatkowy koszt: ok. 0 PLN/mies.**
- **Limity dzienne:** bez zmian (pkt 7).

## Alternatywy Vertex (nie włączamy, nic nie zamawiamy)

Ceny orientacyjne z 2026-11-21 (dokumentacja Google o 429 i opcjach zużycia oraz cenniki zewnętrzne). Przed jakąkolwiek
decyzją trzeba je sprawdzić w oficjalnym cenniku Vertex AI i w Cloud Billing.

| Opcja | Jak działa | Koszt dla Tamitu | Ocena |
|---|---|---|---|
| **Priority PayGo** | nagłówek w żądaniu oznacza ruch jako priorytetowy; mniej odrzuceń w tłoku | wyższa stawka za **każdy** token (wysokość dopłaty i dostępność dla `gemini-3.1-flash-lite` w `eu` do potwierdzenia). Przykład: przy dopłacie 50–100% normalne użycie rośnie z ok. 12 do 18–24 PLN/mies., a pułap nadużycia z ok. 82 do 123–164 PLN/mies., czyli powyżej spend cap prod 80 PLN | odłożone; do rozważenia, jeśli pomiar w dev/prod pokaże próg z O-TAM96-2 |
| **Provisioned Throughput** | stały, zarezerwowany przydział (GSU) dla modelu i lokalizacji; nadwyżka dostaje 429 albo jest liczona po stawce PayGo | najkrótszy okres to 1 tydzień, bez anulowania. Według cenników zewnętrznych ok. 7 USD za GSU-godzinę (`global`, okres 1 tydzień), czyli ok. 1 200 USD ≈ **4 800 PLN tygodniowo** za 1 GSU (ok. 20 000 PLN/mies.). Stawka dla punktu regionalnego/`eu` może być inna | odrzucone: setki razy więcej niż cały budżet AI (12 PLN/mies.) |
| **Punkt `global`** | routing do dowolnego regionu Google | bez dopłaty | wykluczone (dane poza UE; ADR-0001 Aneks B) |
| **Inny punkt w UE** (regionalny) | inna pula | płatny test dostępności i jakości, nowy ADR | odłożone; `europe-west4` nie obsługuje modelu (417) |
| **Wyższy poziom użycia (usage tier) Standard PayGo** | Google przydziela wyższy próg tokenów/min wg wydatków z ostatnich 30 dni | nie da się „kupić” bez większych wydatków | nie dotyczy przy naszej skali |
| **Podniesienie limitu w Quotas** | – | 0 | nie dotyczy: dla tych modeli nie ma stałego limitu projektu, a 429 wynika z tłoku w puli. Odczyt konsoli Quotas (bez zmian) może zrobić właściciel |

## Pomiar i próg ponownej oceny

W dev (po TAM-90) i później w prod liczyć z logów (bez danych osobowych):
- odsetek generowań zakończonych `ai_unavailable` z ostatnim błędem 429 (`stopReason`, `modelError=429`),
- odsetek generowań z co najmniej jednym 429 i odsetek wywołań nr 3,
- czas generowania (mediana, p95) w generowaniach z 429.

Propozycja progu (O-TAM96-2): jeśli w ciągu 7 dni **więcej niż 5%** generowań (przy co najmniej 40 generowaniach)
kończy się `ai_unavailable` przez 429, architekt przygotuje wycenę Priority PayGo do decyzji właściciela.
Do tego czasu nic płatnego nie włączamy.

## Konsekwencje

- **Pozytywne:** odporność na krótkie szczyty tłoku w puli Vertex bez żadnego kosztu; pułapy kosztów i limity bez zmian;
  zgodność wstecz kontraktu (`apiVersion` 1, `posrednik-api.md` v0.6).
- **Negatywne:** w najgorszym przypadku (dwa 429 i wolna trzecia próba) użytkownik czeka ok. 1,5 minuty zamiast ok. 1 minuty.
  Mieści się to w EK-07 (do 120 s, rotujące teksty), bez zmian UX. Logika ponowień jest trochę bardziej złożona,
  więc potrzebne są testy jednostkowe (atrapa modelu, wstrzykiwany zegar i `sleep`).
- **Ryzyka:** długie przeciążenie (minuty) nadal da `ai_unavailable`. Łagodzą to zwrot slotu i `retryAfterSec`.
  Wycena alternatyw opiera się częściowo na źródłach zewnętrznych (do weryfikacji).
- **Dane osobowe:** bez zmian. Nowe pola logów to liczby i stałe kody.
- **Ewaluacja (ADR-0001 pkt 2):** kolejne przebiegi będą korzystać z nowej logiki, bo uruchamiacz używa tej samej ścieżki
  co `generatePlan`. Płatnej powtórki TAM-88 nie planujemy.
