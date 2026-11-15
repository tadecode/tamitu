# Propozycje odpowiedzi do otwartych pytań

Dokument historyczny: pytania 1–8 i N1–N10 zostały odpowiedziane przez właściciela (2026-11-14), obowiązujące decyzje są w `docs/open-questions.md`. Poniższe propozycje zachowano dla porównania; w przypadku różnic (pyt. 7 – polski i angielski; N1 – z preferencjami; S6 – lokalizacja dokładna) wiążąca jest odpowiedź właściciela.

## Pytania istniejące

| # | Propozycja | Uzasadnienie |
|---|---|---|
| 1 | Gemini; decyzja w ADR z szacunkiem kosztów | Firmowe konto Google Cloud, region UE (wizja); pytanie dla architekta |
| 2 | Przez pośrednika (np. Cloud Functions) | Wymóg US-011: limity po stronie serwera i brak klucza w apce |
| 3 | dev + prod, region UE, alerty od początku; budżety ustawia właściciel | Zgodnie z wizją (alerty budżetowe) i ryzykiem R3 |
| 4 | Lokalizacja tylko na żądanie, na pierwszym planie, tylko do linku trasy; bez tła i bez „w pobliżu" w MVP | Minimalizacja danych; przyjęte w US-007 |
| 5 | Lokalnie w MVP; chmura później z wpisem w rejestrze | Mniej danych w chmurze, prostsze RODO; przyjęte w US-008; skutek: ryzyko R13 |
| 6 | Poza apką testową | Wizja: najpierw ocena opłacalności; najbliższy cel to apka testowa |
| 7 | Polski; minimalne API ustala architekt wg danych o urządzeniach | Brak informacji o odbiorcach w wizji |
| 8 | Tylko Google w pierwszym wydaniu | Wizja wskazuje start od Google |

## Nowe pytania do właściciela

| # | Pytanie | Propozycja domyślna |
|---|---|---|
| N1 | Czy formularz ma zawierać więcej pól, np. data wylotu/powrotu, preferencje (zainteresowania, budżet, tempo, liczba osób)? Wizja podaje tylko: cel, nocleg, liczba dni, lot/auto | Tylko pola z wizji + data i godzina przylotu/przyjazdu; bez preferencji w MVP |
| N2 | Maksymalna liczba dni podróży? | 14 dni |
| N3 | Co z lokalnymi planami po wylogowaniu: zostają czy są kasowane? | Zostają, niewidoczne dla innego konta |
| N4 | Limit generowania planów na konto na dobę? | 5 na dobę (do zmiany po pomiarze kosztu) |
| N5 | Czy zgoda na przekazanie danych do AI ma być osobnym polem wyboru? | Tak, osobna zgoda wymagana do generowania planu |
| N6 | Jaki bufor czasowy po przylocie (odprawa, dojazd) przyjąć? | 3 godziny po lądowaniu przy locie, 0 przy dojeździe autem |
| N7 | Okres przechowywania i zakres danych po usunięciu konta; czy eksport danych jest potrzebny? | Natychmiastowe usunięcie, bez eksportu w MVP; do decyzji Security |
| N8 | Kim są odbiorcy (wiek, jeden podróżny czy grupa)? Czy aplikacja jest tylko dla dorosłych? | Dorośli, indywidualni podróżni; grupa bez osobnej obsługi |
| N9 | Czy potrzebny jest tryb gościa bez logowania? | Nie (wizja wymaga logowania) |
| N10 | Kto jest administratorem danych i gdzie jest dostępna polityka prywatności w czasie testów? | TadeCode; strona tadecode.pl/tamitu/prywatnosc przed testami zewnętrznymi |
