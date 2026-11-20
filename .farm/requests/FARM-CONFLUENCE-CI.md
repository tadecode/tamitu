# FARM-CONFLUENCE-CI: automatyczna publikacja docs/ do Confluence po merge'u

- Zgłasza (rola): właściciel (przekazane przez jego sesję pomocniczą) · Data: 2026-11-20 · Powiązane zadanie/PR: FARM-CONFLUENCE-IMPORT
- Typ: ci-change
- Status: approved  (Steward ustawia `done` po merge PR i udanym uruchomieniu próbnym)

## Potrzeba
Po każdym merge'u do `main` zmienione dokumenty z `docs/` mają publikować się do Confluence (przestrzeń Tamitu).
Publikator `.farm/confluence/publish.mjs` jest już na `main`; działa jednokierunkowo i nigdy nie usuwa stron.

## Szczegóły
1. Sekret repo `CONFLUENCE_TOKEN` (token Farm Bota, Menedżer poświadczeń → `gh secret set`, bez wyświetlania).
2. `.github/workflows/confluence.yml`: wyzwalacze `push` na `main` z `paths: docs/**` oraz `workflow_dispatch` (publikuje wszystko);
   `permissions: contents: read`; `concurrency: confluence` bez anulowania; `ubuntu-latest`, 15 min; checkout (`fetch-depth: 0`),
   Node 22, `npm ci --prefix .farm/confluence`.
3. Lista plików: dla `push` `git diff --name-only --diff-filter=AMR before sha`, dla `workflow_dispatch` (oraz pierwszego pushu
   z `before` = same zera) `git ls-files`; filtr `^docs/(requirements|adr|architecture|data|api|security|ux)/.*\.md$`;
   pusta lista = koniec bez błędu.
4. Bez wyzwalacza `pull_request`: sekret nie trafia do kodu z PR-ów.

## Wpływ
Koszty: jeden krótki job (~1 min) na merge z dokumentami, w darmowej puli (repo prywatne). · Bezpieczeństwo: token zwykłego
użytkownika (bez admina) jako sekret repo; workflow działa tylko na `main` i ręcznie. · Ryzyko: niskie.

## Odpowiedź Stewarda
2026-11-20 Steward: sekret `CONFLUENCE_TOKEN` ustawiony (`gh secret list` pokazuje nazwę, wartość poza czatem i plikami).
Wersje akcji jak w `ci.yml` (`checkout@v7`, `setup-node@v7`; tagi zweryfikowane przez `gh api`). Workflow na gałęzi
`chore/FARM-CONFLUENCE-CI`, PR otworzy bot. Po merge'u: jednorazowe `workflow_dispatch` na prośbę właściciela.
