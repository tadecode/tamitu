# US-002: Wylogowanie

**Jako** zalogowany użytkownik **chcę** się wylogować, **aby** inna osoba korzystająca z telefonu nie miała dostępu do moich planów.

- Priorytet: MVP
- Dane osobowe: TAK (pośrednio) – dotyczy sesji powiązanej z identyfikatorem konta; wylogowanie usuwa sesję z urządzenia.

## Kryteria akceptacji
- **Given** zalogowany użytkownik **When** wybiera „Wyloguj" **Then** sesja zostaje zakończona i widzi ekran startowy.
- **Given** użytkownik wylogowany **When** otwiera aplikację **Then** nie widzi żadnych planów poprzedniego konta.
- **Given** użytkownik wylogowany **When** loguje się ponownie tym samym kontem **Then** widzi swoje zapisane plany (zgodnie z US-008, jeśli dane nie zostały usunięte).

## Uwagi / poza zakresem
Lokalne plany po wylogowaniu zostają, ale są niewidoczne dla innego konta (decyzja właściciela, N3).
