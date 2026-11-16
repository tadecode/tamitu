# US-005: Plan na każdy dzień generowany przez AI

**Jako** użytkownik **chcę** otrzymać plan na każdy dzień podróży ułożony przez AI w wybranym języku (polskim lub angielskim), **aby** nie szukać pomysłów w wielu aplikacjach.

- Priorytet: MVP
- Dane osobowe: TAK – dane z formularza (US-004), **w tym preferencje: zainteresowania, budżet, tempo zwiedzania, liczba osób (N1)**, są przekazywane do modelu AI; wygenerowany plan jest powiązany z kontem. Do modelu NIE wysyłamy e-maila, nazwy konta ani UID (zasada minimalizacji). Do czasu potwierdzenia warunków u dostawcy AI (S5, ADR) nie wysyłamy prawdziwych danych.

## Kryteria akceptacji
- **Given** poprawny formularz i osobna zgoda na AI (N5) **When** użytkownik zatwierdza **Then** otrzymuje plan zawierający dokładnie tyle dni, ile podano, każdy z listą punktów (nazwa miejsca, krótki opis, orientacyjna pora).
- **Given** formularz z preferencjami **When** plan jest generowany **Then** preferencje (zainteresowania, budżet, tempo, liczba osób) są przekazane do generowania, a liczba punktów dziennie odpowiada wybranemu tempu (testowalne: wolne tempo – mniej punktów dziennie niż szybkie, w ramach zakresu ustalonego przez architekta).
- **Given** użytkownik wybrał język planu polski lub angielski (domyślnie język interfejsu – propozycja, N11) **When** plan jest wygenerowany **Then** nazwy dni, opisy i komunikaty planu są w wybranym języku (testowalne: automatyczne wykrycie języka opisów na zestawie przypadków w obu językach).
- **Given** język interfejsu różny od języka planu **When** użytkownik wyświetla plan **Then** elementy interfejsu są w języku interfejsu, a treść planu w języku planu; informacja o AI (poniżej) jest w języku interfejsu.
- **Given** język planu **When** plan jest zapisany (US-008) **Then** po zmianie języka interfejsu treść zapisanego planu pozostaje w oryginalnym języku.
- **Given** trwa generowanie **Then** użytkownik widzi wskaźnik postępu i może anulować; po anulowaniu nic nie jest zapisane, a użytkownik wraca do formularza z zachowanymi danymi.
- **Given** użytkownik anuluje generowanie **Then** widzi informację, że wykorzystanie limitu dziennego może nie zostać zwrócone, jeśli generowanie już się rozpoczęło (zasada limitu – US-011, Q12). **[ZMIANA P3-12/P3-14a]**
- **Given** użytkownik używa przycisku „wstecz" systemu w trakcie generowania **Then** jest traktowane jak próba anulowania (z potwierdzeniem). **[ZMIANA P3-14a – propozycja]**
- **Given** odpowiedź AI nie spełnia oczekiwanego formatu (np. zła liczba dni, brak punktów, język inny niż żądany) **When** system ją waliduje **Then** ponawia próbę ograniczoną liczbę razy, a po niepowodzeniu pokazuje komunikat o błędzie bez zapisywania częściowego planu.
- **Given** model AI jest niedostępny lub przekroczono limit czasu **When** użytkownik czeka **Then** widzi komunikat i może spróbować ponownie, a dane formularza nie są utracone.
- **Given** użytkownik wygenerował już 5 planów w ciągu doby na koncie (N4; wartość do zmiany po pomiarze kosztu) **When** próbuje kolejny **Then** widzi informację o limicie (US-011).
- **Given** wygenerowany plan **Then** w widoku planu jest widoczna informacja, że plan stworzyła AI i może zawierać błędy, oraz że godziny otwarcia i dostępność należy zweryfikować.
- **Given** wywołanie AI **Then** żadne wywołanie nie zawiera klucza dostępowego po stronie aplikacji (AI wywoływane przez pośrednika – decyzja właściciela, pyt. 2) i w logach nie ma treści formularza.

## Uwagi / poza zakresem
Model: kierunek Gemini, finalny wybór i koszty w ADR (pyt. 1, architekt). Edycja planu ręczna i regeneracja pojedynczego dnia – później. Języki: polski i angielski (pyt. 7); dodatkowe języki – poza MVP. Sposób wyboru języka planu (osobne pole vs. język interfejsu) – propozycja w N11.
