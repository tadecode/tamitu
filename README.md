# Szablon farmy agentów

Jedna farma = jedna aplikacja. Skopiuj cały folder `template/` jako
repozytorium nowej aplikacji, uzupełnij `docs/vision.md` i uruchom Claude Code
w jego katalogu głównym. Role agentów są w `.claude/agents/`.

## Szybki start

1. Skopiuj szablon: `Copy-Item -Recurse template C:\Repository\<nazwa-aplikacji>`
2. `git init` w nowym katalogu.
3. Uzupełnij `docs/vision.md` (cel, odbiorcy, ograniczenia) i sekcję
   „Parametry farmy" w `CLAUDE.md`.
4. Uruchom Claude Code i napisz: „Przeczytaj `.claude/agents/orchestrator.md`
   i działaj jako orkiestrator farmy. Zacznij od fazy 1 (odkrywanie)."
   (Orkiestratorem jest główna sesja; pozostałe role to subagenci.)
5. Na każdej bramce (`.farm/workflows/gates.md`) agenci zatrzymują się
   i czekają na Twoją decyzję.

## Zabezpieczenia (granice agentów)

- **Zakres zapisu roli** – hook w pliku roli (`hooks:` we frontmatterze)
  uruchamia `.farm/hooks/guard-paths.ps1` z listą dozwolonych ścieżek.
  Zapis poza listą jest blokowany.
- **Ochrona uniwersalna** (`.claude/settings.json`, dotyczy też głównej sesji):
  agent nie edytuje `.claude/`, `.farm/hooks/`, `CLAUDE.md` ani plików
  z sekretami; `guard-bash.ps1` blokuje m.in. push na main, force push,
  `reset --hard`, `curl | bash`, odczyt `.env`.
- **Zmiana kontraktów przez właściciela:** uruchom Claude Code ze zmienną
  `FARM_MAINTENANCE=1` (PowerShell: `$env:FARM_MAINTENANCE='1'; claude`).
  Pliki z sekretami pozostają zablokowane także wtedy.
- **Samotest:** `powershell -NoProfile -ExecutionPolicy Bypass -File .farm/hooks/test-guards.ps1`
- **Zadania próbne ról:** `.farm/evals/trial-tasks.md` – po każdej zmianie
  kontraktu.
- Wymagany Windows + PowerShell. Skrypty `.ps1` muszą być zapisane z BOM
  (UTF-8 z BOM), inaczej PowerShell 5.1 psuje polskie znaki.

Ograniczenia: hooki widzą zapisy narzędziami Write/Edit; role z narzędziem
Bash (security, mobile-dev, qa) mogą w teorii zapisać plik poleceniem
powłoki. `guard-bash.ps1` to lista zakazów, nie pełna izolacja. Pełną
izolację dają dopiero ochrona gałęzi i CI na GitHubie oraz sandbox.

## Co jest w środku

| Ścieżka | Cel |
|---|---|
| `CLAUDE.md` | Zasady wspólne dla wszystkich agentów farmy |
| `.claude/agents/` | Role: orchestrator, analyst, architect, security, mobile-dev, reviewer, qa |
| `.farm/review/` | Checklisty recenzji (bezpieczeństwo, wydajność, jakość) i polityka narzędzi (Sonar opcjonalnie) |
| `docs/reviews/` | Raporty z przeglądów PR i propozycje do checklist |
| `.farm/workflows/` | Fazy, bramki, protokół przekazań |
| `.farm/status.md` | Bieżący stan iteracji (aktualizuje orkiestrator) |
| `.farm/log/` | Dziennik decyzji i przekazań |
| `docs/` | Pamięć farmy: wizja, wymagania, architektura, ADR, dane, security |
| `docs/_templates/` | Szablony: user story, ADR, rejestr danych osobowych |
| `docs/backlog.md` | Lista zadań ze statusami |
| `.github/` | CI, CODEOWNERS, szablony PR i zadań, Dependabot |
| `.farm/steward/` | GitHub Steward: kontrakt roli i skrypt startowy osobnej sesji (admin GitHuba) |
| `.farm/requests/` | Kolejka próśb do Stewarda (tworzenie repo, CI, sekrety, merge) |
| `docs/github-ops/` | Dziennik operacji Stewarda |
| `.farm/setup-github.ps1` | Ochrona gałęzi `main` (dry-run, `-Apply` stosuje) |
| `.farm/setup-local-git.ps1` | Lokalnie: git używa tylko `gh` (konto bota), nie Twojego Git Credential Managera |
| `docs/github.md` | Przepływ PR, kontrole CI, konto bota, ograniczenia planu |

## Role w tej wersji (rdzeń)

Orkiestrator, Analityk, Architekt, Security/Privacy, Mobile Developer,
Reviewer (recenzent kodu PR), QA.
Kolejne role (UX, DBA, DevOps, Reviewer, Writer) dodajemy po pilocie według
szablonu z `.farm/workflows/role-contract.md`.
