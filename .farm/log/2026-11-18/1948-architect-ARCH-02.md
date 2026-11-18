# 19:48  architect → orchestrator (kopia: security, mobile-dev)  |  ARCH-02
- Zrobione: `docs/data/model-danych.md` pkt 3 (v0.5) zgodny z decyzją O4 (wariant A): `usage/{uid}` ma nowe pole `expireAt` (Timestamp = ostatni zapis + 30 dni, ustawiane przy rezerwacji i zwrocie slotu) i to na nim jest polityka TTL; `updatedAt` zostaje jako znacznik diagnostyczny bez TTL i bez indeksu. `usage_global/{day}.expireAt` = ostatni zapis + 7 dni. Dodany akapit „Retencja przez TTL” (pola TTL, wyłączenia z indeksów, typ Timestamp, czas serwera, stan wdrożenia O4-2). W `docs/data/przechowywanie-i-retencja.md` (wiersz D10) dopisane pole TTL; okres retencji bez zmian.
- Artefakty: `docs/data/model-danych.md`, `docs/data/przechowywanie-i-retencja.md`. Źródła: `docs/data/schema/firestore-ttl-indexes.md` (PR #73), `backend/firestore.indexes.json` (O4-1, PR #77 – zgodny z modelem), `docs/open-questions.md` (O4, O4-b).
- Decyzje: brak nowych. Spójność z ADR sprawdzona: ADR-0003 („TTL na `usage`”) i ADR-0002 (rezerwacja w `usage/{uid}`, `usage_global/{dzień}`; Aneks A pkt 1) nie wskazują pola TTL – **zmiana ADR nie jest potrzebna** (zgodnie z oceną dba w `firestore-ttl-indexes.md` pkt 2).
- Do zrobienia przez odbiorcę:
  - security (SEC-34): w `docs/security/personal-data-register.md` D10 pola Firestore to nadal `day`, `count`, `updatedAt` – dopisać `expireAt` (metadana retencji, nie nowa kategoria) i „TTL na `expireAt`”; po O4-2 usunąć adnotację „polityki TTL niewdrożone”. Ewentualnie `privacy-checklist.md` wiersz D10. Nie zmieniałem `docs/security/`.
  - mobile-dev (P3-05): zapis `usage/{uid}` i `usage_global` wg `firestore-ttl-indexes.md` pkt 3.2 (już opisane przez dba); model danych v0.5 jest z tym zgodny.
- Pytania/blokady: brak. O4-b (skrócenie retencji D10) pozostaje otwarte u security; jeśli zostanie przyjęte, w modelu zmieni się tylko opis okresu (schemat i polityka TTL bez zmian).

## Dla orkiestratora (zadania i pytania)
- Zadania – status: ARCH-02: review (PR do `main`)
- Zadania – nowe: brak (aktualizacja D10 w rejestrze mieści się w SEC-34 – proszę potwierdzić, że security ją uwzględni; jeśli nie, nowe zadanie: „D10 – pole `expireAt` w rejestrze”, rola security, zależność: ARCH-02)
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak (O4 zamknięte wcześniej przez dba; ARCH-02 domyka zapis w modelu danych – można dopisać w O4 „model danych v0.5, ARCH-02”)
