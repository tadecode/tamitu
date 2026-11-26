# Bramka 2a – lista kontrolna przed dodaniem kolejnego testera i przed testami zamkniętymi

- Wersja: 0.1 · Data: 2026-11-26 · Autor (rola): security · Zadanie: TAM-132 (REL-SEC-3)
- Podstawa: decyzje właściciela z 2026-11-26 (O-TAM116-1, O-TAM116-7, O-TAM116-8 w `docs/open-questions.md`),
  plan `docs/architecture/plan-wydania-testy-wewnetrzne.md` (sekcje 2a, 4.3, 4.6, 4.7, 4.9, 7.3),
  `docs/security/review-SEC-17-iam.md`, `docs/security/privacy-checklist.md`,
  `docs/security/personal-data-register.md`.
- Nie jest to porada prawna. Punkty z oznaczeniem [PRAWNIK] wymagają opinii prawnika lub decyzji właściciela.

## 1. Co i po co

**Co.** Lista warunków, które muszą być spełnione, zanim na liście testerów Tamitu w Google Play pojawi się
**ktokolwiek poza właścicielem** oraz zanim aplikacja trafi na testy zamknięte, otwarte lub do produkcji.

**Po co.** Od 2026-11-26 aplikacja w prod działa na **realnych danych** (decyzja O-TAM116-1), bez technicznej
blokady listą `testUids` (O-TAM116-8), z limitem globalnym 50 planów na dobę (O-TAM116-7). Właściciel przyjął to
ryzyko **tylko dla własnych danych**. Jedyną barierą przed danymi innych osób jest lista testerów w Play Console.
Ta lista kontrolna ma sprawić, że nikt w farmie nie doda testera, zanim zostaną spełnione warunki.

**Jak czytać.**
- **Część A – blokuje dodanie jakiegokolwiek kolejnego testera** (także na testach wewnętrznych).
- **Część B – dodatkowo blokuje testy zamknięte, otwarte i produkcję.**
- **Część C – zalecenia.** Nie blokują, ale warto je zrobić przed pierwszym obcym testerem.

**Liczba warunków blokujących: 16** (A: 11, B: 5). Zaleceń: 8.

## 2. Zasady bramki

1. **Lista testerów w Play Console = tylko właściciel**, dopóki wszystkie punkty części A nie mają statusu
   „spełnione” z dowodem. Link opt-in do testów nie jest przekazywany nikomu innemu.
2. **Zamknięcie bramki = protokół**: security tworzy plik `docs/security/reviews/gate-2a-<RRRR-MM-DD>.md`
   (kopię tabel z części A i B z kolumną „wynik” i „dowód”) i otwiera PR. Bramkę zatwierdza **właściciel**
   (zasada 5 `CLAUDE.md`, `.farm/workflows/gates.md`) – merge tego PR-a jest zgodą.
3. **Odczyty w prod wykonuje wyłącznie właściciel** (agenci nie mają poświadczeń prod; plan, założenie 4).
   Do protokołu trafia tylko wynik w postaci „tak/nie, N wpisów, nazwa roli” – **bez e-maili, UID, numerów kont
   rozliczeniowych i treści logów** (zasada 7 `CLAUDE.md`). Na początku sesji: `$p = 'tamitu-prod-tadecode'`,
   na końcu `gcloud auth revoke` i `firebase logout`.
4. **Każda zmiana listy testerów** (dodanie kolejnej osoby po przejściu bramki też) – orkiestrator sprawdza, czy
   protokół jest zmergowany i czy od jego daty nie zmieniło się nic z punktów A1–A11 (nowa wersja polityki,
   nowa wersja zgody, nowe dane osobowe w rejestrze, zmiana `config/runtime`). Jeśli zmieniło się – nowy protokół.
5. Punkty z gwiazdką (*) to **decyzje** właściciela: wystarczy decyzja zapisana w `docs/open-questions.md` lub
   ADR; nie muszą kończyć się zmianą w systemie.

## 3. Część A – blokuje dodanie kolejnego testera

Warunki A1–A5 to warunki właściciela z O-TAM116-1. A6–A11 dodaje security (uzasadnienie w kolumnie „Warunek”).

| # | Warunek | Jak sprawdzić | Kto | Dowód (gdzie zapisany) | Jira |
|---|---|---|---|---|---|
| A1 | **Polityka prywatności (PL i EN) opublikowana** pod `https://tadecode.pl/tamitu/prywatnosc` i `/en`. Treść po przeglądzie [PRAWNIK], z danymi administratora (S1). Wersja na stronie = `privacy-v1` (= `AppConstants.privacyPolicyVersion` i `config/runtime.policyVersionCurrent`). Jeśli wersja się zmieni – najpierw SEC-26 (ponowna akceptacja) | `(Invoke-WebRequest https://tadecode.pl/tamitu/prywatnosc -UseBasicParsing).StatusCode` → `200` (to samo dla `/en`); na stronie widać wersję i datę; `Select-String lib/core/config/app_constants.dart -Pattern privacyPolicyVersion`; konsola Firebase prod → Firestore → `config/runtime.policyVersionCurrent` | właściciel (publikacja), security (zgodność treści z rejestrem v0.9 i pkt 10 `privacy-checklist.md`) | protokół: adres, wersja, data publikacji; opinia prawnika – odnotowana w protokole (sama opinia poza repo) | TAM-130 (REL-OWN-9), TAM-53 (SEC-14), TAM-64 (SEC-26, jeśli zmiana wersji) |
| A2 | **Zgoda AI `ai-consent-v2` po opinii prawnika**, wdrożona w aplikacji i w prod. Tekst opisuje odbiorcę i region (Vertex AI, UE), wynik B-2 (A4), wynik O5 (buforowanie), potwierdzenie pełnoletności (SEC-30). Tester dostaje build z `v2`; konto właściciela przechodzi ponowną zgodę | `Select-String lib/core/config/app_constants.dart -Pattern aiConsentVersion` → `ai-consent-v2`; konsola Firebase prod → `config/runtime.aiConsentVersionCurrent` = `ai-consent-v2`; wersja AAB na ścieżce testów (Play Console → Testy wewnętrzne → Wersje) zbudowana z commita z `v2`; na telefonie: po aktualizacji pojawia się ekran ponownej zgody | security + [PRAWNIK] (tekst), mobile-dev (wdrożenie), właściciel (`config/runtime`, build) | protokół: commit z `v2`, `versionCode` w Play, stan `config/runtime`; raport qa z ekranu zgody | TAM-67 (SEC-30); **brak zadania na v2** → nowe Z-1, Z-2 |
| A3 | **`deleteAccount` działa w prod** (P3-08), wdrożony po W-2 (`fn-account` z `tamitu.authUserDeleter`, bez `roles/firebaseauth.admin`). Usuwa: użytkownika Auth, `users/{uid}` rekurencyjnie, `usage/{uid}`, dane lokalne (`privacy-checklist.md` pkt 5); stary token po usunięciu nie tworzy nowych danych (T24) | `gcloud run services list --project=$p --region=europe-west4 --format="value(metadata.name)"` → jest `deleteaccount`; `gcloud run services describe deleteaccount --project=$p --region=europe-west4 --format="value(spec.template.spec.serviceAccountName)"` → `fn-account@…`; `gcloud projects get-iam-policy $p --flatten="bindings[].members" --filter="bindings.members:fn-account" --format="table(bindings.role)"`; test E2E qa na telefonie z aplikacją z Play (konto testowe, nie właściciela) | mobile-dev (kod), qa (test E2E), właściciel (wdrożenie, odczyty), security (przegląd) | raport qa (PR lub `docs/qa/`); protokół: lista ról `fn-account` | TAM-21 (P3-08), TAM-45 (SEC-07), TAM-68 (SEC-31, W-2), TAM-122 (REL-OWN-4) |
| A4* | **Decyzja właściciela w sprawie B-2** (monitoring nadużyć Google: przechowywanie promptów do 90 dni; rodzaj umowy z Google, SEC-15 poz. 4). Wynik opisany w polityce (A1) i zgodzie AI (A2) | `docs/open-questions.md`: wiersz **O6** ma status „odpowiedziane” z datą; `privacy-checklist.md` pkt 2 i 10.3 – usunięty nawias „[po potwierdzeniu SEC-15]” | właściciel (decyzja), [PRAWNIK], security (wpis do rejestru D6 i polityki) | `docs/open-questions.md` (O6); rejestr D6 | TAM-54 (SEC-15), TAM-13 (O5); **brak zadania decyzji** → nowe Z-3 |
| A5 | **Role Ś-1 i Ś-2 w prod**: konta `fn-*` mają wyłącznie role z tabeli SEC-17 sekcja 3 (`tamitu.fsConsentWriter`, `tamitu.fsUsageWriter`, `tamitu.fsConfigUpdater`, `tamitu.authUserReader`), bez `roles/datastore.user` (poza `fn-account`) i bez `roles/firebaseauth.viewer`. Zapis zgody i plan działają po zmianie | `gcloud iam roles list --project=$p --format="value(name)"` → 6 ról `tamitu.*`; `gcloud projects get-iam-policy $p --flatten="bindings[].members" --format="table(bindings.role,bindings.members)" --filter="bindings.members:fn-"` porównane z SEC-17 sekcja 4.2 (tabela „Dodaj/Usuń”); `gcloud secrets get-iam-policy UID_HASH_PEPPER --project=$p`; raport QA-1 (zgoda i plan działają) | właściciel (zmiana i odczyt), security (ocena wyniku) | runbook P3-03 etap 5 (wynik bez e-maili); protokół | TAM-122 (REL-OWN-4), TAM-68 (SEC-31), TAM-123 (REL-SEC-1), TAM-56 (SEC-17) |
| A6* | **Ponowna decyzja o `globalDailyLimit`** (O-TAM116-7 zakłada ponowną decyzję przy bramce). Przy jednym testerze limit globalny nie miał znaczenia; przy kilku osobach to on, a nie limit na konto, wyznacza koszt. Do wyboru: **25** (ADR-0014 Aneks A pkt 3) albo **50** z **aneksem do ADR-0014** (zasada 4 i 10 `CLAUDE.md` – nie zostawiamy odstępstwa od zatwierdzonego ADR bez zapisu) | konsola Firebase prod → Firestore → `config/runtime.globalDailyLimit`; `docs/adr/0014-*.md` – jest aneks z tą wartością (jeśli 50) | właściciel (decyzja i konsola), architect (aneks), security (sprawdzenie zgodności) | `docs/open-questions.md` (nowe pytanie przy bramce) i ADR-0014 (aneks) lub stan `config/runtime` w protokole | **brak** → nowe Z-4 |
| A7* | **Ponowna decyzja o blokadzie `testUids`** (O-TAM116-8). Decyzja opierała się na tym, że lista testerów w Play zawiera tylko właściciela. Po dodaniu testerów każdy z nich (i każdy, komu przekaże link opt-in) generuje plany na realnych danych. Właściciel potwierdza wariant D albo wybiera inne zabezpieczenie (zalecenie C3) | `docs/open-questions.md` – zapis decyzji z datą późniejszą niż 2026-11-26; konsola Firebase prod → `config/runtime.allowRealData` | właściciel; security (opis ryzyka w pytaniu) | `docs/open-questions.md` | **brak** → nowe Z-4 (razem z A6) |
| A8 | **Ochrona kosztów aktywna w prod**: spend cap Vertex AI 80 PLN aktywny, budżet 100 PLN z progami 50/90/100% i prognozą, alerty dochodzą (P1 planu). Bez `budgetGuard` (B3) to jedyne zabezpieczenie przed kosztem przy kilku osobach | konsola Billing → Budżety i alerty (budżet 100 PLN, progi); konsola Billing → spend cap Vertex AI (kwota, „Preview: tak/nie”); test: ostatni e-mail alertu lub wiadomość w temacie `budget-alerts` | właściciel | runbook P3-03 etap 3; protokół (kwoty, data odczytu) | TAM-122 (REL-OWN-4) |
| A9 | **Retencja z polityki działa w prod**: TTL `ACTIVE` na `usage.expireAt` i `usage_global.expireAt` (licznik do 4 dni), kubełek `tamitu-logs` 30 dni, sink do UE, `_Default` wyłączony. Polityka obiecuje te okresy (A1) – muszą być prawdziwe, zanim dotyczą innej osoby | `gcloud firestore fields ttls list --project=$p` → oba pola `ACTIVE`; `gcloud logging buckets describe tamitu-logs --location=europe-west4 --project=$p --format="value(retentionDays)"` → `30`; `gcloud logging sinks list --project=$p` → `tamitu-eu-sink` aktywny, `_Default` wyłączony | właściciel (odczyt), security (ocena) | runbook P3-03 etap 4 i 8; protokół | TAM-12 (O4-2), TAM-122 (REL-OWN-4) |
| A10 | **Logi prod bez danych osobowych** po okresie jednego testera: tylko pola z `logger.ts`, `uidHash` zamiast UID, bez e-maili, bez treści formularza i planu, bez tokenów (plan 4.9 f). Przegląd na realnym ruchu, zanim pojawi się ruch obcej osoby | właściciel na swoim komputerze: `gcloud logging read 'resource.type="cloud_run_revision"' --project=$p --freshness=30d --limit=1000 --format=json > $env:TEMP\tamitu-prod-logs.json`, potem `Select-String $env:TEMP\tamitu-prod-logs.json -Pattern '@','"uid"','idToken','destination','accommodation' \| Measure-Object` → `0` dopasowań; plik usunąć po przeglądzie. Do security trafiają tylko liczby i nazwy pól (`Get-Content … \| ConvertFrom-Json` → lista kluczy `jsonPayload`), nie treść | właściciel (odczyt), security (ocena listy pól) | protokół: liczba wpisów, lista kluczy, wynik wyszukiwania | TAM-61 (SEC-23 – dev), TAM-42 (SEC-04); **prod** → nowe Z-5 |
| A11 | **App Check w prod bez tokenów debug** (N-4) i z Play Integrity „Registered”; `ENFORCE_APP_CHECK=true` w funkcjach. Każdy nowy tester to nowe urządzenie – brak wyjątków „na chwilę” | konsola Firebase prod → App Check → Aplikacje → `pl.tadecode.tamitu` → „Zarządzaj tokenami debug” → lista pusta; `gcloud run services describe generateplan --project=$p --region=europe-west4 --format="yaml(spec.template.spec.containers[0].env)"` → `ENFORCE_APP_CHECK: 'true'`, `ALLOW_REAL_DATA` zgodne z decyzją | właściciel (odczyt), security | protokół | TAM-127 (REL-OWN-5), TAM-123 (REL-SEC-1) |

## 4. Część B – dodatkowo blokuje testy zamknięte, otwarte i produkcję

Wymagania Google Play dla ścieżek z przeglądem (plan 7.3) oraz punkty z sekcji 2a planu („ponadto przed testami
zamkniętymi”). Nie blokują dodania kolejnego testera na **testach wewnętrznych** – tam wystarcza część A.

| # | Warunek | Jak sprawdzić | Kto | Dowód (gdzie zapisany) | Jira |
|---|---|---|---|---|---|
| B1 | **Data Safety zgodna ze stanem aplikacji** w dniu przejścia: odpowiedzi z pliku TAM-131 sprawdzone z rejestrem (aktualna wersja), zmergowanym manifestem (tylko `INTERNET`, bez `ACCESS_*_LOCATION` i `AD_ID`) i stanem `deleteAccount` (A3). Jeśli od TAM-131 zmienił się rejestr – aktualizacja odpowiedzi | porównanie pliku odpowiedzi TAM-131 (`docs/security/`) z `personal-data-register.md`; uprawnienia: Play Console → App bundle explorer → wersja → Uprawnienia (albo `aapt2 dump permissions` na APK z bundletool); Play Console → Zawartość aplikacji → Bezpieczeństwo danych = „Zatwierdzono” | security (odpowiedzi i porównanie), właściciel (formularz w konsoli) | protokół: wersja rejestru, data wysłania formularza | TAM-131 (REL-SEC-2), TAM-52 (SEC-13) |
| B2 | **Strona WWW z instrukcją usuwania konta i danych** (wymóg Google Play dla aplikacji z kontami), adres wpisany w Play Console → Bezpieczeństwo danych → „Usuwanie danych”. Treść zgodna z A3 i polityką | `(Invoke-WebRequest <adres strony> -UseBasicParsing).StatusCode` → `200`; adres w Play Console | właściciel (publikacja), security (treść) | protokół: adres, data | **brak** → nowe Z-6 |
| B3 | **`budgetGuard` działa w prod** (P3-09): po przekroczeniu budżetu ustawia `aiEnabled=false`; `budgetguard` bez `allUsers`, `fn-budget` tylko z `tamitu.fsConfigUpdater`. Kończy czasowe odstępstwo od ADR-0003 (O-TAM116-5 b) | `gcloud run services get-iam-policy budgetguard --region=europe-west4 --project=$p` → bez `allUsers`; test qa w dev (symulowany komunikat budżetu → `aiEnabled=false`); odczyt `config/runtime` po teście | mobile-dev (kod), qa, właściciel (wdrożenie), security | raport qa; protokół | TAM-22 (P3-09) |
| B4* | **Decyzja o danych z okresu jednego testera** (2026-11-26 → bramka): zachować czy usunąć realne dane właściciela w prod (`users/{uid}/consents`, `usage`, logi 30 dni) i jak to opisać w rejestrze. Właściciel zapowiedział „decyzję później” (O-TAM116-1) | `docs/open-questions.md` – zapis decyzji; jeśli „usunąć” – wykonane przez `deleteAccount` na koncie właściciela (A3) i potwierdzone odczytem Firestore | właściciel (decyzja), security (opcje i wpis w rejestrze D18/D3) | `docs/open-questions.md`; rejestr | **brak** → nowe Z-7 |
| B5 | **Deklaracje „Zawartość aplikacji” w Play Console** zgodne z planem 7.3: polityka prywatności (URL z A1), reklamy „nie”, Advertising ID „nie używa”, grupa docelowa 18+, ocena treści IARC, dostęp do aplikacji dla recenzentów (konto testowe – bez danych realnych osoby) | Play Console → Zawartość aplikacji → wszystkie pozycje „Zatwierdzono”/„Ukończono” | właściciel; security (sprawdzenie zgodności z rejestrem i polityką) | protokół | **brak** → nowe Z-8 |

## 5. Część C – zalecenia (nie blokują)

| # | Zalecenie | Jak sprawdzić / gdzie | Kto | Jira |
|---|---|---|---|---|
| C1 | **Krótka informacja dla nowego testera** przed wysłaniem linku: to wersja testowa na realnych danych, AI działa przez Google w UE, jak usunąć konto, kontakt `tamitu@tadecode.pl`, nie przekazywać linku opt-in dalej | szablon w `docs/security/` | security + właściciel | nowe Z-9 |
| C2 | **Procedura na wypadek naruszenia ochrony danych** (wyciek, błędnie dodany tester, dane w logach): kto ocenia, zgłoszenie do UODO w 72 h, powiadomienie osób, szybkie blokady (`aiEnabled=false`, zdjęcie `allUsers` z `generateplan`, usunięcie testera w Play) | dokument w `docs/security/` | security, [PRAWNIK] | nowe Z-10 |
| C3 | **Techniczna lista dozwolonych kont przy realnych danych.** Dziś przy `allowRealData=true` kod nie sprawdza `testUids`, więc do testów zamkniętych jedyną barierą jest lista w Play. Zalecenie: osobna lista dozwolonych UID działająca także przy realnych danych (do czasu wydania publicznego) | ADR lub aneks ADR-0011 | architect → mobile-dev | nowe Z-11 |
| C4 | **Mała pierwsza grupa** (zalecenie: do 5 osób, znanych właścicielowi) i stopniowe zwiększanie; każde zwiększenie – przegląd A6 i A8 | Play Console → lista testerów (liczba adresów w protokole, bez adresów) | właściciel | – |
| C5 | Unieważnienie dostępu Google przy usunięciu konta (SEC-28) | – | architect/mobile-dev | TAM-65 (SEC-28) |
| C6 | Potwierdzenie regionu przetwarzania Google (SEC-10) i warunków dostawcy AI poz. 1–12 (SEC-15) przed testami zamkniętymi – warunki dla polityki A1 | `docs/security/przeglad-adr.md` | security, architect | TAM-49 (SEC-10), TAM-54 (SEC-15) |
| C7 | Automatyczne skanowanie sekretów i podatnych bibliotek w CI przed testami zamkniętymi | – | Steward, security | TAM-39 (SEC-01), TAM-46 (SEC-08), TAM-63 (SEC-25) |
| C8 | **Koniec okresu próbnego GCP ok. 2027-02-15** – decyzja o przejściu na płatne konto przed datą; bez niej prod staje i testerzy tracą dostęp (dostępność, a nie poufność) | konsola Billing | właściciel | – (plan K6) |

## 6. Czego ta lista nie obejmuje

- Wydania publicznego (bramka G5) i reklam – osobna ocena, w tym ponownie DPIA (`privacy-checklist.md` pkt 9).
- Treści polityki i zgód – są w `privacy-checklist.md` pkt 2 i 10; tu sprawdzamy tylko, że są opublikowane
  i wdrożone.
- Formularza Data Safety – przygotowuje TAM-131; tu sprawdzamy zgodność w dniu przejścia (B1).
