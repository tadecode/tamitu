# 19:00  mobile-dev → reviewer, qa  |  TAM-101 (P3-05-APP)
- Zrobione: wszystkie cztery etapy. (1) Klient `generatePlan` w aplikacji: port `PlanApi`, wersja callable (wzorzec `recordConsent`, timeout 120 s, mapowanie błędów przez `classifyCallableError`) i atrapa `FakePlanApi`. Klient jest podłączony w bootstrapie, emulatorach i trybie demo. (2) EK-05: formularz z walidacją, zgodą na AI (EK-06) przed pierwszym generowaniem i komunikatami EK-16 po powrocie z EK-07. (3) EK-07: generowanie z rotującymi tekstami, anulowanie z dialogiem i stan `ai_busy` przez istniejący `AiBusyView`/`AiBusyController`. Ponowienie używa tych samych danych i nowego `requestId`; sukces prowadzi do EK-08, inne błędy do EK-05 według EK-16. (4) EK-08: widok planu w pamięci, z zakładkami dni i podsumowaniem. Nawigacja: przycisk „Nowa podróż” na tymczasowym ekranie startowym → `/home/trip` → EK-07 (modalnie) → `/home/plan`. Formularz nie zostaje na stosie, a wstecz z EK-08 wraca na ekran startowy.
- Artefakty: `lib/features/plan_generation/` (domain, data, application, presentation), `lib/features/trip_form/` (walidacja, ekran), `lib/app/{router,providers,bootstrap,firebase_emulators,environment,home_screen}.dart`, `lib/core/ui/app_icon.dart` (ikony calendar, clock, more, route, add, remove), `lib/l10n/app_{pl,en}.arb` + wygenerowane pliki, testy `test/features/plan_generation/`, `test/features/trip_form/`, `test/helpers.dart`. PR: https://github.com/tadecode/tamitu/pull/164
- Decyzje (bez ADR, do wiadomości):
  - `testData`: w `dev` zawsze `true`; w `prod` tylko z `--dart-define=TAMITU_TEST_DATA=true` (ADR-0011 pkt 6). Emulatory zawsze wysyłają `true`.
  - Brak sprawdzania sieci przed wysłaniem (posrednik-api.md pkt 6). Komunikat `tripFormOfflineNotice` pojawia się dopiero po nieudanej próbie.
  - `consent_required`: `ai_processing` bez zsynchronizowanego rekordu otwiera EK-06 (wariant „updated”), a po zgodzie generowanie startuje ponownie. Zsynchronizowany rekord w wersji aplikacji kończy się CMP-18 „Zaktualizuj aplikację”. `privacy_policy` uruchamia ponowną ocenę sesji (router pokaże EK-03, jeśli brak lokalnej akceptacji), a formularz dostaje ogólny błąd.
  - `invalid_argument` ze znanym `field` oznacza błąd przy polu (`errorInvalidFormBody`). Bez `field` pokazujemy CMP-13.
  - Nowe klucze l10n spoza tabel specyfikacji: `tripFormErrorsCount` (ogłoszenie „2 pola wymagają poprawy” z sekcji Dostępność EK-05), `commonDaysCount` (`{days}` w `generationFor`), `tripFormDecrease`/`tripFormIncrease` (podpowiedzi −/+ w CMP-05), `languageNamePl`/`languageNameEn`.
- Do zrobienia przez odbiorcę: recenzja (komentarz w PR #164), potem QA ekranów. Prawdziwe wywołanie w dev zwróci `ai_unavailable`, bo model nie jest włączony (TAM-90). Pełną ścieżkę widać w wersji demo (`--dart-define=TAMITU_FAKE_BACKEND=true`), gdzie plan przychodzi z atrapy po 3 s.
- Pytania/blokady: brak blokad. Uwagi niżej.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-101: review (PR #164, wszystkie etapy gotowe: klient, EK-05, EK-07, EK-08)
- Zadania – nowe / uzupełnienia istniejących:
  - TAM-19 (P3-06, zapis planów): w EK-08 zostały oznaczone miejsca (`plan_screen.dart`, komentarze `TAM-19`): menu `more-vertical` → „Usuń plan” (EK-11) i snackbar `planSavedSnack` po EK-07. Snackbara celowo nie pokazujemy, bo mówi „Plan zapisany”, a plan jest dziś tylko w pamięci. Po zapisie trzeba też przekazać do niego `quota` (`PlanViewData.fresh`, `GeneratedPlan.quota`) oraz dodać listę planów (EK-04) zamiast tymczasowego ekranu startowego.
  - TAM-20 (P3-07, link do Map): przycisk „Trasa” przy punkcie planu (komentarz `TAM-20` w `_PlanItemTile`). Dane do linku są już w `PlanItem` (`name`, `locality`) i `TripInput.destination`.
  - Bez nowego zadania: dziś EK-08 po zabiciu procesu albo wejściu z linku pokazuje CMP-18 „Nie udało się otworzyć planu” (plan nie jest zapisany). Po TAM-19 ekran ma czytać plan z bazy.
- Pytania otwarte – nowe:
  - TAM101-1 (ux): nowe klucze spoza tabel specyfikacji (`tripFormErrorsCount`, `commonDaysCount`, `tripFormDecrease`/`Increase`, `languageNamePl`/`En`). Teksty przyjąłem roboczo, do akceptacji UX.
  - TAM101-2 (ux/architect): pasek EK-07 w specyfikacji to „Układamy plan”, a w makietach EK-07 i ai_busy „Nowa podróż”. Wybrałem makietę („Nowa podróż” na pasku, „Układamy plan…” jako tytuł w treści).
- Pytania otwarte – zamknięte: brak
