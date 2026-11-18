# 2026-11-18 steward: GH-011, GH-005, GH-006

- Zadanie: kolejka próśb; #77 ma czerwone `flutter` (brak `google-services.json` bez flagi).
- Zrobione: PR `chore/ci-flutter-flags` (flaga `-P tamitu.allowMissingGoogleServices=true` w kroku buildu); zasada Dependabota (GH-005); GH-006 zamknięte po weryfikacji.
- Do zrobienia przez innych: orchestrator/właściciel dopisuje `.runtimeconfig.json` do `.gitignore`; przy GH-009 flagę usunąć z joba z sekretami.
- Następny krok: po merge PR ponowić CI na #77; GH-007 czeka na zgodę właściciela.
