# Bramki zatwierdzeń

Na bramce orkiestrator przygotowuje raport (max ~15 linii), zapisuje go
w `.farm/log/` i **zatrzymuje pracę** do decyzji człowieka.

Format odpowiedzi człowieka: `ZATWIERDZAM` / `POPRAWKI: <uwagi>` / `ODRZUCAM`.

## G1 – Zakres (po fazie 1)
Sprawdź: zakres MVP i „poza zakresem", historyjki z kryteriami
akceptacji, ryzyka, wstępny rejestr danych osobowych, otwarte pytania.

## G2 – Architektura (po fazie 2)
Sprawdź: ADR (stack, backend, model AI, uwierzytelnianie), koszty
zmienne, model danych, model zagrożeń, zgodność z RODO, zależności od
dostawców.

## G5 – Wydanie (po fazie 5)
Sprawdź: raport QA bez blokerów, przegląd security, checklista
prywatności (polityka prywatności, zgody), koszty, notatki wydania.
Człowiek wykonuje samo publikowanie (konto sklepu, podpisy) – agenci
tego nie robią.

## Bramka techniczna w pętli (bez człowieka)
Testy zielone + werdykt QA „przyjęte" + (jeśli dotyczy) przegląd
security bez uwag blokujących.
