# Polityka Dependabota

Decyzja właściciela z 2026-11-15. Prowadzi GitHub Steward.

## Co robi Dependabot w tym repozytorium
- **Alerts i security updates:** włączone w ustawieniach repozytorium; alert w zakładce Security,
  PR z poprawką bezpieczeństwa otwierany od razu.
- **Version updates:** `.github/dependabot.yml`, cotygodniowo, ekosystemy `pub` (`/`),
  `gradle` (`/android`) i `github-actions` (`/`), etykieta `dependencies`.
  Dla `pub` i `gradle` PR-y pojawią się dopiero po powstaniu projektu Flutter.
- Gałęzie mają prefiks `dependabot/`. Kontrola `conventions` je dopuszcza (PR #5).
- Dependabot niczego sam nie merguje.

## Zwolnienie z raportów
PR-y Dependabota (gałąź `dependabot/...`) są **zawsze zwolnione** z raportu recenzenta
(`docs/reviews/PR-<nr>.md`) i raportu QA. Właściciel nie musi tego potwierdzać za każdym razem.

## Warunki merge, które nadal obowiązują
1. Wszystkie 4 wymagane kontrole CI zielone (`farm-guards`, `conventions`, `secrets`, `flutter`).
2. Zatwierdzenie właściciela w PR (`reviewDecision = APPROVED`). Steward nie zatwierdza za właściciela.
3. Gałąź aktualna względem `main` (`gh pr update-branch <nr> --rebase` lub `@dependabot rebase`).
4. Merge: `gh pr merge <nr> --squash --delete-branch`. Nigdy `--admin`.

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
