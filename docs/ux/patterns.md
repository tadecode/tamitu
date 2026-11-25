# Wzorce projektowe – Tamitu

- Status: szkic, wersja 0.1 (2026-11-16, ux, P3-14b krok 1). Niezależne od wariantu marki.
- Każdy ekran (`screens/`, krok 2) wskazuje użyty wzorzec. Komponenty: `components/index.md` (CMP-xx).

---

## 1. Lista i szczegóły

- **Kiedy:** zbiór rzeczy tego samego typu, z których użytkownik wybiera jedną: plany (EK-04 → EK-08), Ustawienia (EK-12 → EK-13).
- **Kiedy nie:** pojedynczy obiekt (od razu szczegóły), wybór wartości (arkusz dolny / pole wyboru).
- **Składniki:** CMP-01, CMP-12 (karta planu) lub CMP-11 (ustawienia), CMP-03 (główne działanie listy), CMP-17 (szkielet), CMP-18 (pusty/błąd); szczegóły: CMP-01 ze wstecz, CMP-12 (podsumowanie), CMP-19, CMP-20.
- **Zasady:** lista od najnowszego (US-008); cała karta jest celem dotyku; szczegóły otwierają się na nowym ekranie (compact). Na expanded kierunek: lista i szczegóły obok siebie (poza MVP).

## 2. Formularz

- **Kiedy:** zebranie kilku danych przed działaniem: EK-05 (nowa podróż).
- **Kiedy nie:** jedna decyzja (dialog), jeden wybór (arkusz dolny).
- **Składniki:** CMP-04, CMP-05, CMP-06, CMP-07, CMP-08, CMP-02 (wypełniony „Generuj plan" na dole), CMP-13 (np. brak sieci).
- **Zasady:**
  - jedno pole = jedna rzecz; etykieta zawsze widoczna (nie tylko placeholder);
  - sekcje: „Dokąd" (cel, nocleg) → „Kiedy i jak" (dni, dojazd, data, godzina, lotnisko, numer lotu) → „Preferencje (opcjonalnie)" (zainteresowania, budżet, tempo, osoby, język planu);
  - pola zależne (lotnisko, numer lotu) pojawiają się dopiero po wyborze „Lot" – bez pustych, nieaktywnych pól;
  - walidacja **przy opuszczeniu pola** i przy wysłaniu; błąd **przy polu** (CMP-04), po wysłaniu fokus i przewinięcie do pierwszego błędu; bez blokowania przycisku wysyłki (przycisk zawsze aktywny, walidacja tłumaczy, czego brakuje);
  - wartości domyślne tylko tam, gdzie wynikają z modelu danych (budżet, tempo, osoby, język planu); pola wymagane bez domyślnych;
  - dane zachowane przy powrocie z EK-06/EK-07 i przy błędach; nie zapisujemy szkicu po zamknięciu aplikacji (U5);
  - podpowiedzi o ochronie danych przy polach tekstowych (nocleg: bez pełnego adresu).

## 3. Pusty stan

- **Kiedy:** brak danych, a użytkownik może to zmienić: EK-04 bez planów.
- **Kiedy nie:** dane się wczytują (szkielet), błąd (wzorzec 6), dzień planu bez punktów (to nie jest „pusty stan", tylko informacja w CMP-20).
- **Składniki:** CMP-18 wariant „Pusty" + opcjonalnie CMP-13 („plany tylko na tym urządzeniu", U9).
- **Zasady:** powód („Nie masz jeszcze planów"), co zrobić („Podaj cel i daty – AI ułoży plan dzień po dniu"), **jedno** działanie („Nowa podróż", wypełnione; FAB ukryty).

## 4. Ładowanie

- **Kiedy / składniki:**
  - znany układ (lista, plan) → **szkielet** (CMP-17) po 300 ms;
  - działanie w przycisku (logowanie, zapis zgody, usuwanie planu) → przycisk w stanie ładowania (CMP-02), blokada podwójnego dotknięcia;
  - długa operacja o nieznanym czasie (generowanie, usuwanie konta) → ekran z liniowym wskaźnikiem nieokreślonym, tekstem i (jeśli możliwe) „Anuluj".
- **Kiedy nie:** operacje < 300 ms (bez wskaźnika – brak migotania); nigdy fałszywy procent.

## 5. Błąd z ponowieniem

- **Kiedy:** operacja się nie udała i ponowienie ma sens: wczytanie, logowanie, zapis zgody, generowanie, usunięcie konta.
- **Składniki:** ekran bez treści → CMP-18 „Błąd" + „Spróbuj ponownie"; ekran z treścią/formularzem → CMP-13 „Błąd" nad treścią (formularz zostaje) lub CMP-14 dla błędu drugorzędnego.
- **Zasady:** bez szczegółów technicznych; co się stało + co zrobić + zapewnienie o danych („Twoje dane w formularzu zostały zachowane"); ponowienie **tylko z decyzji użytkownika** (bez automatycznych ponowień generowania – US-011); przy generowaniu informacja o limicie (zwrócony / mógł zostać zużyty).

## 6. Brak sieci

- **Kiedy:** funkcja wymaga sieci (logowanie, zgody, generowanie, usunięcie konta, Google Maps, link do polityki).
- **Kiedy nie:** ekrany działające offline (EK-04, EK-08, EK-11, EK-12, język) – **bez** komunikatu o braku sieci, dopóki użytkownik nie spróbuje akcji sieciowej.
- **Składniki:** CMP-13 „Ostrzeżenie" z `wifi-off-01` w miejscu akcji (formularz EK-05: nad przyciskiem „Generuj plan" – po nieudanej próbie; połączenie, które nie dotarło do serwera, nie zużywa limitu, ADR-0011 pkt 2); CMP-18 „Brak sieci" dla ekranów, które bez sieci nie mają treści; CMP-14 dla akcji jednorazowej (otwarcie map).
- **Zasady:** **brak sieci to wynik nieudanej próby, nie stały komunikat** – aplikacja nie ma detektora sieci (ADR-0011 pkt 2: bez pakietu łączności i bez `ACCESS_NETWORK_STATE`); jednolity tekst (EK-16); zawsze „Spróbuj ponownie" lub powrót; komunikat znika przy kolejnej udanej próbie lub po opuszczeniu ekranu. Wyjątek: otwarcie Google Maps nie jest blokowane (EK-09).

## 7. Potwierdzenie działania destrukcyjnego

- **Kiedy:** działanie usuwa dane lub kończy sesję: usunięcie planu (EK-11), wylogowanie (EK-14), usunięcie konta (EK-15), anulowanie generowania (EK-07).
- **Cofnięcie zamiast pytania, gdy się da:** dla usunięcia planu M3 zaleca snackbar „Plan usunięto · Cofnij" zamiast dialogu. Wymagania (US-009, EK-11) przewidują potwierdzenie i „trwałe usunięcie", więc **w MVP zostaje dialog** (CMP-15); wariant z cofnięciem (usunięcie odroczone o czas snackbara) – pytanie UX9 do właściciela/architekta.
- **Składniki:** CMP-15 (plan, wylogowanie, anulowanie); **pełny ekran** dla usunięcia konta (EK-15: zakres danych, nieodwracalność, ponowne uwierzytelnienie, postęp) – CMP-01, CMP-13 „Błąd/zagrożenie", CMP-02 destrukcyjny (wypełniony `error` tylko tu), CMP-17.
- **Zasady:** tytuł-pytanie, treść ze skutkiem, przycisk z czasownikiem; działanie destrukcyjne nigdy jako jedyne/domyślne; „Anuluj" zawsze dostępne (poza trwającą operacją).

## 8. Zgody i uprawnienia

- **Kiedy:** akceptacja polityki (EK-02, EK-03), zgoda na AI (EK-06, EK-13). Uprawnień systemowych Tamitu w MVP nie używa (lokalizacja: decyzja Q1 = C, 2026-11-25 – o dostęp pyta Google Maps).
- **Składniki:** polityka – CMP-09 (niezaznaczony) + CMP-02 wypełniony nieaktywny do zaznaczenia; zgoda na AI – pełny ekran z treścią zgody i **dwoma równorzędnymi przyciskami** (CMP-02, ten sam styl), bez checkboxa; uprawnienie systemowe (gdyby było potrzebne po MVP) – wyjaśnienie przed prośbą systemową; stan zgód – CMP-11 informacyjne + CMP-02 „Wycofaj zgodę" / „Wyraź zgodę".
- **Zasady (RODO, privacy-checklist):**
  - **kontekst przed prośbą systemową** (dotyczy każdego przyszłego uprawnienia systemowego);
  - **brak domyślnie zaznaczonych zgód**; brak zapamiętywania zaznaczenia między wersjami;
  - odmowa tak łatwa jak zgoda (równorzędne przyciski, ta sama waga, kolejność: zgoda nie zawsze „bardziej widoczna");
  - wycofanie zgody tak łatwe jak wyrażenie (EK-13, jeden przycisk);
  - odmowa nie blokuje reszty aplikacji (lokalizacja → start z planu; AI → powrót do formularza, plany dostępne);
  - **nie używamy przełącznika (switch)** dla zgody na AI: switch sugeruje natychmiastową zmianę, a wycofanie wymaga zapisu na serwerze (sieć, możliwy błąd) – przycisk + stan ładowania + wynik;
  - akceptacja polityki: **jeden tekst i jeden klucz** (`consentPolicyCheckbox`) we wszystkich miejscach; etykieta TalkBack = tekst widoczny; zmiana języka zdejmuje zaznaczenie (P-2, P-3);
  - **nowy cel przetwarzania oparty na zgodzie (lit. a) = osobny ekran zgody wg wzorca EK-06**, nigdy „przy okazji" ponownej akceptacji polityki (EK-03 tylko dla zmian informacyjnych; P-4);
  - wszystkie ekrany tego wzorca idą do przeglądu security przed `ux-ready` (przegląd P3-14c: `docs/security/reviews/2026-11-16-p3-14c-ekrany.md`).

## 9. Pierwsze uruchomienie

- **Kiedy:** brak sesji (P1).
- **Składniki:** EK-02 jako jedyny ekran powitalny: znak słowny (displaySmall), jedno zdanie o aplikacji, CMP-13 (prywatność i AI), CMP-07 (PL/EN, U1), CMP-09, CMP-02 „Zaloguj przez Google" (przycisk zgodny z wytycznymi marki Google dla przycisku logowania – do sprawdzenia w kroku 2).
- **Zasady:** **bez karuzeli wprowadzającej** (onboarding slides) – skraca drogę do wartości; wyjaśnienia pojawiają się w kontekście (zgoda na AI przy pierwszym generowaniu, lokalizacja przy pierwszej trasie, pusty stan EK-04 tłumaczy, co dalej).

## 10. Wyszukiwanie i filtry

- **MVP: nie dotyczy** (U13 – brak wyszukiwania na liście planów). Wzorzec zostaje opisany jako kierunek:
  pasek wyszukiwania M3 (`SearchAnchor`) w pasku górnym EK-04, filtry jako CMP-08 pod nim. Wymaga nowego komponentu w bibliotece przed użyciem.

## 11. Arkusz dolny do wyboru

- **Kiedy:** wybór w kontekście bieżącego ekranu, blisko kciuka: trasa do punktu (EK-09), język (EK-12).
- **Kiedy nie:** treść główna, długie teksty (zgody), formularze z wieloma polami, decyzje destrukcyjne (dialog).
- **Składniki:** CMP-16 + CMP-10/CMP-07 + CMP-02 (działanie zatwierdzające, jeśli wybór nie jest natychmiastowy).

## 12. Powiadomienia w aplikacji: snackbar a komunikat w treści

| Sytuacja | Komponent | Przykład |
|---|---|---|
| Wynik działania, chwilowy, opcjonalne „Cofnij"/„Spróbuj ponownie" | CMP-14 snackbar | „Zgoda na AI wycofana", „Logowanie anulowane" |
| Informacja ważna dla bieżącego ekranu, trwała | CMP-13 komunikat w treści | „Plan stworzyła AI…", „Brak połączenia…" |
| Błąd uniemożliwiający pokazanie treści | CMP-18 stan ekranu | „Nie udało się wczytać planu" |
| Decyzja wymagana teraz | CMP-15 dialog | „Usunąć plan?" |

Powiadomienia systemowe (push) – poza MVP.

## 13. Dwa języki: interfejs a treść planu

- Interfejs w języku UI (PL/EN); treść planu w języku planu (zapisana z planem). Na jednym ekranie (EK-08)
  mogą współistnieć dwa języki: etykiety (pory dnia, „Trasa", komunikat o AI) w języku UI, nazwy i opisy punktów w języku planu.
- Treści wpisane przez użytkownika (cel, nocleg) pokazujemy tak, jak je wpisał.
- Każdy tekst ma wersję PL i EN; projektujemy pod dłuższą (zwykle PL).

## 14. Wspólna reguła: kolor nigdy sam

Stan i znaczenie zawsze przekazuje także kształt, ikona lub tekst: wybrany chip/segment – ikona `tick-02`;
aktywna zakładka – wskaźnik; błąd – ikona `alert-circle` i tekst; radio – wypełnione koło.

