# Zadania farmy w Jirze (projekt TAM; jedyne źródło prawdy o zadaniach i statusach od 2026-11-20).
# Pisze tylko orkiestrator. Pozostałe role zgłaszają zmiany w sekcji „Dla orkiestratora” pliku przekazania.
# Działa na koncie Farm Bot (token: .farm/atlassian/set-token.ps1 jira).
#
#   task.ps1 list [-Column owner] [-Role mobile-dev] [-All]   lista (domyślnie bez Done)
#   task.ps1 show SEC-35                                       szczegóły i komentarze (działa też: show TAM-12)
#   (ID farmy jest w polu „Farm Id”; tytuł piszemy prosto, bez kodu, dla człowieka)
#   task.ps1 epics                                             otwarte epiki (funkcje produktu)
#   task.ps1 new  P3-15 -Title "..." -Role mobile-dev -Epic EP-PLANY [-Column todo] [-Related "US-004, ADR-0002"] [-Notes "..."] [-Pr 61]
#             -Epic: Farm Id epiku (EP-ZGODY, EP-PLAN-AI, ...) albo jego klucz TAM-n; wymagany, epików skrypt nie tworzy
#   task.ps1 move P3-04 owner [-Note "PR #61 czeka na merge"] [-Pr 61]
#   task.ps1 note P3-04 "tekst komentarza" [-Pr 61]
#   task.ps1 block P3-04 "powód"     /   task.ps1 unblock P3-04
#
# Kolumny: todo (To Do), doing (In Progress), review (In Review), owner (Owner Review), done (Done).
# Zasada: zadanie czekające na właściciela (merge PR-a, decyzja, czynność w konsoli) -> `owner`.
# Gałąź i tytuł PR-a zaczynaj od klucza Jiry (np. TAM-12), żeby GitHub for Jira je powiązał.
param(
    [Parameter(Mandatory, Position = 0)][ValidateSet('list', 'show', 'new', 'move', 'note', 'block', 'unblock', 'epics')][string]$Command,
    [Parameter(Position = 1)][string]$Id,
    [Parameter(Position = 2)][string]$Arg,
    [string]$Title, [string]$Role, [string]$Epic, [string]$Column, [string]$Related, [string]$Notes, [string]$Note,
    [int]$Pr, [switch]$All
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/jira-common.ps1"

function Need-Id { if (-not $Id) { throw 'Podaj ID zadania, np. P3-04 albo TAM-12.' } }
function Get-Task($index) {
    $i = if ($Id -match "^$JiraProject-\d+$") { $k = $index.Keys[$Id]; if ($k) { $script:Id = $k; $index.Items[$k] } } else { $index.Items[$Id] }
    if (-not $i) { throw "Nie ma zadania $Id w Jirze ($JiraBoardUrl)." }
    $i
}

switch ($Command) {
    'epics' { 'Otwarte epiki (funkcje produktu):'; Get-JiraOpenEpicsText (Get-JiraIndex) }
    'list' {
        $index = Get-JiraIndex
        $col = if ($Column) { Resolve-JiraColumn $Column }
        $order = @($JiraColumns.Values)
        $index.Items.GetEnumerator() | ForEach-Object {
            $f = $_.Value.fields
            [pscustomobject]@{
                ID = $_.Key; Klucz = $_.Value.key; Status = $f.status.name; Rola = Get-JiraRoles $_.Value; Kto = $f.assignee.displayName
                Blok = if ($f.labels -contains 'zablokowane') { 'tak' } else { '' }
                Tytul = ($f.summary -replace "^$([regex]::Escape($_.Key)):\s*", '')
            }
        } | Where-Object {
            ($All -or $_.Status -ne 'Done') -and (-not $col -or $_.Status -eq $JiraColumns[$col]) -and (-not $Role -or $_.Rola -match [regex]::Escape($Role))
        } | Sort-Object @{ e = { $order.IndexOf($_.Status) } }, ID |
            Format-Table -AutoSize -Wrap ID, Klucz, Status, Rola, Kto, Blok, @{ n = 'Tytuł'; e = { if ($_.Tytul.Length -gt 80) { $_.Tytul.Substring(0, 77) + '...' } else { $_.Tytul } } }
    }
    'show' {
        Need-Id
        $i = Get-Task (Get-JiraIndex)
        $i = Invoke-Jira -Uri "issue/$($i.key)?fields=summary,status,labels,description,parent,assignee,$(Get-JiraRoleField)"
        $f = $i.fields
        "$Id ($($i.key))  $($f.summary)"
        "Status: $($f.status.name)   Rola: $(Get-JiraRoles $i)   Przypisane: $($f.assignee.displayName)   Etykiety: $($f.labels -join ', ')"
        if ($f.parent) { "Epik: $($f.parent.fields.summary)" }
        "Link: $AtlassianSite/browse/$($i.key)"
        ''
        (ConvertFrom-Adf $f.description).Trim()
        $links = (Invoke-Jira -Uri "issue/$($i.key)/remotelink") | ForEach-Object { "  $($_.object.title): $($_.object.url)" }
        if ($links) { ''; 'Linki:'; $links }
        $comments = (Invoke-Jira -Uri "issue/$($i.key)/comment?orderBy=created").comments
        if ($comments) {
            ''; 'Komentarze:'
            $comments | ForEach-Object { "  [$(([datetime]$_.created).ToString('yyyy-MM-dd HH:mm'))] $((ConvertFrom-Adf $_.body).Trim() -replace "`n", ' ')" }
        }
    }
    'new' {
        Need-Id
        if (-not $Title -or -not $Role) { throw 'Podaj -Title i -Role.' }
        if ($Id -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') { throw "Niepoprawne ID '$Id' (litery, cyfry, - . _)." }
        $index = Get-JiraIndex
        if ($index.Items[$Id]) { throw "Zadanie $Id już istnieje ($($index.Items[$Id].key))." }
        $col = Resolve-JiraColumn ($(if ($Column) { $Column } else { 'todo' }))
        $labels = @()
        $text = "Rola: $Role"
        if ($Related) { $text += "`n`nPowiązane: $Related" }
        if ($Notes) { $text += "`n`nUwagi: $Notes" }
        $epic = Get-JiraEpic $Epic $index
        $type = if ($Id -like 'BUG-*') { 'Bug' } else { 'Task' }
        # Tytuł bez kodu (czytelny dla człowieka); ID farmy trafia do pola „Farm Id”.
        $fields = @{
            project = @{ key = $JiraProject }; issuetype = @{ name = $type }; summary = ($Title -replace "^$([regex]::Escape($Id)):\s*", '')
            labels = $labels; description = (ConvertTo-Adf $text); parent = @{ key = $epic.key }
        }
        $fields[(Get-JiraFarmIdField)] = $Id
        # @(...) - funkcja z jedną rolą zwraca pojedynczy obiekt, a Jira wymaga tablicy.
        $fields[(Get-JiraRoleField)] = @(ConvertTo-JiraRoles $Role)
        $i = Invoke-Jira -Method post -Uri 'issue' -Body @{ fields = $fields }
        if ($col -ne 'todo') { Set-JiraColumn $i.key $col }
        Set-JiraAssigneeFor $i.key $col
        Add-JiraPrLink $i.key $Pr
        "Utworzono $Id = $($i.key) -> $($JiraColumns[$col])  ($AtlassianSite/browse/$($i.key))"
    }
    'move' {
        Need-Id
        if (-not $Arg) { throw 'Podaj kolumnę: todo, doing, review, owner, done.' }
        $col = Resolve-JiraColumn $Arg
        $i = Get-Task (Get-JiraIndex)
        if ($i.fields.status.name -ne $JiraColumns[$col]) { Set-JiraColumn $i.key $col }
        Set-JiraAssigneeFor $i.key $col
        Add-JiraPrLink $i.key $Pr
        if ($Note) { Add-JiraComment $i.key $Note $Pr }
        "${Id} ($($i.key)): $($i.fields.status.name) -> $($JiraColumns[$col])"
    }
    'note' {
        Need-Id
        $text = if ($Arg) { $Arg } else { $Note }
        if (-not $text) { throw 'Podaj treść komentarza.' }
        $i = Get-Task (Get-JiraIndex)
        Add-JiraPrLink $i.key $Pr
        Add-JiraComment $i.key $text $Pr
        "${Id} ($($i.key)): dodano komentarz"
    }
    { $_ -in 'block', 'unblock' } {
        Need-Id
        $i = Get-Task (Get-JiraIndex)
        $op = if ($Command -eq 'block') { 'add' } else { 'remove' }
        $null = Invoke-Jira -Method put -Uri "issue/$($i.key)" -Body @{ update = @{ labels = @(@{ $op = 'zablokowane' }) } }
        if ($Arg) { Add-JiraComment $i.key "$(if ($Command -eq 'block') { 'Zablokowane' } else { 'Odblokowane' }): $Arg" }
        "${Id} ($($i.key)): $Command"
    }
}
