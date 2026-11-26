# TAM-89: runs node:test files against the Firebase emulators (auth, functions, firestore) with the
# Vertex fake. Sets ONLY emulator-time variables in this process; nothing is written to .env files.
#
# ALWAYS through the farm lock (fixed ports 8080/5001/9099 and 8787 for the fake), from the repo root:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .farm/test-lock.ps1 -Resource firebase-emulators `
#     -Command "powershell -NoProfile -ExecutionPolicy Bypass -File backend/functions/test/emulator/run-emulator-tests.ps1"
# With QA tests (paths relative to the repo root):
#     ... run-emulator-tests.ps1 -Tests tests/firebase-emulator/p3-05-generate-plan.int.mjs
#
# demo-* project: the Firebase CLI never contacts a real project, and src/ai.ts accepts
# AI_ENDPOINT_OVERRIDE only for demo-* projects inside the emulator. 0 paid calls.
param(
    [string[]]$Tests = @('backend/functions/test/emulator/smoke.int.mjs'),
    [string]$Project = 'demo-tamitu-qa',
    [int]$FakePort = 8787,
    [int]$AttemptTimeoutMs = 2000
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
$functions = Join-Path $repo 'backend\functions'

if (-not $env:JAVA_HOME) {
    $jbr = 'C:\Program Files\Android\Android Studio\jbr'
    if (Test-Path (Join-Path $jbr 'bin\java.exe')) { $env:JAVA_HOME = $jbr; $env:Path = "$jbr\bin;$env:Path" }
}

# Test UID_HASH_PEPPER: random, in the git-ignored .secret.local (never a real value).
$secret = Join-Path $functions '.secret.local'
if (-not (Test-Path $secret)) {
    $bytes = New-Object byte[] 32
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    "UID_HASH_PEPPER=$(-join ($bytes | ForEach-Object { $_.ToString('x2') }))" | Set-Content -Encoding ascii $secret
}

# Function configuration for the run (same as QA P3-04 + the fake).
$env:ENVIRONMENT = 'dev'
$env:ALLOW_REAL_DATA = 'false'
$env:ENFORCE_APP_CHECK = 'false'
$env:AI_MODEL_ID = 'gemini-3.1-flash-lite'
$env:AI_LOCATION = 'eu'
$env:AI_ENDPOINT_OVERRIDE = "http://127.0.0.1:$FakePort"
$env:AI_ATTEMPT_TIMEOUT_MS = "$AttemptTimeoutMs"

Push-Location $functions
try {
    npm run build
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally { Pop-Location }

$files = ($Tests | ForEach-Object { '"' + (Join-Path $repo $_) + '"' }) -join ' '
Push-Location (Join-Path $repo 'backend')
try {
    firebase emulators:exec --project $Project --only auth,functions,firestore "node --test $files"
    $code = $LASTEXITCODE
} finally { Pop-Location }
exit $code
