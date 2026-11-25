# 14:40  mobile-dev → reviewer, qa  |  TAM-105 (P3-05-APP-UX-DEV)
- Zrobione: wdrożyłem w aplikacji trzy poprawki rozstrzygnięte przez UX w TAM-102 (EK-05 v0.2, EK-07 v0.2, CMP-06 v0.2).
  1. **Q4 (EK-05, data i godzina):** na telefonie (okno < 600 dp) pola „Data …” i „Godzina …” stoją zawsze jedno pod
     drugim, na pełną szerokość, przy każdej skali tekstu. Dwie kolumny tylko na oknach ≥ 600 dp i przy skali < 150%.
     Etykieta „Godzina przylotu” ma całą szerokość pola, więc nie jest ucinana.
  2. **Q5 (EK-05 po EK-07 i wybierakach):** przed EK-06/EK-07 formularz zdejmuje fokus z pól tekstowych (klawiatura się
     chowa i nie wraca po powrocie). Po powrocie (Przerwij, wstecz z `ai_busy`, błąd z CMP-13, odmowa zgody) fokus stoi na
     „Generuj plan”, a snackbar jest przy dolnej krawędzi ekranu. Wyjątek: `invalid_argument` z polem, wtedy fokus na tym
     polu. Wybieraki daty i godziny: przed otwarciem fokus przechodzi na pole wyboru, a po zamknięciu wraca na nie, bez
     klawiatury.
  3. **TAM101-2 (pasek EK-07):** kod już miał „Nowa podróż” na pasku i „Układamy plan…” w treści. Dodałem komentarz
     z odwołaniem do EK-07 v0.2 i test, który to pilnuje (ładowanie i `ai_busy`, PL i EN).
- Artefakty: `lib/features/trip_form/presentation/trip_form_screen.dart`, `lib/core/ui/components.dart` (`AppButton`
  przyjmuje `focusNode`), `lib/core/ui/tokens.dart` (`LayoutLimits.mediumWindowMinWidth = 600`),
  `lib/features/plan_generation/presentation/generation_screen.dart` (komentarz), test
  `test/features/trip_form/trip_form_ux_fixes_test.dart` (13 testów).
- Testy: `flutter analyze` bez uwag, `flutter test` 302/302 zielone. Testy Q5 sprawdziłem też na kodzie bez poprawki:
  5 z 6 pada, więc wykrywają błąd. Q4 testuję geometrią (360 i 411 dp przy 100%, 360 dp przy 200%: jedna kolumna na
  pełną szerokość; 800 dp przy 100%: dwie; 800 dp przy 150%: jedna). Samej etykiety nie da się zmierzyć w teście, bo
  czcionka testowa ma wszystkie znaki szerokie na 1 em.
- Decyzje (bez ADR): „liczba dni” w aplikacji to licznik −/+ (CMP-05), a nie wybierak w oknie, więc punkt specyfikacji
  o powrocie fokusu po wybieraku liczby dni nie ma tu zastosowania. Nie zmieniałem zachowania licznika.
- Do zrobienia przez odbiorcę: recenzja (komentarz w PR), potem QA ekranów EK-05 i EK-07 na telefonie, w tym przy
  powiększonym tekście i rozmiarze wyświetlania.
- Pytania/blokady: brak.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-105: review (PR do `main`, czeka na recenzję i QA)
- Zadania – nowe: brak. Ręczne kontrole TalkBack i jasnego motywu z dziennika TAM-102 (zadanie właściciela) obejmą też
  te poprawki: po „Przerwij” TalkBack powinien stać na „Generuj plan”.
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak (Q4, Q5 i TAM101-2 zamknął UX w TAM-102)
