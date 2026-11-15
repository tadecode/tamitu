# GH-001: Utworzenie repozytorium tadecode/tamitu i ochrona main

- Zgłasza (rola): orchestrator · Data: 2026-11-15 · Powiązane zadanie/PR: P3-01 / brak
- Typ: create-repo
- Status: open  (ustawia Steward)

## Potrzeba
Faza 3 (planowanie) i 4 (implementacja) wymagają repozytorium, CI i ochrony `main`. Obecnie istnieje tylko lokalny katalog bez commitów. Prośba: utworzyć prywatne repozytorium `tadecode/tamitu`, wypchnąć początkową zawartość farmy i dokumentów, włączyć ochronę `main` i CI wg `docs/github.md`.

## Szczegóły
- Repozytorium prywatne, domyślna gałąź `main`, squash merge.
- Wypchnąć: CLAUDE.md, README.md, `.claude/`, `.farm/`, `.github/`, `docs/` (bez sekretów; `.gitignore` obecny).
- Ochrona `main` i CI: `.farm/setup-github.ps1` (najpierw plan, potem `-Apply` po zgodzie właściciela).
- Nie dodawać sekretów w tej prośbie. Pliki konfiguracyjne Firebase (`google-services.json`) nie trafiają do repozytorium.

## Wpływ
Koszty: brak (GitHub). Bezpieczeństwo/RODO: dokumenty nie zawierają danych osobowych ani sekretów (do potwierdzenia skanem gitleaks przy pierwszym pushu). Ryzyko: niskie.

## Odpowiedź Stewarda
(oczekuje na sesję Stewarda: `.farm/steward/start-steward.ps1`)
