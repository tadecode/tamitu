# 19:51  security → orchestrator (kopia: architect, dba, mobile-dev)  |  SEC-34
- Zrobione: rejestr D10 opisuje retencję jako „TTL na `expireAt` (= ostatnia aktualizacja + 30 dni)”, `updatedAt` bez TTL; `usage_global` – TTL na `expireAt` = ostatni zapis + 7 dni. Adnotacja „TTL niewdrożony (O4)” zostaje i wskazuje, że wdrożenie czeka na O4-2 (właściciel: `firebase deploy --only firestore:indexes` w dev, potem w prod); zdjąć ją dopiero po wdrożeniu w obu projektach. Oceniłem O4-b. **Decyzja security: skrócić** retencję D10 do `expireAt = max(resetAt(now) + 2 d, now + 2 d)`, czyli ok. 3 dni od ostatniego użycia plus do ok. 24 h opóźnienia TTL. Uzasadnienie jest w nowej sekcji rejestru. Ta sama zmiana jest w `privacy-checklist.md` (tabela retencji).
- Artefakty: `docs/security/personal-data-register.md` (v0.5: D10, sekcja „Retencja licznika użycia (D10, O4-b)”), `docs/security/privacy-checklist.md` (wiersz D10).
- Decyzje: O4-b – tak, według wzoru powyżej. Decyzja należy do security (wpis O4-b w `docs/open-questions.md`). Zmiana tylko zmniejsza zakres przetwarzania, a ADR-0003 nie ustala okresu retencji, więc nie trzeba ADR ani decyzji właściciela. Właściciel jak dotąd zatwierdza tylko tekst polityki prywatności („do 4 dni od ostatniego użycia”). Dopóki specyfikacja i kod nie zostaną zmienione, rejestr podaje 30 dni.
- Do zrobienia przez odbiorcę:
  - **Zlecenie dotyczyło `docs/security/przechowywanie-i-retencja.md`, ale taki plik nie istnieje.** Dokument retencji to `docs/data/przechowywanie-i-retencja.md` (wiersz „Licznik użycia (D10)”: „TTL 30 dni od ostatniej aktualizacji”), który jest poza uprawnieniami security i poza zakresem SEC-34. Proponuję, żeby architect w ARCH-02 albo w kolejnym zadaniu zmienił go na „TTL na `expireAt` (= ostatnia aktualizacja + 30 dni)”, a po wdrożeniu O4-b na „`resetAt` + 2 dni”. To samo dotyczy `docs/data/model-danych.md`, gdzie `usage/{uid}` ma „`updatedAt` (polityka TTL 30 dni)”.
  - dba: w `docs/data/schema/firestore-ttl-indexes.md` (pkt 2.1, 3, 3.1, 3.2 ust. 5, 7) zmienić stałą na `max(resetAt(now) + 2 d, now + 2 d)`, z testem `usageExpireAt(now) > resetAt(now)` dla 23:59:59 i dni zmiany czasu.
  - mobile-dev: w P3-05 stała w `limits.ts` według specyfikacji dba. Jeżeli P3-05 wejdzie wcześniej ze stałą 30 dni, rejestr nadal jest zgodny, a skrócenie trzeba zrobić osobnym małym PR-em.
  - security (po dwóch powyższych): zmienić D10 i `privacy-checklist.md` z 30 dni na `resetAt` + 2 dni; po O4-2 zdjąć adnotację „TTL niewdrożony”.
- Pytania/blokady: brak. Wdrożenie TTL nadal czeka na O4-2 (właściciel).

## Dla orkiestratora (zadania i pytania)
- Zadania – status: SEC-34: review
- Zadania – nowe:
  - O4-b-dba, „Specyfikacja TTL `usage`: `expireAt = max(resetAt + 2 d, now + 2 d)`”, dba, zależności: ten PR
  - O4-b-arch, „`docs/data/przechowywanie-i-retencja.md` i `model-danych.md`: D10 TTL na `expireAt` (najpierw +30 d, po O4-b `resetAt` + 2 d)”, architect, zależności: ARCH-02 (może być w jego zakresie), O4-b-dba
  - O4-b-dev, „Stała retencji `usage` w `limits.ts` (P3-05) według O4-b”, mobile-dev, zależności: O4-b-dba (lub w ramach P3-05)
  - SEC-34-follow, „Rejestr D10: retencja `resetAt` + 2 dni; zdjęcie adnotacji TTL po O4-2”, security, zależności: O4-b-dev, O4-2
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: **O4-b** – tak (decyzja security 2026-11-18): `expireAt = max(resetAt(now) + 2 d, now + 2 d)`; uzasadnienie w `docs/security/personal-data-register.md`, sekcja „Retencja licznika użycia (D10, O4-b)”
