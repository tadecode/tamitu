# 21:00  mobile-dev → reviewer, qa, orchestrator  |  TAM-111 (A11Y-APPBUTTON)

- Zrobione: TalkBack może nacisnąć wspólne przyciski i linki, które miały `Semantics(excludeSemantics: true)`
  bez `onTap` (błąd z QA PR #178). Ten sam wzorzec co w PR #178: `onTap` + `container: true` w `Semantics`.
  Naprawione miejsca:
  1. `AppButton` (`lib/core/ui/components.dart`) – wszystkie warianty (filled, tonal, outlined): `onTap` tylko
     gdy przycisk aktywny i nie w trakcie akcji. Obejmuje wszystkie użycia: `welcomeSignIn` (EK-02),
     `tripFormGenerate` (EK-05), `reconsentAccept` (EK-03), `aiConsentAgree` / `aiConsentDisagree` (EK-06),
     `homeNewTrip`, `planListRetry`, `aiBusyTryNow`, `aiBusyBack`, `generationCancel` (EK-07), `planBackToList`,
     `gateRetry`, przycisk w `update_app_view.dart`.
  2. `ConsentCheckbox` – osobny przycisk linku „Przeczytaj Politykę prywatności” (EK-02).
  3. `reconsent_screen.dart` – link do polityki nad zgodą (EK-03).
  4. `ai_consent_screen.dart` – link „Szczegóły w Polityce prywatności” (EK-06; tekst z linkiem w treści, bez
     akcji dla TalkBack).
  Sprawdzone i bez zmian (nie są klikalne albo już mają `onTap`): `PlanCard` (home), uchwyt arkusza i
  „Otwórz w Google Maps” (EK-09), „Trasa” (EK-08), tekst w wierszu zgody (`MergeSemantics` z `InkWell`),
  odliczanie EK-07 (tylko tekst), `ExcludeSemantics` na etykietach i dekoracjach.
- Artefakty: `lib/core/ui/components.dart`, `lib/features/consent/presentation/{reconsent,ai_consent}_screen.dart`,
  `test/core/ui/button_semantics_test.dart` (nowy), `test/helpers.dart` (`hasSemanticsTap`, `semanticsTap`),
  testy ekranów: `welcome_screen_test.dart`, `reconsent_screen_test.dart`, `ai_consent_screen_test.dart`,
  `trip_form_ux_fixes_test.dart`.
- Testy: `flutter analyze` bez uwag, `flutter test` 363/363 (bez urządzenia). `AppButton` × 3 warianty: aktywny
  ma akcję tap i akcja naciska przycisk; wyłączony i w trakcie akcji – brak akcji, etykieta z powodem /
  „w trakcie”. Na ekranach akcja semantyczna loguje (EK-02 → EK-04), otwiera politykę (EK-03, EK-06),
  „Nie zgadzam się” zamyka EK-06, „Generuj plan” otwiera EK-07. Nowe testy `AppButton` i linku padają na kodzie
  sprzed poprawki (4 z 11; sprawdzone), więc testują właściwą rzecz.
- `labeledTapTargetGuideline`: przechodzi i teraz z właściwego powodu. Wytyczna sprawdza tylko węzły z akcją tap;
  przed poprawką `AppButton` nie miał akcji, więc był pomijany i wytyczna przechodziła „na pusto”. Teraz węzeł ma
  akcję i etykietę. Test kontrolny pokazuje, że wytyczna odrzuca węzeł z akcją tap bez etykiety.
- Do zrobienia przez odbiorcę: reviewer – przegląd PR; qa – na telefonie `uiautomator dump`: „Zaloguj przez
  Google”, „Generuj plan” i linki do polityki mają `clickable=true`; TalkBack aktywuje je podwójnym dotknięciem;
  wyłączony „Zaloguj przez Google” czyta powód i nie reaguje.
- Pytania/blokady: brak.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-111: review (PR do `main`).
- Zadania – nowe: brak.
- Pytania otwarte – nowe: brak.
- Pytania otwarte – zamknięte: brak.
- Nie sprawdzone automatycznie: zachowanie na prawdziwym TalkBack i `clickable` w `uiautomator dump` – do QA na
  telefonie.
