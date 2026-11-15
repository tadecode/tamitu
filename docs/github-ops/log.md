# Dziennik operacji GitHub (prowadzi Steward)

| Data | Prośba | Operacja (polecenie) | Wynik |
|---|---|---|---|
| 2026-11-15 | GH-001 | `gh repo create tadecode/tamitu --private --source . --remote origin`; push gałęzi `chore/ci-initial` | OK, repozytorium prywatne |
| 2026-11-15 | GH-001 | `git push origin chore/ci-initial:main` (wykonał właściciel; hook blokuje push na main) | OK, `main` istnieje |
| 2026-11-15 | GH-001 | `gh repo edit tadecode/tamitu --default-branch main` | OK |
| 2026-11-15 | GH-001 | `setup-github.ps1 -Repo tadecode/tamitu -Apply` | ustawienia repo OK (tylko squash, usuwanie gałęzi po merge); ochrona `main` BŁĄD 403: wymaga GitHub Pro lub repozytorium publicznego |
| 2026-11-15 | GH-001 | właściciel zmienił widoczność na publiczną (ręcznie); `setup-github.ps1 -Repo tadecode/tamitu -Apply` | OK: ochrona `main` (4 kontrole, 1 zatwierdzenie + CODEOWNERS, liniowa historia, bez force push/usuwania, rozwiązane komentarze) |
| 2026-11-15 | GH-001 | właściciel ręcznie: Secret scanning, Push protection, Dependabot alerts i security updates; weryfikacja `gh api repos/tadecode/tamitu` | OK (non-provider patterns i validity checks wyłączone, opcjonalne) |
| 2026-11-15 | GH-001 / PR #3 | merge PR #3 wykonał właściciel (squash `33b36dc`); właściciel zwolnił PR #3 z raportu recenzenta i QA (PR tylko z logami) | OK |
| 2026-11-15 | FARM-001 | poprawka `test-guards.ps1` na main (PR #4); `gh pr update-branch 3 --rebase` | OK, `farm-guards` zielony |
| 2026-11-15 | PR #1, #2 | `gh pr comment 1/2 "@dependabot rebase"`; właściciel zwolnił #1 i #2 z raportu recenzenta i QA | rebase OK; `conventions` czerwony (nazwa gałęzi `dependabot/...`) |
| 2026-11-15 | inicjatywa Stewarda, zgoda właściciela | PR `chore/ci-allow-dependabot`: regex `conventions` dopuszcza `dependabot/...` | PR #5 zmergowany przez właściciela (`f10ee24`), zwolniony z raportów; `conventions` zielone na gałęziach `dependabot/...` |
| 2026-11-15 | PR #1 | `gh pr update-branch 1 --rebase`; `gh pr merge 1 --squash --delete-branch` (po 4 zielonych kontrolach i zatwierdzeniu właściciela) | OK, `d14e6b1`: `gitleaks-action` 2→3 |
| 2026-11-15 | PR #2 | `gh pr update-branch 2 --rebase` (dwukrotnie, po merge #1); `gh pr merge 2 --squash --delete-branch` | OK, `ca04e7e`: `actions/checkout` 4→7 |
| 2026-11-15 | decyzja właściciela | stałe zwolnienie PR-ów Dependabota z raportów recenzenta i QA; zapis w `docs/github-ops/dependabot-policy.md` (PR `chore/ci-dependabot-policy`) | otwarty |
| 2026-11-15 | GH-003 | PR `chore/ci-dependabot-approve`: workflow `dependabot-approve.yml` + sekcja „Auto-zatwierdzenie" w polityce Dependabota | PR otwarty, czeka na zatwierdzenie właściciela; ustawienie repo (create/approve PRs) jeszcze niezmienione |
| 2026-11-15 | GH-002 | PR `chore/ci-backend-dependabot`: job `backend` w ci.yml (Node 22, lint, vitest, reguły Firestore w emulatorze; pomijany bez `backend/functions/package.json`), filtr w jobie `flutter` (pomija testy przy zmianach tylko w `backend/`), Dependabot `npm` (`/backend/functions`) | PR otwarty; `.gitignore`, CODEOWNERS i wymagana kontrola `backend` czekają na decyzję właściciela |
| 2026-11-15 | GH-003 / PR #10 | merge PR #10 wykonał właściciel (`a97bdc3`), zwolniony z raportów recenzenta i QA; `gh api -X PUT repos/tadecode/tamitu/actions/permissions/workflow -F can_approve_pull_request_reviews=true` (zgoda właściciela w czacie) | OK, zweryfikowane odczytem: `can_approve_pull_request_reviews: true`, `default_workflow_permissions: read` |
| 2026-11-15 | GH-002 / PR #11 | merge PR #11 (job `backend`, filtr Fluttera, Dependabot `npm`), zwolniony z raportów | OK; kontrola `backend` jeszcze niewymagana (lista w `.farm/setup-github.ps1`, poza zakresem Stewarda) |
| 2026-11-15 | GH-002 | PR `chore/ci-codeowners`: CODEOWNERS `/backend/`, `/lib/`, `/android/`, `firestore.rules` (zgoda właściciela) | PR otwarty |
