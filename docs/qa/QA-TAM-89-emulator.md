# QA TAM-89 (P3-05-EMU): limity i zwroty `generatePlan` na emulatorach Firebase

**W skrócie:** 17 testów integracyjnych `generatePlan` na emulatorach (Auth + Firestore + Functions) z atrapą
modelu. **Wynik: 17/17 zielone** (dwa pełne przebiegi przez `.farm/test-lock.ps1`, ok. 2 min każdy). Rezerwacja,
limity 5/25, zwroty po błędach, zwroty po przeciążeniu (ADR-0016) i kolejność „zgoda przed limitem” działają
zgodnie z kontraktem. **Jedno znalezisko (F-1):** przy wielu równoległych wywołaniach transakcja rezerwacji
bywa przerywana (ABORTED), a funkcja odpowiada wtedy ogólnym `internal` zamiast kodem kontraktu. Limitów to nie
łamie: nic nie jest zapisywane i slot nie przepada. Koszt: 0 zł (atrapa, projekt `demo-*`), bez danych osobowych.

## 1. Przebieg

| Pole | Wartość |
|---|---|
| Data | 2026-11-26 |
| Gałąź | `chore/TAM-89-testy-emulatora` (PR #184), atrapa Vertex mobile-dev z `9a07ae3` |
| Plik testów | `tests/firebase-emulator/p3-05-generate-plan.int.mjs` (Node 22+, `node:test`, bez zależności) |
| Uruchomienie | `.farm/test-lock.ps1 -Resource firebase-emulators` → `backend/functions/test/emulator/run-emulator-tests.ps1 -Tests tests/firebase-emulator/p3-05-generate-plan.int.mjs` |
| Konfiguracja | `config/runtime`: `perUserDailyLimit=5`, `globalDailyLimit=25`, `aiEnabled=true`, `testUids` = konta testu; `testData=true` |
| Konta | syntetyczne z emulatora Auth (`qa-tam89-<uuid>@example.test`), nowe w każdym teście |
| Model | atrapa `vertex-fake.mjs` na 127.0.0.1:8787; scenariusze `valid`, `invalid`, `server_error`, `config_error`, `busy` |

Polecenie (z katalogu głównego repozytorium):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .farm/test-lock.ps1 -Resource firebase-emulators -Command "powershell -NoProfile -ExecutionPolicy Bypass -File backend/functions/test/emulator/run-emulator-tests.ps1 -Tests tests/firebase-emulator/p3-05-generate-plan.int.mjs"
```

## 2. Co pokryte

| Id | Wymaganie | Co sprawdza test | Wynik |
|---|---|---|---|
| EMU-01 | rezerwacja | `usage/{uid}`: `day`, `count=1`, `released=0`, `busyReleased=0`, `expireAt` i `updatedAt` jako Timestamp (TTL), `expireAt` 2–3 doby naprzód; `usage_global/{dzień}`: `count=1`, `expireAt` = teraz + 7 dób | ✔ |
| EMU-02 | dokument z wczoraj = 0 | wczorajszy dokument z `count=5`, `released=2`, `busyReleased=10` → plan przechodzi, wszystkie liczniki od zera | ✔ |
| EMU-03 | limit konta 5/dobę | plany 1–5 (malejące `remainingToday`), 6. → `limit_exceeded` (`resource-exhausted`, `details.limit=5`, `resetAt` w przyszłości), bez wywołania modelu, `usage_global` bez zmiany | ✔ |
| EMU-04 | limit globalny 25/dobę | 5 kont × 5 planów = 25 prawdziwych rezerwacji, 26. (6. konto) → odrzucony, bez wywołania modelu i bez dokumentu `usage` | ✔ |
| EMU-05 | kolejność limitów | oba limity wyczerpane → wygrywa globalny (`ai_unavailable`) | ✔ |
| EMU-06 | zwrot po `ai_invalid_response` | 2 wywołania modelu, `slotReleased=true`, `count=0`, `released=1`, `usage_global=1` (bez zwrotu) | ✔ |
| EMU-07 | zwrot po `ai_unavailable` | 503 × 2 (prawdziwy backoff), `slotReleased=true`, `released=1`, `usage_global=1` | ✔ |
| EMU-08 | najwyżej 2 zwroty na dobę | trzy błędy: `slotReleased` = true, true, false; `count=1`, `released=2`, `usage_global=3`; potem udany plan z `remainingToday=3` | ✔ |
| EMU-09 | brak zwrotu przy `limit_exceeded` | liczniki bez zmian | ✔ |
| EMU-10 | przeciążenie (`ai_busy`) | 3 × 429, `slotReleased=true`, `retryAfterSec=60`; konto `count=0`, `released=0`, `busyReleased=1`; `usage_global=0` (zwrot) | ✔ |
| EMU-11 | bezpiecznik `busyReleased ≤ 10` | stan startowy `busyReleased=9`: 10. `ai_busy` → zwrot (`busyReleased=10`), 11. → `slotReleased=false`, `count=1`, `usage_global=1` | ✔ |
| EMU-12 | zwroty `ai_busy` osobno od zwrotów po błędach | przy `released=2` zwrot `ai_busy` nadal działa, `released` bez zmiany | ✔ |
| EMU-13 | zgoda przed limitem | brak zgód → `consent_required`, brak `usage/{uid}` i `usage_global`, 0 wywołań modelu | ✔ |
| EMU-14 | zgoda przed limitem | tylko zgoda na politykę (bez `ai_processing`) → `consent_required`, limit nieruszony | ✔ |
| EMU-15 | zgoda przed limitem | limit konta wyczerpany **i** brak zgód → `consent_required` (nie `limit_exceeded`) | ✔ |
| EMU-16 | transakcja, jedno konto | 7 równoległych wywołań: nigdy > 5 planów; licznik konta = liczba wywołań modelu = `usage_global`; różne `remainingToday`; przy pełnej obsłudze dokładnie 5 × ok i 2 × `limit_exceeded` | ✔ |
| EMU-17 | transakcja, limit globalny | 3 wolne sloty globalne, 10 równoległych wywołań z 5 kont: nigdy > 3 planów, `usage_global` = start + suma liczników kont = liczba wywołań modelu | ✔ (z F-1) |

Uwaga do zadania: w treści TAM-89 „26. globalny daje `limit_exceeded`”. Kontrakt mówi inaczej
(`docs/api/posrednik-api.md`, tabela błędów i reguła 1; `limits.decideQuota`): wyczerpany **limit globalny** to
`ai_unavailable` ze `slotReleased=true`, a `limit_exceeded` dotyczy tylko limitu konta. Test sprawdza kontrakt.

## 3. Znaleziska

### F-1. Przerwana transakcja rezerwacji daje `internal` zamiast kodu kontraktu (średnie)

- **Kroki:** 3 wolne sloty globalne, 10 równoległych `generatePlan` z 5 kont (EMU-17).
- **Wynik (sporadyczny):** w pierwszym przebiegu kilka, w kolejnym **7/10** odpowiedzi to `internal` po ok. 18–23 s,
  w ostatnim przebiegu ani jednej; w logu
  funkcji `errorClass=Error`, `errorCode=10` (gRPC ABORTED). Transakcja `reserveQuota` czyta `usage_global/{dzień}`,
  który współdzielą wszystkie konta, i po wyczerpaniu ponowień SDK się poddaje.
- **Oczekiwane:** kod z kontraktu (np. `ai_busy` z `retryAfterSec` albo `ai_unavailable`, w obu przypadkach
  `slotReleased=true`), żeby aplikacja pokazała właściwy komunikat zamiast ogólnego błędu.
- **Skutek:** limity są bezpieczne (przerwana transakcja nic nie zapisuje, test to sprawdza), ale użytkownik
  dostaje ogólny błąd i nie wie, że slot nie przepadł. Emulator blokuje pesymistycznie i przerywa częściej niż
  produkcja, ale ten sam kod ABORTED może wystąpić w produkcji przy kilku jednoczesnych generowaniach
  (`maxInstances=10`).
- **Propozycja:** nowe zadanie (architect → mobile-dev): przechwycić ABORTED/kontencję w `reserveQuota` i zwrócić
  kod kontraktu ze `slotReleased=true`; ewentualnie wpis w `posrednik-api.md`. Do tego czasu EMU-16/17 tolerują
  `internal` i wypisują diagnostykę `F-1`; po poprawce wystarczy usunąć `internal` z listy dozwolonych kodów.

### Uwaga o emulatorze (nie błąd aplikacji)

W jednym przebiegu emulator Functions nie uruchomił procesów roboczych dla części równoległych żądań
(„Failed to load function”) i nie odpowiedział. EMU-16/17 mają więc limit czasu 60 s na żądanie: niezmienniki
bezpieczeństwa (liczniki nigdy ponad limit, liczba wywołań modelu = zarezerwowane sloty) sprawdzają zawsze,
a dokładne liczby tylko wtedy, gdy emulator odpowiedział na wszystko. W przeciwnym razie test jest oznaczany jako
pominięty z diagnostyką, a nie zielony.

## 4. Czego nie pokryto

- **Zmiana doby w trakcie generowania** (rezerwacja przed północą, zwrot po niej → `stale_day`): wymaga sterowania
  zegarem funkcji, czego emulator nie daje. Pokryte testami jednostkowymi (`limits.test.ts`).
- **Usuwanie przez TTL:** emulator Firestore nie wykonuje polityk TTL; sprawdzono tylko, że `expireAt` jest typu
  Timestamp i ma właściwą wartość. Sama polityka TTL to konfiguracja w konsoli (`firestore-ttl-indexes.md`).
- **10 prawdziwych zwrotów `ai_busy`:** EMU-11 zaczyna od zapisanego `busyReleased=9` (10 przebiegów z backoffem
  to ok. 100 s); granica 10/11 sprawdzona na prawdziwych wywołaniach.
- **`release_failed`** (błąd zapisu przy zwrocie), scenariusze atrapy `timeout`, `bad_body`, `blocked`,
  `aiEnabled=false`, App Check: poza zakresem TAM-89 albo pokryte testami jednostkowymi.
- **Godziny tuż przed północą (Warszawa):** test liczy dzień tak jak funkcja; przebieg przez północ może dać
  fałszywy błąd, wtedy wystarczy powtórzyć.
- **CI:** testy emulatora nie są w CI (Java, porty, kolejka). Uruchamiane lokalnie przez blokadę farmy.
- **Prawdziwy Vertex:** celowo nie (0 kosztów).

## 5. Dla orkiestratora

- Zadania – status: TAM-89 – testy gotowe w PR #184 (17/17 zielone lokalnie), PR gotowy do recenzji.
- Zadania – nowe: „F-1: kontencja transakcji rezerwacji → kod kontraktu zamiast `internal`” (architect → mobile-dev;
  po poprawce QA usuwa tolerancję `internal` w EMU-16/17).
- Pytania otwarte – nowe: brak (rozbieżność „26. globalny = `limit_exceeded`” w treści zadania rozstrzyga kontrakt:
  `ai_unavailable`).
