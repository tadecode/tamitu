# FARM-002: Sesje farmy muszą działać jako konto bota, nie jako `tadecode`

- Zgłasza (rola): orchestrator · Data: 2026-11-16 · Powiązane: GH-004 (krok 3), PR #10-#28
- Typ: zmiana kontraktu farmy (pliki chronione; wykonuje właściciel z `FARM_MAINTENANCE=1`)
- Status: propozycja

## Problem
Konto bota `tadecode-farm` istnieje (GH-004, kroki 1-2), ale sesje farmy nadal pushują i otwierają
PR-y jako `tadecode`. Dowód: PR #28 ma autora `tadecode`. W sesji orkiestratora `git config user.name`
to „TadeCode Farm Bot", więc commity są podpisane botem, ale `gh pr create` i push używają
domyślnej konfiguracji `gh` / poświadczeń właściciela. Skutek: właściciel nie może zatwierdzać PR-ów
i merguje admin bypassem; krok 4 z GH-004 (test bez bypassu) nie może się odbyć.

Uwaga: hook `guard-bash` blokuje agentom odczyt konfiguracji konta (`gh auth status`), więc agent nie może
sam zweryfikować, jaka tożsamość jest aktywna. Weryfikację wykonuje właściciel.

## Proponowane zmiany (wszystko poza zakresem ról; właściciel)
1. **Uruchamianie sesji:** każdą sesję roli innej niż Steward startować ze zmienną `GH_CONFIG_DIR`
   wskazującą katalog konfiguracji bota (już utworzony w GH-004). Dotyczy też sesji z aplikacji
   desktopowej: zmienna musi być w środowisku, z którego startuje aplikacja, albo w skrypcie startowym.
2. **Poświadczenia gita (push):** upewnić się, że `git push` używa tokena bota, a nie Git Credential
   Managera właściciela: `gh auth setup-git` wykonane z `GH_CONFIG_DIR` bota albo wpis
   `credential.https://github.com.helper` ustawiony lokalnie dla repo. Bez tego PR może mieć
   autora-bota, a push dalej pójdzie jako `tadecode`.
3. **`.farm/new-worktree.ps1`:** po utworzeniu worktree ustawić lokalnie `user.name` i `user.email`
   bota (`git config --local`) oraz wypisać przypomnienie o `GH_CONFIG_DIR`. Skrypt nie zawiera tokenów.
4. **`.farm/steward/start-steward.ps1` i `github-steward.md`:** wybrać wariant A (zalecany w
   `docs/github-ops/farm-bot-account.md`): Steward pushuje gałąź i otwiera PR kontem bota, admina
   (`tadecode`) używa tylko do ustawień i merge. Dodać zasadę, że nie zatwierdza PR-ów.
5. **`docs/github.md`:** sekcja o tożsamościach (kto zatwierdza, kto otwiera, jak uruchamiać sesje).
6. **Hook (opcjonalnie):** kontrola przed `gh pr create`/`git push`, która odmawia, gdy aktywne konto to
   `tadecode` (fail-closed). Hook sam zna konfigurację, agent jej nie czyta.

## Weryfikacja (właściciel)
- W nowej sesji farmy `gh api user --jq .login` zwraca `tadecode-farm`.
- Testowy PR z bota: autor `tadecode-farm`, zatwierdzenie przez `tadecode`, merge bez admin bypassu (krok 4 GH-004).
- Dopiero potem, na osobną zgodę: `enforce_admins=true` (GH-004 krok 5).

## Wpływ
Koszty: brak. Bezpieczeństwo: poprawia rozdział uprawnień (bot nie ma admina ani sekretów). RODO: brak.
Ryzyko: niskie; przed `enforce_admins=true` upewnić się, że zatwierdzanie działa, żeby właściciel się nie zablokował.
