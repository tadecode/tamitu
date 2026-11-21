# 08:19  architect → orchestrator, mobile-dev, qa, security, owner  |  TAM-4 (ARCH-01)
- Zrobione: zapisano wyniki testu ARCH-01 (etap A, 2026-11-21) i decyzję właściciela: model startowy `gemini-3.1-flash-lite`, `thinkingLevel=MINIMAL`, punkt `eu`; etap B pominięty. Przeliczono koszty dla wybranego modelu (plan typowy ok. 0,015 PLN, maks. ok. 0,055 PLN; pułap typowy przy 25/dobę ok. 12 PLN/mies.). Spisano wymagania dla P3-05: liczba punktów na dzień (w tym ostatni dzień), obejście błędu 400 w `responseSchema` (uproszczony schemat dla modelu + pełna walidacja na serwerze), ponowienia, logowanie, testy.
- Artefakty: docs/architecture/arch-01-gemini-test.md (sekcja 6, nota w 4.3, sekcja 7), docs/adr/0001-model-ai-gemini-vertex.md (Aneks C), docs/architecture/costs.md (sekcja 0, 1, 6, 8, 10), docs/architecture/p3-05-wymagania-generowania.md (nowy), docs/api/posrednik-api.md („Gwarancje" – ostatni dzień jako propozycja), docs/api/schemas/generate-plan.response.schema.json (opis: nie wysyłać do Vertex wprost), docs/open-questions.md (O-TAM4-1..3)
- Decyzje: ADR-0001 Aneks C (zatwierdzony przez właściciela 2026-11-21) – model, MINIMAL, `eu` w dev i prod. Decyzje architekta w wymaganiach P3-05: próg dnia 1 i zakresy punktów liczy kod, nie model; schemat dla modelu bez zagnieżdżonych limitów liczności; bez „naprawy" odpowiedzi w kodzie w MVP; druga próba z listą błędów pierwszej. Koszt (zasada 10): spada względem klasy Flash, limity bez zmian.
- Do zrobienia przez odbiorcę:
  - mobile-dev (TAM-18, P3-05): implementacja wg `p3-05-wymagania-generowania.md`; konfiguracja `AI_MODEL_ID=gemini-3.1-flash-lite`, lokalizacja `eu`; reguła ostatniego dnia wg O-TAM4-1 (domyślnie 1 – górna granica tempa, łatwa do zmiany).
  - qa: pełna ewaluacja P3 z promptem produkcyjnym, najpierw 3.1 Flash-Lite; śledzić odsetek drugich prób.
  - security: SEC-15 (TAM-54) poz. 3 i 8 dla `gemini-3.1-flash-lite` na `eu`; `disableCache=true` w prod przed pierwszym wywołaniem w prod.
  - owner: O-TAM4-1 (ostatni dzień), O-TAM4-2 (zatwierdzenie Aneksu B), O-TAM4-3 (koszt z Billing, uwagi K3/K4).
- Pytania/blokady: brak blokad dla startu P3-05 (O-TAM4-1 ma wartość domyślną). Bez płatnych wywołań w tej sesji.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-4 (ARCH-01): review (po merge – done; O-TAM4-3 to tylko uzupełnienie dokumentacji)
- Zadania – nowe:
  - „P3-05: uproszczony `responseSchema` dla Vertex + pełny walidator serwerowy (zakresy punktów na dzień, ostatni dzień)" – mobile-dev; część TAM-18 lub podzadanie; zależy od: brak (O-TAM4-1 z wartością domyślną).
  - „Pełna ewaluacja modelu z promptem P3-05 (20 przypadków × PL/EN, ≥ 95%), najpierw `gemini-3.1-flash-lite`" – qa; zależy od: TAM-18 wdrożone do dev; koszt ok. 1,5 PLN za przebieg (dev, zgoda właściciela na płatne wywołania).
  - „Następca `gemini-3.1-flash-lite` (wycofanie ≥ 2027-05-07) – sprawdzić przed startem publicznym" – architect; zależy od: termin startu publicznego.
  - „`disableCache=true` w prod przed pierwszym wywołaniem Vertex w prod" – owner/security (SEC-17 B-1); zależy od: brak; jeśli już ujęte w SEC-31 – nie dublować.
- Pytania otwarte – nowe: O-TAM4-1 (liczba punktów w ostatnim dniu, owner), O-TAM4-2 (zatwierdzenie ADR-0001 Aneks B, owner – bramka „architektura"), O-TAM4-3 (koszt z Billing i uwagi K3/K4, owner) – już wpisane do `docs/open-questions.md` w tym PR-ze (okres przejściowy FARM-006).
- Pytania otwarte – zamknięte: brak
