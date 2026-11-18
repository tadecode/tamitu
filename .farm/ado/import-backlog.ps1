# Jednorazowy import tabel z docs/backlog.md do Azure Boards (migracja 2026-11-18).
# Po migracji zadania i statusy zyja tylko na tablicy; zmieniaj je przez .farm/ado/task.ps1.
# Ponowne uruchomienie nadpisze kolumny, tytuly i opisy zadan obecnych w pliku, dlatego wymaga -Force.
#
#   import-backlog.ps1 -Backlog docs/archive/backlog-2026-11-18.md -WhatIf
#   import-backlog.ps1 -Backlog <plik> -Force
#
# Mapowanie: wiersz -> Issue (tag `bk:<ID>`), rodzic: Epic wg prefiksu ID.
#   todo/blocked -> Do zrobienia (blocked: tag `zablokowane`), in-progress -> W pracy (agent),
#   review -> Przegląd i QA, owner -> Czeka na Ciebie, done -> Gotowe.
#   Rola tylko `owner` (zadanie nie done) albo rola z `owner` i status review -> Czeka na Ciebie.
param([Parameter(Mandatory)][string]$Backlog, [switch]$WhatIf, [switch]$Force)
. "$PSScriptRoot/ado-common.ps1"
if (-not $WhatIf -and -not $Force) { throw 'Import nadpisuje stan tablicy. Uzyj -WhatIf albo -Force.' }

function Esc([string]$s) { [Net.WebUtility]::HtmlEncode($s) }

$rows = @(); $header = $null
foreach ($line in [IO.File]::ReadAllLines((Resolve-Path $Backlog), [Text.Encoding]::UTF8)) {
    if ($line -notmatch '^\|') { $header = $null; continue }
    $cells = ($line.Trim().Trim('|') -split '\|') | ForEach-Object { $_.Trim() }
    if ($cells[0] -eq 'ID') { $header = $cells; continue }
    if ($cells[0] -match '^-+$' -or -not $header -or $cells[0] -notmatch '^[A-Z]+[0-9A-Za-z-]*$') { continue }
    $r = [ordered]@{ ID = $cells[0]; Uwagi = @() }
    for ($i = 1; $i -lt $cells.Count; $i++) {
        $name = if ($i -lt $header.Count) { $header[$i] } else { 'Uwagi' }
        if ($name -eq 'Uwagi') { if ($cells[$i]) { $r.Uwagi += $cells[$i] } } else { $r[$name] = $cells[$i] }
    }
    $rows += [pscustomobject]$r
}

function Get-Target($row) {
    $status = (($row.Status -replace '[`*]', '') -split '[\s(]')[0].ToLower()
    $roles = @(($row.Rola -replace '[`*]', '') -split '[/,\s]+' | Where-Object { $_ })
    $col = switch ($status) {
        'done' { 'Gotowe' } 'review' { 'Przegląd i QA' } 'in-progress' { 'W pracy (agent)' }
        'owner' { 'Czeka na Ciebie' } default { 'Do zrobienia' }
    }
    $ownerOnly = ($roles.Count -eq 1 -and $roles[0] -eq 'owner')
    if ($status -ne 'done' -and ($ownerOnly -or ($roles -contains 'owner' -and $status -eq 'review'))) { $col = 'Czeka na Ciebie' }
    $tags = @("bk:$($row.ID)") + ($roles | ForEach-Object { "rola:$_" })
    if ($status -eq 'blocked') { $tags += 'zablokowane' }
    [pscustomobject]@{ Column = $col; State = $AdoColumns[$col]; Tags = ($tags | Sort-Object -Unique) -join '; ' }
}

$index = Get-AdoIndex
$colField = Get-AdoColumnField
$created = 0; $updated = 0; $same = 0
foreach ($row in $rows) {
    $t = Get-Target $row
    $title = "$($row.ID): $($row.Zadanie -replace '\*\*', '' -replace '`', '')"
    if ($title.Length -gt 250) { $title = $title.Substring(0, 247) + '...' }
    $desc = "<p><b>Rola:</b> $(Esc $row.Rola)<br><b>Status w backlogu:</b> $(Esc $row.Status)</p>"
    if ($row.'Powiązane (story/ADR)') { $desc += "<p><b>Powiązane:</b> $(Esc $row.'Powiązane (story/ADR)')</p>" }
    if ($row.Uwagi) { $desc += "<p><b>Uwagi:</b> $(Esc ($row.Uwagi -join ' | '))</p>" }
    $desc += "<p><i>Zaimportowane z <a href=`"$AdoRepoUrl/blob/main/docs/archive/backlog-2026-11-18.md`">archiwum backlogu</a> 2026-11-18.</i></p>"

    $w = $index.Items[$row.ID]
    $want = [ordered]@{ 'System.Title' = $title; 'System.Description' = $desc; 'System.Tags' = $t.Tags; 'System.State' = $t.State; $colField = $t.Column }
    if ($w) {
        $ops = @()
        foreach ($k in $want.Keys) {
            $cur = "$($w.fields.$k)"; $new = "$($want[$k])"
            if ($k -eq 'System.Tags') { $cur = (($cur -split ';\s*') | Sort-Object) -join '; ' }
            # Azure DevOps normalizuje HTML opisu (spacje, encje), wiec porownujemy tekst bez bialych znakow.
            if ($k -eq 'System.Description') { $cur = [Net.WebUtility]::HtmlDecode($cur) -replace '\s', ''; $new = [Net.WebUtility]::HtmlDecode($new) -replace '\s', '' }
            if ($cur -ne $new) { $ops += New-AdoPatch $k $want[$k] }
        }
        if (-not $ops) { $same++; continue }
        Write-Host ("zmiana  {0,-8} -> {1}" -f $row.ID, $t.Column); $updated++
        if (-not $WhatIf) { $null = Update-AdoItem $w.id $ops }
    } else {
        Write-Host ("nowe    {0,-8} -> {1}" -f $row.ID, $t.Column); $created++
        if ($WhatIf) { continue }
        $epic = Get-AdoEpic $row.ID $index
        $ops = @((New-AdoPatch 'System.Title' $title), (New-AdoPatch 'System.Description' $desc), (New-AdoPatch 'System.Tags' $t.Tags),
            @{ op = 'add'; path = '/relations/-'; value = @{ rel = 'System.LinkTypes.Hierarchy-Reverse'; url = $epic.url } })
        $new = Invoke-Ado -Method post -Uri 'wit/workitems/$Issue?api-version=7.1' -Body $ops -ContentType 'application/json-patch+json'
        # Nowe zadanie startuje w stanie poczatkowym; stan i kolumne ustawia druga operacja.
        if ($t.Column -ne 'Do zrobienia') { $null = Update-AdoItem $new.id @((New-AdoPatch 'System.State' $t.State), (New-AdoPatch $colField $t.Column)) }
    }
}
Write-Host "Backlog: $($rows.Count) wierszy; nowe: $created, zmienione: $updated, bez zmian: $same$(if ($WhatIf) { ' (WhatIf: nic nie zapisano)' })"
Write-Host "Tablica: $AdoBoardUrl"
