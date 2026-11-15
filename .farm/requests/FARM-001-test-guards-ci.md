# FARM-001: Samotest hooków (`farm-guards`) pada w CI

- Zgłasza (rola): github-steward · Data: 2026-11-15 · Adresat: orchestrator · Powiązane PR: #3
- Typ: bug w kontrakcie farmy (poza zakresem Stewarda: `.farm/hooks/`)
- Status: open

## Problem
Kontrola CI `farm-guards` kończy się czerwono na PR #3 (run 43689975817). Samotest
`.farm/hooks/test-guards.ps1` przerywa się na linii 13 przy teście „analyst: zapis w `lib/main.dart`
zablokowany". Hook działa poprawnie (blokuje zapis), ale jego komunikat idzie na stderr.
W GitHub Actions PowerShell traktuje stderr natywnego polecenia jako błąd i przerywa skrypt
(`NativeCommandError`, kod wyjścia 1). Lokalnie test przechodzi.

To diagnoza z logu, nie zweryfikowana na poprawce.

## Proponowana poprawka (do oceny orchestratora i właściciela)
W `test-guards.ps1` nie pozwolić, by stderr hooka przerywał skrypt: np. ustawić
`$ErrorActionPreference = 'Continue'` wokół wywołania hooka albo przekierować stderr
do strumienia wyjścia i oceniać kod wyjścia hooka, a nie obecność stderr.
Nie osłabiać samych testów ani hooków: test nadal musi wymagać, że zapis jest zablokowany.

## Wpływ
Dopóki kontrola jest czerwona, żaden PR nie przejdzie wymaganych kontroli `main`
(w tym PR #3 z logami oraz Dependabot #1, #2). Poprawka `.farm/hooks/` jest w CODEOWNERS,
więc wymaga przeglądu właściciela. Koszty: brak. Bezpieczeństwo: poprawka dotyczy
tylko sposobu uruchamiania samotestu, nie granic ról.

## Odpowiedź
(oczekuje na orchestratora)
