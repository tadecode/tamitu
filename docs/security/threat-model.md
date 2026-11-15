# Model zagrożeń – Tamitu (MVP, wstępny)

Stan: 2026-11-15, wersja 0.3 (po przeglądzie ADR-0001..0008, zadanie P2-08; wcześniej 0.2 po G1 i odpowiedziach właściciela). Autor: Security. Metoda: aktywa, granice zaufania, zagrożenia (STRIDE + prywatność). Architektura: ADR-0001..0008 w statusie „proponowany" (zatwierdzenie na G2): Flutter/Android -> Firebase Auth (Google) -> pośrednik (Cloud Functions 2. gen., `europe-west4`) -> Vertex AI/Gemini (UE); plany lokalnie w bazie SQLCipher; po stronie chmury tylko zgody, licznik i logi.
Zmiany względem 0.2: nowe zagrożenia T24-T30 wynikające z ADR (sekcja 3a); mapowanie mitygacji na decyzje i ocena ryzyka rezydualnego (sekcja 3b); aktualizacje T7, T9, T12 oznaczone „v0.3"; zadania SEC uzupełnione (sekcja 4). Przegląd każdego ADR: `przeglad-adr.md`.
Uwagi do kodu i konfiguracji trafiają do backlogu jako zadania; Security nie poprawia kodu.

## 1. Aktywa
| ID | Aktywo | Dlaczego ważne |
|---|---|---|
| A1 | Klucz/poświadczenia dostępu do modelu AI | Nadużycie = koszty, wyciek danych |
| A2 | Klucz Google Maps / Firebase API key (jeśli użyty) | Koszty, nadużycie limitów |
| A3 | Konta właściciela: Google Cloud/Firebase/Play, GitHub | Pełna kontrola nad usługą i danymi |
| A4 | Budżet projektu (koszty AI) | Wpływ finansowy (R3) |
| A5 | Tożsamość i sesja użytkownika (UID, token) | Przejęcie konta |
| A6 | Dane podróży i plany (miejsce, terminy, nocleg) | Pozwalają wnioskować o nieobecności w domu |
| A7 | Zgody i dowody ich wyrażenia | Rozliczalność RODO |
| A8 | Lokalizacja bieżąca (**dokładna**, S6) | Wysoka wrażliwość; precyzyjna pozycja użytkownika w czasie rzeczywistym |
| A11 | Preferencje podróży (zainteresowania, budżet, tempo, liczba osób) i język | Profil upodobań i orientacyjna sytuacja materialna; wolny tekst może zawierać dane szczególnych kategorii |
| A9 | Licznik użycia i logi | Egzekwowanie limitów; ryzyko danych w logach |
| A10 | Repozytorium, CI, sekrety CI, keystore podpisu | Łańcuch dostaw |

## 2. Granice zaufania
- G-A: urządzenie użytkownika (niezaufane: root, inne aplikacje, kopia zapasowa, utrata telefonu) <-> Internet.
- G-B: aplikacja <-> Firebase Auth/Google (dostawca zewnętrzny).
- G-C: aplikacja <-> pośrednik (Cloud Functions): wejście niezaufane, wymaga uwierzytelnienia i walidacji po stronie serwera.
- G-D: pośrednik <-> model AI: treść od użytkownika trafia do modelu; odpowiedź modelu jest niezaufana.
- G-E: aplikacja <-> Google Maps (współrzędne w linku).
- G-F: deweloperzy/agenci/CI <-> repozytorium i chmura (sekrety, uprawnienia).

## 3. Zagrożenia i mitygacje

| # | Zagrożenie | Aktywa | Waga | Mitygacje (wymagania) | Weryfikacja |
|---|---|---|---|---|---|
| T1 | Wyciek klucza AI (APK, repo, logi, CI) | A1, A4 | W | Klucz nigdy w aplikacji (pośrednik); preferowane konto usługi z IAM zamiast statycznego klucza; jeśli klucz konieczny – Secret Manager; skan sekretów w CI i pre-commit; zakaz sekretów w repo, logach i promptach; rotacja przy podejrzeniu; minimalne uprawnienia konta usługi | Skan APK i repo, przegląd CI |
| T2 | Wyciek/nadużycie klucza Maps lub Firebase API key | A2, A4 | S | Preferowany link bez API (brak klucza); jeśli klucz powstanie: ograniczenie do `pl.tadecode.tamitu` + odcisk certyfikatu i wybranych API; kwoty i alerty; Firebase App Check (Play Integrity) | Konsola Cloud |
| T3 | Nadużycie kosztów (skrypty, pętle ponowień, duże wejścia, wiele kont) | A4 | W | Uwierzytelnienie wymagane (US-011); limit dobowy per UID egzekwowany serwerowo (transakcyjnie); limity rozmiaru wejścia/wyjścia i maksymalnej liczby tokenów; ograniczona liczba ponowień; globalny dzienny bezpiecznik; App Check; alerty budżetowe z progami i mechanizm wyłączenia funkcji po przekroczeniu | Test limitu i obciążeniowy |
| T4 | Prompt injection przez pola formularza, **w tym wolny tekst zainteresowań i nazwa noclegu/celu** (N1; dotyczy obu języków PL/EN – testy w obu) | A1, A6, A11 | S | **Zainteresowania z listy predefiniowanej (rekomendacja N11) zamiast wolnego tekstu; budżet, tempo, liczba osób – wartości ze zbioru, walidowane serwerowo (odrzucenie wartości spoza zbioru);** oczyszczanie i limity pól; rozdzielenie instrukcji od danych użytkownika w prompcie; wyjście ustrukturyzowane (schemat JSON) i walidacja serwerowa; model bez narzędzi i bez dostępu do danych innych użytkowników; brak sekretów w prompcie systemowym; odpowiedź wyświetlana jako zwykły tekst | Zestaw testów adwersaryjnych |
| T5 | Niebezpieczna lub fałszywa treść w odpowiedzi AI (zmyślone miejsca, linki) | A6, A5 | S | Linki do Maps budowane przez aplikację z nazw miejsc, nie przepuszczamy URL-i od modelu; walidacja formatu i godzin; ostrzeżenie o możliwych błędach (US-005) | Testy walidatora |
| T6 | Przejęcie konta (kradzież telefonu, token, konto Google bez 2FA) | A5, A6 | S | Tylko logowanie przez dostawcę (brak haseł); weryfikacja tokenu ID w pośredniku; wylogowanie czyści sesję (US-002); plany izolowane per UID (US-008); ponowne uwierzytelnienie przed usunięciem konta; zalecenie blokady ekranu i 2FA w polityce | Testy US-002/008 |
| T7 | **(v0.3: patrz też T25)** Dane osobowe w logach (formularz, prompty, tokeny, współrzędne, e-mail) | A6, A8, A9 | W | Zakaz logowania treści (US-005, US-007); logowanie tylko metadanych; brak logów debug w wydaniu; filtr logów w pośredniku; retencja logów 30 dni, UID tylko jako skrót (ustalone, S7); brak Crashlytics/Analytics bez wpisu w rejestrze | Grep w kodzie, przegląd logów |
| T8 | Zbyt otwarte reguły Firebase (Firestore/Storage, funkcje publiczne) | A6, A9 | W | Domyślnie `deny all`; licznik zapisywany tylko przez backend (Admin SDK); brak Storage w MVP; funkcje wymagają ważnego tokenu; testy reguł w emulatorze w CI | Emulator reguł |
| T9 | Wyciek danych z urządzenia (kopia zapasowa, root, inne aplikacje, logcat) | A6, A5 | S | Dane w piaskownicy aplikacji; `allowBackup` wyłączone (ustalone, S4); **v0.3 (ADR-0005): baza SQLCipher (AES-256), klucz w Android Keystore (`flutter_secure_storage`), `dataExtractionRules` wykluczają backup i transfer między urządzeniami;** brak jawnych danych w preferencjach; brak logów w wydaniu | Przegląd manifestu |
| T10 | Ruch nieszyfrowany / MITM | wszystkie | S | Tylko HTTPS/TLS; zakaz ruchu cleartext (Network Security Config); brak wyłączania weryfikacji certyfikatów | Przegląd konfiguracji |
| T11 | Nadmierne uprawnienia Androida | A8 | S | Tylko `INTERNET` oraz lokalizacja (dokładna – S6) na pierwszym planie, na żądanie; brak `ACCESS_BACKGROUND_LOCATION`, lokalizacji w tle, aparatu, kontaktów, identyfikatorów telefonu; przegląd zmergowanego manifestu (biblioteki dokładają uprawnienia); zgodność z Data Safety | Analiza manifestu |
| T12 | **[zależy od Q1: przy opcji C zagrożenie praktycznie znika po stronie Tamitu]** Wyciek lokalizacji **dokładnej** (R12): zapis w bazie/cache/preferencjach, logi (logcat, pośrednik), wysłanie do AI lub serwera, usługa działająca w tle, współrzędne w URL-ach zapisanych w planie lub historii | A8 | W | Jednorazowy odczyt na żądanie, na pierwszym planie, po wyborze startu „moja lokalizacja"; bez zapisu i cache (także w stanie aplikacji/zrzutach stanu), bez logów (także debug), nie do serwera ani AI; link budowany w pamięci i niezapisywany w planie z współrzędnymi użytkownika; brak uprawnienia w tle i usług lokalizacyjnych; ocena, czy plugin lokalizacji nie dodaje uprawnień ani nie buforuje pozycji; informacja w polityce, że link przekazuje współrzędne Google; działanie po odmowie. **v0.3 (ADR-0007): jedno wywołanie `getCurrentPosition`, zakaz `getLastKnownPosition`/strumieni, link niezapisywany.** **Ryzyko rezydualne:** po otwarciu linku Google (odrębny administrator) otrzymuje dokładną pozycję; ślad może zostać w historii przeglądarki (fallback) lub aktywności Google – opisane w polityce i Data Safety | Przegląd kodu, grep logów, analiza manifestu |
| T13 | Przekazanie danych do dostawcy AI bez podstaw (brak DPA, trenowanie, region poza UE) | A6 | W | Decyzja w ADR po przeglądzie Security; region UE, DPA, brak trenowania; **bez potwierdzenia nie wysyłać do AI danych realnych użytkowników** (S5); minimalizacja i osobna zgoda | Przegląd warunków dostawcy |
| T14 | Niepełne usunięcie danych (konto Auth, licznik, zgody, logi, kopie, dane lokalne) | A5-A9 | W | Funkcja usuwania: użytkownik Auth + rekordy po UID + dane lokalne; pełna lista miejsc w rejestrze; udokumentowana retencja logów i kopii (S7); test E2E US-010; jasny komunikat przy braku sieci | Test E2E, checklista |
| T15 | Brak podstawy prawnej / wadliwe zgody (domyślnie zaznaczone, bez wersjonowania, bez dowodu) | A7 | W | Zgody niezaznaczone domyślnie, osobne, wersjonowane, z datą; blokady funkcji bez zgody (US-003); wycofanie równie łatwe jak wyrażenie | Przegląd z prawnikiem |
| T16 | Podatne zależności (pluginy Flutter, SDK Firebase, biblioteki funkcji) | wszystkie | S | Audyt zależności w CI; lockfile i przypięte wersje; minimalna liczba pakietów; przegląd uprawnień pakietów | Raport CI |
| T17 | Przejęcie kont właściciela/repo/CI, wyciek keystore | A3, A10 | W | 2FA (najlepiej klucze sprzętowe) na Google/GitHub/Play; minimalne uprawnienia tokenów; sekrety tylko w sekretach CI; keystore poza repo z kopią zapasową; ochrona `main` (Steward) | Checklista właściciela |
| T18 | Fałszywa kopia aplikacji | A5 | N | Dystrybucja przez Google Play, podpis wydań, App Check sprawdza pakiet | – |
| T19 | Dane małoletnich | A6 | S | Założenie: dorośli (N8); informacja w polityce; granica wieku zgody w Polsce do potwierdzenia prawnika; osobna analiza przed reklamami (R14) | Decyzja właściciela |
| T20 | Awaria dostawcy, błędny plan szkodliwy dla użytkownika | A4 | N | Obsługa błędów (US-011), timeouty, ostrzeżenie o błędach AI | Testy |
| T21 | Wnioskowanie o nieobecności w domu z danych podróży po wycieku | A6 | S | Minimalizacja, przechowywanie lokalne, brak udostępniania planów | – |
| T22 | **Wyciek lub nadmiar preferencji (R16):** dane szczególnych kategorii wpisane w wolny tekst, dane osób trzecich, preferencje w logach/promptach, wysłanie do AI bez zgody lub przed warunkami S5, preferencje w kopii zapasowej | A11, A6 | S | Lista predefiniowana zamiast tekstu (rekomendacja N11); budżet tylko jako poziom; objęcie preferencji osobną zgodą na AI (N5) i jej tekstem PL/EN; zakaz logowania wartości preferencji (T7); zapis lokalny, `allowBackup` wyłączone (S4); do AI tylko po zgodzie i po spełnieniu warunków S5 (do tego czasu dane testowe); ostrzeżenie przy ewentualnym polu tekstowym | Przegląd formularza, testy US-004/005 |
| T23 | **Dwujęzyczność (R15):** zgody/polityka wyświetlone w innym języku niż zaakceptowany (słaby dowód), rozbieżność tłumaczeń prawnych, wstrzyknięcie polecenia zmieniającego język lub ujawniającego prompt, ominięcie filtrów w drugim języku | A7, A1 | N | Wersja zgody zapisuje język; teksty PL i EN zatwierdzane razem [PRAWNIK]; testy prompt injection w PL i EN; walidacja języka odpowiedzi; filtry niezależne od języka (schemat JSON, listy wartości) | Przegląd z prawnikiem, zestaw testów |

## 3a. Zagrożenia wynikające z decyzji architektonicznych (v0.3)

| # | Zagrożenie | ADR | Aktywa | Waga | Mitygacje (wymagania) | Weryfikacja |
|---|---|---|---|---|---|---|
| T24 | **Dane osierocone po usunięciu konta:** token ID jest ważny do ok. 1 h, a callable domyślnie nie sprawdza istnienia użytkownika; wywołanie `recordConsent`/`generatePlan` ze starym tokenem po `deleteAccount` odtwarza `users/{uid}/consents` i `usage/{uid}` (zgody bez TTL) | 0002, 0004 | A5, A7, A9 | S | Funkcje zapisujące sprawdzają istnienie użytkownika (np. odczyt użytkownika/`checkRevoked`) lub krótkotrwały znacznik „usunięte"; test E2E ze starym tokenem; zapisy tylko po weryfikacji | SEC-03, SEC-07 |
| T25 | **Treści i dane w logach poza kontrolą wrappera:** nieprzechwycone wyjątki i błędy bibliotek (walidator, SDK Vertex) z wartościami pól/promptem; logi żądań platformy (adres IP); Error Reporting i inne usługi kopiujące komunikaty; błąd konfiguracji sinku (logi wpadają do `_Default` globalnego); włączenie Data Access audit logs | 0002, 0003 | A6, A8, A9 | W | Globalny handler: logowanie tylko kodu i klasy błędu, nigdy `message`/stosu z danymi; walidator zwraca ścieżki bez wartości; sink do kubełka UE + wykluczenie z `_Default`; brak Data Access logs dla Vertex AI/Firestore; test z ciągiem kontrolnym w polu; opis IP i logów administracyjnych (400 dni) w polityce | SEC-04, SEC-10, test w emulatorze i `dev` |
| T26 | **Wyczerpanie limitu globalnego (DoS) i nadużycie kosztów przez wiele kont**, szczególnie gdy App Check nie jest egzekwowany; opóźniony `budgetGuard` | 0002, 0003 | A4 | S | Limit na konto i globalny (niski w fazie testów), `maxInstances`, `maxOutputTokens`, kwoty Vertex AI, alert na wyczerpanie limitu globalnego; egzekwowanie App Check w prod (Q2); przed wydaniem publicznym przegląd limitów i zaproszenia/ograniczenia nowych kont | SEC-09, test obciążeniowy |
| T27 | **Obejście bramki S5 lub pomylenie środowisk:** przełączenie `ALLOW_REAL_DATA=true` przed SEC-15; realne dane w `dev` lub w prod z wyłączonym App Check; nieautoryzowana zmiana `config/runtime` (`aiEnabled`, `testUids`, limity); tokeny debug App Check w repozytorium lub w buildzie prod | 0001, 0002, 0003 | A1, A4, A6 | W | Procedura przełączenia (właściciel, dowód SEC-15 w ADR, wpis w dzienniku); start funkcji odmawia prod z `ALLOW_REAL_DATA=true` i `ENFORCE_APP_CHECK=false`; test `test_data_only`; dostęp do konsoli tylko właściciel z 2FA; skan sekretów (wzorce tokenów debug); debug provider tylko flavor `dev` (test CI); dane syntetyczne w `dev` | SEC-15, SEC-01, test CI |
| T28 | **Nadmierne uprawnienia kont usług i łańcucha wdrożeń:** `fn-account` ma pełne Firestore i usuwanie użytkowników Auth; błąd w `recordConsent` lub przejęcie CI (Workload Identity Federation) daje szeroki skutek; Admin SDK pomija reguły `deny all` | 0002, 0003 | A3, A10, A5 | S | Konta usług per funkcja lub co najmniej rozdzielenie zapisu zgód od usuwania; `budgetGuard` bez dostępu do Auth; WIF ograniczone do repozytorium i gałęzi `main`; przegląd ról (min. uprawnienia) w P3-03; testy funkcji w emulatorze pokrywają ścieżki odmowy | Przegląd IAM, P3-03 |
| T29 | **Transfery i lokalizacja poza kontrolą:** Firebase Auth bez wyboru regionu; niepewne przetwarzanie ML dla wybranego modelu; Error Reporting, App Check/Play Integrity, Secret Manager – lokalizacja niezweryfikowana; Google jako administrator konta Google użytkownika | 0001, 0003, 0004 | A5, A6 | W | SEC-10 (weryfikacja w dokumentacji Google, wynik do rejestru i aneksu ADR); opis transferów w polityce (podstawa wg warunków Google, [PRAWNIK]); do czasu – brak realnych danych i testów zewnętrznych | SEC-10 |
| T30 | **Wadliwy dowód i egzekwowanie zgód:** wycofanie zgody offline nie dociera na serwer (serwer nadal „granted"); zmiana tekstu zgody bez zmiany wersji; zapis zgód po stronie klienta bez gwarancji, że użytkownik zobaczył tekst; sporna wartość dowodowa po usunięciu konta (Q9) | 0004, 0005, 0006 | A7 | S | Wycofanie zgody wymaga zapisu na serwerze (lub blokada lokalna do czasu synchronizacji); wersja zgody powiązana z treścią (test CI); czas serwera obok czasu klienta; Q9: domyślnie usuwanie, ewentualne archiwum zgodnie z wymaganiami w `przeglad-adr.md` | SEC-14, US-003, [PRAWNIK] |

## 3b. Mapowanie mitygacji na decyzje i ocena ryzyka rezydualnego (v0.3)
Skala: W wysokie, S średnie, N niskie. „Rezydualne" = po wdrożeniu mitygacji zgodnie z ADR i uwag z `przeglad-adr.md`; ocena Security, nie audyt kodu (kodu jeszcze nie ma).

| # | Waga przed | Mitygacje zrealizowane w decyzjach | Luki / warunki | Rezydualne |
|---|---|---|---|---|
| T1 | W | ADR-0001/0002: Vertex przez konto usługi IAM, brak klucza; Secret Manager tylko na pieprz HMAC; WIF zamiast kluczy JSON (ADR-0003) | Skan sekretów (SEC-01) | N |
| T2 | S | ADR-0007: link bez klucza Maps; ADR-0003: ograniczenie klucza Firebase do pakietu i odcisku; App Check | Ograniczenie w konsoli (P3-03); `google-services.json` niekomitowany – do ustalenia ze Stewardem | N |
| T3 | W | ADR-0002: App Check (jednorazowe tokeny), limit per UID transakcyjny, limit globalny, `maxInstances`, `maxOutputTokens`, ponowienia ≤ 2; ADR-0003: budżety, `budgetGuard`, kwoty Vertex | Q2 (sideload bez App Check); T26; opóźnienie budżetu | S (faza testów: N-S; do wydania publicznego – przegląd limitów) |
| T4 | S | Wartości ze zbiorów, walidacja serwerowa, `systemInstruction` + dane jako JSON, `responseSchema`, brak narzędzi (ADR-0001/0002); pola tekstowe `destination`/`lodging`/`airport` nadal wolnym tekstem (≤ 80/60 zn.) | Testy adwersaryjne PL/EN (SEC-06); wynik modelu to tylko tekst planu | N-S |
| T5 | S | Walidator odrzuca URL-e/znaczniki; linki budowane w aplikacji z kodowaniem procentowym (ADR-0002/0007) | Test kodowania znaków specjalnych | N |
| T6 | S | ADR-0004: tylko Google, token ID, `sign_in_provider`, `auth_time` ≤ 5 min przy usuwaniu; plany lokalne per konto | T24 (stary token); urządzenie bez blokady | S-N |
| T7 / T25 | W | ADR-0002: wrapper z listą pól, `uidHash` HMAC, brak `console.log`; ADR-0003: kubełek UE 30 dni, wykluczenie `_Default`, brak Data Access logs | Wyjątki i błędy bibliotek, IP, Error Reporting; poprawność sinku | S |
| T8 | W | ADR-0003: `deny all`, Admin SDK, testy reguł; brak Storage | Admin SDK pomija reguły – bezpieczeństwo zależy od kodu funkcji (T28) | N |
| T9 | S | ADR-0005: SQLCipher + Keystore, `allowBackup=false`, `dataExtractionRules`, brak jawnych danych w `shared_preferences` | Root/urządzenie odblokowane; jeden klucz na instalację; osierocony plik po utracie klucza; plany zostają po wylogowaniu (N3) | S-N |
| T10 | S | ADR-0005/0008: `usesCleartextTraffic=false`, Network Security Config, brak własnego klienta HTTP | Test CI | N |
| T11 | S | ADR-0005/0007: lista uprawnień (INTERNET + lokalizacja w opcji A), brak tła, test zmergowanego manifestu, usunięcie `AD_ID` | Q1; pakiety dodające uprawnienia | N (C: bez uprawnień lokalizacji) |
| T12 | W | ADR-0007: jednorazowy odczyt, bez zapisu/stanu/logów, link niezapisywany; opcja C eliminuje | Q1; SEC-12; ślad po stronie Google/przeglądarki | A: S-N; C: N |
| T13 | W | ADR-0001: Vertex UE, zakaz `global` i Developer API, `ALLOW_REAL_DATA=false`; ADR-0002: zgoda AI egzekwowana serwerowo | **SEC-15: wszystkie 6 warunków niepotwierdzone**; buforowanie/monitoring nadużyć u dostawcy; model w regionie niezweryfikowany | **W do czasu SEC-15; po potwierdzeniu: S-N** |
| T14 | W | ADR-0004: `deleteAccount` (kolejność, idempotencja, świeże logowanie); ADR-0005: plik bazy lokalnej; brak kopii | T24; logi 30 dni (opisane); okres dowodu zgód (Q9) | S-N |
| T15 | W | ADR-0005/0006: zgody osobne, wersjonowane, z językiem, serwerowe egzekwowanie | T30; teksty [PRAWNIK] | S |
| T16 | S | ADR-0008: wąska lista pakietów, audyt w CI | Lockfile/`npm ci`; wybór pakietu SQLCipher | S-N |
| T17 | W | ADR-0003: 2FA, WIF, brak poświadczeń prod u agentów | T28; praktyka właściciela | S-N |
| T18 | N | App Check, Play Integrity, podpis | Q2 (sideload) | N |
| T19 | S | Założenie: dorośli; brak reklam | [PRAWNIK] (wiek) | S-N |
| T20 | N | ADR-0002: timeouty, kody błędów, zwrot slotu | T26 | N |
| T21 | S | ADR-0005: dane lokalne i szyfrowane; brak udostępniania | – | N |
| T22 | S | ADR-0002/data: lista predefiniowana, walidacja serwerowa; osobna zgoda | N11/Q6; pola tekstowe (nocleg) – informacja w UI | N-S |
| T23 | N | ADR-0006: wersja zgody z językiem, testy PL/EN | S14 [PRAWNIK] | N |
| T24 | S | – (nowe) | wymaga zmiany/aneksu ADR-0002/0004 (uwaga 2-1) | S do czasu poprawki; potem N |
| T26 | S | – (nowe) | uwagi 2-5, 2-6 | S |
| T27 | W | – (nowe) | uwagi 1-4, 2-6, 3-4 | S po wdrożeniu procedury |
| T28 | S | – (nowe) | uwaga 2-7 | S-N |
| T29 | W | – (nowe) | SEC-10 | W do wyniku SEC-10 |
| T30 | S | – (nowe) | uwagi 2-4, 6-3, Q9 | S |

**Ryzyka wysokie rezydualne (do decyzji człowieka lub potwierdzenia przed realnymi danymi):** T13 (SEC-15) i T29 (SEC-10). Reszta jest średnia lub niska przy spełnieniu uwag Z z `przeglad-adr.md`.

## 4. Zadania do backlogu (zgłoszenia, bez poprawiania kodu)
1. SEC-01 Skan sekretów w CI i pre-commit (prośba do Stewarda w `.farm/requests/`) – T1.
2. SEC-02 Reguły Firebase `deny all` + testy w emulatorze – T8.
3. SEC-03 Weryfikacja tokenu i App Check w pośredniku – T3, T6.
4. SEC-04 Zakaz logowania treści, filtr i retencja logów – T7.
5. SEC-05 `allowBackup`, Network Security Config, minimalny manifest – T9-T11.
6. SEC-06 Walidator i oczyszczanie wejścia/wyjścia AI + testy prompt injection – T4, T5.
7. SEC-07 Usuwanie konta i danych po UID + test E2E – T14.
8. SEC-08 Audyt zależności w CI – T16.
9. SEC-09 Alerty budżetowe i wyłącznik kosztowy (DevOps/właściciel) – T3.
10. SEC-10 Weryfikacja lokalizacji przetwarzania i transferów Firebase/Google Cloud/Vertex AI w dokumentacji Google (S2) – faza 2.
11. SEC-11 Wymagania prywatności dla preferencji: lista predefiniowana, walidacja serwerowa, zakaz logowania wartości, objęcie zgodą AI (T4, T22, R16) – dla architekta/dewelopera.
12. SEC-12 Lokalizacja dokładna: wymagania manifestu (bez tła), jednorazowy odczyt bez zapisu i logów, test braku persystencji (T11, T12, R12) – dla dewelopera/QA.
13. SEC-13 Data Safety i uzasadnienie uprawnienia lokalizacji w Google Play; Data Safety spójne z rejestrem (D7, D15) – właściciel + Security, przed testami zamkniętymi.
14. SEC-14 Teksty zgód i polityka prywatności PL/EN; zapis języka w wersji zgody (T15, T23) – analityk/właściciel, weryfikacja [PRAWNIK].
15. SEC-15 Test bramki S5: zanim realne dane trafią do AI, zapisane potwierdzenie warunków dostawcy (DPA, UE, bez trenowania) w ADR (T13) – architekt/właściciel. **v0.3:** lista kontrolna ADR-0001 (6 pozycji) rozszerzona o poz. 7-12 (podprocesorzy/transfery Vertex, GA i data wycofania modelu, konfiguracja logów i thinking/grounding, kryterium zamknięcia z linkami/datą/osobą, test akceptacyjny `test_data_only`, aktualizacja zgody/polityki/Data Safety) – szczegóły w `przeglad-adr.md` pkt 1.

Uzupełnienia v0.3 do istniejących zadań (wejścia z przeglądu ADR):
- SEC-03: sprawdzanie istnienia użytkownika przy zapisach (T24); reguła „`ENFORCE_APP_CHECK=false` tylko gdy dev lub `ALLOW_REAL_DATA=false`" (T27).
- SEC-04: globalny handler wyjątków bez treści, test z ciągiem kontrolnym, sink i wykluczenie `_Default`, Error Reporting (T25).
- SEC-07: test E2E ze starym tokenem po usunięciu (T24); usunięcie osieroconego pliku po utracie klucza; opcjonalnie klucz per konto.
- SEC-09: alert na wyczerpanie limitu globalnego (T26).
- SEC-10: dodać Error Reporting, App Check/Play Integrity, Secret Manager, Vertex (model docelowy) (T29).
- SEC-14: wersja zgody powiązana z treścią (test CI); sformułowanie akceptacji polityki (T30).
- Nowe SEC-16: procedura przełączenia `ALLOW_REAL_DATA` i zmian `config/runtime`, dostęp do konsoli, tokeny debug App Check (T27) – właściciel/Security/architekt.
- Nowe SEC-17: ograniczenie ról kont usług i WIF (T28) – devops/Steward przy P3-03.

## 5. Eskalacja i ryzyka rezydualne
- **Blokada do decyzji człowieka:** brak potwierdzonych warunków przetwarzania przez dostawcę AI (S5: wariant korporacyjny UE, DPA, bez trenowania – ustalone jako warunek, jeszcze niepotwierdzone w ADR) oraz brak opublikowanej polityki prywatności z danymi administratora (S1: nazwa, adres, NIP – uzupełnia właściciel) blokują testy z osobami spoza zespołu i wysyłanie realnych danych do AI.
- **v0.3:** na G2 Security nie zgłasza uwag blokujących; ADR są akceptowalne po wpisaniu uwag Z do backlogu. Rezydualne wysokie: T13 (SEC-15) i T29 (SEC-10) – blokują realne dane i testy zewnętrzne, nie G2. Decyzje człowieka: Q1 (A/C), Q2 (App Check a testy), Q9 [PRAWNIK].
- Rezydualne: błędny plan AI (R5) – akceptowane z ostrzeżeniem; telefon bez blokady ekranu lub zrootowany.
