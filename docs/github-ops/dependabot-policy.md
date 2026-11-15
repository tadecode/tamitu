# Polityka Dependabota

Decyzja właściciela z 2026-11-15. Prowadzi GitHub Steward.

## Co robi Dependabot w tym repozytorium
- **Alerts i security updates:** włączone w ustawieniach repozytorium; alert w zakładce Security,
  PR z poprawką bezpieczeństwa otwierany od razu.
- **Version updates:** `.github/dependabot.yml`, cotygodniowo, ekosystemy `pub` (`/`),
  `gradle` (`/android`), `npm` (`/backend/functions`) i `github-actions` (`/`), etykieta `dependencies`.
  Dla `pub` i `gradle` PR-y pojawią się dopiero po powstaniu projektu Flutter, dla `npm` po powstaniu backendu.
- Gałęzie mają prefiks `dependabot/`. Kontrola `conventions` je dopuszcza (PR #5).
- Dependabot niczego sam nie merguje.

## Zwolnienie z raportów
PR-y Dependabota (gałąź `dependabot/...`) są **zawsze zwolnione** z raportu recenzenta
(`docs/reviews/PR-<nr>.md`) i raportu QA. Właściciel nie musi tego potwierdzać za każdym razem.

## Warunki merge, które nadal obowiązują
1. Wszystkie 5 wymaganych kontroli CI zielone (`farm-guards`, `conventions`, `secrets`, `flutter`, `backend`).
2. Zatwierdzenie w PR (`reviewDecision = APPROVED`): właściciela albo, w wąskiej klasie opisanej
   w sekcji „Auto-zatwierdzenie", `github-actions[bot]`. Steward nie zatwierdza za właściciela.
3. Gałąź aktualna względem `main` (`gh pr update-branch <nr> --rebase` lub `@dependabot rebase`).
4. Merge: `gh pr merge <nr> --squash --delete-branch`. Nigdy `--admin`.

## Auto-zatwierdzenie (GH-003)
Workflow `.github/workflows/dependabot-approve.yml` (`pull_request_target`, tylko `GITHUB_TOKEN`
z `pull-requests: write`, bez checkoutu kodu z PR, bez modelu i zewnętrznych akcji) zatwierdza PR
jako `github-actions[bot]`, gdy spełnione są **wszystkie** warunki:
- autor PR i wszystkich commitów to `dependabot[bot]`;
- zmienione są wyłącznie pliki zależności: `pubspec.yaml`, `pubspec.lock`, pliki Gradle w `android/`,
  `backend/functions/package.json` i `package-lock.json`;
- skok to patch lub minor (dla wersji 0.x tylko patch); wersja nierozpoznana w tytule = brak zatwierdzenia;
- zatwierdzenie dotyczy konkretnego commita (`commit_id`); nowy push = ponowna ocena.

Zawsze właściciel (workflow nie zatwierdza): ekosystem `github-actions` (zmiany w `.github/`),
skok wersji głównej, PR-y grupowe, PR z commitem kogoś innego, zmiany dotykające danych osobowych
lub uwierzytelniania. Zatwierdzenie nie omija 4 wymaganych kontroli; merge nadal robi Steward.
Wymaga ustawienia repo „Allow GitHub Actions to create and approve pull requests".

## Ignorowane aktualizacje (npm, /backend/functions)
- `typescript` >= 6.1.0: `typescript-eslint` 8.x wymaga `typescript <6.1` (PR #24 zamknięty, `ERESOLVE`). Zdjąć ignorowanie po wydaniu `typescript-eslint` ze wsparciem TS 7.
- `@types/node`, skoki wersji głównej: typy mają odpowiadać runtime Node (`engines.node` = 22; PR #23 podniósł do 26 przed zmianą ignorowania). Skok dopiero razem ze zmianą wersji Node w CI i `package.json`.
Zmiana listy: tylko PR do `.github/dependabot.yml` (zatwierdza właściciel).

## Ocena Stewarda przed merge
Steward ocenia każdy taki PR pod kątem kosztów i bezpieczeństwa: zakres zmiany, wielkość skoku
wersji, notatki wydania, wpływ na sekrety i uprawnienia workflow. Wpis w `docs/github-ops/log.md`.

## Wyjątki (zwolnienie nie obowiązuje)
Steward zatrzymuje się i pyta właściciela, gdy PR Dependabota:
- zmienia coś poza podbiciem wersji (nowe kroki, zmiana `permissions`, `secrets`, `pull_request_target`),
- podnosi zależność o skok główny z istotną zmianą działania (breaking change),
- zostaje zmodyfikowany przez kogoś innego niż Dependabot,
- dotyczy zależności aplikacji (`pub`, `gradle`) ze zmianą dotykającą danych osobowych, uwierzytelniania
  lub zgód. Wtedy potrzebny jest przegląd roli security.

Zmiana tej polityki wymaga zgody właściciela.
