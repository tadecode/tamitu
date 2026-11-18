# Weryfikacja P3-04 na urządzeniu – wariant `dev` (QA-P3-04-DEV)

- Autor (rola): qa · Data: 2026-11-18 · Gałąź: `docs/QA-P3-04-DEV` · Kod: `main` @ `943f9a6`
- Norma: `docs/qa/test-plan-p3-04.md`; poprzednio `docs/qa/verify-p3-04-r3.md` (sekcja 3: przypadki „blokowane: brak urządzenia")
- Zakres: pierwszy przebieg aplikacji na prawdziwym telefonie z prawdziwym logowaniem Google wobec projektu Firebase `tamitu-dev-tadecode` (US-001, US-003 – część P3-04)
- Dane: wyłącznie „konto testowe właściciela" (wybór konta wykonywał właściciel). `config/runtime.allowRealData=false`; nie wprowadzano żadnych danych podróży. W raporcie brak adresu e-mail, nazwy konta, UID, tokenów i identyfikatorów zgód.

## 1. Środowisko

| Element | Stan |
|---|---|
| Urządzenie | telefon właściciela przez USB, Android 13 (SDK 33), 1080×2400, język systemu pl-PL, motyw ciemny; tryb „Nie przeszkadzać" włączony na czas testu |
| Dostęp | `adb` (SDK platform-tools), każde użycie przez `.farm/test-lock.ps1 -Resource device` |
| Build | `flutter build apk --flavor dev --debug` (bez `--dart-define`), pakiet `pl.tadecode.tamitu.dev`; `google-services.json` dev skopiowany z katalogu właściciela tylko na czas buildu (`git check-ignore` potwierdził ignorowanie), po teście usunięty; zawartości nie odczytywano |
| App Check | dostawca debug (wariant `dev`); token debug odczytany z `adb logcat` i zarejestrowany przez właściciela w konsoli (osobny wpis dla telefonu); wartość nie trafiła do repo ani raportu |
| Backend `dev` | funkcje **nie są wdrożone**: `POST …/recordConsent` i `…/generatePlan` → HTTP 404 (stan na 2026-11-18, jak w r3) |
| Dowody | zrzuty ekranu (`adb shell screencap`) wysłane właścicielowi poza repo, bez danych konta; zrzutów okna wyboru konta nie zachowano. `uiautomator dump` do odczytu etykiet semantycznych. `run-as` (build debug) do odczytu `shared_preferences` |

Uwagi do środowiska (nie są błędami aplikacji):
- Telefon (ColorOS) zwracał czarne zrzuty i błąd `uiautomator` do czasu włączenia przez właściciela opcji programisty „Wyłącz monitorowanie uprawnień"; dodatkowo ekran wygasa po 15 s (przed każdym krokiem `KEYCODE_WAKEUP`).
- Pierwszy start wygenerował nowy token debug App Check (inny niż token `owner-laptop` z runbooka) → odrzucenie 403 „App attestation failed" do czasu dodania tokenu telefonu w konsoli. Po `pm clear` (krok SIGN-12) telefon generuje kolejny token – po teście należy usunąć wpis tokenu z konsoli.

## 2. Wyniki – przypadki z planu testów

| ID | Wynik | Obserwacja na urządzeniu |
|---|---|---|
| SIGN-01 | **zaliczony** | EK-02: zgoda niezaznaczona, „Zaloguj przez Google" nieaktywny, podpowiedź „Zaznacz akceptację polityki, aby się zalogować." widoczna; widoczne „Twoja prywatność" (informacja o AI), „Tamitu jest dla osób pełnoletnich.", link polityki |
| SIGN-02 | **zaliczony** | dotknięcie pola → zaznaczone, przycisk aktywny, podpowiedź znika |
| SIGN-04 | **zaliczony** | dotknięcie nieaktywnego przycisku → brak okna Google i brak aktywności logowania w logcat |
| SIGN-05 | **zaliczony** | PL → EN: wszystkie teksty EK-02 natychmiast po angielsku |
| SIGN-06 | **zaliczony** | zaznaczone pole + zmiana języka → zaznaczenie zdjęte, przycisk nieaktywny (P-3) |
| SIGN-08 | **zaliczony** | w trakcie logowania: wskaźnik w przycisku, pole zgody i przełącznik języka wyszarzone |
| SIGN-10 / CONS-09 | **zaliczony** | wpis tymczasowy `pendingPolicyAcceptance` powstaje przy „Zaloguj" i zawiera wyłącznie `consentId`, `version=privacy-v1`, `lang=pl`, `acceptedAt` – bez UID, e-maila, nazwy |
| SIGN-12 | **niezaliczony – BUG-DEV-1** | anulowanie wyboru konta (wstecz) → po ok. 10–17 s czerwony komunikat „Nie udało się zalogować. Spróbuj ponownie." zamiast snackbara „anulowano"; wpis tymczasowy usunięty poprawnie; sekcja 3 |
| SIGN-13 | **zaliczony** | tryb samolotowy: okno wyboru konta otwiera się (konta z pamięci), po wyborze CMP-13 z ikoną braku Wi-Fi „Brak połączenia z internetem. Ta funkcja wymaga sieci." nad przyciskiem; przycisk aktywny, zgoda nadal zaznaczona; brak treści technicznych (ERR-04, ERR-09 dla tego stanu). Klasyfikacja `google_sign_in` „sieć" potwierdzona na urządzeniu (komentarz w `firebase_auth_gateway.dart`) |
| SIGN-15 | **zaliczony** | po SIGN-13 włączenie sieci i ponowienie → komunikat znika, logowanie, EK-04 |
| SIGN-16 | **zaliczony** | zgoda zaznaczona → HOME → `am kill` → powrót: pole niezaznaczone, przycisk nieaktywny |
| SIGN-17 (UI) | **zaliczony** | na EK-02 brak pól hasła/e-maila, rejestracji i innych dostawców |
| SIGN-19 | **zaliczony** | przycisk tekstowy „Zaloguj przez Google" bez logo „G" (wariant „sam tekst" dozwolony) |
| SIGN-20 | **zaliczony** | Credential Manager (`SignInCredentialChooserActivity` → `GoogleSignInActivity`) → wybór konta → bez osobnego ekranu uprawnień (w logu brak dodatkowej aktywności zgody OAuth) → Firebase Auth `dev` → EK-04 |
| SIGN-11 (część kliencka) / CONS-02 | **zaliczony (klient)** | po logowaniu EK-04 bez blokady i bez komunikatu, mimo że `recordConsent` nie mogło się udać (funkcje 404); wpis tymczasowy zostaje do sukcesu (zgodnie z ADR-0005 Aneks A pkt 4), w katalogu aplikacji powstała zaszyfrowana baza konta. Zapis `users/{uid}/consents/{consentId}` – **nie sprawdzono** (brak wdrożenia) |
| CONS-03 (część) | **zaliczony (klient)** | przy ponownym starcie aplikacja ponawia wywołanie (w logcat żądanie do Functions z tokenem App Check); wynik serwera niesprawdzalny (404) |
| US-001 AC4 / GATE-07 (M) | **zaliczony** | zabicie procesu i start → od razu EK-04, bez EK-02 |
| GATE-08 | **zaliczony** | zalogowany, tryb samolotowy, zabicie procesu, start → EK-04, brak komunikatu błędu |
| API-10 (część „realna") | **częściowo** | App Check dev z tokenem debug: po rejestracji tokenu wymiana działa (0 odrzuceń); przed rejestracją SDK wysyła token zastępczy (403 w logcat). Weryfikacja po stronie funkcji (`app_check_failed`) – wymaga wdrożenia |
| A11Y-04 (część) | **zaliczony (odczyt)** | `uiautomator`: etykieta pola zgody = tekst widoczny; link „Przeczytaj politykę prywatności, otwiera przeglądarkę"; przełącznik „Język aplikacji" z „Polski"/„English" |
| PRIV-05 | **częściowo** | aplikacja nie zapisała w logcat żadnej własnej treści (e-mail, UID, `details`) w żadnym kroku; **biblioteki**: Firebase Auth (poziom D) zapisuje UID („Notifying id token listeners about user …"), dostawca debug App Check zapisuje token debug (z założenia, tylko `dev`). Build debug – przebieg na release nie wykonany. OBS-DEV-3 |

### Nie sprawdzono (i dlaczego)

| Przypadki | Powód |
|---|---|
| zapis zgody w Firestore (SIGN-11 serwer, CONS-01 `synced=1`, CONS-10 klient, RECON-03, AIC-04) | funkcje `dev` niewdrożone (404) – po wdrożeniu (P3-05 / GH-010) |
| EK-06 (AIC-01..07) na urządzeniu | brak wejścia z UI (EK-04 to zaślepka; wejście z EK-05/EK-07 w P3-05) |
| EK-03 (RECON-*) na urządzeniu | wymaga zmiany `privacyPolicyVersion` w buildzie |
| OUT-01..06, SES-03/04/06 | brak ekranu wylogowania (EK-14), usuwania konta i drugiego urządzenia |
| SIGN-03, L10N-04 (link polityki) | link nie otwierany w tym przebiegu |
| SIGN-07, A11Y-01..03, A11Y-05..07 (motyw jasny, obrót, 200%, TalkBack, Accessibility Scanner) | poza czasem sesji z właścicielem; tylko motyw ciemny i PL/EN |
| PRIV-05 na buildzie release | build release `dev` nie budowany |

## 3. Błędy

### BUG-DEV-1 (poważny, US-001 AC2): anulowanie logowania pokazuje błąd zamiast komunikatu „anulowano"

- Kroki: czysta instalacja (`pm clear`) → EK-02 → zaznacz zgodę → „Zaloguj przez Google" → w oknie wyboru konta przycisk systemowy „wstecz".
- Oczekiwane (US-001 AC2, SIGN-12, CMP-09): od razu powrót na EK-02 ze snackbarem `welcomeSignInCancelled`, bez komunikatu błędu; pole zgody nadal zaznaczone.
- Rzeczywiste: wskaźnik ładowania przez ok. 10–17 s, potem CMP-13 „Błąd": „Nie udało się zalogować. Spróbuj ponownie." (`welcomeSignInError`). Pole zgody zaznaczone, wpis tymczasowy usunięty (to działa).
- Powtarzalność: 2/2.
- Hipoteza (do potwierdzenia przez mobile-dev): `google_sign_in` 7.x na Androidzie zwraca przy zamknięciu `GoogleSignInActivity` inny kod niż `GoogleSignInExceptionCode.canceled` (np. `unknownError` / `providerConfigurationError` po przekroczeniu czasu Credential Manager), więc `classifyGoogleSignInError` daje `generic`. Aplikacja celowo nie loguje kodu (SEC-29) – do diagnozy potrzebny tymczasowy log kodu (bez `description`) w buildzie `dev` debug albo test z atrapą. Do sprawdzenia także zamknięcie okna dotknięciem poza nim.

### Obserwacje (nie blokują)

- **OBS-DEV-1 (UX):** na EK-02 miejsce ilustracji to pusty szary prostokąt (w obu językach) – do potwierdzenia z UX, czy to zamierzony stan przed dostarczeniem grafiki.
- **OBS-DEV-2 (UX/marka):** okno Google „Wybierz konto, aby nadal używać aplikacji Tamitu Dev" pokazuje domyślne logo Flutter – aplikacja nie ma własnej ikony (launcher). Przed testami z użytkownikami – ikona aplikacji (UX + mobile-dev).
- **OBS-DEV-3 (prywatność logów, security):** UID w logcat z biblioteki Firebase Auth (poziom D) – logi systemowe czytelne tylko przez `adb`/aplikacje z uprawnieniem, ale warto ocenić (T7, U-13) i odnotować w rejestrze ryzyk; token debug App Check w logcat – wynika z dostawcy debug (`dev`), w `prod` dostawca Play Integrity.
- **OBS-DEV-4 (proces):** każde nowe urządzenie / `pm clear` / reinstalacja = nowy token debug App Check do rejestracji. Runbook P3-03 etap 7 mówi o tokenie `owner-laptop` przekazywanym `--dart-define`; dla testów na telefonie wygodniej przekazać zarejestrowany token przez `--dart-define=TAMITU_APP_CHECK_DEBUG_TOKEN` (spoza repo). Propozycja dopisku w `android/FIREBASE.md` (mobile-dev).
- **OBS-DEV-5 (środowisko QA):** ColorOS wymaga „Wyłącz monitorowanie uprawnień" dla `screencap`/`uiautomator` przez `adb`; wygaszanie ekranu 15 s – do listy przygotowania urządzenia testowego.

## 4. Werdykt

**Odrzucone (1 błąd poważny), poza tym ścieżki logowania działają na prawdziwym urządzeniu.**

- Logowanie Google (Credential Manager) z prawdziwym kontem w `tamitu-dev-tadecode`, trwałość sesji (także offline), bramka zgody, przełącznik języka (P-3), brak sieci i ponowienie, wpis tymczasowy bez danych osobowych, odporność na brak `recordConsent` – **zaliczone na urządzeniu**.
- **BUG-DEV-1** (anulowanie = komunikat błędu) narusza US-001 AC2 – do naprawy przez mobile-dev i ponownej weryfikacji na urządzeniu (tylko SIGN-12 i SIGN-14).
- Kliencka i serwerowa część zapisu zgody (`recordConsent` → Firestore) pozostaje niesprawdzona do wdrożenia funkcji w `dev`.

## 5. Sprzątanie po teście (właściciel)

1. Usunąć użytkownika „konto testowe właściciela" z Firebase Auth `dev` (konsola → Authentication), zgodnie z ustaleniem przed testem. W Firestore nie powstały dokumenty (funkcje niewdrożone).
2. Usunąć token debug App Check telefonu z konsoli `dev` (App Check → `pl.tadecode.tamitu.dev` → Manage debug tokens).
3. Na telefonie (opcjonalnie): odinstalować `pl.tadecode.tamitu.dev`, wyłączyć „Wyłącz monitorowanie uprawnień", tryb samolotowy i „Nie przeszkadzać".
