# Uwagi architekta dla orkiestratora (faza 2, bramka G2)

**Aktualizacja po G2 (2026-11-15):** pytania Q1–Q12 rozstrzygnięte przez właściciela (odpowiedzi w `docs/open-questions.md`); ADR-0001..0008 mają status „zatwierdzony" i Aneks A z uwagami Security. Treść poniżej zachowana jako historia; stan faktyczny wg ADR. Otwarte po G2: warunki dostawcy AI (Q11/SEC-15), konto Blaze i projekty (Q10), [PRAWNIK] (Q9), weryfikacja cen modeli przed fazą 3, test wariantu C lokalizacji (P3-07).

Stan: 2026-11-15. Autor: architect. Rola nie ma uprawnień do `docs/open-questions.md`, `docs/requirements/`, `docs/security/`, `docs/backlog.md` ani `.farm/`; potrzeby i pytania zapisano tu – orkiestrator przenosi je do właściwych plików.

## 1. Pytania do właściciela (do rozstrzygnięcia na G2; propozycje w nawiasie)
| # | Pytanie | Propozycja architekta | ADR |
|---|---|---|---|
| Q1 | **Lokalizacja:** czy zostawić uprawnienie dokładnej lokalizacji (S6, opcja A), czy przejść na link bez `origin` (opcja C – Google Maps sam użyje bieżącej pozycji; zero uprawnień i danych lokalizacyjnych w Tamitu)? | Opcja C jest prostsza i bezpieczniejsza; ale zmienia zatwierdzone S6/US-007. Domyślnie wdrażamy A, dopóki właściciel nie zdecyduje. Wymaga testu C na urządzeniu | 0007 |
| Q2 | **Dystrybucja testów a App Check:** instalacja APK spoza Google Play nie przejdzie Play Integrity. Testy przez wewnętrzną ścieżkę Google Play (wymaga konta Play organizacji) czy sideload z wyłączonym egzekwowaniem App Check na czas testów? | Ścieżka Play; do tego czasu `ENFORCE_APP_CHECK=false` na dev | 0002 |
| Q3 | **Budżety:** dev 20 PLN, prod 100 PLN/mies., alerty 50/90/100%, auto-wyłączenie AI przy 100% prod; limit globalny 50 generowań/dobę | akceptacja lub inne kwoty (kwoty ustawia właściciel, SEC-09) | 0003, costs |
| Q4 | **Klasa modelu:** start od klasy Flash i pomiar; Flash-Lite jeśli wystarczy. Czy akceptujesz ceny z `costs.md` jako podstawę (do weryfikacji w SKU)? | akceptacja; ostateczny model po ewaluacji w P3 | 0001 |
| Q5 | **Definicja „doby" limitu:** dzień kalendarzowy w strefie Europe/Warsaw (odnowienie o 00:00) czy okno 24 h od pierwszego użycia? | kalendarzowy (prostszy, jeden dokument/dzień) | 0002 |
| Q6 | **N11 (otwarte):** przyjęto propozycję domyślną analityka: preferencje opcjonalne; lista 11 zainteresowań (0–5); budżet i tempo po 3 poziomy; liczba osób 1–10, **domyślnie 2** (wartość domyślna to dodatek architekta); język planu = język UI z możliwością zmiany. Zatwierdzić lub poprawić listę (S13: lista bez pozycji ujawniających religię/zdrowie/orientację; `family_attractions` sugeruje dzieci – OK?) | akceptacja | 0006, data |
| Q7 | **Szyfrowanie bazy lokalnej (SQLCipher):** akceptujesz dodatkową bibliotekę natywną (+kilka MB APK)? Fallback: baza jawna + piaskownica + brak backupu | tak, szyfrować | 0005 |
| Q8 | **minSdk 26 (Android 8.0)** – akceptacja (24 tylko na wyraźną potrzebę) | 26 | 0007 |
| Q9 | **Dowód zgód po usunięciu konta** [PRAWNIK]: domyślnie usuwany z kontem. Jeśli prawnik zażąda przechowywania – zapseudonimizowane archiwum (osobny ADR) | zapytać prawnika | 0004, 0005 |
| Q10 | **Plan Blaze (karta)** i konto rozliczeniowe TadeCode wymagane do Functions/Vertex AI – właściciel zakłada przed P3; identyfikatory projektów (`tamitu-dev-…`, `tamitu-prod-…`) | potwierdzić nazwy | 0003 |
| Q11 | **Warunki dostawcy AI (SEC-15):** właściciel/Security wypełnia listę w ADR-0001 (CDPA, brak trenowania, region, buforowanie/monitoring nadużyć). Do tego czasu prod przyjmuje tylko dane testowe (`ALLOW_REAL_DATA=false`) | – | 0001 |
| Q12 | **Anulowanie generowania:** serwer nie zwraca slotu limitu po anulowaniu, jeśli wywołanie modelu już ruszyło (koszt poniesiony). Akceptujesz? | tak | 0002 |

## 2. Rozbieżności i uwagi do dokumentów w zakresie innych ról (bez zmian z mojej strony)
1. **US-007 / S6 / rejestr D7:** patrz Q1. Dodatkowo odpowiedź na uwagę rejestru D7: Android 12+ wymaga deklaracji i prośby o `ACCESS_COARSE_LOCATION` razem z `ACCESS_FINE_LOCATION` (użytkownik może wybrać tylko przybliżoną) – US-007 już zakłada obsługę tego przypadku.
2. **US-005 „po anulowaniu nic nie jest zapisane":** po stronie aplikacji prawda; po stronie serwera limit mógł zostać zużyty (Q12). Proponuję doprecyzować US-011.
3. **Rejestr D11 „Cloud Logging, region UE":** domyślny kubełek `_Default` jest globalny – wymagany własny kubełek w UE z retencją 30 dni i wykluczeniem w `_Default` (ADR-0003). Logi żądań Cloud Run/Functions zawierają adres IP klienta (już odnotowane w D11) oraz logi audytu administracyjnego (400 dni, bez danych użytkowników) – opisać w polityce.
3a. **Rejestr D6 „po naszej stronie brak zapisu":** prawda dla Tamitu; Vertex AI może stosować buforowanie promptów i monitoring nadużyć – do potwierdzenia w SEC-15 (lista w ADR-0001).
4. **Rejestr D1/S2:** Firebase Auth nie ma wyboru regionu danych – możliwe przetwarzanie poza UE; wynik SEC-10 decyduje o treści polityki (transfer). Nie blokuje projektu, blokuje testy zewnętrzne.
5. **Rejestr D10:** doprecyzowanie: jeden dokument `usage/{uid}` nadpisywany co dobę + TTL 30 dni od ostatniej aktualizacji (zgodne z „rekordy starsze niż 30 dni usuwane").
6. **Rejestr D4/D15 (szyfrowanie bazy):** decyzja architekta w ADR-0005: baza zaszyfrowana (SQLCipher); do wpisania w rejestrze przez Security. Numer lotu zapisywany wyłącznie lokalnie.
7. **T3 a „build APK do testów" (vision):** patrz Q2.
8. **Tekst zgody AI** powinien wymieniać także: dane trafiają do Vertex AI/Gemini w regionie UE, pośrednik przetwarza je w pamięci, brak zapisu po naszej stronie (już w checkliście pkt 2). Aplikacja pyta o zgodę na AI przy pierwszym generowaniu i w Ustawieniach (US-003 mówi o „przed logowaniem" tylko dla polityki).
9. **ADR dla reklam i płatności** (wymienione w liście ról) – **odroczone**: poza MVP (pyt. 6). Wymagają osobnych ADR i analizy Security (F1, F2, R14) przed rozpoczęciem.
10. **Klucz Firebase (`google-services.json`):** rekomendacja – niekomitowany, dostarczany lokalnie/CI; do ustalenia ze Stewardem i Security (T2).

## 3. Proponowane zadania do backlogu (dla orkiestratora)
| Propozycja | Opis | Rola |
|---|---|---|
| P3-01 | Szkielet `app/` (flavory dev/prod, pakiet `pl.tadecode.tamitu`, manifest minimalny, l10n PL/EN, CI-testy manifestu i tłumaczeń) | developer |
| P3-02 | Szkielet `backend/` (Functions TypeScript, reguły `deny all`, emulator, testy) | developer |
| P3-03 | Projekty Firebase dev/prod, region, kubełek logów 30 dni, budżety, konta usług, WIF dla CI (prośba do Stewarda/DevOps + właściciel) | devops/steward/owner |
| P3-04 | Logowanie Google + zgody + `recordConsent` (US-001..003) | developer |
| P3-05 | `generatePlan` + walidator + zestaw ewaluacyjny PL/EN (US-004..006, US-011), wybór modelu | developer/QA |
| P3-06 | Lokalna baza SQLCipher, lista/podgląd/usuwanie planów (US-008, US-009) | developer |
| P3-07 | Link Maps (+ lokalizacja zależnie od Q1) (US-007) | developer |
| P3-08 | `deleteAccount` + test E2E (US-010, SEC-07) | developer/QA |
| P3-09 | `budgetGuard` i wyłącznik kosztowy (SEC-09) | developer/owner |
| P2-08 | Pogłębiony model zagrożeń na podstawie ADR-0001..0008 (w toku, security) | security |
Aktualizacje istniejących: SEC-02/03/05/06/07/09/10/11/12/13/15 – wejścia w ADR-0002/0003/0005/0007/0001; SEC-15 ma gotową listę kontrolną w ADR-0001; SEC-11 – wartości i walidacja w `docs/data/model-danych.md` i `docs/api/`.

## 4. Założenia architekta do potwierdzenia
- Kurs 4,0 PLN/USD i ceny modeli – do weryfikacji (costs.md).
- Dostępność w `europe-west4`: Cloud Functions 2. gen., Firestore regionalny, Vertex AI dla wybranego modelu – sprawdzić przed utworzeniem projektów (zmiana regionu Firestore później niemożliwa).
- Zdolność wybranego modelu do poprawnej polszczyzny i spełnienia ograniczeń (godziny pierwszego dnia) – ewaluacja w P3-05; wynik może zmienić klasę modelu i koszt.
- Cykl życia modeli Gemini: wybierać modele GA; model w konfiguracji, nie w kodzie.
- Wartości domyślne N11 (w tym `partySize = 2`).

## 5. Wpis do dziennika (propozycja dla orkiestratora, `.farm/log/2026-11-15.md`)
```
### HH:MM  architect → orchestrator  |  P2-01..P2-07
- Zrobione: ADR-0001..0008 (proponowane), architektura, przepływy, koszty, model danych, kontrakt API pośrednika.
- Artefakty: docs/adr/0001..0008, docs/architecture/*, docs/data/*, docs/api/*
- Decyzje: wszystkie jako „proponowany" – zatwierdza właściciel na G2.
- Do zrobienia przez odbiorcę: przenieść pytania Q1–Q12 do docs/open-questions.md; zaktualizować backlog; przekazać Security (P2-08, SEC-10, SEC-15); bramka G2.
- Pytania/blokady: Q1 (lokalizacja A/C), Q2 (App Check a APK), SEC-15 (warunki AI), N11.
```
