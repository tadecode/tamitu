# Plan testów P3-04: logowanie Google, zgody, `recordConsent`

- Autor (rola): qa · Data: 2026-11-17 · Wersja: 0.1 (przygotowany równolegle z implementacją; bez dostępu do kodu P3-04)
- Zadanie: P3-04 (`docs/backlog.md`) – US-001, US-003 (część), US-002 (warunkowo, QA1); ADR-0004, ADR-0005, ADR-0011 pkt 1, 2, 7, 10, ADR-0012 pkt 5
- Ekrany (`ux-ready`): EK-01, EK-02 (v0.2 zatwierdzona; v0.3 czeka na ponowne zatwierdzenie – QA2), EK-03, EK-06, EK-16; komponent CMP-09
- Źródła: `docs/requirements/US-001..003`, `screens-and-flows.md` (P1, P2, P7, P8), `docs/ux/screens/ek-01/02/03/06/16.md`, `docs/ux/components/consent-checkbox.md`, `docs/ux/accessibility.md`, `docs/api/posrednik-api.md` v0.4, `docs/data/model-danych.md` v0.4, `docs/open-questions.md` (U1, U2, UX6, S16, S18, M1), `docs/security/reviews/2026-11-16-p3-14c-ekrany.md` (P-2, P-3, U-5, U-13, B-1), `docs/architecture/przeglad-ekranow-p3-14c.md` pkt 5
- Użycie: plan do weryfikacji PR P3-04 (CI → reviewer → qa → właściciel). Wynik weryfikacji: `docs/qa/reports/P3-04.md`.

## 1. Zakres

**W zakresie P3-04:**
- EK-01: rozgałęzienie startu – brak sesji → EK-02; sesja ważna → EK-04; nowa wersja polityki (stała `privacyPolicyVersion`) → EK-03; sprawdzenie lokalne, także offline.
- EK-02 + CMP-09: akceptacja polityki, przełącznik PL/EN, logowanie Google, anulowanie, błąd, brak sieci.
- Tymczasowy wpis akceptacji (`shared_preferences`: `version`, `lang`, `acceptedAt`, `consentId`) i dosyłanie `recordConsent` z ponowieniami (idempotencja po `consentId`).
- `recordConsent` w backendzie: zapis do `users/{uid}/consents/{consentId}` (dziś `not_implemented`, `endpoints.ts`).
- EK-03: ponowna akceptacja polityki (wymaga sieci, U2).
- EK-06: ekran zgody na AI i zapis `recordConsent(ai_processing)`. Wejście z EK-05/EK-07 (`generatePlan`) należy do P3-05; tu ekran testujemy w izolacji (QA1).
- `core/errors`: klasyfikacja błędów (ADR-0011 pkt 2), mapowanie `details.code` → EK-16, `consent_required` → EK-03/EK-06/„Zaktualizuj aplikację".
- Sesja: trwałość po restarcie, `unauthenticated` → EK-02, wykrycie usuniętego konta (S18, QA8).

**Poza zakresem (inne zadania):** utrata klucza bazy i wariant EK-03 „dane wyczyszczone" – przepływ (P3-06; tu tylko widok wariantu), przerwane usuwanie konta i EK-15 (P3-08), EK-13 Ustawienia → Prywatność i wycofanie zgody AI (EK-13 nie jest `ux-ready`, P3-14f), wysyłka oczekujących zgód przed `generatePlan` i mapowanie w EK-07 (P3-05), EK-14 wylogowanie (nie jest `ux-ready`; QA1).

## 2. Poziomy testów, narzędzia, konwencja

| Poziom | Skrót | Narzędzie | Gdzie | Blokada (`.farm/test-lock.ps1`) |
|---|---|---|---|---|
| Jednostkowy (Dart) | U | `flutter test`, atrapy (`FirebaseAuth`, `GoogleSignIn`, `FirebaseFunctions`, `SharedPreferences.setMockInitialValues`) | `test/` | nie |
| Jednostkowy (backend) | UB | `vitest` | `backend/functions/test/` | nie |
| Widgetowy | W | `flutter test` + `SemanticsTester`, `meetsGuideline(...)`, `tester.platformDispatcher.textScaleFactorTestValue`, testy złote | `test/` | nie |
| Integracyjny z emulatorem Firebase | I | emulatory Auth, Firestore, Functions (`backend/firebase.json`); po stronie aplikacji `integration_test` na emulatorze Androida z adapterem testowym logowania (QA13) | `integration_test/`, `backend/functions/test/` (tryb emulatora) | tak: `-Resource firebase-emulators`; z aplikacją także `-Resource device` |
| Ręczny na urządzeniu | M | emulator Androida / telefon, TalkBack, Accessibility Scanner, `adb logcat` | lista kontrolna w raporcie | tak: `-Resource device` |

ID testu: `P304-<obszar>-<nr>`. Obszary: GATE (EK-01), SIGN (EK-02/CMP-09), CONS (wpis tymczasowy i ponowienia po stronie klienta), API (`recordConsent` w backendzie), RECON (EK-03), AIC (EK-06), ERR (klasyfikacja błędów, EK-16), SES (sesja, S18), OUT (US-002, warunkowo), L10N, A11Y, PRIV.
Kolumna „P3-03": **tak** = wymaga projektu Firebase i nie da się wykonać teraz (sekcja 7).

## 3. Mapowanie kryteriów akceptacji → testy

| Kryterium (Given / When / Then – skrót) | Testy |
|---|---|
| US-001 AC1: niezalogowany, „Zaloguj przez Google" i sukces u dostawcy → zalogowany, ekran główny | SIGN-10, SIGN-11, CONS-01, M: SIGN-20 |
| US-001 AC2: anulowanie u dostawcy → ekran startowy, komunikat bez błędu technicznego | SIGN-12, ERR-09 |
| US-001 AC3: brak internetu przy logowaniu → komunikat o braku połączenia, ponowienie | SIGN-13, SIGN-15, ERR-04 |
| US-001 AC4: restart aplikacji → nadal zalogowany | GATE-02, GATE-07, GATE-08 |
| US-001 AC5: brak rejestracji i logowania hasłem, brak haseł | SIGN-17, PRIV-03 |
| US-001 AC6: bez akceptacji zgód logowanie zablokowane | SIGN-01, SIGN-04 |
| US-003 AC1: przed logowaniem link do polityki i informacja o AI | SIGN-01, SIGN-03, L10N-04 |
| US-003 AC2: bez akceptacji polityki brak logowania i funkcji AI | SIGN-04, GATE-03, RECON-02; serwer: P3-05 (ADR-0012) |
| US-003 AC3: zgoda AI przy pierwszym formularzu – osobna, niezaznaczona, równorzędne opcje, wymagana treść | AIC-01, AIC-02; wejście z EK-05 – P3-05 |
| US-003 AC4: odmowa AI → powrót z danymi, nic nie wysłane, limit niezużyty | AIC-03; zachowanie danych i limit – P3-05 |
| US-003 AC5: zgoda już wyrażona → nie pytamy ponownie | AIC-08, AIC-09 |
| US-003 AC6: Ustawienia → Prywatność: stan i data zgód | poza P3-04 (EK-13, QA1); dane źródłowe: CONS-01 (`client_at`, `received_at`) |
| US-003 AC7: zgoda AI cofnięta → generowanie zablokowane z wyjaśnieniem | poza P3-04 (EK-13, P3-05; QA1) |
| US-003 AC8: w Ustawieniach link do polityki i usunięcie konta | poza P3-04 (EK-12/EK-13, P3-08; QA1) |
| US-003 AC9: nowa wersja polityki → ponowna akceptacja przy starcie | GATE-03, GATE-04, RECON-01..RECON-08, ERR-07 |
| US-002 AC1–AC6 (wylogowanie) | OUT-01..OUT-06 – tylko jeśli US-002 należy do P3-04 (QA1) |
| Decyzja P-3 (zmiana języka zdejmuje zaznaczenie) | SIGN-06, SIGN-07, RECON-07 |
| ADR-0011 pkt 10 / ADR-0005 Aneks A pkt 4 (wpis tymczasowy, `consentId`) | CONS-01..CONS-10 |
| ADR-0011 pkt 2 i 7, ADR-0012 pkt 5 (sieć, `consent_required`) | ERR-01..ERR-10, AIC-09 |
| S18 (usunięte konto na innym urządzeniu) | SES-04, SES-05 |

## 4. Przypadki testowe

### 4.1 EK-01 – bramka sesji (GATE)
| ID | Poziom | Given / When / Then | Źródło | P3-03 |
|---|---|---|---|---|
| GATE-01 | U, W | **Given** brak sesji Auth **When** start **Then** EK-02, bez migotania EK-04/EK-03 | EK-01 | nie |
| GATE-02 | U | **Given** sesja ważna i lokalny rekord `privacy_policy` = `privacyPolicyVersion` **When** start **Then** EK-04; żadnego wywołania sieciowego przed decyzją | EK-01, ADR-0011 pkt 1 | nie |
| GATE-03 | U | **Given** sesja ważna, ostatni lokalny rekord `privacy-v1`, stała `privacy-v2` **When** start (także offline) **Then** EK-03, nie EK-04 | US-003 AC9, ADR-0011 pkt 1 | nie |
| GATE-04 | U | **Given** rekord `privacy-v10`, stała `privacy-v9` (porównanie po N, nie tekstowo) oraz rekord `privacy-v2`, stała `privacy-v10` **When** start **Then** pierwszy → EK-04, drugi → EK-03 | ADR-0012 pkt 1 | nie |
| GATE-05 | U | **Given** sesja ważna, lokalna akceptacja w bieżącej wersji jeszcze niezsynchronizowana (`synced=0`) **When** start z siecią **Then** EK-04 (brak blokady) i w tle ponowienie `recordConsent` z tym samym `consentId` | ADR-0011 pkt 10 | nie |
| GATE-06 | W | **Given** decyzja trwa > 500 ms **Then** wskaźnik kołowy 48 dp z etykietą TalkBack `commonLoadingLabel`; < 500 ms – bez wskaźnika | EK-01 | nie |
| GATE-07 | I | **Given** zalogowany (Auth emulator) **When** zabicie procesu i ponowny start **Then** EK-04 bez EK-02 | US-001 AC4 | nie |
| GATE-08 | M | **Given** zalogowany **When** tryb samolotowy, zabicie procesu, start **Then** EK-04 (praca offline), brak komunikatu błędu | US-001 AC4, EK-01 „Brak sieci" | tak (realne logowanie) |
| GATE-09 | W | **Given** EK-01 **When** wstecz systemowe **Then** zamknięcie aplikacji | EK-01 | nie |

### 4.2 EK-02 i CMP-09 – akceptacja polityki i logowanie (SIGN)
| ID | Poziom | Given / When / Then | Źródło | P3-03 |
|---|---|---|---|---|
| SIGN-01 | W | **Given** pierwsze wejście **Then** pole zgody niezaznaczone, „Zaloguj przez Google" nieaktywny, podpowiedź `welcomeSignInHint` widoczna; widoczne `welcomePrivacyBody` (informacja o AI), `welcomeAdultsOnly`, link polityki | US-001 AC6, US-003 AC1, CMP-09 | nie |
| SIGN-02 | W | **When** dotknięcie wiersza zgody **Then** zaznaczone, przycisk aktywny, podpowiedź znika; ponowne dotknięcie – odznaczenie i powrót do stanu domyślnego | CMP-09 | nie |
| SIGN-03 | W | **When** dotknięcie linku „polityką prywatności" **Then** otwarcie przeglądarki (atrapa `url_launcher`) z adresem w języku UI; zaznaczenie bez zmian | CMP-09, EK-02; URL EN – QA10 | nie |
| SIGN-04 | W | **Given** pole niezaznaczone **When** dotknięcie przycisku **Then** brak wywołania `GoogleSignIn`/`FirebaseAuth`, brak wpisu tymczasowego | US-001 AC6, US-003 AC2 | nie |
| SIGN-05 | W | **When** przełącznik PL → EN **Then** wszystkie teksty ekranu i link natychmiast w EN | U1, ADR-0006 | nie |
| SIGN-06 | W | **Given** pole zaznaczone **When** zmiana języka PL → EN i EN → PL **Then** zaznaczenie zdjęte, przycisk nieaktywny | P-3 | nie |
| SIGN-07 | W | **Given** pole zaznaczone **When** zmiana motywu systemu (jasny ↔ ciemny) lub obrót ekranu **Then** zaznaczenie zostaje (zdejmuje je tylko język) | P-3 (granica) | nie |
| SIGN-08 | W | **Given** dotknięto „Zaloguj" **Then** stan ładowania (`welcomeSigningIn`), pole zgody i przełącznik języka nieaktywne; drugie dotknięcie nie uruchamia drugiego logowania | EK-02 „Ładowanie" | nie |
| SIGN-09 | W | **Given** EK-02 **When** wstecz systemowe **Then** zamknięcie aplikacji | EK-02 | nie |
| SIGN-10 | U | **Given** pole zaznaczone **When** „Zaloguj" **Then** wpis tymczasowy powstaje **dopiero teraz** z `version`=`privacyPolicyVersion`, `lang`=język UI z tej chwili, `acceptedAt`, `consentId` (UUID v4) | CMP-09, ADR-0011 pkt 10; QA4 | nie |
| SIGN-11 | I | **Given** atrapa Google zwraca token przyjmowany przez Auth emulator **When** logowanie **Then** EK-04 w stanie pustym; `recordConsent(privacy_policy, granted=true, privacy-v1, lang, clientAt, consentId)`; dokument `users/{uid}/consents/{consentId}` w Firestore; wpis tymczasowy usunięty | US-001 AC1, ADR-0004 | nie (z adapterem QA13) |
| SIGN-12 | U, W | **When** anulowanie wyboru konta **przy dostępnej sieci** (albo gdy stanu sieci nie da się ustalić; EK-02 v0.4.1, ADR-0015) **Then** EK-02, snackbar `welcomeSignInCancelled` (bez kodu i treści wyjątku), pole nadal zaznaczone w tej sesji ekranu, wpis tymczasowy usunięty, brak `recordConsent` | US-001 AC2, CMP-09 | nie |
| SIGN-13 | U, W | **When** `network-request-failed` (Auth), błąd sieci `google_sign_in`, brak sieci po wyborze konta (GMS zwraca „anulowano”) lub anulowanie wyboru konta przy pewnym braku sieci (EK-02 v0.4.1, ADR-0015) **Then** CMP-13 ostrzeżenie z ikoną `wifi-off-01` i `commonOfflineNotice` nad przyciskiem, przycisk aktywny, wpis tymczasowy usunięty | US-001 AC3, ADR-0011 pkt 2 | nie |
| SIGN-14 | U, W | **When** inny błąd logowania (np. `internal-error`, błąd konfiguracji) **Then** CMP-13 „Błąd" z `welcomeSignInError`, przycisk aktywny, wpis tymczasowy usunięty | EK-02 „Błąd" | nie |
| SIGN-15 | W | **Given** po SIGN-13 **When** ponowienie i sukces **Then** komunikat znika, EK-04; nowa próba tworzy nowy wpis tymczasowy | US-001 AC3 | nie |
| SIGN-16 | M | **Given** pole zaznaczone **When** aplikacja w tle, zabicie procesu (`adb shell am kill`), powrót **Then** pole niezaznaczone, brak wpisu tymczasowego | CMP-09, P-3 | nie |
| SIGN-17 | W, U | **Then** na żadnym ekranie P3-04 nie ma pola hasła, e-maila, rejestracji ani innego dostawcy; w `lib/` brak wywołań `signInWithEmailAndPassword`, `createUserWithEmailAndPassword`, `signInAnonymously` (test statyczny) | US-001 AC5, N9 | nie |
| SIGN-18 | W | **Given** EK-02 otwarty z flagą „konto usunięte" **Then** snackbar `startAccountDeleted` | EK-02, S18 | nie |
| SIGN-19 | M | Przycisk logowania zgodny z wytycznymi marki Google (logo „G" tylko wg wytycznych albo sam tekst) | EK-02 „Układ" | nie |
| SIGN-20 | M | **Given** prawdziwe konto Google **When** logowanie (Credential Manager) **Then** wybór konta bez ekranu dodatkowych uprawnień (tylko podstawowe zakresy), EK-04 | ADR-0004 | **tak** |

### 4.3 Wpis tymczasowy i ponowienia `recordConsent` – klient (CONS)
| ID | Poziom | Given / When / Then | Źródło | P3-03 |
|---|---|---|---|---|
| CONS-01 | U | **When** `recordConsent` zwraca 200 **Then** wiersz `consents_local` (`id`=`consentId`, `type`, `granted=1`, `policy_version`, `lang`, `client_at`, `received_at` z odpowiedzi, `synced=1`) i usunięcie wpisu tymczasowego | ADR-0005 Aneks A pkt 4, model danych; QA3 | nie |
| CONS-02 | U | **Given** logowanie udane, `recordConsent` kończy się błędem transportu (`unavailable` bez `details.code`) **Then** EK-04 bez blokady i bez komunikatu błędu; rekord pozostaje `synced=0` | ADR-0011 pkt 10 | nie |
| CONS-03 | U | **Given** rekord `synced=0` **When** kolejny start z siecią **Then** ponowienie z **tym samym** `consentId`, `clientAt`, `lang`, `version` | ADR-0011 pkt 10 | nie |
| CONS-04 | U | **Given** rekord `synced=0` **When** „Zgadzam się" w EK-06 **Then** najpierw rekord oczekujący `privacy_policy`, potem `ai_processing` (kolejność wywołań) | ADR-0011 pkt 10 | nie |
| CONS-05 | U | **Given** dwa wyzwalacze naraz (start i EK-06) **Then** jedno wywołanie w locie na `consentId`, jeden wiersz lokalny | idempotencja | nie |
| CONS-06 | U | **Given** odpowiedź utracona po zapisie na serwerze (atrapa: wyjątek po sukcesie) **When** ponowienie **Then** ten sam `consentId`, wiersz lokalny `synced=1` po drugiej odpowiedzi, brak drugiego wiersza | API pkt 3 | nie |
| CONS-07 | U | **Given** ponowienie kończy się błędem nieponawialnym (`invalid_argument`, `unsupported_version`) **Then** brak nieskończonej pętli ponowień; zachowanie wg odpowiedzi na QA6 | QA6 | nie |
| CONS-08 | U | **Given** rekord oczekujący konta A **When** wylogowanie i logowanie kontem B przed synchronizacją **Then** rekord konta A nie zostaje wysłany z tokenem konta B | QA5 | nie |
| CONS-09 | U | **Then** wpis tymczasowy zawiera wyłącznie `version`, `lang`, `acceptedAt`, `consentId` – bez UID, e-maila, nazwy | ADR-0005 Aneks A pkt 4, ADR-0011 | nie |
| CONS-10 | I | **Given** zegar urządzenia przesunięty o +3 dni **When** `recordConsent` **Then** serwer zapisuje czas serwera z oznaczeniem korekty; klient przyjmuje odpowiedź (`synced=1`) | API pkt 3 | nie |

### 4.4 `recordConsent` – backend (API)
| ID | Poziom | Given / When / Then | Źródło | P3-03 |
|---|---|---|---|---|
| API-01 | UB | **When** `type` spoza {`privacy_policy`, `ai_processing`}, `lang` spoza {`pl`, `en`} **Then** `invalid_argument` z `field` (bez wartości) | API pkt 3 | nie |
| API-02 | UB | **When** `policyVersion` = `privacy-v0`, `privacy-v01`, `privacy-v10000`, `Privacy-v1`, `privacy-v1 ` **Then** `invalid_argument`, `field: policyVersion` | ADR-0012 pkt 1 | nie |
| API-03 | UB | **When** prefiks niezgodny z typem (`privacy_policy` + `ai-consent-v1`) lub wersja spoza listy znanych (`privacy-v2`) **Then** `invalid_argument`, `field: policyVersion` | ADR-0012 pkt 2, SEC-21 | nie |
| API-04 | UB | **When** `consentId` nie jest UUID, żądanie > 4 KB, `apiVersion` niezgodna **Then** odpowiednio `invalid_argument` / `invalid_argument` / `unsupported_version` | API pkt 1, 3 | nie |
| API-05 | I | **When** poprawne żądanie **Then** dokument `users/{uid}/consents/{consentId}` z polami `type`, `granted`, `policyVersion`, `lang`, `clientAt`, `receivedAt` – bez innych pól; odpowiedź `{consentId, receivedAt}` | model danych pkt 3 | nie |
| API-06 | I | **When** to samo żądanie dwukrotnie **Then** jeden dokument, `receivedAt` bez zmian po drugim wywołaniu | API pkt 3; QA7 | nie |
| API-07 | I | **When** ten sam `consentId` z inną treścią (`granted`, `type` lub wersją) **Then** zachowanie wg QA7 (oczekiwane: pierwszy zapis nienaruszony) | QA7 | nie |
| API-08 | I | **Given** użytkownik usunięty w Auth emulatorze, stary token **When** `recordConsent` **Then** `unauthenticated`, brak dokumentu | ADR-0002 Aneks A pkt 1 | nie |
| API-09 | I | **Given** token innego dostawcy (emulator: hasło, anonimowe) **Then** `unauthenticated` | ADR-0004 | nie |
| API-10 | UB | **Given** `enforceAppCheck=true`, brak tokenu App Check **Then** `app_check_failed`, brak zapisu | API pkt 3 | nie (realny App Check: tak) |
| API-11 | I | **Then** reguły Firestore `deny all`: SDK klienta nie odczyta ani nie zapisze `users/{uid}/consents` (także własnego UID) | ADR-0005 pkt 3 | nie |
| API-12 | I | **Given** ostatni rekord `privacy-v1`, na liście znanych `privacy-v2` **When** `recordConsent(privacy-v2)` **Then** zapis przyjęty (funkcja nie wymaga aktualnej akceptacji) | ADR-0012 opcja 4 | nie |

### 4.5 EK-03 – ponowna akceptacja polityki (RECON)
| ID | Poziom | Given / When / Then | Źródło | P3-03 |
|---|---|---|---|---|
| RECON-01 | W | **Then** tytuł `reconsentTitle`, `reconsentBody`, link, CMP-09 niezaznaczone, „Akceptuję i przechodzę dalej" nieaktywny z powodem, „Wyloguj" i „Usuń konto" (tekst `error`), bez strzałki wstecz | EK-03 | nie |
| RECON-02 | W | **When** wstecz systemowe **Then** zamknięcie aplikacji; po ponownym starcie znów EK-03 | U2 | nie |
| RECON-03 | I | **Given** stała `privacy-v2`, rekord `privacy-v1` **When** zaznaczenie i „Akceptuję" **Then** `recordConsent(privacy_policy, privacy-v2)` z nowym `consentId`, wiersz `synced=1`, EK-04; kolejny start – bez EK-03 | US-003 AC9 | nie |
| RECON-04 | W | **Given** brak sieci **When** „Akceptuję" **Then** CMP-13 `reconsentOffline`, pozostaje na EK-03; po restarcie znów EK-03 (brak lokalnej akceptacji) | U2 | nie |
| RECON-05 | W | **Given** błąd `internal` **Then** `reconsentSaveError`, ponowienie z tym samym `consentId` | EK-03 „Błąd" | nie |
| RECON-06 | W | **When** „Wyloguj" / „Usuń konto" **Then** przejście do EK-14 / EK-15 (wywołanie nawigacji; ekrany docelowe poza P3-04) | EK-03, U2 | nie |
| RECON-07 | W, M | **Given** zaznaczone, aplikacja w języku systemu **When** zmiana języka systemu PL ↔ EN **Then** zaznaczenie zdjęte | EK-03 „Uzgodnienie", P-3; QA11 | nie |
| RECON-08 | W | **Given** parametr „dane wyczyszczone" **Then** treść `reconsentBodyDataReset` zamiast `reconsentBody` (przepływ wejścia – P3-06) | ADR-0011 pkt 9 | nie |
| RECON-09 | U, W | **When** `unauthenticated` przy zapisie **Then** EK-02 + `errorSessionExpired`; **When** `unsupported_version` **Then** CMP-18 „Zaktualizuj aplikację" (dostępność „Wyloguj"/„Usuń konto" – QA9) | EK-16, ADR-0011 pkt 4 | nie |

### 4.6 EK-06 – zgoda na AI (AIC)
| ID | Poziom | Given / When / Then | Źródło | P3-03 |
|---|---|---|---|---|
| AIC-01 | W | **Then** treść zawiera: dane podróży, preferencje, język planu, odbiorcę (usługa AI, region UE), „czego nie wysyłamy" (e-mail, nazwa, identyfikator konta, lokalizacja, numer lotu), błędy AI, ostrzeżenie o danych wrażliwych, wycofanie, administratora, link polityki; brak pola wyboru i brak wyboru domyślnego | US-003 AC3, EK-06 | nie |
| AIC-02 | W | **Then** „Zgadzam się" i „Nie zgadzam się": oba outlined, ta sama szerokość i styl, kolejność stała (bez losowania), każdy ≥ 48 dp | U-5, EK-06 | nie |
| AIC-03 | U, W | **When** „Nie zgadzam się", strzałka lub wstecz systemowe **Then** powrót, **brak** `recordConsent` i brak rekordu lokalnego, brak wywołania `generatePlan` | US-003 AC4, U-5 | nie |
| AIC-04 | I | **When** „Zgadzam się" **Then** `recordConsent(ai_processing, granted=true, ai-consent-v1, lang)`, wiersz `synced=1`, wynik „dalej" do wywołującego | EK-06, ADR-0011 pkt 10 | nie |
| AIC-05 | W | **Given** zapis trwa **Then** „Zgadzam się" w stanie ładowania, „Nie zgadzam się" nieaktywny | EK-06 „Ładowanie" | nie |
| AIC-06 | W | **Given** brak sieci **When** „Zgadzam się" **Then** CMP-13 `aiConsentOffline`, brak rekordu „zgoda wyrażona", powrót możliwy | EK-06 | nie |
| AIC-07 | W | **Given** błąd zapisu **Then** CMP-13 `aiConsentSaveError`, wynik „nie dalej" (nic nie wysłane do AI) | EK-06 | nie |
| AIC-08 | U | **Given** zsynchronizowana zgoda `ai_processing` w wersji aplikacji **When** zapytanie „czy pokazać EK-06" **Then** nie | US-003 AC5 | nie |
| AIC-09 | U, W | **Given** `consent_required` + `ai_processing` i **brak** zsynchronizowanego rekordu w wersji aplikacji **Then** EK-06 ze wstępem `aiConsentUpdatedIntro`; przy zsynchronizowanym rekordzie **Then** CMP-18 „Zaktualizuj aplikację", nie EK-06 (bez pętli) | ADR-0011 pkt 7, EK-06, EK-16 | nie |
| AIC-10 | U | Test skrótu treści: zmiana tekstu zgody AI lub `consentPolicyCheckbox` (PL lub EN) bez podniesienia wersji (`ai-consent-vN`, `privacy-vN`) kończy test błędem | ADR-0006 Aneks A pkt 1, T30, przegląd architekta pkt 5.3 | nie |

### 4.7 Klasyfikacja błędów i EK-16 (ERR)
| ID | Poziom | Given / When / Then | Źródło | P3-03 |
|---|---|---|---|---|
| ERR-01 | U | `FirebaseFunctionsException(unavailable)` **bez** `details.code` → „brak sieci" | ADR-0011 pkt 2 | nie |
| ERR-02 | U | `unavailable` z `details.code=ai_unavailable` → `ai_unavailable` (nie „brak sieci") | API pkt 6 | nie |
| ERR-03 | U | `deadline-exceeded` → „przekroczony czas" | ADR-0011 pkt 2 | nie |
| ERR-04 | U | `FirebaseAuthException(network-request-failed)` i wyjątek sieciowy `google_sign_in` → „brak sieci" | ADR-0011 pkt 2 | nie |
| ERR-05 | U | Każdy kod z tabeli API pkt 6 → właściwy klucz EK-16; nieznany kod i `app_check_failed` → `errorGenericTitle`/`errorGenericBody` | EK-16 | nie |
| ERR-06 | U | `consent_required` z `privacy_policy` → EK-03; z `ai_processing` → EK-06 (AIC-09); bez `consentType` lub z nieznanym → wg QA12 | ADR-0012 pkt 5; QA12 | nie |
| ERR-07 | U | `consent_required` + `privacy_policy`, gdy lokalna akceptacja wersji wbudowanej **jest zsynchronizowana** → „Zaktualizuj aplikację", nie EK-03 | ADR-0012 pkt 5, EK-16 | nie |
| ERR-08 | W | `unsupported_version` → CMP-18 `errorUpdateTitle`/`errorUpdateBody`; „Zaktualizuj aplikację" otwiera `play.google.com/store/apps/details?id=pl.tadecode.tamitu` | U3, EK-16 | nie |
| ERR-09 | W | Dla każdego kodu tekst na ekranie = wyłącznie tekst z ARB; brak `details.code`, `field`, `minVersion`, `message` wyjątku i śladu stosu | US-011, U-13 | nie |
| ERR-10 | U | Żadne automatyczne ponowienie nie dotyczy `generatePlan`; dotyczy tylko `recordConsent` (i `deleteAccount`) | API pkt 6 | nie |

### 4.8 Sesja i usunięte konto (SES)
| ID | Poziom | Given / When / Then | Źródło | P3-03 |
|---|---|---|---|---|
| SES-01 | U, W | **When** dowolna funkcja zwraca `unauthenticated` **Then** EK-02 + snackbar `errorSessionExpired`; dane lokalne nietknięte | EK-16 | nie |
| SES-02 | U | **When** `idTokenChanges` emituje `null` **Then** router przechodzi do EK-02 | ADR-0004 | nie |
| SES-03 | I, M | **Given** odwołane tokeny (`revokeRefreshTokens`) lub token po ~1 h bez odświeżenia **When** wywołanie funkcji **Then** jak SES-01 | ADR-0004 | **tak** (emulator Auth nie odwzorowuje odwołania i wygaśnięcia) |
| SES-04 | I | **Given** konto usunięte z innego urządzenia (emulator: `deleteUser`) **When** następne wywołanie sieciowe (np. dosłanie `recordConsent`) **Then** wykrycie usuniętego konta, usunięcie pliku bazy tego konta, komunikat dla użytkownika, EK-02 | S18; QA8 | nie (plik bazy – po P3-06) |
| SES-05 | U | **Given** `unauthenticated`, a `reload()` potwierdza, że konto istnieje (lub brak sieci) **Then** dane lokalne **nie** są kasowane | S18; QA8 | nie |
| SES-06 | I | **Given** konto usunięte **When** ponowne logowanie tym samym kontem Google **Then** nowy UID, EK-02 wymaga akceptacji, nowy rekord `privacy_policy` | ADR-0004 | nie (E2E: P3-08) |

### 4.9 Wylogowanie – US-002 (OUT, warunkowo – QA1)
| ID | Poziom | Given / When / Then | Źródło | P3-03 |
|---|---|---|---|---|
| OUT-01 | W | „Wyloguj" → dialog z treścią US-002 AC1 (plany zostają, inne konto ich nie zobaczy, usuwanie planów/konta), przyciski „Wyloguj" i „Anuluj", PL/EN | US-002 AC1 | nie |
| OUT-02 | W | „Anuluj" → zalogowany, bez zmian | US-002 AC2 | nie |
| OUT-03 | I | Potwierdzenie → `GoogleSignIn.signOut()` + `FirebaseAuth.signOut()`, EK-02 z niezaznaczonym polem zgody | US-002 AC3, ADR-0004 | nie |
| OUT-04 | W | W trakcie generowania „Wyloguj" niedostępne | US-002 AC4 | nie (po P3-05) |
| OUT-05 | I | Po wylogowaniu i logowaniu innym kontem – brak planów konta A; tym samym kontem – plany widoczne | US-002 AC5, AC6 | nie (po P3-06) |
| OUT-06 | M | Po wylogowaniu kolejne logowanie pokazuje wybór konta Google | P-6 | **tak** |

### 4.10 PL/EN, motyw, duży tekst, TalkBack (L10N, A11Y)
| ID | Poziom | Given / When / Then | Źródło | P3-03 |
|---|---|---|---|---|
| L10N-01 | U | Komplet kluczy EK-01, EK-02, EK-03, EK-06, EK-16, CMP-09 w `app_pl.arb` i `app_en.arb`; brak pustych wartości; te same placeholdery (`{policyLink}`, `{date}`, `{limit}`, `{time}`) | US-011, ADR-0006 | nie |
| L10N-02 | U | Język domyślny: urządzenie PL → PL, EN → EN, inny (np. DE) → EN; zapisany `uiLanguage` ma pierwszeństwo | ADR-0006, U1 | nie |
| L10N-03 | U | `consentPolicyCheckbox` – jeden klucz w CMP-09, EK-02, EK-03; forma neutralna (bez „-łem(-am)") | P-2, UX6, S16 | nie |
| L10N-04 | M | Link polityki otwiera wersję w języku UI (PL i EN) | US-003 AC1; QA10 | nie |
| A11Y-01 | W | Testy złote EK-02, EK-03, EK-06 i stanów EK-16 (CMP-13, CMP-18) w 4 wariantach: PL/EN × jasny/ciemny | accessibility.md | nie |
| A11Y-02 | W | Skala tekstu 1,5 i 2,0 przy szerokości 320 dp: brak przepełnień (`RenderFlex overflowed`); przyciski przestają być przyklejone i przewijają się z treścią (EK-02, EK-06); ilustracja EK-02 96 dp przy 150%, ukryta przy 200% | EK-02, EK-06, accessibility.md | nie |
| A11Y-03 | W | `meetsGuideline(androidTapTargetGuideline)`, `labeledTapTargetGuideline`, `textContrastGuideline` – jasny i ciemny motyw | accessibility.md | nie |
| A11Y-04 | W | Semantyka: etykieta pola zgody = tekst widoczny; link osobny („link, otwiera przeglądarkę"); nieaktywny przycisk z podpowiedzią; ilustracja wykluczona; znak słowny/tytuły jako nagłówki; kolejność fokusu wg EK-02/EK-03/EK-06 | CMP-09, P-2 | nie |
| A11Y-05 | M | TalkBack: pełne przejście EK-02, EK-03, EK-06, stanów EK-16; CMP-13/CMP-14 ogłaszane (live region), CMP-18 przenosi fokus na tytuł | accessibility.md pkt 4 | nie |
| A11Y-06 | M | Skala czcionki 200% + największy rozmiar wyświetlania: wszystkie działania osiągalne, brak ucinania | accessibility.md | nie |
| A11Y-07 | M | Accessibility Scanner bez ostrzeżeń; ciemny motyw: kontrast, ikony, przygaszona ilustracja EK-02 | accessibility.md, EK-02 | nie |

### 4.11 Prywatność (PRIV)
| ID | Poziom | Given / When / Then | Źródło | P3-03 |
|---|---|---|---|---|
| PRIV-01 | U | Test statyczny `lib/`: brak `print`, `debugPrint`, `dart:developer log` poza dozwolonym opakowaniem (analogicznie do `no-direct-logging.test.ts` w backendzie) | T7, U-13 | nie |
| PRIV-02 | U | Opakowanie logowania w trybie release nic nie zapisuje; w debug nie przyjmuje obiektów wyjątków z `details` | T7, U-13 | nie |
| PRIV-03 | U, W | `lib/` nie odczytuje `email`, `displayName`, `photoURL`, `phoneNumber` z `User`/`GoogleSignInAccount` (test statyczny); UI nie pokazuje danych konta | ADR-0004 (D1), U-3 | nie |
| PRIV-04 | I | Logi funkcji przy `recordConsent` (emulator): tylko metadane (`uidHash`, kod, rozmiar) – bez UID, treści zgody, `consentId`, `lang` | ADR-0002, model danych (D11) | nie (Cloud Logging: tak) |
| PRIV-05 | M | `adb logcat` na buildzie release podczas SIGN-11, RECON-03, AIC-04 i błędów: brak e-maila, nazwy, UID, tokenów, `details`; logi bibliotek Google/Firebase odnotować osobno | T7, U-13 | częściowo (pełny przebieg: tak) |
| PRIV-06 | U | Wpis tymczasowy usuwany po udanym `recordConsent` (CONS-01) i po nieudanym logowaniu (SIGN-12..14) | ADR-0005 Aneks A pkt 4 | nie |

## 5. Stany brzegowe – zestawienie

| Stan | Testy |
|---|---|
| Brak sieci | SIGN-13, SIGN-15, CONS-02, CONS-03, RECON-04, AIC-06, ERR-01, ERR-04, GATE-08, SES-05 |
| Anulowanie logowania Google | SIGN-12, PRIV-06 |
| Odmowa akceptacji polityki | SIGN-04, RECON-02, RECON-04 |
| Odmowa zgody na AI | AIC-03 (bez rekordu, U-5) |
| Nowa wersja polityki / `consent_required` | GATE-03, GATE-04, RECON-01..09, ERR-06, ERR-07, AIC-09 |
| Ponowienia `recordConsent` (idempotencja po `consentId`) | CONS-03..CONS-08, API-06, API-07, RECON-05 |
| Wygaśnięcie sesji | SES-01..SES-03, RECON-09 |
| Usunięte konto (S18) | SES-04..SES-06, API-08, SIGN-18 |
| Zmiana języka zdejmuje zaznaczenie (P-3) | SIGN-06, SIGN-07 (granica), RECON-07 |
| Zabicie procesu | SIGN-16, GATE-07 |
| Zegar urządzenia | CONS-10 |

## 6. Liczba przypadków

| Obszar | Liczba |
|---|---|
| GATE | 9 |
| SIGN | 20 |
| CONS | 10 |
| API | 12 |
| RECON | 9 |
| AIC | 10 |
| ERR | 10 |
| SES | 6 |
| OUT (warunkowo) | 6 |
| L10N | 4 |
| A11Y | 7 |
| PRIV | 6 |
| **Razem** | **109** (w tym 6 warunkowych OUT) |

Według poziomu (przypadek z kilkoma poziomami liczony przy każdym): U/UB 47, W 44, I 18, M 12.

## 7. Czego nie da się przetestować przed P3-03 (projekty Firebase)

| Obszar | Testy | Dlaczego |
|---|---|---|
| Prawdziwe logowanie Google (Credential Manager, odciski SHA-1/SHA-256, identyfikator klienta web, `google-services.json`), zakresy OAuth | SIGN-20, GATE-08, OUT-06 | wymaga klienta OAuth w projekcie Firebase; emulator Auth przyjmuje tylko spreparowane tokeny |
| Logowanie w buildzie release podpisanym kluczem uploadu / Play App Signing | SIGN-20 (powtórka na release) | odciski klucza release w projekcie |
| App Check (Play Integrity) i `app_check_failed` na żywym backendzie | API-10 (część „realna") | emulator nie wymusza App Check |
| Odwołanie i wygaśnięcie tokenów | SES-03 | emulator Auth nie odwzorowuje |
| Region Firestore `europe-west4`, indeks `consents` (`type`, `receivedAt`) | – (sprawdzenie konfiguracji) | brak projektu |
| Cloud Logging: `uidHash` (HMAC z pieprzem z Secret Managera), kubełek UE 30 dni | PRIV-04 (część „realna") | brak projektu i Secret Managera |
| Pełny przebieg `adb logcat` z realnym logowaniem | PRIV-05 | jak wyżej |
| S18 na dwóch fizycznych urządzeniach | SES-04 (E2E) | realne konto; emulator pokrywa logikę |

Do tego czasu: testy U/UB/W w CI, testy I na emulatorach Firebase przez `.farm/test-lock.ps1 -Resource firebase-emulators` (z aplikacją także `-Resource device`), testy M dotyczące UI (PL/EN, motywy, 200%, TalkBack) na emulatorze Androida z adapterem testowym logowania (QA13). Testy oznaczone „tak" trafiają do raportu jako „odłożone do P3-03" i są powtarzane po P3-03.

## 8. Kryteria „done" dla P3-04 (perspektywa QA)

1. Każde kryterium z sekcji 3 w zakresie P3-04 ma test zautomatyzowany lub udokumentowaną weryfikację ręczną; wiersze „poza P3-04" mają wskazane zadanie docelowe w backlogu.
2. CI zielone: `flutter analyze`, `flutter test` (U, W, w tym L10N-01, AIC-10, PRIV-01, PRIV-03, A11Y-01..04), `vitest` (UB).
3. Testy I na emulatorach Firebase uruchomione przez `.farm/test-lock.ps1` i zielone; wynik (polecenie, data, liczba testów) w `docs/qa/reports/P3-04.md`.
4. Lista ręczna (M) wykonana na emulatorze Androida: PL i EN, jasny i ciemny motyw, 200%, TalkBack, Accessibility Scanner; zrzuty ekranów bez danych osobowych (konta testowe).
5. Prywatność: PRIV-01..06 zaliczone; zero `details` i kodów technicznych w UI (ERR-09).
6. Brak otwartych błędów krytycznych i poważnych; drobne – jako zadania w `docs/backlog.md`.
7. Luki QA1–QA14 rozstrzygnięte albo jawnie odłożone przez orkiestratora/właściciela, z adnotacją, które testy na nich czekają (CONS-07, CONS-08, API-07, ERR-06, SES-04, SES-05, RECON-07, RECON-09, SIGN-03).
8. Testy wymagające P3-03 (sekcja 7) zapisane w raporcie jako „odłożone", z zadaniem powtórki w backlogu; nie blokują `done` P3-04, blokują pierwsze wydanie testowe z realnym projektem.
9. Dokumentacja zaktualizowana (backlog, dziennik); reviewer zatwierdził PR; werdykt QA „przyjęte" zapisany przed zatwierdzeniem właściciela.

## 9. Luki w wymaganiach

Wpisane jako osobne wiersze w `docs/open-questions.md` (sekcja „Plan testów P3-04, qa, 2026-11-17"): QA1–QA14.

| # | Skrót | Testy, które czekają |
|---|---|---|
| QA1 | Zakres P3-04: US-002/EK-14, US-003 AC6–AC8 (EK-13), wejście EK-06 z EK-05 | OUT-01..06, sekcja 3 |
| QA2 | Która wersja EK-02 jest normą dla P3-04 (v0.2 zatwierdzona czy v0.3 do ponownego zatwierdzenia) | SIGN-01, A11Y-01, A11Y-02 |
| QA3 | Gdzie P3-04 zapisuje `consents_local`, zanim powstanie baza SQLCipher (P3-06) | CONS-01, GATE-02..05 |
| QA4 | Kiedy powstaje `consentId` i `acceptedAt` (zaznaczenie vs „Zaloguj"); nowy `consentId` po anulowaniu | SIGN-10, SIGN-15 |
| QA5 | Przypisanie oczekującego rekordu do konta (wpis bez UID) przy zmianie konta | CONS-08 |
| QA6 | Wyzwalacze i limit ponowień; błędy nieponawialne | CONS-07 |
| QA7 | Ten sam `consentId` z inną treścią; `receivedAt` przy powtórce | API-06, API-07 |
| QA8 | Odróżnienie usuniętego konta od wygasłej sesji (S18); komunikat | SES-04, SES-05 |
| QA9 | EK-03 przy `unsupported_version` – czy „Wyloguj"/„Usuń konto" dostępne | RECON-09 |
| QA10 | Adres polityki w EN | SIGN-03, L10N-04 |
| QA11 | Zmiana języka na EK-03 (brak przełącznika) | RECON-07 |
| QA12 | `consent_required` bez `consentType` lub z nieznanym | ERR-06 |
| QA13 | Adapter testowy logowania Google (tylko testy/`dev`) przed P3-03 | SIGN-11, testy I i M z logowaniem |
| QA14 | Ponowne logowanie użytkownika z aktualną akceptacją – nowe zaznaczenie i nowy rekord | SES-01, OUT-03 |
