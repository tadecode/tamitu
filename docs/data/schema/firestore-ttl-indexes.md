# Firestore – retencja (TTL) i indeksy – Tamitu (MVP)

Stan: 2026-11-21, wersja 0.3, autorzy: dba (v0.1–0.2), architect (v0.3). Zmiany v0.3 (TAM-91, decyzja właściciela O-TAM18-3): pole `usage.released` (najwyżej 2 zwroty slotu na dobę, zerowane w nowej dobie, bez indeksu; pkt 3.1, 3.2); `usage_global` bez zwrotu. Polityki TTL, indeksy i `backend/firestore.indexes.json` bez zmian. Rozstrzyga pytanie **O4** (`docs/open-questions.md`, sekcja „Konfiguracja środowisk (P3-03)").
Zmiany v0.2 (O4-b, decyzja security SEC-34, zatwierdzona przez właściciela 2026-11-18): retencja `usage/{uid}` skrócona z „czas serwera + 30 dni" do `expireAt = max(resetAt(now) + 2 d, now + 2 d)` (pkt 2.1, 3, 3.1, 3.2, 7). Pole TTL, polityka TTL, indeksy i `backend/firestore.indexes.json` bez zmian. `usage_global.expireAt` bez zmian (+7 dni).
Źródła: `docs/data/model-danych.md` pkt 3 (v0.4), `docs/data/przechowywanie-i-retencja.md`, ADR-0002 („Limity i bezpieczniki", Aneks A pkt 1), ADR-0003, ADR-0012, `docs/security/personal-data-register.md` (D3, D10, v0.4), `backend/firestore.indexes.json`, `backend/functions/src/limits.ts`, `backend/functions/src/index.ts`, `.farm/runbooks/P3-03-firebase.md` (etap 8).

## 1. Problem (O4)

`backend/firestore.indexes.json` włącza politykę TTL na `usage.updatedAt`. TTL Firestore usuwa dokument, gdy znacznik czasu w polu TTL jest **w przeszłości** (usuwanie zwykle w ciągu ok. 24 h po tej chwili, nigdy przed nią). `updatedAt` to chwila zapisu, czyli od razu przeszłość, więc `usage/{uid}` byłby kasowany w ciągu ok. doby od każdego zapisu. Licznik znikałby **w trakcie bieżącej doby**, a `effectiveCount()` liczy brak dokumentu jako 0. Użytkownik odzyskiwałby limit 5/dobę (N4), a odczytany licznik zależałby od tego, kiedy zadziała proces TTL. Tak samo działałby każdy TTL na polu z datą przeszłą.

Zapis „TTL 30 dni od ostatniej aktualizacji" w modelu danych i rejestrze (D10) jest celem poprawnym. Błędne jest tylko pole, na którym włączono politykę. (Okres 30 dni skrócono w v0.2, pkt 2.1; analiza wariantów poniżej pochodzi z v0.1 i zakłada 30 dni.)

## 2. Warianty

| # | Wariant | Poprawność limitu | Koszt (na generowanie / stały) | RODO / retencja | Zmiana kodu i modelu |
|---|---|---|---|---|---|
| A | **Pole `expireAt` w `usage/{uid}` ustawiane przy każdym zapisie; TTL na `expireAt`** (v0.1: czas serwera + 30 dni; od v0.2: `max(resetAt(now) + 2 d, now + 2 d)`, pkt 2.1) | Tak. `expireAt` zawsze wypada po końcu doby, której dotyczy zapis, więc dokument nigdy nie znika w tej dobie (TTL nie usuwa przed `expireAt`). Po usunięciu przez TTL dokument jest i tak „wczorajszy" (`effectiveCount` = 0). | Bez zmian: 1 odczyt + 1 zapis w transakcji (rezerwacja), +1 zapis przy zwrocie slotu. Usunięcie przez TTL: 1 zapis-usunięcie na nieaktywne konto (Firestore liczy je jak usunięcia, w darmowej puli) | Jeden dokument na konto, retencja wg D10 (od v0.2: 48–73 h od ostatniego użycia + opóźnienie TTL). Bez historii dziennej | Jedno pole więcej w zapisie (P3-05); w modelu danych pole `expireAt` i TTL przeniesione z `updatedAt` |
| B | Dokumenty dzienne `usage/{uid}/days/{yyyymmdd}` + TTL na `expireAt` | Tak (doba w kluczu, nie trzeba porównywać `day`) | Na żądanie tak samo (1 odczyt + 1 zapis), ale do 30 dokumentów na konto zamiast 1; indeks/TTL na grupie `days` | **Gorzej:** przechowuje historię dziennego użycia z 30 dni (więcej danych powiązanych z UID niż wymaga cel D10, który dotyczy tylko bieżącej doby). Usunięcie konta wymaga `recursiveDelete(usage/{uid})` (podkolekcja), a dokument nadrzędny nie istnieje (dokument „widmo") | Zmiana ścieżek, `UsageDoc`, `effectiveCount`, `deleteAccount`, rejestru D10 i modelu (architekt + security) |
| C | Bez TTL; zaplanowana funkcja czyszcząca (np. raz na dobę zapytanie `updatedAt < now − 30 dni`) | Tak | Dodatkowa funkcja, konto usługi i harmonogram (Cloud Scheduler), odczyty przy każdym przebiegu, indeks na `updatedAt` | Retencja zależy od działania zadania (awaria = brak usuwania) | Nowy kod, IAM, ADR (nowy komponent) |
| D | TTL na `updatedAt` (stan obecny pliku) | **Nie** – licznik zerowany w trakcie doby | – | – | – |
| E | Bez TTL; usuwanie tylko z kontem (`deleteAccount`) | Tak | Najtańszy | **Niezgodny** z D10: konta nieaktywne trzymałyby licznik bez końca | Zmiana rejestru |

**Decyzja: wariant A.** Jedyny, który jest poprawny i zarazem nie zwiększa kosztu, ilości danych osobowych ani zakresu kodu. Odpowiada już przyjętemu wzorcowi `usage_global/{day}.expireAt` i proponowanej odpowiedzi w O4. Wariant B odrzucony przez zbędną historię użycia (minimalizacja danych) i większą zmianę modelu. Wariant C odrzucony, bo wymaga nowego komponentu, a TTL Firestore załatwia to bez kodu.

To decyzja o schemacie (wybór pola TTL w granicach istniejącego ADR-0003 „TTL na `usage`" i retencji z D10), nie architektoniczna. **Nowy ADR nie jest potrzebny.** Potrzebna jest drobna aktualizacja modelu danych przez architekta (pkt 6).

### 2.1. Formuła `expireAt` dla `usage/{uid}` (v0.2, O4-b)

```
usageExpireAt(now) = max(resetAt(now) + 2 d, now + 2 d)
2 d = 2 × 86 400 000 ms (stała długość, nie doby kalendarzowe)
```

- `now` – czas serwera funkcji (`deps.now()`). `resetAt(now)` – najbliższa północ Europe/Warsaw jako chwila UTC (`limits.ts`; zwraca ISO, do obliczeń `new Date(resetAt(now))`).
- **Poprawność limitu** wymaga tylko `expireAt > resetAt(now)`. Formuła daje `expireAt − resetAt(now) ≥ 2 d` niezależnie od długości doby (23/25 h w dniach zmiany czasu), a TTL nigdy nie usuwa przed `expireAt`. Licznik nie zniknie więc w dobie, której dotyczy.
- **Dolne ograniczenie `now + 2 d`:** przy poprawnym `resetAt()` zawsze `resetAt(now) > now`, więc wygrywa pierwszy składnik i `max` niczego nie zmienia. Ograniczenie chroni przed błędem strefy czasowej w `resetAt()` (np. wynik w przeszłości). Wtedy dokument i tak żyje ≥ 48 h, czyli dłużej niż najdłuższa doba (25 h), z zapasem na błąd przesunięcia.
- **Stała długość 2 d** zamiast „2 doby kalendarzowe": prostsze i wystarczające. Po zmianie czasu `expireAt` wypada o 23:00 lub 01:00 czasu lokalnego, co nie ma znaczenia dla limitu.
- **Faktyczna retencja:** `expireAt − now` ∈ (48 h; 73 h] (najwięcej przy zapisie tuż po północy w dobie 25-godzinnej), plus do ok. 24 h opóźnienia TTL. Razem do ok. 4 dni od ostatniego użycia (opis w polityce prywatności: security, rejestr D10).
- v0.1 stosowała `now + 30 d` (dosłownie „30 dni od ostatniej aktualizacji"). Security (O4-b, SEC-34) uznał, że 30 dni nie ma celu: po północy licznik nie służy limitowi i jest nadpisywany co dobę (minimalizacja i ograniczenie przechowywania, art. 5 ust. 1 lit. c i e RODO). Zmiana dotyczy tylko stałej i funkcji w kodzie; schemat i polityka TTL zostają.

Przykłady (wyliczone na obecnym `resetAt()` z `limits.ts`; czasy UTC, w nawiasie Europe/Warsaw):

| `now` | `resetAt(now)` | `expireAt` | `expireAt − now` | Przypadek |
|---|---|---|---|---|
| 2026-11-18T09:00:00Z (10:00 CET) | 2026-11-18T23:00:00Z | 2026-11-20T23:00:00Z | 62 h | zwykła doba |
| 2026-11-18T22:59:59Z (23:59:59 CET) | 2026-11-18T23:00:00Z | 2026-11-20T23:00:00Z | 48 h + 1 s | ostatnia sekunda doby |
| 2026-11-18T23:00:00Z (00:00:00 CET, 19.11) | 2026-11-19T23:00:00Z | 2026-11-21T23:00:00Z | 72 h | pierwsza sekunda doby |
| 2026-03-28T23:00:00Z (00:00 CET, 29.03) | 2026-03-29T22:00:00Z | 2026-03-31T22:00:00Z | 71 h | doba 23 h (zmiana na czas letni) |
| 2026-03-29T21:59:59Z (23:59:59 CEST) | 2026-03-29T22:00:00Z | 2026-03-31T22:00:00Z | 48 h + 1 s | koniec doby 23 h |
| 2026-10-24T22:00:00Z (00:00 CEST, 25.10) | 2026-10-25T23:00:00Z | 2026-10-27T23:00:00Z | 73 h | doba 25 h (zmiana na czas zimowy) |
| 2026-10-25T22:59:59Z (23:59:59 CET) | 2026-10-25T23:00:00Z | 2026-10-27T23:00:00Z | 48 h + 1 s | koniec doby 25 h |

## 3. Pola TTL per kolekcja

| Kolekcja (grupa) | Pole TTL | Typ | Wartość ustawiana przez | Kiedy ustawiane | Efekt |
|---|---|---|---|---|---|
| `usage` (`usage/{uid}`) | **`expireAt`** | Timestamp | `generatePlan` (P3-05) | przy **każdym** zapisie dokumentu w transakcji (rezerwacja slotu i zwrot slotu): `usageExpireAt(now)` = `max(resetAt(now) + 2 d, now + 2 d)` (pkt 2.1) | usunięcie 48–73 h (+ do ok. 24 h opóźnienia TTL) po ostatnim użyciu AI, razem do ok. 4 dni |
| `usage_global` (`usage_global/{yyyy-mm-dd}`) | `expireAt` (bez zmian) | Timestamp | `generatePlan` (P3-05) | przy każdym zapisie: czas serwera + 7 dni | usunięcie ok. 7 dni po ostatnim zapisie danej doby |
| `users/{uid}/consents` | **brak TTL** | – | – | – | do usunięcia konta (D3, Q9, ADR-0002 Aneks A pkt 1) |
| `config` | **brak TTL** | – | – | – | stała |

Pole `updatedAt` w `usage/{uid}` zostaje jako znacznik diagnostyczny (model danych v0.4). **Nie ma** na nim polityki TTL ani indeksu. Typ `expireAt` musi być `Timestamp` (Admin SDK: `Timestamp.fromDate(...)`). Dokument bez tego pola albo z polem innego typu (np. string ISO) **nie jest usuwany** przez TTL.

### 3.1. Docelowy kształt dokumentów

```
usage/{uid}
  day        string     "YYYY-MM-DD" (Europe/Warsaw, warsawDay)
  count      int        0..perUserDailyLimit
  released   int        0..2  zwroty slotu w tej dobie (MAX_RELEASES_PER_DAY); bez indeksu
  updatedAt  timestamp  czas serwera ostatniego zapisu (diagnostyka)
  expireAt   timestamp  max(resetAt(updatedAt) + 2 d, updatedAt + 2 d)  ← polityka TTL

usage_global/{yyyy-mm-dd}
  count      int
  expireAt   timestamp  czas serwera ostatniego zapisu + 7 dni  ← polityka TTL
```

Dane osobowe: `usage/{uid}` = D10 (UID w ścieżce, `day`, `count`). `expireAt` i `updatedAt` to metadane retencji, nie nowa kategoria danych. **Nie wymaga nowego wpisu** w rejestrze, wystarczy doprecyzowanie pola w D10 (security).

### 3.2. Reguły zapisu dla P3-05 (wymagania dla mobile-dev)
1. W transakcji rezerwacji odczyt `usage/{uid}` i `usage_global/{today}`. Jeśli `usage.day ≠ today`, licznik startuje od 0 (`effectiveCount`). Zapis przez `set` z pełnym kształtem: `day = today`, `count`, `updatedAt = now`, `expireAt = usageExpireAt(now)` (pkt 2.1).
2. `usage_global/{today}`: `count + 1`, `expireAt = now + 7 d`.
3. Zwrot slotu (błąd systemu po rezerwacji, ADR-0002): osobna transakcja; zmniejsza `count` **tylko gdy `day` nadal = doba rezerwacji** (po północy nie zwraca slotu do nowej doby), ustawia ponownie `updatedAt = now` i `expireAt = usageExpireAt(now)` (ta sama doba, więc to samo `resetAt`; wartość nie maleje). Gdy `day` ≠ doba rezerwacji, zwrot **nie zapisuje** dokumentu: `expireAt` z rezerwacji już wypada po końcu tamtej doby.
   **Limit zwrotów (v0.3, O-TAM18-3):** zwrot tylko gdy `released < 2` (`MAX_RELEASES_PER_DAY`); wtedy `count − 1` i `released + 1` w tej samej transakcji. Przy `released = 2` zwrot nic nie zapisuje (próba zostaje wliczona). Rezerwacja zapisuje `released` przepisane z dokumentu tej doby, a w nowej dobie `released = 0` (`effectiveReleased`). Wartość zniekształcona (nie liczba całkowita) liczy się jako 0. Zwrot dotyczy wyłącznie `usage/{uid}`: **`usage_global/{day}.count` nigdy nie maleje** (bezpiecznik kosztu). Pole `released` nie jest używane w zapytaniach, więc nie wymaga własnego indeksu ani zmiany `backend/firestore.indexes.json`.
4. `now` = czas serwera funkcji (`deps.now()`), nie czas klienta.
5. Stałe retencji jako nazwane stałe w `limits.ts` (np. `USAGE_RETENTION_AFTER_RESET_MS = 2 × 86 400 000`, `GLOBAL_RETENTION_MS = 7 × 86 400 000`) i czyste funkcje: `usageExpireAt(now): Date` = `max(resetAt(now) + 2 d, now + 2 d)`, `globalExpireAt(now): Date` = `now + 7 d`. Testy jednostkowe wg pkt 7. Zapis do Firestore jako `Timestamp.fromDate(usageExpireAt(now))`.
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
- Jednostkowe (vitest, bez emulatora; wartości oczekiwane z tabeli w pkt 2.1):
  - `usageExpireAt(now) > resetAt(now)` oraz `usageExpireAt(now) − resetAt(now) = 2 d` dla: 23:59:59 Europe/Warsaw w zwykłej dobie (2026-11-18T22:59:59Z), 00:00:00 (2026-11-18T23:00:00Z) oraz w dniach zmiany czasu – 2026-03-29, doba 23 h (2026-03-28T23:00:00Z, 2026-03-29T21:59:59Z) i 2026-10-25, doba 25 h (2026-10-24T22:00:00Z, 2026-10-25T22:59:59Z);
  - `48 h < usageExpireAt(now) − now ≤ 73 h` dla tych samych chwil (dokładnie: 48 h + 1 s, 72 h, 71 h, 73 h);
  - dolne ograniczenie: przy `resetAt` podmienionym na chwilę w przeszłości (np. `now − 1 h`) wynik = `now + 2 d`;
  - `globalExpireAt(now) − now = 7 d`.
- Emulator (przez `.farm/test-lock.ps1`): po rezerwacji `usage/{uid}` ma `expireAt` typu Timestamp; zwrot slotu odświeża `expireAt`; dokument z `day` = wczoraj daje `effectiveCount` = 0. Emulator Firestore **nie wykonuje TTL**, więc samego usuwania nie testujemy lokalnie.
- Dev (po wdrożeniu): dokument syntetyczny `usage/test-ttl` z `expireAt` = teraz − 1 min powinien zniknąć w ciągu ok. 24 h; dokument z `expireAt` = teraz + 3 d pozostaje.

## 8. Wpływ na inne dokumenty (poza zakresem dba – propozycje)
- `docs/data/model-danych.md` pkt 3 (architect): `usage/{uid}` – `expireAt` (timestamp, polityka TTL; od v0.2 = `max(resetAt + 2 d, now + 2 d)`), `updatedAt` bez polityki TTL; `usage_global` – „`expireAt` = ostatni zapis + 7 dni".
- `docs/security/personal-data-register.md` D10 i `docs/data/przechowywanie-i-retencja.md` (security/architect): „TTL na `expireAt`"; od v0.2 (O4-b) retencja = `resetAt` + 2 dni (do ok. 4 dni od ostatniego użycia z opóźnieniem TTL). Zmiany robią równolegle architect i security. Po wdrożeniu usunąć adnotację „polityki TTL niewdrożone".
- `.farm/runbooks/P3-03-firebase.md` etap 8 i „Czego nie zrobiono" poz. 4 (orchestrator): odsyłacz do pkt 6 tego dokumentu.
