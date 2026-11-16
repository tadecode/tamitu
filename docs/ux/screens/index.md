# Specyfikacje ekranów – Tamitu (MVP)

Krok 2 zadania P3-14b (ux, 2026-11-16), wariant marki A „Lazur". Każdy ekran: specyfikacja `ek-xx.md` (wg `docs/_templates/screen-spec.md`) i makieta `../mockups/ek-xx.html` (PL/EN, jasny/ciemny, skala tekstu, stany).

| ID | Ekran | US | Przegląd security | Status |
|---|---|---|---|---|
| [EK-01](ek-01.md) | Start (bramka sesji) | US-001, 002, 003, 010 | tak (stan U12 → usunięcie konta) | zatwierdzony (MVP) |
| [EK-02](ek-02.md) | Ekran startowy: prywatność i logowanie | US-001, 003 | **tak** | zatwierdzony (MVP) |
| [EK-03](ek-03.md) | Ponowna akceptacja polityki | US-003 | **tak** | zatwierdzony (MVP) |
| [EK-04](ek-04.md) | Lista planów | US-008 | nie | zatwierdzony (MVP) |
| [EK-05](ek-05.md) | Formularz podróży | US-004, 006 | tak (podpowiedzi o danych) | zatwierdzony (MVP) |
| [EK-06](ek-06.md) | Zgoda na AI | US-003, 005 | **tak + [PRAWNIK]** | zatwierdzony (MVP) |
| [EK-07](ek-07.md) | Generowanie planu | US-005, 011 | nie | zatwierdzony (MVP) |
| [EK-08](ek-08.md) | Widok planu | US-005, 006, 008, 009 | nie | zatwierdzony (MVP) |
| [EK-09](ek-09.md) | Wybór trasy | US-007 | **tak** (lokalizacja) | zatwierdzony (MVP) |
| [EK-10](ek-10.md) | Wyjaśnienie i prośba o lokalizację | US-007 | **tak** | zatwierdzony (MVP) |
| [EK-11](ek-11.md) | Potwierdzenie usunięcia planu | US-009 | nie | zatwierdzony (MVP) |
| [EK-12](ek-12.md) | Ustawienia | US-002, 003, 010 | tak (wejścia) | zatwierdzony (MVP) |
| [EK-13](ek-13.md) | Prywatność | US-003 | **tak** | zatwierdzony (MVP) |
| [EK-14](ek-14.md) | Potwierdzenie wylogowania | US-002 | tak (treść, U7) | zatwierdzony (MVP) |
| [EK-15](ek-15.md) | Usunięcie konta | US-010 | **tak** | zatwierdzony (MVP) |
| [EK-16](ek-16.md) | Katalog komunikatów | US-011 | tak (brak ujawniania szczegółów) | zatwierdzony (MVP) |

**Zatwierdzenie właściciela 2026-11-16:** „do wersji mvp zatwierdzam ekrany” – wszystkie ekrany EK-01..EK-16 w wersji MVP, wraz z propozycjami domyślnymi z otwartych pytań (U1–U15, UX2–UX13), na których się opierają. Zmiana odpowiedzi na któreś z tych pytań = zmiana ekranu i ponowne zatwierdzenie.

Kolejne kroki (`.farm/workflows/phases.md` krok 1a): architekt sprawdza tabele „Dane na ekranie" i sekcje „Uzgodnienie z architektem" względem `docs/api/` i `docs/data/`; security przegląda ekrany oznaczone **tak**; ux nanosi poprawki; orkiestrator oznacza ekrany `ux-ready` w backlogu.
