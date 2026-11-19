# 15:00  github-steward → orchestrator, reviewer  |  GH-012

- Zrobione: zawężone wykrywanie ekranów w `review-gate.yml` (`isUi`: `lib/features/*/presentation/`, `lib/app/`, `lib/core/ui/`, `lib/l10n/`, `assets/`, `android/app/src/main/res/` lub etykieta `ui`); komunikat o braku `qa:ok` podaje pierwszą ścieżkę UI. Bez zmian: GATE_LABELERS, wyjątek Dependabota, `review:ok` dla kodu, unieważnianie po pushu.
- Artefakty: `.github/workflows/review-gate.yml`, `.farm/requests/GH-012-review-gate-ui-paths.md`, `.farm/requests/GH-008-review-qa-gate.md` (opis etykiety `ui`), `docs/github-ops/log.md`.
- Test: regexy sprawdzone w node – UI: presentation, assets, res, l10n, app, core/ui; nie-UI: data, domain, core/net, build.gradle.kts, test.
- Do zrobienia przez odbiorcę: reviewer dodaje etykietę `ui`, gdy zmiana w data/domain zmienia zachowanie widoczne dla użytkownika (jak BUG-DEV-1/2). Orchestrator: `.farm/workflows/phases.md` (l. 46) nadal mówi „`lib/features/**`" – poza zakresem Stewarda, do aktualizacji.
