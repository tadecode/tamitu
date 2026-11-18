# 09:50  orchestrator → owner, mobile-dev, steward, security, qa  |  backlog po fali 1 (PR #67–#71)
- Zrobione: wyniki PR #67, #68, #69, #70, #71 przeniesione do `docs/backlog.md` i `docs/open-questions.md`. SEC-20 → done (PR #70, przegląd PR #71 „do akceptacji”). SEC-17 zostaje in-progress (raport gotowy; poprawki właściciela w chmurze = nowe SEC-31; zamknięcie po SEC-31 i W-4/Ś-3 w GH-010). O1, O2, O3 → rozstrzygnięte w ADR-0001 Aneks B i ADR-0014 (status „proponowany”), więc w backlogu `review`, czekają na zatwierdzenie właściciela; O5 → decyzja „wyłączamy”, wykonanie = SEC-31 B-1, zamknięcie po potwierdzeniu. O4 bez zmian (dba, `docs/O4-usage-ttl`). P3-04: dopisano, że testy integracyjne robi QA na `docs/qa-P3-04-int`. GH-009: dopisany warunek z przeglądu PR #70 (flaga `-Ptamitu.allowMissingGoogleServices=true`, nie `CI`); nowe SEC-33 (mobile-dev, `build.gradle.kts`).
- Artefakty: docs/backlog.md, docs/open-questions.md, .farm/requests/GH-009-ci-firebase-config-secrets.md
- Decyzje: brak (ADR-0001 Aneks B i ADR-0014 nie zatwierdzam – bramka właściciela)
- Do zrobienia przez odbiorcę:
  - owner: zatwierdzić ADR-0001 Aneks B i ADR-0014; SEC-31 (B-1 wyłączenie cache Vertex, W-1/W-2 role niestandardowe przed P3-05, W-3, W-5 itd.); B-2 i P3-09 (spend cap, status Preview)
  - mobile-dev: SEC-33; porządki z przeglądu PR #70 (ust. 4)
  - steward: GH-009 po SEC-33; GH-010 z W-4 i Ś-3 (nie dopisałem ich do prośby – poza zakresem tego zadania)
  - security: D6/privacy-checklist/SEC-15 poz. 3 wg Aneksu B
- Pytania/blokady: nie wpisałem (poza zakresem „tylko te wiersze”) propozycji z raportu SEC-17: SEC-32 (wymagania P3-05 dla Vertex: bez cache/groundingu/request-response logging), O6 (monitoring nadużyć Vertex do 90 dni – owner/[PRAWNIK]), O7 („repo publiczne” vs „prywatne”), ani zadań z aneksu architekta: test modelu 3.x na `europe-west4` w `dev` przed P3-05, przeliczenie `costs.md` dla kandydatów Aneksu B pkt 3. Do dopisania w kolejnej fali, jeśli właściciel potwierdzi.
