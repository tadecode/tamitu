# ADR-0019: Budowanie i podpisywanie wydań Androida (Play App Signing, klucz przesyłania poza repo, build lokalny)

- Status: **zatwierdzony** (właściciel, 2026-11-26; O-TAM116-3, przekazał orkiestrator)
- Data: 2026-11-26
- Autor (rola): architect
- Zadanie: TAM-116 (REL-INT-PLAN); plan: `docs/architecture/plan-wydania-testy-wewnetrzne.md`
- Powiązane: ADR-0003 (środowiska, brak poświadczeń prod u agentów), ADR-0011 pkt 6 (`testData` ze stałej kompilacji),
  SEC-17 W-3 (operacje prod tylko przez właściciela), runbook P3-03 etap 6–7 i 10 („Czego nie zrobiono” #2).

## Kontekst

Pierwsze wydanie produkcyjne trafia do Google Play: testy wewnętrzne (decyzja właściciela 2026-11-26). Dziś
`android/app/build.gradle.kts` podpisuje `release` **kluczem debug** (`TODO`), a aplikacja prod w Firebase nie ma
odcisków SHA, więc nie działa ani logowanie Google, ani App Check z Play Integrity. Trzeba ustalić:

1. kto trzyma klucz, którym podpisane jest to, co instaluje użytkownik;
2. gdzie powstaje plik AAB i gdzie leży klucz przesyłania;
3. jak plik trafia do Play.

Ograniczenia: repozytorium bez sekretów (zasada 7), agenci bez poświadczeń prod (ADR-0003, SEC-17 W-3), CI
i sekrety zmienia tylko Steward (zasada 11), brak niespodziewanych kosztów (zasada 10), mały zespół (jedna osoba
z dostępem do konsol).

## Rozważane opcje

**A. Klucz podpisu aplikacji**
1. **Play App Signing** (Google generuje i trzyma klucz podpisu; my podpisujemy AAB kluczem przesyłania) – plusy:
   obowiązkowe dla nowych aplikacji w formacie AAB; utratę lub wyciek klucza przesyłania da się naprawić resetem
   w Play Console; Google optymalizuje pliki dla urządzeń. Minusy: Google podpisuje w naszym imieniu (standard rynku).
2. Własny klucz podpisu przesłany do Google – plusy: ten sam klucz poza Play. Minusy: musimy go chronić przez całe
   życie aplikacji; utrata = koniec aktualizacji; nie potrzebujemy dystrybucji poza Play.

**B. Gdzie budujemy AAB `prod`**
1. **Lokalnie u właściciela** – plusy: klucz przesyłania nie opuszcza komputera i menedżera haseł właściciela; zero
   nowych sekretów w CI; zero kosztu; zgodne z W-3 (operacje prod robi właściciel). Minusy: build zależy od środowiska
   właściciela (wersja Fluttera, JDK); ręczna procedura.
2. **W CI (GitHub Actions)** z kluczem w sekretach – plusy: powtarzalny build z przypiętej wersji Fluttera (GH-013),
   ślad w logach. Minusy: klucz w sekretach GitHub (ryzyko wycieku przez workflow), praca Stewarda (środowisko
   z zatwierdzeniem, sekrety), minuty Actions w repo prywatnym.
3. **CI + automatyczne przesłanie do Play** (Play Developer API) – plusy: pełna automatyzacja. Minusy: konto usługi
   z dostępem do Play Console, pierwsze przesłanie i tak ręczne; przesada przy jednym testerze.

**C. Przesłanie do Play**: ręcznie w Play Console albo automat (B3).

Kryteria: bezpieczeństwo klucza, prostota, koszt, powtarzalność, zgodność z zasadami farmy.

## Decyzja

1. **Play App Signing (A1).** Klucz podpisu aplikacji generuje i chroni Google (opcja domyślna w Play Console).
2. **Klucz przesyłania** (upload key) generuje **właściciel** (`keytool`, RSA 4096, ważność ≥ 25 lat, alias np.
   `tamitu-upload`). Plik leży **poza repozytorium** (`%USERPROFILE%\.tamitu\signing\`), hasła i kopia pliku –
   w menedżerze haseł firmy. Nigdy w repo, Jirze, Confluence, czacie, logach ani w promptach do modeli. Agenci nie
   mają do niego dostępu (hooki farmy blokują odczyt kluczy podpisu).
3. **Gradle (mobile-dev):** `prodRelease` podpisuje kluczem przesyłania wskazanym z zewnątrz (właściwości Gradle
   w profilu użytkownika albo zmienne środowiskowe – tak, by etap 2 w CI użył tego samego mechanizmu). Brak klucza
   przy budowaniu `prodRelease` = **błąd buildu** (bez cichego powrotu do klucza debug). `devRelease` i buildy debug
   bez zmian.
4. **Etap 1 (teraz): build lokalny u właściciela (B1) i ręczne przesłanie w Play Console (C ręcznie).** Polecenie
   i lista kontrolna – instrukcja mobile-dev (zadanie MD-3): `flutter build appbundle --release --flavor prod
   --dart-define=TAMITU_TEST_DATA=true` (ADR-0011 pkt 6, tylko w wewnętrznych buildach testowych do zamknięcia SEC-15),
   bez stałych debug.
5. **Etap 2 (później, osobna decyzja właściciela i prośba do Stewarda): build w CI (B2)** – workflow uruchamiany
   ręcznie, w środowisku GitHub `release` z wymaganym zatwierdzeniem właściciela; sekrety klucza przesyłania
   i `GOOGLE_SERVICES_JSON_PROD` tylko w tym środowisku; wynik (AAB i `mapping.txt`) jako artefakt do ręcznego
   przesłania. Warunek: co najmniej jedno udane wydanie z etapu 1 i sprawdzenie zużycia minut Actions.
6. **Automatyczne przesyłanie (B3) – poza MVP.**
7. **Odciski w Firebase prod:** SHA-1 i SHA-256 klucza podpisu Google oraz klucza przesyłania (logowanie Google:
   SHA-1; App Check Play Integrity: SHA-256 klucza Google). Klucza debug **nie dodajemy** do aplikacji prod.
8. **Wersjonowanie:** `version` w `pubspec.yaml` (`versionName+versionCode`); `versionCode` rośnie przy każdym
   przesłaniu do Play, podbijany w PR-ze przed buildem; tag `v<versionName>+<versionCode>` na commicie buildu.

## Konsekwencje

- **Pozytywne:** brak nowych sekretów w CI na start; klucz przesyłania można zresetować, więc jego utrata nie kończy
  życia aplikacji; App Check i logowanie Google dostają stałe odciski od pierwszego przesłania; zgodność z ADR-0003
  i SEC-17 W-3.
- **Negatywne:** build `prod` zależy od komputera właściciela (wersja Fluttera musi być równa przypiętej w CI –
  instrukcja MD-3 to sprawdza); ręczne kroki przy każdym wydaniu; jedna osoba (właściciel) jest wąskim gardłem.
- **Koszty (zasada 10):** etap 1 – 0 zł (poza jednorazową opłatą Play 25 USD, niezależną od tej decyzji). Etap 2 –
  minuty GitHub Actions (ok. 10–15 min na build Linux; w planie Free 2 000 min/mies. wspólnie z resztą CI) – do
  sprawdzenia przed włączeniem.
- **Ryzyka:** wyciek klucza przesyłania (łagodzenie: plik poza repo, hooki, skan sekretów STW-1, reset w Play
  Console); utrata klucza (kopia w menedżerze haseł; reset przez pomoc Google trwa dni); build lokalny z inną wersją
  Fluttera niż CI (kontrola w instrukcji).
- **Dane osobowe:** decyzja nie dodaje nowych danych. Lista testerów w Play Console (rejestr D13) jest poza repo.
- **Zmiana decyzji** (np. przejście na etap 2 lub B3) – nowym ADR albo aneksem przy zatwierdzeniu, nie po cichu.

## Aneks A (2026-11-26, przy zatwierdzeniu)

1. Konto organizacji TadeCode w Google Play Console już istnieje (O-TAM116-4), więc opłata rejestracyjna nie jest
   kosztem tego wydania.
2. Właściciel włączył w prod realne dane od razu (O-TAM116-1). Stała `TAMITU_TEST_DATA=true` z pkt 4 **zostaje**
   w buildzie testów wewnętrznych. Przy obu flagach realnych danych `true` nic nie zmienia, ale pozwala ograniczyć
   generowanie do konta z `testUids` samą zmianą `config/runtime.allowRealData=false`, bez nowego buildu (plan,
   sekcja 4.7, O-TAM116-8). Build dla testerów spoza bramki 2a planu – bez tej stałej, po spełnieniu bramki.
3. Treść decyzji (pkt 1–8) bez zmian.
