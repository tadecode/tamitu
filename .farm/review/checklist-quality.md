# Checklista: jakość kodu

Wersja 0.1. Zmienia ją właściciel; recenzent proponuje w `docs/reviews/lessons-proposed.md`.

- Zgodność z kryteriami akceptacji (US) i z ADR; brak „przy okazji" zmian poza zakresem zadania.
- Czytelność: nazwy, długość funkcji/klas, zagnieżdżenia, duplikacja.
- Obsługa błędów i stanów brzegowych (brak sieci, pusta odpowiedź, timeout); brak połykania wyjątków.
- Testy: pokrywają kryteria akceptacji i ścieżki błędów; brak testów zależnych od czasu/kolejności/sieci.
- Architektura: zależności tylko w dozwolonych kierunkach, logika poza widgetami, abstrakcja nad
  dostawcą AI/map.
- Dostępność (etykiety semantyczne, kontrast, rozmiary dotykowe) zgodnie z wymaganiami.
- Lokalizacja tekstów (brak twardo wpisanych napisów, jeśli wymaga tego projekt).
- Dokumentacja i backlog zaktualizowane; opis PR zgodny ze zmianą.
- Brak martwego kodu, zakomentowanych bloków, TODO bez zadania w backlogu.
