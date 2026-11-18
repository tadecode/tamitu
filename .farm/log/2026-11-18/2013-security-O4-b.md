# 20:13  security → orchestrator (kopia: architect, dba, mobile-dev)  |  O4-b
- Zrobione: zapisałem decyzję właściciela w O4-b. Właściciel odpowiedział orkiestratorowi 2026-11-18: „Skracamy (3 dni)”, czyli przyjął rekomendację security z SEC-34. Rejestr ma wersję 0.6. D10 opisuje teraz retencję `expireAt = max(resetAt(now) + 2 d, now + 2 d)`, czyli do ok. 3 dni od ostatniego użycia plus do ok. 24 h opóźnienia TTL; w polityce prywatności „do 4 dni od ostatniego użycia”. Sekcja O4-b to już nie „decyzja security”, tylko „rekomendacja security, zatwierdzona przez właściciela 2026-11-18”. `usage_global` bez zmian: +7 dni, bez danych osobowych (sam licznik dobowy, bez UID; zgodne z `docs/data/model-danych.md`). Adnotacja „TTL niewdrożony (O4-2)” zostaje. W `privacy-checklist.md` poprawiłem tabelę retencji i szkic polityki prywatności (pkt 2 i 7): licznik ma tam własną pozycję „do 4 dni od ostatniego użycia”, oddzielnie od logów (30 dni).
- Artefakty: `docs/security/personal-data-register.md` (v0.6: nagłówek zmian, D10, sekcja „Retencja licznika użycia (D10, O4-b)”), `docs/security/privacy-checklist.md` (tabela retencji, szkic polityki pkt 2 i 7), `docs/open-questions.md` (tylko wiersz O4-b: zamknięte; poprawiony też błędny odnośnik `docs/security/przechowywanie-i-retencja.md` → `docs/data/...`).
- Decyzje: O4-b – właściciel, 2026-11-18: „Skracamy (3 dni)”. ADR nie jest potrzebny, bo ADR-0003 nie ustala okresu. Wpis SEC-34 (`1951-security-SEC-34.md`) nazywał to decyzją security, a stan właściwy opisuje ten wpis.
- Do zrobienia przez odbiorcę:
  - dba i architect (równoległe sesje O4-b): `docs/data/schema/firestore-ttl-indexes.md`, `docs/data/model-danych.md`, `docs/data/przechowywanie-i-retencja.md` muszą podawać ten sam wzór. Tego PR-a nie dotyczą zmiany w `docs/data/`.
  - mobile-dev (P3-05): stała `usageExpireAt(now) = max(resetAt(now) + 2 d, now + 2 d)` w `limits.ts` z testem `usageExpireAt(now) > resetAt(now)` (23:59:59 Europe/Warsaw, dni zmiany czasu). **Rejestr nie przewiduje już okresu przejściowego z 30 dniami.** P3-05 ze stałą 30 dni byłby niezgodny z rejestrem.
  - security (później): zdjąć adnotację „TTL niewdrożony” po potwierdzonym O4-2 w dev i prod.
- Pytania/blokady: brak. Wdrożenie TTL nadal czeka na O4-2 (właściciel).

## Dla orkiestratora (zadania i pytania)
- Zadania – status: SEC-34-follow (rejestr D10 → `resetAt` + 2 dni): review, w części dotyczącej retencji. Zdjęcie adnotacji TTL po O4-2 zostaje do zrobienia.
- Zadania – nowe: brak (O4-b-dba, O4-b-arch, O4-b-dev zgłoszone w SEC-34; w O4-b-dev dopisać, że stała 30 dni jest już niezgodna z rejestrem)
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: **O4-b** – zamknięte przez właściciela 2026-11-18 („Skracamy (3 dni)”): `expireAt = max(resetAt(now) + 2 d, now + 2 d)`; wiersz w `docs/open-questions.md` zaktualizowany w tym PR-ze
