# QA-P3-04-DEV-2 – zapis zgody end-to-end na urządzeniu: BLOKADA (test niewykonany)

- Autor (rola): qa · Data: 2026-11-20 · Gałąź raportu: `docs/QA-P3-04-DEV-2`
- Zadanie: QA-P3-04-DEV-2 (Azure Boards, work item 180)
- Baza: `main` @ `966170d`
- Norma: `docs/qa/test-plan-p3-04.md` – SIGN-11 (strona serwera), CONS-01, RECON-03, AIC-04; poprzednio
  `docs/qa/verify-p3-04-dev.md` (sekcja „nie sprawdzono”), `docs/qa/verify-pr-99.md`, `docs/qa/verify-pr-102.md`
- **Werdykt: ZABLOKOWANE.** Funkcje backendu nie są wdrożone w projekcie Firebase `dev`. Przypadków nie
  wykonano, aplikacji nie budowano ani nie instalowano, telefonu nie używano, nikt się nie logował.

## 1. Krok 0 – czy `recordConsent` jest wdrożone w `dev` (tylko odczyt)

| Źródło | Wynik |
|---|---|
| `docs/github-ops/log.md`, `.farm/requests/GH-010-wif-deploy.md` | przez `deploy.yml` wdrożono w `dev` tylko `firestore:rules` (run 44353627132) i `firestore:indexes` (run 44628899645). Komponentu `functions` nie wdrażano |
| `gh run list --workflow deploy.yml` | 3 przebiegi (1 błąd WIF, 2 sukcesy – reguły i indeksy). Brak przebiegu `functions` |
| `.farm/log/2026-11-19/2235-steward-GH-010.md` | „`functions` w dev czeka na ADR-0014, role `fn-*` i P3-05” |
| `firebase functions:list --project tamitu-dev-tadecode` (CLI już zalogowane, tylko odczyt) | **HTTP 403: Cloud Functions API nie było używane w projekcie lub jest wyłączone.** W `dev` nie ma więc żadnej funkcji, w tym `recordConsent` |
| App Check | klient ma już `firebase_app_check` (aktywacja w `lib/app/bootstrap.dart`). Stanu wymuszania po stronie serwera (`ENFORCE_APP_CHECK` w `dev`, token debug) nie da się sprawdzić bez wdrożonych funkcji – do sprawdzenia w następnym podejściu |
| Reguły Firestore | wdrożone (run 44353627132); dla zapisu zgody nie mają znaczenia, bo zapis idzie przez callable |

Wniosek: zapisu zgody po stronie serwera nie da się dziś sprawdzić na urządzeniu. Każde `recordConsent`
skończy się błędem (jak w QA-P3-04-DEV: wpis tymczasowy zostaje, `synced=0`), więc wynik testu nie
powiedziałby nic nowego o SIGN-11/CONS-01/RECON-03/AIC-04.

## 2. Przypadki

| Przypadek | Status | Uwagi |
|---|---|---|
| SIGN-11 (strona serwera: dokument `users/{uid}/consents/{consentId}`) | **nie wykonano – blokada** | część kliencka zaliczona w QA-P3-04-DEV |
| CONS-01 (`consents_local` `synced=1`, `received_at` z odpowiedzi, usunięcie wpisu tymczasowego) | **nie wykonano – blokada** | wymaga odpowiedzi 200 z `recordConsent` |
| RECON-03 (`privacy-v2` po `privacy-v1`, nowy `consentId`, `synced=1`) | **nie wykonano – blokada** | jw. |
| AIC-04 (`ai_processing`, `ai-consent-v1`, `synced=1`) | **nie wykonano – blokada** | jw. |

Nowe błędy: brak (BUG-DEV-n nie zgłaszano).

## 3. Co blokuje i kto odblokowuje

1. **Właściciel (GCP `dev`):** włączenie Cloud Functions API (i API wymaganych przez funkcje 2. gen.,
   które `firebase deploy` wskaże), konta `fn-*` oraz `iam.serviceAccountUser` na kontach `fn-*` dla
   `ci-deployer` (warunek z GH-010 / SEC-17 Ś-3), zatwierdzenie ADR-0014.
2. **GitHub Steward:** próbne wdrożenie `deploy.yml -f component=functions` do `dev` (po zgodzie właściciela),
   wpis w `docs/github-ops/log.md`; każda dodana rola jako wpis w `.farm/requests/GH-010-wif-deploy.md`.
3. **Konfiguracja `dev` dla testu na telefonie (właściciel/Steward):** `ENFORCE_APP_CHECK=false` w `dev`
   (Q2, dozwolone przy danych syntetycznych) albo zarejestrowany token debug App Check dla telefonu testowego
   (sekret poza repozytorium, SEC-16); `allowRealData=false`.
4. Zależność z tablicy: P3-05 / GH-010.

Po odblokowaniu QA powtarza to zadanie bez zmian w planie (build `dev` z `main`, OPPO przez
`.farm/test-lock.ps1 -Resource device`, logowanie na konto testowe właściciela).

## 4. Sprzątanie (OWNER-CLEANUP-DEV)

Brak. Test nie tworzył danych w Auth ani Firestore `dev`, nie rejestrował tokenów debug App Check
i nie instalował aplikacji. Jedyne działanie na projekcie to odczyt listy funkcji (zakończony 403).
