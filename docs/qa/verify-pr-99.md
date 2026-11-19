# Weryfikacja PR #99 na urządzeniu – BUG-DEV-1 (QA-PR-99)

- Autor (rola): qa · Data: 2026-11-19 · Gałąź raportu: `docs/qa-PR-99`
- Weryfikowany kod: PR #99 `feat/BUG-DEV-1`, head `82e36da11ca024a7b8274851a81111c23b1fd386` (baza `main` @ `7f06520`)
- Norma: `docs/qa/test-plan-p3-04.md` (SIGN-12, SIGN-13, SIGN-14, PRIV-06); poprzednio `docs/qa/verify-p3-04-dev.md` (BUG-DEV-1)
- Przegląd kodu: `docs/reviews/PR-99.md` (PR #100, `review:ok`)
- Dane: wyłącznie „konto testowe właściciela"; każdy wybór konta wykonywał właściciel przy telefonie. W raporcie brak adresu e-mail, nazwy konta, UID i tokenów. Żadne logowanie nie zakończyło się sukcesem – w Firebase Auth `dev` nie powstał użytkownik.

## 1. Środowisko

| Element | Stan |
|---|---|
| Urządzenie | telefon właściciela (OPPO, ColorOS, Android 13), USB; każde użycie `adb` przez `.farm/test-lock.ps1 -Resource device`; „Nie przeszkadzać" włączone, „Wyłącz monitorowanie uprawnień" włączone (stan z 18.11) |
| Build PR | `flutter build apk --flavor dev --debug` z osobnego worktree (detached `82e36da`, tylko do odczytu); `google-services.json` dev kopiowany z katalogu właściciela tylko na czas buildu (`git check-ignore` potwierdzone), potem usunięty |
| Build SIGN-14 | ten sam kod PR + `--dart-define=TAMITU_GOOGLE_SERVER_CLIENT_ID=<fikcyjny identyfikator>` – wymusza prawdziwy błąd konfiguracji bez zmiany kodu |
| Build kontrolny (A/B) | ten sam head, ale `lib/features/auth/data/firebase_auth_gateway.dart` z `main` (`7f06520`) – jedyny plik w `lib/` zmieniony przez PR; użyty tylko do porównania SIGN-13 |
| Pomiar | `dumpsys window` (fokus: `GoogleSignInActivity` = okno wyboru otwarte), `uiautomator dump` (teksty ekranu EK-02), `run-as` (DataStore `SharedPreferencesAsync`: wpis `pendingPolicyAcceptance`), `logcat` filtrowany po komunikatach GMS (adresy maskowane). Zrzuty ekranu tylko ekranu aplikacji, poza repo, usunięte po teście. Okna wyboru konta nie fotografowano |
| Wygaszanie ekranu | na czas testu 10 min, potem przywrócone 15 s |

## 2. Wyniki

### SIGN-12 – anulowanie wyboru konta (BUG-DEV-1)

Oczekiwane (US-001 AC2, CMP-09): EK-02, snackbar „Logowanie anulowane.", bez komunikatu błędu, zgoda nadal zaznaczona, wpis tymczasowy usunięty.

| # | Wariant | Odczekanie w oknie wyboru | Wynik |
|---|---|---|---|
| 1 | wstecz | 1 s | snackbar „anulowano" po ≤2 s, brak błędu, zgoda ✓ |
| 2 | wstecz | 12 s | jw. (≤5 s) |
| 3 | wstecz | 17 s | jw. (≤2 s) |
| 4 | dotknięcie poza arkuszem | 5 s | jw. (≤3 s) |
| 5 | `pm clear` → start → zgoda → logowanie → wstecz (sekwencja z BUG-DEV-1) | 1 s | jw. (≤3 s) |
| 6 | jw. (`pm clear`) | 10 s | jw. (≤2 s) |
| 7 | jw. (`pm clear`) | 15 s | jw. (≤3 s) |
| 8 | wstecz + kontrola wpisu tymczasowego | 2 s | wpis `pendingPolicyAcceptance`: brak przed, **jest** przy otwartym oknie, **brak** po anulowaniu |
| 9 | wstecz + zrzut ekranu | 11 s | zrzut: snackbar „Logowanie anulowane.", zgoda zaznaczona, przycisk aktywny |
| 10 | wstecz w trybie samolotowym | 4 s | snackbar „anulowano" po ≤2 s, brak błędu i komunikatu o sieci |

**Zaliczony 10/10.** W żadnym przebiegu nie wystąpił wskaźnik ładowania 10–17 s ani „Nie udało się zalogować". Uwaga: na buildzie PR nie odtworzono pierwotnych warunków BUG-DEV-1 (mobile-dev też nie odtworzył ich w 8 próbach) – potwierdzamy zachowanie zgodne z AC2 we wszystkich wariantach anulowania, a nie usunięcie przyczyny opóźnienia z 18.11 (Q-BUG-DEV-1-DELAY pozostaje otwarte).

### SIGN-14 – prawdziwy błąd nadal jest błędem

| Wariant | Wynik |
|---|---|
| build PR z fikcyjnym `serverClientId`, sieć włączona; właściciel wybiera konto | okno wyboru zamyka się po ok. 0,4 s od wyboru (logcat GMS: „GoogleSignIn … Flow failed"); na EK-02 trwały komunikat CMP-13 „Nie udało się zalogować. Spróbuj ponownie." (zrzut), zgoda zaznaczona, przycisk aktywny, wpis tymczasowy usunięty |

**Zaliczony.** Rozszerzona klasyfikacja anulowania nie zamienia błędu konfiguracji w „anulowano".

### SIGN-13 – brak sieci (kontrola regresji) – nowy błąd BUG-DEV-2, niezależny od PR

| Build | Wariant | Wynik |
|---|---|---|
| PR (`82e36da`) | tryb samolotowy, właściciel wybiera konto (2×) | snackbar „Logowanie anulowane." zamiast CMP-13 „Brak połączenia z internetem…"; logcat (2. przebieg): wybór → `getToken() -> NETWORK_ERROR` → „AccountReauth … Flow failed" → okno zamknięte w ok. 0,3 s |
| kontrolny (klasyfikator z `main`) | jw. (1×) | **to samo**: „Logowanie anulowane."; logcat: `NETWORK_ERROR` → „Flow failed" → zamknięcie okna |

Na buildzie kontrolnym klasyfikator `main` daje „anulowano" wyłącznie dla kodu `GoogleSignInExceptionCode.canceled`, więc Google Play services zwraca dziś przy braku sieci po wyborze konta **anulowanie** (`GetCredentialCancellationException`), a nie błąd z opisem o sieci. Zachowanie nie wynika z PR #99. 18.11 ten sam test na `main` dawał komunikat o braku sieci (`verify-p3-04-dev.md`, SIGN-13) – różnica jest po stronie GMS (dziś w przepływie pojawia się krok „AccountReauth"), nie kodu aplikacji.

**SIGN-13: niezaliczony na obu buildach → BUG-DEV-2 (sekcja 3), nie blokuje PR #99.**

### Pozostałe obserwacje

- PRIV-06 (część): wpis tymczasowy usuwany po anulowaniu (SIGN-12) i po błędzie (SIGN-14) – zaliczony.
- SEC-29: aplikacja nie zapisała w logcat własnych treści w żadnym kroku (kod wyjątku niewidoczny – zgodnie z założeniem). Diagnoza BUG-DEV-2 opierała się na logach GMS.
- DOC-APPCHECK-DEVICE (`android/FIREBASE.md` z PR #99): lista przygotowania telefonu zgodna z przebiegiem; wymagane kroki (monitorowanie uprawnień, wygaszanie, „Nie przeszkadzać", osobne konto) wystarczyły. Uwaga do treści: dane `SharedPreferencesAsync` leżą w `files/datastore/FlutterSharedPreferences.preferences_pb`, nie w `shared_prefs/` – przydatne przy kontroli wpisu tymczasowego przez `run-as` (propozycja dopisku, nie blokuje).
- Środowisko: dwa długie zapisy stanu przez `adb shell` przerwały się w trakcie interakcji właściciela z telefonem (wynik odczytano wtedy z logcat i od właściciela); nie dotyczy aplikacji.

## 3. Błędy

### BUG-DEV-2 (średni, US-001 / ERR-04, SIGN-13): brak sieci po wyborze konta pokazuje „Logowanie anulowane."

- Kroki: tryb samolotowy → EK-02 → zgoda → „Zaloguj przez Google" → wybór konta w oknie Google.
- Oczekiwane (SIGN-13, ERR-04): CMP-13 „Brak połączenia z internetem. Ta funkcja wymaga sieci.", przycisk aktywny.
- Rzeczywiste: okno zamyka się po ok. 0,3 s, snackbar „Logowanie anulowane." – użytkownik nie wie, że problemem jest sieć.
- Powtarzalność: 3/3 (2× build PR, 1× klasyfikator `main`). Na `main` 18.11 – nie występowało.
- Przyczyna (z logów GMS): krok „AccountReauth" kończy się `NETWORK_ERROR`, a Credential Manager zwraca anulowanie. Kod `canceled` → `cancelled` jest w `main` od początku, więc to nie regresja PR #99.
- Propozycja dla mobile-dev (do decyzji, nie testowane): przy `cancelled` sprawdzić łączność (np. `connectivity_plus`) i przy jej braku pokazać „offline" – wymaga zgody architekta/UX, bo zmienia ADR-0011 pkt 2.

## 4. Werdykt

**PR #99: PRZYJĘTE (`qa:ok`) dla head `82e36da`.**

- BUG-DEV-1 / SIGN-12: anulowanie wyboru konta – 10/10 zgodnie z US-001 AC2 (także sekwencja `pm clear`, odczekanie 10–17 s, dotknięcie poza arkuszem, brak sieci).
- SIGN-14: prawdziwy błąd konfiguracji nadal daje „Nie udało się zalogować".
- Nowy BUG-DEV-2 (SIGN-13) występuje identycznie bez zmian z PR – osobne zadanie, nie blokuje merge.
- Ograniczenie: przyczyna opóźnienia 10–17 s z 18.11 nieodtworzona (Q-BUG-DEV-1-DELAY). Jeśli objaw wróci, najpierw SEC-AUTHDIAG.

## 5. Sprzątanie

- Telefon: `pl.tadecode.tamitu.dev` odinstalowana; wygaszanie przywrócone do 15 s; tryb samolotowy wyłączony; pliki pomocnicze z `/sdcard` usunięte. „Nie przeszkadzać" i „Wyłącz monitorowanie uprawnień" – zostawione jak przed testem (decyzja właściciela).
- Komputer: worktree buildu i zrzuty ekranu usunięte; kopia `google-services.json` usunięta po każdym buildzie.
- Firebase `dev` (właściciel): w tej sesji nie powstał użytkownik Auth i nie rejestrowano tokenu App Check – nic do usunięcia z tej sesji. Pozostaje sprzątanie z 18.11 (`verify-p3-04-dev.md` sekcja 5), jeśli jeszcze nie wykonane.
