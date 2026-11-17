# 13:30  mobile-dev → orchestrator, security, steward  |  P3-04 / PR #61 – czerwona kontrola `secrets` (gitleaks)

- Zrobione: ustaliłem przyczynę czerwonej kontroli `secrets`. Log gitleaks czytałem tylko w zakresie reguły, pliku, linii i commitu (wartość zredagowana).
  - Jedno znalezisko: reguła `generic-api-key`, `test/core/db/account_database_test.dart:10`, commit `2357403e9f6acc500f2283005da1dc92aa911184`.
  - To **fałszywy alarm**: stała testowa klucza bazy SQLCipher – deterministyczny wzór bajtów (64 znaki hex), użyty tylko w testach na hoście do bazy w katalogu tymczasowym. Nie jest kluczem żadnej usługi ani prawdziwym kluczem bazy (ten jest losowany na urządzeniu i trzymany w `flutter_secure_storage`). Unieważnianie niczego nie jest potrzebne.
  - Poprawka w kodzie (commit `test: klucz testowy bazy budowany w czasie działania`): klucz testowy jest generowany w czasie działania, bez literału.
  - Po poprawce ponowny przebieg CI (run 44082075764) zgłasza już **tylko historyczny commit `2357403`** – gitleaks-action skanuje wszystkie commity z zakresu PR. Bieżące drzewo jest czyste.
  - Przejrzałem cały diff PR pod kątem innych literałów: poza tym miejscem są tylko sumy `sha256` w `pubspec.lock`, których gitleaks nie zgłasza. Brak `google-services.json`, tokenów App Check (token debug idzie wyłącznie przez `--dart-define`) i haseł.
- Artefakty: `test/core/db/account_database_test.dart`
- Decyzje: nie zmieniam `.gitleaks*` i nie przepisuję historii (wymaga zgody security/Stewarda).
- Do zrobienia przez odbiorcę (security/Steward, decyzja):
  - (a) **zalecane:** wpis do `.gitleaksignore` z odciskiem tego jednego znaleziska: `2357403e9f6acc500f2283005da1dc92aa911184:test/core/db/account_database_test.dart:generic-api-key:10`. Wyłącza tylko to znalezisko w tym commicie; nie wycisza reguły.
  - (b) alternatywa: squash przy scaleniu nie wystarczy, bo kontrola blokuje PR wcześniej. Przepisanie historii gałęzi wymagałoby force-push – tylko na wyraźną zgodę właściciela.
- Pytania/blokady: PR #61 pozostaje z czerwonym `secrets`, dopóki nie zapadnie decyzja (a) albo (b).

## Dla orkiestratora (backlog i pytania)
- Backlog – status: brak zmian.
- Backlog – nowe zadania: prośba do Stewarda (security akceptuje): wpis `.gitleaksignore` dla odcisku powyżej (PR #61).
- Pytania otwarte – nowe: brak.
- Pytania otwarte – zamknięte: brak.
