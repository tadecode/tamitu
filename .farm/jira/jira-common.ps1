# Wspólne funkcje farmy dla Jiry (projekt TAM, tadecode.atlassian.net). Od 2026-11-20 Jira
# zastępuje Azure Boards jako jedyne źródło prawdy o zadaniach i statusach.
# Działa na koncie Farm Bot (token w Menedżerze poświadczeń: .farm/atlassian/set-token.ps1 jira).
#
# Model:
#   - zadanie = Task (BUG-* = Bug); ID farmy (np. SEC-35) w polu „Farm Id” (tekst), tytuł bez kodu,
#     czytelny dla człowieka; klucz Jiry (TAM-12) jest dodatkowy; task.ps1 przyjmuje oba,
#   - epik = Epic z „Farm Id” = prefiks (np. SEC); zadanie wskazuje epik polem parent,
#   - role = etykiety `rola:mobile-dev`, blokada = etykieta `zablokowane`,
#   - PR = link zdalny do GitHuba.
. (Join-Path $PSScriptRoot '..\atlassian\atlassian-common.ps1')

$JiraProject = 'TAM'
$JiraBoardUrl = "$AtlassianSite/jira/software/projects/$JiraProject/boards/1"
$JiraRepoUrl = 'https://github.com/tadecode/tamitu'
# Kolumna (skrót) -> status Jiry. Kolejność = kolejność na tablicy.
$JiraColumns = [ordered]@{
    todo   = 'To Do'
    doing  = 'In Progress'
    review = 'In Review'
    owner  = 'Owner Review'
    done   = 'Done'
}
$JiraColumnAlias = @{
    'in-progress' = 'doing'; 'qa' = 'review'; 'czeka' = 'owner'
    'Do zrobienia' = 'todo'; 'W pracy (agent)' = 'doing'; 'Przegląd i QA' = 'review'; 'Czeka na Ciebie' = 'owner'; 'Gotowe' = 'done'
}
$JiraEpics = @{
    'P2' = 'Faza 2: Projekt'; 'P3' = 'Faza 3: Implementacja'; 'SEC' = 'Bezpieczeństwo'
    'GH' = 'Infrastruktura i CI (Steward)'; 'O' = 'Pytania otwarte'; 'REV' = 'Przeglądy kodu'
    'QA' = 'Testy i QA'; 'TEST' = 'Testy integracyjne i CI'; 'OBS' = 'Obserwowalność'; 'ARCH' = 'Architektura'
    'FARM' = 'Farma agentów'; 'BUG' = 'Błędy'; 'UX' = 'UX i grafika'; 'OWNER' = 'Czynności właściciela'
    'DOC' = 'Dokumentacja'; 'CHORE' = 'Porządki'; 'AN' = 'Analiza'; 'MD' = 'Wdrożenia mobile-dev'
}

$script:JiraAuth = Get-AtlassianAuthHeader (Get-AtlassianToken jira)
$script:utf8 = New-Object Text.UTF8Encoding($false)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Invoke-Jira {
    param([string]$Method = 'get', [string]$Uri, $Body)
    if ($Uri -notmatch '^https://') { $Uri = "$AtlassianSite/rest/api/3/$Uri" }
    $req = [Net.HttpWebRequest]::Create($Uri)
    $req.Method = $Method.ToUpper()
    $req.Headers['Authorization'] = $script:JiraAuth
    $req.Accept = 'application/json'
    if ($null -ne $Body) {
        $bytes = $script:utf8.GetBytes((ConvertTo-Json -InputObject $Body -Depth 20 -Compress))
        $req.ContentType = 'application/json; charset=utf-8'
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

# Tekst -> dokument ADF (akapity; puste linie rozdzielają akapity, pojedyncze = hardBreak).
function ConvertTo-Adf([string]$Text, [string]$LinkUrl, [string]$LinkText) {
    $paras = @()
    foreach ($block in ($Text -split "(\r?\n){2,}" | Where-Object { $_.Trim() })) {
        $content = @()
        $lines = $block.Trim() -split "\r?\n"
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($i) { $content += @{ type = 'hardBreak' } }
            if ($lines[$i]) { $content += @{ type = 'text'; text = $lines[$i] } }
        }
        $paras += @{ type = 'paragraph'; content = $content }
    }
    if ($LinkUrl) {
        $paras += @{ type = 'paragraph'; content = @(@{ type = 'text'; text = $(if ($LinkText) { $LinkText } else { $LinkUrl }); marks = @(@{ type = 'link'; attrs = @{ href = $LinkUrl } }) }) }
    }
    if (-not $paras) { $paras = @(@{ type = 'paragraph'; content = @() }) }
    @{ type = 'doc'; version = 1; content = $paras }
}

# ADF -> zwykły tekst (do `show`).
function ConvertFrom-Adf($Node) {
    if ($null -eq $Node) { return '' }
    switch ($Node.type) {
        'text' { return $Node.text }
        'hardBreak' { return "`n" }
        default {
            $inner = ($Node.content | ForEach-Object { ConvertFrom-Adf $_ }) -join ''
            if ($Node.type -in 'paragraph', 'heading', 'listItem') { return "$inner`n" }
            return $inner
        }
    }
}

# Pole „Farm Id” (tekst) - szukane po nazwie, żeby skrypt nie zależał od numeru customfield.
function Get-JiraFarmIdField {
    if (-not $script:FarmIdField) {
        $f = (Invoke-Jira -Uri 'field') | Where-Object { $_.custom -and $_.name -eq 'Farm Id' } | Select-Object -First 1
        if (-not $f) { throw 'Brak pola „Farm Id” w Jirze (projekt TAM, typy Task, Bug, Epic).' }
        $script:FarmIdField = $f.id
    }
    $script:FarmIdField
}
function Get-FarmId($Issue) { $Issue.fields.(Get-JiraFarmIdField) }

# Wszystkie zadania i epiki projektu: @{ Items = @{ID farmy -> issue}; Epics = @{prefiks epiku -> issue}; Keys = @{TAM-n -> ID farmy} }
function Get-JiraIndex {
    $items = @{}; $epics = @{}; $keys = @{}
    $token = $null
    $fid = Get-JiraFarmIdField
    do {
        $body = @{ jql = "project = $JiraProject ORDER BY created ASC"; maxResults = 100; fields = @('summary', 'status', 'labels', 'issuetype', 'parent', 'created', $fid) }
        if ($token) { $body.nextPageToken = $token }
        $r = Invoke-Jira -Method post -Uri 'search/jql' -Body $body
        foreach ($i in $r.issues) {
            $id = $i.fields.$fid
            if (-not $id) { continue }
            if ($i.fields.issuetype.name -eq 'Epic') { if (-not $epics[$id]) { $epics[$id] = $i } }
            elseif (-not $items[$id]) { $items[$id] = $i; $keys[$i.key] = $id }
        }
        $token = $r.nextPageToken
    } while ($token -and -not $r.isLast)
    @{ Items = $items; Epics = $epics; Keys = $keys }
}

function Get-JiraEpicKey([string]$TaskId) {
    if ($TaskId -match '^(P\d+)-') { $Matches[1] } elseif ($TaskId -match '^([A-Z]+)') { $Matches[1] }
}

# Zwraca epik dla zadania; tworzy go, jeśli nie ma.
function Get-JiraEpic([string]$TaskId, $Index) {
    $key = Get-JiraEpicKey $TaskId
    if ($Index.Epics[$key]) { return $Index.Epics[$key] }
    $title = if ($JiraEpics[$key]) { $JiraEpics[$key] } else { $key }
    $fields = @{ project = @{ key = $JiraProject }; issuetype = @{ name = 'Epic' }; summary = $title }
    $fields[(Get-JiraFarmIdField)] = $key
    $e = Invoke-Jira -Method post -Uri 'issue' -Body @{ fields = $fields }
    $Index.Epics[$key] = $e
    $e
}

function Resolve-JiraColumn([string]$Name) {
    if ($JiraColumns.Contains($Name)) { return $Name }
    if ($JiraColumnAlias[$Name]) { return $JiraColumnAlias[$Name] }
    $byStatus = $JiraColumns.Keys | Where-Object { $JiraColumns[$_] -eq $Name }
    if ($byStatus) { return $byStatus }
    throw "Nieznana kolumna '$Name'. Dozwolone: $(($JiraColumns.Keys) -join ', ')."
}

# Przenosi zadanie do statusu odpowiadającego kolumnie (skrót: todo/doing/review/owner/done).
function Set-JiraColumn([string]$Key, [string]$Column) {
    $target = $JiraColumns[$Column]
    $t = (Invoke-Jira -Uri "issue/$Key/transitions").transitions | Where-Object { $_.to.name -eq $target } | Select-Object -First 1
    if (-not $t) { throw "Brak przejścia do '$target' dla $Key." }
    $null = Invoke-Jira -Method post -Uri "issue/$Key/transitions" -Body @{ transition = @{ id = $t.id } }
}

# Przypisanie: kolumna `owner` (czeka na człowieka) -> właściciel, pozostałe -> Farm Bot.
function Set-JiraAssigneeFor([string]$Key, [string]$Column) {
    if (-not $script:BotAccount) {
        $script:BotAccount = (Invoke-Jira -Uri 'myself').accountId
        # ConvertFrom-Json w PS 5.1 zwraca tablicę JSON jako jeden obiekt - rozwijamy ją przez ForEach-Object.
        $users = Invoke-Jira -Uri "user/assignable/search?project=$JiraProject&maxResults=50"
        $script:OwnerAccount = ($users | ForEach-Object { $_ } | Where-Object { $_.accountId -ne $script:BotAccount } | Select-Object -First 1).accountId
    }
    $acc = if ($Column -eq 'owner' -and $script:OwnerAccount) { $script:OwnerAccount } else { $script:BotAccount }
    $null = Invoke-Jira -Method put -Uri "issue/$Key/assignee" -Body @{ accountId = $acc }
}

function Add-JiraComment([string]$Key, [string]$Text, [int]$Pr) {
    $url = if ($Pr) { "$JiraRepoUrl/pull/$Pr" }
    $null = Invoke-Jira -Method post -Uri "issue/$Key/comment" -Body @{ body = (ConvertTo-Adf $Text $url "PR #$Pr") }
}

function Add-JiraPrLink([string]$Key, [int]$Pr) {
    if (-not $Pr) { return }
    $url = "$JiraRepoUrl/pull/$Pr"
    # globalId = URL: ponowne dodanie tego samego PR-a aktualizuje link zamiast dublować.
    $null = Invoke-Jira -Method post -Uri "issue/$Key/remotelink" -Body @{
        globalId = $url
        object   = @{ url = $url; title = "PR #$Pr"; icon = @{ url16x16 = 'https://github.com/favicon.ico'; title = 'GitHub' } }
    }
}
