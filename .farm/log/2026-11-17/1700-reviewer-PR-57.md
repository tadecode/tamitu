# 17:00  reviewer → orchestrator, mobile-dev  |  przegląd PR #57 (P3-04)
- Zrobione: przegląd PR #57 (head `7263957`, CI zielone) – rekomendacja ZMIANY WYMAGANE (0 blokerów, 2 wysokie, 3 średnie, 3 drobne); backend `recordConsent` idempotentny i poprawny, klient bez logów i sekretów, testy dostępności i odcisk tekstów zgód – dobre
- Artefakty: docs/reviews/PR-57.md, docs/reviews/lessons-proposed.md (wzorzec: Firestore w `index.ts` bez testów), komentarz w PR #57
- Decyzje: brak
- Do zrobienia przez odbiorcę: mobile-dev – App Check w aplikacji (ust. 2), dosyłanie wpisu tymczasowego po restarcie (ust. 1c), blokada `TAMITU_FAKE_BACKEND` w release (ust. 3), jedna synchronizacja w locie (ust. 5), komunikat przy nieudanym otwarciu linku (ust. 6), testy emulatora zapisu (ust. 4); owner/orchestrator – czy P3-04 może być `done` przed P3-06 (ust. 1); po poprawkach QA wg `docs/qa/test-plan-p3-04.md`
- Pytania/blokady: brak

## Dla orkiestratora (backlog i pytania)
- Backlog – status: P3-04 – przegląd: zmiany wymagane (`docs/reviews/PR-57.md`)
- Backlog – nowe zadania: poprawki P3-04 po przeglądzie (ust. 1–6) dla mobile-dev; architekt/DBA – pole `clientAtCorrected` w modelu danych (ust. 7); propozycja do checklist w `lessons-proposed.md` – decyzja właściciela
- Pytania otwarte – nowe: architekt – czy wpis tymczasowy z EK-02 można dosłać przy starcie z sesją (ust. 1c); czy `recordConsent` ma odrzucać ponowienie `consentId` z inną treścią (ust. 8)
- Pytania otwarte – zamknięte: brak
