# GH-003: Automatyczne zatwierdzanie wąskiej klasy PR-ów Dependabota

- Zgłasza (rola): właściciel (decyzja w rozmowie, 2026-11-15) · Data: 2026-11-15 · Powiązane zadanie/PR: brak
- Typ: ci-change / dependabot
- Status: approved  (ustawia Steward)

## Potrzeba
Właściciel zatwierdza ręcznie każdy PR Dependabota. Zatwierdzanie ma przejąć deterministyczna reguła
(bez modelu), działająca jako osobna tożsamość `github-actions[bot]`. Steward nadal nie zatwierdza PR-ów
i nadal sam merguje po 4 zielonych kontrolach.

## Szczegóły
1. Nowy plik `.github/workflows/dependabot-approve.yml` (gotowa treść: `.farm/requests/attachments/GH-003-dependabot-approve.yml`),
   wprowadzany przez PR `chore/ci-dependabot-approve`; PR zatwierdza właściciel (ścieżka `.github/` w CODEOWNERS).
2. Ustawienie repo: Settings > Actions > General > "Allow GitHub Actions to create and approve pull requests" = włączone
   (zmiana ustawień: tylko za zgodą właściciela, wpis w `docs/github-ops/log.md`).
3. Aktualizacja `docs/github-ops/dependabot-policy.md`: sekcja "Auto-zatwierdzenie" opisująca regułę poniżej;
   zdanie "Steward nie zatwierdza za właściciela" zostaje.

Reguła (wszystkie warunki, inaczej PR czeka na właściciela):
- autor PR i wszystkich commitów: `dependabot[bot]`;
- zmienione tylko pliki zależności: `pubspec.yaml`, `pubspec.lock`, pliki Gradle w `android/`, `backend/functions/package*.json`;
- skok tylko patch lub minor (dla wersji 0.x tylko patch); wersja nierozpoznana w tytule = bez zatwierdzenia;
- zatwierdzenie dotyczy konkretnego commita (`commit_id`); nowy push = ponowna ocena.

Poza regułą (zawsze właściciel): ekosystem `github-actions` (zmiany w `.github/`, więc i CODEOWNERS),
skok wersji głównej, PR-y grupowe, każdy PR z commitem kogoś innego, dotykanie danych osobowych/uwierzytelniania.

## Wpływ
Koszty: kilka sekund CI na PR Dependabota (repo publiczne: bez kosztu). Bezpieczeństwo: brak sekretów i długożyjącego tokenu
(tylko `GITHUB_TOKEN` z `pull-requests: write`); workflow `pull_request_target` nie robi checkoutu kodu z PR i nie wykonuje
niczego z jego treści (tytuł i nazwy plików tylko porównywane regexem). Ryzyko: niskie. Zatwierdzenie nie omija 4 wymaganych kontroli.
Do sprawdzenia przez Stewarda po wdrożeniu: czy ochrona `main` liczy zatwierdzenie `github-actions[bot]` jako wymagane
(pliki zależności nie są w CODEOWNERS); test na następnym PR Dependabota dla `pub` lub `npm`.

## Odpowiedź Stewarda
2026-11-15 Steward: prośba zgodna z polityką (zatwierdza bot regułą, Steward nadal nie zatwierdza). Treść workflow zweryfikowana: tylko `GITHUB_TOKEN`, brak checkoutu i zewnętrznych akcji, tytuł/pliki tylko porównywane regexem, `github-actions` poza regułą. Ochrona `main` wymaga 1 zatwierdzenia + code owner; pliki zależności nie są w CODEOWNERS, więc zatwierdzenie bota powinno wystarczyć (do weryfikacji na realnym PR Dependabota).
Kroki: (1) PR `chore/ci-dependabot-approve` z workflow i aktualizacją `dependabot-policy.md` - czeka na zatwierdzenie właściciela; (2) ustawienie „Allow GitHub Actions to create and approve pull requests" (obecnie `false`) - dopiero za zgodą właściciela w czacie, bez niego workflow nie zatwierdzi; (3) test na następnym PR `pub`/`npm`.
Status: approved (w toku).
