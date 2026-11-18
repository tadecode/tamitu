# Firestore – retencja (TTL) i indeksy – Tamitu (MVP)

Stan: 2026-11-18, wersja 0.1, autor: dba. Rozstrzyga pytanie **O4** (`docs/open-questions.md`, sekcja „Konfiguracja środowisk (P3-03)").
Źródła: `docs/data/model-danych.md` pkt 3 (v0.4), `docs/data/przechowywanie-i-retencja.md`, ADR-0002 („Limity i bezpieczniki", Aneks A pkt 1), ADR-0003, ADR-0012, `docs/security/personal-data-register.md` (D3, D10, v0.4), `backend/firestore.indexes.json`, `backend/functions/src/limits.ts`, `backend/functions/src/index.ts`, `.farm/runbooks/P3-03-firebase.md` (etap 8).

## 1. Problem (O4)

`backend/firestore.indexes.json` włącza politykę TTL na `usage.updatedAt`. TTL Firestore usuwa dokument, gdy znacznik czasu w polu TTL jest **w przeszłości** (usuwanie zwykle w ciągu ok. 24 h po tej chwili, nigdy przed nią). `updatedAt` to chwila zapisu, czyli od razu przeszłość, więc `usage/{uid}` byłby kasowany w ciągu ok. doby od każdego zapisu. Licznik znikałby **w trakcie bieżącej doby**, a `effectiveCount()` liczy brak dokumentu jako 0. Użytkownik odzyskiwałby limit 5/dobę (N4), a odczytany licznik zależałby od tego, kiedy zadziała proces TTL. Tak samo działałby każdy TTL na polu z datą przeszłą.

Zapis „TTL 30 dni od ostatniej aktualizacji" w modelu danych i rejestrze (D10) jest celem poprawnym. Błędne jest tylko pole, na którym włączono politykę.

## 2. Warianty

| # | Wariant | Poprawność limitu | Koszt (na generowanie / stały) | RODO / retencja | Zmiana kodu i modelu |
|---|---|---|---|---|---|
| A | **Pole `expireAt` w `usage/{uid}` = czas serwera + 30 dni, ustawiane przy każdym zapisie; TTL na `expireAt`** | Tak. `expireAt` zawsze wypada ≥ 30 dni po ostatnim zapisie, więc dokument nigdy nie znika w dobie, której dotyczy (30 dni ≫ 24 h + opóźnienie TTL). Po usunięciu przez TTL dokument jest i tak „wczorajszy" (`effectiveCount` = 0). | Bez zmian: 1 odczyt + 1 zapis w transakcji (rezerwacja), +1 zapis przy zwrocie slotu. Usunięcie przez TTL: 1 zapis-usunięcie na nieaktywne konto (Firestore liczy je jak usunięcia, w darmowej puli) | Jeden dokument na konto, retencja 30 dni od ostatniego użycia, zgodnie z D10 i `przechowywanie-i-retencja.md`. Bez historii dziennej | Jedno pole więcej w zapisie (P3-05); w modelu danych pole `expireAt` i TTL przeniesione z `updatedAt` |
| B | Dokumenty dzienne `usage/{uid}/days/{yyyymmdd}` + TTL na `expireAt` | Tak (doba w kluczu, nie trzeba porównywać `day`) | Na żądanie tak samo (1 odczyt + 1 zapis), ale do 30 dokumentów na konto zamiast 1; indeks/TTL na grupie `days` | **Gorzej:** przechowuje historię dziennego użycia z 30 dni (więcej danych powiązanych z UID niż wymaga cel D10, który dotyczy tylko bieżącej doby). Usunięcie konta wymaga `recursiveDelete(usage/{uid})` (podkolekcja), a dokument nadrzędny nie istnieje (dokument „widmo") | Zmiana ścieżek, `UsageDoc`, `effectiveCount`, `deleteAccount`, rejestru D10 i modelu (architekt + security) |
| C | Bez TTL; zaplanowana funkcja czyszcząca (np. raz na dobę zapytanie `updatedAt < now − 30 dni`) | Tak | Dodatkowa funkcja, konto usługi i harmonogram (Cloud Scheduler), odczyty przy każdym przebiegu, indeks na `updatedAt` | Retencja zależy od działania zadania (awaria = brak usuwania) | Nowy kod, IAM, ADR (nowy komponent) |
| D | TTL na `updatedAt` (stan obecny pliku) | **Nie** – licznik zerowany w trakcie doby | – | – | – |
| E | Bez TTL; usuwanie tylko z kontem (`deleteAccount`) | Tak | Najtańszy | **Niezgodny** z D10: konta nieaktywne trzymałyby licznik bez końca | Zmiana rejestru |

**Decyzja: wariant A.** Jedyny, który jest poprawny i zarazem nie zwiększa kosztu, ilości danych osobowych ani zakresu kodu. Odpowiada już przyjętemu wzorcowi `usage_global/{day}.expireAt` i proponowanej odpowiedzi w O4. Wariant B odrzucony przez zbędną historię użycia (minimalizacja danych) i większą zmianę modelu. Wariant C odrzucony, bo wymaga nowego komponentu, a TTL Firestore załatwia to bez kodu.

To decyzja o schemacie (wybór pola TTL w granicach istniejącego ADR-0003 „TTL na `usage`" i retencji z D10), nie architektoniczna. **Nowy ADR nie jest potrzebny.** Potrzebna jest drobna aktualizacja modelu danych przez architekta (pkt 6).

### 2.1. Dlaczego „czas serwera + 30 dni", a nie „koniec doby + margines"
- Poprawność limitu wymaga tylko `expireAt` > koniec bieżącej doby Europe/Warsaw (`resetAt`). Każde `now + N` dla N ≥ 2 dni to spełnia z zapasem (także w dniach zmiany czasu, gdy doba ma 23/25 h).
- `now + 30 dni` dosłownie realizuje zapis „30 dni od ostatniej aktualizacji" z D10, nie zmienia zatwierdzonej retencji i nie zależy od `resetAt()`. Mniej logiki, mniej miejsc na błąd strefy czasowej.
- Krótsza retencja (np. `resetAt + 2 dni`) byłaby lepsza dla minimalizacji danych, bo po północy licznik nie jest już do niczego potrzebny. Zmienia jednak okres w rejestrze, więc decyduje security, a nie dba. Zgłoszone jako pytanie w dzienniku (propozycja O4-b). Zmiana wymagałaby tylko innej stałej w kodzie i wpisu w rejestrze; schemat i polityka TTL zostają bez zmian.

## 3. Pola TTL per kolekcja

| Kolekcja (grupa) | Pole TTL | Typ | Wartość ustawiana przez | Kiedy ustawiane | Efekt |
|---|---|---|---|---|---|
| `usage` (`usage/{uid}`) | **`expireAt`** | Timestamp | `generatePlan` (P3-05) | przy **każdym** zapisie dokumentu w transakcji: rezerwacja slotu i zwrot slotu | usunięcie ok. 30 dni (+ do ok. 24 h opóźnienia TTL) po ostatnim użyciu AI |
| `usage_global` (`usage_global/{yyyy-mm-dd}`) | `expireAt` (bez zmian) | Timestamp | `generatePlan` (P3-05) | przy każdym zapisie: czas serwera + 7 dni | usunięcie ok. 7 dni po ostatnim zapisie danej doby |
| `users/{uid}/consents` | **brak TTL** | – | – | – | do usunięcia konta (D3, Q9, ADR-0002 Aneks A pkt 1) |
| `config` | **brak TTL** | – | – | – | stała |

Pole `updatedAt` w `usage/{uid}` zostaje jako znacznik diagnostyczny (model danych v0.4). **Nie ma** na nim polityki TTL ani indeksu. Typ `expireAt` musi być `Timestamp` (Admin SDK: `Timestamp.fromDate(...)`). Dokument bez tego pola albo z polem innego typu (np. string ISO) **nie jest usuwany** przez TTL.

### 3.1. Docelowy kształt dokumentów

```
usage/{uid}
  day        string     "YYYY-MM-DD" (Europe/Warsaw, warsawDay)
  count      int        0..perUserDailyLimit
  updatedAt  timestamp  czas serwera ostatniego zapisu (diagnostyka)
  expireAt   timestamp  updatedAt + 30 dni  ← polityka TTL

usage_global/{yyyy-mm-dd}
  count      int
  expireAt   timestamp  czas serwera ostatniego zapisu + 7 dni  ← polityka TTL
```

Dane osobowe: `usage/{uid}` = D10 (UID w ścieżce, `day`, `count`). `expireAt` i `updatedAt` to metadane retencji, nie nowa kategoria danych. **Nie wymaga nowego wpisu** w rejestrze, wystarczy doprecyzowanie pola w D10 (security).

### 3.2. Reguły zapisu dla P3-05 (wymagania dla mobile-dev)
1. W transakcji rezerwacji odczyt `usage/{uid}` i `usage_global/{today}`. Jeśli `usage.day ≠ today`, licznik startuje od 0 (`effectiveCount`). Zapis przez `set` z pełnym kształtem: `day = today`, `count`, `updatedAt = now`, `expireAt = now + 30 d`.
2. `usage_global/{today}`: `count + 1`, `expireAt = now + 7 d`.
3. Zwrot slotu (błąd systemu po rezerwacji, ADR-0002): osobna transakcja; zmniejsza `count` **tylko gdy `day` nadal = doba rezerwacji** (po północy nie zwraca slotu do nowej doby), ustawia ponownie `updatedAt` i `expireAt`.
4. `now` = czas serwera funkcji (`deps.now()`), nie czas klienta.
5. Stałe retencji (30 d, 7 d) jako nazwane stałe w `limits.ts` (czysta funkcja, np. `usageExpireAt(now)`, `globalExpireAt(now)`) z testem jednostkowym: `expireAt − now = 30 d`, oraz `expireAt > resetAt(now)` dla dat granicznych (23:59 Europe/Warsaw, dni zmiany czasu).
6. Kolejność istnienia użytkownika i zapisu bez zmian (ADR-0002 Aneks A pkt 1): brak zapisu dla nieistniejącego UID.

## 4. Indeksy

Zasada (dba): indeks tylko z uzasadnieniem zapytania. Pola TTL wyłączone z indeksów jednopolowych. Monotonicznie rosnące znaczniki czasu powodują hotspoty zapisów indeksu, a po polach TTL nikt nie odpytuje.

| Kolekcja | Zapytanie | Indeks | Źródło |
|---|---|---|---|
| `users/{uid}/consents` (zakres `COLLECTION`) | `where("type","==",t).orderBy("receivedAt","desc").limit(1)` – ostatnia zgoda danego typu, 2× na `generatePlan` (ADR-0012) | złożony: `type` ASC, `receivedAt` DESC | `index.ts` `latestConsent` |
| `usage`, `usage_global`, `config` | tylko odczyt po ścieżce dokumentu | brak (wystarczą automatyczne) | – |

Wyłączenia indeksów (`fieldOverrides`, `indexes: []`): `usage.expireAt`, `usage_global.expireAt`. Pozostałe pola zostają z automatycznymi indeksami jednopolowymi. Są małe i nieużywane, a ich wyłączenie nie zmienia kosztu (indeksy nie są rozliczane per zapis, tylko jako miejsce). Dalsza optymalizacja byłaby więc przedwczesna.

Koszt odczytów: na `generatePlan` 1 (`config/runtime`) + 2 (zgody, po 1 dokumencie dzięki indeksowi; puste zapytanie liczy się jako 1 odczyt) + 2 (`usage`, `usage_global` w transakcji) ≈ 5 odczytów i 2 zapisy (+2 przy zwrocie slotu). Przy limicie globalnym 50/dobę to < 300 odczytów/dobę, czyli głęboko w darmowej puli (50 tys. odczytów / 20 tys. zapisów dziennie, ADR-0003). `costs.md` („ok. 3 odczyty i 3 zapisy") – różnica pomijalna, bez zmiany kosztu.

## 5. Docelowy `backend/firestore.indexes.json`

Plik leży poza uprawnieniami dba (`backend/`). **mobile-dev przenosi go 1:1** (zadanie w dzienniku `.farm/log/2026-11-18/0945-dba-O4.md`). Zmiana względem stanu obecnego dotyczy tylko pola TTL w `usage`: `updatedAt` → `expireAt`.

```json
{
  "indexes": [
    {
      "collectionGroup": "consents",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "type", "order": "ASCENDING" },
        { "fieldPath": "receivedAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": [
    { "collectionGroup": "usage", "fieldPath": "expireAt", "ttl": true, "indexes": [] },
    { "collectionGroup": "usage_global", "fieldPath": "expireAt", "ttl": true, "indexes": [] }
  ]
}
```

Uwaga: Firebase CLI obsługuje polityki TTL w `fieldOverrides` (`"ttl": true`), więc `firebase deploy --only firestore:indexes` wdraża **jednocześnie** indeks złożony i obie polityki TTL. Poniższe polecenia `gcloud` służą do weryfikacji i jako alternatywa ręczna.

## 6. Wdrożenie polityk TTL i indeksów (właściciel)

Warunek: PR mobile-dev ze zmienionym `backend/firestore.indexes.json` scalony do `main`. **Nie wdrażać obecnej wersji pliku** (TTL na `updatedAt`). Kolejność względem kodu P3-05 jest dowolna: polityka TTL na polu, którego dokumenty jeszcze nie mają, niczego nie usuwa. Wdrożenie przed P3-05 jest więc bezpieczne i zalecane (runbook P3-03, „Czego nie zrobiono" poz. 4).

Dla `<P>` = `tamitu-dev-tadecode`, potem `tamitu-prod-tadecode`:

```powershell
firebase deploy --only firestore:indexes --project=<P>
```

Weryfikacja (lub ręczne włączenie, gdy CLI nie wdroży TTL):

```powershell
gcloud firestore fields ttls list --project=<P>
```

```powershell
gcloud firestore fields ttls update expireAt --collection-group=usage --enable-ttl --project=<P>
```

```powershell
gcloud firestore fields ttls update expireAt --collection-group=usage_global --enable-ttl --project=<P>
```

```powershell
gcloud firestore indexes composite list --project=<P>
```

Oczekiwany wynik: TTL `ACTIVE` na `usage.expireAt` i `usage_global.expireAt`, **brak** TTL na `usage.updatedAt`, indeks `consents (type ASC, receivedAt DESC)` w stanie `READY`. Włączenie polityki TTL trwa od kilku minut do godzin (stan `CREATING`). Jeśli wcześniej ręcznie włączono TTL na `usage.updatedAt`: `gcloud firestore fields ttls update updatedAt --collection-group=usage --disable-ttl --project=<P>`.

Plan awaryjny (odwracalność): wyłączenie polityki (`--disable-ttl`) zatrzymuje dalsze usuwanie. Usuniętych dokumentów nie da się przywrócić (brak PITR i kopii, ADR-0003). W tym schemacie dotyczy to wyłącznie liczników z dób, które już minęły, więc utrata nie zmienia działania limitu.

## 7. Testy (dane syntetyczne)
- Jednostkowe (vitest, bez emulatora): `usageExpireAt(now) − now = 30 d`, `globalExpireAt(now) − now = 7 d`, `usageExpireAt(now) > resetAt(now)` dla 23:59:59 Europe/Warsaw oraz dni 2026-03-29 i 2026-10-25 (zmiana czasu).
- Emulator (przez `.farm/test-lock.ps1`): po rezerwacji `usage/{uid}` ma `expireAt` typu Timestamp; zwrot slotu odświeża `expireAt`; dokument z `day` = wczoraj daje `effectiveCount` = 0. Emulator Firestore **nie wykonuje TTL**, więc samego usuwania nie testujemy lokalnie.
- Dev (po wdrożeniu): dokument syntetyczny `usage/test-ttl` z `expireAt` = teraz − 1 min powinien zniknąć w ciągu ok. 24 h; dokument z `expireAt` = teraz + 30 d pozostaje.

## 8. Wpływ na inne dokumenty (poza zakresem dba – propozycje)
- `docs/data/model-danych.md` pkt 3 (architect): `usage/{uid}` – dodać `expireAt (timestamp = updatedAt + 30 dni, polityka TTL)`, `updatedAt` bez polityki TTL; `usage_global` – „`expireAt` = ostatni zapis + 7 dni".
- `docs/security/personal-data-register.md` D10 i `docs/data/przechowywanie-i-retencja.md` (security/architect): „TTL na `expireAt` (= ostatnia aktualizacja + 30 dni)", treść retencji bez zmian. Po wdrożeniu usunąć adnotację „polityki TTL niewdrożone".
- `.farm/runbooks/P3-03-firebase.md` etap 8 i „Czego nie zrobiono" poz. 4 (orchestrator): odsyłacz do pkt 6 tego dokumentu.
