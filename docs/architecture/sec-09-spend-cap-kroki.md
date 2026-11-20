# SEC-09 – spend cap Vertex AI: kroki w konsoli dla właściciela

- Stan: 2026-11-20, autor: architect
- Podstawa: ADR-0014 (zatwierdzony 2026-11-20, w tym Aneks A), ADR-0003 „Budżety i alerty", `docs/architecture/costs.md`
- Wykonuje: **właściciel** (uprawnienia rozliczeniowe; agenci ich nie mają). Ten plik zastępuje wpis w `.farm/runbooks/` (katalog poza uprawnieniami architekta) – orkiestrator może przenieść/odwołać go w runbooku P3-03 lub P3-09.
- Repo jest publiczne: wyniki zapisuj **bez** ID konta rozliczeniowego, adresów e-mail i zrzutów ekranu z danymi konta.

## Wymagane uprawnienie
- `billing.budgets.configureSpendCap` na **koncie rozliczeniowym** (ADR-0014, F5). Ma je rola administratora konta rozliczeniowego (Billing Account Administrator); jeśli konsola odmawia – sprawdź rolę w Billing → Account management. Tylko klienci bezpośredni Google (nie przez resellera).
- Konto właściciela z 2FA (ADR-0003). Nie nadawaj tego uprawnienia kontom usług ani CI.

## Kroki
Kolejność: najpierw `dev` (warunek włączenia Cloud Functions API w dev – ADR-0014 Aneks A pkt 2), potem `prod`.

1. **Otwórz** Google Cloud Console → **Billing** → właściwe konto rozliczeniowe → **Budgets & alerts**. Zapoznaj się z opisem funkcji spend cap (dokumentacja: https://docs.cloud.google.com/billing/docs/how-to/budgets-spend-caps).
2. **Sprawdź oznaczenie Preview.** Jeśli przy funkcji spend cap jest etykieta „Preview"/„Podgląd" – akceptacja jest już udzielona (ADR-0014 Aneks A pkt 1); zanotuj tylko „Preview: tak/nie" do pliku przekazania. Jeśli funkcji nie ma w ogóle – przerwij i zgłoś orkiestratorowi (warunek z ADR-0014 Aneks A pkt 2 nie jest spełniony – Functions API w dev czeka na decyzję właściciela).
3. **`tamitu-dev-tadecode` – utwórz spend cap:**
   - zakres: **jeden projekt** `tamitu-dev-tadecode`, **jedna usługa: Vertex AI / Agent Platform** (`aiplatform.googleapis.com`);
   - **nie** wybieraj Cloud Run functions, Cloud Run ani Gemini API (`generativelanguage`);
   - kwota: **15 PLN**, okres: miesiąc kalendarzowy;
   - nazwa np. `tamitu-dev spend cap aiplatform 15 PLN`.
4. **Sprawdź dev:** cap widoczny na liście budżetów z usługą Vertex AI i kwotą 15 PLN; istniejący budżet `tamitu-dev 20 PLN` z alertami 50/90/100% – bez zmian.
5. **Dopiero teraz** w dev można włączyć Cloud Functions API (odblokowanie QA-P3-04-DEV-2). `budgetGuard` w dev **nie** jest wdrażany.
6. **`tamitu-prod-tadecode` – utwórz spend cap:** jak w kroku 3, projekt `tamitu-prod-tadecode`, usługa Vertex AI, **80 PLN**/mies. Istniejący budżet prod 100 PLN z alertami i tematem `budget-alerts` – bez zmian; `budgetGuard` wdrażany w P3-09.
7. **Limit globalny (gdy dokument istnieje):** w Firestore każdego projektu, w którym jest już dokument `config/runtime`, ustaw `globalDailyLimit = 25` (liczba całkowita). Jeśli dokumentu jeszcze nie ma – nic nie rób (wartość domyślna w kodzie po zmianie mobile-dev).
8. **Zapisz wynik** w pliku przekazania (`.farm/log/<data>/…`): daty ustawienia, kwoty, „Preview: tak/nie", że zakres to wyłącznie Vertex AI. Bez ID konta i e-maili.

## Czego nie robić
- Nie ustawiać spend cap na `cloudfunctions` ani `run` – zatrzymałby `deleteAccount` i `recordConsent` (ADR-0014, opcja 3).
- Nie wywoływać celowo zadziałania capu w `prod`. Test kodu błędu (tymczasowy cap np. 1 PLN, dane syntetyczne) – tylko w `dev`, w ramach P3-09, a potem przywrócić 15 PLN.
- Nie odłączać konta rozliczeniowego od projektów (ADR-0003).

## Po zadziałaniu capu
Generowanie planów stoi do 1. dnia następnego miesiąca albo do ręcznego „Lift spend cap" (powrót do ok. 1 h). Funkcje zgód i usuwania konta działają dalej. Zniesienie lub podniesienie kwoty – wyłącznie decyzja właściciela.
