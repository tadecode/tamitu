# GH-002: CI dla backendu, Dependabot i .gitignore wg ADR-0009

- Zgłasza (rola): orchestrator · Data: 2026-11-15 · Powiązane zadanie/PR: P3-02 / brak
- Typ: ci-change / dependabot / inne
- Status: done  (ustawia Steward)

## Potrzeba
ADR-0009 (układ A: Flutter w korzeniu, backend w `backend/`) wymaga rozszerzenia CI i konfiguracji repozytorium, zanim powstanie kod backendu (P3-02).

## Szczegóły
- `.github/workflows/ci.yml`: nowy job backendu z `working-directory: backend/functions` (`npm ci`, lint, `vitest`) oraz testy reguł Firestore w emulatorze; jak dotąd job musi być zgłaszany jako kontrola zwracająca sukces także gdy `backend/` jeszcze nie istnieje (pomijany, analogicznie do `flutter`), żeby nie blokować PR-ów. Joby Fluttera nie powinny uruchamiać się przy zmianach tylko w `backend/` (o ile da się to zrobić bez utraty wymaganej kontroli; do oceny Stewarda).
- Dependabot: ekosystemy `pub` (`/`) i `npm` (`/backend/functions`).
- `.gitignore`: `backend/functions/node_modules`, `.firebase`, `google-services.json`, `*.keystore`/`key.properties` (jeśli jeszcze nie ma).
- CODEOWNERS: objąć `/backend/`, `/lib/`, `/android/`, `firestore.rules`.
- Zmiana wymaganych kontroli `main` (jeśli nowy job ma być wymagany) – do decyzji właściciela.

## Wpływ
Koszty: minuty CI (publiczne repozytorium: bez kosztu). Bezpieczeństwo: brak sekretów; zmiany tylko w konfiguracji CI/repo. Ryzyko: niskie.

## Odpowiedź Stewarda
2026-11-15 Steward: część wykonana. PR #11 zmergowany: job `backend` (Node 22, lint, vitest, reguły Firestore w emulatorze; pomijany bez `backend/functions/package.json`), filtr Fluttera dla zmian tylko w `backend/`, Dependabot `npm` (`pub` już był). CODEOWNERS (`/backend/`, `/lib/`, `/android/`, `firestore.rules`) w PR `chore/ci-codeowners`, za zgodą właściciela.
Nie wykonane, wymaga właściciela/orchestratora (poza zakresem Stewarda): (1) `.gitignore`: `backend/functions/node_modules`, `.firebase`, `google-services.json` (`*.keystore`, `key.properties` już są); (2) dopisanie `'backend'` do listy kontroli w `.farm/setup-github.ps1` (linia 18); potem Steward uruchomi `-Apply`, by `backend` stał się wymaganą kontrolą `main` (zgoda właściciela jest).
2026-11-15 Steward (aktualizacja): punkty 1-2 wprowadzone w PR #18 (`185420c`): `.gitignore` dla Firebase i `backend` na liście kontroli w `setup-github.ps1`. Za zgodą właściciela w czacie uruchomiono `setup-github.ps1 -Apply`; zweryfikowano odczytem `gh api`: wymagane kontrole `main` = farm-guards, conventions, secrets, flutter, backend; strict, 1 zatwierdzenie, code owner, enforce_admins=false.
Status: done.
