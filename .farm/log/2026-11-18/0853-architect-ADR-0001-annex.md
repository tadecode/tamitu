# 08:53  architect → orchestrator, owner, security, mobile-dev, qa  |  ADR-0001-annex (O1, O2, O3)
- Zrobione: zweryfikowano w dokumentacji Google (2026-11-18) i rozstrzygnięto O1–O3. O1 → ADR-0001 Aneks B (przetwarzanie ML Flash w UE, nie wyłącznie NL; dopuszczalne punkty `europe-west4`/`eu`; nowe brzmienie SEC-15 poz. 3). O2, O3 → nowy ADR-0014 (ADR-0002 Aneks A zabrania późniejszych zmian bez nowego ADR); odnośniki dopisane na końcu ADR-0002 i ADR-0003. Zaktualizowano `overview.md` i `zewnetrzne-integracje.md`. **Nowe ustalenie:** `gemini-2.5-flash` i `gemini-2.5-flash-lite` wycofane 2026-10-20 – kandydaci do ewaluacji: `gemini-3.5-flash`, `gemini-3.8-flash`, `gemini-3.5-flash-lite`, `gemini-3.1-flash-lite` (Aneks B pkt 3).
- Artefakty: docs/adr/0001-model-ai-gemini-vertex.md (Aneks B), docs/adr/0014-korekty-po-p3-03-konto-uslugi-i-limit-wydatkow.md, docs/adr/0002-posrednik-ai-cloud-functions.md, docs/adr/0003-firebase-srodowiska-region-budzety.md (odnośniki), docs/architecture/overview.md, docs/api/zewnetrzne-integracje.md
- Decyzje: Aneks B i ADR-0014 w statusie **proponowany** – zatwierdza właściciel (bramka „architektura"). Spend cap tylko na `aiplatform` (prod 80 PLN, dev 15 PLN – propozycja), nigdy na Functions/Cloud Run (zablokowałby `deleteAccount`, ADR-0011 pkt 4).
- Do zrobienia przez odbiorcę:
  - owner – zatwierdzić ADR-0001 Aneks B i ADR-0014; w P3-09 sprawdzić w konsoli, czy spend cap jest oznaczony „Preview", i ustawić kwoty;
  - security (bez edycji przez architekta – katalog Security): `personal-data-register.md` D6 („przetwarzanie ML w UE, multi-region `eu`, bez gwarancji NL"; punkt `europe-west4` lub `eu`); `privacy-checklist.md` pkt Vertex AI (l. 42) i „Transfery poza EOG" (l. 127: AI „w UE", Holandia tylko dla Firestore/logów); `przeglad-adr.md` 1-1 / SEC-15 poz. 3 – nowe brzmienie z Aneksu B pkt 5; SEC-15 poz. 4 / O5 – dokumentacja „Data residency" nie podaje lokalizacji bufora 24 h; SEC-17 – nazwa `fn-ai-plan` w przeglądzie IAM (stare wzmianki `fn-ai` w `przeglad-adr.md` 2-3 i `reviews/2026-11-16-p3-02-backend.md` są historyczne);
  - mobile-dev – SEC-20: `serviceAccount: fn-ai-plan@…` dla `generatePlan`; walidacja lokalizacji Vertex przyjmuje dokładnie `europe-west4` lub `eu`; przed P3-05 test w `dev` (dane syntetyczne): czy wybrany model 3.x działa na `europe-west4` – wynik do runbooka P3-03 (Aneks B pkt 4); w P3-09 mapowanie błędu wstrzymania Vertex na `ai_unavailable` bez ponowienia;
  - qa – w planie testów ewaluacji modelu: tylko kandydaci z Aneksu B pkt 3.
- Pytania/blokady: brak blokad. Niepotwierdzone: (1) obsługa modeli 3.x na punkcie `europe-west4` (test mobile-dev); (2) status GA/Preview spend cap (strona Google go nie podaje); (3) kod błędu Vertex po zadziałaniu capu.

## Źródła (dostęp 2026-11-18)
- https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/data-residency – Flash: gwarancja ML w `eu`, kolumna Holandia pusta; `eu` = tylko państwa UE; `global` bez gwarancji.
- https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/locations – punkt końcowy sam nie gwarantuje lokalizacji.
- https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versions – daty wycofania modeli.
- https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/2-5-flash – wycofanie 2026-10-20; regiony ML bez `europe-west4`.
- https://docs.cloud.google.com/iam/docs/service-accounts-create, https://docs.cloud.google.com/iam/docs/reference/rest/v1/projects.serviceAccounts/create – ID konta 6–30 znaków, bez zmiany nazwy.
- https://docs.cloud.google.com/billing/docs/how-to/budgets-spend-caps – spend cap: projekt × usługa, `aiplatform`/`run`/`cloudfunctions`/`generativelanguage`, wstrzymanie nowego użycia, szacunek brutto, nie natychmiast, zniesienie ręczne lub od nowego miesiąca.

## Dla orkiestratora (backlog i pytania)
- Backlog – status: brak (SEC-15 pozostaje otwarte; poz. 3 częściowo potwierdzona przez architekta)
- Backlog – nowe zadania: (a) mobile-dev – test obsługi wybranego modelu 3.x na `europe-west4` w `dev`, przed P3-05; (b) P3-09 – rozszerzyć o spend cap `aiplatform` (owner) i mapowanie błędu (mobile-dev); (c) security – aktualizacja D6 / privacy-checklist / SEC-15 poz. 3 wg Aneksu B; (d) architect – przeliczenie `costs.md` dla kandydatów z Aneksu B pkt 3 przy ewaluacji modelu
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte (propozycje odpowiedzi, po zatwierdzeniu ADR przez właściciela):
  - **O1:** Przyjęte z doprecyzowaniem – region funkcji/Firestore/logów bez zmian (`europe-west4`); wywołanie Vertex z punktu `europe-west4` (lub `eu`, jeśli model nie jest tam obsługiwany); przetwarzanie ML „w UE" (gwarancja multi-region `eu`, nie NL); zakaz `global` zostaje. Zapis: ADR-0001 Aneks B. SEC-15 poz. 3 – nowe brzmienie, potwierdza Security dla wybranego modelu. Uwaga: `gemini-2.5-*` wycofane – kandydaci w Aneksie B pkt 3.
  - **O2:** Tak – `fn-ai-plan@<projekt>.iam.gserviceaccount.com` dla `generatePlan`, role bez zmian. Zapis: ADR-0014 pkt 1 + odnośnik w ADR-0002; kod: SEC-20.
  - **O3:** Tak, w P3-09 – spend cap Cloud Billing wyłącznie na `aiplatform` (prod 80 PLN, dev 15 PLN – kwoty decyduje właściciel), jako warstwa obok `budgetGuard`; bez capu na Functions/Cloud Run. Gdy konsola oznacza funkcję jako Preview – świadoma akceptacja właściciela. Zapis: ADR-0014 pkt 2 + odnośnik w ADR-0003.
