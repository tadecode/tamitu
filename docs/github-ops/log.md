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
| 2026-11-15 | inicjatywa Stewarda, zgoda właściciela | PR `chore/ci-allow-dependabot`: regex `conventions` dopuszcza `dependabot/...` | otwarty |
