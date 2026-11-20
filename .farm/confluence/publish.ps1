# Lokalne uruchomienie publikacji do Confluence (token Farm Bota z Menedżera poświadczeń).
#   powershell -File .farm/confluence/publish.ps1 docs/adr/0002-....md [docs/...] [--dry]
# W CI publish.mjs dostaje token z sekretu. Strony nigdy nie są usuwane, tylko archiwizowane.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\atlassian\atlassian-common.ps1')
if (-not (Test-Path (Join-Path $PSScriptRoot 'node_modules'))) {
    Push-Location $PSScriptRoot; try { npm ci --no-audit --no-fund | Out-Null } finally { Pop-Location }
}
$env:ATLASSIAN_EMAIL = $AtlassianEmail
$env:CONFLUENCE_TOKEN = Get-AtlassianToken confluence
try { node (Join-Path $PSScriptRoot 'publish.mjs') @args }
finally { Remove-Item Env:CONFLUENCE_TOKEN -ErrorAction SilentlyContinue }
