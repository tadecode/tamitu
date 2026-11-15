# Wizja produktu: Tamitu

> Źródło: doc „Tamitu — kontekst projektu dla Claude Code" (https://claude.ai/artifact/WsrFdLjbUQETSBx6X8VFsf), stan na 2026-11-14.
> Uzupełnia i aktualizuje właściciel. To punkt wyjścia dla analityka.

- **Nazwa:** Tamitu (od „tam i tu"). Produkt firmy TadeCode (jednoosobowa działalność, tadecode.pl).
- **Problem, który rozwiązujemy:** przy planowaniu podróży w czatach AI trzeba przeskakiwać między aplikacjami, a po powrocie szukać od nowa tego, co chciało się sprawdzić. Tamitu ma trzymać wszystko w jednym miejscu i na bieżąco podpowiadać, co jest w pobliżu.
- **Odbiorcy:** osoby planujące podróże turystyczne i korzystające z telefonu w trakcie wyjazdu (do doprecyzowania przez analityka).
- **Kluczowe funkcje (MVP):**
  - Użytkownik podaje: cel podróży, bazę noclegową, liczbę dni, lot (lub przyjazd autem).
  - AI układa plan na każdy dzień, uwzględniając godzinę przylotu lub przyjazdu.
  - Integracja z mapami ograniczona do linku Google Maps z trasą: z bieżącej lokalizacji albo z zaplanowanego punktu startowego (auto, komunikacja, pieszo). Bez osadzania pełnej mapy.
  - Logowanie wyłącznie przez dostawców: Google, Facebook, Apple, Microsoft (np. Firebase Auth). Nie przechowujemy haseł użytkowników.
- **Funkcje na później:**
  - Zdjęcie zabytku → rozpoznanie obiektu i opis czytany na głos (TTS).
  - Zdjęcie menu w obcym języku → tłumaczenie i przykładowe zdjęcia dań.
- **Poza zakresem (na teraz):** pełna mapa w aplikacji, wersja iOS, własny system haseł.
- **Platformy i technologie (narzucone):** Flutter, na start tylko Android; pakiet `pl.tadecode.tamitu`. Firebase i Google Cloud (Gemini, Maps) na firmowym koncie Google TadeCode, projekty w regionie UE, z alertami budżetowymi. Model AI do wyboru przy implementacji (Gemini naturalnym kandydatem, ale decyzja w ADR).
- **Model biznesowy:** darmowa wersja z reklamami + płatna subskrypcja bez reklam (plan jednorazowy na jedną podróż oraz plan roczny). Najpierw ocena, czy się opłaca; cena tak, by dało się z tego żyć.
- **Dane osobowe przetwarzane (wstępnie):** identyfikator konta z logowania (Google/Facebook/Apple/Microsoft), plany i daty podróży, dane lotów i noclegów, lokalizacja (przy linkach do tras), identyfikator reklamowy i zgody (reklamy), dane przekazywane do modelu AI. Funkcje późniejsze: zdjęcia. Obowiązuje RODO.
- **Ograniczenia (budżet, termin, prawo):** RODO (pełna rola Security od początku); koszty zmienne wywołań AI i map pod kontrolą (alerty budżetowe); polityka prywatności na stronie firmy, np. `tadecode.pl/tamitu/prywatnosc`. Formalności firmowe (Google Play Console jako organizacja, D-U-N-S, 2FA, znak towarowy) prowadzi właściciel poza farmą.
- **Najbliższy cel:** działająca apka testowa na Androida. Proponowana kolejność: (1) szkielet projektu Flutter z pakietem `pl.tadecode.tamitu`; (2) logowanie przez Firebase Auth, zaczynając od Google; (3) formularz podróży → wywołanie AI → plan dnia; (4) przy każdym punkcie planu link do Google Maps z trasą; (5) build APK do testów.
