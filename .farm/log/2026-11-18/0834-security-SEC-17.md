# 08:34  security → owner, steward, orchestrator, mobile-dev, architect  |  SEC-17, O5
- Zrobione: przegląd IAM po P3-03 (konta `fn-*`, WIF z GH-010, klucze API, App Check, domyślne konta usług, poświadczenia CLI) – 2 blokery, 5 wysokich, 4 średnie, 8 niskich, z gotowymi poleceniami dla właściciela; O5 zweryfikowane w aktualnej dokumentacji Google (buforowanie niejawne Gemini ma też warstwę trwałą, 24 h; monitoring nadużyć – zapis promptów do 90 dni dla klientów na warunkach online); rejestr danych → v0.4 (D6, D10, D11, nowy D18).
- Artefakty: docs/security/review-SEC-17-iam.md, docs/security/personal-data-register.md
- Decyzje: brak nowych ADR; propozycja security: role niestandardowe zamiast predefiniowanych dla `fn-*` (realizacja w chmurze – właściciel; opis w runbooku etap 5)
- Do zrobienia przez odbiorcę:
  - owner: B-1 `disableCache=true` w dev i prod przed pierwszym wywołaniem Vertex (raport 4.1); W-1/W-2 role niestandardowe przed P3-05 (4.2); W-3 wylogowanie CLI po sesjach administracyjnych + ponowne uwierzytelnianie Google Cloud; W-5 odczyty kontrolne (4.4); Ś-4 klucze API; B-2 potwierdzić rodzaj umowy z Google (warunki online vs Master Agreement) i podjąć decyzję przy SEC-15 poz. 4
  - steward: GH-010 wg W-4 (warunek na `repository_id`/`repository_owner_id`, `ref`, dla prod `environment` + `job_workflow_ref`; wiązanie bez `/*`) i Ś-3 (minimalne role `ci-deployer`, bez `actAs` na koncie Compute)
  - mobile-dev (P3-05): bez jawnych cache, groundingu i request-response logging w wywołaniu Vertex; test E2E po zmianie ról (`PERMISSION_DENIED` → zgłosić brakujące uprawnienie)
  - architect: wpływ wyłączenia cache na koszt w `docs/architecture/costs.md` (pomijalny); SEC-15 poz. 4 w ADR-0001 (aneks)
- Pytania/blokady: B-2 (monitoring nadużyć) – decyzja właściciela + [PRAWNIK] przed `allowRealData=true`

## Dla orkiestratora (backlog i pytania)
- Backlog – status: SEC-17: in-progress → review (raport gotowy; zamknięcie po wykonaniu W-1, W-2, W-5 przez właściciela i W-4 w GH-010 – security sprawdza odczyty z 4.4)
- Backlog – nowe zadania:
  - SEC-31 (owner): poprawki IAM z SEC-17 – B-1, W-1, W-2, W-3, W-5, Ś-1, Ś-2, Ś-4, N-2, N-3; zależności: przed P3-05 (B-1, W-1, W-2), przed realnymi danymi (reszta)
  - SEC-32 (mobile-dev/security): wymagania P3-05 dla wywołania Vertex – bez `cachedContents`, groundingu, request-response logging; test uprawnień ról niestandardowych w dev
  - do GH-010 (steward): dopisać W-4 i Ś-3 jako warunki realizacji
- Pytania otwarte – nowe:
  - O6 (owner, [PRAWNIK]): Google może logować prompty Vertex do 90 dni (monitoring nadużyć) dla klientów na warunkach online; Master Agreement wyłącza to domyślnie. Akceptujemy i opisujemy w polityce/zgodzie AI, czy szukamy innej podstawy umownej? (SEC-15 poz. 4, rejestr D6)
  - O7 (orchestrator): ujednolicić „repo publiczne" (runbook P3-03, etap 0) vs „prywatne" (`CLAUDE.md`)
- Pytania otwarte – zamknięte (propozycja security):
  - O5: **wyłączamy** buforowanie Vertex AI w dev i prod (`cacheConfig.disableCache=true`, wyłącza warstwę w pamięci i trwałą) przed pierwszym wywołaniem Vertex (P3-05); wykonuje właściciel (raport SEC-17, 4.1); w kodzie bez jawnych cache i groundingu; polityka: „bez buforowania po stronie dostawcy, z wyjątkiem monitoringu nadużyć (O6)". Źródło: docs.cloud.google.com/vertex-ai/generative-ai/docs/vertex-ai-zero-data-retention (2026-11-18). Zamknięcie po potwierdzeniu wykonania (GET `cacheConfig` → `disableCache=true`) w runbooku, etap 9.
