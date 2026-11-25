# 18:30  mobile-dev → reviewer, qa, orchestrator  |  TAM-20 (P3-07)

- Zrobione: przycisk „Trasa” przy każdym punkcie planu w EK-08 (także dotknięcie całego punktu, CMP-20) otwiera
  arkusz EK-09 v0.4: start „Moja lokalizacja” (domyślny, link bez `origin`), „Poprzedni punkt dnia” (ukryty przy
  pierwszym punkcie dnia), „Nocleg” (ukryty bez noclegu); tryb Auto / Komunikacja / Pieszo, zapamiętany lokalnie
  (`shared_preferences.routeTravelMode`, pierwszy raz Komunikacja), start nie; „Otwórz w Google Maps” przez
  `url_launcher` (`externalApplication`), przy błędzie snackbar `routeOpenError` w arkuszu, arkusz zostaje.
  Link wg ADR-0017 (`Uri.https`, `destination` = nazwa, miejscowość, cel podróży; `origin` tylko tekst z planu).
  Manifest: `<queries>` `VIEW` + `https`; brak uprawnień lokalizacji i pakietów lokalizacji (testy pilnują).
- Artefakty: `lib/features/maps_link/domain/maps_link.dart`, `lib/features/maps_link/application/travel_mode.dart`,
  `lib/features/maps_link/presentation/route_sheet.dart`, `lib/features/plan_generation/presentation/plan_screen.dart`,
  `lib/app/bootstrap.dart`, `lib/core/ui/app_icon.dart`, `lib/l10n/app_{pl,en}.arb` (+ wygenerowane),
  `android/app/src/main/AndroidManifest.xml`, `test/features/maps_link/maps_link_test.dart`,
  `test/features/maps_link/route_sheet_test.dart`, `test/android_manifest_test.dart`, `test/helpers.dart`.
- Decyzje (drobne, w ramach specyfikacji):
  - w tekście miejsca pomijam puste i powtórzone części („Zamek, Kraków, Kraków” → „Zamek, Kraków”) – ten sam cel,
    krótszy link;
  - snackbar błędu wyświetlany wewnątrz arkusza (własny `ScaffoldMessenger`), bo snackbar strony byłby schowany pod
    arkuszem;
  - ikony: `route-02` dla „Trasa” (wcześniej w kodzie `route-01`, design-system mówi `route-02`), `bus-01` i
    `walking` dla trybów (design-system pkt 8);
  - nowe klucze poza tabelą EK-09: `commonCloseSheet` (CMP-16), `planRouteTo` (CMP-20, etykieta TalkBack),
    `routeOpensOtherApp` („otwiera inną aplikację” / „opens another app” – wskazówka TalkBack z sekcji „Dostępność”).
- Testy: `flutter analyze` bez uwag, `flutter test` 348/348 (bez urządzenia). Jednostkowe: 3 starty × 3 tryby, brak
  `origin` przy „Moja lokalizacja”, kodowanie `& # | % ( )` i polskich liter, długość URL. Widgetowe: PL/EN × jasny/ciemny,
  ukrywanie opcji, zapamiętany tryb i niezapamiętany start, błąd otwarcia i ponowienie, etykiety i wskazówka TalkBack,
  cele 48 dp (`androidTapTargetGuideline`), 200% (tryby jako lista, przewijanie).
- Do zrobienia przez odbiorcę: reviewer – przegląd PR; qa – weryfikacja na telefonie (trzy tryby, trzy starty,
  powrót z Map do arkusza, TalkBack: fokus na tytule, „1 z 3”).
- Pytania/blokady: brak.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-20: review (PR do `main`).
- Zadania – nowe: brak.
- Pytania otwarte – nowe: brak. Uwaga dla architekta (bez blokady): ADR-0017 zakłada URL < 2 048 znaków „z zapasem”;
  to prawda dla zwykłych nazw (test), ale nazwy złożone niemal wyłącznie z polskich liter przy limitach pól mogą
  przekroczyć 2 048 znaków po kodowaniu procentowym (każda litera = 6 znaków). Mapy na Androidzie przyjmują dłuższe
  linki przez intencję; do ewentualnego doprecyzowania w ADR.
- Pytania otwarte – zamknięte: brak.
- Nie sprawdzone automatycznie: kolejność fokusu TalkBack („fokus po otwarciu na tytule”) i odczyt „1 z 3” na
  prawdziwym TalkBack – do QA na telefonie.
