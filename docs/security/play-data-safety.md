# Google Play – odpowiedzi do formularza „Bezpieczeństwo danych” (Data Safety)

- Wersja 0.1, 2026-11-26 · Autor (rola): security · Zadanie: TAM-131 (REL-SEC-2)
- Dla: właściciela (przepisuje odpowiedzi w Play Console krok po kroku)
- Podstawa: rejestr danych `personal-data-register.md` v0.9 (D7 wycofany, D8 wg ADR-0017), ADR-0017 (bez
  lokalizacji), ADR-0001 (Vertex AI, B-2), ADR-0011/0012 (zgody), plan wydania
  `docs/architecture/plan-wydania-testy-wewnetrzne.md` (sekcja 7.3, decyzje O-TAM116-1…8),
  `privacy-checklist.md` pkt 8, stan kodu `main` 3005847 (`pubspec.yaml`, `AndroidManifest.xml`,
  `backend/functions/src/endpoints.ts`).
- To nie jest porada prawna. Miejsca oznaczone **[PYTANIE O-TAM131-n]** czekają na decyzję właściciela
  (część z udziałem prawnika) – lista w `docs/open-questions.md`, sekcja „Data Safety (TAM-131)”.

## 1. W skrócie

**Co.** Gotowe odpowiedzi do sekcji Play Console **Zawartość aplikacji → Bezpieczeństwo danych** (ang. *App content
→ Data safety*), w kolejności ekranów formularza.

**Najważniejsze odpowiedzi:**
- Tamitu **zbiera** dane (wysyła je poza telefon): e-mail, nazwę i identyfikator konta (logowanie Google), dane
  podróży wpisane do formularza i wysłane do AI, licznik użycia i zapis zgód, identyfikatory techniczne (App Check).
- Tamitu **niczego nie udostępnia** stronom trzecim w rozumieniu Google: Firebase i Vertex AI działają w naszym
  imieniu (dostawcy usług), a link do Google Maps otwiera sam użytkownik.
- **Lokalizacji nie deklarujemy** – ani przybliżonej, ani dokładnej (ADR-0017).
- Wszystko jest **szyfrowane w przesyle** (HTTPS). Reklam i Advertising ID brak.
- **Usuwanie konta w aplikacji jeszcze nie działa** (`deleteAccount` zwraca `not_implemented`). Na czas testów
  wewnętrznych usuwamy dane **ręcznie na prośbę e-mailem** – sekcja 5.

**Kiedy wypełniać.** Do testów wewnętrznych formularz **nie jest wymagany** (plan, sekcja 7.3). Można go wypełnić
już teraz i zapisać, ale **nie wolno wpisywać nic, co nie jest prawdą w dniu wysłania**. Przed testami zamkniętymi
trzeba zmienić odpowiedzi według sekcji 6.

## 2. Jak Google rozumie pojęcia (żeby odpowiedzi były spójne)

| Pojęcie | Znaczenie wg zasad Google Play | Co to znaczy dla Tamitu |
|---|---|---|
| **Zbieranie** (*collected*) | dane wysłane z telefonu poza urządzenie (do nas lub do naszych dostawców) | plany, preferencje i tryb dojazdu, które **zostają tylko w telefonie**, nie są „zbierane”; to, co idzie do Firebase i do AI – jest |
| **Udostępnianie** (*shared*) | przekazanie danych stronie trzeciej | **wyjątki** (nie trzeba deklarować): dostawca usług przetwarzający w naszym imieniu (Firebase, Vertex AI), przekazanie na wyraźne działanie użytkownika, którego się spodziewa (otwarcie linku w Mapach), wymogi prawa |
| **Przetwarzane tymczasowo** (*processed ephemerally*) | tylko w pamięci, nie dłużej niż potrzeba do obsłużenia żądania | dla danych do AI odpowiadamy **„nie”** do czasu decyzji B-2 (sekcja 4.3) |
| **Wymagane / opcjonalne** | czy użytkownik może nie podać danych i dalej korzystać z funkcji | sekcja 4 przy każdej kategorii |

## 3. Ekran 1: „Gromadzenie danych i bezpieczeństwo” (*Data collection and security*)

| # | Pytanie w konsoli (sens; dokładne brzmienie może się różnić) | Odpowiedź | Uzasadnienie |
|---|---|---|---|
| 1.1 | Czy aplikacja zbiera lub udostępnia którykolwiek z wymaganych typów danych użytkownika? (*Does your app collect or share any of the required user data types?*) | **Tak** | e-mail, identyfikatory, dane do AI (sekcja 4) |
| 1.2 | Czy wszystkie dane użytkownika zbierane przez aplikację są szyfrowane podczas przesyłania? (*Is all of the user data collected by your app encrypted in transit?*) | **Tak** | Firebase Auth, Cloud Functions (`recordConsent`, `generatePlan`) i Google Sign-In łączą się tylko po HTTPS/TLS; w manifeście `usesCleartextTraffic="false"`; link Maps to `https://` |
| 1.3 | Jakie metody tworzenia konta obsługuje aplikacja? (*Which methods of account creation does your app support?*) | **OAuth** (logowanie przez Google). Nie zaznaczać: nazwa użytkownika i hasło, inne uwierzytelnianie, „aplikacja nie pozwala tworzyć kont” | ADR-0004: tylko Google przez Firebase Auth; brak haseł |
| 1.4 | Link, pod którym użytkownik może poprosić o usunięcie konta i powiązanych danych (*Delete account URL*) | **Teraz: brak gotowej strony** – patrz sekcja 5. Przed testami zamkniętymi: adres strony WWW z instrukcją usuwania, np. `https://tadecode.pl/tamitu/usuwanie-konta` (adres ustala właściciel) | strona jeszcze nie istnieje (O-TAM116-2, OWN-9); pole jest wymagane, gdy aplikacja ma konta **[PYTANIE O-TAM131-5]** |
| 1.5 | Czy użytkownik może poprosić o usunięcie części lub wszystkich danych **bez usuwania konta**? (*optional*) | **Tak** – e-mailem na `tamitu@tadecode.pl`; plany usuwa sam w aplikacji (US-009), ale one nie są „zbierane” | prawo do usunięcia danych (RODO art. 17), kontakt S8. Można też zostawić „nie” – pytanie dodatkowe; „tak” jest prawdą tylko, jeśli właściciel obsługuje takie prośby ręcznie (sekcja 5) |
| 1.6 | Niezależna weryfikacja bezpieczeństwa (*independent security review*, MASA) | **Nie** (pominąć) | brak audytu zewnętrznego |
| 1.7 | Zgodność z zasadami Rodziny (*Families*) | **nie dotyczy** | grupa docelowa 18+ (N8) |

## 4. Ekran 2: „Typy danych” i ekran 3: „Wykorzystanie i obsługa danych”

### 4.1 Lista kontrolna typów danych – co zaznaczyć

Zaznacz **tylko** pozycje z „TAK”. Każda zaznaczona pozycja ma potem własny zestaw pytań (sekcja 4.2).

| Kategoria w konsoli | Typ danych | Zaznaczyć? | Skąd w Tamitu (rejestr) |
|---|---|---|---|
| **Lokalizacja** (*Location*) | Przybliżona, Dokładna | **NIE** | ADR-0017: brak uprawnień lokalizacji, D7 wycofany; IP w logach nie służy do ustalania położenia |
| **Dane osobowe** (*Personal info*) | Imię i nazwisko (*Name*) | **TAK** | D1 – Firebase Auth zapisuje nazwę z profilu Google **[PYTANIE O-TAM131-4]** |
| | Adres e-mail (*Email address*) | **TAK** | D1 – Firebase Auth |
| | Identyfikatory użytkownika (*User IDs*) | **TAK** | D1, D3, D10, D11 – Firebase UID |
| | Adres, Telefon, Rasa i pochodzenie, Poglądy polityczne lub religijne, Orientacja seksualna | NIE | nie zbieramy; zainteresowania z listy predefiniowanej bez pozycji art. 9 (D15) |
| | Inne informacje (*Other info*) | NIE | dane podróży – w „Inne treści użytkownika” (niżej) **[PYTANIE O-TAM131-3]** |
| **Informacje finansowe** (*Financial info*) | wszystkie | NIE | brak płatności; budżet to poziom 1–3, nie dane finansowe (D15) **[PYTANIE O-TAM131-3]** |
| **Zdrowie i fitness** | wszystkie | NIE | – |
| **Wiadomości** | wszystkie | NIE | – |
| **Zdjęcia i filmy**, **Pliki audio**, **Pliki i dokumenty** | wszystkie | NIE | zdjęcia to F3 [PRZYSZŁE] |
| **Kalendarz**, **Kontakty** | wszystkie | NIE | – |
| **Aktywność w aplikacji** (*App activity*) | Interakcje z aplikacją (*App interactions*) | **TAK** | D10 – licznik generowań planu na konto na dobę |
| | Historia wyszukiwania w aplikacji | NIE | – |
| | Zainstalowane aplikacje | NIE | `<queries>` tylko dla `VIEW https`, bez listy aplikacji |
| | Inne treści wygenerowane przez użytkownika (*Other user-generated content*) | **TAK** | D6 (z D4, D5, D15, D16) – formularz podróży wysyłany do AI |
| | Inne działania (*Other actions*) | **TAK** | D3 – zapis zgód (polityka, AI) na serwerze **[PYTANIE O-TAM131-3]** |
| **Przeglądanie internetu** | Historia przeglądania | NIE | – |
| **Informacje o aplikacji i wydajności** (*App info and performance*) | Logi awarii, Diagnostyka, Inne | NIE | D12: Crashlytics/Analytics nieużywane (brak pakietów w `pubspec.yaml`). Logi serwera (D11) opisane przy identyfikatorach |
| **Identyfikatory urządzenia lub inne** (*Device or other IDs*) | Identyfikatory urządzenia lub inne | **TAK** | D17 – token App Check i atestacja Play Integrity; adres IP w logach platformy (D11) **[PYTANIE O-TAM131-2]** |

### 4.2 Odpowiedzi dla każdego zaznaczonego typu

Dla każdego typu konsola pyta: (a) zbierane / udostępniane, (b) czy przetwarzane tymczasowo, (c) wymagane czy
opcjonalne, (d) cele zbierania (i osobno cele udostępniania – u nas brak). Szyfrowanie w przesyle i usuwanie są
ustawione raz na ekranie 1 (sekcja 3) i dotyczą wszystkich typów; dla porządku powtarzam je w tabeli.

| Typ danych | Zbierane | Udostępniane | Tymczasowo | Wymagane / opcjonalne | Cele (zaznaczyć) | Szyfrowane w przesyle | Usunięcie na prośbę |
|---|---|---|---|---|---|---|---|
| **Imię i nazwisko** | Tak | **Nie** | Nie | Wymagane | Zarządzanie kontem (*Account management*) | Tak | Tak (sekcja 5) |
| **Adres e-mail** | Tak | **Nie** | Nie | Wymagane | Zarządzanie kontem | Tak | Tak |
| **Identyfikatory użytkownika** | Tak | **Nie** | Nie | Wymagane | Zarządzanie kontem; Funkcje aplikacji (*App functionality*); Zapobieganie oszustwom, bezpieczeństwo i zgodność z przepisami (*Fraud prevention, security, and compliance*) | Tak | Tak |
| **Interakcje z aplikacją** (licznik) | Tak | **Nie** | Nie | Wymagane | Funkcje aplikacji; Zapobieganie oszustwom, bezpieczeństwo i zgodność | Tak | Tak (i samo znika do ok. 4 dni, TTL – gdy wdrożony, O4-2) |
| **Inne treści użytkownika** (dane podróży do AI) | Tak | **Nie** | **Nie** (sekcja 4.3) | **Wymagane** (sekcja 4.3) | Funkcje aplikacji | Tak | Tak (u nas nic nie zostaje; sekcja 5) |
| **Inne działania** (zgody) | Tak | **Nie** | Nie | Wymagane | Funkcje aplikacji; Zapobieganie oszustwom, bezpieczeństwo i zgodność | Tak | Tak (**[PRAWNIK]** Q9: czy dowód zgody zostaje po usunięciu konta) |
| **Identyfikatory urządzenia lub inne** | Tak | **Nie** | Nie | Wymagane | Zapobieganie oszustwom, bezpieczeństwo i zgodność | Tak | częściowo: logi z IP wygasają po 30 dniach, dane App Check/Play Integrity przetwarza Google |

Nie zaznaczać celów: Analityka, Komunikacja dewelopera, Reklamy lub marketing, Personalizacja.

### 4.3 Wyjaśnienia do trudniejszych odpowiedzi

**Dane podróży do AI („Inne treści użytkownika”).** Do Vertex AI idą: cel, daty lub liczba dni, nocleg, godzina
i miejsce przylotu/przyjazdu, preferencje (zainteresowania, budżet jako poziom, tempo, liczba osób), język planu
(D6). Nie idą: UID, e-mail, nazwa, numer lotu, lokalizacja. Nasz serwer trzyma je tylko w pamięci i nie zapisuje
w logach; buforowanie Gemini jest wyłączone (B-1, `disableCache=true` w prod).
- **Tymczasowo – „Nie”.** Monitoring nadużyć Google może przechować prompt do 90 dni, jeśli klasyfikator go oznaczy
  (B-2, bez decyzji właściciela). Dopóki to nie jest rozstrzygnięte, „przetwarzane tymczasowo” byłoby za mocnym
  stwierdzeniem. Odpowiedź „Nie” niczego nie zawyża – mówi tylko, że nie obiecujemy przetwarzania wyłącznie w
  pamięci **[PYTANIE O-TAM131-1]**.
- **Wymagane – „Tak”.** Zgoda na AI jest osobna i dobrowolna (N5), ale bez niej nie da się wygenerować planu –
  głównej funkcji aplikacji. Google uznaje dane za opcjonalne, gdy użytkownik może je pominąć i dalej korzystać
  z funkcji; tu nie może. „Wymagane” nie jest mylące; „opcjonalne” mogłoby być.
- **Udostępniane – „Nie”.** Vertex AI to usługa Google Cloud przetwarzająca dane na nasze zlecenie (warunki
  przetwarzania danych Google Cloud, bez trenowania). To wyjątek „dostawca usług”. Wątpliwość: monitoring nadużyć
  (B-2) to przetwarzanie na potrzeby samego Google **[PYTANIE O-TAM131-1]**.

**Link do Google Maps (D8).** Nie deklarujemy jako udostępniania. Link (cel, tryb dojazdu, opcjonalnie nocleg lub
poprzedni punkt jako tekst) otwiera **użytkownik**, dotykając przycisku trasy, i spodziewa się, że trafi do Map.
To wyjątek „działanie zainicjowane przez użytkownika”. Treść linku opisujemy w polityce prywatności (`privacy-checklist.md`
pkt 10) **[PYTANIE O-TAM131-1]**.

**Lokalizacja – „Nie”.** Tamitu nie ma uprawnień lokalizacji, nie ma pakietu lokalizacji i nie wysyła
współrzędnych (ADR-0017, test manifestu). O pozycję pyta aplikacja Google Maps na własnych zasadach. Adres IP
w logach platformy Cloud Run nie jest używany do ustalania położenia – wg zasad Google dopiero wtedy byłaby to
„lokalizacja przybliżona”.

**Identyfikatory urządzenia (App Check, Play Integrity, IP).** Przy każdym wywołaniu funkcji aplikacja wysyła token
App Check, a Google sprawdza integralność aplikacji i urządzenia (D17). Logi żądań Cloud Run zawierają adres IP
i user agent (D11). Deklarujemy ostrożnie jako „Identyfikatory urządzenia lub inne”, cel: bezpieczeństwo. Do
sprawdzenia: wytyczne Firebase dla Data Safety (strona Firebase „Data disclosure for Google Play”) i zmergowane
zależności – czy SDK dokłada np. Firebase Installations ID **[PYTANIE O-TAM131-2]**.

**Imię i nazwisko.** Tamitu nie używa nazwy konta, ale Firebase Auth zapisuje ją z profilu Google na serwerze
(rejestr D1). Skoro dane są przechowywane po naszej stronie, deklarujemy ostrożnie **[PYTANIE O-TAM131-4]**.

**Czego nie deklarujemy, bo zostaje w telefonie:** plany i dane podróży w bazie lokalnej (D4, D5, D9, D15; numer
lotu nigdy nie wychodzi z telefonu), język interfejsu (D16), zapamiętany tryb dojazdu (ADR-0017 Aneks 1), lokalna
kopia zgód. Szyfrowanie bazy w telefonie (SQLCipher) nie jest pytaniem formularza – można o nim wspomnieć
w polityce prywatności.

**Czego nie deklaruje aplikacja, bo to dane Google Play:** lista testerów i statystyki instalacji (D13) – zbiera je
Google Play, nie Tamitu.

## 5. Usuwanie danych – jak uczciwie zadeklarować teraz

**Stan faktyczny (2026-11-26):** w aplikacji nie ma przycisku „Usuń konto”; funkcja serwera `deleteAccount`
zwraca `not_implemented` (P3-08) i nie jest wdrożona w prod (O-TAM116-5). Strona WWW z instrukcją i polityka
prywatności nie są opublikowane (O-TAM116-2). Jedynym testerem jest właściciel.

**Co da się dziś usunąć ręcznie (właściciel w konsoli prod, na prośbę e-mailem):**

| Dane | Gdzie | Jak |
|---|---|---|
| Konto (UID, e-mail, nazwa) – D1 | Firebase Authentication | konsola Firebase → Authentication → usuń użytkownika |
| Zgody – D3 | Firestore `users/{uid}/consents` | konsola Firestore → usuń dokumenty (decyzja Q9 [PRAWNIK] jeszcze nie zapadła – do tego czasu usuwamy) |
| Licznik – D10 | Firestore `usage/{uid}` | usuń dokument (TTL w prod jeszcze niewdrożony, O4-2) |
| Logi ze skrótem UID i IP – D11 | kubełek `tamitu-logs` | nie usuwamy ręcznie; wygasają po 30 dniach |
| Prompt przechowany przez monitoring nadużyć – B-2 | Google (Vertex AI) | poza naszym wpływem; do 90 dni, tylko gdy oznaczony |
| Plany i dane lokalne | telefon | użytkownik: odinstalowanie aplikacji albo „Wyczyść dane” w Ustawieniach Androida |

**Rekomendacja na czas testów wewnętrznych (jeden tester = właściciel):**
1. **Nie wysyłać jeszcze formularza Data Safety** – nie jest wymagany na tej ścieżce (plan, sekcja 7.3). Można
   go wypełnić według sekcji 3–4 i zapisać, a pole „Delete account URL” uzupełnić dopiero, gdy będzie prawdziwa
   strona.
2. Jeśli konsola zażąda formularza wcześniej: pod adresem z pola 1.4 musi być **działająca** strona, która mówi
   prawdę: „Usunięcie konta w aplikacji będzie dostępne wkrótce. Do tego czasu napisz na tamitu@tadecode.pl z
   adresu konta Google – usuniemy konto i dane w ciągu 30 dni [termin – właściciel]; logi techniczne wygasają po
   30 dniach.” Bez takiej strony nie podawać adresu „na zapas”. **Nie pisać**, że usuwanie działa w aplikacji.
3. Odpowiedź 1.5 („usunięcie części danych bez usuwania konta”) zaznaczać „tak” tylko wtedy, gdy właściciel
   rzeczywiście obsłuży taką prośbę ręcznie według tabeli wyżej.

## 6. Co zmienić przed testami zamkniętymi (lub dodaniem drugiego testera)

| # | Zmiana | Skąd | Wpływ na formularz |
|---|---|---|---|
| Z1 | `deleteAccount` działa i jest wdrożony (P3-08, po W-2); w aplikacji jest „Usuń konto” | bramka 2a pkt 3 | pole 1.4 opisuje usuwanie w aplikacji i na stronie; tabela w sekcji 5 – automatycznie |
| Z2 | Strona WWW z instrukcją usuwania (nazwa aplikacji i dewelopera, kroki, co usuwamy, co i jak długo zostaje: logi 30 dni, ew. dowód zgody wg Q9, prompty wg B-2) | plan 2a, `privacy-checklist.md` pkt 5 | adres do pola 1.4 |
| Z3 | Polityka prywatności PL/EN opublikowana i zgodna z tym dokumentem | OWN-9, bramka 2a pkt 1 | adres polityki w karcie aplikacji |
| Z4 | Decyzja B-2 (monitoring nadużyć) | bramka 2a pkt 4 | ewentualna zmiana „Tymczasowo” i „Udostępniane” dla danych do AI (O-TAM131-1) |
| Z5 | Odpowiedzi na O-TAM131-1…5 | `docs/open-questions.md` | poprawki w sekcji 4 |
| Z6 | Kontrola zmergowanego manifestu i zależności (tylko `INTERNET`, bez `AD_ID`, bez lokalizacji, brak Crashlytics/Analytics) przed każdym AAB | T11, ADR-0017 | potwierdza „NIE” dla lokalizacji, awarii i reklam |

**Formularz trzeba poprawić od razu**, gdy dojdzie: Crashlytics lub Analytics (D12), reklamy/AdMob (F1), plany
w chmurze (F4), lokalizacja (F5, nowy ADR), inne logowania (F6), zdjęcia (F3) albo nowa kategoria danych
w rejestrze. Za aktualność odpowiada security razem z właścicielem (SEC-13).

## 7. Inne deklaracje w „Zawartości aplikacji” powiązane z danymi

- **Identyfikator wyświetlania reklam (Advertising ID):** „Nie” – uprawnienie `AD_ID` jest usuwane z manifestu
  (`tools:node="remove"`), reklam brak.
- **Reklamy:** „Aplikacja nie zawiera reklam”.
- **Uprawnienia wrażliwe:** brak – nie ma czego uzasadniać (ADR-0017).
- **Polityka prywatności (URL):** `https://tadecode.pl/tamitu/prywatnosc` – dopiero po publikacji (OWN-9).
