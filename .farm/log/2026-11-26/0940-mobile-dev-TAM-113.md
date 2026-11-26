# 09:40  mobile-dev → reviewer, qa, orchestrator  |  TAM-113 (P3-06-SAVEFAIL-DEV)

- Zrobione: EK-08 v0.2, stan „Plan nie jest zapisany”. Gdy po EK-07 zapis planu w telefonie się nie uda,
  użytkownik nie widzi już planu „po cichu”. Widzi ostrzeżenie CMP-13 (wariant „Błąd”) nad komunikatem o AI
  i przycisk „Spróbuj zapisać ponownie”. Menu „Usuń plan” i snackbara „zapisano” nie ma. Plan działa normalnie
  (zakładki, „Trasa” → EK-09 bez dialogu).
  1. **Rozpoznanie braku miejsca** (`isOutOfStorage`, `sqlite_plan_repository.dart`): SQLITE_FULL (kod 13;
     VFS SQLite na Androidzie zgłasza zapis z ENOSPC jako SQLITE_FULL) albo `FileSystemException` z ENOSPC
     (28), także w opakowaniach drift (`CouldNotRollBackException`, `DriftWrappedException`). Repozytorium
     rzuca `PlanStorageException(PlanStorageFailure.noSpace | other)`. Sprawdzane są tylko kody, nigdy treść
     komunikatu, bo mogłaby cytować plan. `noSpace` → `planNotSavedStorageBody`, reszta → `planNotSavedBody`.
  2. **Ponowienie**: ten sam zapis (jedna transakcja). W trakcie: wskaźnik i „Zapisywanie…”, przycisk
     nieaktywny i bez akcji tap. Po sukcesie: zwykły EK-08 (menu, `planSavedSnack` z limitem, wstecz bez
     dialogu, plan na liście EK-04). Po błędzie: ostrzeżenie zostaje, tekst zgodny z nową przyczyną, snackbar
     `planSaveFailedAgainSnack`. Bez ponowień w tle i bez limitu prób.
  3. **Wstecz** (strzałka, systemowe, przewidywany powrót przez `PopScope`) → CMP-15 `alert-02`, „Anuluj” /
     „Wyjdź bez zapisu” (kolor `error`). Dotknięcie poza dialogiem i wstecz = „Anuluj”. Wstecz w trakcie
     zapisu czeka na wynik: po sukcesie wychodzi od razu, po błędzie pokazuje dialog.
  4. **Dostępność**: tytuł i treść ostrzeżenia tworzą jeden element w regionie live, więc tekst jest ogłaszany
     przy wejściu i przy zmianie przyczyny. Przycisk to osobny węzeł z akcją tap (wzorzec TAM-111) i celem
     48 dp. Przycisk ma kolor `onErrorContainer` (para kolorów z CMP-13 „Błąd”, bez nowych par).
- Artefakty: `lib/features/plans/presentation/unsaved_plan_screen.dart` (nowy), `lib/features/plans/domain/saved_plan.dart`,
  `lib/features/plans/data/sqlite_plan_repository.dart`, `lib/features/plans/presentation/saved_plan_screen.dart`
  (snackbar „zapisano” i usuwanie wydzielone do wspólnych funkcji), `lib/features/plan_generation/presentation/{generation,plan}_screen.dart`,
  `lib/app/router.dart` (`/home/plan` z `extra` = `UnsavedPlan`), `lib/core/ui/components.dart` (`Notice.action`),
  ARB PL/EN (9 kluczy dokładnie ze specyfikacji), testy: `test/features/plans/unsaved_plan_screen_test.dart` (nowy),
  `sqlite_plan_repository_test.dart`, `plan_flow_test.dart`, `test/fakes/in_memory_plan_repository.dart`.
- Testy: `flutter analyze` bez uwag, `dart format` bez zmian, `flutter test` 390/390 (bez urządzenia).
  Testy widgetowe obejmują: brak miejsca, inny błąd (PL/EN, jasny i ciemny motyw), ponowienie zakończone
  sukcesem i błędem (z zmianą tekstu), dialog (Anuluj, wstecz, poza dialogiem, strzałka, Wyjdź → EK-04),
  wstecz w trakcie zapisu (sukces i błąd), `hasSemanticsTap` dla przycisku i obu przycisków dialogu,
  brak akcji w trakcie zapisu, region live, wytyczne celów dotyku, tekst 200%, pełny przepływ EK-05 → EK-07 →
  EK-08 dla obu przyczyn. Test repozytorium na prawdziwej bazie SQLCipher: pełna baza (`PRAGMA max_page_count`)
  daje `noSpace` i zero zapisanych części, a po zwolnieniu miejsca ten sam zapis przechodzi.
- Decyzje: bez ADR.
  1. Po udanym ponowieniu ekran zostaje ten sam (adres `/home/plan`), więc zakładka dnia i przewinięcie się
     nie gubią. Plan ma już identyfikator, menu i usuwanie (EK-11).
  2. W `Notice` z przyciskiem region live jest na węźle tytułu i treści, a nie na całej karcie. Notice bez
     przycisku zachowuje się jak wcześniej.
- Do zrobienia przez odbiorcę: reviewer – przegląd PR. qa – na telefonie: wypełnić pamięć (np. duży plik
  `adb shell fallocate` albo emulator z małą partycją danych), wygenerować plan i sprawdzić tekst o braku
  miejsca, ponowienie po zwolnieniu miejsca, dialog przy wstecz i przy geście przewidywanego powrotu,
  TalkBack (ogłoszenie, podwójne dotknięcie przycisku, „Zapisywanie…”), oba motywy, 200%.
- Pytania/blokady: brak.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-113: review (PR do `main`).
- Zadania – nowe: brak.
- Pytania otwarte – nowe: brak.
- Pytania otwarte – zamknięte: brak (M-TAM19-1 zamknięte projektem EK-08 v0.2 i tym PR-em).
- Nie sprawdzone automatycznie, do QA na telefonie:
  - Przeniesienie fokusu TalkBack z ostrzeżenia na tytuł paska po udanym zapisie. Flutter nie ma API do
    przesuwania fokusu dostępności. Ostrzeżenie znika, a TalkBack sam wybiera kolejny element.
  - Prawdziwy pełny dysk na Androidzie (w testach symulowany przez `max_page_count`).
  - Etykieta w trakcie zapisu to „Zapisywanie…” (`planSaving`), a nie „Zapisywanie, trwa…”. Specyfikacja nie
    podaje osobnego klucza dla tej etykiety. Jeśli UX chce innego brzmienia, potrzebny jest nowy klucz.
