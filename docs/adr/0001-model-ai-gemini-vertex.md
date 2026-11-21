# ADR-0001: Model AI – Gemini (klasa Flash) przez Vertex AI w regionie UE

- Status: zatwierdzony (bramka G2, 2026-11-15; zatwierdził właściciel produktu)
- Data: 2026-11-15
- Autor (rola): architect
- Zadanie: P2-01 (pyt. 1, S5, SEC-15)
- Odpowiedzi właściciela uwzględnione: Q4 (start od Flash, wybór ostateczny po ewaluacji w fazie 3), Q11 (właściciel potwierdza warunki dostawcy AI; do tego czasu `ALLOW_REAL_DATA=false`). Zmiany względem wersji „proponowany" – patrz „Aneks A" na końcu.

## Kontekst
Aplikacja generuje plan dnia (do 14 dni, PL lub EN) na podstawie formularza i preferencji (N1). Wymagania:
- dane osobowe do modelu tylko za osobną zgodą (N5), bez UID, e-maila, lokalizacji i numeru lotu (rejestr D6);
- wariant korporacyjny, region UE, DPA, brak trenowania na danych (S5) – **warunek wstępny: do potwierdzenia nie wysyłamy prawdziwych danych**;
- wyjście ustrukturyzowane (walidacja serwerowa, T4/T5), dobra jakość po polsku i angielsku (R15);
- koszt zmienny pod kontrolą (R3), kierunek właściciela: Gemini.

## Rozważane opcje
| # | Opcja | Plusy | Minusy |
|---|---|---|---|
| 1 | **Gemini na Vertex AI (Google Cloud), region UE** | Ta sama chmura, konto i DPA co Firebase; autoryzacja kontem usługi (IAM) bez klucza statycznego (T1); regionalne przetwarzanie ML dla wybranych modeli; structured output (`responseSchema`); rozliczenie w jednym miejscu (budżety) | Dostępność modelu w regionie i cykl życia modeli trzeba pilnować; część punktów końcowych nie gwarantuje przetwarzania w regionie |
| 2 | Gemini Developer API (AI Studio, klucz API) | Najprostsze wywołanie | Klucz statyczny (T1); brak gwarancji regionu UE i DPA klasy Cloud; w wariancie darmowym dane mogą służyć do ulepszania modeli – **odrzucone (S5)** |
| 3 | Firebase AI Logic (SDK w aplikacji, backend Vertex) | Bez własnego pośrednika, App Check | Sprzeczne z decyzją właściciela (pyt. 2: pośrednik); limity per konto i walidacja serwerowa trudniejsze; prompt w aplikacji – **odrzucone** |
| 4 | Claude/Mistral/OpenAI (Azure OpenAI w UE) | Konkurencyjna jakość; Mistral to dostawca z UE | Drugi dostawca = drugie DPA, konto, rozliczenie; wyższy koszt (Claude, OpenAI) lub słabszy polski (do zmierzenia); poza kierunkiem właściciela. Pozostaje opcją zapasową za abstrakcją (R7) |
| 5 | Model własny / open source | Pełna kontrola | Koszt GPU i utrzymania nieadekwatny do MVP – **odrzucone** |

Kryteria: zgodność z S5/RODO (waga najwyższa), koszt na plan, jakość PL/EN + wyjście JSON, prostota (jedna chmura), możliwość wyjścia z zależności.

## Decyzja
1. **Dostawca:** Gemini na Vertex AI, wywoływany wyłącznie przez pośrednika (ADR-0002) kontem usługi, **regionalny punkt końcowy `europe-west4`** (według dokumentacji Google lokalizacja przetwarzania ML dla Gemini 2.5 Flash – **niezweryfikowane przez Security, SEC-15 poz. 3; sprawdzić ponownie dla wybranego modelu**). Zakaz punktu `global` i Gemini Developer API. Lokalizacja jest stałą środowiskową; kod odmawia startu, jeśli konfiguracja wskazuje punkt inny niż regionalny UE (przegląd Security 1-1).
2. **Klasa modelu:** Flash (równowaga jakości i kosztu), z Flash-Lite jako tańszą alternatywą (Q4: start od Flash zaakceptowany). **Konkretny identyfikator modelu jest parametrem konfiguracji (`AI_MODEL_ID`), nie stałą w kodzie.** Wybór ostateczny w zadaniu P3 po teście na zestawie ewaluacyjnym (min. 20 przypadków × PL/EN: poprawność schematu, język odpowiedzi, ograniczenie godzin pierwszego dnia z US-006, liczba punktów wg tempa). Wygrywa najtańszy model, który przechodzi ≥ 95% przypadków. Tylko modele GA (nie preview); sprawdzić datę wycofania modelu.
3. **Parametry:** `responseMimeType: application/json` + `responseSchema`; temperatura ok. 0,7; `maxOutputTokens` 10 000; „myślenie" (thinking) wyłączone lub z minimalnym budżetem (tokeny myślenia są rozliczane jak wyjściowe); bez narzędzi, bez groundingu, bez wyszukiwania (T4: model bez dostępu do danych/narzędzi). Prompt systemowy po angielsku, język planu jako parametr (ADR-0006).
4. **Abstrakcja:** interfejs `PlanGenerator` w pośredniku; Vertex/Gemini to jedna implementacja (R7).
5. **Warunki dostawcy (SEC-15) – lista kontrolna do wypełnienia przez właściciela/Security PRZED wysłaniem realnych danych.** Do tego czasu pośrednik w środowisku prod przyjmuje wyłącznie dane testowe (flaga `ALLOW_REAL_DATA=false`, patrz ADR-0002).

   | # | Warunek | Stan |
   |---|---|---|
   | 1 | Zaakceptowane warunki przetwarzania danych Google Cloud (CDPA) na koncie firmowym TadeCode | niepotwierdzone |
   | 2 | Dokumentacja „Generative AI on Vertex AI and data governance": dane klienta nie służą do trenowania modeli bez zgody | niepotwierdzone (link i data weryfikacji do wpisania) |
   | 3 | Wybrany model dostępny w `europe-west4` z gwarancją przetwarzania ML w regionie (tabela „Data residency") | do sprawdzenia dla wybranego modelu |
   | 4 | Buforowanie promptów (domyślnie w pamięci, do 24 h) i monitoring nadużyć: ocena, czy wyłączyć lub zażądać wyjątku (zero data retention) | niepotwierdzone |
   | 5 | Brak włączonych logów dostępu do danych (Data Access audit logs) dla Vertex AI zapisujących treść | do konfiguracji (ADR-0003) |
   | 6 | Wpis w tym ADR (nowy ADR zastępujący lub aneks): kto potwierdził, kiedy, źródła | puste |

## Konsekwencje
**Pozytywne:** jeden dostawca i konto; brak statycznego klucza; wymiana modelu zmianą konfiguracji; spełnienie S5 jest możliwe do udokumentowania.
**Negatywne / ryzyka:** cykl życia modeli (wymuszone migracje); ceny zmieniają się (patrz niżej); jakość planów bywa błędna (R5) – łagodzone walidacją i komunikatem w UI; opóźnienie 10–40 s dla długich planów.
**Dane osobowe:** do modelu trafiają pola z rejestru D6 (cel, daty, nocleg, godzina i lotnisko przylotu, preferencje D15, język D16); nie trafiają UID, e-mail, nazwa, lokalizacja, numer lotu. Po naszej stronie prompt i odpowiedź nie są zapisywane ani logowane.

### Szacunek kosztów (skrót; pełna tabela: `docs/architecture/costs.md`)
> **UWAGA: ceny modeli poniżej są NIEZWERYFIKOWANE** (pochodzą z wyszukiwania strony cennika, fragmenty wyników były niespójne). Weryfikacja w oficjalnym cenniku/SKU w Cloud Billing **przed rozpoczęciem fazy 3** – zadanie właściciela i Security. Do tego czasu liczby służą wyłącznie do oszacowania rzędu wielkości.

Założenia: wejście 1 000 tokenów; wyjście ok. 2 100 tokenów dla planu typowego (5 dni, tempo umiarkowane), 5 900 dla 14 dni umiarkowanych, 8 100 dla 14 dni intensywnych; kurs 4,0 PLN/USD. Ceny za 1 mln tokenów (wejście/wyjście) wg strony cennika Vertex AI na 2026-11-15, **do weryfikacji w SKU przed wdrożeniem**: scenariusz A 0,30/2,50 USD (klasa Gemini 2.5 Flash), B 1,50/7,50 USD (nowsza klasa Flash, cena standardowa od 2027-01-01; do końca 2026 promocyjnie 0,75/3,75), C 0,10/0,40 USD (klasa Flash-Lite).

| Profil planu | A (PLN) | B (PLN) | C (PLN) |
|---|---|---|---|
| Typowy (5 dni) | 0,02 | 0,07 | 0,004 |
| 14 dni umiarkowane | 0,06 | 0,18 | 0,01 |
| 14 dni intensywne (maks.) | 0,08 | 0,25 | 0,013 |

Miesięcznie (plan typowy, +10% ponowień): 40 planów (5 testerów) ok. 1–3 PLN; 200 planów (20 testerów) ok. 5–15 PLN; 400 planów ok. 10–30 PLN (A–B). **Pułap teoretyczny jednego konta przy limicie 5/dobę, planach maksymalnych i 2 próbach: ok. 25 PLN (A) – 75 PLN (B) miesięcznie**; pułap globalny ogranicza dzienny bezpiecznik (ADR-0002). Przy limicie 5/dobę i max 14 dniach koszt jest nieistotny w fazie testów; ryzykiem są nadużycia, nie normalne użycie.

## Aneks A (2026-11-15, przy zatwierdzeniu): uwagi Security i procedura `ALLOW_REAL_DATA`
Zmiany nie zmieniają decyzji (model, region, abstrakcja); doprecyzowują warunki wdrożenia. Źródło: `docs/security/przeglad-adr.md` (1-1..1-4, ocena SEC-15).

1. **Procedura przełączenia `ALLOW_REAL_DATA` na `true` (1-4).** Wartość jest w `config/runtime` (`allowRealData`); zmienia ją wyłącznie właściciel (2FA, konsola; agenci nie mają dostępu do prod). Warunki łącznie: (a) wszystkie pozycje 1–6 listy SEC-15 „potwierdzone" z linkiem, datą i osobą, a przy braku możliwości wyłączenia buforowania/monitoringu – jawna decyzja właściciela z oceną ryzyka; (b) zaktualizowane: zgoda AI, polityka prywatności, Data Safety, rejestr danych; (c) wynik SEC-10 wpisany do aneksu ADR-0003; (d) spełniona reguła sprzężenia z App Check (Aneks A w ADR-0002: `ENFORCE_APP_CHECK=true` w prod); (e) aneks do tego ADR (lub nowy ADR) z wpisem kto/kiedy/źródła; (f) wpis w `.farm/log`. Test akceptacyjny (QA): w prod żądanie bez `testData` lub z konta spoza `testUids` zwraca `test_data_only`; po przełączeniu przechodzi.
2. **Rozszerzenie listy SEC-15** (Security, ocena w przeglądzie) o pozycje: (7) podprocesorzy i podstawa ewentualnych transferów poza EOG dla Vertex AI; (8) model jest GA i ma datę wycofania późniejszą niż planowany start; (9) zapis konfiguracji: Data Access audit logs, „thinking", grounding; (10) kryterium zamknięcia jak w pkt 1(a); (11) test akceptacyjny z pkt 1; (12) aktualizacja zgody AI, polityki i Data Safety po potwierdzeniu. Stan pozycji 1–6 pozostaje „niepotwierdzone"; SEC-15 jest `blocked` do działania właściciela (Q11).
3. **Treść pól `lodging`/`destination` (1-3).** Do formularza i zgody AI trafia pomoc: „Nazwa obiektu lub dzielnica (nie wpisuj pełnego adresu prywatnego)" – wymaganie dla Analityka/UI (poza zakresem architekta); brak walidacji blokującej.
4. **Zmiana dostawcy modelu (1-6)** = nowy wpis w rejestrze danych, nowe DPA i nowa wersja zgody AI.
5. **Ceny:** patrz ramka „UWAGA" wyżej i `costs.md` – niezweryfikowane do czasu zadania weryfikacyjnego przed fazą 3.

## Aneks B (2026-11-18, po P3-03): zakres przetwarzania ML i cykl życia modeli
- Status aneksu: **zatwierdzony (2026-11-21, właściciel)** – pkt 1–6 zatwierdzone razem z Aneksem C, treść bez zmian (O-TAM4-2); pkt 7 rozstrzygnięty wcześniej (2026-11-20). Poprzednio: proponowany (2026-11-18).
- Autor (rola): architect. Źródło: pytanie O1 (`docs/open-questions.md`, sekcja „Konfiguracja środowisk (P3-03)"), runbook `.farm/runbooks/P3-03-firebase.md` („Weryfikacja regionu").
- Aneks **koryguje opis faktów** w pkt 1 decyzji i w pozycji 3 listy SEC-15. Nie zmienia wyboru dostawcy, klasy modelu, regionu wywołania ani abstrakcji.

### Fakty (dokumentacja Google, sprawdzone 2026-11-18)
| # | Fakt | Źródło |
|---|---|---|
| F1 | Tabela „Data residency" Vertex AI: dla wszystkich modeli Flash (`gemini-2.5-flash`, `gemini-2.5-flash-lite`, `gemini-3.1-flash-lite`, `gemini-3.5-flash`, `gemini-3.5-flash-lite`, `gemini-3.6/3.7/3.8-flash`) gwarancja przetwarzania ML jest w multi-regionie **UE** (`eu`); kolumna „Holandia" (`europe-west4`) jest pusta – **brak gwarancji przetwarzania ML w Holandii**. | https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/data-residency |
| F2 | Multi-region `eu` obejmuje wyłącznie państwa członkowskie UE (bez Wielkiej Brytanii i Szwajcarii). Regionalne punkty końcowe UE utrzymują przetwarzanie ML w jurysdykcji odpowiadającej regionowi (dla Europy: UE lub kraj – zależnie od modelu). Punkt `global` nie daje żadnej gwarancji lokalizacji. | jw. |
| F3 | Sam punkt końcowy nie jest gwarancją lokalizacji; rozstrzyga tabela „Data residency". | https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/locations |
| F4 | `gemini-2.5-flash` i `gemini-2.5-flash-lite` mają datę wycofania **2026-10-20** (już minęła); następcy wg Google: `gemini-3.8-flash`, `gemini-3.5-flash`, `gemini-3.5-flash-lite`. Modele GA z oknem ≥ 12 mies.: `gemini-3.8-flash` (wycofanie 2027-09-02 lub później), `gemini-3.5-flash` (2027-05-19 lub później), `gemini-3.5-flash-lite` (2027-07-21 lub później), `gemini-3.1-flash-lite` (2027-05-07 lub później). Krótkie okno: `gemini-3.6-flash` (2026-11-19), `gemini-3.7-flash` (2027-01-28). | https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versions |
| F5 | Lista regionów przetwarzania ML na stronie modelu `gemini-2.5-flash` nie wymienia `europe-west4` (tylko multi-region UE, `europe-west2`, `-west3`, `-west9`). Czy wybrany model 3.x jest **obsługiwany** na punkcie `europe-west4`, nie udało się potwierdzić z treści dokumentacji. | https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/2-5-flash |

### Decyzja (korekta)
1. **Pkt 1 decyzji – nowe brzmienie zakresu:** pośrednik wywołuje Vertex AI z regionu `europe-west4` przez **regionalny punkt końcowy `europe-west4`**; **przetwarzanie ML odbywa się w granicach UE (multi-region `eu`), bez gwarancji, że wyłącznie w Holandii**. W dokumentach dla użytkownika (zgoda AI, polityka, Data Safety) piszemy „przetwarzanie w Unii Europejskiej", nie „w Holandii". Region funkcji, Firestore, logów i sekretu – bez zmian (`europe-west4`, ADR-0003).
2. **Dopuszczalne punkty końcowe:** `europe-west4` (domyślny) albo multi-region `eu` – oba dają tę samą gwarancję (F1, F2). `eu` stosujemy tylko wtedy, gdy wybrany model nie jest obsługiwany na `europe-west4` (wynik testu z pkt 4). Zakaz punktu `global`, innych regionów spoza UE i Gemini Developer API – bez zmian. Walidacja startu (przegląd Security 1-1) akceptuje dokładnie te dwie wartości.
3. **Model (doprecyzowanie pkt 2):** kandydaci do ewaluacji to wyłącznie modele GA z wycofaniem ≥ 6 mies. po planowanym starcie testów i z gwarancją UE w tabeli „Data residency": `gemini-3.5-flash`, `gemini-3.8-flash` (klasa Flash), `gemini-3.5-flash-lite`, `gemini-3.1-flash-lite` (Flash-Lite). `gemini-2.5-*` (wycofane) oraz `gemini-3.6-flash`, `gemini-3.7-flash` (krótkie okno) – wykluczone. Kryterium wyboru (≥ 95% przypadków, najtańszy) – bez zmian.
4. **Test przed P3-05 (mobile-dev/qa, dev, dane syntetyczne):** jedno wywołanie wybranego `AI_MODEL_ID` na `europe-west4`; wynik (obsługiwany / błąd „model not found in location") zapisać w runbooku P3-03. Gdy nieobsługiwany – konfiguracja `eu` w obu środowiskach (pkt 2).
5. **Lista SEC-15, pozycja 3 – nowe brzmienie:** „Wybrany model ma w tabeli »Data residency« gwarancję przetwarzania ML w UE (multi-region `eu`) i jest wywoływany z punktu `europe-west4` lub `eu`". Stan: **częściowo potwierdzone przez architekta** (F1 dla wszystkich kandydatów z pkt 3); do potwierdzenia przez Security dla ostatecznie wybranego modelu (SEC-15 pozostaje otwarte).
6. **Ceny i koszty:** scenariusze A i C w szacunku kosztów nazywają modele wycofane (F4). Liczby pozostają szacunkiem rzędu wielkości; tabela w `docs/architecture/costs.md` zostanie przeliczona dla kandydatów z pkt 3 w zadaniu ewaluacji modelu (P3), razem z weryfikacją cennika. Aneks nie zwiększa kosztu.
7. **Preferencja startowa: najpierw Flash-Lite (decyzja właściciela 2026-11-20 – ten punkt jest już rozstrzygnięty, niezależnie od zatwierdzenia reszty aneksu).** Słowa właściciela: „najpierw Flash-Lite w ARCH-01, może wystarczy do prostych rzeczy"; cel – jak najniższy koszt. Zmienia odpowiedź Q4 („start od Flash"; pkt 2 wyżej) w zakresie **kolejności testów i modelu startowego**: test ARCH-01 i pełna ewaluacja P3 zaczynają od `gemini-3.1-flash-lite` i `gemini-3.5-flash-lite` (`thinkingLevel=MINIMAL`); `gemini-3.8-flash` – tylko gdy żaden Flash-Lite nie spełni kryterium „wystarczy" (`docs/architecture/arch-01-gemini-test.md` sekcja 4.6); `gemini-3.5-flash` – tylko na osobną decyzję właściciela. Reguła wyboru z pkt 2 (najtańszy model z ≥ 95% w pełnej ewaluacji, tylko GA) i lista kandydatów z pkt 3 – bez zmian. Koszt: obniża koszt testu (ok. 0,9 zamiast 4,7 PLN w wariancie najgorszym, gdy wystarczy Flash-Lite) i – przy wyborze Flash-Lite – koszt zmienny ok. 3–6× (`costs.md` sekcje 2–4). **W MVP bez innych dostawców i bez wyboru modelu przez użytkownika** (decyzja właściciela 2026-11-20: „w MVP zostajemy przy tym, co mamy”). Modele innych firm i wybór modelu w ustawieniach są pomysłem do rozważenia po MVP. Wymagałyby nowego ADR (jakość po polsku, koszt i limity, RODO: nowy odbiorca, polityka i zgoda AI). Wyszukiwanie w sieci (grounding) pozostaje wyłączone (pkt 3). Model planuje z własnej wiedzy, a ARCH-01 sprawdza ją kryteriami K3 (fakty) i K4 (łączenie preferencji).

### Wpływ na `docs/security/` (zgłoszone do Security, bez edycji – katalog Security)
- `personal-data-register.md`, D6: „punkt regionalny `europe-west4`" → dopisać „przetwarzanie ML w UE (multi-region `eu`), bez gwarancji NL".
- `privacy-checklist.md`: pkt Vertex AI (punkt `europe-west4` **lub** `eu`), pkt „Transfery poza EOG" – AI: „w UE", nie „Holandia" (Holandia zostaje dla Firestore i logów).
- `przeglad-adr.md` 1-1 i lista SEC-15 poz. 3 – nowe brzmienie z pkt 5.
- O5 (buforowanie Vertex do 24 h): dokumentacja „Data residency" nie podaje lokalizacji bufora – pytanie do SEC-15 poz. 4.

### Konsekwencje
**Pozytywne:** opis zgodny z gwarancją Google (UE), brak zmiany infrastruktury; usunięte ryzyko wyboru wycofanego modelu.
**Negatywne / ryzyka:** przetwarzanie może odbywać się w innym państwie UE niż dane w spoczynku (bez wpływu na transfer poza EOG); zależność od testu obsługi modelu w `europe-west4`.
**Dane osobowe:** zakres D6 bez zmian; zmienia się opis miejsca przetwarzania (UE). Wymaga aktualizacji opisu w rejestrze i polityce (Security).

## Aneks C (2026-11-21, po ARCH-01): model startowy `gemini-3.1-flash-lite` na punkcie `eu`
- Status aneksu: **zatwierdzony (2026-11-21, właściciel)** (decyzja w zadaniu TAM-4 / ARCH-01, przekazał orkiestrator).
- Autor (rola): architect. Zadanie: TAM-4 (ARCH-01). Źródła: `docs/architecture/arch-01-gemini-test.md` sekcja 6 (wyniki), `docs/architecture/costs.md` sekcja 0 (koszt), `docs/architecture/p3-05-wymagania-generowania.md` (wymagania dla P3-05).
- Aneks **uzupełnia** pkt 2–3 decyzji i Aneks B pkt 3–4 i 7. Nie zmienia dostawcy, abstrakcji (`PlanGenerator`), zakazu punktu `global` ani reguły końcowego wyboru (pełna ewaluacja, ≥ 95%).

### Co i po co
Test ARCH-01 (etap A, 5 fikcyjnych przypadków na model, dane bez danych osobowych) sprawdził dwa najtańsze modele.
Oba działały tylko na punkcie `eu`, odpowiadały w 2–14 s i bez tokenów myślenia. Oba miały ten sam błąd:
za mało punktów w niektórych dniach długich planów. Właściciel wybrał tańszy z nich, a błąd ma usunąć prompt
i walidacja w P3-05.

### Decyzja
1. **Model startowy P3-05:** `AI_MODEL_ID = gemini-3.1-flash-lite` (GA, wycofanie 2027-05-07 lub później). Zapasowy (zmiana konfiguracji, bez zmiany kodu): `gemini-3.5-flash-lite` – sprawdzony w tym samym teście, ok. 1,6–1,9× droższy.
2. **Myślenie:** `generationConfig.thinkingConfig.thinkingLevel = MINIMAL`. Nie używać `thinkingBudget` (przestarzały dla Gemini 3+). Zmierzone myślenie: 0 tokenów.
3. **Punkt końcowy:** multi-region **`eu`** (`https://aiplatform.eu.rep.googleapis.com`, lokalizacja `eu`) w **dev i prod**. Sonda: `europe-west4` – błąd 417 dla obu modeli Flash-Lite, `eu` – OK. To jest wynik testu z Aneksu B pkt 4 i przypadek „`eu`, gdy model nie działa na `europe-west4`" z Aneksu B pkt 2. Walidacja startu nadal przyjmuje tylko `europe-west4` lub `eu`. Region funkcji, Firestore i logów – bez zmian (`europe-west4`).
4. **Pozostałe parametry bez zmian** (pkt 3): `responseMimeType: application/json` + `responseSchema`, temperatura 0,7, `maxOutputTokens` 10 000 (zmierzone maks. 5 870), bez narzędzi, groundingu i jawnego cache; buforowanie Vertex wyłączone (`disableCache=true`; w dev potwierdzone, w prod – warunek przed pierwszym wywołaniem w prod).
5. **Ograniczenie `responseSchema` (fakt z testu):** Vertex zwraca **400**, gdy schemat ma jednocześnie `minItems`/`maxItems` dla `days` i `maxItems` dla punktów dnia. Schemat wysyłany do modelu jest więc **uproszczony**, a pełne reguły (liczba punktów wg tempa, dni, godziny, długości) sprawdza **walidator po stronie serwera** – zgodnie z pkt 3 i T4/T5. Szczegóły: `p3-05-wymagania-generowania.md` sekcja 3.
6. **Braki K1 w teście (liczba punktów):** nie dyskwalifikują modelu startowego (decyzja właściciela; `arch-01-gemini-test.md` sekcja 7, wiersz 3). P3-05 przekazuje modelowi docelową liczbę punktów dla każdego dnia, a serwer odrzuca i ponawia (maks. 2 próby, bez zmian) odpowiedź, która jej nie spełnia. Ostatni dzień (przy co najmniej 2 dniach): od 1 do górnej granicy tempa, nigdy pusty; dni środkowe – pełny zakres tempa (decyzja właściciela 2026-11-21, O-TAM4-1).
7. **Etap B pominięty:** `gemini-3.8-flash` i `gemini-3.5-flash` – nie testowane. Wracamy do nich tylko wtedy, gdy pełna ewaluacja z promptem P3-05 nie osiągnie ≥ 95% dla obu Flash-Lite (osobna decyzja właściciela; koszt ok. 3–6× wyższy).

### Konsekwencje
**Pozytywne:** najniższy koszt zmienny z kandydatów (plan typowy ok. 0,015 PLN, maks. ok. 0,055 PLN; `costs.md` sekcja 0); krótki czas odpowiedzi (C3, 14 dni: 13 s); brak kosztu myślenia.
**Negatywne / ryzyka:** (a) najkrótszy cykl życia z kandydatów – przed startem publicznym sprawdzić następcę (zadanie proponowane w `.farm/log`); (b) model słabiej trzyma liczbę punktów w długich planach – więcej ponowień, jeśli prompt nie pomoże (koszt nadal pomijalny, ale gorszy czas oczekiwania i ryzyko `ai_invalid_response`); (c) wybór oparty na 5 przypadkach – potwierdza go pełna ewaluacja P3.
**Dane osobowe:** zakres D6 bez zmian. Miejsce przetwarzania: UE (multi-region `eu`), jak w Aneksie B pkt 1. Lista SEC-15 poz. 3 i 8 – do potwierdzenia przez Security dla `gemini-3.1-flash-lite` (SEC-15 / TAM-54 pozostaje otwarte; `ALLOW_REAL_DATA=false` do czasu zamknięcia).
**Koszt (zasada 10):** aneks obniża koszt względem klasy Flash; nie zwiększa żadnego limitu. Limity bez zmian: 5/dobę na konto, 25/dobę globalnie, spend cap dev 15 PLN / prod 80 PLN.
**Uwaga o Aneksie B:** Aneks C opiera się na pkt 2 i 4 Aneksu B (punkt `eu`). Aneks B (pkt 1–6) zatwierdzony przez właściciela 2026-11-21 razem z tym aneksem (O-TAM4-2).
