# 17:00  architect → orchestrator  |  TAM-107

- Zrobione: nowy **ADR-0017** „Trasa w Google Maps bez lokalizacji w aplikacji (wariant C)” – zastępuje ADR-0007
  w części „lokalizacja” (decyzja właściciela 2026-11-25, Q1 = C; podstawa: raport QA TAM-24, PR #172). Zawiera
  wynik testu (wykonanie Aneksu A pkt 2 ADR-0007), budowę URL (`api=1`, `destination` = nazwa + miejscowość,
  `travelmode`, `origin` pominięty przy „Moja lokalizacja”, tekst przy noclegu/poprzednim punkcie), manifest
  (tylko `INTERNET`, `<queries>` dla `VIEW https`), brak `geolocator`, testy, zakres danych w linku (D8), wpływ na
  rejestr i Play. W ADR-0007 dopisany tylko status „zastąpiony przez ADR-0017 w części »lokalizacja«”.
  Odwołania do wariantu A zaktualizowane w `flows.md` (diagram sekcji 3), `overview.md`, `zewnetrzne-integracje.md`,
  `model-danych.md`, `przechowywanie-i-retencja.md`. Dokumenty historyczne (`uwagi-dla-orchestratora.md`,
  `przeglad-ekranow-p3-14c.md`) bez zmian.
- Artefakty: `docs/adr/0017-trasa-maps-bez-lokalizacji-w-aplikacji.md`, `docs/adr/0007-lokalizacja-dokladna-i-link-maps.md`,
  `docs/architecture/flows.md`, `docs/architecture/overview.md`, `docs/api/zewnetrzne-integracje.md`,
  `docs/data/model-danych.md`, `docs/data/przechowywanie-i-retencja.md`, ten wpis.
- Decyzje: ADR-0017 (wariant C). Bez kosztów, bez zmian w chmurze, kod bez zmian. `docs/ux/` i `docs/security/` bez zmian.
- Do zrobienia przez odbiorcę: reviewer – przegląd PR-a (tylko dokumenty); owner – merge.
- Pytania/blokady: brak.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-107: review (PR do `main`).
- Zadania – nowe:
  - **security** (po merge'u): `docs/security/personal-data-register.md` – usunąć D7 (Tamitu nie przetwarza
    lokalizacji; ADR-0017), D8 – zdjąć wzmiankę o współrzędnych, `origin` tylko tekst z planu; `threat-model.md` –
    T12 po stronie Tamitu nieaktualne, T16 bez `geolocator`; SEC-12 – nieaktualne; SEC-13 – bez uzasadnienia
    uprawnienia lokalizacji; `privacy-checklist.md` pkt 2 (tekst przed prośbą o lokalizację) – nieaktualny;
    Google Play Data Safety: **brak** deklaracji lokalizacji (przybliżonej i dokładnej) i brak uprawnień lokalizacji;
    polityka prywatności: link do Google Maps przekazuje Google cel, tryb i opcjonalnie nocleg/poprzedni punkt jako
    tekst; pozycję odczytują Mapy na podstawie zgody danej Mapom/przeglądarce; ślad w historii Google/przeglądarki.
  - **mobile-dev** (implementacja US-007, P3-07): wg ADR-0017 – dopisać `<queries>` `VIEW` + `https` w manifeście
    i test; test braku `geolocator` w `pubspec.lock`; komentarz/odwołanie w `test/android_manifest_test.dart` do ADR-0017.
  - **analyst**: US-007 i S6 – „Moja lokalizacja” bez uprawnienia w Tamitu (link bez `origin`).
  - UX (TAM-108, już w toku): EK-09 bez stanów odczytu pozycji, EK-10 do archiwum.
- Pytania otwarte – nowe: brak.
- Pytania otwarte – zamknięte: Q1 – C (właściciel 2026-11-25; ADR-0017). U11 – do zamknięcia przez UX w TAM-108
  (obowiązuje wariant C, bez ekranu prośby o lokalizację).
