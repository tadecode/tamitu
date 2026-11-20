# 22:45  mobile-dev → orkiestrator  |  TAM-86
- Zrobione: `serviceAccountFor()` zwraca pełny adres `<nazwa>@<projectId>.iam.gserviceaccount.com` zamiast skrótu `<nazwa>@`, który Firebase CLI 15.36 rozwija dla opcji funkcji, ale nie przy nadawaniu dostępu do sekretu (`UID_HASH_PEPPER:setIamPolicy` → 400 „Invalid service account (fn-consent@)"). `projectId` z `GCLOUD_PROJECT`; brak lub zły format → wyjątek (fail-closed, bez konta domyślnego). Testy: pełne adresy dev/prod, brak projectId, złe ID, brak skrótu.
- Artefakty: `backend/functions/src/service-accounts.ts`, `backend/functions/test/service-accounts.test.ts`
- Decyzje: źródło projectId = `GCLOUD_PROJECT` – CLI 15.36 ustawia je z `--project` przy analizie kodu (`loadFirebaseEnvs` → `discoverBuild`) i w zmiennych środowiskowych wdrożonej funkcji (także emulator). Parametr `projectID` z `firebase-functions/params` odrzucony: to Expression, nie da się go skleić z nazwą konta w jedną wartość opcji. Bez hard-codowania ID.
- Do zrobienia przez odbiorcę: recenzja (`review:ok`), merge przez właściciela, ponowne wdrożenie `recordConsent` do dev wg TAM-84; w `firebase functions:list`/konsoli konto ma być `fn-consent@tamitu-dev-tadecode.iam.gserviceaccount.com`.
- Pytania/blokady: brak. Lokalnie zielone: 212 testów, lint, typecheck, build. Nie wdrażano.

## Dla orkiestratora (zadania i pytania)
- Zadania – status: TAM-86: review
- Zadania – nowe: aktualizacja `docs/architecture/deploy-dev-functions.md` (wiersz SEC-20 w tabeli sprawdzeń opisuje skrót `fn-consent@` – po TAM-86 pełny adres), rola architect, zależność: merge TAM-86
- Pytania otwarte – nowe: brak
- Pytania otwarte – zamknięte: brak
