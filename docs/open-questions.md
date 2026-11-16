# Otwarte pytania

Odpowiedzi właściciela z 2026-11-14 (przejście pytań jedno po drugim, przed decyzją G1).
Pytania N1–N10 pochodzą z `docs/requirements/open-questions-proposals.md`, S1–S12 z `docs/security/open-questions-security.md`.
Status „odpowiedziane" = decyzja właściciela zapisana; dokumenty faz muszą ją odzwierciedlić (patrz kolumna „Skutek").

| # | Pytanie | Zadaje | Status | Odpowiedź właściciela | Skutek dla dokumentów |
|---|---|---|---|---|---|
| 1 | Który model AI układa plan dnia? | architect | odpowiedziane | Gemini (kierunek); finalny wybór i koszty w ADR | zgodne z propozycją |
| 2 | AI bezpośrednio czy przez pośrednika? | architect | odpowiedziane | Przez pośrednika (np. Cloud Functions) | zgodne |
| 3 | Środowiska Firebase i budżety | architect, owner | odpowiedziane | dev + prod, region UE, alerty od startu; budżety ustawia właściciel | zgodne |
| 4 | Lokalizacja: do czego, czy w tle | analyst, security | odpowiedziane | Tylko link trasy, na żądanie, na pierwszym planie; bez tła i „w pobliżu" | zgodne |
| 5 | Gdzie plany i dane podróży | analyst, security | odpowiedziane | Lokalnie w MVP | zgodne |
| 6 | Reklamy i subskrypcje | analyst | odpowiedziane | Poza apką testową | zgodne |
| 7 | Języki i minimalna wersja Androida | analyst | odpowiedziane | **Polski + angielski** (min. API wg architekta) | **ZMIANA**: scope/US zakładały tylko polski; plany AI i UI w 2 językach, ryzyko/test |
| 8 | Logowanie w pierwszym wydaniu | analyst | odpowiedziane | Tylko Google | zgodne |
| N1 | Pola formularza | analyst | odpowiedziane | **Pola z wizji + data/godzina przylotu + preferencje: zainteresowania, budżet, tempo, liczba osób** | **ZMIANA**: US-004/005 zakładały brak preferencji; rejestr danych (nowe pola) |
| N2 | Maks. liczba dni | analyst | odpowiedziane | 14 | zgodne |
| N3 | Plany po wylogowaniu | analyst | odpowiedziane | Zostają, niewidoczne dla innego konta | zgodne |
| N4 | Limit generowań na dobę | analyst | odpowiedziane | 5 na konto na dobę (do zmiany po pomiarze kosztu) | zgodne |
| N5 | Osobna zgoda na AI | analyst | odpowiedziane | Tak, osobne pole zgody | zgodne |
| N6 | Bufor po przylocie | analyst | odpowiedziane | 3 h po lądowaniu; 0 przy aucie | zgodne |
| N7 / S9 | Usunięcie konta, eksport | analyst, security | odpowiedziane | Natychmiastowe usunięcie, bez eksportu w aplikacji; dostęp do danych na wniosek e-mailem | zgodne |
| N8 | Odbiorcy | analyst | odpowiedziane | Dorośli, indywidualni | zgodne |
| N9 | Tryb gościa | analyst | odpowiedziane | Nie | zgodne |
| N10 / S1 | Administrator danych, polityka | analyst, security | odpowiedziane (częściowo) | TadeCode, bez IOD; polityka na tadecode.pl/tamitu/prywatnosc przed testami zewnętrznymi. **Do uzupełnienia przez właściciela: nazwa, adres, NIP** | zgodne; dane firmy brakują |
| S2 | Lokalizacja przetwarzania Firebase i transfery | security | odpowiedziane | Security weryfikuje w dokumentacji Google w fazie 2 | zadanie dla security |
| S3 | Dowód zgód | security | odpowiedziane | Minimalny zapis serwerowy (UID, wersja, wartość, data); okres po usunięciu konta: [PRAWNIK] | zgodne |
| S4 | Kopia zapasowa Androida | security | odpowiedziane | Wyłączyć allowBackup; szyfrowanie bazy do decyzji architekta | zgodne |
| S5 | Wariant API modelu AI | security | odpowiedziane | Korporacyjny, region UE, DPA, bez trenowania (np. Vertex AI); warunki do potwierdzenia w ADR; do tego czasu brak prawdziwych danych do AI | zgodne; nadal warunek wstępny |
| S6 | Dokładność lokalizacji | security | odpowiedziane | **Dokładna** (domyślnie) | **ZMIANA**: security zakładał przybliżoną; uprawnienie precyzyjnej lokalizacji, rejestr D7, US-007 |
| S7 | Retencja logów | security | odpowiedziane | 30 dni, bez treści, UID jako skrót | zgodne |
| S8 | Skrzynka kontaktowa RODO | security | odpowiedziane | tamitu@tadecode.pl | uzupełnić politykę/checklistę |
| S10 | Regulamin | security | odpowiedziane | Tak, krótki, przed wydaniem publicznym [PRAWNIK] | zgodne |
| S11 | DPIA | security | odpowiedziane | MVP: raczej nie; ocena przy rozszerzeniach [PRAWNIK] | zgodne |
| S12 | Podstawa prawna logów/licznika, wiek | security | odpowiedziane | Uzasadniony interes (lit. f), tylko dorośli [PRAWNIK] | zgodne |

## Nowe pytanie wynikające z odpowiedzi (analityk, 2026-11-14)

| # | Pytanie | Zadaje | Status | Propozycja domyślna | Skutek |
|---|---|---|---|---|---|
| N11 | Doprecyzowanie po N1 i pyt. 7: (a) czy pola preferencji są obowiązkowe; (b) formaty: zainteresowania (lista predefiniowana czy tekst), budżet i tempo (np. 3 poziomy), liczba osób (zakres); (c) czy język planu wybiera się osobno od języka interfejsu | analyst | otwarte | (a) opcjonalne, z wartościami domyślnymi; (b) lista predefiniowana zainteresowań (minimalizacja danych, ochrona przed danymi wrażliwymi), budżet i tempo – 3 poziomy, liczba osób 1–10 (zakres do potwierdzenia); (c) język planu domyślnie = język interfejsu, z możliwością zmiany w formularzu | US-004, US-005; do czasu odpowiedzi obowiązuje propozycja |

## Przegląd wymagań pod ekrany (P3-14a), analityk, 2026-11-16
Szczegóły i wpływ na ekrany: `docs/requirements/screens-and-flows.md` pkt 5. Do czasu odpowiedzi obowiązuje propozycja domyślna.

| # | Pytanie | Zadaje | Status | Propozycja domyślna | Skutek |
|---|---|---|---|---|---|
| U1 | Czy język interfejsu można zmienić już na ekranie startowym (przed logowaniem)? | analyst | otwarte | Tak: domyślnie język urządzenia (PL/EN, inaczej EN), przełącznik na ekranie startowym i w Ustawieniach | EK-02, EK-12 |
| U2 | Co po odmowie akceptacji polityki lub niezaakceptowaniu zmienionej wersji; czy ponowna akceptacja wymaga sieci; sformułowanie wymogu dorosłości (N8) | analyst, [PRAWNIK] | otwarte | Bez akceptacji brak dostępu; ekran ponownej akceptacji blokujący (opcje: Akceptuję, Wyloguj, Usuń konto), wymaga sieci; jedno zdanie o pełnoletności na ekranie startowym | US-003, EK-02, EK-03 |
| U3 | Komunikaty: wymagana aktualizacja aplikacji (`unsupported_version`); „AI niedostępne dla tego konta" (`test_data_only`, do zamknięcia SEC-15) | architect, owner | otwarte | „Zaktualizuj aplikację" z linkiem do sklepu; „funkcja chwilowo niedostępna" | EK-16 |
| U4 | Czy pokazywać liczbę pozostałych generowań (odpowiedź serwera zawiera `remainingToday` dopiero po generowaniu) | analyst, architect | otwarte | Pokazywać tylko po udanym generowaniu i w komunikacie limitu, bez dodatkowego wywołania | US-011, EK-07, EK-08 |
| U5 | Czy zachowywać szkic formularza po zabiciu aplikacji | analyst, security | otwarte | Nie (tylko w pamięci ekranu; minimalizacja danych) | EK-05 |
| U6 | Generowanie w tle (aplikacja zminimalizowana) i sprawdzenie sieci przed „Generuj" | architect | otwarte | Trwa do limitu 120 s, po powrocie wynik lub błąd; po zabiciu procesu nic nie zapisano, limit może być zużyty; sprawdzenie sieci przed wysłaniem bez zużycia limitu | EK-05, EK-07 |
| U7 | Wzorcowy komunikat z ADR-0004 mówi „usuń je w Ustawieniach", a funkcji „usuń wszystkie plany" nie ma | analyst, architect, security | otwarte | Nie dodawać funkcji; treść komunikatu: usuwanie pojedynczych planów lub konta (już w US-002) | US-002, EK-14 |
| U8 | Wylogowanie podczas generowania i bez sieci | analyst, architect | otwarte | Niedostępne w trakcie generowania; działa bez sieci (operacja lokalna) | US-002, EK-14 |
| U9 | Czy informować, że plany są tylko na urządzeniu (R13, S4) | analyst, owner | otwarte | Tak, krótka informacja w stanie pustym listy i w Ustawieniach/Prywatność | EK-04, EK-13 |
| U10 | Zakres daty przylotu w formularzu | analyst, owner | otwarte | Od wczoraj do +2 lat (jak API); dodane do US-004 jako propozycja | US-004, EK-05 |
| U11 | Wpływ Q1 na mockup: wariant A (z ekranem prośby o lokalizację) i C (bez) | analyst, architect | otwarte | Mockup dla A z adnotacją o wariancie C | EK-09, EK-10 |
| U12 | Komunikat przy niedostępnej lokalnej bazie konta (np. utrata klucza) | architect | otwarte | „Dane na tym urządzeniu są niedostępne"; opcje: wyloguj, usuń konto | EK-01 |
| U13 | Limit liczby zapisanych planów lokalnych, wyszukiwanie na liście | analyst, owner | otwarte | Brak limitu i wyszukiwania w MVP | EK-04 |
| U14 | Dokładność trasy z „bazy noclegowej" przy etykiecie „nazwa obiektu lub dzielnica" | analyst, owner | otwarte | Akceptowalne; informacja o przybliżonym punkcie startu; dokładny start = „moja lokalizacja" | US-007, EK-09 |
| U15 | Czy zgodę na politykę można wycofać w Ustawieniach | analyst, [PRAWNIK] | otwarte | Nie (polityka to informacja); wycofanie = usunięcie konta; zgodę na AI – można | EK-13 |

Rozstrzygnięte w tym przeglądzie (bez nowych pytań): US-010 zgodne z Q9 (dowód zgód usuwany z kontem; ewentualna zmiana po poradzie prawnika = nowy ADR); anulowanie generowania wg Q12 odzwierciedlone w US-005/US-011.

## Marka i design system (P3-14b krok 1), ux, 2026-11-16
Szczegóły: `docs/ux/brand.md`, `docs/ux/design-system.md`, podgląd `docs/ux/mockups/brand-preview.html`. Do czasu odpowiedzi obowiązuje propozycja (poza UX1 – bez wyboru wariantu krok 2 nie rusza).

| # | Pytanie | Zadaje | Status | Propozycja domyślna | Skutek |
|---|---|---|---|---|---|
| UX1 | Który wariant marki: A „Lazur" (morski, Roboto) czy B „Terakota" (ciepły, Nunito w tytułach)? | ux → owner | **zamknięte 2026-11-16: A** („Wybieram wariant A"); UX5 nieaktualne | **A „Lazur"** (odróżnienie działań od błędów, zaufanie przy zgodach i AI, najniższy koszt) | brand.md, design-system.md, krok 2 (ekrany) |
| UX2 | Logo i ikona aplikacji: kto i kiedy dostarcza? | ux → owner | otwarte | Do wersji testowych tymczasowy znak słowny „Tamitu" i ikona adaptacyjna „T" na kolorze primary (specyfikacja ux); finalne logo od grafika przed publikacją w Play | brand.md pkt 5, EK-02, ikona APK |
| UX3 | Czy włączyć kolory dynamiczne Androida (Material You, kolory z tapety)? | ux → owner | otwarte | Nie – kolory marki stałe, kontrast sprawdzony | design-system.md pkt 1 |
| UX4 | Motyw jasny/ciemny: tylko wg systemu czy także wybór w Ustawieniach? | ux → owner, analyst | otwarte | Tylko wg systemu w MVP (EK-12 nie przewiduje przełącznika) | EK-12 |
| UX5 | Wariant B: dołączenie czcionki Nunito do aplikacji (ok. +0,3 MB, bez pobierania z Google Fonts w czasie działania) – akceptowalne technicznie? | ux → architect | nieaktualne (wybrano A, 2026-11-16) | Tak, jako zasób aplikacji; pakiet pobierający czcionki z sieci wykluczony | brand.md, ADR-0008 |
| UX6 | Ton i forma zwracania się: „Ty" czy forma bezosobowa; formy rodzajowe („Zapoznałem(-am) się") czy neutralne („Zapoznaję się z polityką…")? | ux → owner, [PRAWNIK] dla zgód | otwarte | „Ty" / „you"; w zgodach forma neutralna bez rodzaju, jeśli prawnik nie wymaga innej | wszystkie teksty, CMP-09 |
| UX7 | Ilustracje w stanach pustych i błędach: same ikony Material czy ilustracje (koszt grafika)? | ux → owner | otwarte | Same ikony 48 dp w MVP | CMP-18 |
| UX8 | Konwencja kluczy l10n (lowerCamelCase z prefiksem obszaru, np. `planListEmptyTitle`) – zgodna z planem mobile-dev? | ux → mobile-dev | otwarte | Jak w `docs/ux/components/index.md` | ARB, wszystkie ekrany |
| UX9 | Usunięcie planu: dialog potwierdzenia (wymaganie US-009) czy natychmiastowe usunięcie z „Cofnij" w snackbarze (zalecenie M3; usunięcie odroczone o ok. 10 s)? | ux → owner, architect | otwarte | Dialog w MVP (zgodnie z US-009 i „trwałym usunięciem"); „Cofnij" do rozważenia później | EK-11, US-009 |
| UX10 | Wyjście z wypełnionego formularza (EK-05) wstecz: pytać „Odrzucić dane?" czy nie? | ux → owner | otwarte | Nie pytać w MVP (formularz krótki, szkicu nie zapisujemy – U5) | EK-05 |
| UX11 | Domyślny tryb trasy w EK-09 | ux → owner | otwarte | Komunikacja (zwiedzanie w mieście, bez założenia auta); wybór nie jest zapamiętywany | EK-09 |
| UX12 | Czy pokazywać w Ustawieniach, na jakie konto Google jest się zalogowanym (e-mail)? | ux → architect, security | otwarte | Nie – aplikacja nie zapisuje e-maila (model danych, minimalizacja); ewentualnie odczyt z SDK bez zapisu – decyzja architekta/security | EK-12 |
| UX13 | Usunięcie konta: czy oprócz pełnego ekranu ostrzeżenia i ponownego logowania wymagać dodatkowego potwierdzenia (pole wyboru / wpisanie słowa)? | ux → security, owner | otwarte | Nie – wystarczy ekran ostrzeżenia z przyciskiem „Usuń konto na zawsze" i ponowne uwierzytelnienie Google | EK-15 |
| UX14 | Czy używać ikon Hugeicons zamiast Material Symbols Outlined? (pytanie właściciela 2026-11-16: „czy mozemy uzywac ikon z hugeicons ??”) | ux → owner | **zamknięte 2026-11-16: zastąpić od razu** darmowym zestawem Hugeicons Stroke Rounded („tak zastapić odrazu”; wcześniej: „chce zeby porzygotowal wariant z hugeicons darmowy zestaw ikon”). Rekomendacja ux była: zostać przy Material Symbols w MVP | design-system.md pkt 8 i 8.1, brand.md, komponenty, ekrany, makiety; warunek: UX15 |
| UX15 | Hugeicons Free: licencja, pakiet Flutter `hugeicons`, podmiany ikon wbudowanych w widgety M3 (`design-system.md` pkt 8.1), wpis do ADR-0008 | ux → architect | **częściowo zamknięte 2026-11-16:** licencja sprawdzona u źródeł – zestaw Free i pakiet `hugeicons` 4.4.0 na MIT, użycie komercyjne dozwolone; warunek: obie noty MIT (Hugeicons 2025, Halal Labs 2024) na ekranie licencji open source, bez udostępniania ikon jako osobnego zestawu. Otwarte dla architekta: wpis w ADR-0008, czy pakiet nie zawiera ikon Pro (archiwum nieprzeglądane), wykonalność podmian | ADR-0008, design-system.md pkt 8, mobile-dev (P3-04/06/07; ekran licencji open source) |
| UX16 | Dopracowanie kolorystyki (jasny i ciemny motyw) – po przeglądzie użyteczności | owner → ux | odłożone (2026-11-16, właściciel: „ok narazie ske skupimy na uzytecznosci a pozniej na kolorwaniu”) | Do tego czasu obowiązuje obecny jasny motyw (surface `#E6EDEC`) i ciemny bez zmian; żadnych dalszych prób kolorów, aż właściciel wróci do tematu | design-system.md pkt 2, makiety |

## Nadal do wykonania przez właściciela
- Odpowiedź na N11 (może zostać przyjęta propozycja domyślna).
- Dane administratora (nazwa, adres, NIP) do polityki prywatności (S1).
- Potwierdzenie warunków przetwarzania u dostawcy AI przed wysyłką prawdziwych danych (S5, ADR).
- Porada prawnika w punktach oznaczonych [PRAWNIK] (S3, S10, S11, S12).

## Faza 2 – pytania architekta do właściciela (G2), 2026-11-15
Źródło: `docs/architecture/uwagi-dla-orchestratora.md`. Odpowiedzi właściciela z 2026-11-15 w sekcji poniżej tabeli (wszystkie Q1–Q12 odpowiedziane).

| # | Pytanie | Propozycja | ADR |
|---|---|---|---|
| Q1 | Lokalizacja: zostawić dokładną z uprawnieniem (opcja A, zgodnie z S6) czy link Maps bez `origin` (opcja C: Google Maps sam użyje bieżącej pozycji, zero uprawnień; wymaga testu na urządzeniu)? | C prostsza i bezpieczniejsza, ale zmienia S6/US-007; do decyzji wdrażamy A | 0007 |
| Q2 | Testy a App Check: wewnętrzna ścieżka Google Play (konto Play organizacji) czy sideload APK z wyłączonym App Check? | Ścieżka Play; do tego czasu App Check wyłączony na dev | 0002 |
| Q3 | Budżety: dev 20 PLN, prod 100 PLN/mies., alerty 50/90/100%, auto-wyłączenie AI przy 100%; limit globalny 50 generowań/dobę | akceptacja lub inne kwoty | 0003 |
| Q4 | Klasa modelu: start od Flash, ewentualnie Flash-Lite; ceny z `costs.md` (niezweryfikowane) jako podstawa? | akceptacja; ostateczny model po ewaluacji w fazie 3 | 0001 |
| Q5 | „Doba" limitu: dzień kalendarzowy Europe/Warsaw czy okno 24 h? | kalendarzowy | 0002 |
| Q6 | N11: lista 11 zainteresowań (0–5), budżet i tempo po 3 poziomy, liczba osób 1–10 (domyślnie 2), język planu = język UI z możliwością zmiany; `family_attractions` OK? | akceptacja | 0006 |
| Q7 | Szyfrowanie bazy lokalnej (SQLCipher, +kilka MB APK)? | tak | 0005 |
| Q8 | minSdk 26 (Android 8.0)? | 26 | 0007 |
| Q9 | Dowód zgód po usunięciu konta [PRAWNIK] | zapytać prawnika | 0004, 0005 |
| Q10 | Plan Blaze (karta) i konto rozliczeniowe TadeCode; nazwy projektów (`tamitu-dev-…`, `tamitu-prod-…`) | potwierdzić | 0003 |
| Q11 | Warunki dostawcy AI (SEC-15): lista w ADR-0001; do tego czasu prod tylko z danymi testowymi | wypełnić przed realnymi danymi | 0001 |
| Q12 | Anulowanie generowania nie zwraca slotu limitu, jeśli model już ruszył | tak | 0002 |

### Odpowiedzi właściciela na Q1–Q12 (2026-11-15)
| # | Odpowiedź | Skutek |
|---|---|---|
| Q1 | **A, test C później**: wdrażamy dokładną lokalizację (uprawnienia FINE+COARSE); wariant C (link bez `origin`) sprawdzany na urządzeniu w fazie 3 i ewentualnie upraszczamy | P3-07; security rekomendował C |
| Q2 | Ścieżka testowa Google Play (konto Play organizacji); do tego czasu sideload tylko dev, dane testowe, App Check wyłączony | zgodne |
| Q3 | dev 20 PLN, prod 100 PLN/mies., alerty 50/90/100%, auto-wyłączenie AI, limit globalny 50/dobę | zgodne |
| Q4 | Start od Flash, ostateczny wybór po ewaluacji w fazie 3; ceny do weryfikacji przed fazą 3 | zgodne |
| Q5 | Dzień kalendarzowy Europe/Warsaw | zgodne |
| Q6 / N11 / S13 | Zaakceptowano: preferencje opcjonalne; 11 zainteresowań z listy (0–5), bez wolnego tekstu; budżet i tempo 3 poziomy; liczba osób 1–10 (domyślnie 2); język planu = język UI z możliwością zmiany; `family_attractions` zostaje | N11 i S13 zamknięte |
| Q7 | Szyfrować bazę (SQLCipher) | zgodne |
| Q8 | minSdk 26 | zgodne |
| Q9 | Dowód zgód usuwany z kontem; zapytać prawnika | [PRAWNIK] |
| Q10 | Właściciel zakłada konto rozliczeniowe/Blaze i projekty przed fazą 3; nazwy tamitu-dev-… / tamitu-prod-… zaakceptowane | zadanie właściciela |
| Q11 | Właściciel potwierdza warunki dostawcy AI; do tego czasu `ALLOW_REAL_DATA=false` | SEC-15 |
| Q12 | Slot limitu nie wraca po anulowaniu, jeśli model już ruszył | zgodne |

## Przegląd security ekranów (P3-14c), security, 2026-11-16
Szczegóły: `docs/security/reviews/2026-11-16-p3-14c-ekrany.md`. Do czasu odpowiedzi obowiązuje propozycja domyślna.

| # | Pytanie | Zadaje | Status | Propozycja domyślna | Skutek |
|---|---|---|---|---|---|
| S15 | Czy treść zgody na AI (EK-06) ma wskazywać administratora (TadeCode + kontakt), czy wystarczy link do polityki? | security → owner, [PRAWNIK] | otwarte | Dodać jedno zdanie o administratorze i kontakcie (tamitu@tadecode.pl) | EK-06, SEC-30 |
| S16 | Brzmienie akceptacji polityki (CMP-09, EK-02, EK-03): „Zapoznaję się…” (EK-02) vs „Zapoznałem(-am) się…” (CMP-09) | security → owner, [PRAWNIK] | otwarte | Jeden tekst: „Potwierdzam zapoznanie się z {polityką prywatności} i akceptuję ją” / „I confirm I have read and accept the {Privacy Policy}”; etykieta TalkBack = tekst widoczny | CMP-09, EK-02, EK-03, UX6 |
| S17 | Czy serwer egzekwuje aktualną wersję polityki przy `generatePlan` (dziś `consent_required` dotyczy tylko zgody AI; EK-01 pomija sprawdzenie offline)? | security → architect | otwarte | Tak: `consent_required` z `consentType=privacy_policy`, klient → EK-03; EK-01 sprawdza wersję przy pierwszej akcji sieciowej w sesji | SEC-26, US-003, EK-01, EK-16 (blokuje ich `ux-ready`) |
| S18 | Co dzieje się z planami na innym urządzeniu, na którym użytkownik był zalogowany, po usunięciu konta (sesja wygasa, plik bazy zostaje)? | security → architect | otwarte | Przy `unauthenticated`/`user-not-found` po usunięciu konta aplikacja usuwa plik bazy tego konta i informuje użytkownika; tekst EK-15 wspomina o innych urządzeniach | EK-15, EK-01, US-010, ADR-0004/0005 |
