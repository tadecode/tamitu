# Weryfikacja P3-04 – runda 3: przypadki integracyjne (Firebase)

- Autor (rola): qa · Data: 2026-11-18 · Gałąź: `docs/qa-P3-04-int` · Kod: `main` @ `d1cd591` (P3-04 + SEC-20, PR #70)
- Norma: `docs/qa/test-plan-p3-04.md` (sekcje 4.4, 7, 8), poprzednio `docs/qa/verify-p3-04-r2.md` (runda 2: odrzucone – kryteria 3 i 4 niewykonalne na maszynie)
- Zakres rundy 3: tylko zaległe przypadki wymagające Firebase (I – emulatory; M/SIGN-20 – urządzenie z flavorem `dev`). Przypadki U/W/UB bez zmian względem rundy 2.
- Dane: wyłącznie syntetyczni użytkownicy emulatora Auth (`qa-<uuid>@example.test`); projekt emulatora `demo-tamitu-qa` (prefiks `demo-` – emulatory nie łączą się z żadnym prawdziwym projektem). `ALLOW_REAL_DATA=false`.

## 1. Środowisko i polecenia

| Element | Stan |
|---|---|
| Firebase CLI | 15.36.0 (emulatory Auth, Functions, Firestore; JAR-y pobrane przez CLI) |
| Java dla emulatorów | JBR z Android Studio (OpenJDK 25.0.4), `JAVA_HOME` ustawiane tylko w przebiegu |
| Node | 22, `backend/functions`: `npm ci`, `npm run build` |
| Konfiguracja funkcji | `ENVIRONMENT=dev`, `ALLOW_REAL_DATA=false`, `ENFORCE_APP_CHECK=false` (przebieg główny) / nieustawione = wymuszone (przebieg App Check); `UID_HASH_PEPPER` – losowa wartość testowa w `backend/functions/.secret.local` (ignorowany przez git, nie jest prawdziwym sekretem) |
| Skrypt testów | `tests/firebase-emulator/p3-04-record-consent.int.mjs` (ten PR; `node:test` + `fetch`, bez zależności) |

Polecenie (z katalogu repo, przez blokadę zasobów):

```
powershell -NoProfile -ExecutionPolicy Bypass -File .farm/test-lock.ps1 -Resource firebase-emulators -Command "<ustaw env jw.>; cd backend; firebase emulators:exec --project demo-tamitu-qa --only 'auth,functions,firestore' 'node --test --test-concurrency=1 ../tests/firebase-emulator/p3-04-record-consent.int.mjs'"
```

Przebiegi (2026-11-18): **główny – 15/15 zielonych** (34,7 s); **App Check wymuszony – 1/1 zielony**. Dodatkowo `vitest` (UB) na tym samym kodzie: 127/127.

## 2. Wyniki – emulatory Firebase (kryterium 3, część backendowa)

| Przypadek | Wynik | Dowód (test w skrypcie → obserwacja) |
|---|---|---|
| API-05 – poprawny zapis | **zaliczony** | `API-05`: dokument `users/{uid}/consents/{consentId}` ma dokładnie pola `type, granted, policyVersion, lang, clientAt, receivedAt` (daty jako Timestamp); odpowiedź ma tylko `{consentId, receivedAt}`, `receivedAt` = wartość w dokumencie |
| API-06 – idempotencja po `consentId` | **zaliczony** | `API-06`: dwa wywołania w odstępie 1,1 s → 1 dokument, identyczna odpowiedź, `receivedAt` bez zmian. `API-06b`: 5 równoległych wywołań z tym samym `consentId` → wszystkie OK, 1 dokument, jedno `receivedAt` (transakcja + `create()` działa przy wyścigu) |
| API-07 – ten sam `consentId`, inna treść (QA7) | **zaliczony** | `API-07`: zmiana `granted`, `type`+wersji, `lang` → odpowiedź jak przy ponowieniu (pierwsze `receivedAt`), pierwszy zapis nienaruszony. `API-07b`: ten sam `consentId` u dwóch użytkowników → dwa niezależne dokumenty |
| API-08 / SES-04 (część serwerowa) – konto usunięte, stary token | **zaliczony** | `API-08`: `accounts:delete` w emulatorze, potem wywołanie starym tokenem → `UNAUTHENTICATED`/`unauthenticated`, brak dokumentu (`checkRevoked` sprawdza istnienie konta przed zapisem) |
| API-09 – inny dostawca | **zaliczony** | `API-09`: token hasło i anonimowy → `unauthenticated`, brak dokumentu; `API-09b`: brak nagłówka → `unauthenticated` |
| API-10 – App Check (emulator) | **zaliczony (emulator)** | przebieg App Check: `ENFORCE_APP_CHECK` nieustawione (domyślnie wymuszone), brak tokenu → `FAILED_PRECONDITION`/`app_check_failed`, brak dokumentu. Część „realna" (Play Integrity / token debug) – **nie wykonana**, sekcja 3 |
| API-11 – reguły `deny all` | **zaliczony** | `API-11`: token klienta (własny UID) → REST Firestore: odczyt dokumentu 403, lista 403, zapis 403, `config/runtime` 403; liczba dokumentów bez zmian |
| API-12 – zapis bez aktualnej akceptacji | **częściowo** | `API-12 (partial)`: pierwszy w historii rekord (odmowa AI) i ponowna akceptacja polityki przyjęte; historia append-only (3 dokumenty). Wariant „`privacy-v2` na liście znanych" niewykonalny bez zmiany kodu – `KNOWN_VERSIONS` zawiera tylko `privacy-v1` (zgodnie z ADR-0012; `privacy-v2` → `invalid_argument`, sprawdzone w `VAL`) |
| Walidacja przez emulator (API-01..04 end-to-end) | **zaliczony** | `VAL`: 14 wariantów (`privacy-v2`, `-v0`, `-v01`, `Privacy-v1`, spacja, prefiks niezgodny z typem w obie strony, `type`, `lang`, `consentId`, `clientAt`, pole nadmiarowe, > 4 KB, `apiVersion: 2`) → `invalid_argument` z właściwym `field` / `unsupported_version`; `details` nie zawierają wysłanych wartości; brak dokumentu |
| CONS-10 – zegar klienta +3 dni | **zaliczony (serwer)** | `CONS-10`: zapisane `clientAt` = `receivedAt` i `clientAtCorrected: true`; `clientAt` −1 h zachowane bez flagi. Część kliencka (`synced=1`) – wymaga aplikacji, sekcja 3 |
| `consent_required` (ADR-0012 pkt 3–4; AIC-09/ERR po stronie serwera) | **zaliczony** | `CONSENT_REQUIRED` na `generatePlan` z `config/runtime` (`testUids`=[uid], `aiEnabled=false`): brak rekordów → `privacy_policy`; tylko zgoda AI → nadal `privacy_policy`; obie → przechodzi kontrolę (`ai_unavailable`); najnowszy rekord AI `granted=false` → `ai_processing`; ponowna zgoda → przechodzi; `policyVersionCurrent=privacy-v2` → `privacy_policy`; `aiConsentVersionCurrent=ai-consent-v2` → `ai_processing`; zła wersja w konfiguracji (`privacy-v01`) → `consent_required`/`privacy_policy`, `details` = tylko `{code, consentType}`, w logu `configError: consent_versions_invalid`. Status HTTP: `FAILED_PRECONDITION` |
| Polityka danych dev | **zaliczony** | UID spoza `testUids` → `test_data_only` przed odczytem zgód |
| PRIV-04 – logi funkcji (emulator) | **zaliczony (emulator)** | 52 wpisy `fn_event`/`fn_error`: klucze tylko `fn, result, uidHash, durationMs, requestBytes, errorClass, errorCode, days, configError` (+ `severity`, `message`); 0 wystąpień któregokolwiek z 16 UID i 34 `consentId` użytych w przebiegu, 0 e-maili, brak pola `lang`. Uwaga OBS-1. Część „realna" (Cloud Logging, pieprz z Secret Managera) – po wdrożeniu (P3-05) |

**Błędy (BUG-n): brak.** Żaden przypadek backendowy nie wykazał odstępstwa od kontraktu.

### Obserwacje (nie blokują)

- **OBS-1 (drobna, koszt/obserwowalność):** oczekiwane błędy klienta (`consent_required`, `invalid_argument`, `unauthenticated`) są logowane z `severity: ERROR`, a `firebase-functions/logger.error` dokleja do `message` stos wywołań (`Error: fn_error\n at entryFromArgs … handler.js …`; 27 takich wpisów w przebiegu). Bez danych osobowych (tylko ścieżki plików), ale w Cloud Logging/Error Reporting zwykłe odmowy będą wyglądać jak awarie i zwiększą wolumen logów. Propozycja: `WARNING`/`INFO` dla błędów z kontraktu (`AppError`), `ERROR` tylko dla `internal`. Właściciel: mobile-dev (backend), ocena: security.
- **OBS-2:** testy I są dziś skryptem QA w `tests/firebase-emulator/`. Docelowo powinny trafić do `backend/functions` (`npm run test:emulator`) i do CI (Java + emulatory) – zadanie dla mobile-dev/steward.

## 3. Urządzenie / emulator Androida z flavorem `dev` (kryterium 4, SIGN-20, część kliencka I)

| Krok | Wynik | Dowód |
|---|---|---|
| Plik `google-services.json` dev | jest u właściciela (`%USERPROFILE%\.tamitu\firebase\dev\`) | skopiowany do `android/app/src/dev/` tylko na czas buildu; `git check-ignore` potwierdził ignorowanie, `git status` czysty; po teście usunięty. Zawartości nie odczytywano |
| Build `flutter build apk --flavor dev --debug` z wtyczką `google-services` (SEC-20) | **zaliczony** | `√ Built build\app\outputs\flutter-apk\app-dev-debug.apk` (252 s) |
| Start AVD `Medium_Phone_API_37.0` (obraz Google Play, API 37) | **nie uruchomiono – blokada środowiska** | `emulator -avd …`: „x86_64 emulation currently requires hardware acceleration! … Android Emulator hypervisor driver is not installed on this machine" |
| Backend `dev` w chmurze | **brak wdrożonych funkcji** | `POST https://europe-west4-tamitu-dev-tadecode.cloudfunctions.net/recordConsent` i `/generatePlan` (bez tokenu, puste dane) → HTTP 404; zgodne z runbookiem P3-03 (pierwsze wdrożenie przy P3-05; sekret `UID_HASH_PEPPER` bez wersji) |
| Token debug App Check `dev` | **niedostępny dla QA** | wartość tylko w menedżerze haseł właściciela (runbook etap 7), przekazywana `--dart-define=TAMITU_APP_CHECK_DEBUG_TOKEN`; QA jej nie zna i nie powinna jej dostawać w czacie |
| Konto Google testowe na urządzeniu | **niedostępne** | wymaga zalogowania właściciela/konta testowego na AVD |
| Aplikacja wobec emulatorów Firebase | **niemożliwe bez zmiany kodu** | `lib/app/bootstrap.dart` nie ma przełącznika `useAuthEmulator`/`useFunctionsEmulator`; brak `integration_test/` i adaptera logowania (QA13) |

Zgodnie z zadaniem etap urządzenia **zatrzymany**. Nie wykonano: SIGN-20, GATE-08, SIGN-16, SIGN-19, RECON-07 (M), L10N-04, A11Y-05..07, PRIV-05, OUT-06 oraz kliencka część I: GATE-07, SIGN-11, RECON-03, AIC-04, CONS-10 (`synced=1`), SES-04 (usunięcie pliku bazy i EK-02), SES-06.

### Czego brakuje do etapu urządzenia (lista dla właściciela/orkiestratora)

1. **Akceleracja sprzętowa emulatora** – instalacja „Android Emulator hypervisor driver" (SDK Manager → SDK Tools) lub włączenie Windows Hypervisor Platform; zmiana systemowa – tylko właściciel. Alternatywa: fizyczny telefon z debugowaniem USB.
2. **Wdrożenie funkcji w `tamitu-dev-tadecode`** (wraz z wersją sekretu `UID_HASH_PEPPER`) – inaczej logowanie zadziała, ale `recordConsent` zwróci 404 (`not-found`). Albo, bez wdrożenia: **przełącznik emulatorów w aplikacji** (np. `--dart-define=TAMITU_USE_FIREBASE_EMULATORS=true`, tylko `dev` debug) – mobile-dev; to odblokowuje też testy I po stronie aplikacji (QA13).
3. **Token debug App Check** – albo właściciel buduje i uruchamia aplikację sam z `--dart-define`, albo rejestruje osobny token „qa-machine" i przekazuje go poza czatem/repo (np. zmienna środowiskowa użytkownika), wg runbooka etap 7.
4. **Konto Google testowe** zalogowane na AVD/telefonie (nie konto prywatne właściciela; `ALLOW_REAL_DATA=false`) i jego UID w `config/runtime.testUids` dev, jeśli test ma dojść do `generatePlan`.

## 4. Pokrycie po rundzie 3

| Grupa | Runda 2 | Runda 3 |
|---|---|---|
| I – backend (API-05..09, API-11, CONS-10 serwer, SES-04 serwer, PRIV-04 emulator, `consent_required`) | nie uruchomione | **zaliczone** (16/16 testów) |
| API-10 | UB | UB + emulator zaliczony; realny App Check – odłożony |
| API-12 | B | częściowo (wariant z `privacy-v2` wymaga nowej wersji na liście znanych – P3 przy zmianie polityki) |
| I – aplikacja (GATE-07, SIGN-11, RECON-03, AIC-04, SES-04/06 klient) | nie uruchomione | **nie uruchomione** – brak przełącznika emulatorów / adaptera QA13 |
| M (lista ręczna) i F (SIGN-20, GATE-08, OUT-06, PRIV-05) | nie uruchomione | **nie uruchomione** – blokady z sekcji 3 |

## 5. Werdykt

**Warunkowo przyjęte.**

- Kryterium 3 (testy I na emulatorach, `test-lock`) – **spełnione dla backendu**: `recordConsent` (zapis, idempotencja po `consentId` także przy wyścigu, nienaruszalność pierwszego zapisu, walidacja wersji, usunięte konto, inni dostawcy, App Check), reguły `deny all` i `consent_required` działają zgodnie z kontraktem; 0 błędów.
- Kryterium 4 (lista M na urządzeniu) i kliencka część I – **niespełnione z powodu środowiska**, nie kodu: brak akceleracji AVD, brak wdrożonych funkcji w dev, token debug App Check i konto testowe tylko u właściciela, brak przełącznika emulatorów w aplikacji.

Warunek przyjęcia (decyzja orkiestratora/właściciela, plan sekcja 8 pkt 8): P3-04 można zamknąć, jeśli kliencka część I oraz lista M zostaną jawnie odłożone do zadania w backlogu (propozycja: „QA P3-04 na urządzeniu – po P3-05 wdrożeniu dev lub po przełączniku emulatorów") z warunkami z sekcji 3. Bez tej decyzji werdykt pozostaje „odrzucone (środowisko)". Start P3-05 nie zależy od żadnego błędu w P3-04.
