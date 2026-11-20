# Zapisuje token API Farm Bota (farm-bot@tadecode.pl) w Menedżerze poświadczeń Windows.
# Token wpisujesz TYLKO tutaj (ukryte pole). Skrypt sprawdza go w Atlassian i zapisuje dopiero,
# gdy działa. Nie trafia do repo, historii PowerShella ani na ekran.
#
# Użycie:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .farm/atlassian/set-token.ps1 jira
#   ... set-token.ps1 confluence
#   ... set-token.ps1 jira -Check     tylko sprawdza zapisany token
#   ... set-token.ps1 jira -Remove    usuwa zapisany token
param(
    [Parameter(Mandatory, Position = 0)][ValidateSet('jira', 'confluence')][string]$App,
    [switch]$Check,
    [switch]$Remove
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'atlassian-common.ps1')
$target = $AtlassianCredTargets[$App]

if ($Remove) {
    if ([FarmCred]::Delete($target)) { Write-Host "Usunięto '$target'." } else { Write-Host "Nie było '$target'." }
    exit 0
}

if ($Check) {
    $who = Test-AtlassianToken $App (Get-AtlassianToken $App)
    Write-Host "OK: '$target' działa jako: $who"
    exit 0
}

Write-Host "Token API Farm Bota ($AtlassianEmail) dla: $App"
Write-Host "Wklej token (pole jest ukryte) i naciśnij Enter:"
$sec = Read-Host -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
try {
    $token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr).Trim()
    if (-not $token) { throw 'Pusty token.' }
    try { $who = Test-AtlassianToken $App $token }
    catch { throw "Atlassian odrzucił token ($($_.Exception.Message)). Nic nie zapisano." }
    if ($who -notmatch 'farm|bot') {
        Write-Warning "Token działa jako '$who', a nie jako Farm Bot. Nic nie zapisano - utwórz token na koncie $AtlassianEmail."
        exit 1
    }
    [FarmCred]::Write($target, $AtlassianEmail, $token)
    Write-Host "Zapisano '$target' w Menedżerze poświadczeń. Konto: $who"
}
finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    Remove-Variable token -ErrorAction SilentlyContinue
}
