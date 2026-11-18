# 22:35  qa → orchestrator, owner  |  QA-P3-04-DEV
- Zrobione: pierwszy test aplikacji na prawdziwym telefonie (Android 13, USB, przez `.farm/test-lock.ps1`) – build `dev` debug z `google-services.json` właściciela (kopia tylko na czas buildu, usunięta), App Check debug (token telefonu zarejestrowany przez właściciela), logowanie Google „kontem testowym właściciela" wobec `tamitu-dev-tadecode`. 20 przypadków z `test-plan-p3-04.md` na urządzeniu; zrzuty ekranu przekazane właścicielowi poza repo.
- Wyniki: zaliczone SIGN-01/02/04/05/06/08/10/13/15/16/17/19/20, GATE-07 (M), GATE-08, CONS-02, CONS-09, CONS-03 (klient); **niezaliczony SIGN-12 (BUG-DEV-1)**; częściowo PRIV-05, API-10 (realny App Check), A11Y-04. Zapis zgody w Firestore niesprawdzony – funkcje `dev` niewdrożone (404).
- Artefakty: `docs/qa/verify-p3-04-dev.md`
- Decyzje: brak
- Do zrobienia przez odbiorcę:
  - owner: usunąć użytkownika testowego z Firebase Auth `dev` i token debug App Check telefonu z konsoli (raport, sekcja 5)
  - mobile-dev: BUG-DEV-1
- Pytania/blokady: brak

## Dla orkiestratora (zadania i pytania)
- Zadania – status: QA-P3-04-DEV: review (werdykt „odrzucone – 1 błąd poważny"; po poprawce powtórka tylko SIGN-12/SIGN-14 na urządzeniu)
- Zadania – nowe:
  - BUG-DEV-1 – „Anulowanie wyboru konta Google pokazuje błąd zamiast »anulowano« (US-001 AC2)", rola mobile-dev (diagnoza kodu `GoogleSignInException` na urządzeniu, poprawka `classifyGoogleSignInError`), potem qa (powtórka na urządzeniu); zależności: brak
  - QA-P3-04-DEV-2 – „Zapis zgody end-to-end na urządzeniu (SIGN-11 serwer, CONS-01, RECON-03, AIC-04)", rola qa; zależność: wdrożenie funkcji w `dev` (P3-05 / GH-010)
  - UX-ICON – „Ikona aplikacji i grafika EK-02 (dziś logo Flutter w oknie Google i pusty prostokąt ilustracji)", rola ux + mobile-dev (OBS-DEV-1, OBS-DEV-2)
  - DOC-APPCHECK-DEVICE – „Instrukcja tokenu debug App Check dla urządzeń testowych w `android/FIREBASE.md`" (OBS-DEV-4), rola mobile-dev
  - SEC-UIDLOG – „Ocena: UID w logcat z biblioteki Firebase Auth (OBS-DEV-3)", rola security
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak
