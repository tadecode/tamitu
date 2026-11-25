# Ryzyka i założenia

Waga: W = wysoka, S = średnia, N = niska (wpływ x prawdopodobieństwo, ocena wstępna analityka).

## Ryzyka

| # | Ryzyko | Waga | Mitygacja (propozycja) |
|---|---|---|---|
| R1 | RODO: dane podróży, lokalizacja i zgody to dane osobowe; brak podstawy prawnej lub rejestru | W | Rejestr danych osobowych, polityka prywatności przed testami zewnętrznymi, minimalizacja, usunięcie konta (US-010), DPIA jeśli Security uzna za potrzebne |
| R2 | Przekazanie danych do dostawcy AI (transfer, użycie do uczenia modelu) | W | Region UE, warunki przetwarzania danych z dostawcą, brak UID/e-maila w promptach, decyzja w ADR |
| R3 | Niekontrolowane koszty AI (nadużycia, pętle ponowień) | W | Limity na konto po stronie serwera, ograniczenie rozmiaru, alerty budżetowe, cache, szacunek kosztów w ADR (US-011) |
| R4 | Koszty Google Maps | N | Link bez API i bez osadzonej mapy; ponowna ocena przy użyciu API (np. geokodowanie) |
| R5 | Jakość odpowiedzi AI: nieistniejące miejsca, błędne godziny otwarcia, nierealne trasy | W | Walidacja formatu i godzin, komunikat, że plan może zawierać błędy, testy na zestawie przypadków, opcjonalnie weryfikacja miejsc w przyszłości |
| R6 | Wstrzyknięcie poleceń przez pola formularza (prompt injection) | S | Limity i oczyszczanie pól, ustrukturyzowane wyjście, walidacja odpowiedzi |
| R7 | Zależność od dostawców (Google Cloud, Firebase, Gemini): zmiana cennika, awaria, zmiana API | S | Warstwa abstrakcji nad modelem, monitoring, komunikaty o błędach, ADR z opcją wyjścia |
| R8 | Polityki Google Play: usunięcie konta w aplikacji i na stronie, formularz Data Safety, uprawnienia lokalizacji, wymagania dla kont organizacji i testów | S | Zgodność w US-003, US-007, US-010; checklista przed publikacją; formalności prowadzi właściciel |
| R9 | Logowanie Apple/Facebook/Microsoft: Apple wymagane w iOS przy innych logowaniach społecznościowych; Facebook wymaga weryfikacji aplikacji; Microsoft wymaga rejestracji | N (MVP) / S (później) | W MVP tylko Google; ponowna ocena przy rozszerzaniu i iOS |
| R10 | Pozostałe otwarte pozycje właściciela (dane administratora S1, warunki dostawcy AI S5, porada prawnika, N11) opóźnią testy zewnętrzne lub wysyłkę prawdziwych danych do AI | S | Lista w sekcji „Nadal do wykonania" w `docs/open-questions.md`; do czasu potwierdzenia S5 tylko dane testowe |
| R11 | Opłacalność: reklamy i subskrypcje mogą nie pokryć kosztów AI | S | Pomiar kosztu na plan w apce testowej, decyzja o modelu biznesowym po testach |
| R12 | ~~Lokalizacja dokładna (decyzja S6)~~ **Zaktualizowane TAM-110 (Q1 = C, ADR-0017):** Tamitu nie przetwarza lokalizacji; ryzyko rezydualne: przypadkowe dodanie uprawnienia lub pakietu lokalizacji (regresja) oraz ślad trasy w historii Google/przeglądarki po otwarciu linku (poza kontrolą Tamitu) | N | Test manifestu (tylko `INTERNET`) i test braku `geolocator` w `pubspec.lock` (US-007 AC2, AC6); dodanie pakietu lokalizacji wymaga nowego ADR; informacja w polityce prywatności o przekazaniu celu i startu z planu do Google Maps |
| R15 | Dwa języki (PL/EN): jakość planów AI i interfejsu różni się między językami; podwójny koszt testów (zestawy przypadków, tłumaczenia, wykrywanie języka odpowiedzi) i wyższy koszt tokenów przy ponowieniach z powodu złego języka | S | Zestaw testowy dla obu języków, walidacja języka odpowiedzi, kompletność kluczy tłumaczeń sprawdzana automatycznie, pomiar kosztu na język w ADR, limit ponowień (US-005, US-011) |
| R16 | Preferencje (budżet, zainteresowania) to nowe dane osobowe wysyłane do AI; pole tekstowe zainteresowań może zawierać dane wrażliwe lub wstrzyknięcie poleceń | S | Wpis w rejestrze danych, objęcie zgodą na AI (N5), minimalizacja (lista predefiniowana – propozycja N11), oczyszczanie pól (US-004), decyzja Security |
| R13 | Utrata danych lokalnych (zmiana telefonu, odinstalowanie) przy przechowywaniu tylko na urządzeniu | S | Jasna informacja dla użytkownika; synchronizacja w chmurze możliwa później (w MVP lokalnie – decyzja właściciela, pyt. 5) |
| R14 | Reklamy w przyszłości: zgody (CMP), identyfikator reklamowy, polityka dla treści dziecięcych | S | Osobna analiza przed wdrożeniem reklam |

## Założenia
Pytania 1–8 i N1–N10 zostały odpowiedziane przez właściciela (`docs/open-questions.md`); poniższe pozycje to potwierdzone decyzje lub założenia pozostałe.

- A1 (potwierdzone): MVP to apka testowa na Androida, tylko logowanie Google, interfejs i plany w języku polskim i angielskim (pyt. 7, 8).
- A2 (potwierdzone): Plany są przechowywane lokalnie (pyt. 5).
- A3 (potwierdzone): Reklamy i subskrypcje poza apką testową (pyt. 6).
- A4 (założenie, do potwierdzenia przez architekta): Link do map nie wymaga klucza API.
- A5 (potwierdzone): Każdy użytkownik ma konto; brak trybu gościa (N9).
- A6 (potwierdzone): Odbiorcy: dorośli, indywidualni (N8).
- A7 (potwierdzone): limity i wartości: 14 dni, 5 generowań na dobę, bufor 3 h (N2, N4, N6).
- A8 (założenie robocze): jedna baza noclegowa na podróż; szczegóły preferencji i wyboru języka planu – N11.
