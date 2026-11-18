# GH-008: bramka przeglądu i QA jako wymagany status check na main

- Zgłasza (rola): orchestrator (decyzja właściciela 2026-11-17) · Data: 2026-11-17 · Powiązane zadanie/PR: #57, #58, #59 (incydent), FARM-007
- Typ: ci-change + branch-protection + labels
- Status: approved  (ustawia Steward)

## Potrzeba
PR #57 (kod P3-04) został zmergowany mimo werdyktu „zmiany wymagane” od `reviewer` (#59) i `qa` (#58). Raport to tylko komentarz
i plik, a reviewer i autor korzystają z tego samego konta bota, więc „Request changes” w GitHubie jest niemożliwe. Krok przeglądu
(`.farm/workflows/phases.md`) jest dziś tylko konwencją. Potrzebna jest bramka egzekwowana przez GitHub: PR z kodem nie może
zostać zmergowany bez pozytywnego werdyktu reviewer (a dla ekranów także qa), niezależnie od tego, kto kliknie merge.

## Szczegóły

### 1. Etykiety (Steward tworzy, `gh label create` jest zarezerwowane dla Stewarda)
| Etykieta | Znaczenie | Kto ustawia |
|---|---|---|
| `review:ok` | reviewer: werdykt „do akceptacji” dla bieżącego head | reviewer |
| `review:changes` | reviewer: „zmiany wymagane” (blokuje) | reviewer |
| `qa:ok` | qa: kryteria akceptacji spełnione | qa |
| `qa:changes` | qa: odrzucone (blokuje) | qa |
| `ui` | PR zmienia ekrany; wymusza `qa:ok` także poza `lib/features/**` | autor PR / orchestrator |

### 2. Workflow `.github/workflows/review-gate.yml` (nowy plik)
- Wyzwalacze: `pull_request` z typami `opened`, `reopened`, `synchronize`, `labeled`, `unlabeled`, `ready_for_review`; gałąź `main`.
  **Nie** `pull_request_target` i **bez checkoutu kodu PR** – job tylko czyta metadane przez API (brak wykonywania kodu z PR).
- `permissions: contents: read, pull-requests: write` (zdejmowanie etykiet), reszta none. Job `review-gate` (nazwa = nazwa kontroli).
- Job uruchamia się **zawsze** (bez filtra `paths:` na poziomie workflow), bo wymagana kontrola, która się nie uruchomi, blokuje PR
  na zawsze; decyzję „czy to PR z kodem” podejmuje krok w skrypcie. Wzorzec jak w GH-006 (`flutter` z krokiem detect).
- `concurrency: review-gate-${{ github.event.pull_request.number }}`, `cancel-in-progress: true`.
- Logika (`actions/github-script`, wersja przypięta jak w `ci.yml`):
  1. Lista zmienionych plików PR (`pulls.listFiles`, stronicowanie).
  2. `code` = jakikolwiek plik pod `lib/`, `android/`, `backend/`, `test/`, `integration_test/` lub `pubspec.yaml`/`pubspec.lock`.
     `ui` = jakikolwiek plik pod `lib/features/` **lub** etykieta `ui`.
  3. Brak `code` → kontrola przechodzi („PR bez kodu – bramka pominięta”).
  4. Etykieta `review:changes` lub `qa:changes` → porażka z komunikatem.
  5. `code` bez `review:ok` → porażka („brak przeglądu reviewer”). `ui` bez `qa:ok` → porażka („brak weryfikacji qa”).
  6. Zdarzenie `synchronize` (nowy push): zdjąć `review:ok`, `qa:ok` (`issues.removeLabel`), `review:changes`/`qa:changes` zostawić do ponownego
     przeglądu; kontrola kończy się porażką do czasu nowych etykiet.
  7. **Wzmocnienie niezależne od zdjęcia etykiet (wyścig):** dla `*:ok` sprawdzić w zdarzeniach zgłoszenia (`issues.listEvents`), że ostatnie
     `labeled` tej etykiety ma `created_at` **późniejsze niż data commita head** (`pulls.get` → `head.sha` → `git.getCommit`); w przeciwnym razie
     etykieta dotyczy starszej wersji i jest ignorowana. Dzięki temu przegląd starej wersji nie „przejdzie” po pushu, nawet jeśli zdjęcie etykiet
     się spóźni.
  8. Lista kont uprawnionych do nadawania etykiet bramki (zmienna Actions `GATE_LABELERS`, domyślnie `tadecode-farm,tadecode`): etykieta nadana przez
     inne konto jest ignorowana (autor `labeled` z `issues.listEvents`, pole `actor.login`).
- Wyjątek: PR otwarty przez `dependabot[bot]` (aktualizacje `pubspec.*`/backend/Actions) – bramka go pomija; zamiast tego obowiązuje
  istniejące zatwierdzenie właściciela i CI. (Decyzja do potwierdzenia przez właściciela; bez wyjątku Dependabot wymagałby przeglądu każdej aktualizacji.)

### 3. Ochrona gałęzi `main`
- Dodać `review-gate` do wymaganych kontroli (obok `farm-guards`, `conventions`, `secrets`, `flutter`, `backend`); `strict` zgodnie z GH-007.
- Reszta bez zmian: 1 zatwierdzenie właściciela, CODEOWNERS, blokada pushu, squash.
- Dopisać `.github/workflows/review-gate.yml` do CODEOWNERS (zmiana bramki tylko za zgodą właściciela) – o ile `.github/` nie jest już objęte.
- Kolejność wdrożenia: najpierw workflow na `main` (PR od Stewarda), potem dodanie wymaganej kontroli, żeby nie zablokować otwartych PR-ów
  bez możliwości ich spełnienia. Otwarte PR-y z kodem po wdrożeniu dostaną etykiety w zwykłym trybie.

### 4. Kto i jak nadaje etykiety (sprawdzone w hookach)
- `qa` używa `guard-bash.ps1` (lista zakazów): `gh pr edit <nr> --add-label qa:ok` **nie jest dziś blokowane** (poza listą `admin`, bo to nie
  `gh label`, `gh api -X`, `gh pr merge`). Wymaga tylko, żeby etykieta istniała (punkt 1).
- `reviewer` używa `guard-bash-allow.ps1` (lista dozwolonych): `gh pr edit` **jest zablokowane** (poza listą). Potrzebna zmiana hooka
  i `reviewer.md` – opisana w `.farm/requests/FARM-007-reviewer-qa-tools.md` (plik chroniony, zmienia właściciel).
- Etykiety ustawia się kontem bota (`tadecode-farm`), które i tak otwiera PR-y.

## Wpływ
Koszty: jeden krótki job na zdarzenie PR (bez buildów, bez checkoutu, ~kilkanaście sekund; Ubuntu). · Bezpieczeństwo/RODO: bez nowych danych; workflow
nie wykonuje kodu z PR, uprawnienia ograniczone do `pull-requests: write`. · Ryzyko:
- **Bramka proceduralna, nie kryptograficzna.** To samo konto bota otwiera PR i nadaje etykiety, więc agent (lub błąd) może dać `review:ok` bez
  przeglądu. Bramka zatrzymuje pominięcie kroku przez pomyłkę (jak #57), nie złośliwe obejście. Łagodzenie: lista `GATE_LABELERS`, test czasu
  etykiety względem commita, jawny komentarz roli z SHA w PR.
- Wyścig: etykieta nadana dla starego head tuż przed pushem – obsłużone punktem 2.7.
- Zablokowanie PR-a, gdy reviewer/qa nie działa – wyjście awaryjne: właściciel ręcznie nadaje etykietę lub (administracyjnie) pomija kontrolę.
- Wymagana kontrola, która się nie uruchomi (np. wyłączone Actions), blokuje wszystkie PR-y – dlatego job ma działać bez filtra ścieżek.

Alternatywy (do decyzji właściciela, od najsłabszej do najsilniejszej):
1. **Właściciel nadaje etykiety ręcznie** po przeczytaniu raportów (workflow bez zmian, ale `GATE_LABELERS=tadecode`). Najprostsze i realnie niezależne;
   kosztuje kilka kliknięć na PR.
2. **Osobne konto GitHub dla reviewer/qa** (np. `tadecode-farm-review`, własny token w osobnym `GH_CONFIG_DIR`, jak konto Stewarda) – wtedy
   `GATE_LABELERS` zawiera tylko to konto i autor PR nie może sam sobie nadać etykiety; można też użyć prawdziwego „Request changes”.
   Wymaga założenia konta i zaproszenia do repo (sprawa właściciela, hasło/2FA poza agentami).
3. Kontrola zamiast etykiet sprawdza komentarz reviewer z markerem werdyktu i SHA (bez etykiet, ale komentarz da się podrobić tym samym kontem).

Rekomendacja: wdrożyć wersję z etykietami teraz (zatrzymuje pomyłki), a przy skali lub po kolejnym incydencie przejść na alternatywę 2.

## Odpowiedź Stewarda
2026-11-18 Steward: prośba zgodna z polityką (workflow bez `pull_request_target`, bez checkoutu kodu PR, uprawnienia `contents: read`, `pull-requests: write`).
Wykonane:
1. Etykiety `review:ok`, `review:changes`, `qa:ok`, `qa:changes`, `ui` istnieją (zweryfikowane `gh label list`).
2. Workflow `.github/workflows/review-gate.yml` na gałęzi `chore/ci-review-gate` (składnia YAML i JS sprawdzona lokalnie, jeszcze nie uruchomiony w CI). PR do zatwierdzenia przez właściciela (CODEOWNERS `/.github/`).

Przyjęte ustawienia domyślne z rekomendacji prośby, do potwierdzenia przez właściciela: etykiety nadaje bot (`GATE_LABELERS` = `tadecode-farm,tadecode`) oraz PR Dependabota jest zwolniony z bramki.

Czeka:
- po merge PR: dry-run `setup-github.ps1`, potem `-Apply` za zgodą właściciela (dodanie `review-gate` do wymaganych kontroli);
- zmiana hooka reviewera i `reviewer.md` (FARM-007, poza zakresem Stewarda); bez niej reviewer nie nada etykiety przez `gh pr edit`.
