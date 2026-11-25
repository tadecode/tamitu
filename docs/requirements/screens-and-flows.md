# Ekrany, przepływy i stany brzegowe – Tamitu (MVP)

Stan: 2026-11-16, wersja 0.1, zadanie P3-14a (przegląd wymagań pod kątem ekranów – wejście do mockupu UI). Autor: analityk.
Źródła: `docs/vision.md`, `docs/requirements/US-001..011`, `scope.md`, `risks.md`, `docs/open-questions.md` (N1–N11, Q1–Q12, S1–S12), `docs/security/privacy-checklist.md`, `docs/data/model-danych.md`, `docs/api/posrednik-api.md` (tylko jako ograniczenia), `docs/architecture/flows.md`.
Dokument **nie opisuje wyglądu** (kolory, układ, komponenty) ani rozwiązań technicznych. Opisuje: jakie widoki są potrzebne, po co, jakie ścieżki przechodzi użytkownik i jakie stany musi obsłużyć każdy widok. Wygląd to zadanie projektanta mockupu (P3-14b..d wg zlecenia orkiestratora; w `docs/backlog.md` wpisów P3-14a..d jeszcze nie ma – zgłaszam orkiestratorowi).

Oznaczenia: US-xxx – historyjka; U1–U13 – nowe pytania w pkt 5 (i w `docs/open-questions.md`); [PRAWNIK], [WŁAŚCICIEL] – jak w pozostałych dokumentach.

---

## 1. Lista ekranów i widoków MVP

Ekran systemowy (wybór konta Google, okno uprawnień Androida, aplikacja Google Maps/przeglądarka) nie jest naszym ekranem; wymieniony w przepływach jako „system".

| ID | Ekran / widok | Cel | US |
|---|---|---|---|
| EK-01 | Start aplikacji (bramka sesji) | Ustalić, dokąd skierować użytkownika: ekran startowy, zgody do ponownej akceptacji, lista planów; dokończyć przerwane usuwanie konta | US-001, US-002, US-003, US-010 |
| EK-02 | Ekran startowy: prywatność i logowanie | Poinformować o prywatności i o przekazywaniu danych do AI, dać link do polityki, zebrać akceptację polityki, uruchomić logowanie Google; wybór języka interfejsu | US-001, US-003 |
| EK-03 | Ponowna akceptacja polityki/zgód | Poprosić o ponowną akceptację po zmianie wersji polityki lub nowym celu przetwarzania | US-003 |
| EK-04 | Lista planów (ekran główny) | Pokazać zapisane plany konta (cel, liczba dni, data utworzenia, od najnowszego); punkt wejścia do „Nowa podróż" i do Ustawień; stan pusty | US-008 |
| EK-05 | Formularz podróży | Zebrać cel, bazę noclegową, liczbę dni, sposób przyjazdu (lot/auto), datę i godzinę przylotu/przyjazdu, lotnisko, opcjonalny numer lotu, język planu, preferencje (zainteresowania, budżet, tempo, liczba osób); walidacja | US-004, US-006 |
| EK-06 | Zgoda na AI | Przy pierwszym generowaniu uzyskać osobną zgodę na przekazanie danych do AI (z treścią wg privacy-checklist pkt 2) | US-003, US-005 |
| EK-07 | Generowanie planu | Pokazać postęp, pozwolić anulować, obsłużyć wynik (sukces → EK-08; błąd/limit → komunikat, powrót do EK-05 z zachowanymi danymi) | US-005, US-011 |
| EK-08 | Widok planu | Pokazać dane podróży (cel, nocleg, godzina przylotu/przyjazdu), plan dzień po dniu z punktami w kolejności pór, informację „plan stworzony przez AI, możliwe błędy; sprawdź godziny otwarcia", wejście do trasy i do usunięcia planu; dostępny offline | US-005, US-006, US-008, US-009 |
| EK-09 | Wybór trasy do punktu | Wybrać punkt startowy (moja lokalizacja – domyślnie / poprzedni punkt dnia / nocleg) i tryb (auto / komunikacja / pieszo, zapamiętany), potwierdzić otwarcie Google Maps | US-007 |
| ~~EK-10~~ | ~~Wyjaśnienie i prośba o lokalizację~~ | **Wycofany (TAM-110):** Q1 = C (ADR-0017) – Tamitu nie prosi o lokalizację; specyfikacja w archiwum UX (TAM-108) | – |
| EK-11 | Potwierdzenie usunięcia planu | Zapobiec przypadkowemu usunięciu; potwierdzić lub anulować | US-009 |
| EK-12 | Ustawienia | Zebrać: język interfejsu, Prywatność, link do polityki, Wyloguj, Usuń konto | US-002, US-003, US-010 |
| EK-13 | Ustawienia → Prywatność | Pokazać stan zgód (polityka, AI) i daty ich wyrażenia; wycofać lub ponownie wyrazić zgodę na AI; link do polityki | US-003 |
| EK-14 | Potwierdzenie wylogowania | Poinformować, że plany zostają na urządzeniu, i dać wybór Wyloguj/Anuluj | US-002 |
| EK-15 | Usunięcie konta | Ostrzeżenie o nieodwracalności i o zakresie usuwanych danych; potwierdzenie; ponowne uwierzytelnienie, gdy wymagane; postęp; wynik | US-010 |
| EK-16 | Katalog komunikatów (komponent wspólny) | Jednolite komunikaty w PL/EN dla limitu, błędów sieci i usług, braku zgody, wymaganej aktualizacji; bez szczegółów technicznych | US-011 |

Poza MVP (nie projektować): osadzona mapa, edycja planu, regeneracja dnia, udostępnianie, tryb gościa, rejestracja/hasło, podpowiedzi „w pobliżu", zakup subskrypcji, reklamy, eksport danych, zdjęcia (zabytek/menu), inne logowania niż Google, inne języki niż PL/EN.

---

## 2. Przepływy użytkownika

Notacja: EK-xx – ekran; „system" – element Androida/Google. „Brak" i „błąd" opisano w pkt 3.

### P1. Pierwsze uruchomienie: polityka, logowanie, brak zgody na AI na tym etapie (US-001, US-003)
1. EK-01 (brak sesji) → EK-02.
2. EK-02: informacja o prywatności i o AI, link do polityki w języku interfejsu, **checkbox akceptacji polityki niezaznaczony**; przycisk „Zaloguj przez Google" nieaktywny, dopóki polityka nie jest zaakceptowana (US-001/US-003).
3. Użytkownik zaznacza akceptację → „Zaloguj przez Google" → system (wybór konta).
4. Sukces → zapis zgody na politykę (rekord lokalny, potem serwerowy) → EK-04 (stan pusty przy pierwszym logowaniu).
5. Anulowanie u dostawcy → powrót do EK-02 z krótkim komunikatem bez błędu technicznego (US-001).
6. Brak sieci → komunikat i możliwość ponowienia (US-001).
7. Użytkownik niepełnoletni: aplikacja tylko dla dorosłych (N8) – informacja w EK-02 (do potwierdzenia treści [PRAWNIK], U2).
Uwaga: zgoda na AI **nie** jest pytana w tym przepływie (decyzja kolejności wg privacy-checklist pkt 2: przy pierwszym generowaniu i w Ustawieniach); EK-02 zawiera jedynie informację o przekazywaniu danych do AI (US-003, AC 1).

### P2. Powrót zalogowanego użytkownika (US-001, US-003)
1. EK-01 → sesja ważna → EK-04 (bez ekranu logowania; działa offline).
2. Zmiana wersji polityki/zgód od ostatniej akceptacji → EK-03 przed EK-04.
3. Wykryty znacznik przerwanego usuwania konta → dokończenie czyszczenia lokalnego i komunikat o wyniku (US-010), potem EK-02.

### P3. Tworzenie planu (US-004, US-005, US-006, US-011)
1. EK-04 → „Nowa podróż" → EK-05.
2. Wypełnienie pól wymaganych: cel, baza noclegowa („Nazwa obiektu lub dzielnica" – bez pełnego adresu prywatnego), liczba dni 1–14, lot/auto, data i godzina przylotu/przyjazdu; przy locie także lotnisko (numer lotu opcjonalny). Preferencje opcjonalne z wartościami domyślnymi (zainteresowania: 0 z 11, max 5; budżet: średni; tempo: umiarkowane; liczba osób: 2; język planu: język interfejsu).
3. „Generuj" → walidacja; błędy przy polach, bez przejścia dalej.
4. Brak zgody na AI → EK-06 (zgoda wyrażona → krok 5; odmowa → powrót do EK-05, dane zachowane, nic wysłane, limit niezużyty).
5. EK-07: postęp + „Anuluj".
6a. Sukces → plan zapisany automatycznie (lista planów zostaje zaktualizowana) → EK-08 z informacją o AI.
6b. Błąd/model niedostępny/niepoprawna odpowiedź → EK-16 (komunikat), powrót do EK-05 z danymi, limit zwrócony, możliwość ponowienia z decyzji użytkownika (bez automatycznych ponowień).
6c. Limit wyczerpany → EK-16 (godzina odnowienia), powrót do EK-05 z danymi; lista planów i podgląd nadal dostępne.
6d. Anulowanie → patrz P4.

### P4. Anulowanie generowania (US-005, US-011, Q12)
1. W EK-07 „Anuluj" (lub „wstecz" systemu – potwierdzenie) → komunikat: nic nie zostanie zapisane; wykorzystanie limitu dziennego może nie zostać zwrócone, jeśli generowanie już się rozpoczęło.
2. Potwierdzenie → powrót do EK-05 z zachowanymi danymi; nic nie zapisano lokalnie; użytkownik może wysłać ponownie (zużywa kolejny slot).
3. Rezygnacja z anulowania → powrót do EK-07.

### P5. Lista, podgląd i usuwanie planów (US-008, US-009)
1. EK-04 (lista; offline działa) → wybór planu → EK-08 (przełączanie dni; punkty w kolejności pór; pierwszy dzień z godziną przylotu/przyjazdu).
2. EK-08 → „Usuń plan" → EK-11 → potwierdź: plan znika z listy, dane trwale usunięte, powrót do EK-04 (stan pusty, jeśli to ostatni plan); anuluj: bez zmian.
3. Dwa konta na urządzeniu: każde widzi tylko własne plany (US-008); komunikat o tym w wylogowaniu (P8).

### P6. Link do map i lokalizacja (US-007)
1. EK-08 → dotknięcie punktu → EK-09 (domyślny start: „Moja lokalizacja"; „Poprzedni punkt dnia" ukryty przy pierwszym punkcie dnia, „Nocleg" ukryty bez noclegu; tryb zapamiętany). **[ZMIANA TAM-110]**
2. Start z planu → „Otwórz w Google Maps" → system (aplikacja Maps lub przeglądarka). Wymaga internetu.
3. Start „Moja lokalizacja" → „Otwórz w Google Maps" → link **bez `origin`**; bieżącą pozycję ustala Google Maps i to Mapy (nie Tamitu) ewentualnie proszą o zgodę na lokalizację. Tamitu nie ma uprawnień lokalizacji, nie pokazuje prośby ani ekranu wyjaśnienia (EK-10 wycofany). **[ZMIANA TAM-110: Q1 = C, ADR-0017]**
4. Cel w linku zawsze jako nazwa punktu i miejscowość (z celem podróży), nigdy same współrzędne (test TAM-24). **[ZMIANA TAM-110]**
5. [Q1 – rozstrzygnięte 2026-11-25: wariant C] EK-10 wypada; w EK-09 przy „Moja lokalizacja" krótka informacja, że o dostęp do lokalizacji może poprosić Google Maps (EK-09 v0.4). System nie otworzył linku → komunikat, arkusz zostaje, można ponowić.

### P7. Ustawienia, język, prywatność (US-003)
1. EK-04 → EK-12. Język interfejsu: zmiana natychmiast przełącza interfejs; zapisane plany zachowują język oryginalny (US-005).
2. EK-12 → EK-13: stan zgód i daty; link do polityki. Wycofanie zgody na AI: zapis na serwerze przed pokazaniem stanu „wycofano"; bez sieci – komunikat, zgoda pozostaje; po wycofaniu generowanie zablokowane z wyjaśnieniem i opcją ponownego wyrażenia zgody (EK-06 lub przycisk w EK-13).
3. Link do polityki: otwiera przeglądarkę w wersji językowej zgodnej z językiem interfejsu.

### P8. Wylogowanie (US-002)
1. EK-12 → „Wyloguj" → EK-14: plany zostają na urządzeniu i wrócą po zalogowaniu tym samym kontem; inne konto ich nie zobaczy; usunąć je można usuwając plany (US-009) lub konto (US-010) – treść do decyzji U7.
2. „Wyloguj" → EK-02 (bez planów poprzedniego konta w widoku); „Anuluj" → EK-12.
3. Wylogowanie niedostępne w czasie generowania (U8).

### P9. Usunięcie konta (US-010)
1. EK-12 → „Usuń konto" → EK-15 (ostrzeżenie o nieodwracalności, zakres: konto, plany i dane podróży na urządzeniu, zapisy zgód na serwerze w tym dowód zgód (Q9); logi techniczne ze skrótem UID wygasają w 30 dni; konto Google i dane w Google Maps/Play poza Tamitu).
2. Potwierdzenie → ewentualne ponowne uwierzytelnienie Google (system) → postęp → sukces → EK-02 (jako nowy użytkownik przy ponownym logowaniu).
3. Brak sieci → komunikat, nic nie usunięto częściowo bez jasnej informacji. Przerwanie aplikacji → P2 pkt 3.
4. Anulowanie ponownego uwierzytelnienia → powrót do EK-15 / EK-12, dane nietknięte.

### P10. Limity i błędy (US-011)
1. Limit 5 planów na konto na dobę kalendarzową Europe/Warsaw (Q5); po wyczerpaniu P3 pkt 6c. Komunikat podaje godzinę odnowienia w czasie lokalnym.
2. Błędy usługi/sieci → EK-16, bez szczegółów technicznych; formularz zachowany.
3. Przekroczony globalny limit lub wyłączona usługa AI (wyłącznik kosztowy) → komunikat „usługa chwilowo niedostępna" (jak błąd usługi, bez ujawniania powodu kosztowego).

---

## 3. Stany brzegowe

### 3.1 Zasady wspólne (obowiązują każdy ekran)
- **PL/EN:** wszystkie teksty (etykiety, podpowiedzi, błędy, zgody, daty/godziny/liczby) w języku interfejsu; domyślnie język urządzenia (PL lub EN, inaczej EN), zmiana w Ustawieniach (ADR-0006). Wyjątki: **treść planu** w języku planu zapisanym z planem (może różnić się od interfejsu); informacja o AI w języku interfejsu. Mockup musi pokazać wersję PL i EN najdłuższych komunikatów (zgody, limit, usuwanie konta). Komplet kluczy w obu językach jest wymaganiem testowym (US-011).
- **Brak sieci:** ekrany dostępne offline: EK-04, EK-08 (bez linku do map), EK-11, EK-12, ustawienie języka. Wymagające sieci: logowanie, rejestracja zgód/wycofanie, generowanie, usunięcie konta, otwarcie Google Maps, ponowne uwierzytelnienie, link do polityki. Komunikat o braku sieci jest jednolity (EK-16) i zawsze pozwala spróbować ponownie lub wrócić.
- **Błąd nieoczekiwany:** zrozumiały komunikat, możliwość ponowienia lub powrotu, bez szczegółów technicznych i bez utraty wprowadzonych danych.
- **Limit 5/dobę:** dotyczy tylko akcji generowania; reszta aplikacji działa normalnie.
- **Dostępność (do dowiedzenia w mockupie):** etykiety semantyczne, rozmiary dotykowe, kontrast, skalowanie czcionki systemowej bez ucinania komunikatów (`.farm/review/checklist-quality.md`).

### 3.2 Macierz stanów dla ekranów
n/d = stan nie dotyczy ekranu.

| Ekran | Pusty | Ładowanie | Błąd | Brak sieci | Limit 5/dobę | Anulowanie (Q12) | Odmowa lokalizacji | PL/EN |
|---|---|---|---|---|---|---|---|---|
| EK-01 | n/d | krótki stan oczekiwania na ustalenie sesji; bez migotania ekranu logowania | uszkodzona/niedostępna baza konta (np. utrata klucza): komunikat, opcja wylogowania/usunięcia konta (U12) | start offline z ważną sesją → EK-04 | n/d | n/d | n/d | język z ustawień/urządzenia |
| EK-02 | n/d | po „Zaloguj": wskaźnik oczekiwania, blokada podwójnego dotknięcia | błąd logowania: komunikat; anulowanie u dostawcy: komunikat bez błędu technicznego | komunikat + ponów | n/d | anulowanie logowania u dostawcy = powrót do EK-02 | n/d | przełącznik języka dostępny przed logowaniem (U1); link do polityki w wersji zgodnej z językiem |
| EK-03 | n/d | zapis akceptacji | błąd zapisu: komunikat + ponów | wymaga sieci do rejestracji? – jeśli brak: nie wpuszczać dalej (U2) | n/d | brak akceptacji = brak dostępu do planów? (U2): propozycja – można tylko wylogować lub usunąć konto | n/d | jak EK-02 |
| EK-04 | brak planów: komunikat + przycisk „Nowa podróż"; informacja, że plany są tylko na tym urządzeniu (U9) | krótkie wczytanie listy | błąd odczytu bazy lokalnej: komunikat + ponów | działa normalnie | „Nowa podróż" pozostaje dostępna (limit sprawdzany przy generowaniu, nie przy wejściu do formularza) | n/d | n/d | daty tworzenia i liczby wg lokalizacji; cele planów w języku zapisanym |
| EK-05 | pola puste; preferencje z wartościami domyślnymi | n/d (formularz lokalny) | błędy walidacji przy polach: braki (cel, nocleg, dni, dojazd, data/godzina, lotnisko przy locie), dni poza 1–14, liczba osób poza 1–10, więcej niż 5 zainteresowań, data poza zakresem (U10), limity długości | formularz działa; brak sieci komunikowany dopiero przy „Generuj" (generowanie wymaga sieci) – komunikat przed próbą lub po niej (U6) | po „Generuj" komunikat limitu z godziną odnowienia; dane zachowane | powrót z EK-07 z zachowanymi danymi | n/d | etykiety, walidacje i podpowiedzi w języku interfejsu; wybór języka planu (domyślnie język interfejsu); etykieta noclegu „Nazwa obiektu lub dzielnica" / EN odpowiednik |
| EK-06 | n/d | zapis zgody (wymaga sieci) | błąd zapisu: komunikat + ponów; nic nie wysyłane do AI | brak sieci → nie można wyrazić zgody (zgoda i generowanie wymagają sieci) → komunikat, powrót do EK-05 z danymi | n/d (limit sprawdzany po zgodzie) | odmowa = powrót do EK-05, dane zachowane, limit niezużyty | n/d | pełna treść zgody w języku interfejsu; zapisywany język i wersja zgody |
| EK-07 | n/d | postęp bez fałszywego procentu (czas nieznany; timeout klienta 120 s); informacja, że może potrwać | błąd usługi / niepoprawna odpowiedź AI / przekroczony czas / usługa wyłączona → EK-16, limit zwrócony (poza anulowaniem), powrót do EK-05 | utrata sieci w trakcie → komunikat jak błąd, dane zachowane (limit: zgodnie z tym, czy model ruszył – jak anulowanie, U4) | wynik `limit_exceeded` → komunikat z godziną odnowienia | „Anuluj" z informacją o ewentualnym niezwróceniu limitu; „wstecz" = anulowanie z potwierdzeniem; po anulowaniu nic nie zapisane | n/d | komunikaty w języku interfejsu; wskaźnik nie zdradza treści |
| EK-08 | plan bez punktów w dniu 1 (np. przylot po 22:00): dzień pokazuje wyłącznie godzinę przylotu/dotarcie do noclegu, bez „błędu" | wczytanie z lokalnej bazy | błąd odczytu planu: komunikat + powrót do listy | w pełni dostępny; akcja trasy działa (brak sieci obsługuje Google Maps; ADR-0011 pkt 2, EK-09) | n/d | n/d | n/d – Tamitu nie używa lokalizacji (Q1 = C) | interfejs w języku UI, treść planu w języku planu (może się różnić); informacja o AI w języku UI |
| EK-09 | n/d („Moja lokalizacja" zawsze dostępna) | brak (dane lokalne) | system nie otworzył linku: komunikat, arkusz zostaje, można ponowić | Tamitu nie sprawdza; brak sieci obsługuje Google Maps | n/d | zamknięcie arkusza = powrót do EK-08 | n/d – Tamitu nie prosi o lokalizację (Q1 = C) | etykiety trybów (auto/komunikacja/pieszo) i startów w języku UI |
| ~~EK-10~~ | wycofany (TAM-110, Q1 = C) | – | – | – | – | – | – | – |
| EK-11 | n/d | usuwanie (krótkie) | błąd usunięcia: komunikat, plan pozostaje | działa offline | n/d | „Anuluj" = plan bez zmian | n/d | PL/EN |
| EK-12 | n/d | n/d | n/d | działa offline; pozycje wymagające sieci (Usuń konto, zgody) sygnalizują to dopiero przy użyciu | n/d | n/d | n/d | zmiana języka stosowana natychmiast; nazwa bieżącego języka |
| EK-13 | n/d | pobranie/zapis zgód | błąd zapisu wycofania: komunikat, stan zgody nie zmienia się | wycofanie/ponowne wyrażenie wymaga sieci: komunikat | n/d | n/d | n/d | daty zgód wg lokalizacji; opis zgody w języku UI |
| EK-14 | n/d | zamykanie sesji (krótkie) | błąd wylogowania: komunikat + ponów | wylogowanie działa lokalnie, brak sieci nie blokuje (U8) | n/d | „Anuluj" = pozostaje zalogowany | n/d | komunikat PL/EN |
| EK-15 | n/d | postęp usuwania (nieprzerywalny lub z informacją) | błąd usunięcia: komunikat, jasna informacja, co usunięto, możliwość ponowienia (operacja idempotentna) | komunikat „wymaga internetu", nic nie usunięto | n/d | rezygnacja przed potwierdzeniem lub przy ponownym uwierzytelnieniu = dane bez zmian | n/d | ostrzeżenie PL/EN |
| EK-16 | n/d | n/d | katalog: błąd sieci, usługa niedostępna, niepoprawna odpowiedź AI, brak zgody AI, wymagana aktualizacja aplikacji (U3), usługa niedostępna w wersji testowej (U3), błąd nieoczekiwany | komunikat braku połączenia | komunikat limitu z godziną odnowienia | informacja przy anulowaniu | n/d (Q1 = C) | komplet kluczy PL i EN |

---

## 4. Poprawki z P3-12 naniesione w wymaganiach

Wszystkie zmiany oznaczono w plikach tagiem **[ZMIANA P3-12]** / **[ZMIANA P3-12/P3-14a]** / **[ZMIANA P3-14a]**. Zmiany oznaczone „propozycja" wymagają zatwierdzenia przez właściciela (pyt. U-x).

| Poprawka | Plik | Co zmieniono |
|---|---|---|
| Etykieta noclegu bez pełnego adresu | `US-004-formularz-podrozy.md` | Nowe kryterium: etykieta „Nazwa obiektu lub dzielnica" + podpowiedź, by nie wpisywać pełnego adresu prywatnego; bez blokady, limit 80 znaków |
| Komunikat przy wylogowaniu | `US-002-wylogowanie.md` | Nowe kryteria: komunikat z potwierdzeniem (plany zostają na urządzeniu, niewidoczne dla innych kont, jak je usunąć), „Anuluj"; wylogowanie niedostępne w trakcie generowania (propozycja). Poprawiona treść wzorcowa z ADR-0004 („usuń je w Ustawieniach" – brak takiej funkcji, U7) |
| US-010 vs Q9 | `US-010-usuniecie-konta-i-danych.md` | Sekcja „Dane osobowe": dowód zgód usuwany razem z kontem (usunięto wyjątek „poza minimalnym serwerowym dowodem zgód"); kryterium: brak zapisu zgód i licznika po usunięciu (test E2E); treść ostrzeżenia (zakres, logi 30 dni, konto Google poza Tamitu); dokończenie usuwania po restarcie. [PRAWNIK] może zmienić Q9 → nowy ADR |
| US-011 anulowanie | `US-011-limity-i-obsluga-bledow.md`, `US-005-generowanie-planu-ai.md` | US-011: zasada zwrotu limitu (po anulowaniu bez zwrotu, jeśli model już ruszył – Q12; zwrot przy błędzie usługi); komunikat limitu z godziną odnowienia w czasie lokalnym (północ Europe/Warsaw, Q5). US-005: informacja przy anulowaniu, powrót do formularza z danymi, „wstecz" = anulowanie |
| Zgoda na AI przy pierwszym generowaniu | `US-003-zgody-i-prywatnosc.md` | Nowe kryteria: zgoda osobna, niezaznaczona, równorzędne „Zgadzam się/Nie zgadzam się", treść zgody, skutek odmowy (powrót do formularza, nic nie wysłane), brak ponownego pytania po wyrażeniu zgody |
| Zakres daty przylotu | `US-004-formularz-podrozy.md` | Kryterium (propozycja, U10): data nie wcześniejsza niż wczoraj i nie późniejsza niż za 2 lata – zgodnie z kontraktem API |
| Powrót zwrotu limitu | `US-011` | j.w. |

Niezmienione, zgodne ze stanem: N3 (plany zostają po wylogowaniu), N7 (usunięcie natychmiastowe), Q6/N11 (preferencje), Q1 (dokładna lokalizacja, test C później – **nieaktualne od 2026-11-25: Q1 = C, ADR-0017, TAM-110**).

---

## 5. Niejasności i pytania (z propozycją domyślnej odpowiedzi)

Do czasu odpowiedzi obowiązuje propozycja. Te same wiersze dopisano do `docs/open-questions.md` (tabela „Przegląd wymagań pod ekrany (P3-14a)").

| # | Pytanie | Adresat | Propozycja domyślna | Wpływ |
|---|---|---|---|---|
| U1 | Czy język interfejsu można zmienić już na ekranie startowym (przed logowaniem)? Polityka i zgody mają być w języku interfejsu (US-003) | właściciel | Tak: domyślnie język urządzenia (PL/EN, inaczej EN), przełącznik w EK-02 i w Ustawieniach | EK-02, EK-12 |
| U2 | Co dzieje się po odmowie akceptacji polityki (EK-02) lub po niezaakceptowaniu zmienionej wersji (EK-03)? Czy ponowna akceptacja wymaga sieci (rejestracja zgody)? Jak sformułować wymóg dorosłości (N8)? | właściciel, [PRAWNIK] | EK-02: bez akceptacji logowanie nieaktywne, brak innej drogi (aplikacja nie działa bez konta). EK-03: blokujący; dostępne tylko „Akceptuję", „Wyloguj", „Usuń konto"; wymaga sieci; w EK-02 jedno zdanie, że aplikacja jest dla osób pełnoletnich | EK-02, EK-03, US-003 |
| U3 | Jak komunikować: (a) wymaganą aktualizację aplikacji (`unsupported_version`), (b) „usługa AI w wersji testowej niedostępna dla tego konta" (`test_data_only`, do zamknięcia SEC-15) | architekt, właściciel | (a) komunikat „zaktualizuj aplikację" z linkiem do sklepu, formularz zachowany; (b) komunikat „funkcja chwilowo niedostępna", w wersji testowej wewnętrznie rozróżnialny | EK-16 |
| U4 | Czy pokazywać użytkownikowi liczbę pozostałych generowań (np. „pozostało 3 z 5")? Odpowiedź serwera zawiera `remainingToday` dopiero po generowaniu; nie ma osobnego odczytu | właściciel, architekt | Pokazywać „pozostało X z 5" tylko po udanym generowaniu (z odpowiedzi) i w komunikacie limitu; bez dodatkowego wywołania; po utracie sieci w trakcie generowania nie obiecywać zwrotu limitu | EK-07, EK-08, US-011 |
| U5 | Czy zachowywać szkic formularza po zamknięciu/zabiciu aplikacji? | właściciel, security | Nie: szkic tylko w pamięci ekranu (minimalizacja danych); po zabiciu procesu formularz pusty | EK-05 |
| U6 | Zachowanie generowania w tle (aplikacja zminimalizowana) i kontrola sieci przed „Generuj" | architekt | Generowanie trwa do czasu limitu 120 s; po powrocie wynik lub błąd; po zabiciu procesu nic nie zapisano, a limit może być zużyty; przed „Generuj" sprawdzenie sieci i komunikat bez zużycia limitu | EK-05, EK-07 |
| U7 | Treść komunikatu wylogowania odwołuje się do „usuń je w Ustawieniach" (ADR-0004), ale nie ma funkcji „usuń wszystkie plany" | architekt, security | Nie dodawać funkcji; komunikat: usuwanie pojedynczych planów lub usunięcie konta (wdrożone w US-002) | EK-14, US-002 |
| U8 | Wylogowanie podczas generowania i brak sieci przy wylogowaniu | architekt | Wylogowanie niedostępne w trakcie generowania (EK-07 modalny); wylogowanie działa bez sieci (operacja lokalna) | EK-14, US-002 |
| U9 | Czy informować użytkownika, że plany są tylko na urządzeniu (utrata telefonu/odinstalowanie = utrata planów, R13; brak kopii Androida, S4)? | właściciel | Tak: krótka informacja w stanie pustym EK-04 i w Ustawieniach/Prywatność | EK-04, EK-13 |
| U10 | Dopuszczalny zakres daty przylotu w formularzu? (kontrakt API: od wczoraj do +2 lat) | właściciel | Jak w API; komunikat o zakresie; dodane do US-004 jako propozycja | EK-05 |
| U11 | Wpływ Q1 (A vs C) na ekrany: czy mockup ma obejmować EK-10 (wariant A, obowiązujący) i wariant C bez EK-10? | właściciel, architekt | **Zamknięte 2026-11-25:** Q1 = C; EK-10 wycofany, EK-09 v0.4 bez lokalizacji w Tamitu (TAM-108) | EK-09, EK-10 |
| U12 | Co użytkownik widzi, gdy lokalna baza konta jest niedostępna (np. utrata klucza szyfrowania po przywróceniu urządzenia)? | architekt | Komunikat „dane na tym urządzeniu są niedostępne"; opcje: wyloguj, usuń konto (usunięcie osieroconego pliku – ADR-0005) | EK-01 |
| U13 | Czy ograniczać liczbę zapisanych lokalnie planów lub dodać wyszukiwanie/filtr listy? | właściciel | Brak limitu i brak wyszukiwania w MVP (5 generowań dziennie ogranicza przyrost); lista od najnowszego | EK-04 |
| U14 | Przy etykiecie noclegu „nazwa obiektu lub dzielnica" trasa z „bazy noclegowej" (US-007) wyznaczana jest z tekstu: dokładność może być niska. Czy to akceptowalne? | właściciel | Tak; precyzyjny start zapewnia „moja lokalizacja"; informacja w EK-09 przy starcie z noclegu, że punkt jest przybliżony | EK-09, US-007 |
| U15 | Czy EK-13 ma pozwalać wycofać także zgodę na politykę? | właściciel, [PRAWNIK] | Nie: polityka to informacja (akceptacja = zapoznanie); „wycofanie" = usunięcie konta; wycofanie zgody na AI – tak | EK-13 |

Pytania nadal otwarte z wcześniejszych faz (bez zmian): S1 dane administratora, SEC-15 (dostawca AI), [PRAWNIK] S3/S10/S11/S12, Q9 (dowód zgód – obecnie usuwany z kontem), Q10.

---

## 6. Kryteria wejścia dla projektanta mockupu

### 6.1 Wejścia (co ma przeczytać)
Ten dokument; US-001..011 (kryteria akceptacji po zmianach P3-12/P3-14a); `docs/security/privacy-checklist.md` pkt 2 (zgody, lokalizacja) i pkt 5; `docs/data/model-danych.md` pkt 1 (zbiory wartości formularza); `docs/api/posrednik-api.md` pkt 6 (kody błędów do mapowania na komunikaty); ADR-0006 (PL/EN). Odpowiedzi na U1–U15 lub przyjęcie propozycji domyślnych.

### 6.2 Czego mockup ma dowieść (kryteria akceptacji mockupu)
1. **Kompletność:** wszystkie ekrany EK-01..EK-16 i wszystkie przepływy P1–P10 przechodzą od początku do końca bez ślepych zaułków; każdy ekran ma stany z macierzy 3.2 (pusty, ładowanie, błąd, brak sieci, limit, anulowanie, odmowa lokalizacji) lub jawną adnotację „n/d".
2. **Zgody:** akceptacja polityki niezaznaczona domyślnie; logowanie niedostępne bez niej; zgoda na AI osobna, niezaznaczona, z równorzędnymi „Zgadzam się/Nie zgadzam się" i pełną treścią (dane, odbiorca, czego nie wysyłamy, możliwość błędów); cofnięcie zgody tak łatwe jak wyrażenie.
3. **Minimalizacja danych w formularzu:** etykieta „Nazwa obiektu lub dzielnica" z podpowiedzią o nie wpisywaniu adresu prywatnego; zainteresowania wyłącznie z listy 11 (0–5), brak wolnego tekstu; budżet/tempo po 3 poziomy; liczba osób 1–10 (domyślnie 2); lot wymaga lotniska i godziny, auto – godziny.
4. **Informacja o AI:** w widoku planu widoczne, że plan stworzyła AI i może zawierać błędy, godziny otwarcia do weryfikacji; pierwszy dzień pokazuje godzinę przylotu/przyjazdu.
5. **Generowanie:** postęp, anulowanie z informacją o możliwym niezwróceniu limitu, powrót do formularza z zachowanymi danymi; limit 5/dobę z godziną odnowienia.
6. **Lokalizacja (zmiana TAM-110, Q1 = C):** brak prośby o uprawnienie i brak EK-10; „Moja lokalizacja" = link bez punktu startowego z informacją, że o lokalizację może zapytać Google Maps; brak jakiegokolwiek pokazywania mapy w aplikacji (U11 zamknięte). Kolumna „odmowa lokalizacji" w macierzy stanów to wszędzie „n/d".
7. **Wylogowanie i usunięcie konta:** komunikat wylogowania z informacją o planach na urządzeniu; ostrzeżenie o usunięciu konta z zakresem (w tym dowód zgód, logi 30 dni, konto Google poza Tamitu), ponowne uwierzytelnienie, brak sieci, dokończenie po restarcie.
8. **Dwa języki:** wersje PL i EN najdłuższych tekstów (zgody, limit, usunięcie konta, komunikat wylogowania) mieszczą się bez ucinania; pokazane rozdzielenie języka interfejsu i języka planu.
9. **Dostępność:** etykiety semantyczne, kontrast, rozmiary dotykowe, skalowanie czcionki, nie tylko kolor jako nośnik informacji (wg `.farm/review/checklist-quality.md`).
10. **Zgodność z zakresem:** w mockupie nie ma elementów spoza MVP (reklamy, subskrypcje, inne logowania, tryb gościa, eksport, edycja planu, udostępnianie).
11. **Śledzenie:** każdy ekran mockupu wskazuje identyfikator EK-xx i US-xxx; rozbieżności z wymaganiami zgłoszone jako nowe pytania do analityka, a nie rozwiązane po cichu.

### 6.3 Poza zadaniem projektanta mockupu
Wybór technologii, nazwy komponentów Fluttera, schemat danych, kontrakt API; kolory i styl – według wytycznych właściciela/projektanta (analityk ich nie narzuca).
