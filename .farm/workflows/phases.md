# Fazy cyklu życia

| Faza | Role | Artefakty | Bramka |
|---|---|---|---|
| 1 Odkrywanie | analyst, security | `docs/requirements/`, rejestr danych osobowych (wstępny), ryzyka | **G1 Zakres** |
| 2 Projekt | architect, ux, dba, data-analyst, security | `docs/architecture/`, `docs/adr/`, `docs/data/` (model: architect; schemat, zapytania, migracje: dba), `docs/api/`, `docs/ux/` (marka, design system, layout, biblioteka komponentów, wzorce, przepływy, pierwsze makiety), `docs/analytics/` (plan pomiarów, zdarzenia), model zagrożeń | **G2 Architektura** |
| 3 Planowanie | orchestrator, analyst | `docs/backlog.md` z zadaniami, kolejność iteracji, definicje ukończenia | G3 (opcjonalna) |
| 4 Implementacja (pętla) | mobile-dev, qa, security | kod, testy, raporty QA | testy zielone + werdykt QA |
| 5 Wydanie | mobile-dev, qa, security, data-analyst (+ DevOps) | build, checklista wydania, notatki, raport kosztów i metryk pilota | **G5 Wydanie** |
| 6 Utrzymanie | wszyscy wg potrzeby | triage błędów, nowe wymagania | powrót do fazy 1/3 |

## Pętla implementacji (faza 4), dla każdego zadania

1. orchestrator wybiera zadanie i przypisuje właściciela.
1a. **Zadanie z interfejsem (UI) najpierw przechodzi przez ux.** ux składa ekran z biblioteki komponentów
   (`docs/ux/components/`) wg wzorców i zasad layoutu (`docs/ux/patterns.md`, `layout.md`) i pisze
   specyfikację `docs/ux/screens/<id>.md` (stany, dane, teksty, dostępność) wraz z makietą PL/EN
   `docs/ux/mockups/<id>.html`; architect sprawdza dane i koszt względem
   `docs/api/` i `docs/data/`; security przegląda ekrany zgód, uprawnień i prywatności. Po uzgodnieniu
   orchestrator oznacza ekran `ux-ready` w backlogu. Bez `ux-ready` zadanie UI nie idzie do mobile-dev.
   Zadania bez UI (backend, testy, CI) pomijają ten krok.
2. mobile-dev: gałąź `feat/<id>`, kod + testy.
3. Po otwarciu PR: CI (`farm-guards`, `conventions`, `secrets`, `flutter`) musi być zielone.
4. reviewer: przegląd kodu z PR (bezpieczeństwo, wydajność, jakość) wg
   `.farm/review/`; raport `docs/reviews/PR-<nr>.md` i komentarz w PR.
   Ustalenia wagi „bloker" lub „wysoka" → wraca do kroku 2.
5. qa: weryfikacja kryteriów, raport. Odrzucone → wraca do kroku 2
   (maks. 2 razy, potem eskalacja).
6. security: przegląd, jeśli zadanie dotyka danych osobowych, sieci,
   uwierzytelniania, reklam lub płatności (pogłębia ustalenia recenzenta).
7. orchestrator: po merge przenosi zgłoszenia ról (status zadań, nowe zadania, pytania – sekcja „Dla orkiestratora”
   w plikach przekazania) zbiorczo do `docs/backlog.md` i `docs/open-questions.md` osobnym małym PR-em,
   aktualizuje status; zapisuje prośbę o merge w `.farm/requests/` po spełnieniu definicji ukończenia.
   Role nie edytują backlogu ani pytań otwartych; każdy wpis dziennika to osobny plik (`handoff.md`).
8. github-steward (osobna sesja): merguje (`--squash`) dopiero gdy CI zielone,
   właściciel zatwierdził PR, raporty recenzenta i QA są w porządku.

## Zasady
- **Krok przeglądu (decyzja właściciela 2026-11-17):** każdy PR z kodem (Flutter, backend) przechodzi
  zielone CI → przegląd `reviewer` (raport `docs/reviews/PR-<nr>.md` + komentarz w PR) → poprawki autora
  przy werdykcie „zmiany wymagane” → zatwierdzenie i merge przez właściciela. Zadania z ekranami:
  dodatkowo `qa` weryfikuje kryteria akceptacji przed oznaczeniem `done`. PR-y z samą dokumentacją
  nie wymagają reviewer. Brak raportu reviewer = PR nie jest gotowy do merge.
- **Bramka etykiet (stan docelowy po GH-008 i FARM-007; do tego czasu etykiety nadaje ręcznie właściciel):**
  wymagany status check `review-gate` w ochronie `main`. PR zmieniający kod (`lib/`, `android/`, `backend/`, `test/`,
  `integration_test/`, `pubspec.*`) wymaga etykiety `review:ok`; PR z ekranami (`lib/features/**` lub etykieta `ui`)
  dodatkowo `qa:ok`; PR z samą dokumentacją pomija bramkę. `review:changes` / `qa:changes` blokują merge. Etykiety nadaje
  rola (`gh pr edit <nr> --add-label …`, konto bota) po komentarzu z raportem i sprawdzeniu, że head PR-a się nie zmienił;
  nowy push zdejmuje `*:ok` i wymaga ponownego przeglądu. Bramka jest proceduralna (to samo konto bota), więc nie zastępuje
  zatwierdzenia właściciela. Szczegóły: `.farm/requests/GH-008-review-qa-gate.md`, `FARM-007-reviewer-qa-tools.md`.
- **Nowa sesja reviewer/qa na każdy PR** (także na ponowny przegląd po poprawkach): czysty kontekst, poprzednie raporty
  z `docs/reviews/` i `docs/qa/`, nie z pamięci rozmowy.
- Do następnej fazy tylko po zatwierdzeniu bramki przez człowieka
  (dotyczy G1, G2, G5).
- **Wspólne pliki (decyzja właściciela 2026-11-17):** żeby PR-y nie kolidowały, dziennik to osobne pliki
  (`.farm/log/<data>/<HHMM>-<rola>-<zadanie>.md`), a `docs/backlog.md` i `docs/open-questions.md` zmienia tylko
  orkiestrator po merge (zgłoszenia w pliku przekazania). Okres przejściowy i szczegóły: `handoff.md`;
  zmiany uprawnień ról i `CLAUDE.md`: `.farm/requests/FARM-006-shared-files.md`.
- Zmiana zakresu po G1 lub architektury po G2 = nowy przebieg bramki.
