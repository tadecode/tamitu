# ADR-0009: Układ repozytorium – Flutter w korzeniu, backend w `backend/`

- Status: zatwierdzony (decyzja właściciela produktu, 2026-11-15)
- Data: 2026-11-15
- Autor (rola): architect
- Zastępuje: ADR-0008 wyłącznie w punkcie „Układ repozytorium" (`app/` + `backend/`). Reszta ADR-0008 obowiązuje bez zmian.

## Kontekst
ADR-0008 zakładał `app/` (Flutter) + `backend/` (Firebase). Istniejące CI (kontrola Fluttera szuka `pubspec.yaml` w korzeniu, `.github/workflows/ci.yml`) oraz kontrakt agenta mobile-dev (`-Allow`: `lib`, `test`, `integration_test`, `android`, `assets`, `pubspec.yaml`, ...) zakładają Fluttera w korzeniu. Wymagana prostota i brak zbędnych zmian w chronionych plikach.

## Rozważane opcje
1. **A: Flutter w korzeniu + `backend/`** – zgodne z CI i uprawnieniami mobile-dev, standardowy układ `flutter create`, najmniej zmian; korzeń zawiera pliki Fluttera obok `docs/`, `.farm/`, `.github/`.
2. **B: `app/` + `backend/` (ADR-0008)** – czystszy podział katalogów; wymaga zmian w CI i uprawnieniach agentów (pliki chronione).

## Decyzja
Wybrano **A** (właściciel, 2026-11-15).

Układ:
- Korzeń: `lib/`, `android/`, `test/`, `integration_test/`, `assets/`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`.
- `backend/`: `firebase.json`, `firestore.rules`, `firestore.indexes.json`, `functions/` (TypeScript; `package.json` i `package-lock.json` w `backend/functions/`).
- Bez zmian: `docs/`, `.farm/`, `.claude/`, `.github/`.
- Odniesienia w dokumentacji: `app/lib/` → `lib/`; moduł startowy `app/` → `lib/app/` (overview.md). W `docs/data` i `docs/api` brak odniesień do `app/`.

## Wymagane zmiany w plikach chronionych (tylko opis; wykonuje właściwy właściciel pliku)
1. `.claude/agents/mobile-dev.md` – obecne `-Allow` nie zawiera `backend/`. Jeśli mobile-dev ma pisać backend, dodać `backend`; zalecane: osobna rola/agent backendowy lub jawna decyzja, kto pisze `backend/` (do rozstrzygnięcia przez orkiestratora). Pozostałe ścieżki korzeniowe już zgodne.
2. `.github/workflows/ci.yml` – kontrola Fluttera (korzeń, `pubspec.yaml`) bez zmian. Dla backendu dodać (prośba do Stewarda) job z `working-directory: backend/functions` (`npm ci`, lint, `vitest`), testy reguł/emulatora z `backend/`, filtry `paths` obejmujące `backend/**`; `flutter` joby nie powinny reagować na zmiany wyłącznie w `backend/`.
3. `CODEOWNERS` (jeśli istnieje) – dodać wpisy `/backend/` i `/lib/`, `/android/`; reguły dla `firestore.rules` i `backend/functions/` z przeglądem Security. Nie znaleziono pliku w `.github/` z odniesieniami do ścieżek – do weryfikacji przez Stewarda.
4. `.gitignore` – wpisy dla `backend/functions/node_modules/`, `backend/functions/lib/`, `.firebase/`, `*.log` oraz standardowe dla Fluttera w korzeniu (`build/`, `.dart_tool/`, `android/local.properties`, brak `google-services.json` z sekretami wg SEC-01 – decyzja co do pliku konfiguracyjnego osobno).
5. Dependabot – ekosystemy `pub` (katalog `/`) i `npm` (katalog `/backend/functions`).

## Konsekwencje
**Pozytywne:** zero zmian w CI i uprawnieniach dla części Flutter; standardowy układ; prostota.
**Negatywne:** korzeń repozytorium miesza pliki Fluttera z dokumentacją i konfiguracją farmy; narzędzia backendu muszą jawnie wskazywać `backend/`.
**Koszty:** brak kosztów zmiennych; drobna praca konfiguracyjna Stewarda.
**Ryzyka:** reguły ścieżek agentów (guard-paths) muszą obejmować `backend/` – inaczej brak wykonawcy zadań P3 dla backendu (punkt 1).
**Dane osobowe:** brak wpływu.
