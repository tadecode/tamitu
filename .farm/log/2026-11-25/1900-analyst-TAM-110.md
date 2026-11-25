# 19:00  analyst → orchestrator, qa, mobile-dev  |  TAM-110 (P3-07-US007)

- Zrobione: wymagania trasy w Google Maps dostosowane do wariantu C (Q1 = C, ADR-0017) i EK-09 v0.4 (trzy starty).
  US-007 przepisana: „Moja lokalizacja” bez uprawnień w Tamitu (link bez `origin`), trzy starty, tryb zapamiętany,
  cel jako nazwa + miejscowość. S6 oznaczone jako zastąpione przez Q1 = C (scope, risks R12, open-questions).
  `screens-and-flows.md`: EK-10 wycofany, P6 pkt 1/3/4/5, wiersze EK-08, EK-09, EK-10, EK-16 w macierzy stanów,
  U11 zamknięte, kryterium mockupu 6.
- Artefakty: `docs/requirements/US-007-link-google-maps-trasa.md`, `docs/requirements/screens-and-flows.md`,
  `docs/requirements/scope.md`, `docs/requirements/risks.md`, `docs/open-questions.md` (wiersz S6), ten wpis.
- Decyzje: brak nowych (zapis decyzji właściciela Q1 = C i UX-TAM108-1). Bez kosztów. `docs/ux/`, `docs/adr/`,
  `docs/security/` bez zmian.
- Do zrobienia przez odbiorcę: QA – sprawdzać TAM-20 wg nowych AC1–AC8 US-007; reviewer – przegląd PR-a; owner – merge.
- Pytania/blokady: brak.

### Kryteria US-007 – mapa zmian
| Nowe | Treść w skrócie | Skąd |
|---|---|---|
| AC1 | trzy starty (Moja lokalizacja domyślnie przy każdym otwarciu; Poprzedni punkt dnia – nie przy pierwszym punkcie; Nocleg – gdy plan go ma; ukryte, nie nieaktywne); tryb zapamiętany (pierwszy raz Komunikacja), start nie; jedno dotknięcie | dawne AC1, zmienione |
| AC2 | „Moja lokalizacja” → link bez `origin`; brak uprawnień lokalizacji (test manifestu), brak prośby/EK-10, `pubspec.lock` bez `geolocator` | zastępuje dawne AC2, AC3, AC5, AC7 |
| AC3 | Nocleg / Poprzedni punkt → `origin` tekst z planu, nigdy współrzędne, nigdy pusty `origin=` | nowe (ADR-0017) |
| AC4 | parametry URL `api`, `destination`, `travelmode`, `origin`; kodowanie | dawne AC4 |
| AC5 | `destination` = nazwa + miejscowość + cel podróży, nigdy same współrzędne | nowe (test TAM-24); zastępuje dawne AC6 |
| AC6 | brak lokalizacji w tle w manifeście | dawne AC8 (szczególny przypadek AC2) |
| AC7 | bez aplikacji Map – przeglądarka | dawne AC9 |
| AC8 | `launchUrl` = false → komunikat `routeOpenError`, arkusz zostaje | nowe (ADR-0017, EK-09) |

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-110: review (PR do `main`); po merge'u done.
- Zadania – nowe: brak. Uwaga dla QA (TAM-20): numeracja AC w US-007 się zmieniła – mapa wyżej.
  Uwaga dla mobile-dev (TAM-20): `screens-and-flows.md` (EK-08, brak sieci) nie każe już blokować trasy bez internetu –
  zgodnie z EK-09 i ADR-0011 pkt 2 brak sieci obsługuje Google Maps.
- Pytania otwarte – nowe: brak.
- Pytania otwarte – zamknięte: U11 w `screens-and-flows.md` oznaczone jako zamknięte (w `docs/open-questions.md`
  było już zamknięte przez TAM-108). S6 – oznaczone jako zastąpione przez Q1 = C.
