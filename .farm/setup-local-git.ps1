# Konfiguruje LOKALNIE (tylko to repozytorium) obsługę poświadczeń gita tak, by agenci pushowali
# jako konto bota (zwykła konfiguracja gh), a nie przez Git Credential Manager z kontem właściciela.
# Uruchom raz w katalogu głównym repozytorium farmy (po git init):
#   powershell -NoProfile -ExecutionPolicy Bypass -File .farm/setup-local-git.ps1 -BotName "TadeCode Farm Bot" -BotEmail "<id>+<login>@users.noreply.github.com"
# Nie zmienia konfiguracji globalnej ani wpisów w Menedżerze poświadczeń.
param(
    [string]$RepoDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string]$BotName = '',
    [string]$BotEmail = ''
)

git -C $RepoDir rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) { Write-Error "To nie jest repozytorium git: $RepoDir (uruchom najpierw git init)."; exit 1 }

# Pusty wpis "helper =" resetuje listę pomocników odziedziczoną z poziomu systemowego (manager).
# PowerShell 5.1 gubi pusty argument przy wywołaniu git config, więc piszemy sekcję do pliku wprost.
$gitDir = (git -C $RepoDir rev-parse --absolute-git-dir).Trim()
$cfgFile = Join-Path $gitDir 'config'
git -C $RepoDir config --local --remove-section credential *> $null
$section = "[credential]`n`thelper =`n`thelper = !gh auth git-credential`n`tuseHttpPath = true`n"
[IO.File]::AppendAllText($cfgFile, $section, [Text.UTF8Encoding]::new($false))

if ($BotName) { git -C $RepoDir config --local user.name $BotName }
if ($BotEmail) { git -C $RepoDir config --local user.email $BotEmail }

Write-Host "Konfiguracja lokalna ($RepoDir):"
git -C $RepoDir config --local --get-regexp '^(credential|user)\.' | Out-Host
Write-Host "`nPamiętaj: zwykła konfiguracja gh musi być zalogowana kontem BOTA (nie właściciela)."
