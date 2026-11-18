# Lustro docs/backlog.md w Azure Boards (projekt Tamitu, proces Basic, tablica Kanban).
#
# Zrodlem prawdy jest docs/backlog.md. Tablica jest tylko widokiem dla wlasciciela:
# zmiany robione recznie na tablicy zostana nadpisane przy nastepnej synchronizacji.
#
# Uzycie (z worktree albo glownego katalogu repozytorium):
#   powershell -NoProfile -ExecutionPolicy Bypass -File .farm/ado/sync-backlog.ps1
#   ... -WhatIf      pokazuje, co by sie zmienilo, bez zapisu
#   ... -Backlog <sciezka>   inny plik backlogu (domyslnie docs/backlog.md z origin/main)
#
# Wymaga: Azure CLI (`az`) zalogowanego na konto z dostepem do organizacji
# (`az login`), rozszerzenia `azure-devops` niepotrzebne (wywolania REST przez `az rest`).
#
# Mapowanie:
#   wiersz backlogu  -> Issue (tag `bk:<ID>`), rodzic: Epic wg prefiksu ID
#   todo             -> Do zrobienia
#   in-progress      -> W pracy (agent)
#   review           -> Przeglad i QA
#   blocked          -> Do zrobienia + tag `zablokowane`
#   done             -> Gotowe
#   owner            -> Czeka na Ciebie (status `owner` w backlogu)
#   rola tylko `owner` i zadanie nie `done`, albo rola zawiera `owner` i status `review`
#                    -> Czeka na Ciebie
param(
    [string]$Org = 'https://dev.azure.com/tadecode',
    [string]$Project = 'Tamitu',
    [string]$Team = 'Tamitu Team',
    [string]$Backlog,
    [string]$RepoUrl = 'https://github.com/tadecode/tamitu',
    [switch]$WhatIf
)
$ErrorActionPreference = 'Stop'
$AdoResource = '499b84ac-1321-427f-aa17-267ca6975798'
$utf8 = New-Object Text.UTF8Encoding($false)
# Domyslnie: backlog z origin/main (stan zmergowany), niezaleznie od tego, w jakim worktree jestesmy.
if (-not $Backlog) {
    git fetch -q origin main
    if ($LASTEXITCODE -ne 0) { throw 'git fetch origin main nie powiodl sie.' }
    $Backlog = [IO.Path]::GetTempFileName()
    $prevEnc = [Console]::OutputEncoding; [Console]::OutputEncoding = [Text.Encoding]::UTF8
    try { $content = (git show origin/main:docs/backlog.md) -join "`n" } finally { [Console]::OutputEncoding = $prevEnc }
    [IO.File]::WriteAllText($Backlog, $content, $utf8)
}

# Token z `az` (bez `az rest`: az.cmd przepuszcza URL przez cmd.exe, ktory traktuje `&` jako separator polecen).
$token = (& az account get-access-token --resource $AdoResource --query accessToken -o tsv)
if (-not $token) { throw 'Brak tokenu Azure DevOps: uruchom `az login`.' }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Invoke-Ado {
    param([string]$Method = 'get', [string]$Uri, $Body, [string]$ContentType = 'application/json')
    $req = [Net.HttpWebRequest]::Create($Uri)
    $req.Method = $Method.ToUpper()
    $req.Headers['Authorization'] = "Bearer $token"
    if ($null -ne $Body) {
        # -InputObject zachowuje tablice jednoelementowe (operacje json-patch musza byc tablica).
        $json = ConvertTo-Json -InputObject $Body -Depth 10 -Compress
        $bytes = $utf8.GetBytes($json)
        $req.ContentType = $ContentType
        $req.ContentLength = $bytes.Length
        $s = $req.GetRequestStream(); $s.Write($bytes, 0, $bytes.Length); $s.Close()
    }
    try { $resp = $req.GetResponse() }
    catch [Net.WebException] {
        $detail = if ($_.Exception.Response) { (New-Object IO.StreamReader($_.Exception.Response.GetResponseStream(), [Text.Encoding]::UTF8)).ReadToEnd() }
        throw "$Method $Uri : $detail"
    }
    $text = (New-Object IO.StreamReader($resp.GetResponseStream(), [Text.Encoding]::UTF8)).ReadToEnd()
    $resp.Close()
    if ($text) { return $text | ConvertFrom-Json }
}

function Esc([string]$s) { [Net.WebUtility]::HtmlEncode($s) }

# --- 1. Parsowanie backlogu ---------------------------------------------------
$rows = @()
$header = $null
foreach ($line in [IO.File]::ReadAllLines($Backlog, [Text.Encoding]::UTF8)) {
    if ($line -notmatch '^\|') { $header = $null; continue }
    $cells = ($line.Trim().Trim('|') -split '\|') | ForEach-Object { $_.Trim() }
    if ($cells[0] -eq 'ID') { $header = $cells; continue }
    if ($cells[0] -match '^-+$' -or -not $header) { continue }
    if ($cells[0] -notmatch '^[A-Z]+[0-9A-Za-z-]*$') { continue }
    $r = [ordered]@{ ID = $cells[0]; Uwagi = @() }
    for ($i = 1; $i -lt $cells.Count; $i++) {
        $name = if ($i -lt $header.Count) { $header[$i] } else { 'Uwagi' }
        if ($name -eq 'Uwagi') { if ($cells[$i]) { $r.Uwagi += $cells[$i] } } else { $r[$name] = $cells[$i] }
    }
    $rows += [pscustomobject]$r
}

$epicFor = @{
    'P2' = 'Faza 2: Projekt'; 'P3' = 'Faza 3: Implementacja'; 'SEC' = 'Bezpieczeństwo (SEC)'
    'GH' = 'Infrastruktura i CI (Steward)'; 'O' = 'Pytania otwarte'; 'REV' = 'Przeglądy kodu'
}
function Get-EpicKey([string]$id) { if ($id -match '^(P\d+)-') { $Matches[1] } elseif ($id -match '^([A-Z]+)') { $Matches[1] } }

function Get-Target($row) {
    $status = (($row.Status -replace '[`*]', '') -split '[\s(]')[0].ToLower()
    $roles = ($row.Rola -replace '[`*]', '') -split '[/,\s]+' | Where-Object { $_ }
    $ownerOnly = ($roles.Count -eq 1 -and $roles[0] -eq 'owner')
    $hasOwner = $roles -contains 'owner'
    $col = switch ($status) {
        'done' { 'Gotowe' } 'review' { 'Przegląd i QA' } 'in-progress' { 'W pracy (agent)' }
        'owner' { 'Czeka na Ciebie' } default { 'Do zrobienia' }
    }
    if ($status -ne 'done' -and ($ownerOnly -or ($hasOwner -and $status -eq 'review'))) { $col = 'Czeka na Ciebie' }
    $state = switch ($col) { 'Gotowe' { 'Done' } 'Do zrobienia' { 'To Do' } default { 'Doing' } }
    $tags = @("bk:$($row.ID)") + ($roles | ForEach-Object { "rola:$_" })
    if ($status -eq 'blocked') { $tags += 'zablokowane' }
    [pscustomobject]@{ Column = $col; State = $state; Tags = ($tags | Sort-Object -Unique) -join '; ' }
}

# --- 2. Stan tablicy ---------------------------------------------------------
$teamEnc = [uri]::EscapeDataString($Team)
$board = Invoke-Ado -Uri "$Org/$Project/$teamEnc/_apis/work/boards/Issues?api-version=7.1"
$colField = $board.fields.columnField.referenceName

# Tagi filtrujemy po stronie skryptu: WIQL `Tags CONTAINS` dopasowuje tylko caly tag, nie prefiks.
$wiql = @{ query = "SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = '$Project' AND [System.WorkItemType] IN ('Issue', 'Epic') ORDER BY [System.Id]" }
$ids = (Invoke-Ado -Method post -Uri "$Org/$Project/_apis/wit/wiql?api-version=7.1" -Body $wiql).workItems.id
$existing = @{}
$epics = @{}
for ($i = 0; $ids -and $i -lt $ids.Count; $i += 200) {
    $chunk = $ids[$i..([Math]::Min($i + 199, $ids.Count - 1))] -join ','
    $items = Invoke-Ado -Uri "$Org/$Project/_apis/wit/workitems?ids=$chunk&`$expand=relations&api-version=7.1"
    foreach ($w in $items.value) {
        foreach ($t in ($w.fields.'System.Tags' -split ';\s*')) {
            # Przy duplikatach wygrywa najstarszy element (najnizsze ID).
            if ($t -like 'bk:*' -and -not $existing[$t.Substring(3)]) { $existing[$t.Substring(3)] = $w }
            if ($t -like 'epic:*' -and -not $epics[$t.Substring(5)]) { $epics[$t.Substring(5)] = $w }
        }
    }
}

function Patch([string]$path, $value) { @{ op = 'add'; path = "/fields/$path"; value = $value } }

# --- 3. Epiki ----------------------------------------------------------------
foreach ($key in ($rows | ForEach-Object { Get-EpicKey $_.ID } | Sort-Object -Unique)) {
    if ($epics[$key]) { continue }
    $title = if ($epicFor[$key]) { $epicFor[$key] } else { $key }
    Write-Host "nowy epik  $title"
    if ($WhatIf) { continue }
    $ops = @((Patch 'System.Title' $title), (Patch 'System.Tags' "epic:$key"))
    $epics[$key] = Invoke-Ado -Method post -Uri "$Org/$Project/_apis/wit/workitems/`$Epic?api-version=7.1" -Body $ops -ContentType 'application/json-patch+json'
}

# --- 4. Zadania --------------------------------------------------------------
$created = 0; $updated = 0; $same = 0
foreach ($row in $rows) {
    $t = Get-Target $row
    $title = "$($row.ID): $($row.Zadanie -replace '\*\*', '' -replace '`', '')"
    if ($title.Length -gt 250) { $title = $title.Substring(0, 247) + '...' }
    $desc = "<p><b>Rola:</b> $(Esc $row.Rola)<br><b>Status w backlogu:</b> $(Esc $row.Status)</p>"
    if ($row.'Powiązane (story/ADR)') { $desc += "<p><b>Powiązane:</b> $(Esc $row.'Powiązane (story/ADR)')</p>" }
    if ($row.Uwagi) { $desc += "<p><b>Uwagi:</b> $(Esc ($row.Uwagi -join ' | '))</p>" }
    $desc += "<p><i>Lustro <a href=`"$RepoUrl/blob/main/docs/backlog.md`">docs/backlog.md</a>. Nie edytuj tutaj: zmiany zostana nadpisane.</i></p>"

    $w = $existing[$row.ID]
    $want = [ordered]@{ 'System.Title' = $title; 'System.Description' = $desc; 'System.Tags' = $t.Tags; 'System.State' = $t.State; $colField = $t.Column }
    if ($w) {
        $ops = @()
        foreach ($k in $want.Keys) {
            $cur = $w.fields.$k
            $new = "$($want[$k])"
            if ($k -eq 'System.Tags') { $cur = (($cur -split ';\s*') | Sort-Object) -join '; ' }
            # Azure DevOps normalizuje HTML opisu (np. spacja przed </p>), wiec porownujemy bez bialych znakow.
            if ($k -eq 'System.Description') {
                $cur = [Net.WebUtility]::HtmlDecode("$cur") -replace '\s', ''
                $new = [Net.WebUtility]::HtmlDecode($new) -replace '\s', ''
            }
            if ("$cur" -ne $new) { $ops += Patch $k $want[$k] }
        }
        if (-not $ops) { $same++; continue }
        Write-Host ("zmiana     {0,-8} -> {1}" -f $row.ID, $t.Column)
        $updated++
        if (-not $WhatIf) { $null = Invoke-Ado -Method patch -Uri "$Org/$Project/_apis/wit/workitems/$($w.id)?api-version=7.1" -Body $ops -ContentType 'application/json-patch+json' }
    } else {
        Write-Host ("nowe       {0,-8} -> {1}" -f $row.ID, $t.Column)
        $created++
        if ($WhatIf) { continue }
        # Nowe zadanie zawsze startuje w stanie poczatkowym; stan i kolumne ustawia druga operacja.
        $ops = @((Patch 'System.Title' $title), (Patch 'System.Description' $desc), (Patch 'System.Tags' $t.Tags))
        $epic = $epics[(Get-EpicKey $row.ID)]
        if ($epic) { $ops += @{ op = 'add'; path = '/relations/-'; value = @{ rel = 'System.LinkTypes.Hierarchy-Reverse'; url = $epic.url } } }
        $new = Invoke-Ado -Method post -Uri "$Org/$Project/_apis/wit/workitems/`$Issue?api-version=7.1" -Body $ops -ContentType 'application/json-patch+json'
        if ($t.Column -ne 'Do zrobienia') {
            $null = Invoke-Ado -Method patch -Uri "$Org/$Project/_apis/wit/workitems/$($new.id)?api-version=7.1" -Body @((Patch 'System.State' $t.State), (Patch $colField $t.Column)) -ContentType 'application/json-patch+json'
        }
    }
}
Write-Host "Backlog: $($rows.Count) wierszy; nowe: $created, zmienione: $updated, bez zmian: $same$(if ($WhatIf) { ' (WhatIf: nic nie zapisano)' })"
Write-Host "Tablica: $Org/$Project/_boards/board/t/$teamEnc/Issues"
