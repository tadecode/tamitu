# 20:14  architect → orchestrator (kopia: dba, security, mobile-dev)  |  O4-b
- Zrobione: `docs/data/model-danych.md` (v0.6) pkt 3: `usage/{uid}.expireAt = max(resetAt(now) + 2 d, now + 2 d)` zamiast `updatedAt + 30 dni`; retencja do ok. 3 dni od ostatniego użycia (+ do ok. 24 h opóźnienia TTL); w akapicie „Retencja przez TTL” stałe P3-05 i warunek poprawności limitu (`usageExpireAt(now) > resetAt(now)`, dolne ograniczenie `now + 2 d`). `usage_global.expireAt` bez zmian (+7 dni). `docs/data/przechowywanie-i-retencja.md` (v0.3): wiersz D10 z nowym okresem.
- Artefakty: `docs/data/model-danych.md`, `docs/data/przechowywanie-i-retencja.md`. Źródło decyzji: `docs/security/personal-data-register.md`, sekcja „Retencja licznika użycia (D10, O4-b)” (zatwierdzenie właściciela 2026-11-18).
- Decyzje: brak nowych. Spójność z ADR sprawdzona: żaden zatwierdzony ADR nie podaje 30 dni dla `usage` – ADR-0003 mówi tylko „TTL na `usage`”, ADR-0002 i ADR-0004 opisują rezerwację i usuwanie `usage/{uid}` bez okresu (30 dni w ADR-0002/0003/0004 dotyczy wyłącznie logów D11). **Nowy ADR nie jest potrzebny.**
- Do zrobienia przez odbiorcę:
  - dba (równoległa sesja): `docs/data/schema/firestore-ttl-indexes.md` (pkt 2.1, 3, 3.1, 3.2 ust. 1 i 5, 7, 8 – m.in. „`expireAt − now = 30 d`” w teście i „+ 30 d” w teście dev); nie zmieniałem tego pliku.
  - security (równoległa sesja): D10 w rejestrze i `privacy-checklist.md`; nie zmieniałem `docs/security/`.
  - mobile-dev (P3-05): stała w `limits.ts` wg modelu v0.6 i dokumentu dba.
- Pytania/blokady: brak. Uwaga: `docs/architecture/uwagi-dla-orchestratora.md` pkt 5 (historyczna notatka sprzed O4) nadal mówi o „TTL 30 dni” dla D10 – to zapis archiwalny, nie zmieniałem go; jeśli orkiestrator traktuje ten plik jako aktualny, proszę o zgodę na dopisek „zastąpione przez O4-b”.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: O4-b (część architekta): review (PR do `main`)
- Zadania – nowe: brak (zmiana stałej w P3-05 mieści się w istniejącym zadaniu mobile-dev)
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: O4-b – zatwierdzone przez właściciela 2026-11-18 (`expireAt = max(resetAt(now) + 2 d, now + 2 d)`); model danych v0.6 i retencja v0.3 zaktualizowane (zamknięcie po merge PR-ów architekta, dba i security)
