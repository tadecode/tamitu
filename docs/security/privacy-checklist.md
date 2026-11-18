# Lista kontrolna prywatności – Tamitu (wstępna)

Stan: 2026-11-15, wersja 0.3 (po przeglądzie ADR-0001..0008, P2-08, i uwagach architekta `docs/architecture/uwagi-dla-orchestratora.md` pkt 2; wcześniej 0.2 po G1). Autor: Security.
Zmiany v0.3: pkt 2 (kolejność zgód: polityka przed logowaniem, zgoda AI przy pierwszym generowaniu i w Ustawieniach; treść zgody AI; pole noclegu), pkt 3 (Vertex AI, buforowanie u dostawcy), pkt 5 (usunięcie: stary token, logi, UID-HMAC), pkt 6 (retencja: TTL, logi, kubełek), pkt 7 (transfery, Auth), pkt 8 (zależności od Q1), pkt 10 (szkic polityki: Vertex AI, kubełek logów, IP, App Check, szyfrowanie lokalne); oznaczenia „[zależy od Q1]". Przegląd: `przeglad-adr.md`. **Nie jest to porada prawna** – punkty oznaczone [PRAWNIK] lub [WŁAŚCICIEL] wymagają potwierdzenia. Pytania S1..S12: `docs/security/open-questions-security.md` (odpowiedziane).
Legenda statusu: [ ] do zrobienia, [~] zaplanowane w historyjce, [?] decyzja otwarta.
Ustalone przez właściciela: administrator TadeCode bez IOD (dane firmy – do uzupełnienia), kontakt tamitu@tadecode.pl, minimalny zapis serwerowy zgód, `allowBackup` wyłączone, wariant AI korporacyjny UE z DPA bez trenowania (warunek przed realnymi danymi), lokalizacja dokładna, logi 30 dni bez treści ze skrótem UID, regulamin przed wydaniem publicznym [PRAWNIK], DPIA raczej nie w MVP [PRAWNIK], lit. f dla logów i licznika, tylko dorośli [PRAWNIK], języki PL + EN, preferencje podróży.

## 1. Podstawy prawne (propozycja, do potwierdzenia [PRAWNIK])
| Przetwarzanie | Podstawa | Uwagi |
|---|---|---|
| Logowanie, sesja (D1, D2) | Art. 6 ust. 1 lit. b | Umowa o korzystanie z aplikacji (regulamin – czy potrzebny? S10) |
| Dane podróży i plany lokalne (D4, D5, D9) | Art. 6 ust. 1 lit. b | |
| Przekazanie danych do AI (D6) | Zgoda, art. 6 ust. 1 lit. a (osobna – N5, ustalone) + lit. b | Wymaga jasnej informacji kto jest odbiorcą i gdzie |
| Preferencje podróży (D15) | Lit. b (plan); do AI – zgoda na AI (lit. a) | Budżet tylko jako poziom; zainteresowania z listy (bez danych art. 9); [PRAWNIK] potwierdza ocenę |
| Język (D16) | Lit. b (ustawienie funkcjonalne) | Zwykła dana o niskiej wrażliwości; bez wnioskowania o pochodzeniu |
| Lokalizacja dokładna (D7) | Zgoda (uprawnienie systemowe do dokładnej lokalizacji, na żądanie) | Nie utrwalamy |
| Licznik użycia, logi (D10, D11) | Art. 6 ust. 1 lit. f (ustalone, S12) [PRAWNIK] | Zapisać ocenę równowagi interesów |
| Dowód zgód (D3) | Art. 6 ust. 1 lit. c/f [PRAWNIK] | Minimalny zapis serwerowy (S3); okres po usunięciu konta: [PRAWNIK] |
| Reklamy / identyfikator reklamowy (F1) | Zgoda | Poza MVP |

## 2. Zgody
- [~] Polityka prywatności i zgody wyświetlane przed logowaniem (US-003, US-001).
- [ ] Zgoda na AI: osobna (N5, ustalone), niezaznaczona domyślnie, wersjonowana, z datą i językiem wyświetlenia; cofnięcie blokuje generowanie (US-003). **Tekst zgody wymienia: dane podróży, preferencje (zainteresowania, budżet, tempo, liczba osób), język, odbiorcę (dostawca AI, region UE), że nie wysyłamy e-maila, nazwy, identyfikatora konta ani lokalizacji, oraz że plan może zawierać błędy.**
- [ ] **Kolejność (ADR-0004/0005, uwagi architekta pkt 2.8):** (1) ekran startowy z informacją o prywatności i linkiem do polityki; checkbox akceptacji niezaznaczony, przycisk logowania nieaktywny do akceptacji (US-003) – wpis tymczasowy lokalnie; (2) logowanie Google; (3) `recordConsent` dla polityki; (4) **zgoda na AI osobno, przy pierwszym generowaniu i w Ustawieniach -> Prywatność** (nie przed logowaniem; US-003 dotyczy przed logowaniem tylko polityki); `generatePlan` sprawdza zgodę po stronie serwera. Sformułowanie akceptacji polityki to potwierdzenie zapoznania, a nie zgoda z art. 6 ust. 1 lit. a [PRAWNIK].
- [ ] **Treść zgody na AI (v0.3, uzupełnienie wg pkt 2.8 architekta):** odbiorca i region (Google Cloud Vertex AI/Gemini, region UE – po potwierdzeniu SEC-15); dane: dane podróży, preferencje, język; **nie wysyłamy** e-maila, nazwy, identyfikatora konta, lokalizacji, numeru lotu; „pośrednik przetwarza dane tylko w pamięci, nie zapisujemy ich ani nie logujemy" – **bez twierdzenia o braku zapisu u dostawcy, dopóki SEC-15 poz. 4 niepotwierdzone**; plan może zawierać błędy; ostrzeżenie, by nie wpisywać pełnego adresu prywatnego ani danych wrażliwych/osób trzecich w polach tekstowych; wycofanie w Ustawieniach działa od zapisu na serwerze (wymaga sieci).
- [ ] Pole noclegu: etykieta „nazwa obiektu lub dzielnica" i podpowiedź, by nie wpisywać prywatnego adresu (wymaganie UI dla Analityka; przegląd 1-3).
- [ ] Zgody i polityka prywatności w **dwóch językach (PL i EN)**: wyświetlane w języku interfejsu, z możliwością przełączenia; zapisany język i wersja zgody; wersje językowe zatwierdzane razem; tłumaczenie EN i rozstrzyganie rozbieżności [PRAWNIK].
- [ ] Preferencje: zainteresowania jako lista predefiniowana (rekomendacja Security, N11 – decyzja właściciela); budżet tylko poziomy; brak pola tekstowego na dane wrażliwe; jeśli pole tekstowe zostanie – ostrzeżenie, limit długości, oczyszczanie. Pozycje listy nie ujawniają religii, zdrowia ani orientacji.
- [ ] Wycofanie zgody równie łatwe jak wyrażenie (Ustawienia -> Prywatność).
- [ ] Ponowna zgoda przy zmianie wersji polityki lub nowym celu (US-003).
- [ ] **[zależy od Q1]** Przy opcji C (link bez `origin`): punkt wypada; zamiast niego w aplikacji krótka informacja przy starcie „moja lokalizacja": „Google Maps może zapytać o Twoją lokalizację; Tamitu jej nie odczytuje"; brak uprawnień lokalizacji, brak wpisu w Data Safety o lokalizacji (do potwierdzenia po teście na urządzeniu). Poniższe dotyczy opcji A.
- [ ] Lokalizacja **dokładna (S6, ustalone; opcja A)**: prośba o uprawnienie dopiero przy wyborze „moja lokalizacja", poprzedzona wyjaśnieniem celu w PL/EN, np.: „Użyjemy Twojej dokładnej pozycji jednorazowo, by wyznaczyć trasę w Google Maps. Nie zapisujemy jej ani nie wysyłamy na nasze serwery; współrzędne trafią do Google Maps wraz z linkiem." Aplikacja działa po odmowie i przy przyznaniu tylko przybliżonej (US-007); tylko pierwszy plan, jednorazowy odczyt, bez zapisu, cache i logów; brak uprawnienia w tle. Uzasadnienie dokładności (trasa od miejsca, w którym stoi użytkownik) – do użycia w deklaracji Play.
- [ ] **Reklamy i identyfikatory reklamowe [PRZYSZŁE, poza MVP]:** przed wdrożeniem AdMob wymagane: certyfikowany CMP (zgody TCF), brak ładowania SDK reklamowego przed zgodą, osobny wybór dla reklam spersonalizowanych, możliwość cofnięcia zgody, deklaracja Advertising ID w Google Play i w manifeście, obsługa ograniczenia śledzenia reklam przez użytkownika, aktualizacja Data Safety i polityki, analiza dla małoletnich (R14), wpis F1 w rejestrze zmieniony na aktywny. Nie dodawać zależności reklamowych do MVP.
- [ ] Brak ciemnych wzorców (przycisk „Odrzuć" równorzędny z „Akceptuj").
- [?] Wiek: aplikacja dla dorosłych (N8), granica wieku zgody w PL do potwierdzenia [PRAWNIK].

## 3. Dane wysyłane do modelu AI
- [ ] Do modelu nie trafiają: UID, e-mail, nazwa, lokalizacja bieżąca, numer lotu, tokeny. Trafiają: dane podróży, preferencje (D15), język planu – tylko po zgodzie na AI.
- [ ] Limity długości i oczyszczanie pól tekstowych; walidacja serwerowa wartości preferencji (zbiory); użytkownik ostrzeżony, by nie wpisywać danych osobowych w pola swobodne.
- [ ] Wariant korporacyjny (np. Vertex AI), region UE, DPA zaakceptowana, potwierdzone, że dane nie służą do trenowania (S5, ustalone jako wymaganie) – potwierdzenie zapisane w ADR. **Warunek blokujący: do czasu potwierdzenia brak prawdziwych danych w AI (tylko dane testowe/syntetyczne); blokuje też testy z realnymi użytkownikami.**
- [ ] Treść promptów i odpowiedzi nie jest logowana ani zapisywana po naszej stronie (wrapper loggera, globalny handler wyjątków bez treści, test z ciągiem kontrolnym – T25).
- [ ] **Vertex AI (ADR-0001):** punkt regionalny `europe-west4`; zakaz `global` i Gemini Developer API; model GA; brak narzędzi/groundingu; potwierdzone warunki SEC-15 poz. 1-6 (+7-12 z `przeglad-adr.md`); decyzja co do buforowania promptów i monitoringu nadużyć (wyłączenie lub świadoma akceptacja właściciela); `ALLOW_REAL_DATA=false` do czasu zamknięcia SEC-15 (procedura przełączenia – SEC-16).
- [ ] Informacja w aplikacji i polityce: kto jest odbiorcą, jakie dane, po co, że plan może zawierać błędy (US-005).
- [ ] Decyzja o dostawcy i architekturze w ADR (pyt. 1, 2); Security recenzuje ADR przed zatwierdzeniem.

## 4. Prawa użytkownika
| Prawo | Realizacja w MVP | Status |
|---|---|---|
| Informacja (art. 13) | Polityka prywatności + skrócona informacja w aplikacji | [~] US-003 |
| Dostęp (art. 15) | Plany i zgody widoczne w aplikacji; dane po stronie chmury (UID, licznik, zapis zgód) – wniosek e-mailem na tamitu@tadecode.pl, bez eksportu w aplikacji (ustalone, N7/S9) | [~] |
| Sprostowanie (art. 16) | Użytkownik sam edytuje dane podróży przez nowy plan; edycja planu poza MVP | [?] |
| Usunięcie (art. 17) | Usunięcie planu (US-009), usunięcie konta i danych w aplikacji (US-010); wymóg Google Play | [~] |
| Ograniczenie, sprzeciw (art. 18, 21) | Wniosek e-mail; sprzeciw wobec lit. f (limity, logi) | [ ] opisać w polityce |
| Przenoszenie (art. 20) | Bez eksportu w aplikacji (ustalone, N7/S9); na wniosek e-mailem – procedura właściciela [PRAWNIK] | [~] |
| Cofnięcie zgody (art. 7 ust. 3) | Ustawienia -> Prywatność | [~] |
| Skarga do organu nadzorczego | Prezes UODO – informacja w polityce | [ ] |
| Termin odpowiedzi | Do 1 miesiąca – procedura właściciela | [ ] [WŁAŚCICIEL] |

## 5. Usunięcie konta (US-010) – punkty kontrolne
- [ ] Dostępne w aplikacji, bez kontaktu z obsługą.
- [ ] Usuwane: użytkownik Firebase Auth, rekordy po UID (licznik, zapisy zgód), dane lokalne (plany, ustawienia, cache).
- [ ] Ponowne uwierzytelnienie, jeśli wymagane; brak sieci = komunikat, bez cichego częściowego usunięcia.
- [ ] Logi: UID tylko jako skrót, bez treści, retencja 30 dni (ustalone, S7); wygasają po usunięciu konta wg retencji – opisane w polityce.
- [ ] Kopie zapasowe chmury (jeśli włączone) – okres wygasania opisany; w MVP brak kopii Firestore, jeśli nie jest potrzebna.
- [ ] Strona z instrukcją usunięcia danych (wymóg Google Play) na `tadecode.pl/tamitu/...` [WŁAŚCICIEL].
- [ ] Test E2E: po usunięciu ponowne logowanie = nowy użytkownik.
- [ ] **Stary token po usunięciu (T24):** wywołanie `recordConsent`/`generatePlan` ze starym tokenem nie tworzy `users/{uid}/consents` ani `usage/{uid}` (test w E2E; SEC-07).
- [ ] Usunięcie obejmuje: `users/{uid}` (rekurencyjnie), `usage/{uid}`, użytkownika Auth, plik bazy konta, ustawienia konta, znacznik „w toku"; po utracie klucza bazy usunięty osierocony plik.
- [ ] Ekran potwierdzenia usunięcia informuje: logi techniczne (UID jako skrót) wygasają w ciągu 30 dni; konto Google i dane w Google Maps/Play – poza Tamitu; plany na urządzeniu znikają razem z kontem.
- [ ] Przy wylogowaniu informacja, że plany zostają na urządzeniu (N3) i jak je usunąć (przegląd 4-3).
- [?] Okres przechowywania minimalnego dowodu zgód po usunięciu konta (S3: zapis serwerowy ustalony; okres) [PRAWNIK].

## 6. Retencja (propozycja do zatwierdzenia)
| Dane | Retencja |
|---|---|
| Konto Auth (D1) | Do usunięcia konta |
| Plany lokalne (D4, D5, D9) | Do usunięcia planu/konta/odinstalowania aplikacji |
| Zgody (D3) | Do usunięcia konta; ewentualnie minimalny dowód dłużej – S3 |
| Licznik użycia (D10) | Jeden dokument `usage/{uid}`, TTL na `expireAt` (= ostatnia aktualizacja + 30 dni; + do ok. 24 h opóźnienia TTL), kasowanie z kontem. TTL niewdrożony do O4-2. Decyzja O4-b: docelowo `resetAt` + 2 dni (rejestr D10) |
| Logi (D11) | 30 dni, własny kubełek w UE, bez treści, UID jako HMAC (ustalone, S7); logi audytu administracyjnego 400 dni bez danych użytkowników; adres IP w logach żądań |
| Zgody (D3) po usunięciu konta | Q9: domyślnie 0 (usuwane z kontem); archiwum tylko po decyzji [PRAWNIK] |
| Zapytania do AI | Po naszej stronie 0; po stronie dostawcy – S5 |
| Lokalizacja (D7) | 0 (nieutrwalana) |
| Preferencje i język (D15, D16) | Jak plany lokalne; po naszej stronie 0 |
| Kontakt/wnioski (D14) | Czas obsługi + okres przedawnienia [PRAWNIK]; skrzynka tamitu@tadecode.pl (S8) |

## 7. Podmioty przetwarzające i transfery
- [ ] Zaakceptowane warunki przetwarzania danych Google Cloud/Firebase (DPA) na koncie firmowym TadeCode [WŁAŚCICIEL].
- [ ] Dostawca AI: DPA, region UE, brak trenowania (S5).
- [ ] Potwierdzona lokalizacja danych Firebase Auth i innych usług (S2); jeśli transfer poza UE – podstawa (DPF/SCC wg Google) opisana w polityce.
- [ ] Google Maps i Google Play wskazane jako odrębni administratorzy/odbiorcy w polityce.
- [ ] Lista podmiotów aktualizowana przy każdej nowej usłudze (rejestr D/F).
- [ ] Dodatkowe punkty weryfikacji w SEC-10: Vertex AI (model docelowy), Error Reporting, App Check/Play Integrity (D17), Secret Manager, Pub/Sub; Firebase Auth (możliwy brak regionu UE).
- [ ] Kubełek logów: sink do kubełka UE i wykluczenie z `_Default` potwierdzone testem; Data Access audit logs wyłączone dla Vertex/Firestore.
- [ ] Konta usług z minimalnymi rolami (T28); dostęp do konsoli tylko właściciel z 2FA; procedura zmiany `config/runtime` (SEC-16).

## 8. Zgodność ze sklepem Google Play
- [ ] Formularz Data Safety spójny z rejestrem. Wstępne ustalenia do weryfikacji wg aktualnych zasad Google Play [WŁAŚCICIEL/PRAWNIK]:
  - **Dokładna lokalizacja (D7):** zadeklarować użycie uprawnienia precyzyjnej lokalizacji; cel: funkcjonalność aplikacji (trasa); niezapisywana, nieprzekazywana na nasze serwery. Czy współrzędne przekazane do Google Maps przez link liczą się jako „udostępnienie/zbieranie" – do potwierdzenia w aktualnych wytycznych Play i zadeklarować ostrożnie (rekomendacja: ujawnić przekazanie do Google Maps w polityce).
  - **Identyfikatory i dane osobowe:** konto Google (UID, e-mail przez Firebase Auth), identyfikator użytkownika; zgody i licznik (D3, D10).
  - **Inne dane wysyłane do AI (D6, D15):** dane podróży i preferencje (informacje o podróży/upodobaniach; budżet jako poziom) – wysyłane do przetwarzającego (dostawca AI) w celu funkcji aplikacji, za zgodą; sprawdzić właściwe kategorie w formularzu.
  - **[zależy od Q1]** Przy opcji C brak deklaracji lokalizacji i uprawnienia `ACCESS_FINE/COARSE_LOCATION`; przy A – jak wyżej. Dodatkowo do oceny: dane urządzenia przetwarzane przez Play Integrity/App Check (D17) – sprawdzić, czy wymagają ujawnienia w Data Safety (rekomendacja: ujawnić ostrożnie, potwierdzić w aktualnych zasadach Play).
  - Szyfrowanie danych w spoczynku na urządzeniu: tak (SQLCipher) – Data Safety dotyczy danych przesyłanych poza urządzenie, więc to deklaracja pomocnicza.
  - Brak sprzedaży danych, brak reklam i Advertising ID w MVP, szyfrowanie w tranzycie (HTTPS), możliwość usunięcia konta i danych (US-010, strona z instrukcją).
- [ ] Link do polityki prywatności w sklepie i w aplikacji (polityka PL i EN).
- [ ] Deklaracja uprawnień: dokładna lokalizacja tylko na pierwszym planie (bez `ACCESS_BACKGROUND_LOCATION`); uzasadnienie: trasa startuje z faktycznej pozycji użytkownika; opis w sklepie i w aplikacji zgodny z faktyczną funkcją. Sprawdzić zmergowany manifest (biblioteki).
- [ ] Deklaracja Advertising ID (po wdrożeniu reklam: „tak"; w MVP: „nie używa").
- [ ] Wymagania konta organizacji i testów zamkniętych – prowadzi właściciel (R8).

## 9. Ocena skutków (DPIA)
- Ustalenie właściciela (S11): w MVP raczej nie; ocena przy rozszerzeniach [PRAWNIK]. Uwaga Security: MVP ma teraz dokładną lokalizację (jednorazową, bez zapisu) i preferencje wysyłane do AI – nadal brak zapisu centralnego, śledzenia i profilowania na dużą skalę, ale [PRAWNIK] powinien to uwzględnić przy potwierdzeniu. Przed dodaniem zdjęć, reklam, lokalizacji w tle lub synchronizacji w chmurze – ponowna ocena.

## 10. Polityka prywatności – szkic treści (dla właściciela)
Docelowy adres: `tadecode.pl/tamitu/prywatnosc` (musi być publiczny przed testami zewnętrznymi). **Wersje PL i EN** (np. `/pl` i `/en` lub przełącznik) publikowane razem; poniżej szkic w PL, wersję EN przygotować równolegle (tłumaczenie prawne [PRAWNIK]). Szkic wymaga uzupełnienia pól w nawiasach `[...]` i weryfikacji prawnika.

1. **Administrator:** [pełna nazwa działalności TadeCode, adres, NIP – **uzupełnia właściciel (S1)**]; kontakt: tamitu@tadecode.pl. Inspektor ochrony danych: nie wyznaczono (ustalone, S1) [PRAWNIK potwierdza, że nie jest wymagany].
2. **Jakie dane przetwarzamy i po co:**
   - konto (identyfikator, e-mail, nazwa z konta Google) – logowanie, utrzymanie sesji;
   - dane podróży (cel, daty, nocleg, godzina i lotnisko przylotu/przyjazdu) – ułożenie planu; w MVP zapisywane tylko na Twoim urządzeniu;
   - preferencje podróży (zainteresowania, budżet, tempo zwiedzania, liczba osób) i język planu – dopasowanie planu; zapisywane na Twoim urządzeniu; wysyłane do AI razem z danymi podróży, za Twoją zgodą;
   - zgody (rodzaj, wersja, język, data) – wykazanie, że je wyraziłeś; zapisujemy minimalny rekord (identyfikator konta, wersja, wartość, data) także na serwerze;
   - licznik użycia i logi techniczne (bez treści formularza; identyfikator konta w postaci skrótu; przechowywane 30 dni) – limity kosztowe, bezpieczeństwo;
   - lokalizacja dokładna – tylko gdy wybierzesz „moja lokalizacja"; odczytujemy ją jednorazowo, nie zapisujemy i nie wysyłamy na nasze serwery ani do AI; współrzędne trafiają do Google Maps (odrębny administrator) w linku trasy.
3. **Przekazanie do modelu AI:** dane podróży i preferencje (bez Twojego e-maila, nazwy, identyfikatora konta, lokalizacji i numeru lotu) są przekazywane przez nasz serwer pośredniczący (przetwarza je w pamięci, nie zapisuje i nie loguje) do [Google Cloud Vertex AI / Gemini, region UE – po potwierdzeniu SEC-15] w celu wygenerowania planu, na podstawie Twojej zgody; [informacja o braku trenowania na danych, DPA oraz o ewentualnym krótkotrwałym buforowaniu/monitoringu nadużyć u dostawcy i jego okresie – po potwierdzeniu S5/SEC-15]. Nie wpisuj pełnego adresu prywatnego noclegu. Nie wpisuj w pola formularza danych wrażliwych ani danych innych osób. Plan może zawierać błędy.
4. **Podstawy prawne:** wykonanie umowy (art. 6 ust. 1 lit. b), zgoda (lit. a) dla AI i lokalizacji, uzasadniony interes (lit. f) dla limitów i logów – [do potwierdzenia przez prawnika].
5. **Odbiorcy:** Google (Firebase, Google Cloud – podmiot przetwarzający), [dostawca AI], Google Maps i Google Play (odrębni administratorzy). Nie sprzedajemy danych. [W przyszłości: reklamodawcy po zgodzie.]
6. **Transfery poza EOG:** [opis wg S2/SEC-10 i warunków Google; Firebase Authentication nie ma wyboru regionu – możliwe przetwarzanie poza UE]. Dane aplikacji (zgody, licznik, logi) przechowujemy w regionie UE (`europe-west4`, Holandia) [do potwierdzenia].
6a. **Logi i infrastruktura:** logi techniczne (bez treści formularza; identyfikator konta w postaci skrótu; adres IP w logach żądań) 30 dni w UE; logi administracyjne konta Google Cloud do 400 dni (bez danych użytkowników); ochrona przed nadużyciami (Firebase App Check / Google Play Integrity) [opis po SEC-10].
6b. **Przechowywanie na urządzeniu:** plany i preferencje w zaszyfrowanej bazie lokalnej; kopia zapasowa Androida wyłączona (utrata telefonu = utrata planów); plany zostają na urządzeniu po wylogowaniu do czasu usunięcia planu/konta lub odinstalowania.
7. **Okres przechowywania:** wg tabeli w pkt 6 listy (logi 30 dni; po usunięciu konta zapis zgód: [okres wg prawnika]).
8. **Twoje prawa:** dostęp, sprostowanie, usunięcie, ograniczenie, sprzeciw, przenoszenie (jeśli dotyczy), cofnięcie zgody w każdej chwili; skarga do Prezesa UODO. Jak skorzystać: w aplikacji (Ustawienia -> Prywatność, Usuń konto) lub e-mailem na tamitu@tadecode.pl (dostęp do danych na wniosek; nie ma eksportu w aplikacji).
9. **Usunięcie konta:** w aplikacji (Ustawienia -> Usuń konto) oraz instrukcja na stronie [adres].
10. **Bezpieczeństwo:** szyfrowane połączenia, brak haseł, ograniczone uprawnienia, limity.
11. **Dzieci:** aplikacja przeznaczona dla osób dorosłych (N8, S12) [PRAWNIK].
12. **Reklamy i identyfikatory reklamowe:** [sekcja do dodania przed wprowadzeniem reklam: dostawca, cel, zgoda, jak ją cofnąć].
13. **Zmiany polityki:** wersjonowanie, data obowiązywania, ponowna zgoda przy istotnych zmianach.

## 11. Pytania wymagające potwierdzenia
Wszystkie S1..S12 odpowiedziane (`docs/open-questions.md`). Nadal wymagane:
- [WŁAŚCICIEL, G2] Q1 (lokalizacja A/C – rekomendacja Security: C po teście na urządzeniu), Q2 (App Check a dystrybucja testów), Q9 [PRAWNIK] (dowód zgód po usunięciu konta); szczegóły: `przeglad-adr.md`.
- [WŁAŚCICIEL] dane administratora (nazwa, adres, NIP) – blokuje publikację polityki i testy zewnętrzne (S1).
- [WŁAŚCICIEL] potwierdzenie warunków dostawcy AI w ADR – blokuje realne dane w AI (S5).
- [WŁAŚCICIEL] odpowiedź na N11 (lista zainteresowań, formaty preferencji, język planu).
- [PRAWNIK] okres dowodu zgód po usunięciu konta (S3), regulamin przed wydaniem publicznym (S10), DPIA (S11), lit. f dla logów/licznika i granica wieku (S12), ocena budżetu i zainteresowań jako danych, tłumaczenie EN, Data Safety dla lokalizacji.
- Security (faza 2): weryfikacja lokalizacji przetwarzania Firebase i transferów (S2, SEC-10).
