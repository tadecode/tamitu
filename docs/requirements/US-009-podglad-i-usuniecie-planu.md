# US-009: Podgląd i usunięcie pojedynczego planu

**Jako** użytkownik **chcę** przeglądać szczegóły planu dzień po dniu i usuwać niepotrzebne plany, **aby** mieć porządek i kontrolę nad swoimi danymi.

- Priorytet: MVP
- Dane osobowe: TAK – wyświetla dane podróży (cel, daty, nocleg, lot); usunięcie kasuje te dane z urządzenia.

## Kryteria akceptacji
- **Given** lista planów **When** użytkownik wybiera plan **Then** widzi dane podróży (cel, baza noclegowa, godzina przylotu/przyjazdu) i plan podzielony na dni z punktami.
- **Given** widok planu **When** użytkownik przechodzi między dniami **Then** widzi punkty wybranego dnia w kolejności pór.
- **Given** widok planu **When** wybiera „Usuń plan" **Then** aplikacja prosi o potwierdzenie.
- **Given** potwierdzone usunięcie **Then** plan znika z listy i jego dane są trwale usunięte z pamięci aplikacji.
- **Given** anulowane potwierdzenie **Then** plan pozostaje bez zmian.

## Uwagi / poza zakresem
Edycja treści planu, kopiowanie i udostępnianie – później / poza zakresem.
