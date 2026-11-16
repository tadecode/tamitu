# GH-005: PR #22 (Dependabot, AGP) i wpisy .gitignore dla backend/

- Zgłasza (rola): orchestrator · Data: 2026-11-16 · Powiązane PR: #22
- Typ: inne (merge PR, zmiana `.gitignore`, zasady Dependabota)
- Status: open  (ustawia Steward)

## Potrzeba
1. **PR #22** (`com.android.application` 9.3.1 -> 9.5.1 w `/android`) jest otwarty, a check `flutter` pada:
   „Minimum supported Gradle version is 9.6.0. Current version is 9.5.0". Bieg CI był sprzed PR #26
   (wrapper 9.9.1, już na `main`), więc po rebase build powinien przejść. Właściciel zatwierdził PR.
2. **`.gitignore` dla `backend/`**: brakuje wpisów dla artefaktów Firebase (`.firebase/`,
   `firebase-debug.log`, `google-services.json`, `.runtimeconfig.json`) i lokalnych plików emulatora.
   `google-services.json` nie może trafić do repozytorium (T2).
3. **Zasada dla Dependabota**: ustalić, że PR-y Dependabota są rebase'owane i mergowane przez Stewarda
   po zielonym CI (w tym `flutter`), a przy zmianie narzędzi budowania (AGP, Gradle, Kotlin)
   nie wchodzą na `main` bez udanego `assembleDevDebug`.

## Szczegóły
- Krok 1: rebase PR #22 na `main` (np. `@dependabot rebase`), sprawdzić wszystkie 6 checków, merge squash.
  Jeśli `flutter` nadal pada, zgłosić przyczynę zamiast mergować.
- Krok 2: dopisać wpisy do `.gitignore` (poza zakresem ról kodu; zakres Stewarda). Bez sekretów.
- Krok 3: potwierdzić lub poprawić zasadę; ewentualnie zapisać w `docs/github.md` (właściciel/orchestrator).

## Wpływ
Koszty: brak. Bezpieczeństwo: ochrona przed przypadkowym commitem pliku konfiguracyjnego Firebase;
RODO: brak nowych danych. Ryzyko: niskie.

## Odpowiedź Stewarda
(do uzupełnienia)
