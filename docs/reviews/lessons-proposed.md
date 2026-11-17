# Propozycje do checklist recenzji

Wypełnia recenzent. Właściciel przenosi zatwierdzone wnioski do `.farm/review/`
(tryb `FARM_MAINTENANCE=1`). Wzorzec trafia tu po ≥3 wystąpieniach.

| Data | Wzorzec problemu | Przykłady (PR, plik:linia) | Proponowana reguła do checklisty | Decyzja właściciela |
|---|---|---|---|---|
| 2026-11-17 | Kod Firestore w `backend/functions/src/index.ts` (odczyt/zapis, mapowanie dokumentów) bez testów – testy jednostkowe podmieniają zależność, a ścieżka produkcyjna nie jest sprawdzana | P3-02 `index.ts:34-35` (`loadRuntime`, SEC-22); PR #51 `index.ts:44-59` (`latestConsent`); PR #57 `index.ts:66-82` (`writeConsent`) | Backend: każdy odczyt/zapis Firestore ma test na emulatorze albo mapowanie wydzielone do czystej funkcji z testem jednostkowym; brak = ustalenie „średnia" | |
