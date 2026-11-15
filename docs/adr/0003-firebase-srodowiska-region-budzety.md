# ADR-0003: Firebase i Google Cloud – środowiska dev/prod, region UE, budżety i alerty

- Status: zatwierdzony (bramka G2, 2026-11-15; zatwierdził właściciel produktu)
- Data: 2026-11-15
- Autor (rola): architect
- Zadanie: P2-03 (pyt. 3, SEC-02, SEC-09, SEC-10; T2, T3, T7, T8)
- Odpowiedzi właściciela uwzględnione: Q3 (budżety dev 20 PLN, prod 100 PLN/mies., alerty 50/90/100%, auto-wyłączenie AI, limit globalny 50/dobę), Q10 (właściciel zakłada konto rozliczeniowe/Blaze i projekty przed fazą 3; nazwy `tamitu-dev-…`, `tamitu-prod-…` zaakceptowane). Uwagi Security 3-1, 3-2, 3-4, 3-6: „Aneks A" na końcu.

## Kontekst
Firmowe konto Google TadeCode; projekty w regionie UE z alertami budżetowymi od startu (pyt. 3, vision). Dane po stronie chmury powiązane z UID: Auth (D1), zgody (D3), licznik (D10), logi (D11). Lokalizacji danych usług nie da się później zmienić (Firestore), więc decyzja jest trudno odwracalna.

## Rozważane opcje
1. **Dwa projekty: `dev` i `prod`** – izolacja danych i kosztów, bezpieczne eksperymenty, osobne budżety; więcej konfiguracji (dwa pliki konfiguracyjne Firebase, flavory Androida).
2. Jeden projekt – prościej, ale testy mieszają się z danymi prod i nie da się bezpiecznie przełączać flag (np. `ALLOW_REAL_DATA`); **odrzucone**.
3. Trzy projekty (dev/stage/prod) – nadmiarowe dla jednoosobowego MVP.

## Decyzja
### Projekty i region
- Dwa projekty Firebase/GCP na koncie TadeCode: `dev` i `prod` (identyfikatory wolne w chwili tworzenia, np. `tamitu-dev-…`, `tamitu-prod-…`; globalnie unikalne). Jedno konto rozliczeniowe (plan Blaze – wymagany dla Functions i Vertex AI), osobne budżety per projekt.
- **Region jednolity: `europe-west4` (Holandia)** dla Cloud Functions, Firestore (tryb Native, baza regionalna), Vertex AI i niestandardowego kubełka logów. Przed utworzeniem sprawdzić dostępność wszystkich usług i modelu w tym regionie; jeśli któraś usługa jest niedostępna, rozważyć `europe-west1` lub wieloregion `eur3` dla Firestore (decyzja przed utworzeniem bazy).
- Usługi włączone: Authentication (Google), Firestore, Functions, App Check, Vertex AI, Cloud Logging, Secret Manager (1 sekret: pieprz do skrótu UID), Pub/Sub (budżet). **Nie włączamy:** Google Analytics (nie łączyć przy tworzeniu projektu), Crashlytics, Cloud Storage, Hosting, Messaging, Remote Config (D12: brak analityki w MVP).
- Aplikacja Android: prod `pl.tadecode.tamitu`, dev `pl.tadecode.tamitu.dev` (flavory; osobne odciski SHA dla logowania Google i App Check).
- **Firestore: reguły `deny all`** (`allow read, write: if false`), cały dostęp przez Admin SDK z funkcji (T8, SEC-02). Testy reguł w emulatorze w CI. Brak PITR i kopii zaplanowanych (brak kopii = prostsze usuwanie, US-010); TTL na `usage`.
- Klucz API Firebase (`google-services.json`): ograniczyć w konsoli do pakietu i odcisku certyfikatu oraz do potrzebnych API (T2); plik niekomitowany (generowany lokalnie/CI) – rekomendacja, do potwierdzenia ze Stewardem.

### Logi i audyt (D11, S7)
Domyślny kubełek `_Default` ma lokalizację `global`, więc: utworzyć **własny kubełek logów w `europe-west4` z retencją 30 dni**, skierować do niego logi projektu (sink) i **wykluczyć** logi z `_Default`. Nie włączać Data Access audit logs dla Vertex AI/Firestore. Logi audytu administracyjnego (`_Required`, 400 dni, bez danych użytkowników) – opisać w polityce jako logi administracyjne konta. Logi żądań Cloud Run/Functions zawierają adres IP klienta – wskazać w polityce (D11).

### Budżety i alerty (zatwierdzone w Q3; kwoty ustawia i zmienia właściciel – SEC-09)
| Projekt | Budżet miesięczny | Progi alertu (e-mail właściciela) | Akcja |
|---|---|---|---|
| dev | 20 PLN | 50% / 90% / 100% | e-mail |
| prod | 100 PLN | 50% / 90% / 100% + prognoza 100% | e-mail; przy 100% Pub/Sub → `budgetGuard` ustawia `config/runtime.aiEnabled=false` (wyłącznik kosztowy; wznowienie ręczne przez właściciela) |

Budżety GCP nie ograniczają wydatków twardo, a powiadomienia mają opóźnienie; dlatego dodatkowo: limity na konto i globalne (ADR-0002), `maxInstances`, `maxOutputTokens`, niższe limity kwot Vertex AI (zapytania/min) ustawione w konsoli. **Nie odłączamy konta rozliczeniowego automatycznie** (ryzyko utraty projektu).

### Uprawnienia i dostęp
Konta właściciela z 2FA (najlepiej klucze sprzętowe, T17). Agenci i deweloperzy nie mają poświadczeń prod; wdrożenia z CI przez Workload Identity Federation (Steward, bez kluczy JSON). Konta usług wg ADR-0002.

### Weryfikacja lokalizacji (SEC-10, S2)
Security sprawdza w dokumentacji Google m.in.: lokalizację danych Firebase Authentication (usługa nie ma wyboru regionu – **możliwe przetwarzanie poza UE**; wtedy podstawa transferu wg warunków Google, do opisu w polityce), przetwarzanie ML Vertex AI (ADR-0001), lokalizację App Check i Secret Manager. Wynik wpisać do rejestru i do aneksu tego ADR. Do czasu: nie wysyłać realnych danych użytkowników.

## Konsekwencje
**Pozytywne:** izolacja środowisk; dane aplikacyjne i logi w UE; kontrola kosztów w kilku warstwach.
**Negatywne:** dwa zestawy konfiguracji; Auth może pozostać poza kontrolą regionu; wymóg karty (Blaze); region nie do zmiany po utworzeniu Firestore.
**Koszty:** stałe ok. 0–1 PLN/mies. (Secret Manager ≈ 0,06 USD za sekret; reszta w darmowych pulach: Functions 2 mln wywołań, Firestore 50 tys. odczytów i 20 tys. zapisów dziennie, Logging 50 GiB, App Check/Play Integrity w puli bezpłatnej, Auth Google bez opłat do 50 tys. MAU). Zmienne: ADR-0001.
**Dane osobowe:** D1, D3, D10, D11 w UE (Auth do weryfikacji); brak Analytics/Crashlytics zgodnie z D12.

## Aneks A (2026-11-15, przy zatwierdzeniu): wymagania z przeglądu Security
1. **Konfiguracja logów (3-1, T7/T25) – zadanie P3-03.** Sink do kubełka UE z retencją 30 dni musi obejmować logi Cloud Functions/Cloud Run i logi aplikacji; filtr wykluczający w `_Default` zapobiega po cichu zbieraniu logów w lokalizacji `global`. `_Required` pozostaje (logi audytu administracyjnego, 400 dni, bez danych użytkowników). Konfiguracja jako skrypt/IaC lub polecenia w `docs/` oraz **test odbioru**: po wywołaniu funkcji w `_Default` brak nowych wpisów aplikacji, a w kubełku UE są (SEC-04/SEC-10).
2. **Środowisko `dev` (3-4, Q2).** App Check w `dev`: dostawca debug wyłącznie we flavorze `dev`; test w CI: build `prod` nie zawiera dostawcy debug. Tokeny debug App Check są sekretami: zakaz commitowania, wzorce w skanie sekretów (SEC-01). W `dev` wyłącznie dane syntetyczne (zapis w README). Sideload APK dopuszczony tylko do `dev` do czasu ścieżki testowej Google Play (prod, Q2).
3. **Lokalizacja Auth i usług (3-2, 3-3, SEC-10).** Wynik weryfikacji (Auth, Vertex ML, Error Reporting, Secret Manager, App Check) zostanie dopisany jako kolejny aneks. Do tego czasu brak testów z osobami spoza zespołu i `ALLOW_REAL_DATA=false` (ADR-0001, ADR-0002). Przed utworzeniem Firestore potwierdzić dostępność `europe-west4` dla wszystkich usług (region bazy nie jest zmienialny).
4. **Dostęp (3-6).** Lista osób z dostępem do konsol Firestore/Auth w dokumentacji operacyjnej (konsola = UID i e-maile wszystkich użytkowników); dostęp do danych na wniosek – procedura właściciela (S9).
5. **Wyłącznik kosztowy (3-7).** `budgetGuard` jest powiadomieniem opóźnionym, nie twardym limitem; ryzyko rezydualne zaakceptowane, łagodzone limitami (ADR-0002 Aneks A pkt 5).
6. **Zadania właściciela przed fazą 3:** założenie konta rozliczeniowego TadeCode/planu Blaze i projektów `tamitu-dev-…`, `tamitu-prod-…` (Q10); ustawienie budżetów i alertów (Q3).
