# FARM-002: Domyślna konfiguracja `gh` sesji farmy jest zalogowana jako `tadecode`, a nie jako bot

- Zgłasza (rola): orchestrator · Data: 2026-11-16 · Powiązane: GH-004, `docs/github.md` (sekcja „Konta i podział uprawnień"), PR #10-#29
- Typ: poprawka środowiska właściciela + doprecyzowanie dokumentacji
- Status: propozycja (większość kroków wykonuje właściciel w swoim terminalu; zero zmian w hookach)

## Problem
Projekt zakłada (`docs/github.md`): role farmy używają **zwykłej (domyślnej) konfiguracji `gh`**, w której
zalogowany jest **bot farmy** (`tadecode-farm`), a git pushuje przez `!gh auth git-credential`
(`.farm/setup-local-git.ps1`). Steward ma osobną konfigurację (`~/.config/gh-steward`).

W praktyce PR-y #10-#29 mają autora `tadecode`. Commity są podpisane „TadeCode Farm Bot" (`user.name`
jest ustawione), ale `gh pr create` i push używają aktywnego konta domyślnej konfiguracji, a tam jest
konto właściciela. Skutek: właściciel nie może zatwierdzać PR-ów jako inna osoba i merguje admin bypassem;
test z GH-004 krok 4 (merge bez bypassu) jest niemożliwy.

Uwaga: GH-004 mówi, że bot został zalogowany „w osobnej konfiguracji `gh`". To odwrotnie niż zakłada
`docs/github.md` (bot = domyślna, Steward = osobna). Do rozstrzygnięcia przez właściciela, patrz niżej.

Hook `guard-bash` blokuje agentom `gh auth status` i odczyt konfiguracji kont, więc agent nie zweryfikuje
tego sam. Weryfikuje właściciel.

## Poprawka (właściciel, w terminalu poza sesją agenta; żadne wartości nie przechodzą przez czat)
Wybierz jedną z dwóch dróg:

**Wariant 1 (zgodny z `docs/github.md`, zalecany): bot jako konto domyślne.**
```powershell
# w zwykłej konfiguracji gh (bez GH_CONFIG_DIR)
gh auth login --hostname github.com --git-protocol https --with-token   # wklej token bota; tokena nie pokazuj w czacie
gh auth switch --hostname github.com --user tadecode-farm            # bot musi być kontem AKTYWNYM
gh auth status                                                           # sprawdź: Active account: tadecode-farm
gh auth setup-git                                                        # git push używa aktywnego konta gh
.farm/setup-local-git.ps1 -BotName "TadeCode Farm Bot" -BotEmail "<adres e-mail konta bota>"
```
Konto `tadecode` w domyślnej konfiguracji: usunąć (`gh auth logout --user tadecode`) albo zostawić
nieaktywne. Własne operacje właściciela (zatwierdzanie PR w przeglądarce) nie wymagają `gh`.

**Wariant 2: bot w osobnej konfiguracji (jak w GH-004).** Każdą sesję roli (poza Stewardem) startować
z `GH_CONFIG_DIR` wskazującym katalog bota, także sesje z aplikacji desktopowej (zmienna musi być w
środowisku startowym). Wymaga zmiany skryptów startowych, więc to więcej pracy niż wariant 1.

Po wykonaniu **zrestartuj sesję orkiestratora**, bo nowe konto aktywuje się dla nowych procesów.

## Weryfikacja (właściciel)
1. W nowej sesji farmy poproś o PR testowy: autor ma być `tadecode-farm`.
2. Zatwierdź go z `tadecode` i zmerguj bez admin bypassu (GH-004 krok 4).
3. Dopiero potem rozważyć `enforce_admins=true` (GH-004 krok 5). Uwaga z `docs/github.md`: wcześniej upewnić się,
   że PR-y Stewarda (autor = właściciel) da się zatwierdzić; patrz wariant A w `docs/github-ops/farm-bot-account.md`.

## Zmiany w dokumentacji (osobny krok, po wyborze wariantu)
- Login bota ustalony: `tadecode-farm` (`docs/github.md` poprawiony). `docs/github-ops/farm-bot-account.md`
  (zakres Stewarda) ma już poprawny login; ujednolicić tylko miejsce konfiguracji (domyślna vs osobna, GH-004).
- Obserwacja z 2026-11-16: w terminalu właściciela `gh auth status` pokazuje aktywne konto `tadecode-farm`,
  a w sesji orkiestratora `gh api user` zwracało `tadecode` (to samo `APPDATA\GitHub CLI`, brak `GH_TOKEN`).
  Po restarcie sesji sprawdzić autora nowego PR-a; jeśli nadal `tadecode`, źródłem jest środowisko aplikacji.
- `docs/github.md`: dopisać krok „po zalogowaniu bota sprawdź `gh auth status`: aktywne konto = bot".
- Opcjonalnie nowy hook przed `gh pr create`/`git push`, odmawiający gdy aktywne konto to `tadecode`
  (zmiana chronionych plików; tylko właściciel).

## Wpływ
Koszty: brak. Bezpieczeństwo: poprawia rozdział uprawnień (bot bez admina, Workflows, Secrets). RODO: brak.
Ryzyko: niskie. Nie włączać `enforce_admins=true` przed udanym testem zatwierdzania.
