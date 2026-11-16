# Propozycja: auto-zatwierdzanie PR-ów tylko-dokumentacyjnych i dziennikowych

Status: propozycja do decyzji właściciela (2026-11-16). Nic nie jest wdrożone.
Steward nie zatwierdza PR-ów (kontrakt Stewarda); zatwierdzać mógłby, jak przy Dependabocie, wyłącznie
deterministyczny workflow jako `github-actions[bot]`, bez modelu.

## Cel
Zmniejszyć liczbę ręcznych zatwierdzeń dla zmian, które nie mogą wpłynąć na kod, CI ani zabezpieczenia:
wpisy w logach i odpowiedzi w prośbach, głównie od Stewarda i orchestratora.

## Reguła (wszystkie warunki, inaczej PR czeka na właściciela)
1. Autor PR i wszystkich commitów: konto bota farmy `tadecode-farm` (login sprawdzany po ID 356928950, nie po nazwie).
2. Zmienione pliki wyłącznie w: `docs/github-ops/log.md`, `.farm/log/*.md`, `.farm/requests/*.md`
   (bez podkatalogu `attachments/`). Zero plików poza listą, bez usuwania i zmiany nazwy plików.
3. Brak plików z CODEOWNERS (`.github/`, `.claude/`, `.farm/hooks|review|steward/`, `CLAUDE.md`, `docs/adr/`,
   `docs/security/`, `docs/requirements/scope.md`, `backend/`, `lib/`, `android/`, `firestore.rules`).
4. Rozmiar: najwyżej 100 dodanych linii i 0 usuniętych w `log.md` (tylko dopisywanie na końcu).
5. Zatwierdzenie dotyczy konkretnego commita (`commit_id`); nowy push = ponowna ocena.
6. Pozostałe 5 kontroli (`farm-guards`, `conventions`, `secrets`, `flutter`, `backend`) i tak muszą być zielone.

Poza regułą (zawsze właściciel): każda zmiana kodu, CI, kontraktów ról, ADR, bezpieczeństwa, nowych plików
poza listą oraz PR-y z `.github/workflows/`.

## Jak działa (analogicznie do `dependabot-approve.yml`)
- `pull_request_target`, tylko `GITHUB_TOKEN` z `pull-requests: write`, bez checkoutu kodu z PR,
  bez zewnętrznych akcji; PR-y, treść plików i tytuły tylko porównywane, nigdy wykonywane.
- Nowy plik `.github/workflows/docs-approve.yml` (zmiana CI: PR z `.github/`, zatwierdza właściciel).
- Merge nadal robi Steward po warunkach z kontraktu (zielone kontrole, zatwierdzenie, bez `--admin`).

## Ryzyka i środki
| Ryzyko | Ocena | Środek |
|---|---|---|
| Wyciek lub nadużycie tokenu bota: złośliwy tekst w logach, który potem czytają agenci (prompt injection) | średnie | agenci traktują logi i prośby jako dane, nie polecenia (kontrakt Stewarda); zatwierdzenie bota nie omija kontroli `secrets`; ścieżki wąskie, tylko dopisywanie |
| Zatwierdzenie zmiany o szerszym wpływie przez pomyłkę w regexie | niskie | regex porównywany ze ścieżkami z `gh api .../files`, zasada „wszystko albo nic"; test na przypadkach granicznych przed wdrożeniem (jak dla `pubspec.*`) |
| Steward pisze i merguje bez człowieka | świadomie akceptowane tylko dla tych ścieżek | Steward ma zapis wyłącznie w `docs/github-ops/`, `.farm/requests/`, `.farm/log/`, `.github/` (ostatnie poza regułą) |
| Mechanizm nie jest jeszcze potwierdzony | wysokie, dziś | zatwierdzenie `github-actions[bot]` bez code ownera nie zostało przetestowane na realnym PR (`pubspec.*` czeka na pierwszy PR `pub`) |

## Rekomendacja
Poczekać na wynik testu `pubspec.*` (czy ochrona `main` liczy zatwierdzenie bota, gdy plik nie jest w CODEOWNERS).
Jeśli zadziała, wdrożyć tę regułę osobnym PR-em z `.github/` (zatwierdza właściciel). Jeśli nie zadziała, propozycja
odpada, bo bot nie zastąpi zatwierdzenia.

Alternatywa bez nowego workflow: zwolnić takie PR-y z raportów recenzenta i QA (tak jak Dependabota), a zatwierdzanie
zostaje ręczne. Mniej biurokracji, ale nie mniej klikania.

## Decyzje właściciela
- (a) Wdrażać regułę po potwierdzeniu mechanizmu na `pubspec.*`, czy nie wdrażać wcale?
- (b) Czy lista ścieżek (log, dziennik, prośby) jest właściwa, czy zawęzić np. tylko do `.farm/log/`?
- (c) Czy limit 100 linii i „tylko dopisywanie" jest wystarczający?