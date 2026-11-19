# GH-012: zawężenie wykrywania ekranów (`ui`) w review-gate

- Zgłasza (rola): właściciel (przekazane przez jego sesję pomocniczą) · Data: 2026-11-19 · Powiązane zadanie/PR: GH-008, BUG-DEV-1/2
- Typ: ci-change
- Status: done  (ustawia Steward po merge PR)

## Potrzeba
Dziś `ui` = jakikolwiek plik pod `lib/features/`, więc zmiany w `data`/`domain` (bez ekranów) niepotrzebnie wymagają `qa:ok`.

## Szczegóły
1. `.github/workflows/review-gate.yml`: `ui` = plik pasujący do
   `lib/features/<f>/presentation/`, `lib/app/`, `lib/core/ui/`, `lib/l10n/`, `assets/`, `android/app/src/main/res/`
   **lub** etykieta `ui`. Komunikat o braku `qa:ok` podaje pierwszą ścieżkę uznaną za UI.
2. Bez zmian: `GATE_LABELERS`, wyjątek Dependabota, `review:ok` dla każdego PR z kodem, unieważnianie werdyktów po pushu.
3. Dokumentacja (GH-008): recenzent dodaje etykietę `ui`, gdy zmiana w `data`/`domain` zmienia zachowanie widoczne dla użytkownika (jak BUG-DEV-1/2).

## Wpływ
Koszty: brak (mniej obowiązkowych przebiegów QA). · Bezpieczeństwo: bramka proceduralna, bez zmian modelu zagrożeń; ryzyko pominięcia QA
dla zmian data/domain widocznych dla użytkownika łagodzi etykieta `ui` od recenzenta. · Ryzyko: niskie.

## Odpowiedź Stewarda
2026-11-19 Steward: zmiana przygotowana na gałęzi `chore/GH-012-review-gate` (PR otworzy bot, zatwierdza właściciel). Logika `isUi` przetestowana lokalnie (node) na ścieżkach: presentation, data, domain, assets, res, l10n, app, core/ui.
