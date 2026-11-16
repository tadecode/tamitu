# US-010: Usunięcie konta i danych

**Jako** użytkownik **chcę** usunąć swoje konto wraz ze wszystkimi danymi, **aby** korzystać ze swoich praw wynikających z RODO (prawo do usunięcia danych).

- Priorytet: MVP
- Dane osobowe: TAK – usuwane są: konto w usłudze logowania (UID), wszystkie plany i dane podróży, zapisane zgody **wraz z minimalnym serwerowym dowodem zgód (UID, wersja, wartość, data) – dowód jest usuwany razem z kontem (Q9, 2026-11-15; ADR-0002/0004/0005; potwierdzenie przez [PRAWNIK] – ewentualna zmiana wymaga nowego ADR i aktualizacji tej historyjki)**, dane lokalne. **[ZMIANA P3-12 – US-010 vs Q9; wcześniej: „poza minimalnym serwerowym dowodem zgód, okres po usunięciu [PRAWNIK], S3"]**

## Kryteria akceptacji
- **Given** zalogowany użytkownik **When** wybiera Ustawienia → „Usuń konto" **Then** widzi ostrzeżenie o nieodwracalności i musi je potwierdzić.
- **Given** ekran ostrzeżenia **Then** informuje, że usuwane są: konto w Tamitu, plany i dane podróży na urządzeniu, zapisy zgód na serwerze (w tym dowód zgód); że logi techniczne (identyfikator konta tylko jako skrót, bez treści) wygasają w ciągu 30 dni; że konto Google oraz dane w Google Maps/Google Play pozostają poza Tamitu. **[ZMIANA P3-12/P3-14a – Q9, privacy-checklist pkt 5]**
- **Given** konto usunięte **Then** na serwerze nie pozostaje żaden zapis zgód ani licznik użycia powiązany z kontem (test E2E: brak dokumentów po usunięciu, także po wywołaniu starym tokenem). **[ZMIANA P3-12 – Q9]**
- **Given** aplikacja zakończona w trakcie usuwania konta **When** zostaje uruchomiona ponownie **Then** dokończa usuwanie danych lokalnych i informuje o wyniku, zamiast pokazać plany. **[ZMIANA P3-14a – ADR-0004/flows pkt 4]**
- **Given** potwierdzenie **When** operacja się powiodła **Then** konto jest usunięte, plany i dane lokalne skasowane, a użytkownik wraca na ekran startowy.
- **Given** konto usunięte **When** użytkownik loguje się ponownie tym samym kontem Google **Then** startuje jako nowy użytkownik bez poprzednich planów.
- **Given** wymagane ponowne uwierzytelnienie (np. sesja zbyt stara) **When** użytkownik usuwa konto **Then** aplikacja prosi o ponowne zalogowanie i dokończenie usunięcia.
- **Given** brak internetu **When** użytkownik próbuje usunąć konto **Then** widzi komunikat, a dane nie są usuwane częściowo bez jasnej informacji.
- **Given** dane usunięte **Then** żadne dane użytkownika nie pozostają w usługach backendowych (w tym w kopiach i logach) dłużej niż okres określony przez Security (logi: 30 dni, bez treści, UID jako skrót – S7; usunięcie natychmiastowe – N7).
- **Given** funkcja usunięcia konta **Then** jest dostępna z poziomu aplikacji bez kontaktu z obsługą (wymóg sklepu Google Play).

## Uwagi / poza zakresem
Eksport danych w aplikacji – nie w MVP; dostęp do danych na wniosek e-mailem (decyzja właściciela, N7/S9). Instrukcja usunięcia danych na stronie internetowej (wymóg Google Play) – właściciel.
