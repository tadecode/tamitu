# 14:50  architect → owner, orchestrator, steward, security, mobile-dev, qa  |  TAM-116
> **Lista zadań i pytań zastąpiona** wpisem `1600-architect-TAM-116-decyzje.md` (decyzje właściciela 2026-11-26).
- Zrobione: plan pierwszego wydania produkcyjnego na Google Play: testy wewnętrzne (projekt `tamitu-prod-tadecode`,
  App Check z Play Integrity bez tokenów debug). Stan prod opisany tylko z dokumentów (bez odczytów chmury); różnice
  „według przekazania” (spend cap 80 PLN, `disableCache`, `globalDailyLimit=25`) – do potwierdzenia odczytem (O-TAM116-6).
  ADR-0019 (proponowany) o budowaniu i podpisywaniu. Niczego nie zmieniano w chmurze ani w kodzie.
- Artefakty: docs/architecture/plan-wydania-testy-wewnetrzne.md (nowy), docs/adr/0019-budowanie-i-podpisywanie-wydan-android.md (nowy),
  docs/open-questions.md (sekcja TAM-116, okres przejściowy FARM-006)
- Decyzje (propozycje do zatwierdzenia): Play App Signing + klucz przesyłania u właściciela poza repo, build AAB lokalnie,
  ręczne przesłanie (ADR-0019); w prod tylko `recordConsent` i `generatePlan`; `ALLOW_REAL_DATA=false`, AAB z
  `TAMITU_TEST_DATA=true`; wszystkie poprawki ról SEC-17 (W-1, W-2, Ś-1, Ś-2) w prod przed pierwszym wdrożeniem;
  `budgetGuard` i `deleteAccount` czasowo bez wdrożenia (O-TAM116-5).
- Do zrobienia przez odbiorcę: zadania z sekcji 10.2 planu (lista niżej). Właściciel: 9 zadań (OWN-1…OWN-9) i odpowiedzi
  O-TAM116-1…6. Płatne: tylko opłata Play Console 25 USD (jeśli nieopłacona); AI w prod ok. 0–2 PLN/mies. z kredytu.
- Pytania/blokady: O-TAM116-1…6 (wpisane do `docs/open-questions.md`).

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-116: review (PR do `main`; sama dokumentacja – bez reviewer)
- Zadania – nowe (tytuły prostym językiem; szczegóły i „gotowe, gdy” – plan, sekcja 10.2):
  - OWN-1 „Załóż konto Google Play Console firmy (D-U-N-S, opłata 25 USD)”, owner, zależy od: – (poza farmą; O-TAM116-4)
  - OWN-2 „Utwórz aplikację Tamitu w Play Console i listę testerów wewnętrznych”, owner, zależy od: OWN-1
  - OWN-3 „Wygeneruj klucz przesyłania aplikacji i schowaj go poza repozytorium”, owner, zależy od: ADR-0019 (O-TAM116-3)
  - OWN-4 „Przygotuj projekt produkcyjny: role kont funkcji, TTL, sekret, konto budujące”, owner, zależy od: MD-2 (merge), O-TAM116-5
  - OWN-5 „Dodaj odciski klucza podpisu do Firebase prod i włącz App Check z Play Integrity”, owner, zależy od: OWN-8
  - OWN-6 „Wdróż w produkcji funkcje zgody i tworzenia planu”, owner, zależy od: SEC-1
  - OWN-7 „Włącz tworzenie planów w produkcji tylko dla swojego konta”, owner, zależy od: OWN-5, OWN-6
  - OWN-8 „Zbuduj plik AAB i prześlij pierwsze wydanie na testy wewnętrzne”, owner, zależy od: MD-3, OWN-2, OWN-3
  - OWN-9 „Opublikuj politykę prywatności pod adresem tadecode.pl/tamitu/prywatnosc”, owner (treść: security, [PRAWNIK]), zależy od: O-TAM116-2
  - STW-1 „Sprawdź, że skan sekretów i .gitignore blokują klucze podpisu i pliki prod”, steward, zależy od: – (prośba GH w `.farm/requests/`)
  - STW-2 „Budowanie wydania Androida w CI z zatwierdzeniem właściciela (później)”, steward, zależy od: ADR-0019 etap 2 + decyzja właściciela – założyć jako „później”
  - SEC-1 „Przegląd bezpieczeństwa projektu produkcyjnego przed pierwszym wdrożeniem”, security, zależy od: OWN-4
  - SEC-2 „Przygotuj odpowiedzi do formularza Data Safety w Google Play (bez lokalizacji)”, security, zależy od: –
  - SEC-3 „Lista warunków przed realnymi danymi w produkcji (ALLOW_REAL_DATA)”, security, zależy od: –
  - MD-1 „Podpisuj wydanie produkcyjne kluczem przesyłania zamiast klucza debug”, mobile-dev, zależy od: ADR-0019 zatwierdzony
  - MD-2 „Dodaj plik środowiska produkcyjnego dla funkcji (.env prod)”, mobile-dev, zależy od: O-TAM116-1
  - MD-3 „Instrukcja budowania AAB i próba wersji release na telefonie”, mobile-dev (z właścicielem), zależy od: MD-1
  - QA-1 „Sprawdź aplikację zainstalowaną z Google Play na telefonie właściciela”, qa, zależy od: OWN-7
- Pytania otwarte – nowe: O-TAM116-1 (realne dane w prod), O-TAM116-2 (polityka opublikowana?), O-TAM116-3 (ADR-0019),
  O-TAM116-4 (konto Play, D-U-N-S, opłata), O-TAM116-5 (role SEC-17 w prod od razu; bez `budgetGuard`/`deleteAccount`),
  O-TAM116-6 (potwierdzenie stanu prod) – wszystkie do owner; już wpisane w tym PR (okres przejściowy FARM-006)
- Pytania otwarte – zamknięte: brak
- Uwagi: po wykonaniu OWN-4/OWN-6 wynik odczytów do runbooka P3-03 (poza uprawnieniami architekta – orkiestrator);
  O5 zamknąć po potwierdzeniu `disableCache=true` w obu projektach.
