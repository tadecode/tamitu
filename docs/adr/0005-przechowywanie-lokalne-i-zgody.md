# ADR-0005: Przechowywanie danych – lokalnie (szyfrowana baza), backup wyłączony, minimalny zapis serwerowy zgód

- Status: zatwierdzony (bramka G2, 2026-11-15; zatwierdził właściciel produktu)
- Data: 2026-11-15
- Autor (rola): architect
- Zadanie: P2-05 (pyt. 5, S3, S4, US-003, US-008, US-009, US-010; T9, T14, T15, T21)
- Odpowiedzi właściciela uwzględnione: Q7 (szyfrować bazę – SQLCipher), Q9 (dowód zgód usuwany razem z kontem; [PRAWNIK] do potwierdzenia). Uwagi Security 5-1, 5-2, 2-4/5-7, 5-4: „Aneks A" na końcu (w tym korekta określenia „crypto-shredding").

## Kontekst
Plany i dane podróży (D4, D5, D9, D15, D16) mają być wyłącznie lokalne w MVP (pyt. 5). Po wylogowaniu zostają, niewidoczne dla innego konta (N3). Kopia zapasowa Androida wyłączona (S4); szyfrowanie bazy – decyzja architekta. Dowód zgód: minimalny zapis serwerowy (UID, wersja, wartość, data; S3).

## Rozważane opcje
### Baza lokalna
| # | Opcja | Plusy | Minusy |
|---|---|---|---|
| 1 | **SQLite przez Drift + SQLCipher (szyfrowanie AES-256), klucz w Android Keystore** | Dane zaszyfrowane w spoczynku; relacyjne zapytania (lista, dni, punkty); migracje schematu (określenie „crypto-shredding" wycofane – Aneks A pkt 1) | Dodatkowa biblioteka natywna (+kilka MB APK); zarządzanie kluczem; utrata klucza = utrata bazy |
| 2 | Drift/SQLite bez szyfrowania | Najprościej | Dane podróży jawne przy dostępie root/ADB do telefonu; słabsza odpowiedź na T9 |
| 3 | Pliki JSON / Hive / SharedPreferences | Proste | Brak relacji, słabe migracje, SharedPreferences to jawne dane (T9: zakaz) |
| 4 | Firestore (chmura) | Synchronizacja | Sprzeczne z pyt. 5; zmiana rejestru (F4) – odroczone |

### Dowód zgód
| # | Opcja | Uwagi |
|---|---|---|
| a | **Lokalny zapis + minimalny rekord w Firestore przez funkcję `recordConsent`** | Zgodne z S3; dowód niezależny od urządzenia |
| b | Tylko lokalnie | Słaby dowód (S3 odrzucone przez właściciela) |

## Decyzja
### 1. Baza lokalna: opcja 1 (szyfrowana)
Uzasadnienie: koszt niewielki (Drift obsługuje SQLCipher), a plany + nocleg + daty ujawniają nieobecność w domu (T21). Szczegóły:
- **Jeden plik bazy na konto:** `tamitu_<sha256(uid)[0..16]>.db` w katalogu prywatnym aplikacji (izolacja kont, N3/US-008). Usunięcie konta = skasowanie pliku (US-010).
- **Klucz:** losowe 256 bitów generowane przy pierwszym uruchomieniu, przechowywane w `flutter_secure_storage` (klucz opakowany w Android Keystore). Jeden klucz na instalację. Brak klucza przy otwarciu (np. unieważnienie Keystore) = baza nieczytelna; aplikacja **usuwa stary, nieczytelny plik bazy**, zakłada nową pustą i informuje użytkownika (ryzyko R13 – akceptowane, plany są lokalne; Aneks A pkt 2).
- Fallback, gdyby biblioteka SQLCipher okazała się kłopotliwa (rozmiar, utrzymanie): opcja 2 + decyzja właściciela; wymagałoby to aktualizacji oceny T9.
- **Brak** lokalnego zapisu lokalizacji, współrzędnych, URL-i tras ze współrzędnymi, treści promptów (T12). Numer lotu (opcjonalny) zapisywany tylko lokalnie i nigdy wysyłany do AI (D5).
- Ustawienia niebędące danymi osobowymi (język interfejsu, flagi UI) w `shared_preferences`. W nich także tymczasowy wpis „zgoda na politykę przed logowaniem" (wersja, język, czas) do chwili przesłania na serwer.

### 2. Kopia zapasowa i manifest (S4, SEC-05)
- `android:allowBackup="false"`, a dla Androida 12+ także `android:dataExtractionRules` z wykluczeniem `cloud-backup` i `device-transfer` całego `domain` (oraz `fullBackupContent` dla starszych), aby wyłączyć też transfer między urządzeniami.
- `usesCleartextTraffic="false"` + Network Security Config bez wyjątków (T10). Minimalne uprawnienia: `INTERNET`, lokalizacja (ADR-0007). Przegląd zmergowanego manifestu, usunięcie `AD_ID` i innych dodanych przez biblioteki (`tools:node="remove"`).
- Brak logów debug w wydaniu (T7); brak Crashlytics/Analytics (D12).

### 3. Zgody (S3, T15)
- Rodzaje: `privacy_policy`, `ai_processing` (osobne, niezaznaczone domyślnie, wersjonowane; US-003, N5). Każdy rekord: typ, wartość (nadana/cofnięta), wersja tekstu, język wyświetlenia (PL/EN), czas klienta, czas serwera.
- Polityka prywatności przed logowaniem jest akceptowana, gdy konto jeszcze nie istnieje: zapis tymczasowy lokalnie → po zalogowaniu `recordConsent` (z czasem klienta) i zapis w bazie konta. Wycofanie/ponowne wyrażenie zgody zapisuje nowy rekord (historia „tylko dopisywanie").
- Serwer: `users/{uid}/consents/{id}` (Firestore, `deny all` dla klientów, zapis wyłącznie przez funkcję). `generatePlan` sprawdza, że ostatnia zgoda `ai_processing` jest nadana dla bieżącej wersji (egzekwowanie po stronie serwera).
- Zmiana wersji polityki/celu = żądanie ponownej zgody przy starcie (US-003).
- Okres przechowywania po usunięciu konta: **usuwane razem z kontem (Q9)**; zmiana tylko po poradzie prawnika [PRAWNIK] i nowym ADR (ADR-0004, Aneks A pkt 2).

### 4. Model danych
Szczegóły: `docs/data/model-danych.md` i `docs/data/przechowywanie-i-retencja.md`.

## Konsekwencje
**Pozytywne:** dane podróży nie opuszczają telefonu poza wysyłką do AI (za zgodą); minimalna powierzchnia serwerowa (zgody, licznik); szyfrowanie w spoczynku; łatwe, kompletne usunięcie.
**Negatywne:** utrata telefonu/odinstalowanie = utrata planów (R13, informować użytkownika); brak synchronizacji (później, F4); większy APK (SQLCipher); testy migracji schematu wymagane.
**Koszty:** brak kosztów zmiennych; Firestore na zgody/licznik w darmowej puli.
**Dane osobowe:** D3, D4, D5, D9, D15, D16 – lokalnie, zaszyfrowane; D3 także w Firestore (UE); brak zmian w rejestrze poza doprecyzowaniem „szyfrowanie bazy: tak" (do wpisania przez Security).

## Aneks A (2026-11-15, przy zatwierdzeniu): uwagi Security
1. **„Crypto-shredding" – doprecyzowanie (5-1).** Przy jednym kluczu na instalację usunięcie konta kasuje **plik** bazy (usunięcie pliku z systemu plików), a nie klucz; **ADR nie obiecuje kryptograficznego usunięcia danych**. Bezpieczeństwo skasowanych danych opiera się na szyfrowaniu pliku w spoczynku (klucz w Keystore) oraz na szyfrowaniu pamięci urządzenia przez Android (szyfrowanie plikowe); klucz bazy jest usuwany, gdy nie ma już żadnej bazy kont (`przechowywanie-i-retencja.md`). Klucz **per konto** (klucz opakowany w Keystore, kasowanie klucza = kasowanie danych) rozważony i **odłożony** jako opcjonalne wzmocnienie (większa złożoność, MVP); może wejść osobnym ADR. W dokumentach i polityce używać sformułowania „usunięcie pliku bazy", nie „crypto-shredding".
2. **Utrata klucza (5-2).** Brak klucza przy otwarciu bazy → usunięcie starego pliku, założenie pustej bazy, komunikat dla użytkownika. Test: utrata klucza → stary plik skasowany (SEC-07).
3. **Wycofanie zgody (2-4/5-7).** Normatywnie w Aneksie A ADR-0002, pkt 4: zapis `recordConsent(granted=false)` przed potwierdzeniem w UI, blokada lokalna działa od razu. Pole `synced` w `consents_local` obsługuje ponowienia; dla wycofania stan „wycofano" w UI dopiero po `synced=1`.
4. **`shared_preferences` (5-4).** Tymczasowy wpis zgody na politykę (bez UID) jest usuwany po udanym `recordConsent` (test).
5. **Zadania P3-06:** sprawdzenie pakietu `flutter_secure_storage` (backup wyłączony także dla jego plików, `dataExtractionRules` obejmują całą domenę), kryteria wyboru biblioteki SQLCipher (aktualność, aktywne wydania, brak znanych luk, licencja – 5-3, ADR-0008 Aneks A).
6. **Do decyzji właściciela, nie blokuje:** `FLAG_SECURE` na ekranach zgód i planu (5-8).
