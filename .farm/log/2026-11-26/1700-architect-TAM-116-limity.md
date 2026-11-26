# 17:00  architect → orchestrator, owner, security, qa  |  TAM-116
- Zrobione: wprowadziłem decyzje właściciela z 2026-11-26 w sprawie O-TAM116-7 i O-TAM116-8 (przekazał orkiestrator).
  W prod zostaje `globalDailyLimit = 50`. To świadome odstępstwo od ADR-0014 Aneks A pkt 3; ADR-0014 nie jest
  zmieniony. Lista `testUids` nie blokuje AI, bo w prod `ALLOW_REAL_DATA=true` i `allowRealData=true`. Oba ryzyka są
  zapisane jako świadomie przyjęte (plan, sekcje 4.7, 9 K3 i 11). Zaktualizowałem OWN-7 i kolejność zadań. Przy okazji
  naprawiłem rozbitą tabelę `config/runtime` w sekcji 4.7.
- Artefakty: docs/architecture/plan-wydania-testy-wewnetrzne.md, docs/adr/0019-budowanie-i-podpisywanie-wydan-android.md
  (Aneks A pkt 2), docs/open-questions.md (O-TAM116-7, -8 odpowiedziane).
- Decyzje: właściciela (wyżej); architektonicznych brak.
- Do zrobienia przez odbiorcę: orkiestrator – patrz niżej. qa (QA-1) – przy teście sprawdzić w logach, że
  `generatePlan` działa bez wpisu w `testUids` (`allowRealData=true`), i nie zgłaszać tego jako błąd.
- Pytania/blokady: brak. Wszystkie O-TAM116-1…8 są rozstrzygnięte.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-116: review (PR #186).
- Zadania – nowe: lista z `1600-architect-TAM-116-decyzje.md` obowiązuje z jedną zmianą. Pkt 12 to OWN-7 „Włącz
  tworzenie planów w produkcji (realne dane, tylko Ty na liście testerów)”, owner, zależy od: OWN-5, OWN-6 (bez
  zależności od pytań). Gotowe, gdy: `allowRealData=true`, `globalDailyLimit=50`, `perUserDailyLimit=5`,
  `aiEnabled=true` na czas testu, lista testerów w Play = tylko właściciel.
- **Propozycja – aneks do ADR-0014?** Rekomendacja: **tak, krótki aneks** (np. ADR-0014 Aneks B, architect, mały PR).
  Powody: ADR-0014 Aneks A pkt 3 mówi „25/dobę w dev **i** prod”, a prod ma 50. Bez zapisu w ADR rozbieżność wygląda
  na pomyłkę, a kolejne role (security, qa, przegląd przed wydaniem publicznym, ADR-0002 Aneks A pkt 5b) mogą ją
  „naprawić” albo zgłaszać jako błąd. Treść aneksu: prod 50/dobę decyzją właściciela z 2026-11-26 na czas testów
  wewnętrznych z jednym testerem; ryzyko ok. 164 PLN/mies. przy nadużyciu; ochrona: spend cap 80 PLN i budżet
  100 PLN; ponowna decyzja przy bramce 2a (przed kolejnymi testerami). Alternatywa: tylko wpis w tym planie
  i w `docs/open-questions.md` (już jest), bez aneksu. Do decyzji właściciela.
- Pytania otwarte – nowe: brak.
- Pytania otwarte – zamknięte: O-TAM116-7 (prod zostaje przy 50, świadome odstępstwo od ADR-0014), O-TAM116-8 (bez
  blokady `testUids`, ryzyko przyjęte). Oba już wpisane w `docs/open-questions.md` w tym PR.
