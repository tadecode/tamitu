# Zadania farmy w Azure Boards (jedyne zrodlo prawdy o zadaniach i statusach; od 2026-11-18).
# Pisze tylko orkiestrator. Pozostale role zglaszaja zmiany w sekcji „Dla orkiestratora” pliku przekazania.
#
#   task.ps1 list [-Column owner] [-Role mobile-dev] [-All]   lista (domyslnie bez Gotowe)
#   task.ps1 show P3-04                                        szczegoly i komentarze
#   task.ps1 new  P3-15 -Title "..." -Role mobile-dev [-Column todo] [-Related "US-004, ADR-0002"] [-Notes "..."]
#   task.ps1 move P3-04 owner [-Note "PR #61 czeka na merge"] [-Pr 61]
#   task.ps1 note P3-04 "tekst komentarza" [-Pr 61]
#   task.ps1 block P3-04 "powod"     /   task.ps1 unblock P3-04
#
# Kolumny: todo (Do zrobienia), doing (W pracy (agent)), review (Przegląd i QA),
#          owner (Czeka na Ciebie), done (Gotowe).
# Zasada: zadanie czekajace na wlasciciela (merge PR-a, decyzja, czynnosc w konsoli) -> `owner`.
param(
    [Parameter(Mandatory, Position = 0)][ValidateSet('list', 'show', 'new', 'move', 'note', 'block', 'unblock')][string]$Command,
    [Parameter(Position = 1)][string]$Id,
    [Parameter(Position = 2)][string]$Arg,
    [string]$Title, [string]$Role, [string]$Column, [string]$Related, [string]$Notes, [string]$Note,
    [int]$Pr, [switch]$All
)
. "$PSScriptRoot/ado-common.ps1"

function Need-Id { if (-not $Id) { throw "Podaj ID zadania, np. P3-04." } }
function Get-Task($index) {
    $w = $index.Items[$Id]
    if (-not $w) { throw "Nie ma zadania $Id na tablicy ($AdoBoardUrl)." }
    $w
}
function Add-Comment([int]$WorkItemId, [string]$Text) {
    $html = [Net.WebUtility]::HtmlEncode($Text)
    if ($Pr) { $html += " <a href=`"$AdoRepoUrl/pull/$Pr`">PR #$Pr</a>" }
    $null = Invoke-Ado -Method post -Uri "wit/workItems/$WorkItemId/comments?api-version=7.1-preview.4" -Body @{ text = $html }
}
function Add-PrLink($w) {
    if (-not $Pr) { return }
    $url = "$AdoRepoUrl/pull/$Pr"
    if ($w.relations | Where-Object { $_.url -eq $url }) { return }
    $null = Update-AdoItem $w.id @(@{ op = 'add'; path = '/relations/-'; value = @{ rel = 'Hyperlink'; url = $url; attributes = @{ comment = "PR #$Pr" } } })
}

switch ($Command) {
    'list' {
        $index = Get-AdoIndex
        $col = if ($Column) { Resolve-AdoColumn $Column }
        $order = @($AdoColumns.Keys)
        $index.Items.GetEnumerator() | ForEach-Object {
            $f = $_.Value.fields
            [pscustomobject]@{
                ID = $_.Key; Kolumna = $f.'System.BoardColumn'
                Rola = (($f.'System.Tags' -split ';\s*') | Where-Object { $_ -like 'rola:*' } | ForEach-Object { $_.Substring(5) }) -join '/'
                Blok = if ($f.'System.Tags' -match 'zablokowane') { 'tak' } else { '' }
                Tytul = ($f.'System.Title' -replace "^$([regex]::Escape($_.Key)):\s*", '')
            }
        } | Where-Object {
            ($All -or $_.Kolumna -ne 'Gotowe') -and (-not $col -or $_.Kolumna -eq $col) -and (-not $Role -or $_.Rola -match [regex]::Escape($Role))
        } | Sort-Object @{ e = { $order.IndexOf($_.Kolumna) } }, ID |
            Format-Table -AutoSize -Wrap ID, Kolumna, Rola, Blok, @{ n = 'Tytuł'; e = { if ($_.Tytul.Length -gt 90) { $_.Tytul.Substring(0, 87) + '...' } else { $_.Tytul } } }
    }
    'show' {
        Need-Id
        $w = Get-Task (Get-AdoIndex)
        $w = Invoke-Ado -Uri "wit/workitems/$($w.id)?`$expand=relations&api-version=7.1"
        $f = $w.fields
        "$($f.'System.Title')"
        "Kolumna: $($f.'System.BoardColumn')   Tagi: $($f.'System.Tags')"
        "Link: $AdoOrg/$AdoProject/_workitems/edit/$($w.id)"
        ''
        [Net.WebUtility]::HtmlDecode(($f.'System.Description' -replace '<br\s*/?>', "`n" -replace '</p>', "`n" -replace '<[^>]+>', '')).Trim()
        $links = $w.relations | Where-Object { $_.rel -eq 'Hyperlink' } | ForEach-Object { $_.url }
        if ($links) { ''; 'Linki:'; $links | ForEach-Object { "  $_" } }
        $comments = (Invoke-Ado -Uri "wit/workItems/$($w.id)/comments?order=asc&api-version=7.1-preview.4").comments
        if ($comments) {
            ''; 'Komentarze:'
            $comments | ForEach-Object { "  [$(([datetime]$_.createdDate).ToString('yyyy-MM-dd HH:mm'))] $([Net.WebUtility]::HtmlDecode(($_.text -replace '<[^>]+>', '')))" }
        }
    }
    'new' {
        Need-Id
        if (-not $Title -or -not $Role) { throw 'Podaj -Title i -Role.' }
        $index = Get-AdoIndex
        if ($index.Items[$Id]) { throw "Zadanie $Id juz istnieje." }
        $col = Resolve-AdoColumn ($(if ($Column) { $Column } else { 'todo' }))
        $roles = $Role -split '[/,\s]+' | Where-Object { $_ }
        $tags = (@("bk:$Id") + ($roles | ForEach-Object { "rola:$_" })) -join '; '
        $desc = "<p><b>Rola:</b> $([Net.WebUtility]::HtmlEncode($Role))</p>"
        if ($Related) { $desc += "<p><b>Powiązane:</b> $([Net.WebUtility]::HtmlEncode($Related))</p>" }
        if ($Notes) { $desc += "<p><b>Uwagi:</b> $([Net.WebUtility]::HtmlEncode($Notes))</p>" }
        $epic = Get-AdoEpic $Id $index
        $ops = @((New-AdoPatch 'System.Title' "${Id}: $Title"), (New-AdoPatch 'System.Description' $desc), (New-AdoPatch 'System.Tags' $tags),
            @{ op = 'add'; path = '/relations/-'; value = @{ rel = 'System.LinkTypes.Hierarchy-Reverse'; url = $epic.url } })
        $w = Invoke-Ado -Method post -Uri 'wit/workitems/$Issue?api-version=7.1' -Body $ops -ContentType 'application/json-patch+json'
        if ($col -ne 'Do zrobienia') { $null = Update-AdoItem $w.id @((New-AdoPatch 'System.State' $AdoColumns[$col]), (New-AdoPatch (Get-AdoColumnField) $col)) }
        Add-PrLink $w
        "Utworzono $Id -> $col  ($AdoOrg/$AdoProject/_workitems/edit/$($w.id))"
    }
    'move' {
        Need-Id
        if (-not $Arg) { throw 'Podaj kolumne: todo, doing, review, owner, done.' }
        $col = Resolve-AdoColumn $Arg
        $w = Get-Task (Get-AdoIndex -Relations)
        $null = Update-AdoItem $w.id @((New-AdoPatch 'System.State' $AdoColumns[$col]), (New-AdoPatch (Get-AdoColumnField) $col))
        Add-PrLink $w
        if ($Note) { Add-Comment $w.id $Note }
        "${Id}: $($w.fields.'System.BoardColumn') -> $col"
    }
    'note' {
        Need-Id
        $text = if ($Arg) { $Arg } else { $Note }
        if (-not $text) { throw 'Podaj tresc komentarza.' }
        $w = Get-Task (Get-AdoIndex -Relations)
        Add-PrLink $w
        Add-Comment $w.id $text
        "${Id}: dodano komentarz"
    }
    { $_ -in 'block', 'unblock' } {
        Need-Id
        $w = Get-Task (Get-AdoIndex)
        $tags = @($w.fields.'System.Tags' -split ';\s*' | Where-Object { $_ -and $_ -ne 'zablokowane' })
        if ($Command -eq 'block') { $tags += 'zablokowane' }
        $null = Update-AdoItem $w.id @(New-AdoPatch 'System.Tags' ($tags -join '; '))
        if ($Arg) { Add-Comment $w.id "$(if ($Command -eq 'block') { 'Zablokowane' } else { 'Odblokowane' }): $Arg" }
        "${Id}: $Command"
    }
}
