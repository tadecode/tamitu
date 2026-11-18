# ADR-0014: Korekty po P3-03 – konto usługi `fn-ai-plan` i limit wydatków Vertex AI

- Status: proponowany (wymaga zatwierdzenia przez właściciela; bramka „architektura")
- Data: 2026-11-18
- Autor (rola): architect
- Zadanie: P3-03 (pytania O2, O3 w `docs/open-questions.md`, sekcja „Konfiguracja środowisk (P3-03)")
- Uzupełnia: ADR-0002 (Aneks A pkt 6 – nazwa konta), ADR-0003 (sekcja „Budżety i alerty", Aneks A pkt 5). Nie zastępuje ich w całości; pozostała treść obowiązuje bez zmian.

## Kontekst
ADR-0002 Aneks A stanowi, że późniejsze zmiany wprowadza się tylko nowym ADR. Podczas P3-03 (runbook `.farm/runbooks/P3-03-firebase.md`) wyszły dwie sprawy:
1. **O2:** Google wymaga, by ID konta usługi miało 6–30 znaków (małe litery, cyfry, myślniki; wzorzec RFC1035), a po utworzeniu nie da się go zmienić. `fn-ai` (5 znaków) nie mogło powstać; utworzono `fn-ai-plan`.
2. **O3:** Cloud Billing udostępnia „spend cap budgets" – budżety, które po przekroczeniu kwoty **wstrzymują** nowe użycie wskazanej usługi. ADR-0003 przyjął, że budżety GCP nie ograniczają wydatków twardo, a `budgetGuard` jest wyłącznikiem opóźnionym (ryzyko rezydualne, Aneks A pkt 5).

### Fakty (dokumentacja Google, sprawdzone 2026-11-18)
| # | Fakt | Źródło |
|---|---|---|
| F1 | ID konta usługi: 6–30 znaków, małe litery, cyfry i myślniki; unikalne w projekcie; nazwy nie można zmienić po utworzeniu. | https://docs.cloud.google.com/iam/docs/service-accounts-create, https://docs.cloud.google.com/iam/docs/reference/rest/v1/projects.serviceAccounts/create |
| F2 | Spend cap: jeden projekt × jedna usługa, okres miesięczny od 1. dnia. Usługi objęte: Gemini API (`generativelanguage`), Agent Platform / Vertex AI (`aiplatform`), Cloud Run (`run`), Cloud Run functions (`cloudfunctions`). | https://docs.cloud.google.com/billing/docs/how-to/budgets-spend-caps |
| F3 | Po przekroczeniu: wstrzymanie **całego nowego użycia** danej usługi w projekcie do końca okresu; żądania w toku kończą się; nic nie jest usuwane. Zniesienie: automatycznie od nowego okresu albo ręcznie („Lift spend cap"), powrót do 1 h. | jw. |
| F4 | Egzekwowanie na podstawie **szacowanych kosztów brutto** (cena katalogowa, bez kredytów i rabatów), **nie natychmiastowe** – nadwyżka jest rozliczana normalnie; Google zaleca kwotę nieco poniżej faktycznego limitu. | jw. |
| F5 | Strona nie oznacza funkcji jako Preview ani GA („in this release…"); źródła wtórne podają sprzecznie (podgląd / GA od X 2026). Strona nie podaje kodu błędu zwracanego przez wstrzymaną usługę. Tylko klienci bezpośredni (nie przez resellera); zarządzanie wymaga uprawnienia `billing.budgets.configureSpendCap`. | jw. |

## Rozważane opcje
### O2 – nazwa konta
1. **`fn-ai-plan` (już utworzone)** – spełnia F1, czytelne (funkcja `generatePlan`), bez dodatkowej pracy w chmurze.
2. Inna nazwa (np. `fn-generate-plan`) – wymaga usunięcia i odtworzenia konta z rolami w dwóch projektach; brak korzyści. Odrzucone.

### O3 – limit wydatków
1. **Bez spend cap** (stan obecny) – warstwy: limity na konto/globalny (ADR-0002), `maxInstances`, `maxOutputTokens`, kwoty Vertex, budżety + `budgetGuard`. Minus: brak twardego zatrzymania po stronie Google przy błędzie w naszych limitach.
2. **Spend cap tylko na `aiplatform`** (dev i prod) – dodatkowa, niezależna od naszego kodu warstwa na jedynej usłudze o istotnym koszcie zmiennym. Po zadziałaniu zatrzymuje wyłącznie generowanie planów.
3. Spend cap także na `cloudfunctions`/`run` – **odrzucone**: wstrzymałby wszystkie funkcje, w tym `deleteAccount` i `recordConsent` (usuwanie konta zawsze dostępne – ADR-0011 pkt 4, RODO art. 17; zgody – rozliczalność). Funkcje 2. gen. działają na Cloud Run, więc cap na `run` ma ten sam skutek.

Kryteria: brak blokady praw użytkownika (usunięcie konta, zgody), niezależność od naszego kodu, prostota, koszt zerowy.

## Decyzja
### 1. Konto usługi dla `generatePlan` (O2)
`fn-ai` → **`fn-ai-plan`** (`fn-ai-plan@<projekt>.iam.gserviceaccount.com`) w ADR-0002 Aneks A pkt 6 (tabela kont) i w sekcji „Tożsamości (IAM)". Role i uprawnienia bez zmian: `roles/aiplatform.user`, Firestore (`roles/datastore.user`), odczyt użytkownika Auth (`roles/firebaseauth.viewer`), `secretAccessor` na `UID_HASH_PEPPER`. Pozostałe nazwy (`fn-consent`, `fn-account`, `fn-budget`) spełniają F1 – bez zmian. Kod: `serviceAccount` w opcjach `generatePlan` (SEC-20, mobile-dev). Każde przyszłe konto usługi: nazwa 6–30 znaków, wzorzec `fn-<funkcja>`.

### 2. Spend cap na Vertex AI jako czwarta warstwa wyłącznika kosztowego (O3)
1. **Zakres:** spend cap wyłącznie na usługę `aiplatform.googleapis.com`, osobno w `tamitu-dev-tadecode` i `tamitu-prod-tadecode`. **Nie** na `cloudfunctions`, `run` ani `generativelanguage` (niewykorzystywane, ADR-0001).
2. **Kwoty (propozycja, decyduje właściciel – SEC-09):** prod **80 PLN/mies.**, dev **15 PLN/mies.** – poniżej budżetów projektów (100/20 PLN, ADR-0003), tak by cap zadziałał przed budżetem całego projektu z zapasem na opóźnienie (F4). Istniejące budżety alertowe i `budgetGuard` – bez zmian.
3. **Kolejność warstw:** limit na konto i globalny (ADR-0002) → `budgetGuard` (`aiEnabled=false` po 100% budżetu projektu) → **spend cap `aiplatform`** (zatrzymanie po stronie Google, niezależne od naszego kodu) → ręczna decyzja właściciela. Spend cap nie zastępuje `budgetGuard` (ten działa na budżecie całego projektu).
4. **Zachowanie pośrednika:** błąd Vertex wynikający z wstrzymania usługi → odpowiedź `ai_unavailable` (jak przy `aiEnabled=false`), **bez ponowienia** i bez zużycia slotu limitu, jeśli model nie ruszył (ADR-0002, Q12). Kod błędu Google nieznany (F5) – ustalić w P3-09 testem w `dev` (tymczasowy cap np. 1 PLN, dane syntetyczne) i zapisać w `docs/api/posrednik-api.md`.
5. **Warunek wdrożenia:** właściciel sprawdza w konsoli, czy funkcja jest oznaczona jako Preview. Jeśli tak – świadoma akceptacja właściciela (ryzyko: zmiana działania lub brak SLA; funkcja nie przetwarza danych osobowych, a awaria oznacza brak zatrzymania – stan jak dziś). Wdrożenie: zadanie P3-09 (razem z `budgetGuard`), ustawienie w konsoli przez właściciela (uprawnienia rozliczeniowe; agenci ich nie mają). Wpis w runbooku P3-03 / P3-09.

## Konsekwencje
**Pozytywne:** nazwa zgodna z wymaganiami Google i stanem chmury; twarde zatrzymanie kosztu AI niezależne od poprawności naszych liczników; zgody i usuwanie konta działają także po zadziałaniu capu.
**Negatywne / ryzyka:** cap nie jest natychmiastowy (F4) – możliwa nadwyżka ponad kwotę; po zadziałaniu generowanie planów stoi do 1. dnia miesiąca lub ręcznego zniesienia (akceptowalne w fazie testów); niepotwierdzony status GA/Preview (F5); `budgetGuard` pozostaje opóźniony (ADR-0003 Aneks A pkt 5 – ryzyko rezydualne mniejsze).
**Koszty:** brak dodatkowych opłat za spend cap; zmiana nie zwiększa kosztu.
**Dane osobowe:** brak wpływu (konfiguracja rozliczeń, bez danych użytkowników). Zmiana nazwy konta usługi nie zmienia zakresu dostępu do danych (D3, D10, D11).
**Dokumenty do aktualizacji (po zatwierdzeniu):** `docs/architecture/overview.md`, `docs/api/zewnetrzne-integracje.md` (architect – w tym PR); `docs/security/` – zgłoszone Security (rejestr kont w przeglądach, SEC-17); `backend/functions` – SEC-20 (mobile-dev).
