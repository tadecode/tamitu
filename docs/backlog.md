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

Zadanie przykładowe T-001 (szkielet Flutter) powstanie w fazie 3 po G2.

## Propozycje fazy 3 (planowanie; start po G2)
| ID | Zadanie | Rola | Status |
|---|---|---|---|
| P3-01 | Szkielet `app/` (flavory dev/prod, pakiet `pl.tadecode.tamitu`, manifest minimalny, l10n PL/EN, testy manifestu i tłumaczeń) | mobile-dev | todo |
| P3-02 | Szkielet `backend/` (Functions TS, reguły `deny all`, emulator, testy) | mobile-dev | todo |
| P3-03 | Projekty Firebase dev/prod, region, kubełek logów 30 dni, budżety, konta usług (prośba do Stewarda + właściciel) | steward/owner | todo |
| P3-04 | Logowanie Google + zgody + `recordConsent` (US-001..003) | mobile-dev | todo |
| P3-05 | `generatePlan` + walidator + zestaw ewaluacyjny PL/EN, wybór modelu (US-004..006, US-011) | mobile-dev/qa | todo |
| P3-06 | Lokalna baza SQLCipher, lista/podgląd/usuwanie planów (US-008, US-009) | mobile-dev | todo |
| P3-07 | Link Maps (+ lokalizacja zależnie od Q1) (US-007) | mobile-dev | todo (Q1: A, test C) |
| P3-08 | `deleteAccount` + test E2E (US-010, SEC-07) | mobile-dev/qa | todo |
| P3-09 | `budgetGuard` i wyłącznik kosztowy (SEC-09) | mobile-dev/owner | todo |
| P3-10 | Weryfikacja cen modeli i kursu w cenniku Google (costs.md) – przed implementacją `generatePlan` | owner/security | todo |
| P3-11 | Test wariantu C lokalizacji (link bez `origin`) na urządzeniu; ewentualny nowy ADR zastępujący (Q1) | mobile-dev/architect | todo (w ramach P3-07) |
| P3-12 | Poprawki wymagań UI: etykieta noclegu bez pełnego adresu, komunikat przy wylogowaniu, US-010 vs Q9 (dowód zgód usuwany z kontem), US-011 anulowanie | analyst | todo |
| P3-13 | Rejestr danych: szyfrowanie bazy, T11/T12/D7 po Q1 = A | security | todo |

Wejścia z Aneksów A ADR (do uwzględnienia przy realizacji): SEC-03, SEC-04, SEC-07, SEC-09, P3-03 (konta usług `fn-ai`, `fn-consent`, `fn-account`, `fn-budget`; sink logów; tokeny debug App Check jako sekrety); P3-01/02/06 (kryteria SQLCipher, lockfile, `flutter_secure_storage`; ADR-0008, ADR-0005). Warunek: `ALLOW_REAL_DATA=false` do zamknięcia SEC-15.
