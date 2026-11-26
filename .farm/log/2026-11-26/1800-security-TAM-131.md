# 18:00  security → owner, orchestrator  |  TAM-131 (REL-SEC-2)
- Zrobione: odpowiedzi do formularza Data Safety w Google Play w kolejności ekranów konsoli, bez lokalizacji
  (ADR-0017). Zbierane: e-mail, nazwa i UID konta (Firebase Auth), dane podróży wysyłane do AI („Inne treści
  użytkownika”), licznik użycia, zapis zgód, identyfikatory techniczne (App Check/Play Integrity, IP w logach).
  Udostępniane: nic (Firebase i Vertex AI – dostawcy usług; link Maps – działanie użytkownika). Szyfrowanie
  w przesyle: tak. Konto: OAuth (Google). Usuwanie: `deleteAccount` jeszcze nie działa – na czas testów
  wewnętrznych ręcznie na prośbę e-mailem; formularza nie wysyłać przed testami zamkniętymi (niewymagany).
- Artefakty: `docs/security/play-data-safety.md` (v0.1), `docs/open-questions.md` (sekcja TAM-131).
- Decyzje: brak nowych ADR; propozycje domyślne w O-TAM131-1…5. Koszt: 0. Kod bez zmian.
- Do zrobienia przez odbiorcę: właściciel – odpowiedzi na O-TAM131-1…5; przed testami zamkniętymi zmiany Z1–Z6
  z sekcji 6 dokumentu. Orkiestrator – przy następnej edycji `privacy-checklist.md` pkt 8 dodać odsyłacz do
  `play-data-safety.md` (nie edytowano teraz, żeby nie kolidować z TAM-132).
- Pytania/blokady: O-TAM131-1…5 (żadne nie blokuje testów wewnętrznych).
