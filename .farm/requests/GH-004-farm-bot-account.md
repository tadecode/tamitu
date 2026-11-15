# GH-004: Konto bota farmy do pushy i PR-ów (zatwierdzanie PR-ów przez właściciela)

- Zgłasza (rola): github-steward, na decyzję właściciela (opcja 1, rozmowa 2026-11-15) · Data: 2026-11-15 · Powiązane PR: #10-#19
- Typ: inne (tożsamości i uprawnienia)
- Status: approved  (ustawia Steward)

## Potrzeba
Wszystkie PR-y mają autora `tadecode` (także code ownera i admina), więc właściciel nie może ich
zatwierdzić i merguje przez admin bypass. Potrzebna osobna tożsamość dla farmy.

## Szczegóły
Opis w `docs/github-ops/farm-bot-account.md`. Skrót: konto bota z rolą Write, fine-grained token
(Contents + Pull requests), osobna konfiguracja `gh`; właściciel zatwierdza z `tadecode`.

Kroki:
1. Właściciel zakłada konto i podaje login (bez tokenów w czacie).
2. Steward zaprasza je do repo z rolą Write (zgoda właściciela w czacie) - **czeka**.
3. Właściciel/orchestrator aktualizuje `docs/github.md`, `.farm/steward/github-steward.md`,
   `.farm/new-worktree.ps1`, `.farm/steward/start-steward.ps1` (poza zakresem Stewarda).
4. Test: PR z konta bota zatwierdzony przez `tadecode`, merge bez admin bypassu.
5. Opcjonalnie później: `enforce_admins=true` (osobna zgoda).

## Wpływ
Koszty: brak (darmowe konto). Bezpieczeństwo: dochodzi jedna tożsamość z minimalnym zakresem;
RODO: adres e-mail konta bota nie jest danymi użytkowników aplikacji. Ryzyko: niskie.

## Odpowiedź Stewarda
2026-11-15 Steward: prośba zgodna z polityką. Przygotowano dokument i prośbę (PR `chore/ci-farm-bot-account`).
Wykonanie zaproszenia dopiero po podaniu loginu przez właściciela.
2026-11-15 Steward (aktualizacja): kroki 1-2 wykonane. Konto `tadecode-farm` zaproszone z rolą Write, zaproszenie zaakceptowane (zweryfikowane `gh api`: write, admin=false). Właściciel utworzył token i zalogował bota w osobnej konfiguracji `gh`. Krok 4 (test): PR z konta bota, zatwierdzenie przez `tadecode`, merge bez bypassu. Kroki 3 i 5 czekają.
