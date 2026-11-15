# US-008: Zapis i lista planów

**Jako** użytkownik **chcę**, aby wygenerowane plany były zapisane i widoczne na liście, **aby** wrócić do nich w trakcie i po podróży.

- Priorytet: MVP
- Dane osobowe: TAK – zapisane plany, cele i daty podróży, noclegi, dane lotów, preferencje podróży (N1). Decyzja właściciela (pytanie 5): przechowywanie lokalnie na urządzeniu w MVP; zmiana na chmurę wymaga wpisu w rejestrze danych osobowych.

## Kryteria akceptacji
- **Given** poprawnie wygenerowany plan **When** generowanie się kończy **Then** plan jest automatycznie zapisany i pojawia się na liście planów.
- **Given** lista planów **Then** każdy wpis pokazuje cel, liczbę dni i datę utworzenia, posortowane od najnowszego.
- **Given** użytkownik bez planów **When** otwiera listę **Then** widzi pusty stan z przyciskiem „Nowa podróż".
- **Given** zapisane plany **When** aplikacja zostaje zamknięta i uruchomiona ponownie **Then** plany są nadal dostępne.
- **Given** brak internetu **When** użytkownik otwiera zapisany plan **Then** plan jest w pełni dostępny do odczytu (link do map wymaga internetu).
- **Given** dwa różne konta na tym samym urządzeniu **When** drugie loguje się **Then** nie widzi planów pierwszego.

## Uwagi / poza zakresem
Synchronizacja między urządzeniami i kopia w chmurze – później (pytanie 5). Udostępnianie planów innym osobom – poza zakresem.
