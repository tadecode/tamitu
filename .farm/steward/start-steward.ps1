# Uruchamia osobną sesję Claude Code jako GitHub Steward.
#
# Izolacja poświadczeń: token Stewarda istnieje w Menedżerze poświadczeń Windows
# TYLKO na czas sesji. Skrypt loguje konto na starcie (przeglądarka, kod jednorazowy)
# i WYLOGOWUJE je po zakończeniu (także przy błędzie). Poza sesją Stewarda żaden proces
# agentów nie ma czego odczytać. Uprawnienia tokena: repo, workflow, read:org
# (bez delete_repo - skradziony token nie usunie repozytorium).
#
# Użycie:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .farm/steward/start-steward.ps1
#   ... -Logout       tylko wylogowuje (gdy okno zamknięto awaryjnie)
#   ... -KeepLogin    nie wylogowuje po sesji (wygodne, ale osłabia izolację)
param(
    [switch]$Logout,
    [switch]$KeepLogin,
    [string]$ProjectDir = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error 'Brak polecenia gh (GitHub CLI). Zainstaluj: winget install --id GitHub.cli -e'
    exit 1
}

$cfg = Join-Path $env:USERPROFILE '.config\gh-steward'
New-Item -ItemType Directory -Force $cfg | Out-Null
$env:GH_CONFIG_DIR = $cfg

function Steward-Logout {
    gh auth logout --hostname github.com | Out-Null
    gh auth status *> $null
    if ($LASTEXITCODE -ne 0) { Write-Host 'Steward wylogowany - token usunięty z Menedżera poświadczeń.' }
    else { Write-Warning 'Konto Stewarda nadal zalogowane. Uruchom skrypt z -Logout.' }
}

if ($Logout) { Steward-Logout; exit 0 }

gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Logowanie konta Stewarda (konto właściciela). Uprawnienia: repo, workflow, read:org.'
    Write-Host 'Wybierz: GitHub.com -> HTTPS -> logowanie przez przeglądarkę.'
    gh auth login --hostname github.com --git-protocol https --web --scopes 'repo,workflow,read:org'
    if ($LASTEXITCODE -ne 0) { Write-Error 'Logowanie nie powiodło się.'; exit 1 }
}

$who = gh api user --jq .login
Write-Host "Steward działa jako: $who"
Write-Host 'Uruchamiaj w zwykłym trybie uprawnień (z potwierdzeniami).'

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Error 'Brak polecenia claude (Claude Code CLI).'
    if (-not $KeepLogin) { Steward-Logout }
    exit 1
}

$env:FARM_ROLE = 'steward'
Remove-Item Env:FARM_MAINTENANCE -ErrorAction SilentlyContinue
Set-Location $ProjectDir
try {
    claude --model sonnet 'Przeczytaj .farm/steward/github-steward.md i działaj jako GitHub Steward. Zacznij od przejrzenia .farm/requests/ i podsumuj, co czeka.'
}
finally {
    Remove-Item Env:FARM_ROLE -ErrorAction SilentlyContinue
    if (-not $KeepLogin) { Steward-Logout }
}
