# Weryfikacja QA: P3-04 (PR tadecode/tamitu#57)

- Autor (rola): qa · Data: 2026-11-17 · Wersja: 1.0
- Przedmiot: PR #57 `feat/P3-04` „logowanie Google, zgody i recordConsent (US-001..003)", commit `7263957`
- Norma: plan testów `docs/qa/test-plan-p3-04.md` (PR #54, 109 przypadków)
- Sposób: przegląd kodu i testów PR (`git fetch origin pull/57/head`), uruchomienie testów bez urządzenia w osobnym, odłączonym worktree. Kod aplikacji nie był zmieniany.

## 1. Wynik testów

| Zestaw | Polecenie | Wynik |
|---|---|---|
| Analiza statyczna | `flutter analyze` | brak uwag |
| Flutter (U, W) | `flutter test` | **94 / 94 zielone** |
| Backend (UB) | `npm test` (`vitest run`, `backend/functions`) | **107 / 107 zielone** (6 plików) |
| CI PR #57 | GitHub Actions | `flutter`, `backend`, `farm-guards`, `conventions`, `secrets` – zielone |
| Integracyjne (I) z emulatorem Firebase | – | **nie uruchomiono:** PR nie zawiera `integration_test/` ani skryptu emulatora w `backend/functions`; na tej maszynie brak Firebase CLI i Javy |
| Ręczne (M) na urządzeniu | – | **nie wykonano** (lista kontrolna w sekcji 5); możliwe bez Firebase w buildzie `--dart-define=TAMITU_FAKE_BACKEND=true` przez `.farm/test-lock.ps1 -Resource device` |

## 2. Macierz pokrycia planu

Legenda: **P** – pokryty testem automatycznym; **C** – częściowo (test na niższym poziomie niż w planie, część wariantów albo zachowanie tylko w kodzie); **B** – brak testu lub brak zachowania; **R** – test ręczny, nie wykonany; **F** – wymaga projektu Firebase (P3-03); **N** – nie dotyczy P3-04 (inne zadanie / ekran nie `ux-ready`).

### EK-01 – GATE
| ID | Status | Test w PR #57 / uwaga |
|---|---|---|
| GATE-01 | P | `session_controller_test`: „no session -> signed out", `sessionRedirect` |
| GATE-02 | P | „restored session (offline) with current acceptance -> ready (US-001)" – w obrębie jednego procesu; po restarcie patrz BUG-1 |
| GATE-03 | P | `consent_service_test`: „no record / withdrawn / older version -> reconsent" |
| GATE-04 | C | porównanie po N w `AppConstants.versionNumber` (poprawne w kodzie); brak testu `v10` vs `v9` |
| GATE-05 | C | „offline recordConsent after sign-in does not block EK-04" – tak; ponowienie „przy kolejnym starcie" nie działa (BUG-1, BUG-2) |
| GATE-06 | C | `SessionGateScreen.indicatorDelay = 500 ms` z etykietą `commonLoadingLabel`; brak testu |
| GATE-07 | B | brak testu I; przy obecnym magazynie w pamięci zalogowany użytkownik po restarcie trafia do EK-03, nie do EK-04 (BUG-1) |
| GATE-08 | F | realne logowanie; przy BUG-1 start offline blokuje użytkownika na EK-03 |
| GATE-09 | B | brak testu (trasa korzeniowa – zachowanie prawdopodobnie poprawne) |

### EK-02 i CMP-09 – SIGN
| ID | Status | Test w PR #57 / uwaga |
|---|---|---|
| SIGN-01 | P | `welcome_screen_test`: „EK-02 default state (PL/EN, jasny/ciemny)" |
| SIGN-02 | P | „checking enables sign-in…" |
| SIGN-03 | P | „policy link opens the policy in the UI language and does not toggle"; adres EN `…/prywatnosc/en` przyjęty przez mobile-dev – czeka na QA10 |
| SIGN-04 | P | stan domyślny: przycisk bez akcji |
| SIGN-05 | P | „switching language changes texts…" |
| SIGN-06 | P | jw. – zaznaczenie zdjęte (P-3) |
| SIGN-07 | B | brak testu: motyw / obrót nie zdejmują zaznaczenia |
| SIGN-08 | P | „loading: button busy, checkbox and language disabled, one sign-in only" |
| SIGN-09 | B | brak testu (wstecz zamyka aplikację) |
| SIGN-10 | P | „stage writes version, lang, acceptedAt and consentId - no UID"; `consentId` przy zaznaczeniu (ADR-0011 pkt 10), wpis przy „Zaloguj" (CMP-09) – zgodne z propozycją QA4 co do wpisu |
| SIGN-11 | C | W z atrapami: „success goes to EK-04 and records the consent"; brak I z emulatorem Auth |
| SIGN-12 | P | „cancelled at Google: snackbar, box stays checked, staged entry cleared" |
| SIGN-13 | C | `network-request-failed` (Auth) → „brak sieci" – tak; błąd sieci na etapie `google_sign_in` → komunikat ogólny (BUG-3) |
| SIGN-14 | P | „other error: error notice without technical details" |
| SIGN-15 | P | „offline after a failed attempt: warning notice, retry possible" |
| SIGN-16 | R | stan tylko w pamięci ekranu (kod zgodny) – nie sprawdzono na urządzeniu |
| SIGN-17 | C | ręczny `grep` w `lib/`: brak logowania hasłem, rejestracji, logowania anonimowego; brak testu automatycznego |
| SIGN-18 | C | `WelcomeFlash.accountDeleted` → `startAccountDeleted` w kodzie; test tylko dla `sessionExpired` |
| SIGN-19 | R | nie wykonano |
| SIGN-20 | F | realne konto Google |

### Wpis tymczasowy i ponowienia – CONS
| ID | Status | Test w PR #57 / uwaga |
|---|---|---|
| CONS-01 | C | „adopt -> local unsynced record; sync -> server once, staged entry removed" – tak, ale `consents_local` jest w pamięci procesu (`InMemoryConsentLocalStore`, TODO P3-06; QA3) |
| CONS-02 | P | „offline recordConsent after sign-in does not block EK-04" |
| CONS-03 | C | „sync failure keeps the record and the staged entry; retry is idempotent" – w tym samym procesie; po restarcie rekord ginie, a wpis tymczasowy nie jest ponownie przejmowany (BUG-2) |
| CONS-04 | P | „sends pending records first, then the AI record" |
| CONS-05 | B | brak ograniczenia „jedno wywołanie w locie" (`syncPending` z EK-01 i EK-06 może wysłać ten sam rekord dwa razy; serwer idempotentny – obserwacja O-1) |
| CONS-06 | P | „retry is idempotent" (ten sam `consentId`) |
| CONS-07 | B | brak testu; zachowanie: zatrzymanie na pierwszym błędzie, ponowienie przy kolejnej ocenie sesji – bez pętli, ale bez rozróżnienia błędów nieponawialnych (QA6) |
| CONS-08 | P | „accounts are isolated (N3)"; rekord przypisany do UID przy logowaniu, `syncPending(uid)` tylko dla bieżącego konta |
| CONS-09 | P | „stage writes … - no UID", `prefs_pending_policy_store_test` |
| CONS-10 | P | UB: „replaces clientAt outside ±24 h with server time and flags it", „exactly 24 h is still accepted" |

### `recordConsent` w backendzie – API
| ID | Status | Test w PR #57 / uwaga |
|---|---|---|
| API-01 | P | „recordConsent rejects bad input and deleted users before any write" + `schemas.test.ts` |
| API-02 | P | `consents.test.ts`, `schemas.test.ts` (wzorzec wersji) |
| API-03 | P | „known list holds only well-formed versions with a matching prefix", walidacja prefiksu |
| API-04 | P | `consentId` – `UUID_V4` w `schemas.ts`; rozmiar i `apiVersion` – testy z P3-02 |
| API-05 | C | UB z atrapą zapisu: „stores the record under users/{uid}/consents/{consentId} and returns receivedAt"; transakcja Firestore (`index.ts`) bez testu na emulatorze |
| API-06 | C | UB: „a retry with the same consentId creates no duplicate and keeps the first receivedAt"; brak I |
| API-07 | B | brak testu; zachowanie: pierwszy zapis wygrywa, inna treść cicho ignorowana (zwraca pierwotne `receivedAt`) – QA7 |
| API-08 | C | UB: odrzucenie tokenu odwołanego / usuniętego (`checkRevoked`) przed zapisem; brak I |
| API-09 | P | „rejects … non-Google provider" |
| API-10 | P | „enforces App Check only when enabled" (realny App Check – P3-03) |
| API-11 | B | brak testu reguł Firestore na emulatorze |
| API-12 | P | „does not require current consents (ADR-0012…)" |

### EK-03 – RECON
| ID | Status | Test w PR #57 / uwaga |
|---|---|---|
| RECON-01 | P | `reconsent_screen_test`: „EK-03 default state (PL/EN, jasny/ciemny)" z wytycznymi dostępności |
| RECON-02 | B | brak testu (wstecz) |
| RECON-03 | C | W: „accept saves the acceptance on the server, then EK-04"; brak I; po restarcie znów EK-03 (BUG-1) |
| RECON-04 | P | „offline: notice, not let through; retry uses the same consentId" |
| RECON-05 | P | „save error: error notice, stays on EK-03" |
| RECON-06 | C | „sign out from EK-03 -> EK-02" – bez EK-14 (nie `ux-ready`, odstępstwo opisane w kodzie); „Usuń konto" ukryte do P3-08 |
| RECON-07 | B | brak obsługi i testu zmiany języka systemu (QA11) |
| RECON-08 | P | „data reset variant text" |
| RECON-09 | C | `unauthenticated` → EK-02 + snackbar – test jest; `unsupported_version` → `reconsentSaveError` zamiast „Zaktualizuj aplikację" (BUG-4, QA9) |

### EK-06 – AIC
| ID | Status | Test w PR #57 / uwaga |
|---|---|---|
| AIC-01 | P | `ai_consent_screen_test`: „EK-06 content (PL/EN, jasny/ciemny)" |
| AIC-02 | P | dwa `AppButton.outlined`, stała kolejność; wytyczne celów dotyku w teście treści |
| AIC-03 | P | „I don't agree: pops false, no record (U-5)", „back arrow = disagree, no record" |
| AIC-04 | C | W: „I agree: saves ai-consent-v1 with the UI language, pops true"; brak I |
| AIC-05 | P | „loading: agree busy, disagree disabled" |
| AIC-06 | P | „offline: notice, nothing stored, can still go back" |
| AIC-07 | P | „save error: error notice says nothing was sent" |
| AIC-08 | P | „AI state: none -> notGiven, withdrawn, older version -> notGiven" |
| AIC-09 | P | „updated variant shows the intro", „AI: synced grant -> update app; after withdrawal -> ask again" |
| AIC-10 | P | `guards_test`: przypięte skróty tekstów `privacy-v1`, `ai-consent-v1` (FNV-1a, PL i EN) |

### Błędy i EK-16 – ERR
| ID | Status | Test w PR #57 / uwaga |
|---|---|---|
| ERR-01 | P | `app_failure_test`: `classifyCallableError` |
| ERR-02 | P | jw. |
| ERR-03 | P | jw. |
| ERR-04 | C | `classifyAuthError` – tak; wyjątki sieciowe `google_sign_in` → `generic` (BUG-3) |
| ERR-05 | P | „every contract code maps; app_check_failed, internal and unknown are generic" |
| ERR-06 | P | „consent_required carries consentType; unknown type is treated as the policy" – rozstrzygnięcie QA12 przez mobile-dev, do zatwierdzenia przez architekta |
| ERR-07 | P | „no or unsynced record -> ask again; synced in app version -> update app" |
| ERR-08 | C | komunikaty `errorUpdate*` w katalogu (`failure_messages_test`); ekran CMP-18 z linkiem do Google Play – przy P3-05 |
| ERR-09 | P | „other error: … without technical details", „toString exposes the kind only", katalog EK-16 PL/EN |
| ERR-10 | N | klient `generatePlan` – P3-05 |

### Sesja – SES
| ID | Status | Test w PR #57 / uwaga |
|---|---|---|
| SES-01 | P | „unauthenticated during background sync -> signed out with a flash (EK-16)" |
| SES-02 | P | strumień `sessionChanges` → `null` → EK-02 |
| SES-03 | F | odwołanie i wygaśnięcie tokenów |
| SES-04 | B | S18 nie zaimplementowane: `unauthenticated` → zawsze wylogowanie, bez `reload()` i bez usunięcia pliku bazy (baza – P3-06; QA8) |
| SES-05 | P | dane lokalne nigdy nie są kasowane przy `unauthenticated` (bezpieczny kierunek) |
| SES-06 | N | E2E w P3-08 |

### Wylogowanie (warunkowo) – OUT
| ID | Status | Uwaga |
|---|---|---|
| OUT-01 | N | EK-14 nie jest `ux-ready` (QA1) |
| OUT-02 | N | jw. |
| OUT-03 | C | „sign out -> signed out (US-002)"; `FirebaseAuthGateway.signOut` wylogowuje Google i Firebase (błąd Google nie zatrzymuje wylogowania Firebase) |
| OUT-04 | N | P3-05 |
| OUT-05 | N | P3-06 |
| OUT-06 | F | realne konto |

### PL/EN i dostępność – L10N, A11Y
| ID | Status | Test w PR #57 / uwaga |
|---|---|---|
| L10N-01 | P | `l10n_keys_test` (identyczne klucze, brak pustych), `failure_messages_test` (każdy rodzaj błędu w PL i EN) |
| L10N-02 | P | „unsupported device language falls back to English"; zapisany `uiLanguage` czytany w `bootstrap.dart` (bez testu) |
| L10N-03 | P | jeden klucz `consentPolicyCheckbox` w EK-02/EK-03, forma neutralna; skrót w `guards_test` |
| L10N-04 | R | nie wykonano |
| A11Y-01 | C | brak testów złotych; stany domyślne EK-02, EK-03, EK-06 sprawdzane w PL/EN × jasny/ciemny z wytycznymi |
| A11Y-02 | C | EK-02: „150 % text: illustration 96 dp", „200 % text: illustration hidden, everything reachable"; brak testów 150/200% dla EK-03 i EK-06 |
| A11Y-03 | P | `meetsGuideline(androidTapTarget/labeledTapTarget/textContrast)` w EK-02, EK-03, EK-06, oba motywy |
| A11Y-04 | P | „TalkBack: checkbox label = visible text; disabled button reads the reason", etykieta linku EK-06 |
| A11Y-05 | R | nie wykonano |
| A11Y-06 | R | nie wykonano |
| A11Y-07 | R | nie wykonano |

### Prywatność – PRIV
| ID | Status | Test w PR #57 / uwaga |
|---|---|---|
| PRIV-01 | P | `guards_test`: „no logging in lib/ (SEC-29…)" |
| PRIV-02 | P | brak jakiegokolwiek logowania w `lib/`; `AppFailure.toString` tylko rodzaj |
| PRIV-03 | C | ręczny `grep`: `lib/` nie odczytuje `email`, `displayName`, `photoURL`, `phoneNumber`; brak testu automatycznego |
| PRIV-04 | P | UB: „a write failure is a bare internal error and nothing from the request is logged", „logs only allow-listed keys" (Cloud Logging – P3-03) |
| PRIV-05 | F | `logcat` z realnym logowaniem |
| PRIV-06 | P | „discard removes the staged entry", „adopt … staged entry removed" |

### Podsumowanie

| Status | Liczba |
|---|---|
| P – pokryty | 59 |
| C – częściowo | 22 |
| B – brak | 11 |
| R – ręczny, nie wykonany | 6 |
| F – wymaga Firebase (P3-03) | 5 |
| N – nie dotyczy P3-04 | 6 |
| **Razem** | **109** |

Pokrycie przypadków dotyczących P3-04 (109 − 6 N = 103): **pełne 57% (59/103)**, **pełne lub częściowe 79% (81/103)**. Bez przypadków zależnych od Firebase (98): pełne 60%, z częściowymi 83%.

## 3. Znalezione błędy

| ID | Waga | Opis | Kroki / dowód | Oczekiwane | Odwołanie |
|---|---|---|---|---|---|
| BUG-1 | **poważny** | Rekordy zgód (`consents_local`) są tylko w pamięci procesu (`InMemoryConsentLocalStore`, TODO P3-06). Po każdym restarcie zalogowany użytkownik trafia do EK-03; bez sieci nie może zaakceptować (U2), więc **start offline blokuje aplikację**. Każdy restart tworzy też nowy rekord `privacy_policy` na serwerze. | `bootstrap.dart` → `InMemoryConsentLocalStore()`; zalogować się, zabić proces, uruchomić (offline) → EK-03 z `reconsentOffline` | sesja ważna (także offline) → EK-04; EK-03 tylko przy nowszej wersji polityki | US-001 AC4, EK-01, ADR-0011 pkt 1; GATE-02, GATE-07, GATE-08; QA3 |
| BUG-2 | średni | Rekord niezsynchronizowany ginie przy restarcie, a wpis tymczasowy w `shared_preferences` nie jest ponownie przejmowany przy starcie (`adoptStagedPolicy` tylko w przepływie logowania): dowód akceptacji nie zostanie dosłany, a wpis zostaje w `shared_preferences` na stałe. | logowanie z błędem `recordConsent` (brak sieci) → zabicie procesu → start z siecią: brak wywołania `recordConsent` z pierwotnym `consentId` | ponowienie przy każdym starcie z siecią; wpis tymczasowy usunięty po sukcesie | ADR-0011 pkt 10, ADR-0005 Aneks A pkt 4; CONS-03, GATE-05 |
| BUG-3 | średni (do potwierdzenia na urządzeniu) | Błąd sieci na etapie Google (`GoogleSignInException` inny niż `canceled`) daje `welcomeSignInError` zamiast `commonOfflineNotice`. | `firebase_auth_gateway.dart`: `_ => AppFailure(generic)` | „brak sieci" także dla błędu sieci `google_sign_in` | ADR-0011 pkt 2, US-001 AC3; SIGN-13, ERR-04 |
| BUG-4 | drobny | EK-03: `unsupported_version` przy zapisie akceptacji pokazuje `reconsentSaveError` (ponowienie bez szans powodzenia) zamiast komunikatu „Zaktualizuj aplikację". | `reconsent_screen.dart`: wszystkie błędy poza `offline`/`unauthenticated` → `reconsentSaveError` | CMP-18 `errorUpdate*` z linkiem do Google Play (EK-16); czy „Wyloguj" zostaje – QA9 | EK-16, U3; RECON-09 |
| BUG-5 | drobny | EK-02: komunikat błędu / braku sieci jest nad polem zgody, a nie bezpośrednio nad przyciskiem. | `welcome_screen.dart`: `Notice` w `content` przed `ConsentCheckbox` | CMP-13 „nad przyciskiem" | EK-02 „Stany" |
| BUG-6 | drobny (dokumentacja w kodzie) | Komentarz w `app_constants.dart` wskazuje nieistniejący `test/consent_text_version_test.dart`; test jest w `test/guards_test.dart`. | – | poprawny odnośnik | AIC-10 |

Obserwacje (bez wagi błędu):
- O-1: brak ograniczenia do jednego wywołania `recordConsent` w locie na `consentId` (CONS-05); serwer jest idempotentny, więc skutkiem jest tylko dodatkowe wywołanie.
- O-2: ten sam `consentId` z inną treścią jest cicho ignorowany (pierwszy zapis wygrywa) – zgodne z historią „tylko dopisywanie", rozstrzygnięcie QA7 należy do architekta.
- O-3: `consent_required` bez `consentType` → traktowane jak polityka (EK-03). To rozstrzyga QA12 inaczej niż propozycja QA („jak `internal`"); oba warianty są bezpieczne, potrzebna decyzja architekta.
- O-4: S18 (QA8) nie jest zaimplementowane; obecne zachowanie (wylogowanie bez kasowania danych) jest bezpieczne do czasu bazy z P3-06.
- O-5: zgodnie z decyzją ux v0.3 ilustracja EK-02 jest zastąpiona dekoracyjnym miejscem o tych samych wymiarach (QA2, UX2).

## 4. Werdykt

**Odrzucone – niegotowe do `done`** (P3-04 nie spełnia kryteriów z sekcji 8 planu).

Uzasadnienie:
1. BUG-1 (poważny) narusza zatwierdzone zachowanie EK-01 i US-001 AC4: po restarcie, zwłaszcza offline, użytkownik nie wchodzi do aplikacji. BUG-2 łamie ADR-0011 pkt 10 (dosyłanie przy starcie).
2. Testy integracyjne z emulatorem Firebase (plan: 18 wystąpień poziomu I) nie istnieją, więc kryterium „done" nr 3 nie jest spełnione.
3. Lista ręczna (M) nie została wykonana (kryterium nr 4).

Kod jest uporządkowany i dobrze przetestowany na poziomie U/W/UB (201 zielonych testów, wytyczne dostępności, brak logowania, rozdzielenie kont), więc PR może wejść do `main` jako przyrost, jeśli orkiestrator i właściciel tak zdecydują – ale P3-04 pozostaje wtedy w `review`, nie w `done`.

Warunki ponownej weryfikacji:
- BUG-1 i BUG-2: trwały lokalny zapis zgód (minimalna baza konta albo P3-06 przed zamknięciem P3-04) i przejęcie/dosłanie wpisu tymczasowego przy starcie – albo decyzja orkiestratora (QA3), że P3-04 zamyka się razem z P3-06;
- BUG-3 i BUG-4 poprawione lub świadomie odłożone (wpis w backlogu);
- testy I dla `recordConsent` (zapis, idempotencja, usunięty użytkownik, reguły Firestore) uruchomione przez `.farm/test-lock.ps1 -Resource firebase-emulators`;
- lista M (sekcja 5) wykonana na emulatorze Androida z `TAMITU_FAKE_BACKEND=true`.

## 5. Lista ręczna do wykonania (bez Firebase)

Build: `flutter run --flavor dev --dart-define=TAMITU_FAKE_BACKEND=true` przez `.farm/test-lock.ps1 -Resource device`. Przypadki: SIGN-16, SIGN-19, L10N-04, A11Y-05, A11Y-06, A11Y-07 oraz powtórka GATE-07 (restart) po poprawce BUG-1. Odłożone do P3-03: GATE-08, SIGN-20, SES-03, OUT-06, PRIV-05.
