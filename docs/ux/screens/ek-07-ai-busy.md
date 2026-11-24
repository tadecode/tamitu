# Ekran: EK-07 – stan „Asystent AI chwilowo przeciążony” (`ai_busy`)

- Status: **szkic** – do uzgodnienia z architektem (pytanie UX-TAM98-1) i zatwierdzenia przez właściciela; potem `ux-ready` dla TAM-99
- Historyjki: US-005, US-011
- Autor: ux · Data: 2026-11-24 · Wersja: 0.1 · Zadanie: TAM-98 (P3-05-429-UX)
- Makieta: [`mockups/ek-07-ai-busy.html`](../mockups/ek-07-ai-busy.html) (PL/EN, jasny/ciemny, tekst 100–200%, żywe odliczanie)
- Źródła: ADR-0016 pkt 10–14, `docs/api/posrednik-api.md` v0.6 (pkt 2 tabela kodów, „Slot limitu i zwrot próby” reguła 7, pkt 6), `.farm/log/2026-11-21/1500-architect-TAM-96.md`, [EK-07](ek-07.md), [EK-05](ek-05.md), [EK-16](ek-16.md)

## W skrócie (dla nietechnicznych)
Czasem asystent AI Google jest chwilowo zajęty i nie przyjmuje zapytań. Wtedy nie wracamy od razu do formularza
z błędem, tylko zostajemy na ekranie generowania i mówimy: „Nasz asystent AI jest chwilowo przeciążony.
Spróbujemy ponownie za minutę.” Odliczamy minutę i **raz** sami ponawiamy. Użytkownik może nie czekać
(„Spróbuj teraz”) albo zrezygnować („Wróć do formularza”, dane zostają). Jeśli i to się nie uda, zostaje sam
przycisk – bez kolejnego odliczania. Taka próba zwykle **nie zużywa** dziennego limitu i mówimy o tym tylko wtedy,
gdy serwer to potwierdzi.

## Cel
Przeczekać chwilowe przeciążenie AI bez frustracji: wiedzieć, co się dzieje, ile to potrwa i co można zrobić.

## Wejście i wyjście
- Skąd: EK-07 (ładowanie), gdy `generatePlan` zwróci `details.code = ai_busy` (`unavailable`). Stan jest **częścią EK-07**
  (ten sam ekran modalny, pasek „Nowa podróż”), nie powrotem do EK-05 – tylko tak odliczanie i automat mają sens.
- Dokąd:
  - koniec odliczania (ekran na pierwszym planie) → EK-07 ładowanie („Próbujemy ponownie…”) → wynik jak zwykle;
  - „Spróbuj teraz” → EK-07 ładowanie (zastępuje automat, nie dodaje drugiego);
  - wynik ponowienia: sukces → EK-08; `ai_busy` → stan **B** (ręczny) na tym ekranie; każdy inny kod → mapowanie
    EK-16 (EK-05 z CMP-13, limit, aktualizacja, sesja…);
  - „Wróć do formularza” lub **wstecz systemowe** → EK-05 z zachowanymi danymi, **bez dialogu** (nic się nie
    generuje, więc nie ma czego przerywać), bez komunikatu na EK-05. Zaplanowane ponowienie zostaje anulowane;
  - zabicie procesu → jak EK-07 (U6): nic nie zapisano, start od EK-04; stan nie jest odtwarzany.

## Wzorzec i komponenty
- Wzorzec (`patterns.md`): błąd z ponowieniem (pkt 5) – **wyjątek** od „ponowienie tylko z decyzji użytkownika”
  zatwierdzony w ADR-0016 pkt 13 (jedno ponowienie, bo próba `ai_busy` nie zużywa limitu); ładowanie (pkt 4) dla
  samego ponowienia.
- Komponenty (tylko z biblioteki):
  - CMP-01 pasek górny (jak EK-07, bez strzałki wstecz),
  - **CMP-18 stan ekranu, wariant „Przeciążenie”** (nowy wariant, dopisany w `components/state-view.md` v0.2):
    ikona `ai` (sparkles), tytuł, opis, odliczanie, przycisk tonalny,
  - **CMP-17 wskaźnik, wariant „Liniowy określony – odliczanie”** (nowy wariant, `components/progress.md` v0.2):
    pasek, który się opróżnia w rytm odliczania (czas, nie fałszywy procent),
  - CMP-02 przyciski: tonalny „Spróbuj teraz” (w CMP-18), outlined „Wróć do formularza” na dole (w miejscu „Anuluj” z EK-07),
  - CMP-15 dialog anulowania – tylko w trakcie ponowienia (stan C, bez zmian względem EK-07).

## Układ
Makieta: [`mockups/ek-07-ai-busy.html`](../mockups/ek-07-ai-busy.html). Zasady: `layout.md`.
Pasek „Nowa podróż”; w treści, wyśrodkowane pionowo (CMP-18): ikona 48 dp → 16 dp → tytuł `headlineSmall` →
8 dp → opis `bodyMedium` (2 zdania: co się stanie + zdanie o limicie) → 24 dp → **odliczanie** (`titleMedium`,
cyfry o stałej szerokości, np. „Ponowna próba za 0:42”) → 8 dp → pasek CMP-17 (4 dp, szerokość tekstu, maks. 320 dp)
→ 24 dp → „Spróbuj teraz” (tonalny). Na dole „Wróć do formularza” (outlined, pełna szerokość, 48 dp) – w tym samym
miejscu co „Anuluj” w EK-07, więc kciuk trafia w znane miejsce.
- Jedno główne działanie: automat. „Spróbuj teraz” jest tonalny (nie wypełniony), „Wróć” – outlined.
- Medium/expanded: jak EK-07 – kolumna wyśrodkowana, tekst maks. 320 dp, przycisk dolny maks. 360 dp.
- Skala 200%: treść przewija się, przycisk dolny zostaje przyklejony (jest jeden); odliczanie i przycisk tonalny w treści.

## Dane na ekranie
| Pole | Źródło | Wymagane | Uwagi |
|---|---|---|---|
| Kod `ai_busy` | `generatePlan` → `details.code` | tak | **nie wyświetlany** |
| `retryAfterSec` | `details.retryAfterSec` | tak (zawsze przy `ai_busy`) | przyjmowane 30–120; brak lub poza zakresem → 60 (ADR-0016 pkt 10). Dziś zawsze 60 |
| `slotReleased` | `details.slotReleased` | tak (zawsze przy `ai_busy`) | `true` / `false` / brak → zdanie o limicie i decyzja o automacie (niżej) |
| Termin ponowienia | aplikacja: chwila odebrania odpowiedzi + `retryAfterSec` | – | liczony od **zegara monotonicznego**, nie od tyknięć; przeżywa przejście w tło |
| Licznik automatu | aplikacja (pamięć kontrolera) | – | 0/1 na **jedno wysłanie formularza**; „Spróbuj teraz” w odliczaniu też go zużywa |
| Dane formularza | pamięć (EK-05) | tak | do ponowienia (nowy `requestId`) i do powrotu; bez danych osobowych na ekranie |

Brak nowych danych osobowych, nowych zdarzeń analitycznych i nowych wywołań poza ponowieniem `generatePlan`.

## Stany
| Stan | Kiedy | Co widzi użytkownik | Teksty (klucze l10n) |
|---|---|---|---|
| **A. Odliczanie** | pierwsze `ai_busy` po wysłaniu formularza, `slotReleased = true`, automat niewykorzystany | ikona, tytuł, opis „Spróbujemy ponownie za minutę. Nie musisz nic robić.” + zdanie o limicie, odliczanie m:ss i pasek, „Spróbuj teraz”, na dole „Wróć do formularza” | `generationBusyTitle`, `generationBusyBodyAuto`, `generationBusyQuotaReleased`, `generationBusyCountdown`, `generationBusyCountdownA11y`, `generationBusyTryNow`, `generationBusyBack` |
| **C. Ponawianie** | koniec odliczania (na pierwszym planie) lub „Spróbuj teraz” w stanie A/B/D | zwykły stan ładowania EK-07, pierwszy tekst pomocniczy „Próbujemy ponownie…”, potem rotacja jak EK-07; „Anuluj” z dialogiem jak EK-07 | `generationTitle`, `generationRetrying`, `generationMayTakeTime`, `generationStep2..3` |
| **B. Ręcznie po nieudanym ponowieniu** | ponowienie (automat lub ręczne) znów skończyło się `ai_busy` | ikona, tytuł „Nasz asystent AI nadal jest przeciążony”, opis „Spróbuj ponownie za chwilę…” + zdanie o limicie, **bez odliczania i bez paska**, „Spróbuj teraz”, „Wróć do formularza”. Kolejne `ai_busy` po „Spróbuj teraz” → znów B (bez automatu) | `generationBusyStillTitle`, `generationBusyBodyManual`, `generationBusyQuota*`, `generationBusyTryNow`, `generationBusyBack` |
| **D. Powrót z tła po terminie** | termin ponowienia minął, gdy aplikacja była w tle (automat się nie wykonał) | jak B, ale tytuł z A i opis „Gdy aplikacja była w tle, nie ponawialiśmy próby. Możesz spróbować teraz.” + zdanie o limicie | `generationBusyTitle`, `generationBusyBodyPaused`, `generationBusyQuota*`, `generationBusyTryNow`, `generationBusyBack` |
| **E. Bez automatu (limit niezwrócony)** | pierwsze `ai_busy`, ale `slotReleased = false` (bezpiecznik 10/dobę) lub brak pola | jak B z tytułem z A: opis ręczny + „Ta próba została wliczona do dzisiejszego limitu.” (albo „mogła zostać…”); **bez odliczania i automatu** – propozycja UX-TAM98-1 | `generationBusyTitle`, `generationBusyBodyManual`, `generationBusyQuotaCounted` / `generationBusyQuotaUnknown` |
| Ładowanie | – | stan C | – |
| Pusty | – | n/d | – |
| Sukces | ponowienie udane | EK-08 jak zwykle | – |
| Inny błąd po ponowieniu | `ai_unavailable`, `ai_invalid_response`, `limit_exceeded`, timeout, brak sieci… | mapowanie EK-16 → EK-05 z CMP-13 (formularz z przyciskiem „Generuj plan” = „sam przycisk”) | klucze EK-16 |
| Brak sieci przy ponowieniu | ponowienie nie doszło do serwera | jak wyżej: EK-05 + `commonOfflineNotice` (limit niezużyty) | EK-16 |

### Zachowanie w tle (doprecyzowanie ADR-0016 pkt 11)
1. Odliczanie liczy się od terminu (zegar monotoniczny). Przejście w tło nie zatrzymuje czasu.
2. Automat startuje **tylko** gdy w chwili terminu aplikacja jest na pierwszym planie (stan cyklu życia `resumed`;
   zablokowany ekran = tło).
3. Powrót **przed** terminem → odliczanie trwa dalej od pozostałego czasu, automat jak w A.
4. Powrót **po** terminie → stan D (sam przycisk, bez nowego odliczania, automat uznany za wykorzystany).
5. Bez powiadomień systemowych, bez pracy w tle, bez wybudzania.
6. Ponowienie trwające w chwili przejścia w tło → jak EK-07 (U6): trwa do 120 s, po powrocie wynik lub błąd.

### Zdanie o limicie (ADR-0016 pkt 14, `posrednik-api.md` pkt 6)
| `slotReleased` | Zdanie | Automat |
|---|---|---|
| `true` | „Ta próba nie wlicza się do limitu.” | tak (stan A) |
| `false` | „Ta próba została wliczona do dzisiejszego limitu.” | **nie** (stan E) – propozycja UX-TAM98-1 |
| brak | „Ta próba mogła zostać wliczona do dzisiejszego limitu.” | **nie** (stan E) – propozycja UX-TAM98-1 |

Uzasadnienie UX-TAM98-1: wyjątek od „bez automatycznych ponowień” stoi na tym, że `ai_busy` nie zużywa limitu
(ADR-0016 pkt 13). Gdy serwer tego nie potwierdza, automat mógłby zużyć limit bez decyzji użytkownika
(`patterns.md` pkt 5). Przypadek rzadki (11. `ai_busy` w dobie). W stanach B i D zdanie o limicie dotyczy
**ostatniej** odpowiedzi.

Nie piszemy o kosztach, Google ani „429” (EK-16, przegląd security: bez szczegółów technicznych).

## Działania
| Element | Akcja | Wynik |
|---|---|---|
| (czas) koniec odliczania, pierwszy plan | automatycznie | stan C, `generatePlan` z tymi samymi danymi i **nowym** `requestId`; licznik automatu = 1 |
| „Spróbuj teraz” (A) | dotknięcie | odliczanie anulowane, stan C; licznik automatu = 1 (zastępuje automat) |
| „Spróbuj teraz” (B, D, E) | dotknięcie | stan C; po `ai_busy` → B |
| „Wróć do formularza” / wstecz systemowe (A, B, D, E) | dotknięcie | EK-05 z danymi, bez dialogu; zaplanowane ponowienie anulowane |
| „Anuluj” / wstecz (C) | dotknięcie | dialog CMP-15 jak EK-07 (P4) |
| Ponowne „Generuj plan” w EK-05 | nowe wysłanie formularza | nowy licznik automatu (jedno automatyczne ponowienie na jedno wysłanie) |

Podwójne dotknięcie „Spróbuj teraz” – przycisk znika z chwilą przejścia do C, więc drugie wywołanie nie powstaje.

## Teksty
| Klucz l10n | PL | EN |
|---|---|---|
| `generationBusyTitle` | Nasz asystent AI jest chwilowo przeciążony | Our AI assistant is busy right now |
| `generationBusyStillTitle` | Nasz asystent AI nadal jest przeciążony | Our AI assistant is still busy |
| `generationBusyBodyAuto` | Spróbujemy ponownie za {minutes, plural, one{minutę} few{{minutes} minuty} many{{minutes} minut} other{{minutes} minuty}}. Nie musisz nic robić. | We'll try again in {minutes, plural, one{a minute} other{{minutes} minutes}}. You don't need to do anything. |
| `generationBusyBodyManual` | Spróbuj ponownie za chwilę. Twoje dane w formularzu zostały zachowane. | Please try again in a moment. Your trip details are kept in the form. |
| `generationBusyBodyPaused` | Gdy aplikacja była w tle, nie ponawialiśmy próby. Możesz spróbować teraz. | We didn't retry while the app was in the background. You can try now. |
| `generationBusyQuotaReleased` | Ta próba nie wlicza się do limitu. | This attempt doesn't count towards your limit. |
| `generationBusyQuotaCounted` | Ta próba została wliczona do dzisiejszego limitu. | This attempt counted towards today's limit. |
| `generationBusyQuotaUnknown` | Ta próba mogła zostać wliczona do dzisiejszego limitu. | This attempt may have counted towards today's limit. |
| `generationBusyCountdown` | Ponowna próba za {time} | Retrying in {time} |
| `generationBusyCountdownA11y` | Ponowna próba za {seconds, plural, one{1 sekundę} few{{seconds} sekundy} many{{seconds} sekund} other{{seconds} sekundy}} | Retrying in {seconds, plural, one{1 second} other{{seconds} seconds}} |
| `generationBusyTryNow` | Spróbuj teraz | Try now |
| `generationBusyBack` | Wróć do formularza | Back to the form |
| `generationRetrying` | Próbujemy ponownie… | Trying again… |

- `{minutes}` = `retryAfterSec` / 60 zaokrąglone w górę (30–60 s → „minutę”, 61–120 s → „2 minuty”). Dokładny czas pokazuje odliczanie.
- `{time}` = `m:ss` bez zera wiodącego minut: `1:00`, `0:42`, `0:05` (przy 120 s: `2:00`). Cyfry o stałej szerokości
  (`FontFeature.tabularFigures`), żeby tekst nie „skakał”.
- Wyświetlany opis = `generationBusyBody*` + spacja + `generationBusyQuota*` (dwa klucze, nie sklejać w tłumaczeniu).
- Sens zaproponowany przez właściciela („Nasz asystent AI jest chwilowo przeciążony. Spróbujemy ponownie za minutę.”)
  jest zachowany: tytuł + pierwsze zdanie opisu.
- PL jest ok. 25% dłuższy; sprawdzone w makiecie przy 360 dp i 200% (tytuł do 3 linii, bez ucięć).

## Dostępność
- **Fokus:** po wejściu w stan A/B/D/E fokus TalkBack na tytule (nagłówek, CMP-18). Kolejność: tytuł → opis → odliczanie → „Spróbuj teraz” → „Wróć do formularza”.
- **Odliczanie:** tekst widoczny zmienia się co 1 s, ale **nie** jest regionem na żywo. Ma własną etykietę
  `generationBusyCountdownA11y` (pełne słowa, nie „0:42”), czytaną przy najechaniu. Osobne uprzejme ogłoszenie
  (`SemanticsService.announce`, polite) **co 15 s** pozostałego czasu, w pełnych wielokrotnościach 15
  (dla 60 s: przy 45, 30 i 15 s; pierwsze ogłoszenie pomijamy, bo tytuł i opis są czytane przy wejściu).
  Nie ogłaszamy, gdy TalkBack właśnie czyta (polite czeka w kolejce). W chwili ponowienia ogłoszenie
  „Próbujemy ponownie…” (fokus na tytuł stanu C, jak EK-07).
- **Pasek odliczania** ukryty przed TalkBack (powtarza tekst). Przy „Usuń animacje” pasek skacze co 1 s bez płynnego przejścia.
- Kolor nie jest jedynym nośnikiem: stan opisany tytułem i tekstem, ikona dekoracyjna.
- **Kontrast:** wyłącznie istniejące pary tokenów – `onSurface`/`surface`, `onSurfaceVariant`/`surface`
  (≥ 7,8:1 w obu motywach), `onSecondaryContainer`/`secondaryContainer` (tonalny), `primary` na `surfaceContainerHighest`
  dla paska (element nietekstowy, ≥ 3:1 jak EK-07). Nowych par brak (`accessibility.md` bez zmian w tabeli).
- **Cele dotyku:** „Spróbuj teraz” i „Wróć do formularza” min. 48 dp, odstęp ≥ 8 dp.
- **Skalowanie 200%:** odliczanie nie ma stałej szerokości; treść przewija się.
- Czas na reakcję: użytkownik **nie musi** nic robić w limicie czasu (WCAG 2.2.1) – automat jest dodatkiem, a „Spróbuj teraz” działa bez limitu.

## Prywatność i zgody
Brak nowych danych osobowych, uprawnień i zgód. Ponowienie wysyła te same dane co pierwsze wysłanie (po zgodzie
na AI z EK-06). Teksty nie ujawniają przyczyny technicznej ani kosztowej. Przegląd security: nie wymagany
(ewentualnie przy okazji przeglądu EK-16).

## Uzgodnienie z architektem
Zgodne z ADR-0016 pkt 10–14 i `posrednik-api.md` v0.6. Do potwierdzenia przez architekta (przez orkiestratora):
- **UX-TAM98-1:** brak automatu, gdy `slotReleased ≠ true` (stan E). Domyślnie tak, jak w tej specyfikacji.
- Pkt 11 („UX może to doprecyzować”): stan D i reguły tła powyżej.
- Ponowienie z `ai_busy` przyjmowane tylko na ekranie EK-07; inne ekrany nie wywołują `generatePlan`.

## Pytania otwarte
UX-TAM98-1 (w `.farm/log/2026-11-24/1700-ux-TAM-98.md`, sekcja „Dla orkiestratora”).
