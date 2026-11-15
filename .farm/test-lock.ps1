# Kolejka na zasoby wspolne maszyny (emulator Androida, urzadzenie, emulatory Firebase).
#
# Worktree rozdzielaja pliki, ale nie rozdzielaja emulatora, urzadzenia adb ani stalych
# portow. Testy, ktore ich uzywaja, uruchamiaj PRZEZ ten skrypt: drugi agent poczeka
# w kolejce zamiast nadpisac instalacje aplikacji albo zajac port.
# Zwykle testy (flutter analyze, flutter test, vitest) NIE potrzebuja blokady.
#
# Uzycie:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .farm/test-lock.ps1 -Resource device -Command "flutter test integration_test -d emulator-5554"
#   ... -Resource firebase-emulators -Command "npm --prefix backend/functions run test:emulator"
#   ... -Resource device -TimeoutMin 60 -Command "..."
# Zasoby (konwencja): device (emulator lub telefon), firebase-emulators (porty Firebase).
# Blokada to mutex systemowy: zwalnia sie sama, takze gdy proces padnie lub okno zamkniesz.
param(
    [Parameter(Mandatory = $true)][string]$Resource,
    [Parameter(Mandatory = $true)][string]$Command,
    [int]$TimeoutMin = 30
)

if ($Resource -notmatch '^[a-z0-9][a-z0-9-]*$') {
    Write-Error 'Nazwa zasobu: male litery, cyfry i myslnik (np. device).'
    exit 1
}

$mutex = New-Object System.Threading.Mutex($false, "Global\farm-$Resource")
$held = $false
$sw = [Diagnostics.Stopwatch]::StartNew()
try {
    while (-not $held) {
        try {
            $held = $mutex.WaitOne(10000)
        } catch [System.Threading.AbandonedMutexException] {
            # poprzedni wlasciciel padl bez zwolnienia; blokada jest teraz nasza
            $held = $true
        }
        if (-not $held) {
            $min = [math]::Floor($sw.Elapsed.TotalMinutes)
            if ($min -ge $TimeoutMin) {
                Write-Error "Zasob '$Resource' zajety dluzej niz $TimeoutMin min. Rezygnuje."
                exit 2
            }
            Write-Host "Czekam na zasob '$Resource' (zajety, czekam $min min)..."
        }
    }
    Write-Host "Zasob '$Resource' zajety przez ten przebieg. Uruchamiam: $Command"
    powershell -NoProfile -Command $Command
    $code = $LASTEXITCODE
} finally {
    if ($held) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
Write-Host "Zasob '$Resource' zwolniony."
exit $code
