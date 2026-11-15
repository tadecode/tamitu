# US-006: Plan uwzględnia godzinę przylotu lub przyjazdu

**Jako** użytkownik **chcę**, aby pierwszy dzień planu uwzględniał godzinę mojego przylotu lub przyjazdu, **aby** plan był realny do wykonania.

- Priorytet: MVP
- Dane osobowe: TAK – data i godzina przylotu/przyjazdu oraz lotnisko (dane o podróży przekazywane do AI, jak w US-005).

## Kryteria akceptacji
- **Given** przylot o 18:00 **When** plan jest wygenerowany **Then** pierwszy dzień nie zawiera punktów zaplanowanych przed godziną przylotu powiększoną o bufor na dojazd do bazy noclegowej (bufor: 3 h po lądowaniu przy locie, 0 przy dojeździe autem – decyzja właściciela, N6).
- **Given** przylot o 06:00 **When** plan jest wygenerowany **Then** pierwszy dzień zawiera aktywności od przybliżonej pory po dotarciu do noclegu, bez punktów przed przylotem.
- **Given** przyjazd autem o 14:00 **When** plan jest wygenerowany **Then** żaden punkt pierwszego dnia nie ma pory wcześniejszej niż 14:00.
- **Given** przylot późną nocą (po 22:00) **Then** pierwszy dzień zawiera co najwyżej dotarcie do noclegu, a aktywności zaczynają się od dnia drugiego.
- **Given** plan wygenerowany **When** automatyczny test sprawdza pory punktów pierwszego dnia **Then** żadna nie jest wcześniejsza niż godzina przylotu/przyjazdu (walidacja po stronie systemu, nie tylko prompt).
- **Given** wyświetlony plan **Then** pierwszy dzień pokazuje wprowadzoną godzinę przylotu/przyjazdu.

## Uwagi / poza zakresem
Śledzenie opóźnień lotów i dynamiczna zmiana planu – poza zakresem. Godzina powrotu/wylotu ostatniego dnia – poza MVP (N1 obejmuje tylko datę/godzinę przylotu).
