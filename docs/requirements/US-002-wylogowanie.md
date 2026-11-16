# US-002: Wylogowanie

**Jako** zalogowany użytkownik **chcę** się wylogować, **aby** inna osoba korzystająca z telefonu nie miała dostępu do moich planów.

- Priorytet: MVP
- Dane osobowe: TAK (pośrednio) – dotyczy sesji powiązanej z identyfikatorem konta; wylogowanie usuwa sesję z urządzenia.

## Kryteria akceptacji
- **Given** zalogowany użytkownik **When** wybiera „Wyloguj" **Then** widzi komunikat z potwierdzeniem (przyciski „Wyloguj" i „Anuluj") o treści zawierającej: plany zostają zapisane na tym urządzeniu i będą dostępne po ponownym zalogowaniu tym samym kontem; nie zobaczy ich inna osoba logująca się innym kontem; można je usunąć, usuwając poszczególne plany (US-009) lub konto (US-010). Komunikat jest w języku interfejsu (PL/EN). **[ZMIANA P3-12/P3-14a – Security, przegląd 4-3; ADR-0004 pkt 3]**
- **Given** komunikat przy wylogowaniu **When** użytkownik wybiera „Anuluj" **Then** pozostaje zalogowany i nic się nie zmienia. **[ZMIANA P3-12]**
- **Given** zalogowany użytkownik i potwierdzony komunikat **When** wybiera „Wyloguj" **Then** sesja zostaje zakończona i widzi ekran startowy.
- **Given** trwa generowanie planu (US-005) **Then** wylogowanie nie jest dostępne do czasu zakończenia lub anulowania generowania. **[ZMIANA P3-14a – propozycja, U8]**
- **Given** użytkownik wylogowany **When** otwiera aplikację **Then** nie widzi żadnych planów poprzedniego konta.
- **Given** użytkownik wylogowany **When** loguje się ponownie tym samym kontem **Then** widzi swoje zapisane plany (zgodnie z US-008, jeśli dane nie zostały usunięte).

## Uwagi / poza zakresem
Lokalne plany po wylogowaniu zostają, ale są niewidoczne dla innego konta (decyzja właściciela, N3).
**[ZMIANA P3-14a]** Wzorcowa treść komunikatu z ADR-0004 („usuń je w Ustawieniach") sugeruje funkcję „usuń wszystkie plany", której nie ma w MVP (usuwanie pojedynczych planów – US-009; wszystkich – przez usunięcie konta). Treść poprawiona w tej historyjce; pytanie U7 w `docs/open-questions.md`.
