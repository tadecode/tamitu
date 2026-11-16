# US-003: Informacja o prywatności i zgody

**Jako** użytkownik **chcę** wiedzieć, jakie dane są przetwarzane i móc wyrazić lub cofnąć zgody, **aby** świadomie decydować o swoich danych.

- Priorytet: MVP
- Dane osobowe: TAK – zapis decyzji o zgodach (rodzaj zgody, wartość, data); dane o zgodach są danymi osobowymi powiązanymi z kontem.

## Kryteria akceptacji
- **Given** pierwsze uruchomienie aplikacji **When** użytkownik widzi ekran startowy **Then** jest link do polityki prywatności (np. tadecode.pl/tamitu/prywatnosc) oraz informacja o przekazywaniu danych podróży do modelu AI, przed logowaniem.
- **Given** użytkownik nie zaakceptował polityki prywatności **When** próbuje przejść dalej **Then** nie może się zalogować ani używać funkcji AI.
- **Given** użytkownik zalogowany, który nie wyraził jeszcze zgody na AI **When** po raz pierwszy zatwierdza formularz podróży (US-004) **Then** przed wysłaniem danych widzi osobną zgodę na AI (niezaznaczoną domyślnie, z równorzędnymi opcjami „Zgadzam się" i „Nie zgadzam się"), której treść wymienia: dane podróży, preferencje, język planu, odbiorcę (dostawca AI, region UE), że nie wysyłamy e-maila, nazwy, identyfikatora konta, lokalizacji ani numeru lotu, że plan może zawierać błędy, oraz ostrzeżenie, by nie wpisywać pełnego adresu prywatnego ani danych wrażliwych/osób trzecich. **[ZMIANA P3-14a – kolejność wg privacy-checklist pkt 2]**
- **Given** odmowa zgody na AI w tym momencie **Then** użytkownik wraca do formularza z zachowanymi danymi, nic nie jest wysyłane, a licznik limitu nie jest zużyty. **[ZMIANA P3-14a]**
- **Given** zgoda na AI została już wyrażona **When** użytkownik ponownie generuje plan **Then** zgoda nie jest pytana ponownie (do zmiany wersji zgody lub cofnięcia). **[ZMIANA P3-14a]**
- **Given** użytkownik zaakceptował zgody **When** otwiera Ustawienia → Prywatność **Then** widzi aktualny stan zgód i datę ich wyrażenia.
- **Given** zgoda na przekazanie danych do AI została cofnięta **When** użytkownik próbuje wygenerować plan **Then** generowanie jest zablokowane z wyjaśnieniem i możliwością ponownego wyrażenia zgody.
- **Given** użytkownik w Ustawieniach **Then** ma dostęp do linku polityki prywatności i do usunięcia konta (US-010).
- **Given** zmiana wersji polityki lub nowy cel przetwarzania **When** użytkownik uruchamia aplikację **Then** jest proszony o ponowną akceptację.

## Uwagi / poza zakresem
Zgody na reklamy (identyfikator reklamowy, CMP) – później, razem z reklamami (pytanie 6: poza apką testową). Treść polityki i podstawy prawne – Security/właściciel; dane administratora (nazwa, adres, NIP) uzupełnia właściciel (N10/S1), kontakt RODO: tamitu@tadecode.pl (S8). Zgoda na AI jest osobnym polem zgody (decyzja właściciela, N5); zgoda obejmuje także preferencje z formularza (N1). Dostęp do danych na wniosek e-mailem (N7/S9). Polityka i zgody dostępne po polsku i angielsku (pyt. 7). Tylko dorośli (N8/S12).
