# ADR-0018: Równoczesne rezerwacje limitu (kontencja na `usage_global`)

- Status: **proponowany** (zatwierdza właściciel przy merge'u PR-a TAM-115)
- Data: 2026-11-26
- Autor (rola): architect
- Zadanie: TAM-115 (P3-05-CONTENTION), na podstawie znaleziska F-1 z `docs/qa/QA-TAM-89-emulator.md` (PR #184)
- **Uzupełnia (nie zastępuje):** ADR-0016 pkt 6 („`ai_busy` tylko wtedy, gdy wszystkie wywołania dostały 429”)
  o drugą przyczynę `ai_busy`: kontencję przy rezerwacji limitu. Reszta ADR-0016 obowiązuje bez zmian.
  ADR-0002 (rezerwacja przed wywołaniem modelu, krok 5) bez zmian. Model danych (`usage`, `usage_global`) bez zmian.

## W skrócie

Gdy kilka próśb o plan przychodzi naraz, wszystkie zapisują ten sam licznik globalny dnia. Baza wtedy czasem
przerywa transakcję (kod ABORTED) i każe spróbować jeszcze raz. Biblioteka Firestore już to robi sama, a gdy
skończą się jej próby, użytkownik dostaje dziś **ogólny błąd** (`internal`), choć nic się nie zepsuło i limit nie
został zużyty.

Decyzja: **nie przebudowujemy licznika**. Zostawiamy ponowienia biblioteki, ale ograniczamy je jawnie do **3 prób**
(żeby zmieścić się w czasie funkcji), a gdy i one się nie udadzą, serwer odpowiada znanym już aplikacji kodem
**`ai_busy`** z `retryAfterSec = 60` i `slotReleased = true`. Aplikacja pokazuje wtedy istniejący ekran „asystent
chwilowo zajęty”, odlicza minutę i raz sama ponawia (ADR-0016 pkt 10–14). **Zmiany są tylko w backendzie.**
Koszt: **0 PLN** (kilka odczytów Firestore więcej tylko przy kontencji, w darmowej puli; bez wywołań modelu).

## Kontekst

- **Objaw (F-1, TAM-89):** 10 równoległych `generatePlan` z 5 kont na emulatorze. W jednym przebiegu 7 z 10 odpowiedzi
  to `internal` po ok. 18–23 s, w innym kilka, w ostatnim żadna. Log funkcji: `errorClass=Error`, `errorCode=10`
  (gRPC ABORTED). Limity są bezpieczne: przerwana transakcja nic nie zapisuje, test to sprawdza.
- **Mechanizm:** `reserveQuota` (`backend/functions/src/index.ts`) w jednej transakcji czyta i zapisuje
  `usage/{uid}` i `usage_global/{dzień}`. Ten drugi dokument współdzielą wszystkie konta. Serwerowy SDK Firestore
  blokuje dokumenty pesymistycznie; przy konflikcie przerywa jedną z transakcji (ABORTED).
- **Co już robi SDK** (`@google-cloud/firestore` 9.x, `Transaction.runTransaction`): ponawia transakcję po
  ABORTED (oraz CANCELLED, UNKNOWN, DEADLINE_EXCEEDED, INTERNAL, UNAVAILABLE, UNAUTHENTICATED, RESOURCE_EXHAUSTED),
  domyślnie **5 prób** (`DEFAULT_MAX_TRANSACTION_ATTEMPTS`). Odczekanie przed kolejną próbą: 1 s, 1,5 s, 2,25 s,
  3,4 s, każde z rozrzutem ±50%, czyli łącznie do ok. **12 s** samego czekania, plus czas prób. Wyjątek: po
  RESOURCE_EXHAUSTED i HTTP 409 SDK czeka od razu ok. **60 s** (maksymalne odczekanie). Po wyczerpaniu prób SDK
  rzuca ostatni błąd, a `runGuarded` zamienia go na `internal`. Czyli opcja „ponów z backoffem” **już działa**;
  problemem jest to, co dzieje się, gdy się skończy, i ile to trwa.
- **Emulator a produkcja:** emulator przerywa transakcje częściej niż produkcja (QA, F-1). W produkcji kontencja jest
  możliwa przy kilku równoczesnych generowaniach (`maxInstances = 10`), ale przy obecnej skali (limit globalny 25 na
  dobę, pojedynczy użytkownicy testowi) będzie rzadka.
- **Budżet czasu (ADR-0016 pkt 4):** generowanie ma 100 s od pierwszego wywołania modelu; limit funkcji i klienta to
  120 s. Na wszystko inne (zimny start, token, konfiguracja, zgody, **rezerwacja**, zwrot slotu) zostaje ok. 15–20 s.
  Domyślne 5 prób rezerwacji może zjeść cały ten zapas (do ok. 12 s czekania + próby), więc w najgorszym przypadku
  funkcja przekroczyłaby 120 s i klient dostałby `deadline-exceeded`.
- **Kontrakt dziś:** `ai_busy` = „wszystkie wywołania modelu dostały 429, próba nie zużywa limitu”, `retryAfterSec = 60`
  (ADR-0016 pkt 6, `posrednik-api.md` v0.6). Aplikacja obsługuje go w pełni (`ai_busy_controller.dart`, EK-07).

## Rozważane opcje

Koszt Firestore liczony na jedną rezerwację. Dziś (bez kontencji): **2 odczyty + 2 zapisy**. Każda przerwana próba
transakcji to 2 odczyty (Firestore rozlicza odczyty także w przerwanej transakcji) i 0 zapisów.

| # | Opcja | Plusy | Minusy | Odczyty / zapisy (najgorszy przypadek) | Opóźnienie | Ryzyko |
|---|---|---|---|---|---|---|
| 1a | **Więcej ponowień** (np. 8–10 prób zamiast 5) | mniej porażek pod obciążeniem | dłużej (czekanie rośnie wykładniczo: 10 prób to ok. 1,5 min), przekroczony budżet 120 s; po wyczerpaniu nadal `internal` | 16–20 / 2 | +30–90 s | wysokie (czas funkcji) |
| 1b | **Mniej ponowień, jawnie** (`maxAttempts: 3`) | przewidywalny czas (≤ ok. 4 s czekania) | sama z siebie nie rozwiązuje `internal` | 6 / 2 | ≤ ok. 4 s + 3 próby | niskie |
| 2 | **Rozproszony licznik globalny** (N shardów `usage_global/{dzień}/shards/{i}`) | klasyczny wzorzec na częste zapisy | sprawdzenie limitu wymaga sumy, czyli odczytu **wszystkich** shardów w każdej transakcji, a odczyt blokuje shard tak samo jak dziś dokument: kontencja zostaje. Wariant z limitem na shard (25 / N) daje fałszywe „limit wyczerpany”, gdy jeden shard jest pełny, a inne nie. Zwrot slotu (`ai_busy`) musi pamiętać shard. Więcej dokumentów z TTL, zmiana modelu danych, `firestore-ttl-indexes.md`, testów i odczytu sumy w diagnostyce | N+1 / 2 (np. 6 / 2 przy N=5), przy kontencji N+1 na każdą próbę | ≈ jak dziś | średnie (złożoność, nowe błędy) |
| 3 | **Mapowanie wyczerpanych ponowień na kod kontraktu** (`ai_busy`, `retryAfterSec`, `slotReleased = true`) | użytkownik widzi właściwy komunikat i automatyczne ponowienie; nic do zwrotu, bo nic nie zapisano | sama nie skraca czasu (przy domyślnych 5 próbach nadal do ok. 20 s) | jak dziś (do 10 / 2) | jak dziś | niskie |
| 3' | jak 3, ale **nowy kod** (np. `quota_busy`) | precyzyjna nazwa | zmiana w aplikacji, UX, tekstach PL/EN i kontrakcie dla zdarzenia, które użytkownik odbiera tak samo jak `ai_busy` („chwilowo zajęte, spróbuj za chwilę, nic nie straciłeś”) | jak 3 | jak 3 | niskie, ale więcej pracy |
| 3'' | jak 3, ale **`ai_unavailable`** ze `slotReleased = true` | kod już istnieje | aplikacja pokazuje „niedostępne, spróbuj później” bez automatycznego ponowienia, choć kontencja mija w sekundy | jak 3 | jak 3 | niskie |
| 4 | **Rezerwacja dwuetapowa** (ślepe `increment(1)` na `usage_global` bez odczytu, potem odczyt i ewentualna kompensata) | mniej blokad odczytu | dodatkowe zapisy, chwilowe przekroczenie licznika, wyścig przy kompensacie (fałszywe odmowy), trudne testy; zmiana zasad z `firestore-ttl-indexes.md` pkt 3.2 | 2–3 / 3–5 | ≈ jak dziś | średnie |
| **5** | **1b + 3 (wybrana)** | prosto, w budżecie czasu, właściwy komunikat, zero zmian w aplikacji i modelu danych | `ai_busy` ma teraz dwie przyczyny (rozróżnia je log) | **6 / 2** | **≤ ok. 4 s czekania** + 3 próby | niskie |

Ocena: przy limicie 25 generowań na dobę dla całej aplikacji kontencja jest zjawiskiem rzadkim i krótkim. Shardy (2)
i rezerwacja dwuetapowa (4) rozwiązują problem przepustowości, którego nie mamy, kosztem złożoności i nowego modelu
danych. Wybieramy najprostsze rozwiązanie, które daje użytkownikowi właściwą odpowiedź i mieści się w czasie.

## Decyzja

Opcja 5 (1b + 3). Zasady normatywne, implementacja: mobile-dev (tylko `backend/functions/`).

### A. Ponowienia transakcji limitu

1. Trzy transakcje limitu (`reserveQuota`, `releaseQuota`, `releaseBusyQuota` w `index.ts`) wywołują
   `runTransaction(fn, { maxAttempts: 3 })` (nazwana stała, np. `QUOTA_TX_MAX_ATTEMPTS = 3`). Ponowienia i odczekanie
   (1 s, 1,5 s, ±50%) robi SDK; **własnej pętli ponowień nie piszemy**.
2. Uzasadnienie liczby 3: czekanie najwyżej ok. 3,75 s plus 3 próby (w produkcji po kilkadziesiąt–kilkaset ms),
   czyli rezerwacja mieści się w zapasie z ADR-0016 pkt 4. Zwrot slotu po `ai_unavailable` przy końcu budżetu (ok. 94–100 s)
   też nie przekroczy 120 s. Budżetu generowania (100 s) nie zmieniamy.
3. Klient Firestore zostaje na gRPC (domyślnie). **Nie włączamy `preferRest`**: w trybie REST kontencja przychodzi jako
   HTTP 409, po którym SDK czeka ok. 60 s, co rozbija budżet czasu.

### B. Wynik po wyczerpaniu prób rezerwacji

4. Jeśli `reserveQuota` rzuci błąd z kodem **10 (gRPC ABORTED)** albo **409**, `generatePlanCore` odpowiada:
   `AppError("ai_busy", { retryAfterSec: 60, slotReleased: true })` (HttpsError `unavailable`, jak dziś dla `ai_busy`).
   - `slotReleased = true` jest prawdziwe: ABORTED oznacza, że transakcja **nie została zatwierdzona**, więc nie ma
     żadnego slotu konta ani globalnego do zwrotu. Serwer **nie** wywołuje `releaseQuota` ani `releaseBusyQuota`
     i **nie** zwiększa `usage/{uid}.busyReleased` (bezpiecznik 10 na dobę dotyczy zwrotów, a tu nic nie zwracamy).
   - `retryAfterSec = 60`: ta sama wartość co przy 429. Kontencja mija w sekundy, ale wartość 60 pasuje do istniejących
     tekstów („spróbujemy ponownie za minutę”) i daje jednolite zachowanie aplikacji. Aplikacja raz ponawia sama
     (ADR-0016 pkt 11), a „Spróbuj teraz” działa od razu.
5. Każdy **inny** błąd rezerwacji (np. UNAVAILABLE, DEADLINE_EXCEEDED, INTERNAL po wyczerpaniu prób, błąd uprawnień)
   zostaje `internal`, bez zmian (`posrednik-api.md` reguła 3). Powód: przy tych kodach nie wiadomo, czy zatwierdzenie
   doszło do skutku, więc nie możemy obiecać `slotReleased = true`.
6. Rozpoznanie kodu: na błędzie rzuconym przez `runTransaction` pole `code` równe liczbie `10` (gRPC) albo `409`.
   Czysta funkcja w `limits.ts` (np. `isQuotaContention(e: unknown): boolean`), testowana jednostkowo. Kod błędu nigdy nie
   trafia do odpowiedzi, a do logu tylko przez istniejące `classifyError` (SEC-19).
7. **Zwroty slotu bez zmian** (`posrednik-api.md` reguła 6): jeśli `releaseQuota` albo `releaseBusyQuota` po 3 próbach
   dostanie ABORTED, w logu jest `quotaRelease = release_failed`, a aplikacja dostaje dotychczasowy kod z
   `slotReleased = false`. To rzadkie (zwrot konkuruje tylko z równoczesnymi prośbami) i bezpieczne kosztowo.

### C. Logi (bez danych osobowych)

8. Wpis `generatePlan` dostaje pole **`reserveTries`** (liczba całkowita 1–3: ile razy SDK uruchomiło funkcję
   transakcji rezerwacji; licznik zwiększany na początku funkcji przekazanej do `runTransaction`). Pole jest tylko
   wtedy, gdy generowanie doszło do rezerwacji (po zgodach i `aiEnabled`), także gdy rezerwacja się nie udała.
9. Przy `ai_busy` z kontencji wpis ma **`stopReason = "contention"`** (nowa wartość obok `busy` z ADR-0016 pkt 15;
   pętla generowania się nie zaczęła, więc `calls` nie ma) i nie ma `quotaRelease`. Wpis `generatePlan` z
   `errorCode = ai_busy` rozróżnia więc przeciążenie Vertex (`stopReason = busy`) od kontencji (`contention`).

### D. Aplikacja

10. **Bez zmian.** Aplikacja obsługuje `ai_busy` ze `slotReleased = true` (odliczanie 60 s, jedno automatyczne
    ponowienie, „Spróbuj teraz”, tekst „ta próba nie wlicza się do limitu”). Tekst o „asystencie AI” jest przy
    kontencji nieco nieprecyzyjny, ale dla użytkownika skutek jest ten sam. Zmiana tekstu nie jest potrzebna.

### E. Drobna uwaga z przeglądu PR #184: odrzucony `AI_ENDPOINT_OVERRIDE` w logach

11. **Zmieniamy w tym samym PR-ze** (osobny, mały commit). Dziś odrzucony przełącznik atrapy daje w logu ten sam
    `configError = ai_config_invalid` co brak `AI_MODEL_ID` / `AI_LOCATION`, więc diagnoza (np. przypadkowy wpis
    w `.env.<projekt>`) idzie w złą stronę. Zmiana dotyczy tej samej funkcji i tego samego miejsca w `generatePlanCore`,
    jest mała i ma test jednostkowy, więc osobne zadanie byłoby droższe niż zmiana.
12. Zasada: gdy model nie powstał, bo `parseAiEndpointOverride` zwrócił `rejected` (przy poprawnym `AI_MODEL_ID` /
    `AI_LOCATION`), wpis `generatePlan` ma **`configError = "ai_endpoint_override_rejected"`**; w pozostałych
    przypadkach braku modelu zostaje `ai_config_invalid`. Odpowiedź dla aplikacji bez zmian (`ai_unavailable`,
    `slotReleased = true`). **Nigdy** nie logujemy wartości URL-a ani timeoutu. Fail-closed bez zmian: brak modelu,
    brak wywołań `fetch` i ADC. Logujemy przy żądaniu (jak dziś), nie przy ładowaniu modułu: jedno miejsce i jeden
    mechanizm logów.

## Koszt

- **Firestore:** bez kontencji bez zmian (2 odczyty + 2 zapisy na rezerwację). Przy kontencji do 6 odczytów (3 próby)
  i 0 zapisów, gdy kończy się `ai_busy`. Dziś przy 5 próbach to do 10 odczytów, więc najgorszy przypadek **maleje**.
  Automatyczne ponowienie z aplikacji to jeszcze jedno `generatePlan` (ok. 5 odczytów). Przy limicie 25 generowań na dobę
  to setki odczytów na dobę wobec darmowej puli 50 tys.: **0 PLN**.
- **Model AI:** 0. Przy kontencji model nie jest wywoływany (rezerwacja jest przed modelem, ADR-0002 krok 5).
- **Cloud Functions:** krócej niż dziś w najgorszym przypadku (≤ ok. 4 s czekania zamiast ≤ ok. 12 s). W darmowym limicie.
- **Razem: 0 PLN/mies.** (zasada 10 CLAUDE.md: koszt nie rośnie).

## Konsekwencje

- **Pozytywne:** użytkownik nie dostaje ogólnego błędu przy równoczesnych prośbach, tylko znany komunikat z automatycznym
  ponowieniem i informacją, że próba nie przepadła. Czas rezerwacji jest przewidywalny i mieści się w budżecie 120 s.
  Testy emulatora mogą usunąć tymczasową tolerancję `internal` (EMU-16/17).
- **Negatywne:** `ai_busy` ma dwie przyczyny (rozróżnia je `stopReason` w logu). Pod dużym obciążeniem (którego dziś nie
  mamy) część próśb zakończy się `ai_busy` zamiast czekać dłużej.
- **Kontrakt:** `posrednik-api.md` v0.7: rozszerzony opis `ai_busy`, reguła 1 i logi. `apiVersion` zostaje 1. Pola
  i kody odpowiedzi bez zmian.
- **Model danych i TTL:** bez zmian (`usage`, `usage_global`, polityki TTL, indeksy). `firestore-ttl-indexes.md` pkt 3.2
  dostaje regułę 7 (liczba prób i wynik ABORTED).
- **Dane osobowe:** brak nowych. Nowe pola logów to liczba i stałe kody.
- **Ryzyka:** (a) emulator przerywa transakcje częściej niż produkcja, więc testy EMU-16/17 nie dadzą stałych liczb
  `ai_busy` (asercje muszą to uwzględniać, sekcja „Dla QA” w pliku przekazania); (b) gdyby SDK zmieniło domyślne
  odczekanie, `maxAttempts` nadal ogranicza liczbę prób; (c) gdyby kontencja w produkcji okazała się częsta, wracamy
  do tego ADR (próg niżej).

## Pomiar i próg ponownej oceny

Z logów (bez danych osobowych), w dev i później w prod: liczba wpisów `stopReason = contention`, rozkład `reserveTries`,
liczba `quotaRelease = release_failed`. Jeśli w ciągu 7 dni **więcej niż 2%** generowań (przy co najmniej 100) kończy się
`contention` albo mediana `reserveTries` > 1, architekt wraca do opcji 2 lub 4 z wyceną.

## Historia

- 2026-11-26 (TAM-115, architect): propozycja.
