# FARM-001: gotowa poprawka do wklejenia przez właściciela

Orchestrator próbował zmienić `.farm/hooks/test-guards.ps1` (na zlecenie właściciela, osobny PR),
ale hook ochronny zablokował zapis: „agent nie zmienia własnych kontraktów ani zabezpieczeń".
Blokady nie omijano. Poprawkę wprowadza właściciel (CODEOWNERS), na gałęzi `fix/FARM-001`
utworzonej od `origin/main`.

## Zmiana w funkcji `Run` (linie 12–15)

Przed:
```powershell
function Run([string]$script, [string]$json, [string[]]$extra) {
    $null = $json | & powershell -NoProfile -ExecutionPolicy Bypass -File $script @extra 2>&1
    return $LASTEXITCODE
}
```

Po:
```powershell
function Run([string]$script, [string]$json, [string[]]$extra) {
    # stderr hooka (komunikat blokady) nie może przerywać samotestu (CI: NativeCommandError);
    # oceniamy wyłącznie kod wyjścia hooka.
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $null = $json | & powershell -NoProfile -ExecutionPolicy Bypass -File $script @extra 2>&1
        $code = $LASTEXITCODE
    }
    finally { $ErrorActionPreference = $prev }
    return $code
}
```

Plik musi zachować BOM UTF-8 (kontrola `farm-guards` sprawdza BOM w `.ps1`).
Asercje (`Check ...`) i hooki bez zmian. Po zmianie: uruchomić samotest lokalnie
(wszystkie PASS) i sprawdzić zielony `farm-guards` w PR.
Diagnoza Stewarda jest niezweryfikowana na poprawce; jeśli CI nadal czerwone, obejrzeć log runu.
