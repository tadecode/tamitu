# Przepływy użytkownika – Tamitu (MVP)

- Status: szkic, wersja 0.1 (2026-11-16, ux, P3-14b krok 1)
- Źródło: `docs/requirements/screens-and-flows.md` (P3-14a: EK-01..EK-16, P1–P10, macierz stanów). Ten dokument
  przekłada przepływy na diagramy i przypisuje im wzorce (`patterns.md`). **Nie zmienia wymagań**; rozbieżności
  zgłaszam jako pytania.
- Do czasu odpowiedzi na U1–U15 obowiązują propozycje domyślne analityka; miejsca zależne od pytań oznaczone `[Ux]`.
- Oznaczenia: prostokąt – nasz ekran; `([…])` – element systemu (Android/Google); romb – decyzja.

## 0. Mapa aplikacji

```mermaid
flowchart TD
  EK01["EK-01 Start (bramka sesji)"] -->|brak sesji| EK02["EK-02 Ekran startowy: prywatność i logowanie"]
  EK01 -->|nowa wersja polityki| EK03["EK-03 Ponowna akceptacja"]
  EK01 -->|sesja ważna| EK04["EK-04 Lista planów"]
  EK02 --> EK04
  EK03 --> EK04
  EK04 -->|Nowa podróż| EK05["EK-05 Formularz podróży"]
  EK05 -->|pierwsze generowanie| EK06["EK-06 Zgoda na AI"]
  EK05 --> EK07["EK-07 Generowanie"]
  EK06 --> EK07
  EK07 --> EK08["EK-08 Widok planu"]
  EK04 -->|plan| EK08
  EK08 -->|punkt| EK09["EK-09 Trasa (arkusz)"]
  EK09 -->|Otwórz w Google Maps| GM(["Google Maps (poza aplikacją)"])
  EK08 -->|Usuń plan| EK11["EK-11 Potwierdzenie usunięcia"]
  EK04 -->|ikona ustawień| EK12["EK-12 Ustawienia"]
  EK12 --> EK13["EK-13 Prywatność"]
  EK12 -->|Wyloguj| EK14["EK-14 Potwierdzenie wylogowania"]
  EK12 -->|Usuń konto| EK15["EK-15 Usunięcie konta"]
  EK16["EK-16 Katalog komunikatów (wspólny)"]:::shared
  classDef shared stroke-dasharray: 4 4
```

Nawigacja: brak dolnego paska (2 cele najwyższego poziomu); Ustawienia z paska górnego EK-04 (`layout.md` pkt 3).

## P1. Pierwsze uruchomienie (US-001, US-003) – wzorce: pierwsze uruchomienie, zgody

```mermaid
flowchart TD
  A["EK-01"] -->|brak sesji| B["EK-02: informacja o prywatności i AI, PL/EN [U1], pole zgody NIEZAZNACZONE, Zaloguj nieaktywny"]
  B -->|zaznacza akceptację polityki| C["Zaloguj przez Google (aktywny)"]
  C --> D(["System: wybór konta Google"])
  D -->|sukces| E["Zapis akceptacji polityki"]
  E --> F["EK-04 stan pusty + informacja: plany tylko na urządzeniu [U9]"]
  D -->|anulowano, sieć jest lub stan niepewny| G["EK-02 + snackbar: Logowanie anulowane (bez błędu technicznego)"]
  D -->|anulowano przy pewnym braku sieci - M-BUG-DEV-2| H
  D -->|brak sieci / błąd| H["EK-02 + komunikat i Spróbuj ponownie"]
  B -->|nie akceptuje| B
```

Zgoda na AI **nie** jest pytana w P1 (privacy-checklist pkt 2). Informacja o pełnoletności na EK-02 [U2, PRAWNIK].

## P2. Powrót zalogowanego użytkownika (US-001, US-003, US-010; ADR-0005 Aneks A pkt 2, ADR-0011 pkt 1, 8, 9)

```mermaid
flowchart TD
  A["EK-01 (systemowy ekran powitalny, bez migotania)"] --> B{"Stan"}
  B -->|sesja ważna, także offline| C["EK-04"]
  B -->|wersja polityki w aplikacji nowsza niż akceptacja (offline)| D["EK-03 blokujący: Akceptuję / Wyloguj / Usuń konto [U2]"]
  D -->|Akceptuję, wymaga sieci| C
  B -->|znacznik: usuwanie w toku| R{"Konto na serwerze? (reload)"}
  R -->|usunięte| E["Czyszczenie lokalne"] --> F["EK-02 + komunikat"]
  R -->|istnieje| K["Dokończ usuwanie / Anuluj usuwanie"]
  K -->|Dokończ| Q["EK-15 (ponowne logowanie)"]
  K -->|Anuluj| C
  R -->|brak sieci| N["Połącz się, aby dokończyć + Spróbuj ponownie"]
  B -->|baza nieczytelna: utrata klucza| G["Usunięcie pliku, pusta baza, jednorazowy dialog"] --> H["EK-03 wariant: dane wyczyszczone"] --> I["EK-04 pusty"]
```

## P3. Tworzenie planu (US-004, US-005, US-006, US-011) – wzorce: formularz, zgody, ładowanie, błąd z ponowieniem

```mermaid
flowchart TD
  A["EK-04"] -->|Nowa podróż| B["EK-05 formularz (sekcje: Dokąd / Kiedy i jak / Preferencje)"]
  B -->|Generuj plan| V{"Walidacja"}
  V -->|błędy| B2["Błędy przy polach, fokus na pierwszym"] --> B
  V -->|OK| N{"Sieć? [U6]"}
  N -->|brak| B3["Komunikat brak sieci nad przyciskiem; limit niezużyty"] --> B
  N -->|jest| Z{"Zgoda na AI?"}
  Z -->|brak| C["EK-06 Zgoda na AI: Zgadzam się / Nie zgadzam się (równorzędne)"]
  C -->|nie zgadzam się| B4["EK-05, dane zachowane, nic nie wysłano"]
  C -->|zgadzam się, zapis OK| G
  Z -->|jest| G["EK-07 Generowanie: wskaźnik nieokreślony + Anuluj"]
  G -->|sukces| P["Plan zapisany automatycznie → EK-08 z informacją o AI; pozostało X z 5 [U4]"]
  G -->|sukces, ale zapis w telefonie nieudany| PN["EK-08 stan Plan nie jest zapisany: ostrzeżenie + Spróbuj zapisać ponownie, bez menu (TAM-104)"]
  PN -->|zapis udany| P
  PN -->|zapis znów nieudany| PN
  PN -->|wstecz| PD{"Dialog: Wyjść bez zapisania planu?"}
  PD -->|Anuluj| PN
  PD -->|Wyjdź bez zapisu: plan przepada| EK04L["EK-04"]
  G -->|błąd / AI niedostępne / zła odpowiedź| E1["EK-05 + komunikat błędu (EK-16), dane zachowane, limit zwrócony"]
  G -->|ai_busy: AI chwilowo przeciążone| BZ["EK-07 stan przeciążenia: odliczanie 60 s, Spróbuj teraz, Wróć do formularza (ek-07-ai-busy)"]
  BZ -->|koniec odliczania na pierwszym planie albo Spróbuj teraz| G2["EK-07 ponawianie (jedno automatyczne)"]
  BZ -->|Wróć / wstecz| B
  G2 -->|ai_busy ponownie| BM["EK-07: sam przycisk Spróbuj teraz, bez odliczania"]
  BM -->|Spróbuj teraz| G2
  BM -->|Wróć / wstecz| B
  G2 -->|sukces| P
  G2 -->|sukces, zapis nieudany| PN
  G2 -->|inny błąd| E1
  G -->|limit wyczerpany| E2["EK-05 + komunikat limitu z godziną odnowienia"]
  G -->|Anuluj / wstecz| P4["P4"]
```

## P4. Anulowanie generowania (US-005, US-011, Q12) – wzorzec: potwierdzenie działania destrukcyjnego

```mermaid
flowchart TD
  A["EK-07"] -->|Anuluj lub wstecz| B["Dialog: Przerwać generowanie? Nic nie zostanie zapisane; dzisiejszy limit może zostać zużyty"]
  B -->|Przerwij| C["EK-05, dane zachowane, nic nie zapisano"]
  B -->|Kontynuuj| A
```

## P5. Lista, podgląd i usuwanie planów (US-008, US-009) – wzorce: lista i szczegóły, potwierdzenie

```mermaid
flowchart TD
  A["EK-04 lista (offline OK)"] -->|karta planu| B["EK-08: podsumowanie, zakładki dni, punkty wg pór, komunikat o AI"]
  B -->|menu: Usuń plan| C["EK-11 dialog: Usunąć plan? [UX9]"]
  C -->|Usuń| D["EK-04 + snackbar: Plan usunięto (pusty stan, jeśli ostatni)"]
  C -->|Anuluj| B
  C -->|błąd usunięcia| E["Komunikat w dialogu, plan pozostaje"]
```

## P6. Trasa (US-007; wariant C z Q1, 2026-11-25) – wzorzec: arkusz dolny do wyboru

```mermaid
flowchart TD
  A["EK-08"] -->|punkt / Trasa| B["EK-09 arkusz: start (Moja lokalizacja – domyślnie / Poprzedni punkt dnia / Nocleg*), tryb (auto / komunikacja / pieszo – ostatnio użyty)"]
  B -->|Otwórz w Google Maps| L{"Start?"}
  L -->|Moja lokalizacja| U1(["Link bez origin: pozycję ustala Google Maps"])
  L -->|Poprzedni punkt / Nocleg| U2(["Link z origin = tekst z planu"])
  U1 --> S{"System otworzył link?"}
  U2 --> S
  S -->|tak| G(["Google Maps: aplikacja albo przeglądarka"])
  S -->|nie| E["EK-09 + snackbar: Nie udało się otworzyć map"]
  G -.->|Mapy bez dostępu do lokalizacji| GP(["Prośba systemowa dla Map / wybór startu w Mapach – nie ekran Tamitu"])
```

* start „Nocleg” z informacją o przybliżonym punkcie [U14]; bez noclegu w planie pozycja jest ukryta; „Poprzedni punkt dnia” ukryty przy pierwszym punkcie dnia (UX-TAM108-1). Przy domyślnym starcie wystarczy jedno dotknięcie. Tamitu nie
prosi o lokalizację i nie odczytuje pozycji (EK-10 wycofany). Brak sieci obsługuje Google Maps (ADR-0011 pkt 2).

## P7. Ustawienia, język, prywatność (US-003) – wzorce: lista i szczegóły, zgody

```mermaid
flowchart TD
  A["EK-04"] -->|Ustawienia| B["EK-12: Język, Prywatność, Polityka prywatności, Wyloguj, Usuń konto"]
  B -->|Język| C["Arkusz: Język systemu / Polski / English → natychmiastowa zmiana UI (plany bez zmian)"]
  B -->|Polityka| D(["Przeglądarka: wersja w języku UI"])
  B -->|Prywatność| E["EK-13: stan zgód z datami, informacja: plany tylko na urządzeniu [U9]"]
  E -->|Wycofaj zgodę na AI| F{"Zapis na serwerze"}
  F -->|OK| G["Stan: wycofano + snackbar; generowanie zablokowane z wyjaśnieniem"]
  F -->|brak sieci / błąd| H["Komunikat; zgoda bez zmian"]
  E -->|Wyraź zgodę| I["EK-06 lub zapis z EK-13"]
```

EK-13 nie pozwala „wycofać" akceptacji polityki [U15]; drogą jest usunięcie konta.

## P8. Wylogowanie (US-002)

```mermaid
flowchart TD
  A["EK-12"] -->|Wyloguj| B["EK-14 dialog: plany zostają na urządzeniu, wrócą po zalogowaniu tym kontem, inne konto ich nie zobaczy [U7]"]
  B -->|Wyloguj, działa offline [U8]| C["EK-02"]
  B -->|Anuluj| A
```

Wylogowanie niedostępne w trakcie generowania – EK-07 jest modalny [U8].

## P9. Usunięcie konta (US-010) – wzorzec: potwierdzenie działania destrukcyjnego (pełny ekran)

```mermaid
flowchart TD
  A["EK-12"] -->|Usuń konto| B["EK-15: ostrzeżenie (nieodwracalne; zakres: konto, plany na urządzeniu, zapisy zgód; logi 30 dni; konto Google poza Tamitu)"]
  B -->|Usuń konto na zawsze| N{"Sieć?"}
  N -->|brak| B1["Komunikat: wymaga internetu; nic nie usunięto"]
  N -->|jest| R(["System: ponowne uwierzytelnienie Google (jeśli wymagane)"])
  R -->|anulowano| B2["EK-15, dane nietknięte"]
  R -->|OK| P["Postęp usuwania (bez Anuluj)"]
  P -->|sukces| D["EK-02 + komunikat: konto usunięte"]
  P -->|błąd| E["Komunikat: co usunięto, Spróbuj ponownie (operacja idempotentna)"]
  P -->|przerwanie aplikacji| F["P2: dokończenie przy starcie"]
```

## P10. Limity i błędy (US-011) – wzorce: błąd z ponowieniem, brak sieci

```mermaid
flowchart TD
  A["Akcja Generuj plan"] --> B{"Wynik"}
  B -->|limit 5/dobę| C["Komunikat limitu z godziną odnowienia (czas lokalny); reszta aplikacji działa"]
  B -->|błąd usługi / sieci / zła odpowiedź| D["Komunikat EK-16 bez szczegółów; formularz zachowany; ponowienie z decyzji użytkownika"]
  B -->|limit globalny / wyłącznik kosztowy| E["Usługa chwilowo niedostępna (bez ujawniania powodu)"]
  B -->|wymagana aktualizacja [U3]| F["Stan: Zaktualizuj aplikację + link do sklepu"]
```

## Śledzenie: przepływ → ekrany → wzorce

| Przepływ | Ekrany | Wzorce (`patterns.md`) |
|---|---|---|
| P1 | EK-01, EK-02, EK-04 | 9, 8, 3 |
| P2 | EK-01, EK-03, EK-04, EK-02 | 8, 5 |
| P3 | EK-04, EK-05, EK-06, EK-07, EK-08, EK-16 | 2, 8, 4, 5, 6 |
| P4 | EK-07, EK-05 | 7 |
| P5 | EK-04, EK-08, EK-11 | 1, 7, 12 |
| P6 | EK-08, EK-09 | 11 |
| P7 | EK-12, EK-13, EK-06 | 1, 8, 11 |
| P8 | EK-12, EK-14, EK-02 | 7 |
| P9 | EK-12, EK-15, EK-02 | 7, 4, 5, 6 |
| P10 | EK-05, EK-07, EK-16 | 5, 6 |
