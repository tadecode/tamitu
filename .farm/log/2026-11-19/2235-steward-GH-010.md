# 22:35  steward → owner, orchestrator  |  GH-010
- Zrobione: próbne wdrożenie `firestore:indexes` w dev przez `deploy.yml` (run 44628899645, `success`; indeksy i TTL `expireAt` dla `usage` i `usage_global`). Zgoda właściciela w czacie.
- Artefakty: `.farm/requests/GH-010-wif-deploy.md` (odpowiedź Stewarda), `docs/github-ops/log.md`
- Decyzje: brak
- Do zrobienia przez odbiorcę:
  - owner: zatwierdzenie ADR-0014; `iam.serviceAccountUser` na kontach `fn-*` dla `ci-deployer` (przed próbą `functions` w dev); konfiguracja prod wg W-4 i zawężenie ról (Ś-3) – osobny krok.
- Pytania/blokady: `functions` w dev czeka na ADR-0014, role `fn-*` i P3-05

## Dla orkiestratora (zadania i pytania)
- Zadania – status: bez zmian
- Zadania – nowe: brak
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak
