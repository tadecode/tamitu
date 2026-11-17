# ADR-0013: Wybór platformy – Flutter (aplikacja) i Firebase (backend); zapis wsteczny z analizą alternatyw

- Status: proponowany (decyzję zatwierdza właściciel produktu)
- Data: 2026-11-17
- Autor (rola): architect
- Zadanie: pytanie właściciela (2026-11-17): „dlaczego Flutter, a nie React Native; dlaczego Firebase, a nie Supabase"
- Charakter: **zapis wsteczny**. Flutter i Firebase były parametrami wejściowymi farmy (`CLAUDE.md`, `docs/vision.md`: „narzucone") i żaden ADR nie porównywał alternatyw. ADR-0008 wybiera pakiety *wewnątrz* Fluttera, ADR-0003/0004 – konfigurację *wewnątrz* Firebase. Ten ADR niczego w nich nie zmienia; ocenia, czy założenie wejściowe się broni i ile kosztowałaby zmiana.

## Kontekst

### Wymagania, które rozstrzygają wybór
| # | Wymaganie | Źródło |
|---|---|---|
| W1 | Android na start (`pl.tadecode.tamitu`, minSdk 26); iOS „poza zakresem na teraz", ale możliwy później | vision, ADR-0008 |
| W2 | Interfejs PL/EN, Material 3, własny design system UX (EK-01..EK-16), dostępność (duży tekst do 200%) | ADR-0006, `docs/ux/` |
| W3 | RODO: minimalizacja danych na serwerze; **plany wyłącznie lokalnie**, szyfrowana baza (SQLCipher), klucz w Android Keystore | ADR-0005 |
| W4 | Model AI wyłącznie przez pośrednika: Gemini na Vertex AI, regionalny punkt `europe-west4`, **konto usługi IAM bez klucza statycznego** (T1) | ADR-0001, ADR-0002 |
| W5 | Atestacja aplikacji (App Check / Play Integrity), tokeny jednorazowe dla `generatePlan` | ADR-0002 |
| W6 | Logowanie wyłącznie Google (później Facebook, Apple, Microsoft), bez haseł | ADR-0004 |
| W7 | Dane serwerowe w UE; lokalizacja Auth do potwierdzenia (SEC-10, T29) | ADR-0003 |
| W8 | Koszty pod kontrolą: budżet prod 100 PLN/mies., dev 20 PLN/mies., wyłącznik kosztowy | ADR-0003 (Q3) |

### Skala i zespół
- **Skala MVP:** testy z kilkoma–kilkudziesięcioma osobami; ok. 40–400 generowań planu miesięcznie (ADR-0001). Na serwerze tylko zgody (D3), licznik limitu (D10), logi bez treści (D11) i konto Auth (D1). Brak synchronizacji, brak plików, brak zapytań relacyjnych po stronie serwera.
- **Zespół:** jedna osoba (właściciel, jednoosobowa działalność TadeCode) + farma agentów AI. Liczy się: mało ruchomych części, mało dostawców do nadzoru (umowy, rozliczenia, 2FA), dobre emulatory do testów bez chmury, dojrzała dokumentacja (agenci uczą się z dokumentacji).

### Stan prac (koszt zmiany rośnie z każdym zadaniem)
Zatwierdzone ADR-0001..0012; szkielet Flutter (P3-01, ok. 360 linii `lib/`+`test/`), szkielet backendu (P3-02) i #51 (ADR-0011/0012 w `backend/functions`, ok. 1 500 linii TS z testami, 99 testów vitest); w toku P3-04 (logowanie Google, zgody, `recordConsent`). Projektów Firebase jeszcze nie utworzono (P3-03, Q10), więc nie ma danych do migracji.

## Część A – aplikacja: Flutter vs React Native (oraz natywny Kotlin, Kotlin Multiplatform)

### Kryteria i ocena
| Kryterium (waga) | **Flutter (Dart)** | React Native (TS, Expo / bare) | Natywny Kotlin (Compose) | Kotlin Multiplatform (+ Compose MP) |
|---|---|---|---|---|
| Material 3 i design system UX (wysoka) | Material 3 wbudowany w SDK, własny silnik renderujący – ekran wygląda tak samo na każdym Androidzie; motyw z tokenów UX 1:1 (`ThemeData`, `ColorScheme`) | Komponenty natywne lub biblioteki (np. React Native Paper – M3, społecznościowa); większa zależność od bibliotek zewnętrznych | Najlepszy Material 3 (Compose Material 3 od Google) | Compose MP ≈ Compose; M3 dostępny |
| Wsparcie Firebase (wysoka) | **FlutterFire – pakiety Google** (repo `firebase/flutterfire`, dokumentacja na firebase.google.com), Auth, App Check (Play Integrity), Functions callable | `@react-native-firebase` (Invertase) – dojrzały, ale **społecznościowy, nie Google**; App Check z Play Integrity obsługiwany. Alternatywa: Firebase JS SDK – bez natywnego App Check/Play Integrity | Oficjalne SDK Android – najlepsze | Brak oficjalnego SDK KMP; społecznościowy GitLive (opakowuje SDK natywne) |
| SQLCipher i bezpieczne przechowywanie (wysoka, W3) | Drift + SQLCipher (wsparcie opisane w dokumentacji Drift), `flutter_secure_storage` (Keystore) | Możliwe (np. `op-sqlite` z SQLCipher, `react-native-keychain`), ale mniej jednolite; wybór biblioteki to osobna ocena | Room + SQLCipher, Keystore – najdojrzalsze | SQLDelight + SQLCipher – możliwe, więcej pracy przy iOS |
| l10n PL/EN (średnia) | `flutter_localizations` + ARB, generowane klasy, test kompletności (ADR-0006) | `i18next`/`react-intl` – dojrzałe | Zasoby Androida – dojrzałe | Compose MP resources – młodsze |
| iOS w przyszłości (średnia) | Jeden kod UI i logiki; iOS wymaga konfiguracji, Apple Sign-In (R9) | Jeden kod; iOS równie dobry | **Brak** – druga aplikacja od zera | Wspólna logika; UI wspólne przez Compose MP (stabilność iOS niezweryfikowana) |
| Wydajność (niska dla tej aplikacji) | AOT, 60 fps, większy APK (silnik ~kilka MB + SQLCipher) | Nowa architektura (JSI, Fabric) – wystarczająca; mniejsza kontrola przy listach | Najlepsza, najmniejszy APK | Jak natywny na Androidzie |
| Dostępność programistów (średnia) | Dart mniej popularny niż TS; rynek Fluttera duży, ale mniejszy niż React | **Największa pula** (React/TS) | Duża pula Android | Mała pula, technologia młodsza |
| Spójność języka z backendem TS (niska–średnia) | Dwa języki (Dart + TS) – koszt opisany w ADR-0008 | **Jeden język** (TS) w aplikacji i funkcjach; wspólne typy kontraktu | Dwa języki | Dwa języki |
| Narzędzia testów i CI dla farmy (średnia) | `flutter test` + testy widgetów bez emulatora, `flutter analyze` – jedno narzędzie | Jest + RNTL; więcej konfiguracji (Metro, Babel, natywne moduły) | Robolectric/Compose tests, Gradle | Gradle, więcej konfiguracji |

### Wnioski części A
- **React Native** to realna alternatywa: wygrywa jednym językiem z backendem i pulą programistów. Przegrywa tam, gdzie Tamitu ma wymagania twarde: integracja Firebase nie jest prowadzona przez Google (ryzyko opóźnień po zmianach SDK, szczególnie App Check), Material 3 i spójność z design systemem wymagają bibliotek społecznościowych, a szyfrowana baza to wybór spośród kilku bibliotek o różnej dojrzałości. Zysk „jednego języka" jest mniejszy, niż się wydaje: kontrakt aplikacja–pośrednik jest mały (`docs/api/posrednik-api.md`, 3 funkcje).
- **Natywny Kotlin** byłby najlepszy dla samego Androida, ale zamyka drogę do iOS bez drugiej aplikacji – sprzeczne z W1 („iOS później").
- **Kotlin Multiplatform** – brak oficjalnego SDK Firebase, mniejsza dojrzałość i pula; za duże ryzyko dla jednoosobowego MVP.
- **Flutter** spełnia wszystkie wymagania twarde bez bibliotek spoza Google/Drift. Wada (drugi język, Dart) jest znana i zaakceptowana w ADR-0008.

## Część B – backend: Firebase vs Supabase (oraz własny backend na Cloud Run)

### Kryteria i ocena
| Kryterium (waga) | **Firebase + Google Cloud** | Supabase (Postgres, Auth, Edge Functions) | Własny backend na Cloud Run (+ Cloud SQL / Firestore) |
|---|---|---|---|
| Integracja z Vertex AI i IAM (najwyższa, W4, T1) | Funkcje działają na koncie usługi w tym samym projekcie GCP; Vertex wywoływany przez IAM **bez klucza statycznego**; jeden projekt, jeden budżet, jeden wyłącznik (`budgetGuard`) | Edge Functions działają poza GCP. Bez klucza wymagałoby Workload Identity Federation z tokenem OIDC środowiska wykonawczego – **nie znalazłem w dokumentacji Supabase takiego tokenu dla Edge Functions (niezweryfikowane)**; w praktyce klucz JSON konta usługi w sekretach Supabase = złamanie T1 | Jak Firebase (konto usługi, IAM) |
| App Check / Play Integrity (wysoka, W5) | Wbudowane: `enforceAppCheck`, `consumeAppCheckToken` w callable | **Brak wbudowanego odpowiednika**; trzeba samodzielnie weryfikować token Play Integrity w Edge Function (API Google + konto usługi – znowu poświadczenie GCP poza GCP) | Firebase App Check działa też z Cloud Run (weryfikacja tokenu Admin SDK) – ręczny kod |
| Logowanie Google (wysoka, W6) | Firebase Auth + `google_sign_in`; token weryfikowany automatycznie w callable | Supabase Auth: natywne logowanie Google przez `signInWithIdToken` (oficjalny `supabase_flutter`) – równie dobre | Trzeba wybrać dostawcę tożsamości (Firebase Auth / Identity Platform albo własny OIDC) |
| **Rezydencja danych w UE (wysoka, W7, SEC-10)** | Firestore, Functions, logi, Vertex – `europe-west4`. **Firebase Auth / Identity Platform: brak wyboru regionu** (źródła wtórne z 2026 r. podają przechowywanie w USA; oficjalnej strony Google o lokalizacji Auth nie znalazłem – **niezweryfikowane, rozstrzyga SEC-10**) | **Przewaga Supabase:** baza, Auth i Storage w wybranym regionie (np. `eu-central-1` Frankfurt) wg oficjalnego przewodnika GDPR Supabase; FAQ transferów Supabase (wersja z 2026-10-06) wymienia jednak transfery do USA i Singapuru na SCC (podprocesorzy, wsparcie) | Zależnie od wyboru tożsamości; z Firebase Auth – jak Firebase |
| Model danych (średnia) | Mało danych na serwerze (zgody, licznik); Firestore + transakcje wystarczają; reguły `deny all` | Postgres i RLS to przewaga przy dużym modelu relacyjnym – **dla Tamitu niewykorzystana** (plany są lokalne, ADR-0005) | Pełna swoboda, pełne utrzymanie |
| Koszt i darmowe limity (wysoka, W8) | Przy skali MVP ok. 0–1 PLN/mies. + model AI (ADR-0003); plan Blaze bez opłaty stałej; Auth Google bez opłat do 50 tys. MAU (źródła wtórne 2026; oficjalny cennik niezweryfikowany) | Free: 500 MB bazy, 50 tys. MAU, **wstrzymanie projektu po tygodniu bezczynności**, 2 aktywne projekty; Pro: **25 USD/mies. za organizację** (+ compute ponad kredyt 10 USD) – ok. 100 PLN, czyli **cały obecny budżet prod**; Vertex AI i tak rozliczany osobno w GCP (źródła wtórne 2026; oficjalny cennik niezweryfikowany) | Cloud Run ≈ 0 przy skalowaniu do zera; Cloud SQL od kilkudziesięciu PLN/mies. (niezweryfikowane) – Firestore zamiast Cloud SQL ≈ 0 |
| Uzależnienie od dostawcy (średnia, R7) | Wysokie: Firestore i callable są własnościowe; łagodzone małą ilością danych na serwerze (brak danych do migracji), abstrakcją `PlanGenerator` i cienką warstwą funkcji | Niższe: Postgres jest przenośny | Najniższe |
| Self-hosting (niska) | Brak | Możliwy (open source), ale to własna eksploatacja i bezpieczeństwo – nierealne dla 1 osoby | Z definicji |
| RODO / DPA (wysoka) | **Jeden dostawca** (Google Cloud: CDPA, Firebase w warunkach GCP), jedno konto, jeden rejestr podprocesorów – już potrzebny dla Vertex AI (SEC-15) | **Dwóch dostawców** (Supabase + Google dla Vertex AI i Play Integrity): dwie umowy powierzenia, dwie listy podprocesorów, dwa rozliczenia i budżety, aktualizacja rejestru i polityki | Jeden dostawca (Google) |
| Emulator i testy bez chmury (średnia, farma) | Firebase Emulator Suite (Functions, Firestore, Auth) – używany w CI (P3-02) | Supabase CLI (lokalny Postgres w Dockerze) – dobry, ale Docker w CI/Windows | Własne mocki/kontenery |
| Utrzymanie przez 1 osobę (wysoka) | Zarządzane, brak serwerów | Zarządzane | Kontener, obraz, aktualizacje, sieć – więcej pracy |

### Wnioski części B
- **Jedyny mocny argument za Supabase to rezydencja Auth w UE.** Wszystkie pozostałe wymagania twarde (W4 bez klucza, W5 atestacja, W8 koszt, jeden DPA) przemawiają za Firebase. Supabase nie usuwa Google z łańcucha: Vertex AI (ADR-0001) i Play Integrity zostają w Google Cloud, więc pojawia się drugi dostawca, a nie zamiana dostawcy.
- **Ekspozycja Auth na transfer jest mała:** Firebase Auth przechowuje UID, e-mail i nazwę konta Google (D1) – bez danych podróży (lokalnie) i bez treści do AI. Transfer do USA ma podstawę w warunkach Google (do opisu w polityce, SEC-10). To ryzyko prawne, nie techniczne – rozstrzyga prawnik.
- **Własny backend na Cloud Run** nie daje nic ponad Cloud Functions 2. gen. (które działają na Cloud Run) przy większym koszcie utrzymania; odrzucony już w ADR-0002 (opcja 3).

## Decyzja
1. **Aplikacja: Flutter (Dart), Android na start** – potwierdzone. Uzasadnienie: oficjalne pakiety Firebase od Google (w tym App Check z Play Integrity), Material 3 i design system bez bibliotek społecznościowych, Drift + SQLCipher, jedno źródło dla przyszłego iOS.
2. **Backend: Firebase + Google Cloud (`europe-west4`)** – potwierdzone. Uzasadnienie: Vertex AI przez IAM bez klucza statycznego, wbudowany App Check, jeden dostawca i jeden DPA, koszt stały ≈ 0 przy skali MVP, emulator w CI.
3. **Zmiana stosu teraz: nie.** Nic w wymaganiach nie przemawia za zmianą; jedyny otwarty argument (rezydencja Auth) czeka na SEC-10 i opinię prawnika i – jeśli zostanie przesądzony – da się go rozwiązać węższą zmianą (pkt 4), bez przepisywania całości.
4. **Ścieżka awaryjna dla Auth (gdy wymagana rezydencja UE):** rozważyć najpierw *zamianę samej warstwy tożsamości* (dostawca tożsamości z regionem UE, którego tokeny weryfikuje pośrednik), zachowując Functions, Firestore, App Check i Vertex. Szkic zakresu: ADR-0004 (nowy, zastępujący), weryfikacja tokenu w `auth.ts` zamiast wbudowanej w callable (przejście na `onRequest` albo ręczna weryfikacja), klient logowania w P3-04, rejestr D1, polityka. Ocena kosztu i wybór dostawcy – osobny ADR, dopiero gdy warunek z sekcji „Warunki ponownego rozpatrzenia" pkt 1 zajdzie.

## Konsekwencje

**Pozytywne:** decyzje ADR-0001..0012 pozostają spójne; jawny zapis, dlaczego alternatywy odrzucono; zdefiniowane warunki powrotu do tematu zamiast okresowych dyskusji.

**Negatywne / ryzyka (zaakceptowane):**
- Dwa języki (Dart + TS) – bez zmian względem ADR-0008.
- Uzależnienie od Google/Firebase (R7) – łagodzone: mało danych na serwerze, abstrakcja modelu, cienkie funkcje.
- Auth bez wyboru regionu (T29) – do wyniku SEC-10; brak realnych danych do tego czasu (`ALLOW_REAL_DATA=false`, bez zmian).

**Koszty:** brak zmian kosztów (decyzja potwierdza stan obecny). Dla porównania: Supabase Pro dodałby ok. 25 USD/mies. kosztu stałego (niezweryfikowane w oficjalnym cenniku) przy nadal płatnym Vertex AI w GCP.

**Dane osobowe:** bez zmian w rejestrze.

### Koszt ewentualnej zmiany (stan na 2026-11-17)
| Zmiana | Dotknięte ADR | Dotknięte zadania / kod | Szacunek |
|---|---|---|---|
| Flutter → React Native | ADR-0005 (biblioteki bazy i Keystore), 0006 (i18n), 0008 (cały stos aplikacji), 0009 (układ repo), 0010 (ikony), 0011 (pakiety, sieć) – nowe, zastępujące | P3-01 (szkielet, test manifestu i tłumaczeń, CI), P3-04 w toku (logowanie, zgody), specyfikacje ekranów odwołujące się do komponentów Flutter; prośba do Stewarda o nowe CI | Kod aplikacji dziś mały (ok. 360 linii), ale **koszt dokumentacyjny i CI duży** i rośnie z każdym zadaniem P3; ok. 1–2 tygodnie pracy farmy + ponowne bramki. Backend bez zmian |
| Firebase → Supabase | ADR-0002 (pośrednik, App Check, IAM), 0003 (środowiska, region, budżety, logi), 0004 (Auth), 0005 (dowód zgód w Firestore), 0011, 0012 – nowe, zastępujące; aktualizacja rejestru, modelu zagrożeń (T1, T3, T29), polityki | Przepisanie `backend/functions` (#51: ok. 1 500 linii TS z 99 testami; callable → Edge Functions na Deno; transakcje Firestore → Postgres/RLS; własna weryfikacja Play Integrity), P3-02, P3-03, P3-04; drugi dostawca: DPA, konto, budżet | ok. 2–4 tygodnie + nowa analiza Security i ponowna G2; nierozwiązany problem klucza do Vertex AI (T1) |
| Tylko Auth → dostawca z regionem UE | ADR-0004 (zastępujący), aneks ADR-0002 | `auth.ts`, `deleteAccount`, klient logowania (P3-04), rejestr D1 | Najwęższa zmiana; ocena w osobnym ADR przy spełnieniu warunku 1 |

## Warunki ponownego rozpatrzenia
1. **Wynik SEC-10 lub opinia prawnika** wymagająca przechowywania danych konta (D1) w UE, albo zmiana podstawy transferów UE–USA, której nie da się opisać w polityce → najpierw ścieżka z Decyzji pkt 4 (sama warstwa Auth), dopiero potem pełna zmiana backendu.
2. **Synchronizacja planów między urządzeniami (F4)** – dużo danych osobowych na serwerze i model relacyjny: ponownie ocenić Firestore vs Postgres (Supabase / Cloud SQL) w ADR dla F4.
3. **Start prac nad iOS** – potwierdzić wsparcie FlutterFire i Drift/SQLCipher na iOS, Apple Sign-In (R9); jeśli FlutterFire lub któryś pakiet krytyczny przestanie być utrzymywany – ponownie ocenić React Native.
4. **Zmiana cennika lub warunków** Firebase/Google Cloud powodująca przekroczenie budżetu (Q3) przy normalnym użyciu, albo zmiana dostawcy modelu AI poza Google (ADR-0001 opcja 4) – wtedy argument „jeden dostawca" słabnie.

## Weryfikacja źródeł (2026-11-17, WebSearch)
| Twierdzenie | Źródło | Stan |
|---|---|---|
| Supabase: baza, Auth i Storage w regionie projektu; DPA dostępne | supabase.com/docs/guides/security/gdpr-compliance | potwierdzone w dokumentacji Supabase |
| Supabase: transfery do USA i Singapuru na SCC | supabase.com/legal/privacy-resources/data-residency-and-transfers-faq (wersja 2026-10-06) | potwierdzone; treści DPA i listy podprocesorów nie czytałem |
| Supabase: Free 500 MB / 50 tys. MAU / wstrzymanie po 7 dniach; Pro 25 USD, 100 tys. MAU | blogi i porównania z 2026 r. (np. makerkit.dev, toolradar.com) | **niezweryfikowane** w supabase.com/pricing |
| Supabase: brak wbudowanego odpowiednika App Check | brak w wynikach wyszukiwania; jedynie pakiety społecznościowe (Apple App Attest) | **niezweryfikowane** (brak dowodu negatywnego) |
| Supabase Edge Functions: brak tokenu OIDC dla Workload Identity Federation | brak w wynikach wyszukiwania | **niezweryfikowane** |
| Supabase: natywne logowanie Google (`signInWithIdToken`) w `supabase_flutter` | supabase.com/docs/reference/dart/auth-signinwithidtoken | potwierdzone |
| Firebase Auth / Identity Platform: brak wyboru regionu | issuetracker.google.com/issues/322471351, wątki społeczności, strony porównawcze 2026 | **niezweryfikowane w oficjalnej dokumentacji Google** – SEC-10 |
| Firebase Auth: bez opłat do 50 tys. MAU (Spark i Blaze) | blogi 2026 (logto.io, rapidnative.com) | **niezweryfikowane** w oficjalnym cenniku (zgodne z ADR-0003) |
| `@react-native-firebase` (Invertase) obsługuje App Check z Play Integrity | rnfirebase.io/app-check/usage | potwierdzone (dokumentacja biblioteki) |
| FlutterFire: pakiety w repo `firebase/flutterfire`, dokumentacja i informacje o wydaniach na firebase.google.com | firebase.google.com/docs/flutter/setup, release notes Flutter | potwierdzone; strona instalacji oznacza część wtyczek (m.in. App Check, Functions) jako „beta" – **sprawdzić przy P3-03** |
| Brak oficjalnego SDK Firebase dla Kotlin Multiplatform; GitLive społecznościowy | firebase.uservoice.com, klibs.io, developer.android.com/kmp | potwierdzone (brak oficjalnego ogłoszenia) |
| Workload Identity Federation działa dla obciążeń spoza GCP z tokenem OIDC | dokumentacja Vercel (GCP WIF), przewodniki zewnętrzne | potwierdzone ogólnie; dla Supabase niezweryfikowane |
| Dostępność programistów, wydajność RN vs Flutter | ocena architekta | opinia, bez pomiaru |
