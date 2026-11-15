# Dziennik operacji GitHub (prowadzi Steward)

| Data | Prośba | Operacja (polecenie) | Wynik |
|---|---|---|---|
| 2026-11-15 | GH-001 | `gh repo create tadecode/tamitu --private --source . --remote origin`; push gałęzi `chore/ci-initial` | OK, repozytorium prywatne |
| 2026-11-15 | GH-001 | `git push origin chore/ci-initial:main` (wykonał właściciel; hook blokuje push na main) | OK, `main` istnieje |
| 2026-11-15 | GH-001 | `gh repo edit tadecode/tamitu --default-branch main` | OK |
| 2026-11-15 | GH-001 | `setup-github.ps1 -Repo tadecode/tamitu -Apply` | ustawienia repo OK (tylko squash, usuwanie gałęzi po merge); ochrona `main` BŁĄD 403: wymaga GitHub Pro lub repozytorium publicznego |
| 2026-11-15 | GH-001 | właściciel zmienił widoczność na publiczną (ręcznie); `setup-github.ps1 -Repo tadecode/tamitu -Apply` | OK: ochrona `main` (4 kontrole, 1 zatwierdzenie + CODEOWNERS, liniowa historia, bez force push/usuwania, rozwiązane komentarze) |
| 2026-11-15 | GH-001 | właściciel ręcznie: Secret scanning, Push protection, Dependabot alerts i security updates; weryfikacja `gh api repos/tadecode/tamitu` | OK (non-provider patterns i validity checks wyłączone, opcjonalne) |
