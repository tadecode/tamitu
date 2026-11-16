# Przegląd ekranów EK-01..EK-16 przez architekta (P3-14c)

- Data: 2026-11-16 · Autor (rola): architect · Wersja: 1.0
- Zakres: `docs/ux/screens/ek-01..16.md`, `docs/ux/design-system.md` (pkt 8, 8.1), `components/`, `patterns.md`, `flows.md` względem ADR-0001..0009, `docs/api/`, `docs/data/`, `docs/architecture/`.
- Poza zakresem: ocena zgód i prywatności (równoległy przegląd security), treść prawna [PRAWNIK], kolorystyka (UX16).
- Wynik w ADR: **ADR-0010** (ikony Hugeicons, proponowany), **ADR-0011** (doprecyzowania po przeglądzie, w tym SEC-24, proponowany). Zatwierdzone ADR-0001..0009 bez zmian.

## 1. Werdykt zbiorczy
**Ekrany są wykonalne na obecnej architekturze. Żaden nie wymaga nowej funkcji serwera, nowego magazynu danych ani nowego uprawnienia; żaden nie zwiększa kosztów.** Wymagane:
- **7 ekranów do poprawy w UX** (EK-01, EK-03, EK-06, EK-09, EK-12, EK-13, EK-16) – dwie poprawki są **zgodnością z zatwierdzonymi ADR** (EK-01 stan U12 vs ADR-0005 Aneks A pkt 2; EK-13 wycofanie zgody offline vs ADR-0002 Aneks A pkt 4), reszta to brakujące stany i źródła danych;
- **3 ekrany zależne od doprecyzowania kontraktu** (EK-01, EK-05, EK-15) – ADR-0011 i projekt zmian `posrednik-api.md` pkt 7 (v0.3), do zatwierdzenia przez właściciela;
- **9 ekranów OK** (EK-02, EK-04, EK-07, EK-08, EK-10, EK-11, EK-14 bez zastrzeżeń; EK-05, EK-15 z uwagami dla mobile-dev).

| Ekran | Werdykt | Główny powód |
|---|---|---|
| EK-01 Start | **do poprawy w UX + ADR-0011** | wersja polityki nieczytelna dla klienta; stan U12 sprzeczny z ADR-0005; brak stanów przerwanego usuwania konta |
| EK-02 Ekran startowy | OK (uwagi mobile-dev) | `consentId` w tymczasowym wpisie; „Brak sieci" po próbie |
| EK-03 Ponowna akceptacja | **do poprawy w UX** | źródło daty wersji; wariant treści po wyczyszczeniu bazy |
| EK-04 Lista planów | OK | – |
| EK-05 Formularz | OK, **zmiana API (ADR-0011 pkt 3)** | tolerancja daty przylotu po stronie serwera |
| EK-06 Zgoda na AI | **do poprawy w UX** (drobna) | tekst „wycofanie wymaga internetu" sprzeczny z ADR-0002 Aneks A pkt 4 |
| EK-07 Generowanie | OK | U6 potwierdzone; anulowanie = porzucenie wyniku |
| EK-08 Widok planu | OK | – |
| EK-09 Wybór trasy | **do poprawy w UX** (drobna) | brak detektora sieci – nie blokować otwarcia Maps |
| EK-10 Prośba o lokalizację | OK | – |
| EK-11 Usunięcie planu | OK | UX9: dialog |
| EK-12 Ustawienia | **do poprawy w UX** | brak wejścia „Licencje open source" (warunek MIT, ADR-0010) |
| EK-13 Prywatność | **do poprawy w UX** | wycofanie zgody offline: stan „oczekuje na połączenie" (ADR-0002 Aneks A pkt 4) |
| EK-14 Wylogowanie | OK | U8 potwierdzone |
| EK-15 Usunięcie konta | OK, **zmiana API (ADR-0011 pkt 4, 8)** | zawsze ponowne logowanie przed `deleteAccount`; usuwanie bez blokady wersji |
| EK-16 Katalog komunikatów | **do poprawy w UX** | brakujące mapowania (błąd transportu, pętla zgody, `reauth_required`) |

## 2. Ustalenia przekrojowe
**P-1. Brak detektora sieci (EK-02, 03, 05, 06, 09, 13, 15, 16).** Ekrany zakładają stan „Stan sieci: system". ADR-0008 nie ma pakietu łączności, a `connectivity_plus` dodałby `ACCESS_NETWORK_STATE` (test manifestu dopuszcza dziś tylko `INTERNET`). Decyzja (ADR-0011 pkt 2): brak sieci wykrywany z wyniku wywołania; stany „Brak sieci" pokazywane **po próbie**. Większość specyfikacji już tak robi („po dotknięciu"); do poprawy: EK-02 (stan „Brak sieci" jako komunikat z wyprzedzeniem) i EK-09 (blokowanie Maps). Uwaga dla P3-04: jeśli SDK Firebase/Google same dodadzą `ACCESS_NETWORK_STATE` do zmergowanego manifestu, test manifestu trzeba zaktualizować świadomie (wpis Security), ale decyzja o braku pakietu łączności się nie zmienia.

**P-2. `config/runtime` jest niedostępne dla klienta (EK-01, EK-03).** Firestore `deny all`, brak funkcji odczytu. Wersja i data polityki = stałe w aplikacji (ADR-0011 pkt 1). Sprawdzenie w EK-01 działa offline – pytanie „zachowanie offline" z EK-01 znika.

**P-3. Zgody: kolejność i ponowienia (EK-02, EK-06, EK-13).** Potwierdzam propozycję ux z EK-02: zapis tymczasowy → logowanie → `recordConsent(privacy_policy)` z ponowieniem w tle (idempotentne po `consentId`, który trzeba dopisać do wpisu tymczasowego – ADR-0011 pkt 10). Odmowa przy pierwszym pytaniu o AI (EK-06) **może nie tworzyć rekordu** – serwer sprawdza ostatni rekord `ai_processing`, brak rekordu = brak zgody (decyzja formalna: security). Wycofanie po wcześniejszej zgodzie zawsze tworzy rekord `granted=false`. Daty w EK-13: z `consents_local.client_at` (czas urządzenia w chwili decyzji) – wystarczające do wyświetlenia; `receivedAt` z serwera nie jest potrzebny w UI.

**P-4. Wycofanie zgody AI bez sieci (EK-13, EK-06) – niezgodność z ADR.** ADR-0002 Aneks A pkt 4 (normatywny): bez sieci aplikacja **blokuje generowanie lokalnie od razu** i informuje, że wycofanie zostanie dokończone po odzyskaniu połączenia; stan „wycofano" dopiero po potwierdzeniu serwera (`synced=1`). EK-13 w obecnej wersji odrzuca wycofanie offline („Zgoda pozostaje bez zmian"), a EK-06 mówi „wymaga internetu". Do poprawy w UX: stan EK-13 „Wycofanie oczekuje na połączenie" (generowanie zablokowane, EK-05 pokazuje `tripFormConsentWithdrawn`), teksty `privacyAiOffline` i `aiConsentWithdraw`. Alternatywa (zostawić odrzucenie offline) wymagałaby nowego ADR zastępującego pkt 4 Aneksu – nie rekomenduję (wycofanie powinno być co najmniej tak łatwe jak wyrażenie zgody).

**P-5. Utrata klucza bazy (EK-01, U12) – niezgodność z ADR.** ADR-0005 (Decyzja pkt 1 i Aneks A pkt 2): brak klucza → **usunięcie nieczytelnego pliku, nowa pusta baza, komunikat**. EK-01 proponuje stan blokujący z „Wyloguj / Usuń konto", który zostawia nieczytelny plik i blokuje aplikację. Rekomendacja (ADR-0011 pkt 9): zgodnie z ADR – jednorazowy komunikat (np. dialog „Nie mogliśmy odczytać zapisanych planów i zostały usunięte z tego urządzenia…"), potem EK-03 w wariancie „dane wyczyszczone" (lokalny dowód akceptacji przepadł), następnie EK-04 w stanie pustym. Tekst `startDataUnavailableBody` wspomina „przywrócenie z kopii" – kopia jest wyłączona (`allowBackup=false`); typowe przyczyny to unieważnienie Keystore (zmiana blokady ekranu na niektórych urządzeniach, aktualizacja systemu). Inne błędy otwarcia bazy przy obecnym kluczu → stan błędu EK-04 z ponowieniem (już jest).

**P-6. Przerwane usunięcie konta (EK-01, EK-15).** Znacznik „w toku" nie mówi, czy serwer zdążył usunąć konto. Rozstrzygnięcie w ADR-0011 pkt 8 (`currentUser.reload()`): konto usunięte → czyszczenie lokalne; konto istnieje → wybór „Dokończ usuwanie" / „Anuluj usuwanie"; brak sieci → stan blokujący z ponowieniem. EK-01 potrzebuje tych dwóch stanów. Teksty EK-15: kolejność „serwer, potem lokalnie" potwierdzona (ADR-0004) – `deleteAccountError` („dane na tym urządzeniu nienaruszone") jest prawdziwy, bo pliki lokalne kasujemy dopiero po sukcesie serwera.

**P-7. Generowanie: tło, zabicie procesu, anulowanie (EK-05, EK-07; U6, Q12).** `HttpsCallable.call` nie ma przerwania żądania. Anulowanie = porzucenie wyniku po stronie klienta (odpowiedź z tym `requestId` jest ignorowana i niczego nie zapisujemy); serwer kończy żądanie i slot jest zużyty, jeśli model ruszył – zgodne z Q12 i tekstem `generationCancelBody`. Wynik musi zapisywać kontroler poza drzewem widgetów (np. notifier Riverpod o czasie życia aplikacji), aby po powrocie z tła plan był już w bazie. Po zabiciu procesu nic nie zapisano (serwer nie przechowuje planu – ADR-0002 „brak cache"), slot mógł zostać zużyty – teksty EK-07/EK-16 to mówią. Koszt: bez zmian (każda próba = 1 slot, już w `costs.md`).

**P-8. Sesja (EK-01, EK-16).** Sesja SDK działa offline (US-001), więc EK-01 → EK-04 bez sieci jest poprawne. `unauthenticated` z dowolnej funkcji (konto usunięte na innym urządzeniu, unieważnione tokeny) → lokalne `signOut` (plany zostają, N3) → EK-02 z `errorSessionExpired` – mapowanie w EK-16 poprawne. To samo, gdy strumień `idTokenChanges` zgłosi brak użytkownika.

**P-9. Limit (EK-05, EK-07, EK-08; U4).** `limit_exceeded.details.resetAt` (UTC) → czas lokalny urządzenia; tekst „od jutra, od {time}" poprawny tylko, gdy reset wypada jutro w strefie urządzenia – mobile-dev formatuje datę względną (dziś/jutro) wg `intl`. `quota.remainingToday` tylko po sukcesie, przekazane do EK-08 w pamięci (bez zapisu). Brak dodatkowego wywołania = brak kosztu.

**P-10. Ikony (design-system pkt 8, 8.1).** Rozstrzygnięte w ADR-0010: pakiet `hugeicons` 4.4.0 (MIT, tylko Stroke Rounded, SVG przez `flutter_svg`) za widgetem `AppIcon`; podmiany z pkt 8.1 wykonalne parametrami typu `Widget` (`ActionIconThemeData.backButtonIconBuilder`, `DropdownMenu.trailingIcon`, `SegmentedButton.selectedIcon`, `PopupMenuButton.icon`); wyjątki jak u ux. Warunek: pomiar APK w P3-04 (próg +1,0 MB, plan B: własna czcionka z ikon Free) i ekran licencji (EK-12).

**P-11. Walidacja pól (EK-05).** Zbiór dozwolonych znaków i długości z `docs/data/model-danych.md` pkt 1 stosuje aplikacja (komunikat `commonFieldCharsError`); serwer dziś sprawdza długość i znaki sterujące (rozszerzenie NFC/Cf – SEC-21). Klient jest ostrzejszy niż serwer, więc poprawny formularz nie dostanie `invalid_argument`. Długość liczona w jednostkach UTF-16 po NFC (tak samo w Dart i TypeScript). Data przylotu: ADR-0011 pkt 3 (serwer „dziś − 2 dni" Warsaw, klient „wczoraj" w strefie urządzenia).

**P-12. Koszty (CLAUDE.md pkt 10).** Żaden ekran nie dodaje wywołania AI ani funkcji. Dodatkowe operacje: `recordConsent` przy logowaniu, zgodzie i ponownej akceptacji; `reload()` przy przerwanym usuwaniu – wszystko w darmowych pulach Firestore/Auth. Ikony: tylko rozmiar APK (ADR-0010). `docs/architecture/costs.md` bez zmian.

## 3. Ekrany – „Dane na ekranie" i uwagi
Format: pole → źródło → czy model/API dostarcza. Pola potwierdzone bez uwag pominięto w opisie, jeśli tabela ekranu jest kompletna.

### EK-01 Start – do poprawy w UX + ADR-0011
| Pole | Źródło | Dostarcza? | Uwagi |
|---|---|---|---|
| Stan sesji | Firebase Auth SDK | tak | offline OK |
| Aktualna wersja polityki | ~~`config/runtime.policyVersionCurrent`~~ → stała aplikacji `privacyPolicyVersion` vs `consents_local` | **nie (klient nie czyta Firestore)** | ADR-0011 pkt 1; działa offline |
| Znacznik „usuwanie w toku" | `flutter_secure_storage` | tak | + `reload()` (ADR-0011 pkt 8) |
| Dostępność bazy | SQLCipher | tak | zachowanie wg ADR-0005 Aneks A pkt 2, nie stan blokujący |
Odpowiedzi na „Uzgodnienie z architektem": offline – sprawdzenie wersji jest lokalne; „Wyloguj w U12 a osierocony plik" – nieaktualne, bo nieczytelny plik usuwa aplikacja (ADR-0005).

### EK-02 Ekran startowy – OK
Dane kompletne. Kolejność zapisu zgody potwierdzona (P-3); błąd `recordConsent` po udanym logowaniu → ponowienie w tle, bez blokowania EK-04. Każde ponowne logowanie po wylogowaniu tworzy nowy rekord `privacy_policy` (historia „tylko dopisywanie", ADR-0005) – akceptowalne. Stan „Brak sieci" – pokazać po nieudanej próbie logowania (`network-request-failed`), nie z wyprzedzeniem (P-1).

### EK-03 Ponowna akceptacja – do poprawy w UX
| Pole | Źródło | Dostarcza? | Uwagi |
|---|---|---|---|
| Data nowej wersji | ~~`config/runtime`~~ → stała aplikacji `privacyPolicyDate` | tylko jako stała | ADR-0011 pkt 1 |
| Akceptacja | `recordConsent(privacy_policy, nowa wersja)` | tak | wymaga sieci (U2) |
Dodać wariant treści `reconsentBodyDataReset` dla wejścia po wyczyszczeniu bazy (P-5). „Nowy cel przetwarzania" (US-003): ten sam ekran, inna treść – OK, wersja polityki i tak się zmienia.

### EK-04 Lista planów – OK
Wszystkie pola w `trips`; `ORDER BY created_at DESC`; paginacja zbędna (U13: brak limitu, zapytanie lokalne, rząd dziesiątek planów; przy setkach – `ListView.builder` wystarcza).

### EK-05 Formularz – OK, zmiana API (ADR-0011 pkt 3)
Pola 1:1 z `generate-plan.request.schema.json` i tabelą `trips`; `flightNumber` tylko lokalnie (zgodne z D5 i kontraktem – brak pola w żądaniu). Odpowiedzi: (1) znaki i limity – P-11; (2) data „od wczoraj" w strefie urządzenia – tak, a serwer dostaje tolerancję − 2 dni (ADR-0011 pkt 3); (3) sprawdzenie sieci – reaktywne (P-1); nieudane połączenie nie zużywa limitu. Stan „Błąd generowania – limit zwrócony" poprawny tylko dla `ai_unavailable`/`ai_invalid_response` (tak jest w EK-16).

### EK-06 Zgoda na AI – do poprawy w UX (drobna)
Dane: treść `ai-consent-v1` (ARB), decyzja → `recordConsent`. Odpowiedzi: odmowa przy pierwszym pytaniu bez rekordu – technicznie poprawne (P-3); `consent_required` z serwera → ten sam ekran, **chyba że** rekord w wersji aplikacji jest już zsynchronizowany – wtedy „Zaktualizuj aplikację" (ADR-0011 pkt 7, bez pętli). Wyrażenie zgody wymaga sieci – poprawne (serwer i tak sprawdza zgodę przed generowaniem). Do poprawy: w `aiConsentWithdraw` usunąć „(wymaga internetu)" lub zastąpić zgodnym z P-4. Odbiorca „Vertex AI, UE" – stała po SEC-15 (bez zmian).

### EK-07 Generowanie – OK
Dane: cel i liczba dni z pamięci formularza; wynik z `generatePlan`. U4/U6 – P-7, P-9. Timeout klienta 120 s zgodny z kontraktem. Zapis planu (trip + dni + punkty) w jednej transakcji po walidacji klienta (liczba dni, `dayNumber`) – kontrakt już to gwarantuje, klient sprawdza obronnie.

### EK-08 Widok planu – OK
Wszystkie pola w `trips`, `plan_days`, `plan_items`. Numer lotu – pokazywanie lokalne zgodne z D5 (nie opuszcza urządzenia; ekran z planem nie trafia do Maps). `quota` w snackbarze – tylko po EK-07 (P-9). Dzień bez punktów (`items: []`) dopuszczony przez schemat – stan `planDayOnlyArrival` poprawny.

### EK-09 Wybór trasy – do poprawy w UX (drobna)
Pola zgodne z `zewnetrzne-integracje.md` pkt 1: `destination` = „{name}, {locality}, {trip.destination}"; start „Nocleg" = „{lodging}, {trip.destination}"; „Poprzedni punkt" = tekst poprzedniego punktu; „Moja lokalizacja" = `lat,lng` tylko w zmiennej lokalnej (ADR-0007). Domyślny tryb (UX11, komunikacja) – bez wpływu na architekturę. Punkt bez rozpoznanej lokalizacji – zapytanie tekstowe, Maps samo wyszukuje (bez zmiany UI). Do poprawy: stan „Brak sieci" – nie blokować i nie wykrywać z wyprzedzeniem; otworzyć link, a przy błędzie uruchomienia `routeOpenError` (P-1). „Tylko przybliżona" → start z planu (zgodne z ADR-0007). Anulowanie odczytu pozycji = porzucenie wyniku `getCurrentPosition` (limit 10 s).

### EK-10 Prośba o lokalizację – OK
„Tylko tym razem" = uprawnienie przyznane na sesję – odczyt jak przy przyznaniu; przy kolejnym uruchomieniu system zapyta ponownie (EK-10 pokazywany ponownie, gdy `shouldShowRequestPermissionRationale`/stan „denied" pozwala pytać). Przy wariancie C ekran znika (U11) – bez wpływu na dane.

### EK-11 Usunięcie planu – OK
`DELETE trips` z kaskadą w jednej transakcji. UX9 – dialog (sekcja 4).

### EK-12 Ustawienia – do poprawy w UX
Język – `shared_preferences`; e-mail – nie pokazujemy (UX12, sekcja 4). Wersja aplikacji – stała kompilacji (bez nowego pakietu: wartość z `pubspec.yaml` przekazana `--dart-define` w CI; ewentualnie `package_info_plus` po przeglądzie wg ADR-0008). Do dodania: wiersz **„Licencje open source"** → `showLicensePage` (warunek licencji MIT Hugeicons, ADR-0010 pkt 6; dobra praktyka dla wszystkich zależności).

### EK-13 Prywatność – do poprawy w UX
Dane: stan i data zgody AI oraz akceptacji polityki z `consents_local` (`client_at`, `policy_version`) – dostępne; po wyczyszczeniu bazy stan „Nie wyrażono" (P-5). Kontakt – stała. Do poprawy: wycofanie offline (P-4) – nowy stan „Wycofanie oczekuje na połączenie" zamiast odrzucenia; ponowienie zapisu przy następnym starcie/powrocie sieci (pole `synced`).

### EK-14 Wylogowanie – OK
U8 potwierdzone: wylogowanie lokalne (`GoogleSignIn.signOut`, `FirebaseAuth.signOut`, zamknięcie bazy) działa offline; niedostępne w trakcie generowania (EK-07 modalny). Oczekujące rekordy zgód (`synced=0`) zostają w bazie konta i zostaną wysłane po ponownym zalogowaniu tym kontem.

### EK-15 Usunięcie konta – OK, zmiana API (ADR-0011 pkt 4, 8)
Kolejność: znacznik → ponowne logowanie Google (zawsze, z wyprzedzeniem) → `deleteAccount` → usunięcie pliku bazy, wpisów `shared_preferences`, klucza (gdy brak innych baz), znacznika → `signOut` → EK-02. `reauth_required` nadal obsługiwane (np. gdy logowanie trwało > 5 min). `deleteAccount` nie zwróci `unsupported_version` ani nie wymaga dostawcy (ADR-0011 pkt 4). Wejście z EK-01 (U12) znika (P-5); dochodzi wejście „Dokończ usuwanie" z EK-01 (P-6). UX13 – decyzja security/właściciela, bez wpływu technicznego.

### EK-16 Katalog komunikatów – do poprawy w UX
Mapowanie kodów zgodne z kontraktem. Dodać/doprecyzować:
| Sytuacja | Rekomendacja |
|---|---|
| `unavailable` bez `details.code`, `network-request-failed` | „brak sieci" (klient) – P-1 |
| `deadline-exceeded` | `errorTimeoutBody` (już jest) |
| `consent_required` przy zsynchronizowanej zgodzie w wersji aplikacji | `errorUpdateTitle`/`errorUpdateBody` (bez pętli do EK-06) |
| `unsupported_version` | blokuje tylko funkcje sieciowe (generowanie, zgody); **nie** usuwanie konta; przycisk otwiera Google Play (`https://play.google.com/store/apps/details?id=pl.tadecode.tamitu` przez `url_launcher`, bez pakietu aktualizacji w aplikacji) – U3 |
| `test_data_only` | `errorUnavailableForAccountBody` – U3 (bez ujawniania przyczyny) |
| `reauth_required` | EK-15 ponawia logowanie; po anulowaniu `deleteAccountReauthCancelled` |
| `app_check_failed` | jak `internal` (zgodnie z EK-16); w kanale testowym przyczyną bywa APK spoza Google Play – opis dla testerów w README, nie w aplikacji |

## 4. Odpowiedzi na pytania do architekta (wpisane też w `docs/open-questions.md`)
| # | Odpowiedź |
|---|---|
| UX5 | Nieaktualne (wariant A). Gdyby wróciło: czcionka jako zasób aplikacji – technicznie OK. |
| UX9 | **Dialog** (bez zmiany modelu danych). „Cofnij" wymagałby odroczonego usunięcia (kolumna/stan „do usunięcia" lub opóźniona transakcja) i obsługi zabicia procesu w oknie 10 s – większa złożoność, sprzeczność z „trwałym usunięciem" US-009. Do rozważenia po MVP. |
| UX12 | **Nie pokazywać e-maila.** ADR-0004: e-mail i nazwa z SDK „nie są zapisywane, logowane ani wyświetlane" – pokazanie (nawet bez zapisu) wymagałoby nowego ADR i oceny security. Plany są per konto, a wybór konta odbywa się w oknie Google – w MVP wystarczy. |
| UX15 | Rekomendacja: **pakiet `hugeicons` (MIT, tylko Stroke Rounded, SVG przez `flutter_svg`) za widgetem `AppIcon`**, podmiany z pkt 8.1 wykonalne, wyjątki jak u ux; warunki: pomiar APK (≤ +1,0 MB, inaczej własna czcionka z ikon Free), sprawdzenie braku Pro w pakiecie, ekran licencji z obiema notami MIT. ADR-0010 (proponowany). |
| U3 | (a) `unsupported_version`: komunikat blokujący funkcje sieciowe + przycisk do Google Play; plany offline dostępne; usuwanie konta nigdy nieblokowane (ADR-0011 pkt 4). (b) `test_data_only`: „Tworzenie planów jest chwilowo niedostępne" – akceptuję propozycję. |
| U4 | Akceptuję propozycję: tylko po sukcesie i w komunikacie limitu; bez dodatkowego wywołania (koszt 0). |
| U6 | Akceptuję z doprecyzowaniem: wywołanie trwa w tle do 120 s, wynik zapisuje kontroler aplikacji; po zabiciu procesu nic nie zapisano, slot mógł zostać zużyty; anulowanie = porzucenie wyniku. „Sprawdzenie sieci przed wysłaniem" bez pakietu: nieudane połączenie nie dociera do serwera, więc nie zużywa limitu (ADR-0011 pkt 2). |
| U8 | Akceptuję propozycję: niedostępne w trakcie generowania, działa offline (operacja lokalna). |
| U12 | Zgodnie z ADR-0005 Aneks A pkt 2: **nie** stan blokujący – aplikacja usuwa nieczytelny plik, zakłada pustą bazę, pokazuje jednorazowy komunikat, potem EK-03 (wariant „dane wyczyszczone") i EK-04. Zmiana na stan blokujący wymagałaby nowego ADR – nie rekomenduję. |
| SEC-24 | (1) **Tak: odmowa startu dla `dev` + `ALLOW_REAL_DATA=true`**, a w `dev` `config/runtime.allowRealData` ignorowane – `dev` przyjmuje tylko `testData=true` z `testUids` (testerzy `dev` dopisani do `testUids` projektu `dev`). (2) **`deleteAccount` celowo bez `requireGoogleProvider`** – usuwa tylko konto z tokenu, a ograniczenie mogłoby zablokować prawo do usunięcia po dodaniu dostawcy; udokumentować komentarzem i testem. ADR-0011 pkt 4–5; decyzja właściciela. |

## 5. Zadania
### Dla ux (poprawki przed `ux-ready`)
1. EK-01: zastąpić stan U12 przepływem z ADR-0005 (komunikat jednorazowy → EK-03 wariant → EK-04); dodać stany przerwanego usuwania konta („Dokończ / Anuluj usuwanie", „Połącz się, aby dokończyć"); źródło wersji polityki = stała aplikacji; usunąć „przywrócenie z kopii" z `startDataUnavailableBody`.
2. EK-03: data wersji jako stała aplikacji (lub zdanie bez daty); wariant `reconsentBodyDataReset`.
3. EK-13 i EK-06: wycofanie zgody offline wg ADR-0002 Aneks A pkt 4 – stan „Wycofanie oczekuje na połączenie", teksty `privacyAiOffline`, `aiConsentWithdraw` (uzgodnić z security).
4. EK-09: stan „Brak sieci" – bez blokowania i bez wykrywania z wyprzedzeniem; błąd uruchomienia → `routeOpenError`.
5. EK-02 (i ogólnie `patterns.md` pkt 6): „Brak sieci" jako wynik nieudanej próby, nie stały komunikat.
6. EK-12: wiersz „Licencje open source" → ekran licencji.
7. EK-16: dopisać wiersze z tabeli w sekcji 3 (błąd transportu, pętla zgody → aktualizacja, `unsupported_version` nie dotyczy usuwania konta, `reauth_required`).

### Dla mobile-dev (przy P3-04/05/06/07/08)
1. `core/errors`: klasyfikacja błędów wg ADR-0011 pkt 2 i 7 (`unavailable` bez `details.code`, `deadline-exceeded`, `network-request-failed`, pętla `consent_required`).
2. Zgody: `consentId` w tymczasowym wpisie `shared_preferences`; ponowienia `recordConsent` (start, powrót sieci, przed zgodą AI); wycofanie offline z lokalną blokadą i `synced`.
3. Wersja i data polityki jako stałe aplikacji (obok tekstów zgód; test skrótu treści z ADR-0006 Aneks A pkt 1).
4. Generowanie: kontroler o czasie życia aplikacji, porzucanie wyniku po anulowaniu (po `requestId`), brak automatycznych ponowień; `testData` ze stałej `TAMITU_TEST_DATA`.
5. Backend (`backend/functions`): `checkArrivalDate` „dziś − 2 dni"; `deleteAccount` bez `unsupported_version` i bez wymogu dostawcy (komentarz + test); odmowa startu `dev` + `ALLOW_REAL_DATA=true` i ignorowanie `runtime.allowRealData` w `dev` (testy) – po zatwierdzeniu ADR-0011.
6. Baza: przepływ utraty klucza (ADR-0005 Aneks A pkt 2) z testem; rozróżnienie „brak klucza" vs inny błąd otwarcia.
7. Usuwanie konta: ponowne logowanie z wyprzedzeniem, `reload()` przy znaczniku „w toku" (ADR-0011 pkt 8), test E2E SEC-07 rozszerzony o przerwanie.
8. Ikony: `AppIcon`, pomiar `--analyze-size` przed/po, sprawdzenie braku Pro, `LicenseRegistry.addLicense` dla noty Hugeicons 2025 (ADR-0010).
9. Walidacja formularza wg `model-danych.md` pkt 1 (znaki, NFC, długości) i daty „od wczoraj" w strefie urządzenia.

### Dla architekta (po decyzji właściciela)
- Po zatwierdzeniu ADR-0011: kontrakt `posrednik-api.md` → v0.3 (przenieść pkt 7 do pkt 2–6), `model-danych.md` pkt 2.1 bez dopisku „proponowane".
- Po pomiarze APK: aneks do ADR-0010.

## 6. Decyzje do podjęcia przez właściciela
1. **Zatwierdzić ADR-0010** (Hugeicons: `hugeicons` + `flutter_svg`, `AppIcon`, próg APK +1,0 MB).
2. **Zatwierdzić ADR-0011** (w tym SEC-24: `dev` tylko dane testowe; `deleteAccount` bez wymogu dostawcy i wersji; tolerancja daty − 2 dni; reaktywne wykrywanie sieci).
3. Potwierdzić, że EK-01 (U12) i EK-13 (wycofanie offline) idą **za zatwierdzonymi ADR** (rekomendacja), a nie zmieniają ADR.
4. UX9 (dialog) i UX12 (bez e-maila) – rekomendacje architekta; zmiana = ponowne zatwierdzenie ekranu.
