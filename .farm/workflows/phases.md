# Fazy cyklu życia

| Faza | Role | Artefakty | Bramka |
|---|---|---|---|
| 1 Odkrywanie | analyst, security | `docs/requirements/`, rejestr danych osobowych (wstępny), ryzyka | **G1 Zakres** |
| 2 Projekt | architect, security (+ UX, DBA później) | `docs/architecture/`, `docs/adr/`, `docs/data/`, `docs/api/`, model zagrożeń | **G2 Architektura** |
| 3 Planowanie | orchestrator, analyst | `docs/backlog.md` z zadaniami, kolejność iteracji, definicje ukończenia | G3 (opcjonalna) |
| 4 Implementacja (pętla) | mobile-dev, qa, security | kod, testy, raporty QA | testy zielone + werdykt QA |
| 5 Wydanie | mobile-dev, qa, security (+ DevOps) | build, checklista wydania, notatki | **G5 Wydanie** |
| 6 Utrzymanie | wszyscy wg potrzeby | triage błędów, nowe wymagania | powrót do fazy 1/3 |

## Pętla implementacji (faza 4), dla każdego zadania

1. orchestrator wybiera zadanie i przypisuje właściciela.
2. mobile-dev: gałąź `feat/<id>`, kod + testy.
3. Po otwarciu PR: CI (`farm-guards`, `conventions`, `secrets`, `flutter`) musi być zielone.
4. reviewer: przegląd kodu z PR (bezpieczeństwo, wydajność, jakość) wg
   `.farm/review/`; raport `docs/reviews/PR-<nr>.md` i komentarz w PR.
   Ustalenia wagi „bloker" lub „wysoka" → wraca do kroku 2.
5. qa: weryfikacja kryteriów, raport. Odrzucone → wraca do kroku 2
   (maks. 2 razy, potem eskalacja).
6. security: przegląd, jeśli zadanie dotyka danych osobowych, sieci,
   uwierzytelniania, reklam lub płatności (pogłębia ustalenia recenzenta).
7. orchestrator: aktualizacja backlogu, statusu i dziennika; zapisuje prośbę
   o merge w `.farm/requests/` po spełnieniu definicji ukończenia.
8. github-steward (osobna sesja): merguje (`--squash`) dopiero gdy CI zielone,
   właściciel zatwierdził PR, raporty recenzenta i QA są w porządku.

## Zasady
- Do następnej fazy tylko po zatwierdzeniu bramki przez człowieka
  (dotyczy G1, G2, G5).
- Zmiana zakresu po G1 lub architektury po G2 = nowy przebieg bramki.
