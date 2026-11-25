# Dostępność – Tamitu (MVP)

- Status: szkic, wersja 0.1 (2026-11-16, ux, P3-14b krok 2). Wariant marki A „Lazur".
- Cel: WCAG 2.1 AA w aplikacji na Androida; wymagania sprawdzalne przez qa (TalkBack, skala czcionki, Accessibility Scanner).

## 1. Kontrast (sprawdzony)
Współczynniki policzone wzorem WCAG (luminancja względna sRGB) dla tokenów z `design-system.md`. Próg: tekst 4,5:1; duży tekst i elementy interfejsu 3:1.

| Para (treść / tło) | Użycie | Próg | Jasny | Ciemny |
|---|---|---|---|---|
| onPrimary / primary | przycisk wypełniony | 4,5 | 6,42 | 7,73 |
| onPrimaryContainer / primaryContainer | FAB | 4,5 | 13,24 | 7,28 |
| onSecondaryContainer / secondaryContainer | chip/segment wybrany, komunikat informacyjny | 4,5 | 12,53 | 7,25 |
| onTertiaryContainer / tertiaryContainer | znacznik godziny | 4,5 | 13,28 | 7,25 |
| onErrorContainer / errorContainer | komunikat błędu | 4,5 | 13,26 | 7,24 |
| onError / error | przycisk „Usuń konto na zawsze" | 4,5 | 6,46 | 7,72 |
| onSurface / surface | tekst główny | 4,5 | 14,41 | 14,33 |
| onSurfaceVariant / surface | tekst pomocniczy, ikony | 4,5 | 7,83 | 10,90 |
| onSurface / surfaceContainerLow | tekst na karcie, w arkuszu | 4,5 | 13,51 | 13,26 |
| onSurfaceVariant / surfaceContainerLow | opis na karcie, w arkuszu | 4,5 | 7,35 | 10,08 |
| onSurfaceVariant / surfaceContainerHigh | treść dialogu | 4,5 | 6,68 | 8,48 |
| primary / surface | przycisk tekstowy, link, zakładka aktywna | 4,5 | 5,41 | 10,90 |
| primary / surfaceContainerHigh | przycisk tekstowy w dialogu | 4,5 | 4,61 | 8,49 |
| error / surface | błąd pola, „Usuń konto" w liście | 4,5 | 5,44 | 10,89 |
| error / surfaceContainerHigh | „Usuń" w dialogu | 4,5 | 4,64 | 8,48 |
| tertiary / surfaceContainerLow | godzina przylotu na karcie | 4,5 | 5,09 | 10,08 |
| onInverseSurface / inverseSurface | snackbar | 4,5 | 11,56 | 10,15 |
| inversePrimary / inverseSurface | akcja snackbara | 4,5 | 7,73 | 4,98 |
| outline / surface | obrys pola, checkboxa, segmentu | 3,0 | 3,77 | 5,84 |
| primary / surfaceContainerHighest | pasek postępu na torze | 3,0 | 4,35 | 7,26 |

Wszystkie pary spełniają próg (jasny motyw przyciemniony 2026-11-16: tła ok. tonu 93 zamiast 98; najsłabsze pary tekstu: `primary`/`error` na `surfaceContainerHigh` – 4,61 i 4,64). Na `surfaceContainerHighest` nie stawiamy tekstu w kolorze `primary`/`error` (4,35) – ten kontener służy tylko torom wskaźników i szkieletom. `outlineVariant` (separatory, oś czasu, obrys niewybranego chipa) jest dekoracyjny – granicę elementu wyznacza tekst. Po implementacji: ponowna kontrola na zrzutach (Accessibility Scanner) – zadanie qa.

## 2. Kolor nie jest jedynym nośnikiem znaczenia
Wybór: ikona `tick-02` (chip, segment), wypełnione koło (radio), wskaźnik (zakładka). Błąd: ikona `alert-circle` + tekst. Stan zgody: tekst („Wyrażona", „Wycofana") + data. Działania destrukcyjne: tekst z czasownikiem i ikona `delete-02`.

## 3. Cele dotyku
- Minimum 48 × 48 dp dla każdego elementu interaktywnego; odstęp ≥ 8 dp.
- Elementy wizualnie mniejsze (checkbox 18 dp, radio 20 dp, ikona 24 dp, chip 32 dp) mają obszar dotyku 48 dp.
- Cały wiersz zgody, opcji radiowej i elementu listy jest celem dotyku; link w treści zgody ma osobny cel 48 dp.

## 4. TalkBack
- Każdy ekran: tytuł jako nagłówek; nagłówki sekcji (formularz, ustawienia, zgoda na AI) jako nagłówki – nawigacja po nagłówkach.
- Kolejność fokusu = kolejność wizualna (opisana w każdej specyfikacji `screens/`).
- Ikony samodzielne mają etykiety („Wstecz", „Ustawienia", „Więcej opcji", „Zamknij arkusz"); ikony obok tekstu są dekoracyjne.
- Karty planów i punkty planu czytane jako jedna etykieta (np. „Lizbona, 4 dni, lot, utworzono 12 maja 2027, przycisk").
- Treść planu oznaczona językiem planu (właściwa wymowa przy języku UI ≠ języku planu).
- Komunikaty CMP-13 o zmianie stanu (sieć) i snackbary ogłaszane jako regiony na żywo (uprzejmie); stan ekranu CMP-18 przenosi fokus na tytuł; dialog przenosi fokus na tytuł i jest modalny.
- Przycisk nieaktywny czytany z powodem (EK-02, EK-03).
- Postęp generowania: ogłoszenie zmian tekstu nie częściej niż co 10 s.
- Odliczanie (EK-07 `ai_busy`, TAM-98): tekst odliczania nie jest regionem na żywo; etykieta w pełnych słowach („Ponowna próba za 42 sekundy”); ogłoszenie uprzejme co 15 s; pasek odliczania ukryty przed TalkBack; użytkownik nie musi działać w limicie czasu (WCAG 2.2.1).

## 5. Skalowanie tekstu
- Wszystkie rozmiary w sp; aplikacja działa przy skali systemowej do **200%** bez utraty treści i funkcji.
- Zachowania przy dużej skali (sprawdzone w makietach przełącznikiem „Tekst 150% / 200%"):
  - pola dwukolumnowe (data | godzina) → na telefonie (okno < 600 dp) zawsze jedna kolumna; na szerszych oknach jedna kolumna od 150% (TAM-102: etykiety nie mogą być ucinane, także przy powiększonym rozmiarze wyświetlania);
  - segmenty 3-opcyjne → lista jednokrotnego wyboru (CMP-10) od 150%;
  - przyciski przyklejone do dołu (EK-02, EK-06) → przewijają się z treścią przy 200%;
  - dialogi: treść przewijana, przyciski pionowo;
  - arkusz dolny: do 90% wysokości, przewijany.
- Brak stałych wysokości dla elementów z tekstem; tytuły w pasku górnym mogą mieć 2 linie przy 200%.

## 6. Ruch
- Ustawienie systemowe „usuń animacje" wyłącza animacje dekoracyjne (szkielet, przejścia), wskaźniki postępu zostają.
- Brak animacji migających i automatycznie przewijanych treści.

## 7. Teksty i języki
- PL i EN dla każdego tekstu (klucze w `screens/`); PL dłuższy o ok. 20–30% – sprawdzony w makietach (najdłuższe: EK-06, EK-15, EK-14, EK-16).
- Prosty język, zdania krótkie, bez żargonu i kodów błędów.
- Format dat, godzin i liczb wg języka interfejsu.

## 8. Lista kontrolna dla qa (przy każdym ekranie)
- [ ] TalkBack: przejście całego ekranu, etykiety, nagłówki, kolejność.
- [ ] Skala czcionki 200% (Ustawienia → Wyświetlacz): brak ucinania, wszystkie działania dostępne.
- [ ] Accessibility Scanner: kontrast i cele dotyku bez ostrzeżeń.
- [ ] Ciemny motyw: kontrast i czytelność ikon.
- [ ] EN i PL: brak ucinania najdłuższych tekstów.
- [ ] „Usuń animacje": brak blokady funkcji.
