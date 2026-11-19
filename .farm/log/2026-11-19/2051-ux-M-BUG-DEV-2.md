# 20:51  ux → orchestrator, qa, owner (kopia: architect, mobile-dev)  |  M-BUG-DEV-2 (BUG-DEV-2, PR #102)

- Zrobione: rozstrzygnięta część UX pytania M-BUG-DEV-2. Anulowanie wyboru konta Google przy **pewnym** braku sieci (np. tryb samolotowy) pokazuje stan „Brak sieci” (CMP-13 `commonOfflineNotice`) zamiast snackbara „Logowanie anulowane.” – zgodnie z PR #102. Przy sieci albo przy niepewnym stanie sieci (Wi-Fi bez internetu, portal, limit czasu) zostaje „anulowano”. Tekst bez zmian, bez nowego klucza l10n.
- Artefakty: `docs/ux/screens/ek-02.md` (v0.4.1: stany „Anulowano u Google”, „Brak sieci”, nowa sekcja „Anulowanie bez sieci”), `docs/ux/screens/ek-16.md` (mapowanie brak sieci), `docs/ux/flows.md` (P1), `docs/open-questions.md` (sekcja „M-BUG-DEV-2 – odpowiedź UX”).
- Decyzje: CMP-13 przy anulowaniu offline jest właściwe – prawdziwa i pomocna informacja, nie błąd techniczny (US-001 AC2/AC3); koszt pomyłki asymetryczny (fałszywe „brak sieci” nieszkodliwe, fałszywe „anulowano” = BUG-DEV-2). Mechanizmu technicznego (DNS a ADR-0011 pkt 2) nie oceniam – to odpowiedź architekta.
- Do zrobienia przez odbiorcę:
  - owner: potwierdzić EK-02 v0.4.1 przy merge PR #102 (układ i teksty bez zmian).
  - qa: zmienione oczekiwanie **QA-PR-99 SIGN-12 #10** (wstecz w trybie samolotowym): EK-02, **CMP-13 ostrzeżenie „Brak połączenia z internetem. Ta funkcja wymaga sieci.”** nad przyciskiem, **brak** snackbara „Logowanie anulowane.”, brak „Nie udało się zalogować”, pole zgody zaznaczone, przycisk aktywny (nie w stanie ładowania dłużej niż ok. 2 s po zamknięciu okna), wpis tymczasowy usunięty. SIGN-12 #1–#9 (z siecią) – bez zmian: snackbar „anulowano”, bez CMP-13. SIGN-13 (brak sieci po wyborze konta) – CMP-13 jak wyżej. Po SIGN-12 #10 / SIGN-13 włączenie sieci i ponowna próba: komunikat znika; anulowanie z siecią → snackbar (SIGN-15).
  - architect: odpowiedź na część techniczną M-BUG-DEV-2 (osobna sesja).
- Pytania/blokady: brak.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: brak (BUG-DEV-2 bez zmian – czeka na architekta i QA na telefonie)
- Zadania – nowe: brak
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: M-BUG-DEV-2 – część UX: tak, CMP-13 przy anulowaniu z pewnym brakiem sieci; stan niepewny → „anulowano” (czeka na potwierdzenie właściciela; część architekta otwarta)
