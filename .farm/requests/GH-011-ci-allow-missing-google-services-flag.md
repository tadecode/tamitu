# GH-011: jawna flaga `tamitu.allowMissingGoogleServices` w kroku CI „Build APK (debug) – czy się składa”

- Zgłasza (rola): mobile-dev · Data: 2026-11-18 · Powiązane zadanie/PR: SEC-33 / PR `feat/SEC-33` (przegląd PR #70, ustalenie #1); poprzedza GH-009
- Typ: ci-change
- Status: done  (ustawia Steward)

## Potrzeba
SEC-33 usuwa z `android/app/build.gradle.kts` obejście braku `google-services.json` oparte na zmiennej `CI=true`.
Po zmianie brak pliku jest błędem buildu **także w CI**, chyba że Gradle dostanie jawną właściwość
`tamitu.allowMissingGoogleServices=true` (dozwoloną tylko dla buildów debug/profile; z zadaniem `release` Gradle przerywa build).
Dziś CI nie ma plików (GH-009 jeszcze niewykonane), więc krok „czy się składa” musi przekazać flagę jawnie.

## Szczegóły
1. `.github/workflows/ci.yml`, job `flutter`, krok „Build APK (debug) - czy się składa”:

   ```yaml
   run: flutter build apk --debug -P tamitu.allowMissingGoogleServices=true
   ```

   (`-P` = `--android-project-arg` w `flutter build apk`, Flutter 3.50; przekazuje `-P` do Gradle).
2. **Kolejność:** zmianę można scalić do `main` **przed** SEC-33 – obecny `build.gradle.kts` na `main` już honoruje tę
   właściwość (obok `CI=true`), więc nic się nie zepsuje. Bez niej CI PR-a SEC-33 będzie czerwone w kroku buildu
   (`Missing google-services.json` = ERROR). Po scaleniu wystarczy ponownie uruchomić CI PR-a SEC-33.
3. **Przy GH-009:** gdy krok zapisze pliki z sekretów, flagę należy **usunąć** z joba, który ma sekrety (build z plikami
   ma zawieść, jeśli plik się nie zapisał), a zostawić tylko w wariancie bez sekretów (PR z forków), jeśli taki będzie.
   Żaden przyszły krok `--release`/`appbundle` nie może jej używać – Gradle i tak go odrzuci.
4. Bez sekretów, tokenów ani wartości w workflow; zmiana jednej linii.

## Wpływ
Koszty: brak. · Bezpieczeństwo/RODO: wzmacnia kontrolę – build wydaniowy w CI bez prawdziwego pliku nie przejdzie. · Ryzyko: niskie; zgodne wstecz z `main`.

## Odpowiedź Stewarda
2026-11-18 Steward: wykonane, zweryfikowane. `ci.yml` na `main` zawiera `flutter build apk --debug -P tamitu.allowMissingGoogleServices=true` (PR #80). Przy GH-009 flagę usunąć z joba z sekretami.
