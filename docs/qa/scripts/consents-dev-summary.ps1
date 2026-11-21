# QA (TAM-34): read-only summary of consent records and recordConsent logs in Firebase `dev`.
#
# Prints ONLY counts and non-identifying fields. Never prints document names/paths (they contain
# the UID), consentId, e-mail or tokens. Requires `gcloud` signed in with read access to the project.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File docs/qa/scripts/consents-dev-summary.ps1 [-Freshness 1d]
param(
    [string]$Project = 'tamitu-dev-tadecode',
    [string]$Freshness = '1d'
)
$ErrorActionPreference = 'Stop'

# 1. Firestore: collection-group query on "consents" (users/{uid}/consents/{consentId}).
$t = gcloud auth print-access-token
$body = '{"structuredQuery":{"from":[{"collectionId":"consents","allDescendants":true}]}}'
$uri = "https://firestore.googleapis.com/v1/projects/$Project/databases/(default)/documents:runQuery"
$r = Invoke-RestMethod -Method Post -Uri $uri -Headers @{ Authorization = "Bearer $t" } -ContentType 'application/json' -Body $body
Remove-Variable t
$docs = @($r | Where-Object { $_.document })
"Firestore consents: $($docs.Count) document(s), " +
    "$(@($docs | ForEach-Object { ($_.document.name -split '/consents/')[0] } | Sort-Object -Unique).Count) user(s)"
$docs | ForEach-Object {
    $f = $_.document.fields
    [pscustomobject]@{
        type          = $f.type.stringValue
        policyVersion = $f.policyVersion.stringValue
        granted       = $f.granted.booleanValue
        lang          = $f.lang.stringValue
        clientAt      = $f.clientAt.timestampValue
        receivedAt    = $f.receivedAt.timestampValue
        fields        = ($f.PSObject.Properties.Name | Sort-Object) -join ','
    }
} | Format-Table -AutoSize | Out-String -Width 300

# 2. Logs of the recordconsent service: request status and allow-listed fn_event/fn_error fields.
#    uidHash is shortened to 8 characters (enough to compare entries, not to identify anyone).
"recordconsent logs ($Freshness):"
$filter = 'resource.type="cloud_run_revision" AND resource.labels.service_name="recordconsent" AND ' +
    '(httpRequest.status>0 OR jsonPayload.message=("fn_event" OR "fn_error"))'
$entries = gcloud logging read $filter --project $Project --freshness=$Freshness --limit 50 --format=json | ConvertFrom-Json
$entries | ForEach-Object {
    $p = $_.jsonPayload
    [pscustomobject]@{
        timestamp = $_.timestamp
        severity  = $_.severity
        http      = $_.httpRequest.status
        message   = $p.message
        result    = $p.result
        errorCode = $p.errorCode
        uidHash8  = if ($p.uidHash) { $p.uidHash.Substring(0, [Math]::Min(8, $p.uidHash.Length)) } else { $null }
    }
} | Format-Table -AutoSize | Out-String -Width 300
