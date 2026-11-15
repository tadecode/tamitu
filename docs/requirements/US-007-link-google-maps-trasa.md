# US-007: Link Google Maps z trasą do punktu planu

**Jako** użytkownik **chcę** jednym dotknięciem otworzyć w Google Maps trasę do punktu planu, **aby** łatwo tam dotrzeć.

- Priorytet: MVP
- Dane osobowe: TAK – **dokładna lokalizacja bieżąca** (uprawnienie precyzyjnej lokalizacji; S6, rejestr D7; tylko gdy użytkownik wybierze start „moja lokalizacja"), punkt startowy (np. nocleg) i cel; lokalizacja nie jest zapisywana ani wysyłana do naszych serwerów; współrzędne trafiają do Google Maps przez link/aplikację.

## Kryteria akceptacji
- **Given** widok planu **When** użytkownik dotyka punktu **Then** widzi wybór: punkt startowy (domyślnie baza noclegowa lub poprzedni punkt dnia / bieżąca lokalizacja) oraz tryb (auto / komunikacja / pieszo).
- **Given** wybrano start „moja lokalizacja" i brak zgody systemowej **When** użytkownik wybiera tę opcję **Then** aplikacja prosi o uprawnienie precyzyjnej (dokładnej) lokalizacji na pierwszym planie z wyjaśnieniem celu.
- **Given** użytkownik odmówił uprawnienia lokalizacji lub przyznał tylko przybliżoną **Then** aplikacja nadal działa, a trasę można zbudować z punktu startowego z planu.
- **Given** poprawny start, cel i tryb **When** użytkownik potwierdza **Then** otwiera się Google Maps (aplikacja lub przeglądarka) z trasą ze startu do celu w wybranym trybie (testowalne: sprawdzenie parametrów URL origin, destination, travelmode).
- **Given** start „moja lokalizacja" z przyznanym uprawnieniem **When** użytkownik potwierdza **Then** parametr origin zawiera pobrane dokładne współrzędne.
- **Given** punkt planu bez rozpoznanej lokalizacji **When** użytkownik dotyka go **Then** link używa nazwy miejsca i miasta jako zapytania zamiast współrzędnych.
- **Given** dowolne użycie funkcji **Then** lokalizacja jest pobierana tylko na żądanie (po wyborze startu „moja lokalizacja") na pierwszym planie, bez lokalizacji w tle i bez zapisu w pamięci trwałej lub logach.
- **Given** aplikacja w manifeście **Then** nie deklaruje uprawnienia lokalizacji w tle (testowalne: analiza manifestu).
- **Given** brak zainstalowanej aplikacji Google Maps **Then** link otwiera się w przeglądarce.

## Uwagi / poza zakresem
Bez osadzania mapy w aplikacji, bez podpowiedzi „w pobliżu" i bez lokalizacji w tle (decyzja właściciela, pyt. 4), bez nawigacji krok po kroku. Dokładność lokalizacji: dokładna (decyzja właściciela, S6). Link nie wymaga klucza Google Maps API (do potwierdzenia przez architekta).
