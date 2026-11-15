# Hook PreToolUse (Bash): blokuje najgroźniejsze polecenia powłoki (lista zakazów, nie pełna izolacja).
# Kod wyjścia 2 = blokada. Zasada: fail-closed.
function Block([string]$msg) {
    [Console]::Error.WriteLine("[farma] ZABLOKOWANO: $msg")
    exit 2
}

$raw = [Console]::In.ReadToEnd()
try { $data = $raw | ConvertFrom-Json } catch { Block 'nie można odczytać danych hooka (fail-closed)' }
$cmd = [string]$data.tool_input.command
if (-not $cmd) { exit 0 }

$rules = @(
    @{ p = 'git\s+push\b[^|;&]*(\s|:)(main|master)(\s|$)'; m = 'push na main/master. Pracuj na gałęzi feat/<id-zadania>.' },
    @{ p = 'git\s+push\b[^|;&]*(--force|--force-with-lease|\s-f(\s|$))'; m = 'wymuszony push.' },
    @{ p = 'git\s+reset\s+--hard'; m = 'git reset --hard niszczy niezapisaną pracę.' },
    @{ p = 'git\s+clean\s+-[a-zA-Z]*f'; m = 'git clean -f usuwa pliki bezpowrotnie.' },
    @{ p = 'git\s+(commit|push)\b[^|;&]*--no-verify'; m = 'pomijanie weryfikacji commita.' },
    @{ p = '\brm\s+-[a-zA-Z]*[rR][a-zA-Z]*\s+(/|~|\.|\*|\.\.)(\s|$|/)'; m = 'rekurencyjne usuwanie katalogu głównego/domowego/bieżącego.' },
    @{ p = '(curl|wget|iwr|Invoke-WebRequest)\b[^;&]*\|\s*(sh|bash|iex|Invoke-Expression)\b'; m = 'wykonywanie pobranego skryptu.' },
    @{ p = '(cat|type|Get-Content|gc|less|more|head|tail)\s+[^|;&]*\.env(\.|\s|$)'; m = 'odczyt pliku .env (sekrety).' },
    @{ p = '(cat|type|Get-Content|gc)\s+[^|;&]*\.(jks|keystore)\b|key\.properties'; m = 'dostęp do kluczy podpisywania.' }
)
foreach ($r in $rules) {
    if ($cmd -match $r.p) { Block "$($r.m) Polecenie: $cmd" }
}

$isSteward = ($env:FARM_ROLE -eq 'steward')

# Zakazy dla WSZYSTKICH (także Stewarda)
$always = @(
    @{ p = '\bgh\s+auth\s+token\b'; m = 'wypisanie tokena GitHub.' },
    @{ p = '\b(GH|GITHUB)_[A-Za-z_]*TOKEN\b'; m = 'odwołanie do tokena GitHub.' },
    @{ p = 'GH_CONFIG_DIR|gh-steward'; m = 'konfiguracja konta Stewarda jest niedostępna z poleceń agenta.' },
    @{ p = '\bgh\s+repo\s+(delete|transfer|rename)\b'; m = 'usuwanie, przenoszenie i zmiana nazwy repozytorium - tylko ręcznie przez właściciela.' },
    @{ p = '--visibility\b|--accept-visibility-change-consequences'; m = 'zmiana widoczności repozytorium - tylko ręcznie przez właściciela.' },
    @{ p = '\bgh\s+pr\s+merge\b[^|;&]*--admin'; m = 'ominięcie ochrony gałęzi (--admin).' }
)
foreach ($r in $always) {
    if ($cmd -match $r.p) { Block "$($r.m) Polecenie: $cmd" }
}

# Operacje administracyjne GitHub: tylko GitHub Steward (sesja z FARM_ROLE=steward)
$admin = @(
    '\bgh\s+repo\s+(create|edit|archive|unarchive|fork|sync|deploy-key)\b',
    '\bgh\s+(secret|variable|ruleset|ssh-key|gpg-key|release|codespace|extension|alias|config)\b',
    '\bgh\s+label\s+(create|delete|edit|clone)\b',
    '\bgh\s+workflow\s+(run|enable|disable)\b',
    '\bgh\s+pr\s+merge\b',
    '\bgh\s+issue\s+(delete|transfer|lock|pin)\b',
    '\bgh\s+api\b[^|;&]*(-X|--method)\s*=?\s*(POST|PUT|PATCH|DELETE)\b',
    '\bgh\s+api\b[^|;&]*\s(-f|-F|--field|--raw-field|--input)\b',
    '\bgh\s+auth\s+(login|logout|refresh|setup-git|switch)\b',
    '\bgit\s+remote\s+(add|set-url|remove|rm|rename)\b',
    '\bgit\s+config\b[^|;&]*(credential|\burl\.)',
    '\bgit\s+credential\b',
    '(curl|wget|iwr|irm|Invoke-WebRequest|Invoke-RestMethod)\b[^;&]*api\.github\.com'
)
if (-not $isSteward) {
    foreach ($p in $admin) {
        if ($cmd -match $p) { Block "operacje administracyjne GitHub są zarezerwowane dla agenta GitHub Steward. Zgłoś potrzebę orkiestratorowi (.farm/requests/). Polecenie: $cmd" }
    }
}
if ($isSteward -and $cmd -match '\bgh\s+repo\s+create\b') {
    if ($cmd -notmatch '--(private|internal)\b' -or $cmd -match '--public\b') { Block 'nowe repozytorium musi być prywatne (--private).' }
}

if ($env:FARM_MAINTENANCE -ne '1') {
    if ($cmd -match '(>>?|\btee\b|Set-Content|Out-File|Add-Content|sed\s+-i|\bcp\b|\bmv\b|\brm\b|Remove-Item|\bdel\b)[^|;&]*(\.claude[/\\]|\.farm[/\\]hooks|\.github[/\\])') {
        Block "zmiana kontraktów ról lub zabezpieczeń przez powłokę. Zgłoś potrzebę właścicielowi."
    }
}
exit 0
