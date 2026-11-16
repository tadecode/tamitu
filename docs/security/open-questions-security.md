# Pytania Security do właściciela

Stan: 2026-11-15. **Wszystkie pytania S1–S12 odpowiedziane** przez właściciela 2026-11-14; źródłem prawdy jest `docs/open-questions.md` (tam pełne brzmienie odpowiedzi). Pozycje [PRAWNIK] nadal wymagają porady prawnej.

| # | Pytanie | Status | Ustalenie (skrót; szczegóły w `docs/open-questions.md`) | Pozostaje |
|---|---|---|---|---|
| S1 | Administrator, IOD, polityka | odpowiedziane (częściowo) | TadeCode, bez IOD; polityka na tadecode.pl/tamitu/prywatnosc przed testami zewnętrznymi | [WŁAŚCICIEL] nazwa, adres, NIP; [PRAWNIK] brak IOD |
| S2 | Lokalizacja przetwarzania Firebase i transfery | odpowiedziane | Security weryfikuje w dokumentacji Google w fazie 2 | Zadanie SEC-10 |
| S3 | Dowód zgód | odpowiedziane | Minimalny zapis serwerowy (UID, wersja, wartość, data) | [PRAWNIK] okres po usunięciu konta |
| S4 | Kopia zapasowa Androida | odpowiedziane | `allowBackup` wyłączone | Szyfrowanie bazy – decyzja architekta (ADR) |
| S5 | Wariant API modelu AI | odpowiedziane | Korporacyjny, region UE, DPA, bez trenowania (np. Vertex AI) | **Warunek przed realnymi danymi:** potwierdzenie w ADR; do tego czasu dane testowe |
| S6 | Dokładność lokalizacji | odpowiedziane | **Dokładna** (zmiana względem propozycji) | Data Safety i uzasadnienie uprawnienia (SEC-13) |
| S7 | Retencja logów | odpowiedziane | 30 dni, bez treści, UID jako skrót | Opis w polityce |
| S8 | Skrzynka kontaktowa RODO | odpowiedziane | tamitu@tadecode.pl | [PRAWNIK] okres przechowywania korespondencji |
| S9 | Dostęp i eksport | odpowiedziane (z N7) | Bez eksportu w aplikacji; dostęp na wniosek e-mailem | – |
| S10 | Regulamin | odpowiedziane | Tak, krótki, przed wydaniem publicznym | [PRAWNIK] |
| S11 | DPIA | odpowiedziane | MVP: raczej nie; ocena przy rozszerzeniach | [PRAWNIK] (uwzględnić lokalizację dokładną i preferencje) |
| S12 | Podstawa prawna logów/licznika, wiek | odpowiedziane | Lit. f; tylko dorośli | [PRAWNIK] |

## Nowe pytania Security (wynikające z odpowiedzi)

| # | Pytanie | Rekomendacja | Status |
|---|---|---|---|
| S13 | Zainteresowania: lista predefiniowana czy wolny tekst (część N11) | Lista predefiniowana, bez pozycji ujawniających religię, zdrowie, orientację; budżet tylko poziomy | otwarte – rozstrzyga właściciel w N11 (`docs/open-questions.md`) |
| S14 | Który tekst zgód/polityki PL/EN jest wiążący przy rozbieżności; weryfikacja tłumaczenia | Teksty zatwierdzane razem | otwarte [PRAWNIK] |

Powiązane: pyt. 1, 2, 5, 6, 7, N1, N3, N5, N7, N8, N10, N11 w `docs/open-questions.md`.

## Pytania z przeglądu ekranów (P3-14c, 2026-11-16)
Pełne brzmienie i propozycje: `docs/open-questions.md` (sekcja „Przegląd security ekranów”), raport: `reviews/2026-11-16-p3-14c-ekrany.md`.

| # | Pytanie | Status |
|---|---|---|
| S15 | Administrator w treści zgody na AI (EK-06) | otwarte [PRAWNIK] |
| S16 | Brzmienie akceptacji polityki (CMP-09) | otwarte [PRAWNIK] |
| S17 | Serwerowe egzekwowanie wersji polityki | otwarte – architekt |
| S18 | Plany na innych urządzeniach po usunięciu konta | otwarte – architekt |
