# 16:00  architect → orchestrator, owner, security, mobile-dev, qa, steward  |  TAM-116
- Zrobione: wprowadziłem do planu, ADR-0019 i `docs/open-questions.md` decyzje właściciela z 2026-11-26 (O-TAM116-1…6,
  przekazał orkiestrator). Realne dane w prod od razu, z bramką przed każdym kolejnym testerem (plan, sekcja 2a).
  ADR-0019 ma status „zatwierdzony” z Aneksem A. Konto Play istnieje, więc OWN-1 i koszt K1 odpadają. Zgoda na
  role SEC-17 od razu oraz na brak `budgetGuard` i `deleteAccount`. Stan prod z odczytu orkiestratora jest
  w sekcji 3 planu. Dwa nowe pytania: O-TAM116-7 (`globalDailyLimit` 50 → 25) i O-TAM116-8 (`testUids` przy
  realnych danych). Bez zmian w chmurze i w kodzie.
- Artefakty: docs/architecture/plan-wydania-testy-wewnetrzne.md, docs/adr/0019-budowanie-i-podpisywanie-wydan-android.md,
  docs/open-questions.md (sekcja TAM-116). Ten wpis zastępuje listę zadań z `1450-architect-TAM-116.md`.
- Decyzje: brak nowych architektonicznych; Aneks A ADR-0019 przy zatwierdzeniu (stała `TAMITU_TEST_DATA=true`
  zostaje w buildzie testów wewnętrznych jako zabezpieczenie dla wariantu R).
- **Ustalenie techniczne:** `assertDataPolicy` (`backend/functions/src/config.ts`) przy `ALLOW_REAL_DATA=true`
  **i** `config/runtime.allowRealData=true` w ogóle nie sprawdza `testUids`. Warunek właściciela „AI tylko dla mojego
  konta” jest wtedy spełniony tylko organizacyjnie, przez listę testerów w Play i App Check. Rekomendacja (wariant R):
  `config/runtime.allowRealData=false`, dopóki jest jeden tester, przy `.env` `ALLOW_REAL_DATA=true` zgodnie z decyzją.
- Do zrobienia przez odbiorcę: orkiestrator – zadania niżej, pytania O-TAM116-7 i -8 do właściciela, odczyt
  z O-TAM116-6 do runbooka P3-03 (etapy 5, 8, 9), zamknięcie O5 dla prod (`disableCache=true`).
- Pytania/blokady: O-TAM116-7, O-TAM116-8 (blokują tylko OWN-7).

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-116: review (PR #186, sama dokumentacja).
- Zadania – nowe (ostateczna lista, w kolejności; szczegóły i „gotowe, gdy” – plan, sekcja 10.2; OWN-1 **odpada**):
  1. MD-2 „Dodaj plik środowiska produkcyjnego dla funkcji (.env prod)”, mobile-dev, zależy od: –
  2. OWN-3 „Wygeneruj klucz przesyłania aplikacji i schowaj go poza repozytorium”, owner, zależy od: –
  3. MD-1 „Podpisuj wydanie produkcyjne kluczem przesyłania zamiast klucza debug”, mobile-dev, zależy od: – (ADR-0019 zatwierdzony)
  4. STW-1 „Sprawdź, że skan sekretów i .gitignore blokują klucze podpisu i pliki prod”, steward (prośba GH), zależy od: –
  5. OWN-2 „Utwórz aplikację Tamitu w Play Console i listę testerów wewnętrznych (tylko Ty)”, owner, zależy od: –
  6. OWN-4 „Przygotuj projekt produkcyjny: role kont funkcji, TTL, konto budujące, spend cap”, owner, zależy od: MD-2 (merge)
  7. SEC-1 „Przegląd bezpieczeństwa projektu produkcyjnego przed pierwszym wdrożeniem”, security, zależy od: OWN-4
  8. OWN-6 „Wdróż w produkcji funkcje zgody i tworzenia planu”, owner, zależy od: SEC-1
  9. MD-3 „Instrukcja budowania AAB i próba wersji release na telefonie”, mobile-dev (z właścicielem), zależy od: MD-1, OWN-3
  10. OWN-8 „Zbuduj plik AAB i prześlij pierwsze wydanie na testy wewnętrzne”, owner, zależy od: MD-3, OWN-2
  11. OWN-5 „Dodaj odciski klucza podpisu do Firebase prod i włącz App Check z Play Integrity”, owner, zależy od: OWN-8
  12. OWN-7 „Włącz tworzenie planów w produkcji tylko dla swojego konta”, owner, zależy od: OWN-5, OWN-6, O-TAM116-7, O-TAM116-8
  13. QA-1 „Sprawdź aplikację zainstalowaną z Google Play na telefonie właściciela”, qa, zależy od: OWN-7
  14. OWN-9 „Opublikuj politykę prywatności pod adresem tadecode.pl/tamitu/prywatnosc”, owner (treść: security, [PRAWNIK]), zależy od: dane firmy (S1); warunek 1 bramki 2a
  15. SEC-2 „Przygotuj odpowiedzi do formularza Data Safety w Google Play (bez lokalizacji)”, security, zależy od: –
  16. SEC-3 „Lista kontrolna bramki przed dodaniem kolejnych testerów i testami zamkniętymi”, security, zależy od: –
  17. STW-2 „Budowanie wydania Androida w CI z zatwierdzeniem właściciela”, steward, zależy od: ADR-0019 etap 2 + decyzja właściciela – założyć jako „później”
- Pytania otwarte – nowe: O-TAM116-7 (`globalDailyLimit` w prod 50 → 25? rekomendacja: 25), O-TAM116-8
  (`config/runtime.allowRealData=false`, dopóki jest jeden tester? rekomendacja: tak) – do owner; wpisane w tym PR.
- Pytania otwarte – zamknięte: O-TAM116-1 (realne dane od razu, bramka 2a), O-TAM116-2 (polityka nieopublikowana →
  OWN-9), O-TAM116-3 (ADR-0019 zatwierdzony), O-TAM116-4 (konto Play istnieje), O-TAM116-5 (zgoda a i b), O-TAM116-6
  (odczyt orkiestratora; spend cap – OWN-4). Statusy już wpisane w `docs/open-questions.md` w tym PR.
- Bramka (stała zasada od 2026-11-26): przed dodaniem kogokolwiek do listy testerów w Play sprawdzić warunki z planu,
  sekcja 2a.
