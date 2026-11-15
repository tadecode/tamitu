# US-010: Usunięcie konta i danych

**Jako** użytkownik **chcę** usunąć swoje konto wraz ze wszystkimi danymi, **aby** korzystać ze swoich praw wynikających z RODO (prawo do usunięcia danych).

- Priorytet: MVP
- Dane osobowe: TAK – usuwane są: konto w usłudze logowania (UID), wszystkie plany i dane podróży, zapisane zgody (poza minimalnym serwerowym dowodem zgód – UID, wersja, wartość, data; okres przechowywania po usunięciu: [PRAWNIK], S3), dane lokalne.

## Kryteria akceptacji
- **Given** zalogowany użytkownik **When** wybiera Ustawienia → „Usuń konto" **Then** widzi ostrzeżenie o nieodwracalności i musi je potwierdzić.
- **Given** potwierdzenie **When** operacja się powiodła **Then** konto jest usunięte, plany i dane lokalne skasowane, a użytkownik wraca na ekran startowy.
- **Given** konto usunięte **When** użytkownik loguje się ponownie tym samym kontem Google **Then** startuje jako nowy użytkownik bez poprzednich planów.
- **Given** wymagane ponowne uwierzytelnienie (np. sesja zbyt stara) **When** użytkownik usuwa konto **Then** aplikacja prosi o ponowne zalogowanie i dokończenie usunięcia.
- **Given** brak internetu **When** użytkownik próbuje usunąć konto **Then** widzi komunikat, a dane nie są usuwane częściowo bez jasnej informacji.
- **Given** dane usunięte **Then** żadne dane użytkownika nie pozostają w usługach backendowych (w tym w kopiach i logach) dłużej niż okres określony przez Security (logi: 30 dni, bez treści, UID jako skrót – S7; usunięcie natychmiastowe – N7).
- **Given** funkcja usunięcia konta **Then** jest dostępna z poziomu aplikacji bez kontaktu z obsługą (wymóg sklepu Google Play).

## Uwagi / poza zakresem
Eksport danych w aplikacji – nie w MVP; dostęp do danych na wniosek e-mailem (decyzja właściciela, N7/S9). Instrukcja usunięcia danych na stronie internetowej (wymóg Google Play) – właściciel.
