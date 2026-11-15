# Zaklada osobny worktree git dla zadania, zeby sesje agentow nie wchodzily sobie w droge.
#
# Zasada: glowny katalog repozytorium zostaje na `main` i sluzy tylko do odczytu.
# Kazde zadanie i kazda sesja (orkiestrator, Steward, implementacja) pracuje we WLASNYM
# worktree w katalogu `<repo>-wt\<nazwa>`, na wlasnej galezi. Historia jest wspolna,
# pliki robocze osobne. Jedna galaz moze byc wypozyczona tylko w jednym worktree naraz.
#
# Uzycie (z dowolnego worktree tego repozytorium):
#   powershell -NoProfile -ExecutionPolicy Bypass -File .farm/new-worktree.ps1 P3-03
#   ... P3-03 -Prefix fix          galaz fix/P3-03 zamiast feat/P3-03
#   ... P3-03 -Branch feat/P3-03b  wlasna nazwa galezi
#   ... P3-03 -Base origin/main    punkt startu (domyslnie origin/main)
#   ... -List                      pokazuje worktree
#   ... P3-03 -Remove              usuwa worktree (git odmowi, gdy sa niezapisane zmiany)
# Potem otworz sesje Claude Code W KATALOGU nowego worktree (hooki ufaja katalogowi projektu).
param(
    [Parameter(Position = 0)][string]$Task,
    [string]$Prefix = 'feat',
    [string]$Branch = '',
    [string]$Base = 'origin/main',
    [switch]$List,
    [switch]$Remove
)

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error 'Brak polecenia git.'
    exit 1
}

$common = git rev-parse --git-common-dir 2>$null
if ($LASTEXITCODE -ne 0 -or -not $common) {
    Write-Error 'To nie jest repozytorium git.'
    exit 1
}
$common = (Resolve-Path $common).Path
$mainDir = Split-Path $common -Parent
$wtRoot = "$mainDir-wt"

if ($List) {
    git worktree list
    exit 0
}

if (-not $Task) {
    Write-Error 'Podaj nazwe zadania, np. P3-03 (albo uzyj -List).'
    exit 1
}
if ($Task -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
    Write-Error 'Nazwa zadania: litery, cyfry, kropka, myslnik, podkreslnik (bez spacji i ukosnikow).'
    exit 1
}

$path = Join-Path $wtRoot $Task

if ($Remove) {
    if (-not (Test-Path $path)) {
        Write-Error "Nie ma worktree: $path"
        exit 1
    }
    $here = (Get-Location).Path
    if ($here -eq $path -or $here.StartsWith($path + '\')) {
        Write-Error 'Jestes w usuwanym worktree. Przejdz do innego katalogu (np. glownego) i ponow.'
        exit 1
    }
    git worktree remove $path
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'Git odmowil usuniecia (niezapisane zmiany?). Zapisz albo odloz zmiany, potem ponow. Nie uzywam --force.'
        exit 1
    }
    Write-Host "Usunieto worktree $path. Galaz zostaje; usun ja po merge: git branch -d <galaz>."
    exit 0
}

if (Test-Path $path) {
    Write-Error "Worktree juz istnieje: $path"
    exit 1
}
if (-not $Branch) { $Branch = "$Prefix/$Task" }

git fetch origin --prune 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Nie udalo sie pobrac origin; start z lokalnego '$Base' (moze byc nieaktualny)."
}

New-Item -ItemType Directory -Force $wtRoot | Out-Null

git show-ref --verify --quiet "refs/heads/$Branch"
if ($LASTEXITCODE -eq 0) {
    git worktree add $path $Branch
} else {
    git worktree add -b $Branch $path $Base
}
if ($LASTEXITCODE -ne 0) {
    Write-Error 'Nie udalo sie zalozyc worktree (galaz wypozyczona gdzie indziej? zly -Base?).'
    exit 1
}

Write-Host ''
Write-Host "Worktree: $path"
Write-Host "Galaz:    $Branch"
Write-Host 'Nastepny krok: otworz sesje Claude Code w tym katalogu i pracuj tylko tam.'
Write-Host "Glowny katalog ($mainDir) zostaje na main, bez pracy."
