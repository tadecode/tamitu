# 10:30  mobile-dev → orchestrator, reviewer, qa  |  TAM-19 (P3-06)

- Zrobione: plany zapisują się w zaszyfrowanej bazie konta (SQLCipher) i nie znikają po zamknięciu aplikacji.
  Etapy: (1) schemat v2 (`trips`, `plan_days`, `plan_items`, kaskada) z migracją v1→v2 i `SqlitePlanRepository`
  (zapis w jednej transakcji, lista od najnowszego, odczyt, usunięcie); (2) zapis automatyczny po EK-07 i EK-08
  z bazy (`/home/plans/:id`) ze snackbarem `planSavedSnack` (U4); (3) EK-04 zamiast tymczasowego ekranu startowego
  (szkielet po 300 ms, pusty stan z informacją U9, karty CMP-12, FAB, błąd z ponowieniem); (4) EK-08 → menu
  „Usuń plan” → EK-11 (ładowanie, błąd z „Spróbuj ponownie”/„Zamknij”) → EK-04 ze snackbarem; (5) utrata klucza:
  test ADR-0011 pkt 9 (plany znikają, zgoda AI „nie wyrażono”, EK-03 w wariancie „dane wyczyszczone”).
  Testy: 289 zielonych (`flutter test`), `flutter analyze` bez uwag. Bez urządzenia, bez płatnych wywołań.
- Artefakty: `lib/core/db/account_database.dart` (v2), `lib/features/plans/**` (domena, repozytorium, providery,
  `saved_plan_screen.dart`, `delete_plan_dialog.dart`), `lib/app/home_screen.dart` (EK-04), `lib/app/router.dart`,
  `lib/app/bootstrap.dart`, `lib/app/providers.dart`,
  `lib/features/plan_generation/presentation/{generation_screen,plan_screen}.dart`,
  `lib/features/plan_generation/domain/generated_plan.dart` (`promptVersion`), `lib/core/ui/app_icon.dart` (5 ikon),
  `lib/l10n/app_{pl,en}.arb`; testy: `test/features/plans/*`, `test/home_screen_test.dart`,
  `test/features/plan_generation/plan_flow_test.dart`, `test/features/session/restart_test.dart`,
  `test/core/db/account_database_test.dart`, `test/fakes/in_memory_plan_repository.dart`.
- Decyzje (bez ADR, w granicach modelu danych 2.2):
  - Jedna instancja `AccountDatabases` dla zgód i planów (każda baza konta otwierana raz na proces).
  - `prompt_version` z odpowiedzi `generatePlan`; brak w odpowiedzi → pusty tekst (kolumna `NOT NULL`).
    `requestId` nie jest zapisywany (nie ma go w modelu danych).
  - Lista bez automatycznego ponawiania (Riverpod 3 domyślnie ponawia błędy) – błąd odczytu pokazuje CMP-18, ponawia
    użytkownik. Inne błędy otwarcia bazy niż zły klucz nie kasują danych (ADR-0011 pkt 9) – to zostało z P3-04.
  - EK-08 bez danych w `extra` (np. po odtworzeniu procesu) czyta plan z bazy; brak planu lub błąd odczytu → CMP-18
    „Wróć do listy”.
  - Snackbar po usunięciu pokazuje EK-08 przez wspólny `ScaffoldMessenger` po przejściu do EK-04 (wyświetla się nad FAB).
- Rozmiar APK (ADR-0010 pkt 5): `flutter build apk --release --flavor prod --target-platform android-arm64
  --analyze-size` na tej gałęzi (2026-11-25). Build `prod` wymaga `google-services.json`, którego nie ma w repo ani
  lokalnie, więc do pomiaru wstawiłem tymczasowo plik zastępczy z fikcyjnymi wartościami (ignorowany przez git,
  usunięty po buildzie; niczego nie łączy z Firebase). Wyniki:
  - plik APK: 27 191 215 B (25,9 MiB); `libapp.so` (Dart AOT) 8 021 KB, `libflutter.so` 11 080 KB,
    `libsqlcipher.so` 5 138 KB;
  - łańcuch ikon w Dart AOT: `hugeicons` 6 KB + `flutter_svg` 9 KB + `vector_graphics` 36 KB +
    `vector_graphics_codec` 22 KB + `vector_graphics_compiler` 188 KB = **ok. 261 KB < próg 1,0 MB** (górne
    oszacowanie przyrostu; buildu „bez pakietu” nie robiłem). Decyzja ADR-0010 bez zmian;
  - porównanie z analizą z P3-04 (17.11, `apk-code-size-analysis_02.json` lokalnie): `libapp.so` 6 095 → 8 021 KB
    (+1,9 MB – głównie zadania od P3-04: TAM-101, Functions, App Check); `package:tamitu` 95 → 241 KB, w tym TAM-19
    (`package:drift` 34 → 46 KB). Natywne biblioteki bez zmian.
- Dane osobowe: bez nowej kategorii. Zapisywane pola to D4, D5 (w tym numer lotu – tylko lokalnie), D9, D15, D16, już
  w rejestrze z miejscem „Urządzenie”; `prompt_version` nie jest daną osobową. Rejestru nie zmieniałem.
- Do zrobienia przez odbiorcę: reviewer – przegląd PR; qa – EK-04, EK-08 (z bazy), EK-11 wg specyfikacji, w tym PL/EN,
  motywy, 200 %, TalkBack (karta jako jeden element), offline (lista i plan działają bez sieci), restart aplikacji.
- Pytania/blokady: dwa odstępstwa od specyfikacji, niżej (M-TAM19-1, M-TAM19-2).

## Dla orkiestratora (zadania i pytania)

- Zadania – status: TAM-19: review (PR #170 do `main`; draft zdjęty po etapie 5).
- Zadania – nowe:
  - **architect**: aneks do ADR-0010 z wynikiem pomiaru APK (liczby wyżej). Tytuł techniczny TAM-19 wskazuje raport
    w `docs/architecture/`, a mobile-dev nie ma tam uprawnień; liczby są w tym wpisie.
  - **mobile-dev** (przy zadaniu Ustawień, EK-12): ikona `settings-02` w pasku EK-04 – pominięta w TAM-19, bo
    EK-12 nie jest zaimplementowany ani `ux-ready` (status „do ponownego zatwierdzenia”).
  - **ux** (drobne): klucze `homeTitle` i `homeSubtitle` (tymczasowy ekran startowy) są już nieużywane; usunąć je
    przy najbliższej zmianie ARB albo zostawić – decyzja ux.
- Pytania otwarte – nowe:
  - **M-TAM19-1** (ux → owner): co widzi użytkownik, gdy plan się wygenerował, ale **zapis do bazy się nie udał**
    (np. brak miejsca)? Specyfikacje EK-07/EK-08 tego nie opisują. Tymczasowo: plan pokazany z pamięci (jak przed
    TAM-19), bez snackbara „zapisano” i bez menu „Usuń plan”; po wyjściu plan znika. Propozycja: dodać do EK-08
    stan „Nie udało się zapisać planu” (CMP-13 ostrzeżenie + „Spróbuj zapisać ponownie”) z tekstami ux.
  - **M-TAM19-2** (ux): EK-04 w specyfikacji ma `settings-02` → EK-12; do czasu EK-12 ikona nie jest pokazywana
    (patrz zadanie wyżej). Potwierdzić, że to akceptowalne w dev.
- Pytania otwarte – zamknięte: brak.
