# Ocena SEC-UIDLOG – UID i token debug App Check w logcat (OBS-DEV-3)

- Data: 2026-11-18. Autor: Security. Zadanie: SEC-UIDLOG.
- Wejście: `docs/qa/verify-p3-04-dev.md` (PRIV-05 „częściowo”, OBS-DEV-3), `threat-model.md` v0.3 (T7, T9), przegląd `reviews/2026-11-16-p3-14c-ekrany.md` (U-13), `personal-data-register.md` (D1, D2, D18), `android/app/build.gradle.kts`, `lib/app/bootstrap.dart`, `lib/app/environment.dart`.
- Metoda: analiza bajtkodu bibliotek z lokalnej pamięci Gradle (`javap -c`, bez uruchamiania), kod narzędzi Flutter (`FlutterPlugin.kt`), dokumentacja Androida. Bez użycia telefonu.
- To nie jest porada prawna.

## 1. Podsumowanie

| # | Ustalenie | Ocena |
|---|---|---|
| 1 | Firebase Auth (`com.google.firebase:firebase-auth:25.0.0`) zapisuje Firebase UID przez **bezwarunkowe** `android.util.Log.d("FirebaseAuth", …)` przy każdym powiadomieniu nasłuchiwaczy (logowanie, odświeżenie tokenu ID, start z zapisaną sesją). Biblioteka jest prekompilowana, a jej kod jest **identyczny w buildzie debug i release**. Android nie odfiltrowuje `Log.d` w wydaniu. **Wniosek: w obecnej konfiguracji release (dev i prod) UID też trafi do logcat** | potwierdzone w bajtkodzie; obserwacja na release – **do weryfikacji na urządzeniu** |
| 2 | Token debug App Check zapisuje tylko dostawca debug, który jest aktywowany wyłącznie w wariancie `dev` (`appCheckModeFor`). W `prod` jest Play Integrity. Dodatkowo `firebase-appcheck-debug:20.1.0` w buildzie niedebugowalnym ignoruje wstrzyknięty token i zapisuje ostrzeżenie | akceptowalne (dane zespołu, D18) |
| 3 | Kto czyta logcat na Androidzie 13+: aplikacja widzi tylko własne logi. Pełny log mają: powłoka `adb` (debugowanie USB włączone i komputer autoryzowany przez użytkownika), aplikacje systemowe/uprzywilejowane z `READ_LOGS` (od Androida 13 z jednorazową zgodą użytkownika na pierwszym planie) oraz raport błędu (bugreport) tworzony przez użytkownika | ryzyko **niskie** |
| 4 | Rekomendacja: **ograniczyć** (reguła R8 usuwająca `Log.v/d` w release, zadanie dla mobile-dev) + **test release przez QA** (PRIV-05 na release). Do tego czasu **akceptacja tymczasowa** z uzasadnieniem z pkt 4 | nieblokujące dla testów z użytkownikami w `dev`, warunek przed publikacją `prod` |

## 2. Ustalenia szczegółowe

### 2.1 Firebase Auth – czy UID trafia do logcat w release

Ustalenie z bajtkodu `com.google.firebase.auth.FirebaseAuth` (firebase-auth 25.0.0 – wersja rozwiązywana przez `firebase_auth: ^7.1.0`):

- `"Notifying id token listeners about user ( " + uid + " )."` → `android.util.Log.d("FirebaseAuth", …)`,
- `"Notifying auth state listeners about user ( " + uid + " )."` → `android.util.Log.d("FirebaseAuth", …)`,
- komunikaty o wylogowaniu („… about a sign-out event.”) – też `Log.d`, ale bez UID.

Przed tymi wywołaniami **nie ma** sprawdzenia `Log.isLoggable(…)` (w klasie jest jedno takie sprawdzenie, dotyczy innej ścieżki – logu `Log.i` przy konfiguracji emulatora). Wniosek:

1. Poziom D w logcat nie zależy od typu buildu aplikacji. `BuildConfig.DEBUG` aplikacji nie ma wpływu na kod biblioteki, a Android zapisuje `Log.d` w każdym buildzie (dokumentacja `android.util.Log`: poziomy debug/verbose „należy usuwać” przy kompilacji – robi to deweloper, nie system).
2. Właściwość `log.tag.FirebaseAuth` (`setprop`) wpływa tylko na `Log.isLoggable`, więc tych wywołań nie wyłączy.
3. Flutter włącza R8 w release (`FlutterPlugin.kt`: `isMinifyEnabled = true`, `proguard-android-optimize.txt`, `flutter_proguard_rules.pro`, opcjonalny `android/app/proguard-rules.pro`). Domyślne reguły **nie** usuwają `android.util.Log`, a w repo nie ma `android/app/proguard-rules.pro`. R8 sam z siebie nie usunie więc tych wywołań.

**Status:** w obecnej konfiguracji release UID będzie w logcat (wysoka pewność, wniosek z kodu). Potwierdzenie obserwacją: **do weryfikacji na urządzeniu** (QA, PRIV-05 na release).

### 2.2 App Check – token debug

- `lib/app/environment.dart`: `flavor == 'dev' ? AppCheckMode.debug : AppCheckMode.playIntegrity`. W `prod` dostawca debug nie jest aktywowany, więc jego log nie powstaje.
- `DebugAppCheckProvider` (firebase-appcheck-debug 20.1.0) wypisuje „Firebase App Check debug token: …” przez `Log.d`. W buildzie niedebugowalnym ignoruje token wstrzyknięty z zewnątrz (ostrzeżenie „SECURITY WARNING: App Check debug token found in a non-debuggable Release build!”). Wygenerowany lokalnie token jest jednak nadal używany i logowany. To dotyczy tylko `dev release`, którego nie dystrybuujemy użytkownikom.
- Token debug to sekret zespołu (D18), nie dane użytkownika. Ryzyko: osoba z dostępem do logcat telefonu testowego może przejąć token i obejść App Check w `dev` do czasu jego usunięcia. Mitygacja istnieje: usuwanie tokenu po teście (sekcja 5 raportu QA, pkt 2) i projekt `dev` bez danych realnych (`allowRealData=false`).
- Uwaga: biblioteka `firebase-appcheck-debug` jest dołączana przez plugin `firebase_app_check` także do `prod`. Kod jest martwy (nieaktywowany) i nie loguje tokenu – bez działań; do ponownego sprawdzenia przy przeglądzie wydania `prod`.

### 2.3 Kto może czytać logcat (Android 13, urządzenie bez roota)

| Podmiot | Dostęp do logu `FirebaseAuth` naszej aplikacji | Uwagi |
|---|---|---|
| Tamitu | tak (własne logi) | nie czytamy |
| Inne aplikacje ze sklepu | **nie** | od Androida 4.1 `READ_LOGS` nie jest przyznawane aplikacjom zewnętrznym; bez niego aplikacja widzi tylko własne wpisy |
| Aplikacje systemowe/uprzywilejowane producenta (np. narzędzia diagnostyczne, „feedback”) z `READ_LOGS` | tak, od Androida 13 po **jednorazowej zgodzie użytkownika** (okno „dostęp do logów systemowych”), tylko na pierwszym planie | aplikacje producenta urządzenia; pośredni kanał przekazania logów producentowi, jeśli użytkownik zgodzi się i wyśle raport |
| `adb shell` / `adb logcat` | tak | wymaga włączonych opcji programisty, debugowania USB i autoryzacji komputera na telefonie; `pm grant … READ_LOGS` przez `adb` – ten sam warunek |
| Raport błędu (bugreport) | tak | tworzy go użytkownik; zawiera logcat; użytkownik może go komuś wysłać (np. nam przy zgłoszeniu) |
| Root / złośliwe oprogramowanie z uprawnieniami systemowymi | tak | wtedy UID jest najmniej cennym celem (dostęp do piaskownicy, T9) |

Bufor logcat jest pierścieniowy w pamięci urządzenia (zwykle minuty–godziny, zależnie od ruchu) i znika po restarcie.

### 2.4 Waga danych

- Firebase UID to pseudonimowy identyfikator konta (D1). Sam nie daje dostępu do konta ani do danych (reguły Firestore i App Check wymagają tokenu ID, a nie UID). W połączeniu z dostępem do projektu Firebase pozwala powiązać wpis z kontem Google.
- Nie zaobserwowano w logcat e-maila, nazwy, tokenu ID/odświeżania (D2) ani treści planów. Aplikacja sama nic nie loguje (PRIV-05, U-13 spełnione po stronie naszego kodu).
- Odniesienie do T7: „brak logów debug w wydaniu” obejmuje również biblioteki. Ten środek jest obecnie **niespełniony** dla Firebase Auth. Odniesienie do T9: logcat jest wymieniony jako kanał wycieku z urządzenia.

## 3. Ocena ryzyka

- Prawdopodobieństwo: **niskie**. Odczyt wymaga fizycznego dostępu z debugowaniem USB, świadomej zgody użytkownika dla aplikacji systemowej albo raportu błędu wysłanego przez samego użytkownika.
- Skutek: **niski**. Pseudonimowy identyfikator, bez danych podróży i bez poświadczeń.
- Ryzyko rezydualne: **niskie**. Niezgodność z deklaracją T7 („brak logów debug w wydaniu”) i z zasadą minimalizacji – łatwa do usunięcia, więc należy ją usunąć przed `prod`.
- Nie jest to naruszenie ochrony danych w rozumieniu art. 33 RODO (brak ujawnienia osobie nieuprawnionej). Jest to przetwarzanie techniczne na urządzeniu użytkownika do opisania w rejestrze (D1).

## 4. Rekomendacja

1. **Testy z użytkownikami w `dev` (build debug) – akceptacja tymczasowa.** Uzasadnienie: niskie ryzyko (pkt 3), telefony testowe pod kontrolą zespołu, token debug usuwany po teście, projekt `dev` bez danych realnych. Warunek: uczestnicy nie przekazują nam raportów błędu (bugreport), a jeśli przekażą – traktujemy je jak dane osobowe (bez commitowania, usunięcie po analizie).
2. **Ograniczyć w release (zadanie mobile-dev, SEC-UIDLOG-1).** Dodać `android/app/proguard-rules.pro` (Flutter dołącza go automatycznie do release) z regułą usuwającą `Log.v`/`Log.d` w całym programie, także w bibliotekach – R8 optymalizuje kod zależności razem z aplikacją. Preferowana reguła z dokumentacji Androida:
   ```
   -maximumremovedandroidloglevel 3
   ```
   (usuwa `Log.v`, `Log.d` i odpowiadające im `isLoggable`; poziomy I/W/E zostają). Zastępczo, jeśli wersja AGP/R8 jej nie obsługuje – `-assumenosideeffects` z **jawnymi sygnaturami** `v`/`d` klasy `android.util.Log` (bez `*` i bez `public *`, bo szeroki wzorzec może zepsuć aplikację). Uwagi:
   - reguła usuwa wywołanie; budowanie napisu (konkatenacja z UID) R8 zwykle też usunie jako martwy kod, ale weryfikacją jest test na urządzeniu, nie założenie;
   - nie ustawiać poziomu logowania SDK przez `setprop` – nie działa dla tych wywołań (pkt 2.1);
   - zmiana nie wpływa na koszty ani na buildy debug (w debug logi zostają – akceptowalne).
3. **Test release przez QA (SEC-UIDLOG-1, kryterium akceptacji).** Na buildzie `devRelease` (lub `prodRelease` z kontem testowym): zalogować się, wymusić odświeżenie sesji (ponowne uruchomienie), `adb logcat -d -s FirebaseAuth RegionalFirebaseAuth` oraz `adb logcat -d | grep -F <UID testowy>`. Oczekiwane: zero wpisów z UID. To samo bez reguły (stan obecny) jest opcjonalne – potwierdza ustalenie 2.1. Wymaga telefonu, więc przez `.farm/test-lock.ps1` i po zakończeniu pracy mobile-dev nad BUG-DEV-1.
4. **Warunek przed publikacją `prod`:** SEC-UIDLOG-1 zrobione i PRIV-05 zaliczone na release. Do listy kontrolnej bramki wydania jako punkt T7.

## 5. Zmiany w dokumentach security

- `threat-model.md`: T7 i T9 – dopisek SEC-UIDLOG („brak logów debug w wydaniu” obejmuje biblioteki; środek: reguła R8 + test release).
- `personal-data-register.md` v0.7: D1 – UID w logcat urządzenia (biblioteka Firebase Auth), stan i działanie; D18 – token debug App Check w logcat telefonu testowego.

## 6. Źródła

- Bajtkod: `firebase-auth-25.0.0` (`com.google.firebase.auth.FirebaseAuth`, `…auth.internal.zzbz`), `firebase-appcheck-debug-20.1.0` (`DebugAppCheckProvider`) z lokalnej pamięci Gradle; `flutter_tools/gradle/src/main/kotlin/FlutterPlugin.kt` (lokalny Flutter SDK).
- Android Developers, „Additional rule types” (`-assumenosideeffects`, `-maximumremovedandroidloglevel`): https://developer.android.com/topic/performance/app-optimization/additional-rule-types
- Android Help, „Manage your device logs on Android” (zgoda na dostęp do logów, Android 13): https://support.google.com/android/answer/12986432
- Chromium `remove_logging.flags` (przykład użycia `-maximumremovedandroidloglevel 3`): https://chromium.googlesource.com/chromium/src.git/+/main/base/android/proguard/remove_logging.flags
- Lyons i in., USENIX Security 2023 (aplikacje firm trzecich bez `READ_LOGS` widzą tylko własne logi; uprawnienie tylko dla aplikacji uprzywilejowanych): https://www.usenix.net/system/files/usenixsecurity23-lyons.pdf
