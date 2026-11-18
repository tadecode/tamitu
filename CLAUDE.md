# Farma agentów – zasady wspólne

Pracujesz w farmie agentów budującej **jedną aplikację**. Każdy agent ma
wąską rolę (`.claude/agents/`). Człowiek jest właścicielem produktu.

## Parametry farmy (uzupełnij)

- Aplikacja: Tamitu (planer podróży, produkt TadeCode)
- Platforma: Flutter, na start tylko Android (pakiet `pl.tadecode.tamitu`); Firebase, Google Cloud (UE)
- Repozytorium: tadecode/tamitu (prywatne; tworzy GitHub Steward)
- Dane osobowe (RODO): tak – obowiązuje `docs/security/`
- Język dokumentów: polski; kod, nazwy i komentarze techniczne: angielski

## Zasady obowiązujące wszystkich

1. **Pamięć jest w plikach.** Nie polegaj na historii rozmowy. Na starcie
   przeczytaj `.farm/status.md`, `docs/vision.md` i dokumenty swojej roli.
2. **Przekazanie = zapisany plik.** Wynik pracy zapisujesz w `docs/` lub
   w kodzie, nie tylko w odpowiedzi. Wpis o przekazaniu dodaj do
   `.farm/log/` wg `.farm/workflows/handoff.md`.
3. **Trzymaj się swojej roli.** Zmieniasz tylko katalogi z sekcji
   „Uprawnienia" swojego agenta. Potrzebujesz zmiany poza zakresem →
   zgłoś orkiestratorowi.
4. **Decyzje architektoniczne = ADR** w `docs/adr/`. Nie zmieniaj
   zatwierdzonego ADR po cichu; zaproponuj nowy, zastępujący.
5. **Bramki zatwierdza człowiek** (`.farm/workflows/gates.md`). Nie
   przechodź do kolejnej fazy bez jawnej zgody.
6. **Niejasność = pytanie.** Jeśli brakuje informacji, wpisz pytanie do
   `docs/open-questions.md` i eskaluj, zamiast zgadywać.
7. **Bezpieczeństwo i RODO.** Żadnych sekretów, kluczy i danych osobowych
   w repozytorium, logach ani promptach do modeli. Nowy rodzaj danych
   osobowych wymaga wpisu w `docs/security/personal-data-register.md`.
8. **Praca na gałęziach.** Kod trafia na gałąź `feat/<id-zadania>`; nigdy
   bezpośrednio na `main`. Commity małe i opisowe.
9. **Definicja ukończenia zadania:** kod + testy zielone + zaktualizowana
   dokumentacja + wpis w dzienniku (status zadania na tablicy Azure Boards zmienia orkiestrator).
10. **Koszty.** Wywołania modeli AI w aplikacji i w CI mają limity;
    każda zmiana zwiększająca koszt wymaga wzmianki w ADR lub zadaniu.
11. **GitHub.** Tworzenie repozytoriów, CI, sekrety, ustawienia i merge do `main`
    wykonuje wyłącznie agent GitHub Steward na podstawie prośby w
    `.farm/requests/`. Pozostali pushują gałęzie i otwierają PR-y; nie
    używają tokenów ani nie omijają blokad.
12. **Osobny worktree na zadanie.** Główny katalog repozytorium zostaje na
    `main` i służy tylko do odczytu. Każda sesja i każde zadanie pracuje we
    własnym worktree (`.farm/new-worktree.ps1 <zadanie>`, katalog
    `<repo>-wt\<zadanie>`) i nie przełącza gałęzi w cudzym katalogu. Pliki
    wspólne (`docs/open-questions.md`) edytuj małymi, osobnymi wpisami; zadania są w Azure Boards,
    żeby równoległe PR-y nie kolidowały. Testy na emulatorze, urządzeniu lub
    emulatorach Firebase uruchamiaj przez `.farm/test-lock.ps1` (kolejka na
    zasoby wspólne); zwykłe testy bez urządzenia nie potrzebują blokady.
