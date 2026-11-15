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
