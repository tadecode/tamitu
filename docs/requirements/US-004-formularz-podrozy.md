# US-004: Formularz podróży

**Jako** zalogowany użytkownik **chcę** podać cel, bazę noclegową, liczbę dni, sposób dojazdu (lot lub auto) oraz swoje preferencje, **aby** otrzymać plan dopasowany do mojej podróży.

- Priorytet: MVP
- Dane osobowe: TAK – cel i daty/liczba dni podróży, adres/nazwa noclegu (miejsce pobytu), dane lotu (numer/godzina przylotu); **NOWE (N1): preferencje podróży – zainteresowania, budżet, tempo zwiedzania, liczba osób** (dane o upodobaniach i sytuacji finansowej użytkownika, wpis do rejestru danych osobowych przez Security). Dane powiązane z kontem i wysyłane do modelu AI (US-005).

## Kryteria akceptacji
- **Given** zalogowany użytkownik na ekranie głównym **When** wybiera „Nowa podróż" **Then** widzi formularz z polami: cel podróży, baza noclegowa, liczba dni, sposób przyjazdu (lot / auto) oraz preferencje: zainteresowania, budżet, tempo zwiedzania, liczba osób.
- **Given** formularz **When** użytkownik pozostawia puste pole cel, baza noclegowa lub liczba dni **Then** formularz nie przechodzi dalej i wskazuje brakujące pola.
- **Given** formularz **When** liczba dni jest mniejsza niż 1 lub większa niż 14 **Then** pole jest odrzucone z komunikatem o dozwolonym zakresie (maksimum 14 dni – decyzja właściciela, N2).
- **Given** wybrano „lot" **When** użytkownik wypełnia formularz **Then** wymagana jest data i godzina przylotu oraz miejsce lądowania (lotnisko); numer lotu jest opcjonalny.
- **Given** wybrano „auto" **When** użytkownik wypełnia formularz **Then** wymagana jest data i planowana godzina przyjazdu.
- **Given** formularz **When** użytkownik wypełnia pola preferencji (zainteresowania, budżet, tempo, liczba osób) **Then** ich wartości są walidowane (liczba osób – liczba całkowita w dozwolonym zakresie; budżet i tempo – wartość z ustalonego zbioru; zainteresowania – ograniczona liczba/długość) i trafiają do generowania planu (US-005).
- **Given** formularz **When** użytkownik pozostawia pola preferencji puste **Then** formularz przechodzi dalej, a plan jest generowany z wartościami domyślnymi (propozycja – obowiązkowość i zbiory wartości: pyt. N11 w `docs/open-questions.md`).
- **Given** poprawnie wypełniony formularz **When** użytkownik zatwierdza **Then** uruchamia się generowanie planu (US-005).
- **Given** formularz **Then** pola tekstowe mają limit długości, a wartości (także preferencje) są oczyszczone przed wysłaniem do AI (ochrona przed wstrzyknięciem poleceń do promptu).
- **Given** język interfejsu polski lub angielski **When** użytkownik otwiera formularz **Then** etykiety, komunikaty walidacji i podpowiedzi są w tym języku (US-005, scope.md).

## Uwagi / poza zakresem
Dojazd inny niż lot/auto (pociąg, autobus) – nie w MVP wg wizji. Jedna baza noclegowa na podróż (założenie, nadal robocze – do potwierdzenia przy okazji N11). Szczegóły preferencji (obowiązkowość, zbiory wartości) – pyt. N11. Godzina powrotu/wylotu ostatniego dnia – poza MVP.
