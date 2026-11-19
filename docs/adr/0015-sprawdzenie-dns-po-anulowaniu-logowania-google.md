# ADR-0015: Sprawdzenie DNS po „anulowaniu” logowania Google (uzupełnienie ADR-0011 pkt 2)

- Status: zatwierdzony (właściciel produktu, 2026-11-19: „zatwierdzam ADR-0015”)
- Data: 2026-11-19
- Autor (rola): architect
- Zadanie: BUG-DEV-2 (QA-PR-99, SIGN-13), pytanie M-BUG-DEV-2, przegląd `docs/reviews/PR-102.md` ustalenie #1
- Uzupełnia (nie zastępuje): ADR-0011 pkt 2. Pozostała treść pkt 2 obowiązuje bez zmian; poniższy wyjątek dotyczy tylko jednego przypadku.

## Kontekst
ADR-0011 pkt 2 wybrał wykrywanie braku sieci **z wyniku wywołania** (wyjątek SDK), bez pakietu łączności, bez `ACCESS_NETWORK_STATE` i bez osobnego „sprawdzenia sieci”. Założenie: SDK zgłasza błąd sieci jako błąd sieci.

QA-PR-99 (`docs/qa/verify-pr-99.md`, sekcja 3) pokazało, że to założenie nie zawsze jest prawdziwe. Gdy po wyborze konta nie ma sieci, Google Play services kończy krok „AccountReauth” błędem `NETWORK_ERROR`, ale Credential Manager zwraca `GetCredentialCancellationException`, a wtyczka `google_sign_in` – kod `canceled`. Wyjątek SDK nie odróżnia tego od anulowania przez użytkownika, więc sam klasyfikator z pkt 2 nie spełni US-001 AC3 (CMP-13 przy braku sieci). Różnica pochodzi z GMS (18.11 ten sam test dawał błąd sieci), więc może się zmieniać bez zmian w aplikacji.

PR #102 dodaje po takim „anulowaniu” jedno zapytanie DNS. Spełnia warunki pkt 2 (reaktywnie, po próbie; bez nowego pakietu i uprawnienia), ale wprowadza aktywne sprawdzenie, którego pkt 2 nie przewiduje. Zasada 4 CLAUDE.md: zmiana nie może być cicha.

## Rozważane opcje
1. **Zostawić pkt 2 dosłownie** (anulowanie zawsze „anulowano”) – zero nowego mechanizmu; minus: SIGN-13 / US-001 AC3 niespełnione, użytkownik bez sieci nie wie, dlaczego logowanie się nie udaje.
2. **`connectivity_plus` + `ACCESS_NETWORK_STATE`** (propozycja QA) – odrzucone już w ADR-0011 (nowy pakiet i uprawnienie, test manifestu; „połączono z Wi-Fi” nie oznacza internetu). Bez nowych argumentów.
3. **Zapytanie HTTP (np. `generate_204`)** – wiarygodniejsze przy portalach, ale to pełne połączenie z serwerem, dłuższe i z większym śladem sieciowym; nie jest potrzebne do przypadku „brak sieci”.
4. **Jedno zapytanie DNS o stały host Google, tylko po wyniku „anulowano” z logowania Google** (PR #102) – bez pakietu i uprawnienia (`INTERNET` już jest), bez danych użytkownika, zero kosztu; minus: nowy, wąski mechanizm i możliwe fałszywe „offline” przy blokadzie DNS (niżej).

## Decyzja
Opcja 4, w ściśle ograniczonym zakresie. ADR-0011 pkt 2 dostaje jeden wyjątek:

1. **Kiedy:** wyłącznie po wyjątku `google_sign_in` sklasyfikowanym przez `classifyGoogleSignInError` jako „anulowano”. Nigdy z wyprzedzeniem (przed próbą), nigdy cyklicznie, nigdy dla innych rodzajów błędów i innych wywołań (Functions, Auth, `recordConsent`, `generatePlan` – tam bez zmian obowiązuje klasyfikacja z pkt 2).
2. **Jak:** jedno rozwiązanie nazwy `www.googleapis.com` przez resolver systemu (`InternetAddress.lookup`), limit 2 s. Bez HTTP, bez wysyłania danych, bez pamięci podręcznej wyniku, bez ponowień.
3. **Wynik:** tylko **pewny** brak sieci (`SocketException` resolvera lub pusta lista adresów) → „brak sieci” (CMP-13). Adres rozwiązany, przekroczony czas lub inny błąd → zostaje „anulowano” (zachowanie sprzed zmiany; fail-safe na korzyść US-001 AC2).
4. **Logi:** wynik sprawdzenia i nazwa hosta nie są logowane (SEC-29).
5. **Rozszerzenie** tego sprawdzenia na inne przepływy wymaga nowego ADR.
6. Treść komunikatu przy anulowaniu w trybie samolotowym (CMP-13 zamiast „Logowanie anulowane.”) to decyzja UX (M-BUG-DEV-2, część UX); ten ADR jej nie przesądza. Jeśli UX wybierze inny komunikat, mechanizm z pkt 1–5 pozostaje, zmienia się tylko mapowanie na ekran.

Uzasadnienie: to najmniejsza zmiana, która przywraca US-001 AC3 mimo zmiany zachowania GMS, bez łamania celów pkt 2 (brak pakietu, brak uprawnienia, stan sieci po próbie, nie z wyprzedzeniem).

## Konsekwencje
**Pozytywne:** SIGN-13 / US-001 AC3 spełnione niezależnie od tego, jak GMS raportuje błąd sieci; przy niepewnym wyniku zachowanie jak dziś (BUG-DEV-1 / SIGN-12 bez regresji).

**Negatywne / ryzyka (niezawodność):**
- *Anulowanie bez sieci* (QA-PR-99 SIGN-12 #10, tryb samolotowy): aplikacja nie odróżni go od SIGN-13 i pokaże komunikat o braku sieci. Komunikat jest prawdziwy; oczekiwanie SIGN-12 #10 zmienia się po decyzji UX.
- *Fałszywe „offline”* przy sieci, w której resolver zwraca `NXDOMAIN` dla `www.googleapis.com` (blokery DNS, filtr rodzicielski, firmowy DNS) albo gdy skonfigurowany „Prywatny DNS” Androida jest nieosiągalny. Wtedy anulowanie pokaże CMP-13. Skutek łagodny: logowanie Google w takiej sieci i tak nie zadziała (ten sam host), przycisk zostaje aktywny, nic się nie zapisuje. Blokery zwracające `0.0.0.0` dają adres → „anulowano”.
- *Fałszywe „anulowano”* (BUG-DEV-2 nienaprawiony w wariancie): Wi-Fi bez internetu, portal przechwytujący DNS – jak przed zmianą, bez regresji.
- *Pamięć podręczna resolvera* w trybie samolotowym: Android bez domyślnej sieci zwraca błąd od razu (oczekiwane); potwierdza QA na telefonie (SIGN-13). Jeśli zwróci adres z pamięci → „anulowano”, czyli zachowanie sprzed zmiany.
- *Opóźnienie:* anulowanie z siecią – zwykle kilkadziesiąt ms (pamięć podręczna), najwyżej 2 s dłużej stanu ładowania.

**Koszty (CLAUDE.md pkt 10):** zero. Brak wywołań AI i usług płatnych; jedno zapytanie DNS na anulowane logowanie.

**Dane osobowe (RODO):** brak nowego rodzaju danych i nowego odbiorcy danych użytkownika. Zapytanie zawiera tylko stałą nazwę hosta; trafia do resolvera skonfigurowanego na urządzeniu (operator, Prywatny DNS użytkownika), który widzi adres IP urządzenia i nazwę `www.googleapis.com` – tę samą metadaną, którą ten przepływ i tak ujawnia, łącząc się z Google przy logowaniu. Aplikacja nic nie zapisuje ani nie loguje (SEC-29). Wpis w `docs/security/personal-data-register.md` nie jest potrzebny; do wiadomości security (bez blokady).

**Po zatwierdzeniu:** kod PR #102 jest zgodny z pkt 1–5 bez zmian. QA: SIGN-13 (offline → CMP-13), SIGN-12 z siecią (→ „anulowano”), SIGN-14, SIGN-15 oraz oczekiwanie SIGN-12 #10 wg decyzji UX.
