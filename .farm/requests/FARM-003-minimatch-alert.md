# FARM-003: alert Dependabota #1 - minimatch w backend/functions (CVE-2026-118764)

- Zgłasza (rola): github-steward, na polecenie właściciela · Data: 2026-11-16 · Adresat: orchestrator (zlecić roli znającej Node/npm i TypeScript, np. `mobile-dev` z zakresem `backend/` lub rola backendowa, jeśli istnieje; do wyboru orchestratora) · Powiązane: alert https://github.com/tadecode/tamitu/security/dependabot/1
- Typ: zmiana poza zakresem Stewarda (`backend/functions/`)
- Status: open

## Problem
GitHub zgłasza na `main` 1 podatność (średnia): **minimatch**, CVE-2026-118764, „potential denial of service via globparts amplification". Podatne wersje: `>= 7.0.0, < 11.0.1`, poprawka: `11.0.1`. Manifest: `backend/functions/package-lock.json`, zakres `development`.

## Diagnoza (odczyt `package-lock.json` na `main` @ `dc1edfd`; nie zweryfikowana `npm ls`)
- Główna kopia `node_modules/minimatch` ma wersję **11.0.8** (załatana).
- Podatna jest kopia zagnieżdżona: `node_modules/@typescript-eslint/typescript-estree/node_modules/minimatch` w wersji **10.2.6**. Wciąga ją `@typescript-eslint/typescript-estree` (zależność `typescript-eslint@8.72.2`) przez zakres `"minimatch": "^10.2.2"`.
- Dependabot nie otworzył PR-a, bo to zależność pośrednia pod dolnym limitem zakresu rodzica.

## Ryzyko
Niskie w praktyce: pakiet jest tylko deweloperski (lint/typy), nie trafia do Cloud Functions i nie przetwarza danych użytkowników ani danych osobowych. Jest to jednak otwarty alert bezpieczeństwa na domyślnej gałęzi, więc do zamknięcia.

## Proponowane opcje (do oceny wykonawcy)
1. **Czekać na `typescript-eslint`** z podniesionym `minimatch`. Bezkosztowe, ale bez terminu; alert zostaje otwarty.
2. **`overrides` w `backend/functions/package.json`** wymuszający `minimatch >= 11.0.1` dla `@typescript-eslint/typescript-estree`. Ryzyko: zmiana wersji głównej 10 -> 11 w zależności, której autor oczekuje `^10`; trzeba potwierdzić, że `npm run lint`, `typecheck` i `test` przechodzą oraz że linter działa tak samo.
3. Odrzucić alert jako „tolerable risk / dev-only" (zamknięcie alertu to ustawienie repo, robi je Steward na zgodę właściciela, z uzasadnieniem w logu). Tylko jeśli opcje 1-2 odpadną.

Zalecenie Stewarda: opcja 2 po teście; jeśli przejdzie, PR z `backend/`, w którym wykonawca podaje wynik `npm audit` przed i po. Uwaga: Dependabot ma `ignore` dla `typescript >=6.1` (PR `chore/ci-dependabot-ignore-ts`), co nie wpływa na tę prośbę.

## Zakres i granice
Tylko `backend/functions/package.json` i `package-lock.json` (CODEOWNERS `/backend/`, zatwierdza właściciel). Bez nowych zależności i bez zmian w kodzie funkcji. Koszty: brak. RODO: brak (dev-only, bez danych).

## Odpowiedź
(orchestrator/wykonawca: status, numer PR; Steward po zmergowaniu sprawdzi, czy alert #1 zamknął się sam, i dopisze wynik do `docs/github-ops/log.md`)