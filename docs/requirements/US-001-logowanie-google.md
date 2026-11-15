# US-001: Logowanie przez Google

**Jako** użytkownik **chcę** zalogować się kontem Google, **aby** korzystać z aplikacji bez zakładania hasła.

- Priorytet: MVP
- Dane osobowe: TAK – identyfikator konta dostawcy logowania (UID), adres e-mail i nazwa konta zwracane przez Google (zakres do potwierdzenia przez Security; zasada minimalizacji: aplikacja nie wymaga więcej niż UID).

## Kryteria akceptacji
- **Given** niezalogowany użytkownik na ekranie startowym **When** wybiera „Zaloguj przez Google" i kończy proces u dostawcy **Then** zostaje zalogowany i widzi ekran główny z listą planów.
- **Given** niezalogowany użytkownik **When** anuluje proces logowania u dostawcy **Then** wraca na ekran startowy i widzi komunikat bez błędu technicznego.
- **Given** brak połączenia z internetem **When** użytkownik próbuje się zalogować **Then** widzi komunikat o braku połączenia i może spróbować ponownie.
- **Given** zalogowany użytkownik **When** zamyka i ponownie uruchamia aplikację **Then** pozostaje zalogowany.
- **Given** dowolny stan aplikacji **Then** aplikacja nie oferuje rejestracji ani logowania hasłem i nie przechowuje haseł.
- **Given** użytkownik nie zaakceptował wymaganych zgód (US-003) **When** próbuje się zalogować **Then** logowanie jest zablokowane do czasu akceptacji.

## Uwagi / poza zakresem
Facebook, Apple, Microsoft – później (patrz scope.md; decyzja właściciela, pytanie 8: w pierwszym wydaniu tylko Google). Brak trybu gościa (N9).
