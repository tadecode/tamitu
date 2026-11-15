# Brief: faza 1 (odkrywanie), bramka G1

Jesteś orkiestratorem farmy Tamitu (główna sesja). Poprowadź FAZĘ 1 i zatrzymaj się na bramce G1.

Najpierw przeczytaj: `CLAUDE.md`, `.claude/agents/orchestrator.md` (Twoja instrukcja roli; pozostałe role
wywołujesz jako subagentów), `.farm/workflows/phases.md`, `gates.md`, `handoff.md`, `docs/vision.md`,
`docs/open-questions.md`, `.farm/status.md`.

## Kroki
1. Zleć subagentowi `analyst` (brief wg formatu z `handoff.md`: cel, wejścia, wyjście, definicja ukończenia,
   ograniczenia): user stories dla MVP wg `docs/_templates/user-story.md` w `docs/requirements/`
   (kryteria akceptacji Given/When/Then), `docs/requirements/scope.md` (MVP / później / poza zakresem),
   `docs/requirements/risks.md` oraz propozycje odpowiedzi do pytań w `docs/open-questions.md`
   (nie zamykaj ich - decyduje właściciel). Wskaż, które historyjki dotykają danych osobowych.
2. Po zakończeniu analityka zleć subagentowi `security`: `docs/security/personal-data-register.md`
   (wg `docs/_templates/personal-data-register.md`), `docs/security/threat-model.md`,
   `docs/security/privacy-checklist.md` (RODO: zgody na reklamy i identyfikatory reklamowe, lokalizacja,
   dane wysyłane do modelu AI, prawo do usunięcia konta, polityka prywatności).
3. Zaktualizuj `.farm/status.md`, `docs/backlog.md` (zadania fazy 2) i dopisz wpisy przekazań do
   `.farm/log/2026-11-14.md`.
4. **TEST GRANIC (obowiązkowy, po zakończeniu pracy):** poproś `analyst` o utworzenie pliku `lib/test.txt`,
   a `security` o utworzenie `docs/adr/0001-test.md`. Oczekiwane: zapis ZABLOKOWANY przez hook (komunikat
   zaczyna się od `[farma] ZABLOKOWANO`). Nie omijaj blokad. Zapisz w `.farm/log/` dla każdej próby:
   zablokowano / nie zablokowano i dosłowny komunikat. Jeśli któraś próba się powiodła, natychmiast usuń
   plik i zgłoś to jako awarię zabezpieczeń.
5. Uruchom `git status --short` i sprawdź, że zmieniły się tylko dozwolone ścieżki (docs/requirements,
   docs/security, docs/backlog.md, docs/open-questions.md, .farm/).
6. Przygotuj raport bramki G1 (maks. ~15 linii: co zrobiono, decyzje, ryzyka, pytania do właściciela,
   wynik testu granic) w `.farm/log/` i pokaż go w odpowiedzi. ZATRZYMAJ SIĘ i czekaj na odpowiedź
   właściciela: `ZATWIERDZAM` / `POPRAWKI: ...` / `ODRZUCAM`. Nie przechodź do fazy 2.

## Ograniczenia
Nie dotykaj GitHuba, nie rób commitów, nie zmieniaj `.claude/`, `.farm/hooks/`, `.farm/review/`,
`.farm/steward/`, `.github/`, `CLAUDE.md`. Dokumenty po polsku. Nie wymyślaj faktów o produkcie: czego
brakuje w `docs/vision.md`, zapisz jako pytanie w `docs/open-questions.md`.

Gotowe, gdy raport G1 jest pokazany i sesja czeka na decyzję.
