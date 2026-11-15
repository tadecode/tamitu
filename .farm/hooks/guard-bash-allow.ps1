# Hook PreToolUse (Bash): lista DOZWOLONYCH poleceń dla ról o ograniczonym dostępie.
# Wywołanie: guard-bash-allow.ps1 -Profile reviewer
# Zasada: tylko jedno proste polecenie; łączenie (; & |), przekierowania, podstawienia i
# wiele linii są zabronione. Polecenie musi pasować do wzorca z listy. Fail-closed.
param([string]$Profile = 'reviewer')

function Block([string]$msg) {
    [Console]::Error.WriteLine("[farma] ZABLOKOWANO: $msg")
    exit 2
}

$profiles = @{
    reviewer = @(
        '^git\s+(diff|log|show|status|blame|ls-files|rev-parse|merge-base|shortlog|grep)(\s|$)',
        '^git\s+branch\s+--show-current$',
        '^gh\s+pr\s+(view|diff|checks|list|status|comment|review)(\s|$)',
        '^gh\s+(run\s+(list|view)|issue\s+(view|list))(\s|$)',
        '^(flutter|dart)\s+analyze(\s|$)',
        '^dart\s+format\s+.*--output=none(\s|$)',
        '^(dart|flutter)\s+pub\s+(deps|outdated)(\s|$)',
        '^(osv-scanner|gitleaks)(\s|$)',
        '^(ls|dir|pwd|where|wc|rg|grep|cat|type|head|tail)(\s|$)'
    )
}
$deny = @{
    reviewer = @(
        @{ p = '^gh\s+pr\s+review\b.*(--approve|-a(\s|$))'; m = 'recenzent nie zatwierdza PR - robi to właściciel.' },
        @{ p = '^gh\s+pr\s+review\b.*(--request-changes|-r(\s|$))'; m = 'recenzent zgłasza ustalenia komentarzem, bez blokowania merge przez GitHub.' },
        @{ p = '^git\s+(branch|log|show)\b.*(-D|--delete|--output)'; m = 'polecenie modyfikujące.' }
    )
}

$raw = [Console]::In.ReadToEnd()
try { $data = $raw | ConvertFrom-Json } catch { Block 'nie można odczytać danych hooka (fail-closed)' }
$cmd = ([string]$data.tool_input.command).Trim()
if (-not $cmd) { exit 0 }
if (-not $profiles.ContainsKey($Profile)) { Block "nieznany profil '$Profile' (fail-closed)" }

if ($cmd -match '[;&|<>`]' -or $cmd -match '\$\(' -or $cmd -match "[\r\n]") {
    Block 'łączenie poleceń, przekierowania i podstawienia są niedozwolone dla tej roli. Uruchamiaj jedno proste polecenie naraz.'
}
foreach ($d in $deny[$Profile]) {
    if ($cmd -match $d.p) { Block "$($d.m) Polecenie: $cmd" }
}
foreach ($p in $profiles[$Profile]) {
    if ($cmd -match $p) { exit 0 }
}
Block "polecenie spoza listy dozwolonych dla roli '$Profile': $cmd"
