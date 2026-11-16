# Zasady układu (layout) – Tamitu

- Status: szkic, wersja 0.1 (2026-11-16, ux, P3-14b krok 1). Niezależne od wariantu marki.
- Tokeny odstępów, kształtów i typografii: `design-system.md`.

## 1. Siatka i odstępy

- Skala 4 dp, rytm 8 dp. Odstępy tylko z tokenów: 4, 8, 12, 16, 24, 32, 48 dp.
- **Margines ekranu: 16 dp** (`space-4`) z lewej i prawej na oknach compact.
- Między polami formularza: 16 dp; między sekcjami formularza: 24 dp (nagłówek sekcji titleSmall).
- Między kartami na liście: 8 dp; wnętrze karty: 16 dp.
- Treść odsuwa się od dolnej krawędzi o wysokość FAB + 16 dp, żeby ostatnia karta nie chowała się pod FAB.
- Hierarchię budujemy **odstępem i typografią**, nie liniami i ramkami. Separator (`outlineVariant`)
  tylko w listach ustawień między grupami.

## 2. Klasy rozmiaru okna

Projektujemy najpierw dla **compact** (telefon pionowo, szerokość < 600 dp; odniesienie: 360 × 800 dp).

| Klasa | Szerokość | Zachowanie |
|---|---|---|
| compact | < 600 dp | jedna kolumna; FAB w prawym dolnym rogu; arkusze dolne na całą szerokość |
| medium | 600–839 dp (telefon poziomo, składany, mały tablet) | treść w jednej kolumnie o maks. szerokości 600 dp, wyśrodkowana; formularz maks. 560 dp; dialogi i arkusze dolne maks. 640 dp |
| expanded | ≥ 840 dp | jak medium w MVP (aplikacja jest na telefon). Wzorzec lista–szczegóły (EK-04 + EK-08 obok siebie) **opisany jako kierunek**, nie wdrażany w MVP |

- Długość linii tekstu ciągłego (zgody, opisy) maks. ok. 70 znaków – na szerszych oknach ograniczamy szerokość kolumny.
- Orientacja pozioma na telefonie: działa (przewijanie pionowe), bez osobnego układu.

## 3. Struktura ekranu (zawsze taka sama)

```
┌────────────────────────────┐  pasek statusu (obszar bezpieczny)
│ [←]  Tytuł ekranu     [⚙]  │  pasek górny (CMP-01), 64 dp
├────────────────────────────┤
│  komunikat (CMP-13), jeśli │  opcjonalnie: AI / brak sieci / informacja
│  dotyczy                   │
│                            │
│  treść – przewijana        │  jedna oś przewijania (pionowa)
│  pionowo                   │
│                            │
│                 [+ Nowa…]  │  główne działanie: FAB albo przycisk na dole treści
└────────────────────────────┘  pasek nawigacji systemu (obszar bezpieczny)
```

- **Pasek górny**: tytuł ekranu po lewej (po ikonie wstecz), działania po prawej (maks. 2 ikony, reszta w menu).
- **Nawigacja: bez dolnego paska nawigacji.** Aplikacja ma dwa cele najwyższego poziomu (Plany i Ustawienia),
  a dolna nawigacja jest dla 3–5 celów. Ustawienia: ikona `settings-02` w pasku górnym listy planów (EK-04).
  Wszystkie pozostałe ekrany są zagnieżdżone (strzałka wstecz). Gdyby w przyszłości doszły kolejne cele
  (np. „W pobliżu"), przechodzimy na `NavigationBar`.
- **Wstecz systemowe** zawsze działa jak strzałka w pasku górnym; wyjątki opisane w przepływach
  (EK-07: wstecz = anulowanie z potwierdzeniem; EK-03: brak wyjścia poza „Wyloguj"/„Usuń konto").

## 4. Hierarchia działań

- **Jeden ekran = jedno główne działanie** w stylu wypełnionym (`FilledButton` lub FAB). Pozostałe: tonalne,
  outlined lub tekstowe.
- Miejsce głównego działania:
  - ekrany z listą (EK-04): rozszerzony FAB w prawym dolnym rogu (strefa kciuka),
  - formularze i ekrany treści (EK-02, EK-05, EK-06, EK-15): przycisk na pełną szerokość na **dole treści**
    (formularz) albo **przyklejony do dołu** ekranu, gdy treść jest krótsza niż ekran (ekrany zgód).
    Przy wysuniętej klawiaturze przycisk przewija się z treścią (nie zasłania pól),
  - dialogi: przyciski po prawej stronie, działanie potwierdzające z prawej.
- **Działania destrukcyjne** daleko od głównego: „Usuń plan" w menu paska górnego EK-08 (nie obok tras),
  „Usuń konto" na końcu listy Ustawień, oddzielone grupą.
- **Równorzędne wybory w zgodach** (EK-06 „Zgadzam się" / „Nie zgadzam się"): dwa przyciski **tej samej
  wagi wizualnej** (oba outlined lub oba tonalne – decyzja w kroku 2 z security), jeden nad drugim na
  całą szerokość (przy dużym tekście nie łamią się w połowie).

## 5. Strefy kciuka

- Najczęstsze działanie (Nowa podróż, wybór dnia, trasa do punktu) w dolnej 2/3 ekranu lub w zasięgu kciuka.
- Zakładki dni (EK-08) pod paskiem górnym (wzorzec M3), ale przełączanie także **przesunięciem** treści
  w poziomie (gest w zasięgu kciuka). To jedyny wyjątek od „jednej osi przewijania": przesuwanie między
  dniami zmienia stronę, nie przewija treści.
- Wybory z listy (trasa, język) w arkuszu dolnym (CMP-16) – blisko kciuka.

## 6. Obszary bezpieczne

- Treść w obrębie obszaru bezpiecznego (wcięcie aparatu, pasek statusu, pasek nawigacji gestami);
  tło i pasek górny mogą wchodzić pod pasek statusu (edge-to-edge, wymagane od Androida 15).
- Klawiatura: ekran z polami przewija aktywne pole nad klawiaturę; przycisk główny nie przykleja się do klawiatury.
- Snackbar nad FAB i nad paskiem nawigacji.

## 7. Przewijanie

- Jedna oś: pionowa. **Brak poziomego przewijania treści** (wyjątek: zakładki dni przy więcej niż 4–5 dniach
  są przewijalne poziomo – wzorzec M3 `scrollable tabs`; chipy zainteresowań **zawijają się** do
  kolejnych wierszy, nie przewijają poziomo).
- Pasek górny zostaje na miejscu; po przewinięciu zmienia kolor (elevation 2, `surfaceContainer`).

## 8. Cele dotyku i skalowanie

- Cel dotyku min. **48 × 48 dp**, odstęp między celami min. 8 dp. Elementy wizualnie mniejsze (checkbox 18 dp,
  ikona 24 dp) mają obszar dotyku 48 dp.
- Cały wiersz z checkboxem zgody (tekst + pole) jest celem dotyku.
- Tekst skaluje się do **200%** bez utraty treści i funkcji: brak stałych wysokości dla elementów z tekstem
  (karty, przyciski, segmenty rosną w pionie), etykiety zawijają się zamiast ucinać; przy 200% przyciski
  segmentowe z ≥ 3 opcjami przechodzą w listę wyboru (opisane w CMP-07).
- Teksty PL są zwykle o 20–30% dłuższe niż EN: każdy komponent ma zachowanie przy długim tekście.

## 9. Przewidywalność

Te same elementy w tym samym miejscu na każdym ekranie:
- wstecz – lewy górny róg; ustawienia – prawy górny róg listy planów,
- komunikaty kontekstowe (AI, brak sieci, „plany tylko na urządzeniu") – zawsze pod paskiem górnym, nad treścią,
- komunikaty chwilowe (potwierdzenia, „Cofnij") – snackbar na dole,
- błędy pól – pod polem; błędy ekranu – stan błędu w miejscu treści z „Spróbuj ponownie".

## 10. Ekran startowy, ekran ładowania aplikacji

- EK-01 (bramka sesji) wykorzystuje systemowy ekran powitalny Androida (ikona aplikacji na tle `surface`);
  bez własnego ekranu „splash" z animacją (brak migotania, wymaganie z macierzy stanów).
