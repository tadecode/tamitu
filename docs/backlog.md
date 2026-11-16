# Backlog

Statusy: `todo` · `in-progress` · `review` · `done` · `blocked`

Faza 2 zakończona (G2 zatwierdzona 2026-11-15). Faza 3: zadania P3-01..09 gotowe do realizacji; SEC-* wg wejść w ADR.

| ID | Zadanie | Rola | Status | Powiązane (story/ADR) | Uwagi |
|---|---|---|---|---|---|
| P2-01 | ADR: wybór modelu AI i szacunek kosztów | architect | done | pyt. 1, S5 | G2 zatwierdzona |
| P2-02 | ADR: pośrednik AI (Cloud Functions) vs bezpośrednio, limity, cache | architect | done | pyt. 2, US-005, US-011 | G2 zatwierdzona |
| P2-03 | ADR: Firebase – środowiska, region UE, budżety i alerty | architect | done | pyt. 3, SEC-09 | G2 zatwierdzona |
| P2-04 | ADR: uwierzytelnianie (Firebase Auth, Google) i zarządzanie sesją | architect | done | US-001, US-002, pyt. 8 | G2 zatwierdzona |
| P2-05 | ADR: przechowywanie danych (lokalnie, szyfrowanie, backup) | architect | done | pyt. 5, S4, US-008 | G2 zatwierdzona |
| P2-06 | Architektura aplikacji Flutter i podział na moduły (`docs/architecture/`) | architect | done | US-001..011 | G2 zatwierdzona |
| P2-07 | Model danych i kontrakt API pośrednika (`docs/data/`, `docs/api/`) | architect | done | US-004..007 | G2 zatwierdzona |
| P2-08 | Pogłębiony model zagrożeń po decyzjach architektonicznych | security | review | threat-model.md v0.3, przeglad-adr.md | brak uwag blokujących G2; uwagi Z w przeglad-adr.md |
| SEC-01 | Skan sekretów w CI i pre-commit (prośba do Stewarda) | security/orchestrator | blocked | T1 | |
| SEC-02 | Reguły Firebase `deny all` + testy emulatora | architect/security | blocked | T8 | faza 2/4 |
| SEC-03 | Weryfikacja tokenu i App Check w pośredniku | architect/security | blocked | T3, T6, T24, T27 | wejście: sprawdzanie istnienia użytkownika, sprzężenie App Check z ALLOW_REAL_DATA (przeglad-adr 2-1, 2-6) |
| SEC-04 | Zakaz logowania treści, filtr i retencja logów | security | blocked | T7, T25, S7 | wejście: globalny handler wyjątków, sink, test ciągu kontrolnego (przeglad-adr 2-2, 3-1) |
| SEC-05 | `allowBackup`, Network Security Config, minimalny manifest | security | blocked | T9-T11, S4 | |
| SEC-06 | Walidator wejścia/wyjścia AI, testy prompt injection | security | blocked | T4, T5 | |
| SEC-07 | Usuwanie konta i danych po UID + test E2E | security | blocked | T14, T24, US-010 | wejście: test ze starym tokenem, osierocony plik bazy (przeglad-adr 2-1, 5-2) |
| SEC-08 | Audyt zależności w CI | security | blocked | T16 | |
| SEC-09 | Alerty budżetowe i wyłącznik kosztowy (właściciel) | owner | blocked | T3, T26 | wejście: alert na wyczerpanie limitu globalnego (przeglad-adr 2-5) |
| SEC-10 | Weryfikacja lokalizacji przetwarzania i transferów Firebase/Google Cloud/Vertex AI w dokumentacji Google | security | todo | S2, P2-03, T29 | faza 2; zakres rozszerzony: Error Reporting, App Check/Play Integrity, Secret Manager, Vertex (model docelowy) |
| SEC-11 | Wymagania prywatności dla preferencji: lista predefiniowana, walidacja serwerowa, zakaz logowania, zgoda AI | security/architect | blocked | T4, T22, R16, N11 | czeka na N11 |
| SEC-12 | Lokalizacja dokładna: manifest bez tła, jednorazowy odczyt bez zapisu/logów, test braku persystencji | developer/QA | blocked | T11, T12, R12, US-007 | faza 3 |
| SEC-13 | Data Safety i uzasadnienie uprawnienia lokalizacji w Play, spójne z rejestrem | owner/security | blocked | D7, D15, privacy-checklist pkt 8 | przed testami zamkniętymi |
| SEC-14 | Teksty zgód i polityka prywatności PL/EN, zapis języka w wersji zgody | analyst/owner | blocked | T15, T23, US-003 | weryfikacja [PRAWNIK]; potrzebne dane firmy (S1); wersja zgody powiązana z treścią (przeglad-adr 6-3) |
| SEC-15 | Potwierdzenie warunków dostawcy AI (DPA, UE, bez trenowania) zapisane w ADR przed realnymi danymi | architect/owner | blocked | S5, T13, P2-01 | warunek wstępny; lista rozszerzona o poz. 7-12 (przeglad-adr pkt 1) |
| SEC-16 | Procedura przełączenia `ALLOW_REAL_DATA` i zmian `config/runtime`; dostęp do konsoli; tokeny debug App Check | owner/security/architect | blocked | T27, ADR-0001/0002 | przed SEC-15; wejście z P2-08 |
| SEC-17 | Role kont usług per funkcja, ograniczenie WIF (repo/gałąź), przegląd IAM | steward/devops | blocked | T28, ADR-0002/0003 | przy P3-03 |
| SEC-18 | `consumeAppCheckToken` dla `generatePlan` i `enforceAppCheck` w opcjach SDK; sprawdzić w emulatorze, czy SDK loguje własne ostrzeżenia App Check poza wrapperem | mobile-dev/security | todo | T3, T27, ADR-0002 | przegląd 2026-11-16 P-1; przed P3-05 |
| SEC-19 | `classifyError`: lista dozwolonych wzorców dla `errorCode`/`errorClass` (inaczej `unknown`) + test | mobile-dev | todo | T7, T25 | przegląd 2026-11-16 P-2; `errors.ts:53-59`; przed P3-05 |
| SEC-20 | Zakaz wdrożenia bez kont usług per funkcja (`serviceAccount` w opcjach funkcji; `fn-ai`, `fn-consent`, `fn-account`, `fn-budget`) | mobile-dev/steward | todo | T28, ADR-0002 Aneks A pkt 6 | przegląd 2026-11-16 P-3; razem z P3-03/SEC-17; `index.ts:50-56` |
| SEC-21 | Walidacja tekstów: NFC i odrzucenie Unicode Cc/Cf/Zl/Zp w `text()`; `policyVersion` wzorzec i lista znanych wersji; testy | mobile-dev | todo | T4, przeglad-adr 6-3 | przegląd 2026-11-16 P-4; `schemas.ts:26-35,76`; powiązane z SEC-06 |
| SEC-22 | Granice `perUserDailyLimit`/`globalDailyLimit` (poza zakresem -> domyślne) i wydzielenie `loadRuntime` parsowania z `index.ts` do `config.ts` z testami | mobile-dev | todo | T3, T26 | przegląd 2026-11-16 P-5; `index.ts:26-37` |
| SEC-23 | Test ciągu kontrolnego w emulatorze/projekcie dev (grep logów, `_Default` vs kubełek UE, Error Reporting); wzmocnić asercję braku UID w logach (`endpoints.test.ts:191`) | security/qa | todo | T7, T25, przeglad-adr 2-2, 3-1 | przegląd 2026-11-16 U-1; część SEC-04 |
| SEC-24 | Decyzja architekta: odmowa startu także dla `dev` + `ALLOW_REAL_DATA=true`; ujednolicić `requireGoogleProvider` w `deleteAccount` (`endpoints.ts:69-78`) | architect/mobile-dev | todo | T27, ADR-0002 Aneks A pkt 3 | przegląd 2026-11-16 U-2, U-3; zmiana semantyki = aneks/nowy ADR |
| SEC-25 | CI: `npm audit --omit=dev --audit-level=high` jako bramka (całość informacyjnie); opis ustawiania parametrów `ENVIRONMENT`/`ENFORCE_APP_CHECK`/`ALLOW_REAL_DATA` per środowisko (`.env.*` ignorowane); rozbieżność publiczne/prywatne repo w `.gitignore` | steward/architect | todo | T16, T27 | przegląd 2026-11-16 U-5, U-6; dev: 7 moderate (minimatch, GHSA-g3hv-75wg-m249) |
| SEC-26 | Egzekwowanie nowej wersji polityki: `generatePlan` odrzuca przy nieaktualnej akceptacji `privacy_policy` (`consent_required`, `consentType=privacy_policy`); EK-01 sprawdza wersję także przy pierwszej akcji sieciowej w sesji; EK-16 mapuje `consentType` → EK-03 / EK-06 | architect/mobile-dev/ux | todo | US-003, T30, S17 | przegląd ekranów 2026-11-16 B-1 (`docs/security/reviews/2026-11-16-p3-14c-ekrany.md`); blokuje `ux-ready` EK-01 i EK-16 |
| SEC-27 | Poprawki ux z przeglądu security ekranów: P-1 (EK-06 wersja robocza, odbiorca warunkowy, administrator), P-2 (jeden tekst akceptacji polityki w CMP-09/EK-02/EK-03, etykieta TalkBack = tekst), P-3 (zmiana języka zdejmuje zaznaczenie), P-4 (nowy cel na zgodzie = osobny ekran), P-5 (EK-15 zakres), P-7 (EK-09 sieć przed pozycją), P-8 (EK-16 `errorGenericBody`), U-6, U-7 | ux | todo | US-003, US-010, T15, T23, T30 | przegląd ekranów 2026-11-16; przed `ux-ready` EK-02, 03, 06, 09, 15, 16 |
| SEC-28 | Usunięcie konta odwołuje dostęp aplikacji do konta Google (`GoogleSignIn.disconnect()` po udanym `deleteAccount`, błąd nieblokujący) + test; aneks ADR-0004, jeśli potrzebny | architect/mobile-dev | todo | US-010, T14, ADR-0004 | przegląd ekranów 2026-11-16 P-6; razem z P3-08 |
| SEC-29 | Implementacja ekranów – wymagania prywatności: `enableIMEPersonalizedLearning: false` i brak `autofillHints` dla noclegu i numeru lotu, `maxLength` jak w API; brak logowania `details` błędów; bez FLAG_SECURE w MVP (decyzja U-1); usunięcie osieroconego pliku bazy przy „Wyloguj” w stanie U12 (do potwierdzenia architekta) | mobile-dev | todo | T7, T9, D4, D5 | przegląd ekranów 2026-11-16 U-1, U-2, U-10, U-13; przy P3-04/P3-06 |
| SEC-30 | Ostateczne teksty zgód PL/EN: EK-06 (po SEC-15), akceptacja polityki (CMP-09/EK-02/EK-03), zdanie o pełnoletności; nadanie wersji ostatecznej zamiast roboczej | owner/[PRAWNIK]/security | blocked | S14, S15, S16, SEC-14, SEC-15 | przegląd ekranów 2026-11-16; przed testami zewnętrznymi |

Zadanie przykładowe T-001 (szkielet Flutter) powstanie w fazie 3 po G2.

## Propozycje fazy 3 (planowanie; start po G2)
| ID | Zadanie | Rola | Status |
|---|---|---|---|
| P3-01 | Szkielet Flutter w korzeniu repozytorium (ADR-0009; flavory dev/prod, pakiet `pl.tadecode.tamitu`, manifest minimalny, l10n PL/EN, testy manifestu i tłumaczeń) | mobile-dev | review |
| P3-02 | Szkielet `backend/` (Functions TS, reguły `deny all`, emulator, testy) | mobile-dev | review |
| P3-03 | Projekty Firebase dev/prod, region, kubełek logów 30 dni, budżety, konta usług (prośba do Stewarda + właściciel) | steward/owner | todo |
| P3-04 | Logowanie Google + zgody + `recordConsent` (US-001..003) | mobile-dev | todo |
| P3-05 | `generatePlan` + walidator + zestaw ewaluacyjny PL/EN, wybór modelu (US-004..006, US-011) | mobile-dev/qa | todo |
| P3-06 | Lokalna baza SQLCipher, lista/podgląd/usuwanie planów (US-008, US-009) | mobile-dev | todo |
| P3-07 | Link Maps (+ lokalizacja zależnie od Q1) (US-007) | mobile-dev | todo (Q1: A, test C) |
| P3-08 | `deleteAccount` + test E2E (US-010, SEC-07) | mobile-dev/qa | todo |
| P3-09 | `budgetGuard` i wyłącznik kosztowy (SEC-09) | mobile-dev/owner | todo |
| P3-10 | Weryfikacja cen modeli i kursu w cenniku Google (costs.md) – przed implementacją `generatePlan` | owner/security | todo |
| P3-11 | Test wariantu C lokalizacji (link bez `origin`) na urządzeniu; ewentualny nowy ADR zastępujący (Q1) | mobile-dev/architect | todo (w ramach P3-07) |
| P3-12 | Poprawki wymagań UI: etykieta noclegu bez pełnego adresu, komunikat przy wylogowaniu, US-010 vs Q9 (dowód zgód usuwany z kontem), US-011 anulowanie | analyst | review | zrobione w P3-14a (PR #31); decyzje właściciela: U1-U15 |
| P3-13 | Rejestr danych: szyfrowanie bazy, T11/T12/D7 po Q1 = A | security | todo |
| P3-14a | Przegląd wymagań pod kątem ekranów: lista ekranów, przepływy, stany brzegowe (brak sieci, limit, wylogowanie, usunięcie konta, anulowanie), poprawki z P3-12 | analyst | review | PR #31 zmergowany; czeka na odpowiedzi U1-U15 i przegląd security (komunikaty wylogowania i usunięcia konta) |
| P3-14b | Mockup UI PL/EN (klikalny prototyp, nie kod aplikacji) na podstawie P3-14a | designer (brak roli: propozycja FARM-003) | blocked |
| P3-14c | Przegląd mockupu przez architekta: zgodność z ADR, API, modelem danych, kosztami; lista zmian i ewentualne nowe ADR | architect | blocked |
| P3-14d | Akceptacja mockupu przez właściciela (wpis w `.farm/log/` i `docs/open-questions.md`) | owner | blocked |

**Decyzja właściciela 2026-11-16:** przed implementacją ekranów (P3-04, P3-06, P3-07) przechodzimy P3-14a..d; każde zadanie wykonuje osobny agent z właściwą rolą. P3-04, P3-06, P3-07 wstrzymane do P3-14d. Prace bez UI (SEC-18/19/21 w backendzie, SEC-24, zadania właściciela) idą równolegle.

Wejścia z Aneksów A ADR (do uwzględnienia przy realizacji): SEC-03, SEC-04, SEC-07, SEC-09, P3-03 (konta usług `fn-ai`, `fn-consent`, `fn-account`, `fn-budget`; sink logów; tokeny debug App Check jako sekrety); P3-01/02/06 (kryteria SQLCipher, lockfile, `flutter_secure_storage`; ADR-0008, ADR-0005). Warunek: `ALLOW_REAL_DATA=false` do zamknięcia SEC-15.
