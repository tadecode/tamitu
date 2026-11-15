# US-011: Limity użycia AI i obsługa błędów

**Jako** właściciel produktu **chcę**, aby użycie AI było ograniczone limitami, **aby** koszty zmienne pozostały pod kontrolą.

- Priorytet: MVP
- Dane osobowe: TAK (pośrednio) – licznik użycia jest powiązany z identyfikatorem konta (podstawa: uzasadniony interes, S12 [PRAWNIK]).

## Kryteria akceptacji
- **Given** użytkownik zalogowany **When** generuje plany **Then** liczba generowań jest ograniczona do 5 na konto na dobę (N4; wartość do zmiany po pomiarze kosztu) i egzekwowana po stronie serwera, nie tylko w aplikacji.
- **Given** limit wyczerpany **When** użytkownik próbuje generować **Then** widzi komunikat z informacją, kiedy limit się odnowi.
- **Given** zapytanie bez uwierzytelnienia **When** trafia do usługi generowania **Then** jest odrzucane.
- **Given** wysłany formularz **Then** rozmiar danych wejściowych i odpowiedzi AI jest ograniczony (kontrola kosztu tokenów).
- **Given** przekroczenie progu budżetu projektu **Then** właściciel otrzymuje alert (konfiguracja – GitHub/Cloud Steward, DevOps; środowiska dev i prod, region UE, budżety ustawia właściciel – pyt. 3).
- **Given** błąd sieci lub usługi **Then** użytkownik widzi zrozumiały komunikat w języku interfejsu (polski lub angielski, pyt. 7), bez szczegółów technicznych.
- **Given** język interfejsu polski lub angielski **When** pojawia się komunikat o limicie lub błędzie **Then** jest on dostępny w obu językach (testowalne: komplet kluczy tłumaczeń).

## Uwagi / poza zakresem
Płatne plany zwiększające limity – poza apką testową (pyt. 6).
