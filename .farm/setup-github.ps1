# Konfiguracja ochrony gałęzi i ustawień repozytorium GitHub dla farmy.
# DOMYŚLNIE TYLKO POKAZUJE, CO USTAWI (dry-run). Zmiany wykonuje dopiero z -Apply.
# Użycie:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .farm/setup-github.ps1 -Repo owner/nazwa
#   powershell -NoProfile -ExecutionPolicy Bypass -File .farm/setup-github.ps1 -Repo owner/nazwa -Apply
# Wymaga: zainstalowane gh i zalogowanie (gh auth login) kontem właściciela repozytorium.
# Uwaga: ochrona gałęzi w prywatnych repozytoriach wymaga planu GitHub Pro/Team (na Free działa tylko w publicznych).
param(
    [Parameter(Mandatory = $true)][string]$Repo,
    [string]$Branch = 'main',
    [int]$Approvals = 1,
    [switch]$Apply
)

$protection = [ordered]@{
    required_status_checks = [ordered]@{
        strict   = $true
        contexts = @('farm-guards', 'conventions', 'secrets', 'flutter', 'backend')
    }
    enforce_admins = $false
    required_pull_request_reviews = [ordered]@{
        dismiss_stale_reviews           = $true
        require_code_owner_reviews      = $true
        required_approving_review_count = $Approvals
    }
    restrictions = $null
    required_linear_history = $true
    allow_force_pushes = $false
    allow_deletions = $false
    required_conversation_resolution = $true
}
$protectionJson = $protection | ConvertTo-Json -Depth 6

$settings = @{
    delete_branch_on_merge = $true
    allow_squash_merge     = $true
    allow_merge_commit     = $false
    allow_rebase_merge     = $false
}
$settingsJson = $settings | ConvertTo-Json

Write-Host "Repozytorium: $Repo  Gałąź: $Branch  Wymagane zatwierdzenia: $Approvals"
Write-Host "`n--- Ochrona gałęzi (PUT repos/$Repo/branches/$Branch/protection) ---"
Write-Host $protectionJson
Write-Host "`n--- Ustawienia repozytorium (PATCH repos/$Repo) ---"
Write-Host $settingsJson

if (-not $Apply) {
    Write-Host "`nTRYB PODGLĄDU: nic nie zmieniono. Dodaj -Apply, aby zastosować."
    Write-Host "Ręcznie w ustawieniach repo włącz też: Secret scanning + Push protection, Dependabot alerts."
    exit 0
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Write-Error 'Brak polecenia gh (GitHub CLI).'; exit 1 }
gh auth status 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error 'Zaloguj się: gh auth login'; exit 1 }

$settingsJson | gh api --method PATCH "repos/$Repo" --input - | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error 'Nie udało się ustawić opcji repozytorium.'; exit 1 }
$protectionJson | gh api --method PUT "repos/$Repo/branches/$Branch/protection" --input - | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error 'Nie udało się ustawić ochrony gałęzi (sprawdź plan konta i czy gałąź istnieje).'; exit 1 }
Write-Host "`nZastosowano ochronę gałęzi $Branch w $Repo."
