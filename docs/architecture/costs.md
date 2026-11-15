# Szacunek kosztów zmiennych – Tamitu (MVP)

Stan: 2026-11-15 (po G2), autor: architect. **To szacunek, nie wycena.**

> **UWAGA – CENY MODELI NIEZWERYFIKOWANE.** Wszystkie ceny tokenów w scenariuszach A, B, C (w tym promocja dla B do 2026-12-31 i cena od 2027-01-01) pochodzą z wyszukiwania strony cennika Vertex AI z 2026-11-15; fragmenty wyników były niespójne i nie zostały sprawdzone w oficjalnym cenniku ani w SKU Cloud Billing. Liczby w tym dokumencie (oraz skrót w ADR-0001) służą wyłącznie do oszacowania rzędu wielkości i **nie mogą być podstawą decyzji o budżecie ani wyborze modelu**. **Weryfikacja przed rozpoczęciem fazy 3 – zadanie właściciela i Security** (oficjalny cennik dla wybranego modelu i regionu `europe-west4`, kurs, VAT); po weryfikacji zaktualizować tabele i zdjąć to ostrzeżenie. Dotyczy to też pułapów w sekcji 4 i oceny Security (2-5).

Kurs przyjęty: **4,0 PLN za 1 USD** (zaokrąglenie ostrożne; również niezweryfikowany). Ceny nie zawierają VAT.

## 1. Założenia
- Wejście do modelu (prompt systemowy + dane): ok. **1 000 tokenów**.
- Wyjście: punkt planu ≈ 80 tokenów (nazwa, miejscowość, opis, godzina, JSON); tytuł dnia ≈ 20.
  - **Typowy:** 5 dni, tempo umiarkowane (5 punktów/dzień) ≈ 2 100 tokenów.
  - **Duży:** 14 dni umiarkowane ≈ 5 900.
  - **Maksymalny:** 14 dni intensywne (7 punktów/dzień) ≈ 8 100 (limit `maxOutputTokens` 10 000).
- „Myślenie" modelu wyłączone/minimalne (inaczej tokeny myślenia liczone jak wyjściowe zwiększyłyby koszt kilkukrotnie).
- Ponowienia: średnio +10% prób; maksimum 2 próby na generowanie.
- Scenariusze cen (USD za 1 mln tokenów, wejście / wyjście):
  - **A** 0,30 / 2,50 – klasa Gemini 2.5 Flash,
  - **B** 1,50 / 7,50 – nowsza klasa Flash, cena standardowa od 2027-01-01 (do 2026-12-31 promocyjnie 0,75 / 3,75, czyli ok. połowa B),
  - **C** 0,10 / 0,40 – klasa Flash-Lite.

## 2. Koszt jednej próby generowania
| Profil | A USD | A PLN | B USD | B PLN | C USD | C PLN |
|---|---|---|---|---|---|---|
| Typowy | 0,0056 | 0,022 | 0,0173 | 0,069 | 0,0009 | 0,004 |
| Duży | 0,0151 | 0,060 | 0,0458 | 0,183 | 0,0025 | 0,010 |
| Maksymalny | 0,0206 | 0,082 | 0,0623 | 0,249 | 0,0033 | 0,013 |

Język polski zwykle zużywa więcej tokenów na ten sam sens niż angielski; założenia wyjścia mają ten zapas. Pomiar rzeczywisty (tokeny wejścia/wyjścia na plan, osobno PL i EN) – obowiązkowy w pierwszych testach (R15, US-011, uwaga w N4: limit do zmiany po pomiarze).

## 3. Scenariusze miesięczne (plan typowy, +10% ponowień)
| Scenariusz | Planów/mies. | A | B | C |
|---|---|---|---|---|
| 5 testerów × 8 planów | 40 | 0,24 USD (≈ 1 PLN) | 0,76 USD (≈ 3 PLN) | 0,04 USD (≈ 0,2 PLN) |
| 20 testerów × 10 planów | 200 | 1,22 USD (≈ 5 PLN) | 3,80 USD (≈ 15 PLN) | 0,21 USD (≈ 0,8 PLN) |
| 100 użytkowników × 4 plany | 400 | 2,44 USD (≈ 10 PLN) | 7,59 USD (≈ 30 PLN) | 0,41 USD (≈ 1,7 PLN) |

Plany „duże" kosztują ok. 2,7 razy więcej niż typowe.

## 4. Pułapy kosztowe (najgorszy przypadek)
| Pułap | A | B | C |
|---|---|---|---|
| Jedno konto, doba: 5 generowań × plan maksymalny × 2 próby | 0,21 USD (0,8 PLN) | 0,62 USD (2,5 PLN) | 0,03 USD (0,13 PLN) |
| Jedno konto, miesiąc (30 dób, teoretycznie) | 6,2 USD (≈ 25 PLN) | 18,7 USD (≈ 75 PLN) | 1,0 USD (≈ 4 PLN) |
| Pułap globalny: 50 generowań/dobę (bezpiecznik), maksymalne plany, 2 próby, 30 dób | 62 USD (≈ 247 PLN) | 187 USD (≈ 747 PLN) | 10 USD (≈ 40 PLN) |
| To samo, plany typowe z 10% ponowień | 9 USD (≈ 37 PLN) | 28 USD (≈ 114 PLN) | 1,5 USD (≈ 6 PLN) |

Pułapy globalne są zbyt wysokie względem proponowanego budżetu prod 100 PLN, ale **nie są osiągalne bez nadużycia**; ogranicza je dodatkowo wyłącznik budżetowy (ADR-0003). Jeśli właściciel chce twardszej gwarancji: obniżyć limit globalny (np. 20/dobę) lub wybrać klasę C po ewaluacji (ADR-0001).

## 5. Pozostałe usługi (przy skali testowej)
| Usługa | Koszt | Uwagi |
|---|---|---|
| Cloud Functions 2. gen. | ≈ 0 | pula bezpłatna (2 mln wywołań, 180 tys. vCPU-s, 360 tys. GiB-s); jedno generowanie ≈ 20–40 s przy 512 MiB, rząd 0,001 PLN poza pulą |
| Firestore | ≈ 0 | ok. 3 odczyty i 3 zapisy na generowanie; pula 50 tys./20 tys. dziennie |
| Firebase Auth (Google) | 0 | do 50 tys. MAU |
| App Check / Play Integrity | 0 | pula standardowa Play Integrity (rząd 10 tys. atestacji dziennie, do weryfikacji) |
| Cloud Logging | ≈ 0 | metadane, pula 50 GiB; retencja 30 dni |
| Secret Manager | ≈ 0,06 USD/mies. | 1 sekret (pieprz do skrótu UID) |
| Artifact Registry / Cloud Build (wdrożenia funkcji) | ≈ 0–0,5 USD | pule bezpłatne, drobne opłaty za przechowywanie obrazów |
| Pub/Sub (budżet) | ≈ 0 | |
| Google Maps (link bez API) | 0 | brak Maps SDK, Places, Geocoding |
| **Razem stałe** | **ok. 0–3 PLN/mies.** | wymaga planu Blaze (karta) |

Koszty poza zakresem: konto Google Play (jednorazowa opłata), domena/strona polityki, porada prawna, reklamy/subskrypcje (po MVP).

## 6. Koszty testów i CI
- Standardowe testy CI używają atrapy modelu – 0 wywołań.
- Ewaluacja (zestaw min. 20 przypadków × PL/EN = 40 wywołań, mieszane długości): ok. 0,3 USD (A) – 1,0 USD (B) na przebieg. Zasada: uruchamiana ręcznie lub co noc na gałęzi `main`/przy zmianie promptu, **maks. 1 przebieg dziennie**, w projekcie `dev`, dane syntetyczne, `dev` ma własny limit globalny (np. 20/dobę dla testów ręcznych) i budżet 20 PLN.

## 7. Co najmocniej zmienia koszt
1. Włączone „myślenie" modelu (×3–×10 na wyjściu) – nie włączać bez pomiaru.
2. Liczba dni i tempo (liniowo wyjście).
3. Ponowienia przy złym schemacie/języku – limit 2 prób, jakość promptu.
4. Zmiana klasy modelu (A↔B↔C, różnica rzędu 4–20×).
5. Limit na konto i globalny (parametry w `config/runtime`).
6. Zmiana cennika po 2026-12-31 (scenariusz B).

## 8. Alerty i wyłączniki (patrz ADR-0002, ADR-0003)
Budżety zatwierdzone przez właściciela (Q3, 2026-11-15; ustawia właściciel): dev 20 PLN, prod 100 PLN, alerty 50/90/100%, automatyczne wyłączenie AI przy 100% prod, limit na konto 5/dobę (doba kalendarzowa Europe/Warsaw, Q5), limit globalny 50/dobę, `maxInstances` 10, `maxOutputTokens` 10 000, kwoty Vertex ograniczone w konsoli. Dodatkowo alert na wyczerpanie limitu globalnego i przegląd limitów przed wydaniem publicznym (ADR-0002, Aneks A pkt 5). Klasa modelu: start od Flash, wybór ostateczny po ewaluacji w fazie 3 (Q4).

## 9. Koszt wynikający z decyzji G2
Czwarte konto usług, sprawdzanie istnienia użytkownika (jedno wywołanie Admin API na żądanie), handler wyjątków i dodatkowy alert nie zmieniają kosztów w istotny sposób (pula bezpłatna). SQLCipher zwiększa rozmiar APK, nie koszt zmienny.
