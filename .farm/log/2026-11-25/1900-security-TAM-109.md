# 19:00  security → orchestrator  |  TAM-109

- Zrobione: dokumenty security dostosowane do ADR-0017 (wariant C – Tamitu nie prosi o lokalizację i jej nie
  przetwarza). Rejestr v0.9: **D7 wycofany** (wiersz zostaje jako ślad, numer nieużywany ponownie), **D8**
  przepisany wg ADR-0017 pkt 5 (cel: nazwa + miejscowość + cel podróży, tryb, opcjonalnie start z planu jako tekst –
  nocleg albo poprzedni punkt dnia; bez współrzędnych; lit. b; ślad w historii Google/przeglądarki). Model zagrożeń:
  A8 i T12 nieaktualne po stronie Tamitu, T11 – tylko `INTERNET`, T16 – bez `geolocator`, **SEC-12 nieaktualne**,
  **SEC-13 bez lokalizacji**. Checklista: Data Safety **bez lokalizacji** (ani przybliżonej, ani dokładnej) i bez
  deklaracji uprawnień lokalizacji; pkt 2 (prośba o lokalizację) nieaktualny; szkic polityki prywatności (pkt 10,
  dokument security) – „nie zbieramy lokalizacji” + opis linku do Google Maps; podstawy prawne bez lokalizacji.
  S6 i Q1 oznaczone jako rozstrzygnięte; przegląd ADR pkt 7 z dopiskiem o decyzji.
- Artefakty: `docs/security/personal-data-register.md`, `docs/security/threat-model.md`,
  `docs/security/privacy-checklist.md`, `docs/security/open-questions-security.md`, `docs/security/przeglad-adr.md`,
  ten wpis. Raporty w `docs/security/reviews/` (np. P3-14c: P-7, U-8 o EK-09/EK-10) bez zmian – historyczne.
- Decyzje: brak nowych (wykonanie ADR-0017). Bez kosztów, kod bez zmian.
- Do zrobienia przez odbiorcę: reviewer – przegląd PR-a (tylko dokumenty); owner – merge.
- Pytania/blokady: brak.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-109: review (PR do `main`).
- Zadania – nowe:
  - **analyst** (poza US-007, które jest w TAM-110 – do dołączenia tam albo osobno): nadal opisują wariant A
    (dokładna lokalizacja, D7, EK-10): `docs/requirements/risks.md` R12 (ryzyko nieaktualne lub zmienione na
    „ślad po stronie Google Maps”), `docs/requirements/scope.md` (wiersze 13, 47, pkt 6 „ZMIANA (S6)”),
    `docs/requirements/screens-and-flows.md` (EK-10 w tabeli ekranów, przepływ 3, wzmianka „Q1 (dokładna
    lokalizacja, test C później)”).
  - **UX** (TAM-108 – jeśli jeszcze nie zrobione): `docs/ux/screens/ek-10.md` i `docs/ux/mockups/ek-10.html` do
    archiwum lub z oznaczeniem „wycofany (ADR-0017)”.
  - **Polityka prywatności (właściciel/[PRAWNIK])**: szkic jest w `privacy-checklist.md` pkt 10 (dokument security,
    już poprawiony). Opublikowana polityka (`tadecode.pl/tamitu/prywatnosc`) jeszcze nie istnieje; przy publikacji
    użyć nowej treści: Tamitu nie zbiera lokalizacji; link do Google Maps przekazuje Google cel, tryb i opcjonalnie
    nocleg/poprzedni punkt jako tekst; pozycję mogą odczytać Mapy lub przeglądarka na podstawie zgody danej im;
    ślad w historii konta Google/przeglądarki. Inne dokumenty ról nie zawierają tekstu polityki o lokalizacji.
  - **Google Play (właściciel, SEC-13, przed testami zamkniętymi)**: w Data Safety nie zaznaczać lokalizacji; do
    potwierdzenia [WŁAŚCICIEL/PRAWNIK], czy treść linku Maps (D8) wymaga ujawnienia jako udostępnienie danych
    podróży (rekomendacja: ocenić razem z kategorią danych podróży D6).
- Pytania otwarte – nowe: brak.
- Pytania otwarte – zamknięte: S6 (security) – nieaktualne po ADR-0017 (Tamitu nie przetwarza lokalizacji).
