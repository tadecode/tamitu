# Otwarte pytania

Odpowiedzi właściciela z 2026-11-14 (przejście pytań jedno po drugim, przed decyzją G1).
Pytania N1–N10 pochodzą z `docs/requirements/open-questions-proposals.md`, S1–S12 z `docs/security/open-questions-security.md`.
Status „odpowiedziane" = decyzja właściciela zapisana; dokumenty faz muszą ją odzwierciedlić (patrz kolumna „Skutek").

| # | Pytanie | Zadaje | Status | Odpowiedź właściciela | Skutek dla dokumentów |
|---|---|---|---|---|---|
| 1 | Który model AI układa plan dnia? | architect | odpowiedziane | Gemini (kierunek); finalny wybór i koszty w ADR | zgodne z propozycją |
| 2 | AI bezpośrednio czy przez pośrednika? | architect | odpowiedziane | Przez pośrednika (np. Cloud Functions) | zgodne |
| 3 | Środowiska Firebase i budżety | architect, owner | odpowiedziane | dev + prod, region UE, alerty od startu; budżety ustawia właściciel | zgodne |
| 4 | Lokalizacja: do czego, czy w tle | analyst, security | odpowiedziane | Tylko link trasy, na żądanie, na pierwszym planie; bez tła i „w pobliżu" | zgodne |
| 5 | Gdzie plany i dane podróży | analyst, security | odpowiedziane | Lokalnie w MVP | zgodne |
| 6 | Reklamy i subskrypcje | analyst | odpowiedziane | Poza apką testową | zgodne |
| 7 | Języki i minimalna wersja Androida | analyst | odpowiedziane | **Polski + angielski** (min. API wg architekta) | **ZMIANA**: scope/US zakładały tylko polski; plany AI i UI w 2 językach, ryzyko/test |
| 8 | Logowanie w pierwszym wydaniu | analyst | odpowiedziane | Tylko Google | zgodne |
| N1 | Pola formularza | analyst | odpowiedziane | **Pola z wizji + data/godzina przylotu + preferencje: zainteresowania, budżet, tempo, liczba osób** | **ZMIANA**: US-004/005 zakładały brak preferencji; rejestr danych (nowe pola) |
| N2 | Maks. liczba dni | analyst | odpowiedziane | 14 | zgodne |
| N3 | Plany po wylogowaniu | analyst | odpowiedziane | Zostają, niewidoczne dla innego konta | zgodne |
| N4 | Limit generowań na dobę | analyst | odpowiedziane | 5 na konto na dobę (do zmiany po pomiarze kosztu) | zgodne |
| N5 | Osobna zgoda na AI | analyst | odpowiedziane | Tak, osobne pole zgody | zgodne |
| N6 | Bufor po przylocie | analyst | odpowiedziane | 3 h po lądowaniu; 0 przy aucie | zgodne |
| N7 / S9 | Usunięcie konta, eksport | analyst, security | odpowiedziane | Natychmiastowe usunięcie, bez eksportu w aplikacji; dostęp do danych na wniosek e-mailem | zgodne |
| N8 | Odbiorcy | analyst | odpowiedziane | Dorośli, indywidualni | zgodne |
| N9 | Tryb gościa | analyst | odpowiedziane | Nie | zgodne |
| N10 / S1 | Administrator danych, polityka | analyst, security | odpowiedziane (częściowo) | TadeCode, bez IOD; polityka na tadecode.pl/tamitu/prywatnosc przed testami zewnętrznymi. **Do uzupełnienia przez właściciela: nazwa, adres, NIP** | zgodne; dane firmy brakują |
| S2 | Lokalizacja przetwarzania Firebase i transfery | security | odpowiedziane | Security weryfikuje w dokumentacji Google w fazie 2 | zadanie dla security |
| S3 | Dowód zgód | security | odpowiedziane | Minimalny zapis serwerowy (UID, wersja, wartość, data); okres po usunięciu konta: [PRAWNIK] | zgodne |
| S4 | Kopia zapasowa Androida | security | odpowiedziane | Wyłączyć allowBackup; szyfrowanie bazy do decyzji architekta | zgodne |
| S5 | Wariant API modelu AI | security | odpowiedziane | Korporacyjny, region UE, DPA, bez trenowania (np. Vertex AI); warunki do potwierdzenia w ADR; do tego czasu brak prawdziwych danych do AI | zgodne; nadal warunek wstępny |
| S6 | Dokładność lokalizacji | security | odpowiedziane | **Dokładna** (domyślnie) | **ZMIANA**: security zakładał przybliżoną; uprawnienie precyzyjnej lokalizacji, rejestr D7, US-007 |
| S7 | Retencja logów | security | odpowiedziane | 30 dni, bez treści, UID jako skrót | zgodne |
| S8 | Skrzynka kontaktowa RODO | security | odpowiedziane | tamitu@tadecode.pl | uzupełnić politykę/checklistę |
| S10 | Regulamin | security | odpowiedziane | Tak, krótki, przed wydaniem publicznym [PRAWNIK] | zgodne |
| S11 | DPIA | security | odpowiedziane | MVP: raczej nie; ocena przy rozszerzeniach [PRAWNIK] | zgodne |
| S12 | Podstawa prawna logów/licznika, wiek | security | odpowiedziane | Uzasadniony interes (lit. f), tylko dorośli [PRAWNIK] | zgodne |

## Nowe pytanie wynikające z odpowiedzi (analityk, 2026-11-14)

| # | Pytanie | Zadaje | Status | Propozycja domyślna | Skutek |
|---|---|---|---|---|---|
| N11 | Doprecyzowanie po N1 i pyt. 7: (a) czy pola preferencji są obowiązkowe; (b) formaty: zainteresowania (lista predefiniowana czy tekst), budżet i tempo (np. 3 poziomy), liczba osób (zakres); (c) czy język planu wybiera się osobno od języka interfejsu | analyst | otwarte | (a) opcjonalne, z wartościami domyślnymi; (b) lista predefiniowana zainteresowań (minimalizacja danych, ochrona przed danymi wrażliwymi), budżet i tempo – 3 poziomy, liczba osób 1–10 (zakres do potwierdzenia); (c) język planu domyślnie = język interfejsu, z możliwością zmiany w formularzu | US-004, US-005; do czasu odpowiedzi obowiązuje propozycja |

## Nadal do wykonania przez właściciela
- Odpowiedź na N11 (może zostać przyjęta propozycja domyślna).
- Dane administratora (nazwa, adres, NIP) do polityki prywatności (S1).
- Potwierdzenie warunków przetwarzania u dostawcy AI przed wysyłką prawdziwych danych (S5, ADR).
- Porada prawnika w punktach oznaczonych [PRAWNIK] (S3, S10, S11, S12).

## Faza 2 – pytania architekta do właściciela (G2), 2026-11-15
Źródło: `docs/architecture/uwagi-dla-orchestratora.md`. Odpowiedzi właściciela z 2026-11-15 w sekcji poniżej tabeli (wszystkie Q1–Q12 odpowiedziane).

| # | Pytanie | Propozycja | ADR |
|---|---|---|---|
| Q1 | Lokalizacja: zostawić dokładną z uprawnieniem (opcja A, zgodnie z S6) czy link Maps bez `origin` (opcja C: Google Maps sam użyje bieżącej pozycji, zero uprawnień; wymaga testu na urządzeniu)? | C prostsza i bezpieczniejsza, ale zmienia S6/US-007; do decyzji wdrażamy A | 0007 |
| Q2 | Testy a App Check: wewnętrzna ścieżka Google Play (konto Play organizacji) czy sideload APK z wyłączonym App Check? | Ścieżka Play; do tego czasu App Check wyłączony na dev | 0002 |
| Q3 | Budżety: dev 20 PLN, prod 100 PLN/mies., alerty 50/90/100%, auto-wyłączenie AI przy 100%; limit globalny 50 generowań/dobę | akceptacja lub inne kwoty | 0003 |
| Q4 | Klasa modelu: start od Flash, ewentualnie Flash-Lite; ceny z `costs.md` (niezweryfikowane) jako podstawa? | akceptacja; ostateczny model po ewaluacji w fazie 3 | 0001 |
| Q5 | „Doba" limitu: dzień kalendarzowy Europe/Warsaw czy okno 24 h? | kalendarzowy | 0002 |
| Q6 | N11: lista 11 zainteresowań (0–5), budżet i tempo po 3 poziomy, liczba osób 1–10 (domyślnie 2), język planu = język UI z możliwością zmiany; `family_attractions` OK? | akceptacja | 0006 |
| Q7 | Szyfrowanie bazy lokalnej (SQLCipher, +kilka MB APK)? | tak | 0005 |
| Q8 | minSdk 26 (Android 8.0)? | 26 | 0007 |
| Q9 | Dowód zgód po usunięciu konta [PRAWNIK] | zapytać prawnika | 0004, 0005 |
| Q10 | Plan Blaze (karta) i konto rozliczeniowe TadeCode; nazwy projektów (`tamitu-dev-…`, `tamitu-prod-…`) | potwierdzić | 0003 |
| Q11 | Warunki dostawcy AI (SEC-15): lista w ADR-0001; do tego czasu prod tylko z danymi testowymi | wypełnić przed realnymi danymi | 0001 |
| Q12 | Anulowanie generowania nie zwraca slotu limitu, jeśli model już ruszył | tak | 0002 |

### Odpowiedzi właściciela na Q1–Q12 (2026-11-15)
| # | Odpowiedź | Skutek |
|---|---|---|
| Q1 | **A, test C później**: wdrażamy dokładną lokalizację (uprawnienia FINE+COARSE); wariant C (link bez `origin`) sprawdzany na urządzeniu w fazie 3 i ewentualnie upraszczamy | P3-07; security rekomendował C |
| Q2 | Ścieżka testowa Google Play (konto Play organizacji); do tego czasu sideload tylko dev, dane testowe, App Check wyłączony | zgodne |
| Q3 | dev 20 PLN, prod 100 PLN/mies., alerty 50/90/100%, auto-wyłączenie AI, limit globalny 50/dobę | zgodne |
| Q4 | Start od Flash, ostateczny wybór po ewaluacji w fazie 3; ceny do weryfikacji przed fazą 3 | zgodne |
| Q5 | Dzień kalendarzowy Europe/Warsaw | zgodne |
| Q6 / N11 / S13 | Zaakceptowano: preferencje opcjonalne; 11 zainteresowań z listy (0–5), bez wolnego tekstu; budżet i tempo 3 poziomy; liczba osób 1–10 (domyślnie 2); język planu = język UI z możliwością zmiany; `family_attractions` zostaje | N11 i S13 zamknięte |
| Q7 | Szyfrować bazę (SQLCipher) | zgodne |
| Q8 | minSdk 26 | zgodne |
| Q9 | Dowód zgód usuwany z kontem; zapytać prawnika | [PRAWNIK] |
| Q10 | Właściciel zakłada konto rozliczeniowe/Blaze i projekty przed fazą 3; nazwy tamitu-dev-… / tamitu-prod-… zaakceptowane | zadanie właściciela |
| Q11 | Właściciel potwierdza warunki dostawcy AI; do tego czasu `ALLOW_REAL_DATA=false` | SEC-15 |
| Q12 | Slot limitu nie wraca po anulowaniu, jeśli model już ruszył | zgodne |
