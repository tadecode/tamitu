# 14:42  analyst → owner, orchestrator, architect, security  |  AN-CREDITS
- Zrobione: wstępna analiza pomysłu właściciela (2026-11-20) – przedpłacone kredyty „słoneczka" zamiast subskrypcji, realizacja po MVP. Model (przelicznik 1/2/3 słoneczka wg liczby dni, paczki 10/30/100 za 4,99/11,99/29,99 zł, darmowy próg 5, ważność 12 mies.), koszt AI na słoneczko z `costs.md`, ryzyka (wzrost cen tokenów, nadużycia, zwroty), szkic US-K01–K07, pytania do prawnika P-L1–P-L7, wymagania dla architekta i security. Zakres MVP bez zmian.
- Artefakty: `docs/requirements/idea-kredyty-sloneczka.md`, `docs/open-questions.md` (sekcja „Kredyty „słoneczka" (AN-CREDITS)", OC1–OC10, oznaczone „po MVP")
- Decyzje: brak (propozycje domyślne do decyzji właściciela; bez ADR).
- Do zrobienia przez odbiorcę:
  - owner – decyzje OC1–OC10 (po MVP, nie blokują); w szczególności OC5 (relacja do modelu z `vision.md`) i OC6 (limit globalny 25/dobę nie do pogodzenia ze sprzedażą).
  - security – przy konsultacji prawnej SEC-30 dołączyć P-L1–P-L7 (analiza sekcja 4); po MVP ocena nowych danych osobowych (zakupy, księga salda, ślad darmowego progu) – analiza 5.2; rejestru nie zmieniałem.
  - architect – po MVP ADR „Kredyty i Google Play Billing" wg analizy 5.1 (produkty konsumowalne, weryfikacja serwerowa, księga salda, integracja z `generatePlan`, przegląd limitów).
- Pytania/blokady: brak.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: AN-CREDITS (194): review
- Zadania – nowe (po MVP, propozycje): (1) ARCH-CREDITS – ADR kredytów i Google Play Billing, architect, zależy od OC1–OC8; (2) SEC-CREDITS – model zagrożeń i rejestr danych dla kredytów, security, zależy od ARCH-CREDITS i P-L4; (3) dopisanie P-L1–P-L7 do pakietu prawnego SEC-30, security, bez zależności
- Pytania otwarte – nowe: OC1–OC10 (owner; OC4, OC8 także [PRAWNIK]; OC6 także architect) – już wpisane do `docs/open-questions.md`
- Pytania otwarte – zamknięte: brak
