# Checklista: wydajność i szybkość (Flutter/Android)

Wersja 0.1. Zmienia ją właściciel; recenzent proponuje w `docs/reviews/lessons-proposed.md`.
Zasada: zgłaszaj tylko to, co ma uzasadniony wpływ na użytkownika. Mikrooptymalizacje bez
dowodu = ustalenie „drobna" lub pominięcie.

## Renderowanie (UI)
- Niepotrzebne przebudowy: duże `build()`, brak `const`, zmiana stanu wysoko w drzewie.
- Długie listy bez `ListView.builder`/`SliverList` (budowanie wszystkiego naraz).
- Ciężkie obliczenia w `build()` lub na głównym wątku (parsowanie JSON, sortowanie, obrazy) - `compute`/`Isolate`.
- Animacje bez `RepaintBoundary` tam, gdzie malowanie jest kosztowne.

## Obrazy i zasoby
- Obrazy z sieci bez cache i bez skalowania do rozmiaru wyświetlania.
- Zbyt duże zasoby w paczce (rozmiar APK).

## Sieć i dane
- Zapytania w pętli, brak paginacji, brak debounce przy wyszukiwaniu.
- Wielokrotne pobieranie tych samych danych, brak cache/offline tam, gdzie wymagany.
- Wywołania modeli AI: brak limitów, brak cache powtarzalnych zapytań, zbyt duże prompty
  (koszt i opóźnienie); sztywne timeouty i obsługa błędów.
- Wywołania map/geokodowania w pętli (koszt API).

## Zasoby i pamięć
- Niezamykane strumienie, subskrypcje, kontrolery (`dispose`), wycieki słuchaczy.
- Duże obiekty trzymane w pamięci dłużej niż trzeba.

## Start i energia
- Ciężka inicjalizacja przed pierwszym ekranem; zbędne zadania w tle, polling zamiast zdarzeń.
- Nadmierne użycie lokalizacji (częstotliwość, dokładność).

## Backend / Firebase
- Zapytania bez indeksów, odczyty całych kolekcji, brak limitów.
