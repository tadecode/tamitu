# GH-007: wyłączyć wymóg „branches up to date” na main

- Zgłasza (rola): orchestrator (decyzja właściciela) · Data: 2026-11-17 · Powiązane zadanie/PR: chore/conflicts, #41–#49
- Typ: branch-protection
- Status: done  (ustawia Steward)

## Potrzeba
Ochrona `main` wymaga, by gałąź PR była aktualna z `main` (strict). Po każdym merge wszystkie pozostałe PR-y wchodzą w stan BEHIND
i trzeba je aktualizować (merge/rebase) oraz czekać na ponowne CI, co przy równoległych sesjach daje kaskadę aktualizacji
i dodatkowych konfliktów. Właściciel zgodził się 2026-11-17 na wyłączenie tego wymogu.

## Szczegóły
Zmiana w ochronie gałęzi `main` (repozytorium tadecode/tamitu):
- wyłączyć „Require branches to be up to date before merging” (`required_status_checks.strict = false`),
- **zostawić bez zmian:** listę wymaganych kontroli (`farm-guards`, `conventions`, `secrets`, `flutter`, `backend`), wymagane zatwierdzenie
  właściciela, wymóg przeglądu CODEOWNERS, blokadę pushu na `main` i pozostałe ustawienia.

Alternatywa (jeśli plan GitHub na to pozwala): kolejka scalania (merge queue) – testuje PR na świeżym `main` bez ręcznych aktualizacji;
wymaga wyzwalacza `merge_group` w `.github/workflows/ci.yml` i planu z tą funkcją dla prywatnych repozytoriów. Steward sprawdza dostępność;
jeśli plan nie pozwala, wystarczy samo wyłączenie strict.

## Wpływ
Koszty: mniej minut Actions (brak ponownych przebiegów CI po aktualizacji gałęzi). · Bezpieczeństwo/RODO: bez zmian; `secrets` i `farm-guards` dalej
działają na każdym PR. · Ryzyko: dwa PR-y zielone osobno mogą po scaleniu razem złamać `main` (konflikt semantyczny). Łagodzenie: PR-y są rozłączne
(osobne worktree i pliki, dziennik w osobnych plikach), CI uruchamia się na każdym PR i na `push` do `main`, więc awaria `main` jest widoczna od razu;
poprawka lub revert osobnym PR-em. Ryzyko niskie dla obecnej skali.

## Odpowiedź Stewarda
2026-11-18 Steward: wykonane wcześniej, zweryfikowane odczytem: `gh api repos/tadecode/tamitu/branches/main/protection` zwraca `strict=false`, kontrole bez zmian (`farm-guards`, `conventions`, `secrets`, `flutter`, `backend`). Merge queue nie wdrażana (wystarczy wyłączenie strict, wg prośby).
