# FARM-004: Pakiet ról UX, DBA i analityk danych (szablon farmy 0.1.0)

- Zgłasza: sesja budowy farmy (na polecenie właściciela) · Data: 2026-11-16 · Odpowiedź na: FARM-003 (P3-14b)
- Typ: zmiana kontraktu farmy (`.claude/agents/`, `.farm/`, chronione; PR zatwierdza właściciel)
- Status: do przeglądu właściciela

## Po co
Zadanie P3-14 (mockup UI przed implementacją) nie miało wykonawcy. Zamiast osobnej roli `designer` dodajemy rolę
`ux` z szablonu farmy, rozszerzoną o to, co jest potrzebne do spójnego, „ładnego" UI:

- **Biblioteka komponentów** (`docs/ux/components/`): ekrany składane z gotowych klocków, nie rysowane od zera.
- **Zasady layoutu** (`docs/ux/layout.md`): siatka 4/8 dp, klasy rozmiaru okna, strefy kciuka, jedno główne działanie na ekran.
- **Wzorce projektowe** (`docs/ux/patterns.md`): formularz, pusty stan, błąd, brak sieci, zgody, pierwsze uruchomienie itd.
- **Makiety ekranów** (`docs/ux/mockups/<id>.html`): PL/EN, jasny i ciemny motyw, wszystkie stany, kryteria jakości
  (kontrast 4,5:1, cele dotyku 48 dp, Material 3).
- **Marka** (`docs/ux/brand.md`): kolory, logo, wzory aplikacji dostarcza właściciel; bez nich ux zgłasza pytanie i
  proponuje dwa warianty.

Dochodzą też role `dba` (schemat, zapytania, migracje) i `data-analyst` (plan pomiarów, koszty), z szablonu.

## Zawartość pakietu
| Plik | Zmiana |
|---|---|
| `.claude/agents/ux.md`, `dba.md`, `data-analyst.md` | nowe role |
| `docs/_templates/screen-spec.md`, `component-spec.md` | nowe szablony |
| `.claude/agents/orchestrator.md` | sekcja „Zadania z interfejsem", lista ról |
| `.claude/agents/mobile-dev.md` | wejście: specyfikacja `ux-ready` (zachowano katalog `backend` w uprawnieniach) |
| `.farm/workflows/phases.md`, `role-contract.md` | faza 2 i krok 1a pętli |
| `.farm/hooks/test-guards.ps1` | testy granic nowych ról (zachowano poprawkę stderr z CI) |

## Do wykonania przez właściciela
1. Zatwierdzić PR z pakietem (CODEOWNERS: `/.claude/`, `/.farm/hooks/`).
2. Dostarczyć materiały marki Tamitu (kolory, logo, wzory aplikacji) albo zdecydować, że ux ma zaproponować dwa warianty.
3. Orkiestrator zleca P3-14b roli `ux` (marka, design system, layout, komponenty, wzorce, potem makiety).

## Wpływ
Koszty: brak (role działają na żądanie). Bezpieczeństwo: zakres zapisu ux to `docs/ux/`, dba to `docs/data/schema|queries|migrations`,
data-analyst to `docs/analytics/`; granice sprawdza samotest hooków (105 PASS). RODO: makiety używają tylko danych wymyślonych.
