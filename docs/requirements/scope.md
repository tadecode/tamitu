# Zakres: MVP, później, poza zakresem

Stan: po bramce G1 (zatwierdzona). Źródło: `docs/vision.md`. Pytania 1–8 oraz N1–N10 (i S1–S12) zostały odpowiedziane przez właściciela – patrz `docs/open-questions.md`; zakres poniżej odzwierciedla te decyzje. Potwierdzone wartości: maks. 14 dni podróży (N2), limit 5 generowań na konto na dobę (N4), bufor 3 h po lądowaniu / 0 przy aucie (N6). Nowe pytania doprecyzowujące: N11 (w `docs/open-questions.md`).

Ekrany, przepływy i stany brzegowe MVP (wejście do mockupu UI, P3-14a): `docs/requirements/screens-and-flows.md`. Zakres MVP nie uległ zmianie.

## MVP (apka testowa na Androida, `pl.tadecode.tamitu`)
- Logowanie przez Google (Firebase Auth), wylogowanie; bez trybu gościa.
- Informacja o prywatności i zgody (w tym osobna zgoda na przekazanie danych do AI).
- Formularz podróży: cel, baza noclegowa, liczba dni (1–14), lot lub auto, data i godzina przylotu/przyjazdu oraz preferencje: zainteresowania, budżet, tempo zwiedzania, liczba osób.
- Plan na każdy dzień generowany przez AI (przez pośrednika po stronie serwera), z uwzględnieniem godziny przylotu/przyjazdu i preferencji.
- Interfejs i plany AI w dwóch językach: polskim i angielskim (US-004, US-005, US-011); minimalne API Androida ustala architekt.
- Link Google Maps z trasą (start: „Moja lokalizacja” – link bez punktu startowego, pozycję ustala Google Maps, Tamitu nie odczytuje lokalizacji i nie ma uprawnień lokalizacji; albo poprzedni punkt dnia lub nocleg z planu; auto/komunikacja/pieszo). **[ZMIANA TAM-110: Q1 = C, ADR-0017]**
- Zapis, lista i podgląd planów (lokalnie), usunięcie planu.
- Usunięcie konta i danych (natychmiast, w aplikacji); bez eksportu w aplikacji, dostęp do danych na wniosek e-mailem.
- Limity użycia AI i obsługa błędów.

## Później
- Logowanie Facebook, Apple, Microsoft.
- Zdjęcie zabytku: rozpoznanie obiektu i opis czytany na głos (TTS).
- Zdjęcie menu: tłumaczenie i przykładowe zdjęcia dań.
- Reklamy (AdMob) i zgody reklamowe; subskrypcje (plan jednorazowy na podróż, plan roczny; Google Play Billing) – po ocenie opłacalności (poza apką testową).
- Synchronizacja planów w chmurze między urządzeniami.
- Podpowiedzi „w pobliżu".
- Edycja planu, regeneracja pojedynczego dnia.
- Dodatkowe języki ponad polski i angielski.
- Eksport danych użytkownika w aplikacji.

## Poza zakresem (na teraz)
- Pełna mapa osadzona w aplikacji.
- Wersja iOS.
- Własny system haseł.
- Lokalizacja w tle.
- Udostępnianie planów innym osobom, współdzielenie podróży (brak w wizji).
- Tryb gościa; użytkownicy niepełnoletni (tylko dorośli, indywidualni – N8).

## Historyjki MVP

| ID | Tytuł | Dane osobowe |
|---|---|---|
| US-001 | Logowanie przez Google | TAK – UID, e-mail, nazwa konta |
| US-002 | Wylogowanie | TAK (pośrednio) – sesja |
| US-003 | Informacja o prywatności i zgody | TAK – zapis zgód |
| US-004 | Formularz podróży | TAK – cel, daty, nocleg, lot, **preferencje: zainteresowania, budżet, tempo, liczba osób (NOWE, N1)** |
| US-005 | Plan dnia generowany przez AI (PL/EN) | TAK – dane podróży **i preferencje** do modelu AI |
| US-006 | Uwzględnienie godziny przylotu/przyjazdu | TAK – godzina, lotnisko |
| US-007 | Link Google Maps z trasą | TAK – cel i start z planu (tekst w linku, D8); **bez lokalizacji bieżącej** (Q1 = C, ADR-0017; zastępuje S6) |
| US-008 | Zapis i lista planów | TAK – zapisane plany (w tym preferencje) |
| US-009 | Podgląd i usunięcie planu | TAK – dane podróży |
| US-010 | Usunięcie konta i danych | TAK – usuwanie wszystkich danych |
| US-011 | Limity AI i obsługa błędów | TAK (pośrednio) – licznik użycia per konto |

## Wstępny wykaz danych osobowych dla Security
1. Identyfikator konta (UID), e-mail, nazwa – Google/Firebase Auth (US-001).
2. Zgody i ich daty (US-003).
3. Dane podróży: cel, daty/liczba dni, baza noclegowa, dane lotu (US-004, US-006, US-008).
4. **NOWE (N1): preferencje podróży – zainteresowania, budżet, tempo zwiedzania, liczba osób (US-004, US-005, US-008).** Dane o upodobaniach i sytuacji finansowej (budżet); liczba osób może wskazywać na towarzyszy. Zainteresowania w polu tekstowym mogą zawierać dane wrażliwe (np. religia, zdrowie) – do oceny Security (propozycja: lista predefiniowana, N11).
5. Dane przekazywane do modelu AI (US-005) – zasada: bez UID/e-maila; w tym preferencje z pkt 4; wariant API korporacyjny, region UE, bez trenowania (S5), warunki do potwierdzenia w ADR; do tego czasu brak prawdziwych danych do AI.
6. ~~ZMIANA (S6): dokładna lokalizacja bieżąca (uprawnienie precyzyjnej lokalizacji, rejestr D7)~~ – **nieaktualne (TAM-110):** Q1 = C (właściciel 2026-11-25, ADR-0017) – Tamitu nie przetwarza lokalizacji urządzenia; w linku Google Maps trafiają tylko cel, tryb i opcjonalnie start z planu jako tekst (D8; US-007).
7. Licznik użycia AI per konto (US-011).
8. Język interfejsu/planu (PL/EN) – ustawienie aplikacji, bez własnego znaczenia osobowego, ale zapisywane razem z planem (US-005); do potwierdzenia przez Security.
9. Później: identyfikator reklamowy i zgody reklamowe; zdjęcia (zabytki, menu); dane rozliczeniowe subskrypcji (obsługuje Google Play).
