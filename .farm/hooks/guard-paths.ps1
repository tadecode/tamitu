# Hook PreToolUse (Write|Edit|NotebookEdit): pilnuje, gdzie agent może zapisywać.
# Wywołanie: guard-paths.ps1 [-Role <nazwa>] [-Allow "sciezka1,sciezka2"]
# - bez -Allow: tylko ochrona uniwersalna (dla wszystkich, także głównej sesji)
# - z -Allow: dodatkowo zapis tylko w podanych ścieżkach (względem katalogu projektu)
# Kod wyjścia 2 = blokada (komunikat na stderr trafia do agenta). Zasada: fail-closed.
# Wyjątek dla właściciela: FARM_MAINTENANCE=1 pozwala edytować .claude/, .farm/hooks/, CLAUDE.md.
param([string]$Role = 'main', [string]$Allow = '')

function Block([string]$msg) {
    [Console]::Error.WriteLine("[farma] ZABLOKOWANO: $msg")
    exit 2
}

$raw = [Console]::In.ReadToEnd()
try { $data = $raw | ConvertFrom-Json } catch { Block 'nie można odczytać danych hooka (fail-closed)' }

$target = $null
if ($data.tool_input) {
    if ($data.tool_input.file_path) { $target = [string]$data.tool_input.file_path }
    elseif ($data.tool_input.notebook_path) { $target = [string]$data.tool_input.notebook_path }
}
if (-not $target) { exit 0 }

$root = $env:CLAUDE_PROJECT_DIR
if (-not $root) { $root = [string]$data.cwd }
if (-not $root) { Block 'nieznany katalog projektu (fail-closed)' }

if ($target -match '^/([a-zA-Z])/(.*)$') { $target = "$($Matches[1]):/$($Matches[2])" }
$rootFull = [IO.Path]::GetFullPath($root).Replace('\', '/').TrimEnd('/')
if ([IO.Path]::IsPathRooted($target)) { $full = [IO.Path]::GetFullPath($target) }
else { $full = [IO.Path]::GetFullPath((Join-Path $rootFull $target)) }
$full = $full.Replace('\', '/')

$cmp = [StringComparison]::OrdinalIgnoreCase
if (-not $full.StartsWith($rootFull + '/', $cmp)) { Block "ścieżka poza projektem: $target" }
$rel = $full.Substring($rootFull.Length + 1)

# 1. Sekrety - zawsze zablokowane
if ($rel -match '(^|/)\.env(\.|$)' -or $rel -match '\.(jks|keystore)$' -or $rel -match '(^|/)key\.properties$') {
    Block "plik z sekretami: $rel. Sekrety nie trafiają do repozytorium."
}

# 2. Kontrakty ról, hooki i zasady farmy - tylko właściciel (FARM_MAINTENANCE=1)
if ($env:FARM_MAINTENANCE -ne '1') {
    $githubProtected = ($rel -match '^\.github/') -and ($env:FARM_ROLE -ne 'steward')
    if ($rel -match '^\.claude/' -or $rel -match '^\.farm/hooks/' -or $githubProtected -or $rel -match '^\.farm/review/' -or $rel -match '^\.farm/steward/' -or $rel -eq 'CLAUDE.md') {
        Block "agent nie zmienia własnych kontraktów ani zabezpieczeń: $rel. Zgłoś potrzebę właścicielowi."
    }
}

# 3. Zakres roli (sesja GitHub Stewarda ma wbudowaną, wąską listę)
if ($env:FARM_ROLE -eq 'steward' -and -not $Allow) {
    $Role = 'steward'
    $Allow = '.github,.farm/requests,.farm/log,docs/github-ops'
}
if ($Allow) {
    $ok = $false
    foreach ($a in ($Allow -split ',')) {
        $a = $a.Trim().Trim('/')
        if (-not $a) { continue }
        if ($rel.Equals($a, $cmp) -or $rel.StartsWith($a + '/', $cmp)) { $ok = $true; break }
    }
    if (-not $ok) {
        Block "rola '$Role' nie może zapisywać w '$rel'. Dozwolone: $Allow. Zgłoś potrzebę orkiestratorowi."
    }
}
exit 0
