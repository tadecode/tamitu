# Konto bota farmy (osobna tożsamość GitHub do pushy i PR-ów)

Status: propozycja do wdrożenia przez właściciela (decyzja: opcja 1, 2026-11-15).

## Problem
Wszystkie role farmy pushują i otwierają PR-y z konta `tadecode`, które jest też jedynym
code ownerem i adminem. GitHub nie pozwala zatwierdzić własnego PR-a, więc obecnie jedyna
droga to admin bypass (`enforce_admins=false`), przez co wymóg zatwierdzenia jest fikcją.

## Docelowy podział tożsamości
| Tożsamość | Do czego | Uprawnienia w repo |
|---|---|---|
| `tadecode` (właściciel) | zatwierdza PR-y, ręczne operacje wrażliwe, sesja Stewarda dla ustawień i merge | admin |
| konto bota farmy (nazwa do wyboru, np. `tadecode-farm`) | push gałęzi `feat/*`, `chore/*`, `fix/*` i otwieranie PR-ów przez wszystkie role | Write (bez admina) |
| `github-actions[bot]` | auto-zatwierdzanie wąskiej klasy PR-ów Dependabota (GH-003) | bez zmian |

Bot nie jest code ownerem, nie może zmergować do `main` (ochrona gałęzi: PR + zatwierdzenie
code ownera + 5 kontroli), nie ma dostępu do ustawień, sekretów ani Actions.

## Kroki właściciela (ręcznie, żadne wartości nie przechodzą przez czat)
1. Załóż drugie konto GitHub (osobny adres e-mail, 2FA włączone). Podaj Stewardowi sam login.
2. Steward zaprosi je do repo z rolą **Write** (po Twojej zgodzie w czacie).
3. Zaakceptuj zaproszenie z konta bota.
4. Utwórz dla bota **fine-grained personal access token** ograniczony do repo `tadecode/tamitu`,
   uprawnienia: Contents: Read and write, Pull requests: Read and write, Metadata: Read.
   Bez Administration, Actions, Secrets, Workflows. Krótki termin ważności (np. 90 dni).
5. Zaloguj bota w osobnym katalogu konfiguracji GitHub CLI (osobnym od konta właściciela),
   tokena wklejasz sam w terminalu. Sesje ról innych niż Steward uruchamiasz z tym katalogiem.
6. Ustaw dla sesji farmy `git config user.name "TadeCode Farm Bot"` i adres e-mail powiązany
   z kontem bota, żeby commity przypisały się do niego.

## Sesja Stewarda
Steward potrzebuje admina (ustawienia, merge), więc zostaje na `tadecode`. Jego własne PR-y
(`.github/`, `.farm/requests/`, logi) nadal miałyby autora `tadecode`. Do ustalenia przez właściciela:
- **A (zalecane):** Steward pushuje gałąź i otwiera PR kontem bota, a admina używa tylko do
  ustawień i merge'a. Wymaga zmiany w `.farm/steward/` (kontrakt zmienia właściciel).
- **B:** PR-y Stewarda są nadal z `tadecode` i zmerguje je właściciel admin bypassem (zmiany małe,
  w obszarze logów i próśb).

## Zmiany w repo wynikające z tej decyzji (poza zakresem Stewarda, do wykonania przez właściciela/orchestratora)
- `docs/github.md`: sekcja o tożsamościach i uwaga, że role pushują kontem bota.
- `.farm/steward/github-steward.md`: wariant A lub B oraz zasada, że nie zatwierdza PR-ów.
- `.farm/new-worktree.ps1`, `.farm/steward/start-steward.ps1`: wybór konta `gh` i `user.name`/`user.email` bota.
- Opcjonalnie po wdrożeniu: `enforce_admins=true` w `setup-github.ps1`, żeby admin bypass przestał
  działać. Steward uruchomi `-Apply` dopiero na osobną zgodę właściciela; przed tym upewnić się,
  że bot i zatwierdzanie działają, bo inaczej właściciel sam się zablokuje.

## Bezpieczeństwo
- Token bota ma minimalny zakres i termin ważności; wyciek pozwala najwyżej otworzyć PR lub wypchnąć gałąź,
  którą i tak zablokuje ochrona `main`.
- Nigdy: admin, Workflows, Secrets, Actions dla bota. Tokenów nie zapisujemy w repo, logach ani promptach.
- Zmiany w `.github/workflows/` nadal wymagają zatwierdzenia właściciela (CODEOWNERS `/.github/`).
