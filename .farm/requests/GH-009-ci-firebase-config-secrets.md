# GH-009: sekrety CI z konfiguracją Firebase Android (`google-services.json`) i tokenem debug App Check

- Zgłasza (rola): orchestrator (P3-03, decyzja właściciela 2026-11-18) · Data: 2026-11-18 · Powiązane zadanie/PR: P3-03 / #66; ADR-0003, SEC-01, SEC-16
- Typ: secret + ci-change
- Status: open  (ustawia Steward)

## Potrzeba
Projekty Firebase `tamitu-dev-tadecode` i `tamitu-prod-tadecode` istnieją (P3-03). Plik `google-services.json` jest per flavor i
**nie jest commitowany** (`.gitignore`, ADR-0003, przegląd security 3-5; repozytorium publiczne). Gdy mobile-dev doda wtyczkę Gradle
`com.google.gms.google-services` (zadanie po P3-03), build Androida w CI będzie potrzebował tych plików. Do testów CI z
dostawcą debug App Check (flavor `dev`) potrzebny jest osobny token debug CI.

## Szczegóły
1. **Sekrety Actions (repozytorium lub środowiska `dev`/`prod`)** – wartości dostarcza właściciel bezpośrednio Stewardowi
   (`gh secret set … < plik`, z pliku na dysku właściciela; nigdy przez czat, prośbę ani log):

   | Sekret | Zawartość | Źródło (właściciel, lokalnie) |
   |---|---|---|
   | `GOOGLE_SERVICES_JSON_DEV` | base64 pliku dla `pl.tadecode.tamitu.dev` | `firebase apps:sdkconfig android 1:660969630372:android:48e4768c86542f081cd431 --project=tamitu-dev-tadecode` |
   | `GOOGLE_SERVICES_JSON_PROD` | base64 pliku dla `pl.tadecode.tamitu` | `firebase apps:sdkconfig android 1:41324867505:android:c983219aaa7a3c11449790 --project=tamitu-prod-tadecode` |
   | `TAMITU_APP_CHECK_DEBUG_TOKEN_CI` | token debug App Check **tylko projektu dev**, osobny dla CI (nazwa w konsoli `ci-github`) | Firebase → Tamitu Dev → App Check → Manage debug tokens |

   Rekomendacja: sekret `PROD` w środowisku GitHub `prod` (dostęp tylko z `main`); tokenu debug **nie ma i nie będzie** dla prod (ADR-0003 Aneks A pkt 2).
2. **Zmiana CI (po PR mobile-dev z wtyczką):** krok przed `flutter build` dekoduje sekret do `android/app/src/<flavor>/google-services.json`
   (bez `echo` wartości, `::add-mask::` niepotrzebne dla pliku, brak artefaktu z plikiem); token debug przez `--dart-define` tylko dla `dev`.
   Joby z PR-ów z forków nie dostają sekretów (domyślne zachowanie GitHub) – build w takim przypadku pomija krok lub używa `TAMITU_FAKE_BACKEND`.
3. **Warunek z przeglądu PR #70 (ustalenie #1, `docs/reviews/PR-70.md`):** obejście braku `google-services.json` w buildzie ma działać tylko przez jawną flagę `-Ptamitu.allowMissingGoogleServices=true` w kroku CI „czy się składa” albo wyłącznie dla wariantów debug – **nie** przez zmienną `CI`; przed buildem wydaniowym w CI plik z sekretu jest wymagany. Poprawka w `android/app/build.gradle.kts`: zadanie SEC-33 (mobile-dev); Steward dodaje flagę w kroku CI i wykonuje prośbę po SEC-33.
4. Skan sekretów (SEC-01, gitleaks): wzorce na `google-services.json` i tokeny debug App Check – potwierdzić, że są.

## Wpływ
Koszty: brak. · Bezpieczeństwo/RODO: klucz API Firebase nie jest sekretem w ścisłym sensie (jest w APK), ale repo jest publiczne – trzymamy poza repo; klucz ograniczony do API Firebase (P3-03). Token debug = obejście App Check w dev – tylko sekret, rotacja przy wycieku. · Ryzyko: niskie; zależne od PR mobile-dev (wtyczka Gradle).

## Odpowiedź Stewarda
