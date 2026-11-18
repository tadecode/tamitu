# 15:30  steward → owner  |  GH-009
- Zrobione: utworzone środowisko `prod` (tylko gałąź `main`). Sekrety dev obecne (nazwy sprawdzone). Zmiana `ci.yml`: zapis `google-services.json` z sekretu dev i build `--flavor dev` bez flagi; bez sekretu build jak dotąd z flagą (GH-011). Składnia nie była uruchamiana w CI przed PR.
- Artefakty: .github/workflows/ci.yml, .farm/requests/GH-009-ci-firebase-config-secrets.md, docs/github-ops/log.md
- Decyzje: brak własnych; środowisko `prod` bez wymaganych recenzentów (brak odpowiedzi właściciela, do ewentualnej zmiany przy GH-010).
- Do zrobienia przez odbiorcę:
  - owner: otworzyć PR `chore/ci-gh-009-firebase-secrets` z konta bota i zatwierdzić; ustawić `GOOGLE_SERVICES_JSON_PROD` (`--env prod`); zdecydować o `.gitleaks.toml`
- Pytania/blokady: brak

## Dla orkiestratora (zadania i pytania)
- Zadania – status: brak
- Zadania – nowe: brak
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak
