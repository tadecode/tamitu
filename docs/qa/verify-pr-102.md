# Weryfikacja PR #102 na urządzeniu – BUG-DEV-2 (QA-PR-102)

- Autor (rola): qa · Data: 2026-11-19 · Gałąź raportu: `docs/qa-PR-102`
- Weryfikowany kod: PR #102 `fix/BUG-DEV-2`, head `47f4212cc4e74476ab9f2e0ba7c52106c0e5fad9` (baza `main` @ `5e1f4dd`)
- Norma: `docs/qa/test-plan-p3-04.md` (SIGN-12, SIGN-13, SIGN-14, SIGN-15, PRIV-06); EK-02 v0.4.1 (`docs/ux/screens/ek-02.md`, „Anulowanie bez sieci”); ADR-0015 (sprawdzenie DNS po „anulowaniu”, limit 2 s)
- Przegląd kodu: `docs/reviews/PR-102.md` (PR #103, `review:ok`)
- Dane: wyłącznie „konto testowe właściciela”. Każdy wybór konta wykonywał właściciel przy telefonie. W raporcie nie ma adresu e-mail, nazwy konta, UID ani tokenów. SIGN-15 zakończył się udanym logowaniem, więc w Firebase Auth `dev` jest użytkownik konta testowego (sekcja 5).

## 1. Środowisko

| Element | Stan |
|---|---|
| Urządzenie | telefon właściciela (OPPO, ColorOS, Android 13), USB. Każde użycie `adb` szło przez `.farm/test-lock.ps1 -Resource device`. Wygaszanie ekranu na czas testu 10 min, potem przywrócone do 15 s |
| Build PR | `flutter build apk --flavor dev --debug` z osobnego worktree (detached `47f4212`, tylko do odczytu). `google-services.json` dev był kopiowany z katalogu właściciela tylko na czas buildu (`git check-ignore` potwierdzone, `git status` czysty), a potem usunięty. Zawartości nie odczytywano |
| Build SIGN-14 | ten sam kod + `--dart-define=TAMITU_GOOGLE_SERVER_CLIENT_ID=<fikcyjny identyfikator>`. Wymusza prawdziwy błąd konfiguracji bez zmiany kodu |
| Pomiar | `dumpsys window` (fokus `GoogleSignInActivity` = okno wyboru otwarte), `uiautomator dump` (tylko teksty EK-02/EK-04, filtrowane), `run-as` (obecność klucza `pendingPolicyAcceptance` w DataStore), `dumpsys connectivity` (domyślna sieć), `logcat` GMS (adresy maskowane). Okna wyboru konta nie fotografowano ani nie zrzucano. Zrzutów ekranu nie robiono |
| Sieć | z siecią: Wi-Fi/dane właściciela. Bez sieci: tryb samolotowy włączany przez właściciela, `Active default network: none` |

## 2. Wyniki

### SIGN-12 – anulowanie wyboru konta z siecią (regresja BUG-DEV-1)

Oczekiwane (US-001 AC2, EK-02 v0.4.1 „Anulowano u Google”): snackbar „Logowanie anulowane.”, brak komunikatu błędu i komunikatu o sieci, zgoda zaznaczona, przycisk aktywny, wpis tymczasowy usunięty.

| # | Wariant | Czas w oknie wyboru | Wynik |
|---|---|---|---|
| 1 | wstecz | ok. 4 s | snackbar „Logowanie anulowane.”, zgoda ✓, przycisk aktywny |
| 2 | wstecz | 10 s | jw. |
| 3 | wstecz | 3 s | jw. |
| 4 | dotknięcie poza arkuszem + kontrola wpisu tymczasowego | 4 s | jw. Wpis `pendingPolicyAcceptance` **jest** przy otwartym oknie, **brak** po anulowaniu |
| 5 | `pm clear` → start → zgoda → logowanie → wstecz (sekwencja BUG-DEV-1) | ok. 4 s | pierwszy odczyt (ok. 1 s po wstecz): EK-02, zgoda ✓, przycisk aktywny, **bez** błędu i komunikatu o sieci. Snackbara w odczycie nie było (pojedynczy `uiautomator dump`; snackbar trwa ok. 4 s) – wynik nierozstrzygnięty co do snackbara, powtórzono jako #6 |
| 6 | jw. (`pm clear`), trzy kolejne odczyty | ok. 4 s | snackbar „Logowanie anulowane.” w 1. odczycie, potem znika. Zgoda ✓ |
| 7 | jw. (`pm clear`) | 14 s | snackbar „Logowanie anulowane.” |

**Zaliczony.** W żadnym przebiegu z siecią nie pojawił się CMP-13 („Brak połączenia…” ani „Nie udało się zalogować”). Sprawdzenie DNS po anulowaniu nie zamienia prawdziwego anulowania w komunikat o sieci. Opóźnienie po zamknięciu okna było niezauważalne: snackbar był już w pierwszym odczycie. Wskaźnik ładowania 10–17 s z BUG-DEV-1 nie wystąpił.

### Anulowanie wyboru konta w trybie samolotowym (dawne SIGN-12 #10, oczekiwanie wg EK-02 v0.4.1)

Oczekiwane (EK-02 v0.4.1 „Anulowanie bez sieci”, ADR-0015 pkt 3): CMP-13 `commonOfflineNotice` „Brak połączenia z internetem. Ta funkcja wymaga sieci.”, **bez** snackbara „Logowanie anulowane.”, zgoda zaznaczona, przycisk aktywny.

| # | Wariant | Wynik |
|---|---|---|
| 1 | tryb samolotowy, okno wyboru otwarte ok. 4 s, wstecz | CMP-13 „Brak połączenia z internetem. Ta funkcja wymaga sieci.” we wszystkich trzech odczytach, bez snackbara; zgoda ✓, przycisk aktywny |
| 2 | jw., okno otwarte 8 s (`Active default network: none`) | CMP-13, bez snackbara |

**Zaliczony 2/2.** Resolver ColorOS w trybie samolotowym od razu zwraca błąd (a nie adres z pamięci podręcznej) – to rozstrzyga punkt „Czego nie sprawdzono” z przeglądu PR-102 i ryzyko „pamięć podręczna resolvera” z ADR-0015. Okno wyboru konta otwiera się offline normalnie.

### SIGN-13 – brak sieci po wyborze konta (BUG-DEV-2)

Oczekiwane (US-001 AC3, EK-02 v0.4.1 „Brak sieci” (b)): CMP-13 `commonOfflineNotice`, przycisk aktywny, zgoda zaznaczona, wpis tymczasowy usunięty, bez snackbara.

| Wariant | Wynik |
|---|---|
| tryb samolotowy, właściciel wybiera konto testowe | okno zamyka się po wyborze. Logcat GMS: `AccountReauth` → `getToken() -> NETWORK_ERROR` → „AccountReauth … Flow failed” → „GoogleSignIn … Flow failed” (ten sam przebieg co w QA-PR-99). Na EK-02: CMP-13 „Brak połączenia z internetem. Ta funkcja wymaga sieci.” w trzech kolejnych odczytach, bez snackbara; zgoda ✓, przycisk aktywny; wpis `pendingPolicyAcceptance` usunięty |

Uwaga do metody: przed tą próbą na ekranie był już CMP-13 z anulowania offline. Że komunikat pochodzi z tej próby, potwierdzają: CMP-13 znika przy nowej próbie (SIGN-15: odczyt przy otwartym oknie – 0 wystąpień), przebieg GMS z `NETWORK_ERROR` i usunięty wpis tymczasowy (powstaje przy każdej próbie).

**Zaliczony.** BUG-DEV-2 naprawiony: przypadek z QA-PR-99 (3/3 „Logowanie anulowane.”) daje teraz komunikat o braku sieci.

### SIGN-15 – ponowienie z siecią po SIGN-13

| Wariant | Wynik |
|---|---|
| właściciel wyłącza tryb samolotowy (domyślna sieć wróciła), „Zaloguj przez Google”, wybór konta testowego | przy otwartym oknie: CMP-13 zniknął (0 wystąpień), **nowy** wpis tymczasowy (`pendingPolicyAcceptance` = 1, wcześniej 0). Po wyborze: logowanie udane, EK-04 (obecnie zaślepka „Zaplanuj podróż z pomocą AI.”) |

**Zaliczony.** Wpis tymczasowy po zalogowaniu nadal jest. Zgodnie z ADR-0005 Aneks A pkt 4 zostaje do udanego `recordConsent` (w `dev` funkcje nie są wdrożone – jak w `verify-p3-04-dev.md`, SIGN-11/CONS-02). To nie wynika z PR.

### SIGN-14 – prawdziwy błąd nadal jest błędem

| Wariant | Wynik |
|---|---|
| build z fikcyjnym `serverClientId`, sieć włączona, `pm clear`, właściciel wybiera konto | okno zamyka się po wyborze (logcat GMS „GoogleSignIn … Flow failed”). Na EK-02 trwały CMP-13 „Nie udało się zalogować. Spróbuj ponownie.” (dwa odczyty w odstępie 2 s), zgoda ✓, przycisk aktywny, wpis tymczasowy usunięty |

**Zaliczony.** `refineCancellation` nie dotyka rodzajów innych niż „anulowano”.

### Pozostałe

- PRIV-06 (część): wpis tymczasowy usuwany po anulowaniu z siecią (SIGN-12 #4), po braku sieci (SIGN-13) i po błędzie (SIGN-14). Zaliczony.
- SEC-29: w logcat brak wpisów aplikacji (`flutter`) z całej sesji testu; wynik sprawdzenia DNS i nazwa hosta nie są logowane (ADR-0015 pkt 4). Zaliczony.
- Nie testowano (poza zakresem BUG-DEV-2, przypadki graniczne z ADR-0015): Wi-Fi bez internetu, portal przechwytujący, blokery DNS, nieosiągalny „Prywatny DNS”.

## 3. Błędy

Brak nowych błędów.

## 4. Werdykt

**PR #102: PRZYJĘTE (`qa:ok`) dla head `47f4212`.**

- SIGN-13 (BUG-DEV-2): brak sieci po wyborze konta → CMP-13 zgodnie z US-001 AC3 i EK-02 v0.4.1.
- Anulowanie w trybie samolotowym → CMP-13 bez snackbara (EK-02 v0.4.1, nowe oczekiwanie dawnego SIGN-12 #10) – 2/2.
- SIGN-12 z siecią (BUG-DEV-1): „Logowanie anulowane.” bez komunikatu błędu i o sieci – 7 przebiegów, w 6 snackbar potwierdzony odczytem, w 1 odczyt go nie złapał (bez innego komunikatu).
- SIGN-14: błąd konfiguracji nadal „Nie udało się zalogować”. SIGN-15: ponowienie z siecią → EK-04.

## 5. Sprzątanie

- Telefon: `pl.tadecode.tamitu.dev` odinstalowana; wygaszanie przywrócone do 15 s; tryb samolotowy wyłączony (stan `0`); pliki pomocnicze z `/sdcard` i `/data/local/tmp` usunięte.
- Komputer: worktree buildu usunięty (z kopią `google-services.json`); pliki APK usunięte; zrzutów ekranu nie było.
- **Firebase `dev` (właściciel):** SIGN-15 utworzył (albo ponownie zalogował) użytkownika konta testowego w Firebase Auth `dev`. Do usunięcia w konsoli Firebase razem z pozostałościami z 18.11 (`verify-p3-04-dev.md` sekcja 5), jeśli niepotrzebny. Tokenu App Check nie rejestrowano.
