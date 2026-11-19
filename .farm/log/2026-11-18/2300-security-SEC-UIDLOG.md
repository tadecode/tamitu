# 23:00  security → orchestrator (kopia: mobile-dev, qa)  |  SEC-UIDLOG
- Zrobione: oceniłem OBS-DEV-3. W bajtkodzie `firebase-auth` 25.0.0 UID jest zapisywany przez bezwarunkowe `android.util.Log.d` („Notifying id token/auth state listeners about user ( … )”), bez `isLoggable`. Ten sam kod jest w buildzie debug i release, a domyślne reguły R8 we Flutterze nie usuwają logów. **UID trafi więc do logcat także w release** (pewność wysoka, z kodu; obserwacja na release – do weryfikacji na urządzeniu). Token debug App Check loguje tylko dostawca debug aktywowany wyłącznie w `dev`. Ryzyko niskie: na Androidzie 13 logcat jest czytelny tylko przez `adb`, raport błędu użytkownika lub aplikacje uprzywilejowane po jednorazowej zgodzie. Inne aplikacje widzą tylko własne logi.
- Artefakty: `docs/security/reviews/2026-11-18-sec-uidlog-logcat.md` (ocena), `docs/security/threat-model.md` (dopiski T7, T9), `docs/security/personal-data-register.md` v0.7 (D1, D18).
- Decyzje: OBS-DEV-3 – **akceptacja tymczasowa** dla testów z użytkownikami w `dev` (build debug). **Ograniczenie** w release regułą R8 `-maximumremovedandroidloglevel 3` w `android/app/proguard-rules.pro` jest **warunkiem przed publikacją `prod`**, razem z PRIV-05 zaliczonym na buildzie release. Bez ADR (zmiana konfiguracji buildu, bez wpływu na koszty).
- Do zrobienia przez odbiorcę:
  - mobile-dev: SEC-UIDLOG-1 – utworzyć `android/app/proguard-rules.pro` z `-maximumremovedandroidloglevel 3` (Flutter dołącza plik do release automatycznie). Jeśli AGP/R8 nie obsługuje tej reguły: `-assumenosideeffects class android.util.Log` z jawnymi sygnaturami `v`/`d` (bez `*`). Sprawdzić, że `flutter build apk --release --flavor dev` przechodzi.
  - qa: PRIV-05 na buildzie release (`devRelease`, konto testowe): logowanie, ponowne uruchomienie, `adb logcat -d -s FirebaseAuth RegionalFirebaseAuth` i grep po UID testowym. Oczekiwane: brak UID. Uruchamiać przez `.farm/test-lock.ps1`, po BUG-DEV-1. UID nie wpisywać do raportu.
  - orkiestrator: przy testach z użytkownikami dopisać do instrukcji, że raporty błędu (bugreport) od uczestników traktujemy jak dane osobowe (bez repo, usunięcie po analizie).
- Pytania/blokady: brak. Telefonu nie używałem.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: SEC-UIDLOG: review
- Zadania – nowe:
  - SEC-UIDLOG-1, „Release: usunięcie `Log.v/d` regułą R8 (`proguard-rules.pro`) – UID z Firebase Auth w logcat”, mobile-dev, zależności: ten PR; kryterium akceptacji: QA PRIV-05 na release bez UID; warunek przed publikacją `prod`
  - QA-PRIV-05-REL, „PRIV-05 na buildzie release (logcat bez UID)”, qa, zależności: SEC-UIDLOG-1, wolny telefon (po BUG-DEV-1)
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak (OBS-DEV-3 – ocenione: akceptacja tymczasowa w `dev`, ograniczenie przed `prod`)
