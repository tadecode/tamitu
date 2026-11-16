# GH-006: CI flutter pomija build dla PR-ów z samą dokumentacją i plikami farmy

- Zgłasza (rola): właściciel (przez sesję budowy farmy) · Data: 2026-11-16 · Powiązane zadanie/PR: #34
- Typ: ci-change
- Status: open

## Potrzeba
Kontrola `flutter` (wymagana na `main`) pomija kroki tylko dla PR-ów zmieniających wyłącznie `backend/`.
PR z samymi dokumentami i plikami farmy (np. #34) i tak pobiera Fluttera, uruchamia testy i buduje APK
(ok. 3 min 40 s). Chcemy, żeby takie PR-y też pomijały kroki Fluttera, a kontrola nadal zgłaszała sukces.

## Szczegóły
Plik: `.github/workflows/ci.yml`, job `flutter`, krok `detect` („Czy to projekt Flutter i czy zmiana go dotyczy?").

Zamienić gałąź `elif` tak, żeby kroki były pomijane, gdy **każdy** zmieniony plik należy do zbioru:
`backend/`, `docs/`, `.farm/`, `.claude/` albo kończy się na `.md`.

```yaml
        run: |
          if [ ! -f pubspec.yaml ]; then
            echo "Brak pubspec.yaml - krok pominięty (szkielet jeszcze nie powstał)."
          elif [ -n "$BASE_SHA" ] && ! git diff --name-only "$BASE_SHA" HEAD | grep -Ev '^(backend/|docs/|\.farm/|\.claude/)|\.md$' | grep -q .; then
            echo "PR zmienia tylko backend/, dokumentację lub pliki farmy - testy Fluttera pominięte (kontrola nadal zgłasza sukces)."
          else
            echo "flutter=true" >> "$GITHUB_OUTPUT"
          fi
```

Warunki:
- **Nie** używać `paths:` / `paths-ignore:` w wyzwalaczu `on:`. Wymagana kontrola, która się nie uruchomi, zostaje
  „Expected" i blokuje PR na zawsze.
- Zmiany w `.github/`, `lib/`, `test/`, `android/`, `assets/`, `pubspec.*` i wszystkim innym nadal uruchamiają pełny przebieg.
- `push` na `main` (brak `BASE_SHA`) dalej uruchamia pełny przebieg.

Filtr sprawdzony lokalnie na przykładach:

| Zmienione pliki | Wynik |
|---|---|
| `docs/ux/a.md`, `.claude/agents/ux.md`, `.farm/hooks/test-guards.ps1` | pominięte |
| `backend/x.ts` | pominięte (jak dziś) |
| `README.md`, `CLAUDE.md` | pominięte |
| `lib/main.dart`, `docs/a.md` | pełny przebieg |
| `pubspec.yaml` / `.github/workflows/ci.yml` / `assets/logo.png` | pełny przebieg |

Gałąź: `chore/ci-gh-006-flutter-skip-docs`. PR otwiera bot (autor `tadecode-farm`), zatwierdza właściciel (CODEOWNERS `/.github/`).
Push zmiany w `.github/workflows/` wymaga tokenu z zakresem `workflow` (patrz uwaga przy GH-005).

## Wpływ
Koszty: mniej minut GitHub Actions (ok. 3–4 min na każdy PR z samą dokumentacją). · Bezpieczeństwo/RODO: bez zmian;
`farm-guards` i `secrets` nadal sprawdzają każdy PR. · Ryzyko: niskie; plik `.dart` lub zasób poza listą zawsze uruchamia pełny przebieg.

## Odpowiedź Stewarda
