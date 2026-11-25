# Przegląd Security: ADR-0001..0008 (faza 2, zadanie P2-08)

Stan: 2026-11-15. Autor: Security. Przedmiot: ADR-0001..0008 (status „proponowany"), `docs/architecture/*`, `docs/data/*`, `docs/api/*`, w odniesieniu do `threat-model.md` (v0.3), `personal-data-register.md` (v0.3), `privacy-checklist.md` (v0.3) i wymagań (US-001..011, R12-R16).
**To nie jest porada prawna.** Punkty [PRAWNIK] i [WŁAŚCICIEL] wymagają potwierdzenia. Security nie zmienia ADR ani kodu: uwagi są adresowane do architekta (propozycja zmiany lub aneksu ADR) albo trafiają do backlogu.
Nie weryfikowałem treści dokumentacji Google ani cen (brak dostępu do źródeł w tym zadaniu): twierdzenia ADR o regionach, buforowaniu i zachowaniu Maps URLs traktuję jako **niezweryfikowane** – weryfikacja to SEC-10 i SEC-15.

Skala uwag: **B** = blokująca (blokuje G2 lub zatwierdzenie ADR bez poprawki), **W** = blokuje testy z osobami spoza zespołu / realne dane (nie blokuje G2), **Z** = zalecana zmiana przed implementacją (P3), **N** = niska / informacyjna.

## 0. Werdykt ogólny
- **Brak uwag blokujących G2.** Architektura jest zgodna z zasadą minimalizacji: dane podróży tylko lokalnie i szyfrowane, po stronie chmury wyłącznie zgody, licznik i logi bez treści, brak statycznych kluczy, reguły `deny all`, brak analityki. Wszystkie ADR mogą zostać zatwierdzone na G2 **pod warunkiem** wpisania do backlogu uwag Z (w tym trzech wejść do ADR: Z-1 stary token po usunięciu konta, Z-2 błędy i wyjątki w logach, Z-3 sprzężenie `ENFORCE_APP_CHECK` z `ALLOW_REAL_DATA`) i świadomej decyzji właściciela w Q1, Q2, Q9.
- **Uwagi „W" (blokada testów zewnętrznych i realnych danych)** – zgodnie z eskalacją roli: (1) SEC-15 – brak potwierdzenia warunków dostawcy AI (wszystkie 6 pozycji w ADR-0001 „niepotwierdzone/puste"); (2) S1 – brak danych administratora i opublikowanej polityki; (3) SEC-10 – lokalizacja Firebase Auth i innych usług niezweryfikowana; (4) [PRAWNIK] – podstawy prawne, zgody, okres dowodu zgód. Do ich zamknięcia obowiązuje `ALLOW_REAL_DATA=false` (ADR-0002) – to jest właściwa, techniczna realizacja warunku S5.

## 1. ADR-0001 – Model AI: Gemini (Flash) na Vertex AI, `europe-west4`
**Zgodność:** zgodny z S5 (wariant korporacyjny, region UE) i T1/T13: brak statycznego klucza, wywołanie wyłącznie z pośrednika, odrzucenie Developer API (słusznie: wariant darmowy bywa wykorzystywany do ulepszania modeli – do potwierdzenia przy SEC-15, ale odrzucenie jest bezpieczne), brak narzędzi/groundingu (T4), `responseSchema`, „thinking" wyłączone. Lista warunków SEC-15 w ADR jest dobrym punktem wyjścia.

| # | Uwaga | Waga | Propozycja |
|---|---|---|---|
| 1-1 | Twierdzenie, że `europe-west4` jest „potwierdzony w dokumentacji Google" dla Gemini 2.5 Flash, jest niezweryfikowane przez Security; dla ostatecznie wybranego modelu (może inna generacja, ceny B/C) dostępność i gwarancja przetwarzania ML w regionie mogą się różnić. Punkt `global` zakazany – dobrze | W | Pozycja 3 listy SEC-15 jest wymagana przed realnymi danymi; test techniczny: kod odmawia startu, jeśli `AI_MODEL_ID`/lokalizacja wskazują punkt inny niż regionalny UE (konfiguracja lokalizacji jako stała środowiskowa, nie dowolny parametr) |
| 1-2 | Buforowanie promptów (do 24 h w pamięci) i monitoring nadużyć u dostawcy: nie wiadomo, czy treść promptów jest przechowywana poza naszą kontrolą i na jak długo. Rejestr D6 mówi „po naszej stronie brak zapisu", co jest prawdą, ale polityka i zgoda **nie mogą** twierdzić „nigdzie nie zapisujemy" | W | SEC-15 poz. 4: zapisany wynik oceny; treść zgody AI i polityki pisana dopiero po potwierdzeniu; jeśli zapis u dostawcy możliwy – opisać okres w polityce |
| 1-3 | Pola tekstowe `destination`, `lodging`, `airport` trafiają do modelu. `lodging` może być pełnym adresem prywatnym (nocleg u znajomych, Airbnb) – to dana osobowa osoby trzeciej/miejsce pobytu. Oczyszczanie przepuszcza litery i cyfry, więc nie ograniczy adresu. Rekomendacja UX „nazwa obiektu lub okolica" jest tylko rekomendacją | Z | Tekst pomocy w formularzu (PL/EN) i w zgodzie AI; wymaganie w US-004 (Analityk) lub w specyfikacji UI: etykieta „Nazwa obiektu lub dzielnica (nie wpisuj pełnego adresu prywatnego)". Test: brak walidacji nie blokuje, tylko informacja |
| 1-4 | `ALLOW_REAL_DATA`: mechanizm właściwy, ale sam parametr jest jedynym zabezpieczeniem; zmiana na `true` to krytyczna decyzja bez opisanej procedury | Z | Procedura przełączenia (kto, kiedy, dowód SEC-15 w ADR-aneks, wpis w `.farm/log`); `true` tylko w prod po wpisie 6 w liście SEC-15; zmiana parametru w `config/runtime` wymaga dostępu właściciela (nie agentów) – por. T27 |
| 1-5 | Koszty: pułap globalny przy ataku (por. 2-5). Informacyjnie: ceny z `costs.md` niezweryfikowane | N | Bez zmian; SEC-09 |
| 1-6 | Abstrakcja `PlanGenerator` (R7) ułatwia zmianę dostawcy; zmiana dostawcy = nowy wpis w rejestrze, DPA i nowa zgoda/wersja zgody | N | Dopisać do ADR przy ewentualnej zmianie |

**Ocena SEC-15 (wymagania):** lista z ADR-0001 (6 pozycji) jest niezbędna, ale **niewystarczająca**. Proponuję rozszerzyć o:
- (7) lista podprocesorów i podstawa ewentualnych transferów poza EOG dla Vertex AI (nie tylko Firebase) – wpis do polityki;
- (8) potwierdzenie, że wybrany model jest GA i ma datę wycofania późniejszą niż planowany start (R7) – dotyczy ciągłości, nie RODO, ale zmiana modelu może zmienić warunki;
- (9) zapis, że włączono/wyłączono: Data Access audit logs dla Vertex AI (poz. 5), „thinking" i grounding (zgodnie z ADR);
- (10) konkretne **kryterium zamknięcia**: pozycje 1-6 „potwierdzone" z linkami, datą i osobą; przy braku możliwości wyłączenia buforowania/monitoringu – decyzja właściciela z oceną ryzyka (nie milczące przyjęcie);
- (11) test akceptacyjny SEC-15: żądanie bez `testData`/z konta spoza `testUids` w prod zwraca `test_data_only`, a po przełączeniu – przechodzi (QA);
- (12) aktualizacja zgody AI, polityki i Data Safety po potwierdzeniu (spójność z faktycznym stanem).
Status SEC-15: pozostaje `blocked` do działania właściciela; zadanie przypisane: właściciel + Security (potwierdzenia), architekt (aneks ADR).

## 2. ADR-0002 – Pośrednik (Cloud Functions callable), limity, brak cache, logi, IAM
**Zgodność:** zgodny z T1, T3, T4, T5, T6, T7; brak cache odpowiedzi (słusznie – zero zapisu treści); dwa konta usług z minimalnymi rolami; zakaz logowania treści i wrapper loggera; `consumeAppCheckToken`; kolejność przetwarzania (walidacja przed rezerwacją limitu i przed wywołaniem modelu).

| # | Uwaga | Waga | Propozycja |
|---|---|---|---|
| 2-1 | **Stary token po usunięciu konta.** Token ID Firebase pozostaje ważny do wygaśnięcia (ok. 1 h), a callable standardowo nie sprawdza, czy użytkownik nadal istnieje. Po `deleteAccount` wywołanie `recordConsent`/`generatePlan` ze starym tokenem **odtworzy** `users/{uid}/consents/*` i `usage/{uid}` dla nieistniejącego UID: dane osierocone, sprzeczne z US-010 i T14 (kopia `consents` nie ma TTL). To również wektor dla (nieistotnego kosztowo, ale istniejącego) nadużycia po kradzieży tokenu | Z (do ADR) | Funkcje zapisujące (`recordConsent`, `generatePlan`) sprawdzają istnienie użytkownika (np. weryfikacja z `checkRevoked`/odczyt użytkownika Admin SDK) albo `deleteAccount` zapisuje na krótko znacznik „usunięte" z TTL 2 h; test E2E rozszerzyć: wywołanie ze starym tokenem po usunięciu nie tworzy dokumentów (SEC-07). T24 |
| 2-2 | **Logi poza wrapperem.** Wrapper ogranicza własne logi, ale (a) nieprzechwycone wyjątki i błędy bibliotek (walidator schematu, SDK Vertex) mogą zawierać wartości pól lub fragmenty promptu i trafiają do Cloud Logging automatycznie; (b) logi żądań platformy (adres IP, user agent, czas) powstają poza kontrolą wrappera; (c) czy Error Reporting lub inne usługi kopiują komunikaty błędów poza kubełek UE – niezweryfikowane | Z (do ADR) | Globalny handler: łapanie wszystkich wyjątków, logowanie wyłącznie kodu i klasy błędu, nigdy `error.message`/stosu z danymi; walidator zwraca ścieżki pól bez wartości (zgodne z API); test: żądanie z kontrolnym ciągiem w polu → grep logów emulatora i testowego projektu nie znajduje ciągu; sprawdzić w SEC-10 Error Reporting. T25, SEC-04 |
| 2-3 | `uidHash` = HMAC z jednym „pieprzem" w Secret Manager: to pseudonimizacja (art. 4 pkt 5), nie anonimizacja; osoba z dostępem do pieprzu i listy UID może powiązać logi. Po usunięciu konta logi pozostają do 30 dni (zgodne z S7, ale opisać w polityce) | N | Pieprz tylko dla `fn-ai`/`fn-account`, nie ten sam co ewentualny pieprz archiwum zgód (Q9); rotacja przy podejrzeniu wycieku; opis w polityce |
| 2-4 | **Egzekwowanie zgody AI po stronie serwera** opiera się na rekordzie w Firestore. Wycofanie zgody zapisane lokalnie, gdy brak sieci, nie trafia na serwer – serwer nadal widzi „granted". Klient blokuje generowanie lokalnie (US-003), więc to obrona warstwowa, ale nie pełna | Z | Wycofanie zgody wymaga online i zapisu `recordConsent` **przed** potwierdzeniem w UI (lub kolejka z blokadą lokalną do synchronizacji); tekst zgody mówi, że wycofanie działa od momentu zapisu. T30 |
| 2-5 | **Limit globalny jako wektor DoS i koszt przy wielu kontach.** Limit 5/konto + globalny 50/dobę: atakujący z kilkoma kontami Google wyczerpie globalny limit i zablokuje uczciwych użytkowników (dostępność, T26). Przy `ENFORCE_APP_CHECK=false` nic nie wymusza użycia oficjalnej aplikacji. Koszt: wg liczb z ADR-0001 (maks. plan, scenariusz B, 2 próby, ok. 0,5 PLN) 50 generowań to ok. 25 PLN/dobę – kilkukrotnie więcej niż dzienny udział budżetu prod 100 PLN/mies. (obliczenie Security na podstawie ADR; ceny niezweryfikowane); `budgetGuard` reaguje z opóźnieniem | Z | (a) dla fazy testów globalny limit niski i nastawiony na test (jest); (b) przed wydaniem publicznym przegląd: limit per UID + próg globalny skalowany do budżetu; (c) rozważyć limit per „nowe konto" (wiek konta) lub zaproszenia – decyzja właściciela; (d) alert na wyczerpanie globalnego limitu (sygnał ataku). T3, T26, SEC-09 |
| 2-6 | **Sprzężenie App Check i danych realnych.** ADR dopuszcza `ENFORCE_APP_CHECK=false` na dev „na czas testów" i monitorowanie w prod. Wyłączenie egzekwowania w prod razem z realnymi danymi to najgorszy wariant | Z (do ADR) | Reguła: `ENFORCE_APP_CHECK=false` dozwolone **tylko** (a) w `dev` z danymi syntetycznymi albo (b) w prod, gdy `ALLOW_REAL_DATA=false`; start funkcji odmawia konfiguracji prod z `ALLOW_REAL_DATA=true` i `ENFORCE_APP_CHECK=false`. Szczegóły: Q2, pkt 10 niżej. T27 |
| 2-7 | Role: `fn-account` ma uprawnienia usuwania użytkowników Auth i pełne Firestore – błąd w `recordConsent` (wejście od klienta) daje szeroki skutek. Rozdzielenie `recordConsent` (tylko zapis zgód) od `deleteAccount` (usuwanie) zmniejszyłoby powierzchnię | Z | Trzy konta usług lub konta per funkcja; `budgetGuard` bez dostępu do Auth. T28 |
| 2-8 | Parametr `testUids` w `config/runtime` (UID właściciela) – dane osobowe właściciela w konfiguracji; zmiana wymaga zabezpieczenia dostępu do konsoli Firestore (2FA, T17) | N | Opis w dokumentacji operacyjnej; dostęp tylko właściciel |
| 2-9 | `testData` flaga w żądaniu: asercja klienta, ale serwer sprawdza listę UID – poprawnie. Odnotować, że flaga nie jest zabezpieczeniem sama w sobie | N | – |
| 2-10 | Odpowiedź modelu wyświetlana w aplikacji: walidator odrzuca URL-e i znaczniki – dobrze (T5). Dodać: test kodowania procentowego nazw w linku (znaki `&`, `#`, `|`, `%` oraz nawiasy) i odrzucenie sekwencji markdown-linków | N | SEC-06 |

Dodatkowo: kolejność „zgoda AI -> `aiEnabled`/`ALLOW_REAL_DATA` -> limit" jest poprawna z perspektywy prywatności (dane nie trafiają do modelu przed spełnieniem warunków).

## 3. ADR-0003 – Firebase/GCP: dev/prod, region, budżety, logi
**Zgodność:** dobra: region UE dla danych aplikacyjnych, własny kubełek logów z retencją 30 dni, wyłączone Analytics/Crashlytics/Storage, `deny all`, brak kopii (prostsze usuwanie), brak automatycznego odłączania billingu, WIF dla CI (brak kluczy JSON), App Check, ograniczenie klucza API.

| # | Uwaga | Waga | Propozycja |
|---|---|---|---|
| 3-1 | **Logi: poprawność konfiguracji kubełka** to kluczowy punkt T7/T25: sink do kubełka UE + wykluczenie z `_Default` musi objąć także logi Cloud Run/Functions i logi aplikacji; `_Required` zostaje (logi audytu administracyjnego, 400 dni, bez danych użytkowników, wg ADR). Kubełek `_Default` nie może po cichu zbierać logów | Z | Zadanie P3-03: skrypt/konfiguracja (IaC lub polecenia w `docs/`) i test odbioru: po wywołaniu funkcji test sprawdza, że w `_Default` brak nowych wpisów aplikacji, a w kubełku UE są (SEC-04/SEC-10) |
| 3-2 | Auth: ADR słusznie odnotowuje możliwe przetwarzanie poza UE. To dotyczy D1, a także logowania przez Google (Google jest tu też administratorem danych konta Google użytkownika) | W | SEC-10: wynik do rejestru, polityka (transfery); do czasu – brak testów z osobami z zewnątrz. T29 |
| 3-3 | Firestore: region nie do zmiany; ADR przewiduje weryfikację przed utworzeniem. Ryzyko prywatności: wybór `eur3` (wieloregion) rozszerzyłby lokalizacje, ale nadal UE | N | Wynik weryfikacji do aneksu ADR |
| 3-4 | Środowisko `dev`: App Check debug i `ENFORCE_APP_CHECK=false`; budżet dev 20 PLN tylko z e-mailem, bez wyłącznika. Tokeny debug App Check są sekretami (rejestrowane w konsoli) | Z | Zakaz commitowania tokenów debug (skan sekretów SEC-01 – dodać wzorce); debug provider tylko w flavorze `dev` (test w CI: `prod` bez dostawcy debug); w `dev` wyłącznie dane syntetyczne – zapis w README |
| 3-5 | `google-services.json` niekomitowany – rekomendacja (klucz API Firebase nie jest sekretem, ale ograniczenie w konsoli i niekomitowanie to rozsądne); wymaga ustalenia ze Stewardem | N | Bez zmian |
| 3-6 | Dostęp: właściciel z 2FA, agenci bez poświadczeń prod – zgodne z T17. Dostęp do konsoli Firestore/Auth to dostęp do UID/e-maili wszystkich użytkowników | N | Lista osób z dostępem w dokumentacji operacyjnej; dostęp do danych na wniosek (S9) procedura właściciela |
| 3-7 | Wyłącznik kosztowy `budgetGuard` jest jedynie powiadomieniem opóźnionym; ryzyko finansowe rezydualne | N | SEC-09; nie blokuje |

## 4. ADR-0004 – Firebase Auth (Google), sesja, usunięcie konta
**Zgodność:** zgodny z T6, T14: brak haseł, tylko zakres podstawowy, SDK zarządza tokenami (D2), weryfikacja `sign_in_provider`, usunięcie ze świeżym logowaniem (`auth_time` ≤ 5 min), idempotencja, kolejność „dane, potem konto", obsługa przerwania na urządzeniu, nowy UID po ponownym logowaniu.

| # | Uwaga | Waga | Propozycja |
|---|---|---|---|
| 4-1 | Stary token po usunięciu – patrz 2-1 (T24) | Z | jak wyżej |
| 4-2 | **Rozbieżność z US-010:** US-010 wymienia „minimalny serwerowy dowód zgód" jako pozostający po usunięciu (z zastrzeżeniem okresu [PRAWNIK]), ADR-0004/0005 domyślnie usuwa go razem z kontem. To spójne z S3 („okres po usunięciu: [PRAWNIK]"), ale tekst US-010 sugeruje zachowanie | N | Do uzgodnienia z Analitykiem po decyzji w Q9; Security nie zmienia requirements |
| 4-3 | Plany zostają na urządzeniu po wylogowaniu (N3). Na urządzeniu współdzielonym osoba z dostępem do telefonu odblokowanego nie zobaczy planów w aplikacji, ale dane (zaszyfrowane jednym kluczem na instalację) pozostają do usunięcia konta lub odinstalowania. Użytkownik, który „wylogowuje się" na cudzym telefonie, może zakładać, że dane zniknęły | Z | Komunikat przy wylogowaniu (PL/EN): „Twoje plany zostają na tym urządzeniu; usuń je w Ustawieniach lub usuń konto"; wymaganie dla Analityka/UI. Decyzja właściciela N3 pozostaje. T9 |
| 4-4 | `privacy_policy` jako „zgoda": polityka prywatności to obowiązek informacyjny (art. 13), a nie zgoda w rozumieniu art. 6 ust. 1 lit. a; rekord „akceptacji" jest dobrym dowodem zapoznania, ale tekst UI nie powinien sugerować, że to zgoda na przetwarzanie podstaw umownych. Zgoda w sensie RODO dotyczy AI (i lokalizacji) | N | [PRAWNIK] potwierdza sformułowanie (SEC-14); nazewnictwo techniczne bez zmian |
| 4-5 | `deleteAccount` nie wspomina o kasowaniu klucza bazy ani innych kont na tym samym urządzeniu – opisane w `przechowywanie-i-retencja.md` (klucz usuwany, gdy brak baz) | N | OK |
| 4-6 | Ponowne zalogowanie po usunięciu – nowy UID; stare logi (HMAC) nie łączą się z nowym kontem po wygaśnięciu 30 dni – dobrze | N | – |

### Ocena Q9 (dowód zgód po usunięciu konta) – perspektywa prywatności
- **Domyślne zachowanie (usunięcie razem z kontem) jest zgodne z zasadą minimalizacji i prawem do usunięcia** i jest rekomendowane jako stan wyjściowy.
- Argument za przechowywaniem (wykazanie zgody, obrona roszczeń) jest prawny – ocenia [PRAWNIK] (m.in. czy art. 17 ust. 3 lit. e i art. 6 ust. 1 lit. f mogą uzasadniać krótki okres). Security zauważa praktyczną słabość: po usunięciu konta Auth nie istnieje wiązanie UID z osobą; zapseudonimizowany rekord (HMAC UID) pozwala co najwyżej wykazać, że „istniał rekord zgody o danym skrócie", nie że zgodę wyraziła konkretna osoba – wartość dowodowa jest niska, co przemawia za brakiem archiwum.
- **Jeśli prawnik zażąda archiwum**, minimalne wymagania Security dla nowego ADR: osobna kolekcja zapisywana tylko przez `deleteAccount`; pola: HMAC UID (osobny pieprz niż w logach), typ, wartość, wersja, język, znaczniki czasu; **stały, krótki, wskazany w polityce okres** z TTL (np. równy okresowi wskazanemu przez prawnika); brak dostępu klientów; informacja w ekranie usuwania konta i polityce; archiwum jest nadal daną osobową (pseudonim) i podlega prawu dostępu i sprzeciwu; test E2E rozszerzony.
- Status: pytanie pozostaje do prawnika (rejestr D3, checklista pkt 5). Nie blokuje G2.

## 5. ADR-0005 – Przechowywanie lokalne (SQLCipher), backup, zgody
**Zgodność:** silnie zgodny z S4, T9, T21: szyfrowanie bazy (odpowiedź na „rozważyć szyfrowanie" w T9), `allowBackup=false` plus `dataExtractionRules` (także `device-transfer`), brak lokalizacji w pamięci trwałej, klucz w Keystore, wersjonowane zgody dopisywane, egzekwowanie po stronie serwera. **Rekomendacja Security: akceptacja Q7 (szyfrować).**

| # | Uwaga | Waga | Propozycja |
|---|---|---|---|
| 5-1 | Klucz bazy jeden na instalację, w `flutter_secure_storage`. ADR nazywa to „crypto-shredding", ale przy jednym kluczu usunięcie konta kasuje **plik** (nie klucz) – bezpieczne kasowanie zależy od systemu plików. Dla pełnego kryptograficznego usunięcia potrzebny klucz per konto | Z | Rozważyć klucz per konto (wrapped w Keystore) – kasowanie klucza = kasowanie danych; wymaga zmiany ADR (opcjonalne). Minimum: poprawić opis w ADR, by nie obiecywać crypto-shreddingu |
| 5-2 | Utrata klucza => aplikacja zakłada pustą bazę; stary plik zostaje jako osierocone, nieczytelne dane osobowe | Z | Przy utracie klucza usunąć stary plik bazy; test (utrata klucza -> plik skasowany) |
| 5-3 | `flutter_secure_storage`: szczegóły zależą od wersji pakietu i sposobu opakowania klucza (Keystore). Nie weryfikowałem implementacji | N | P3-06: sprawdzić w dokumentacji pakietu zasadność przechowywania klucza (backup wyłączony także dla jego plików, `dataExtractionRules` obejmują całą domenę – zgodnie z ADR) |
| 5-4 | `shared_preferences` zawiera tymczasową zgodę na politykę przed logowaniem (wersja, język, czas) – bez UID, niska wrażliwość; po `recordConsent` usunąć wpis | N | Test: po przesłaniu wpis usunięty |
| 5-5 | Nazwa pliku `tamitu_<sha256(uid)[0..16]>.db` – UID nie jest sekretem, ale to dodatkowy pseudonim na urządzeniu. Akceptowalne | N | – |
| 5-6 | Lokalna baza zawiera numer lotu (opcjonalny, tylko lokalnie): zgodne z D5 | N | – |
| 5-7 | Synchronizacja zgód: pole `synced`, ponowienia – spójne z `recordConsent` idempotentnym. Patrz 2-4 dla wycofania | Z | jak 2-4 |
| 5-8 | Zrzuty ekranu/podgląd w liście ostatnich aplikacji: plany widoczne; nie ma wymogu RODO, ale można rozważyć `FLAG_SECURE` na ekranach zgód i planu | N | Decyzja właściciela (UX); nie blokuje |

## 6. ADR-0006 – i18n PL/EN
**Zgodność:** zgodny z T23/R15: wersja zgody z językiem (`lang`), kody błędów zamiast tekstów (brak wycieków treści z serwera), prompt systemowy po angielsku z parametrem języka, testy prompt injection w obu językach, brak zależności trzecich (T16).

| # | Uwaga | Waga | Propozycja |
|---|---|---|---|
| 6-1 | Walidacja języka odpowiedzi heurystyką słów funkcyjnych bywa zawodna dla krótkich planów; ponowienie kosztuje (limit 2 prób) – zagadnienie kosztu/jakości, nie prywatności | N | Wynik ewaluacji P3-05 |
| 6-2 | Który tekst jest wiążący przy rozbieżności PL/EN (S14) i weryfikacja tłumaczenia EN – wciąż otwarte | W (dla publikacji) | [PRAWNIK]; SEC-14 |
| 6-3 | Wersje zgód `privacy-v1`, `ai-consent-v1` – wersja musi być zmieniana przy każdej zmianie treści w którymkolwiek języku (obie wersje językowe mają wspólny identyfikator wersji) | Z | Wymaganie dla P3-04; test: zmiana tekstu ARB zgody bez zmiany wersji = błąd CI (np. skrót tekstu w teście) |
| 6-4 | Etykiety wartości wyliczeniowych tylko w ARB, identyfikatory angielskie – bez danych osobowych | N | – |

## 7. ADR-0007 – Lokalizacja i link Maps (oraz Q1)
> **Aktualizacja 2026-11-25 (TAM-109):** właściciel wybrał opcję C (Q1 = C) po pozytywnym teście na telefonie (TAM-24); obowiązuje ADR-0017. Poniższa ocena jest historyczna; skutki dla rejestru (D7 wycofany, D8), modelu zagrożeń (T11, T12, SEC-12, SEC-13) i checklisty wprowadzono w TAM-109.

**Zgodność opcji A** (decyzja domyślna wg S6/US-007): zgodna z T11/T12 przy spełnieniu specyfikacji (jednorazowy `getCurrentPosition`, zakaz `getLastKnownPosition`/strumieni, bez stanu i logów, brak tła, test manifestu). Link bez API/klucza (T2). Uwagi:

| # | Uwaga | Waga | Propozycja |
|---|---|---|---|
| 7-1 | Rejestr D8: `origin` może zawierać też **nocleg** (`"{lodging}, {trip.destination}"`) i poprzedni punkt dnia – dane podróży (nocleg) trafiają do Google (Maps) w linku; rejestr wcześniej wymieniał tylko cel i punkty | Z | Poprawione w rejestrze v0.3 (D8); polityka: Google Maps otrzymuje cel, nocleg/punkty i ewentualnie współrzędne |
| 7-2 | Współrzędne w URL (opcja A) mogą trafić do **historii przeglądarki** (fallback gdy brak aplikacji Maps), historii aktywności Google (w Maps) lub, teoretycznie, do innej aplikacji obsługującej link https (`url_launcher` w trybie zewnętrznym). „Nieutrwalanie" dotyczy Tamitu, ale ślad po stronie użytkownika/Google istnieje | Z | W polityce i tekście wyjaśnienia (pkt 2 checklisty): wprost o przekazaniu do Google; test: link otwierany wyłącznie w trybie `externalApplication`, bez zapisu w naszej historii |
| 7-3 | `minSdk` 26: systemy starsze mają mniej poprawek bezpieczeństwa – akceptowalne; nie wpływa na zgodność | N | Q8: akceptuję 26 z perspektywy Security |
| 7-4 | Przy opcji A nadal wymagane: SEC-12 (test braku persystencji), SEC-13 (Data Safety, uzasadnienie uprawnienia), D7, T12, dodatkowa biblioteka `geolocator` (T16, zmergowany manifest) | Z | patrz niżej |

### Ocena Q1: opcja A (dokładna lokalizacja w aplikacji) vs opcja C (link bez `origin`) – perspektywa prywatności
Zastrzeżenie: zachowanie Google Maps przy braku `origin` (użycie bieżącej pozycji użytkownika) wynika z dokumentacji cytowanej w ADR-0007; Security tego nie zweryfikował – wymagany test na urządzeniu (z aplikacją Maps i bez niej, z uprawnieniem i bez uprawnienia lokalizacji w Maps).

| Kryterium | A | C |
|---|---|---|
| Minimalizacja danych (art. 5 ust. 1 lit. c), privacy by design (art. 25) | Tamitu pobiera dokładną pozycję (jednorazowo) | Tamitu nie pobiera lokalizacji w ogóle |
| Uprawnienia Androida | `ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION` | brak (tylko `INTERNET`) |
| Ryzyko wycieku (T12) | wymaga kontroli kodu, pluginu, logów, zrzutów stanu; ślad w historii przeglądarki/Google | T12 i D7 praktycznie wypadają; zostaje ślad po stronie Google/Maps – poza naszą kontrolą i bez naszego udziału |
| Zgoda | uprawnienie systemowe + wyjaśnienie w aplikacji; Tamitu odpowiada za zgodność | użytkownika pyta Google Maps (odrębny administrator) |
| Google Play (Data Safety, deklaracja uprawnień, SEC-13) | wymagane; precyzyjna lokalizacja budzi dodatkowe pytania recenzentów | brak lokalizacji w Data Safety (współrzędne nie przechodzą przez Tamitu) |
| Testy, koszt utrzymania | SEC-12, dodatkowy pakiet, aktualizacje | brak |
| Funkcjonalnie | zgodne z S6/US-007; start „moja lokalizacja" świadomie wybrany | do potwierdzenia testem: sposób, w jaki Maps wybiera start (np. gdy brak uprawnienia lokalizacji w Maps użytkownik wybierze start ręcznie), zachowanie w przeglądarce |
| Zmiana zatwierdzonych decyzji | brak | zmienia S6 i kryteria US-007 (parametr `origin` ze współrzędnymi) – wymaga decyzji właściciela i zmiany requirements (Analityk) |

**Rekomendacja Security: opcja C** (największa pojedyncza redukcja ryzyka prywatności możliwa w MVP: usuwa uprawnienie wrażliwe, wpis D7, SEC-12, większość SEC-13 oraz T12 po stronie Tamitu), pod warunkiem pozytywnego testu na urządzeniu i akceptacji zmiany US-007 przez właściciela. Jeśli właściciel pozostaje przy A (dokładność ma realne znaczenie produktowe, S6 był świadomą zmianą), Security nie blokuje – obowiązuje pełna specyfikacja ADR-0007, SEC-12, SEC-13 i polityka (T12 rezydualne: średnie-niskie). Opcja B (tylko przybliżona) jest sprzeczna z S6 i nie daje korzyści względem C; nie rekomenduję.
Wpływ na dokumenty security zależnie od wyboru zapisany w rejestrze (D7), modelu zagrożeń (T11/T12) i checkliście (pkt 2, 8) – patrz oznaczenia „[zależy od Q1]".

## 8. ADR-0008 – Stos technologiczny
**Zgodność:** zgodny z T16 i D12: wąska lista pakietów, brak SDK analitycznych/reklamowych/crash, własny klient HTTP zakazany (TLS przez SDK), pakiety dodające uprawnienia wymagają uzasadnienia, CI z testem manifestu, skanem sekretów, audytem zależności; reklamy i płatności poza MVP – wymagają osobnych ADR i analizy Security.

| # | Uwaga | Waga | Propozycja |
|---|---|---|---|
| 8-1 | Wersje przypięte i lockfile (`pubspec.lock`, `package-lock.json`) – ADR mówi o przypięciu Fluttera; potrzebne jawnie także lockfile i `npm ci` w CI (T16) | Z | Dopisać w zadaniach P3-01/P3-02 |
| 8-2 | Zależność od `sqlcipher_flutter_libs` „lub odpowiednik" – pakiety szyfrujące są wrażliwe na utrzymanie; sprawdzić aktualność i licencję przed użyciem | Z | Kryteria wyboru w P3-06 (aktualność, aktywne wydania, brak znanych luk) |
| 8-3 | `geolocator` tylko w opcji A (Q1); przy C usunąć z listy | N | Rozstrzygnięte: C (ADR-0017) – bez `geolocator` |
| 8-4 | Backend: Node.js LTS i Vertex SDK – zależności backendu w audycie (SEC-08), minimalne uprawnienia konta usług, brak `console.log` (lint) | N | OK |
| 8-5 | Zakaz „własnego klienta HTTP" – kluczowy dla T10; test CI na brak zależności `http`/`dio` oraz brak `usesCleartextTraffic` | N | SEC-05 |

## 9. Dokumenty pomocnicze (architecture/data/api)
- `model-danych.md`, `przechowywanie-i-retencja.md`: zgodne z rejestrem po aktualizacji v0.3. **Do doprecyzowania:** `usage/{uid}` ma TTL 30 dni od ostatniej aktualizacji – to zgodne z D10 (rejestr: „okno dobowe; rekordy starsze niż 30 dni usuwane"); TTL w Firestore usuwa z opóźnieniem (do ok. 24 h po terminie wg dokumentacji Firestore – niezweryfikowane) – zapisano w rejestrze jako „do ok. 30 dni + opóźnienie TTL".
- `users/{uid}/consents` nie ma TTL: usuwane tylko przez `deleteAccount` (por. 2-1 – ryzyko osierocenia).
- `posrednik-api.md`: kontrakt zgodny z minimalizacją (brak UID/e-mail/lokalizacji/numeru lotu, odrzucanie nieznanych pól, `field` bez wartości). `clientAt` ±24 h – poprawne.
- `zewnetrzne-integracje.md`: dopisać zakaz logowania `data.*` żądań `onCall` w konfiguracji logowania SDK (powiązane z 2-2).

## 10. Ocena Q2 – App Check a dystrybucja testów
Fakty z ADR-0002: Play Integrity (App Check) nie przepuści APK z poza Google Play; `ENFORCE_APP_CHECK` jest parametrem środowiska.
Ocena Security:
- App Check jest **warstwą ograniczającą nadużycia (T3, T18), nie granicą bezpieczeństwa** – zdeterminowany atakujący z zroot-owanym urządzeniem może go obchodzić. Utrata egzekwowania nie ujawnia danych użytkowników (dane podróży i tak nie są w chmurze), ale zwiększa ryzyko kosztowe i DoS limitu globalnego (T26).
- **Rekomendacja:** ścieżka testowa Google Play (wewnętrzna) jako docelowa dla prod. Do czasu jej dostępności: sideload dozwolony **tylko** z flavorem `dev`, projektem `dev` (App Check debug lub monitorowanie), danymi syntetycznymi i niskim budżetem. **W prod `ENFORCE_APP_CHECK=false` tylko przy `ALLOW_REAL_DATA=false`** (patrz 2-6); w chwili włączenia realnych danych w prod – egzekwowanie obowiązkowe.
- Konto Play organizacji to też formalność właściciela (D13: lista testerów to dane osobowe – ograniczyć dostęp, usunąć po testach).
- Nie blokuje G2; wpływa na harmonogram testów zewnętrznych (które i tak blokują S1/S5).

## 11. Lista uwag do backlogu (propozycje, bez zmian w kodzie)
Uwagi Z/W przekazane orkiestratorowi jako wejścia do zadań (statusy w `docs/backlog.md` zaktualizowane tylko tam, gdzie dopisano wejścia):
- SEC-03: sprawdzanie istnienia użytkownika po tokenie (2-1), reguła sprzężenia App Check/dane realne (2-6).
- SEC-04: globalny handler wyjątków, test „ciąg kontrolny w logach", konfiguracja sink/exclusion, Error Reporting (2-2, 3-1).
- SEC-07: test E2E rozszerzony o stary token po usunięciu (2-1); klucz per konto (5-1, opcjonalnie); usunięcie osieroconego pliku (5-2).
- SEC-09: alert na wyczerpanie limitu globalnego (2-5).
- SEC-10: Auth, Vertex, Error Reporting, Secret Manager, App Check/Play Integrity – lokalizacja i transfery.
- SEC-14: wersje zgód zależne od treści (6-3), sformułowanie akceptacji polityki (4-4).
- SEC-15: rozszerzenie listy kontrolnej (pkt 1 powyżej).
- Dla Analityka/UI (poza uprawnieniami Security): tekst pomocy dla pola noclegu (1-3), komunikat przy wylogowaniu (4-3).
