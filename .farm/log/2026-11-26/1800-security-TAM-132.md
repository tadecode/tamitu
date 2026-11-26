# 18:00  security → orkiestrator, właściciel  |  TAM-132 (REL-SEC-3)
- Zrobione: lista kontrolna bramki 2a (przed dodaniem kolejnego testera i przed testami zamkniętymi). Dla każdego
  punktu: warunek, jak sprawdzić (polecenie odczytu, plik lub ekran), kto, dowód i zadanie w Jirze. 16 warunków
  blokujących: część A (11) blokuje dodanie jakiegokolwiek kolejnego testera, część B (5) dodatkowo testy
  zamknięte, otwarte i produkcję; 8 zaleceń (część C). Bez zmian w kodzie i chmurze, bez kosztów.
- Artefakty: `docs/security/gate-2a-checklist.md`
- Decyzje: brak nowych. Propozycja zasady: bramkę zamyka protokół `docs/security/reviews/gate-2a-<data>.md`
  w PR-ze, którego merge przez właściciela jest zgodą; odczyty prod robi tylko właściciel, do protokołu trafiają
  wyniki bez e-maili, UID i treści logów.
- Do zrobienia przez odbiorcę: orkiestrator – założyć zadania Z-1…Z-11 (niżej); każdą zmianę listy testerów
  w Play sprawdzać względem zmergowanego protokołu (zasada 4 listy). Właściciel – nic do czasu bramki.
- Pytania/blokady: brak. Security dodało do warunków właściciela A6–A11 (m.in. ponowna decyzja o
  `globalDailyLimit` i o blokadzie `testUids`, ochrona kosztów, retencja w prod, przegląd logów prod, App Check
  bez tokenów debug) – właściciel może je odrzucić przy przeglądzie PR-a.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-132 (REL-SEC-3): review
- Zadania – nowe:
  - Z-1 „Napisz tekst zgody na AI w wersji 2 i daj go do sprawdzenia prawnikowi” – security (+ [PRAWNIK],
    właściciel); zależy od: TAM-54 (SEC-15), Z-3 (B-2), TAM-13 (O5), TAM-67 (SEC-30). Punkt A2.
  - Z-2 „Wprowadź w aplikacji zgodę na AI w wersji 2 i ponowne pytanie o zgodę” – mobile-dev (+ właściciel:
    `config/runtime.aiConsentVersionCurrent`); zależy od: Z-1. Punkt A2.
  - Z-3 „Zdecyduj, czy akceptujesz, że Google może przechowywać zapytania do AI do 90 dni w celu wykrywania
    nadużyć (B-2)” – właściciel (+ [PRAWNIK]; security przygotowuje opis); zależy od: TAM-54 (SEC-15 poz. 4).
    Punkt A4, pytanie O6.
  - Z-4 „Przed dodaniem testerów potwierdź limit 50 planów na dobę i brak blokady listą kont (albo zmień)” –
    właściciel + architect (aneks do ADR-0014, jeśli zostaje 50); zależy od: –. Punkty A6, A7.
  - Z-5 „Przejrzyj logi produkcyjne pod kątem danych osobowych przed kolejnym testerem” – security
    (odczyt: właściciel); zależy od: TAM-129 (REL-QA-1). Punkt A10.
  - Z-6 „Opublikuj stronę z instrukcją usuwania konta i danych Tamitu” – właściciel (treść: security);
    zależy od: TAM-21 (P3-08). Punkt B2.
  - Z-7 „Zdecyduj, co zrobić z Twoimi danymi z okresu testów wewnętrznych” – właściciel (opcje: security);
    zależy od: –. Punkt B4.
  - Z-8 „Uzupełnij deklaracje »Zawartość aplikacji« w Play Console przed testami zamkniętymi” – właściciel
    (sprawdzenie: security); zależy od: TAM-130 (REL-OWN-9), TAM-131 (REL-SEC-2). Punkt B5.
  - Z-9 „Przygotuj krótką informację dla nowego testera” – security; zależy od: TAM-130. Zalecenie C1.
  - Z-10 „Procedura na wypadek wycieku danych osobowych” – security (+ [PRAWNIK]); zależy od: –. Zalecenie C2.
  - Z-11 „Lista dozwolonych kont także przy realnych danych (do wydania publicznego)” – architect → mobile-dev;
    zależy od: –. Zalecenie C3.
- Pytania otwarte – nowe: brak (decyzje A6, A7, B4 ujęte jako zadania Z-4, Z-7; pytania zakłada orkiestrator przy
  bramce)
- Pytania otwarte – zamknięte: brak
