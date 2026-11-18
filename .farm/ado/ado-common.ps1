# Wspolne funkcje Azure Boards dla skryptow w .farm/ado/ (dot-source: . "$PSScriptRoot/ado-common.ps1").
# Logowanie: token z Azure CLI (`az login`). Nie uzywamy `az rest`: az.cmd przepuszcza URL przez cmd.exe,
# ktory traktuje `&` jako separator polecen i ucina zapytania.
$ErrorActionPreference = 'Stop'
$AdoOrg = 'https://dev.azure.com/tadecode'
$AdoProject = 'Tamitu'
$AdoTeam = 'Tamitu Team'
$AdoRepoUrl = 'https://github.com/tadecode/tamitu'
$AdoBoardUrl = "$AdoOrg/$AdoProject/_boards/board/t/$([uri]::EscapeDataString($AdoTeam))/Issues"
$script:utf8 = New-Object Text.UTF8Encoding($false)

# Kolumny tablicy (kolejnosc jak na tablicy) i stan Basic, do ktorego naleza.
$AdoColumns = [ordered]@{
    'Do zrobienia' = 'To Do'; 'W pracy (agent)' = 'Doing'; 'Przegląd i QA' = 'Doing'
    'Czeka na Ciebie' = 'Doing'; 'Gotowe' = 'Done'
}
# Krotkie nazwy kolumn uzywane przez orkiestratora.
$AdoColumnAlias = @{
    'todo' = 'Do zrobienia'; 'doing' = 'W pracy (agent)'; 'in-progress' = 'W pracy (agent)'
    'review' = 'Przegląd i QA'; 'owner' = 'Czeka na Ciebie'; 'done' = 'Gotowe'
}
$AdoEpics = @{
    'P2' = 'Faza 2: Projekt'; 'P3' = 'Faza 3: Implementacja'; 'SEC' = 'Bezpieczeństwo (SEC)'
    'GH' = 'Infrastruktura i CI (Steward)'; 'O' = 'Pytania otwarte'; 'REV' = 'Przeglądy kodu'
}

$script:AdoToken = (& az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv)
if (-not $script:AdoToken) { throw 'Brak tokenu Azure DevOps: uruchom `az login`.' }
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Invoke-Ado {
    param([string]$Method = 'get', [string]$Uri, $Body, [string]$ContentType = 'application/json')
    if ($Uri -notmatch '^https://') { $Uri = "$AdoOrg/$AdoProject/_apis/$Uri" }
    $req = [Net.HttpWebRequest]::Create($Uri)
    $req.Method = $Method.ToUpper()
    $req.Headers['Authorization'] = "Bearer $script:AdoToken"
    if ($null -ne $Body) {
        # -InputObject zachowuje tablice jednoelementowe (operacje json-patch musza byc tablica).
        $bytes = $script:utf8.GetBytes((ConvertTo-Json -InputObject $Body -Depth 10 -Compress))
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

function New-AdoPatch([string]$Field, $Value) { @{ op = 'add'; path = "/fields/$Field"; value = $Value } }

function Update-AdoItem([int]$Id, [array]$Ops) {
    Invoke-Ado -Method patch -Uri "wit/workitems/$Id`?api-version=7.1" -Body $Ops -ContentType 'application/json-patch+json'
}

function Get-AdoColumnField {
    if (-not $script:AdoColField) {
        $b = Invoke-Ado -Uri "$AdoOrg/$AdoProject/$([uri]::EscapeDataString($AdoTeam))/_apis/work/boards/Issues?api-version=7.1"
        $script:AdoColField = $b.fields.columnField.referenceName
    }
    $script:AdoColField
}

# Wszystkie Issue i Epic projektu; zwraca @{ Items = @{ID -> item}; Epics = @{klucz -> item} }.
# Tagi filtrujemy tutaj: WIQL `Tags CONTAINS` dopasowuje tylko caly tag. Przy duplikatach wygrywa najstarszy.
function Get-AdoIndex([switch]$Relations) {
    $q = @{ query = "SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = '$AdoProject' AND [System.WorkItemType] IN ('Issue', 'Epic') ORDER BY [System.Id]" }
    $ids = @((Invoke-Ado -Method post -Uri 'wit/wiql?api-version=7.1' -Body $q).workItems.id)
    $items = @{}; $epics = @{}
    $expand = if ($Relations) { '&$expand=relations' } else { '' }
    for ($i = 0; $ids.Count -and $i -lt $ids.Count; $i += 200) {
        $chunk = $ids[$i..([Math]::Min($i + 199, $ids.Count - 1))] -join ','
        foreach ($w in (Invoke-Ado -Uri "wit/workitems?ids=$chunk$expand&api-version=7.1").value) {
            foreach ($t in ($w.fields.'System.Tags' -split ';\s*')) {
                if ($t -like 'bk:*' -and -not $items[$t.Substring(3)]) { $items[$t.Substring(3)] = $w }
                if ($t -like 'epic:*' -and -not $epics[$t.Substring(5)]) { $epics[$t.Substring(5)] = $w }
            }
        }
    }
    @{ Items = $items; Epics = $epics }
}

function Get-AdoEpicKey([string]$TaskId) {
    if ($TaskId -match '^(P\d+)-') { $Matches[1] } elseif ($TaskId -match '^([A-Z]+)') { $Matches[1] }
}

# Zwraca epik dla zadania; tworzy go, jesli nie ma.
function Get-AdoEpic([string]$TaskId, $Index) {
    $key = Get-AdoEpicKey $TaskId
    if ($Index.Epics[$key]) { return $Index.Epics[$key] }
    $title = if ($AdoEpics[$key]) { $AdoEpics[$key] } else { $key }
    $e = Invoke-Ado -Method post -Uri 'wit/workitems/$Epic?api-version=7.1' -ContentType 'application/json-patch+json' `
        -Body @((New-AdoPatch 'System.Title' $title), (New-AdoPatch 'System.Tags' "epic:$key"))
    $Index.Epics[$key] = $e
    $e
}

function Resolve-AdoColumn([string]$Name) {
    if ($AdoColumnAlias[$Name]) { return $AdoColumnAlias[$Name] }
    if ($AdoColumns.Contains($Name)) { return $Name }
    throw "Nieznana kolumna '$Name'. Dozwolone: $(($AdoColumnAlias.Keys | Sort-Object) -join ', ') albo pelna nazwa kolumny."
}
