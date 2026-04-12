# uninstaller.ps1 - Disinstalla Importa Foto
# Eseguire come Amministratore in PowerShell

$ErrorActionPreference = "Stop"

# 0. Auto-elevazione UAC se non admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/Flavio-coding/importa-foto/main/uninstaller.ps1 | iex`"" -Verb RunAs
    exit
}

$AppName           = "ImportaFoto"
$PackageFamilyName = "f3aa30ca-c500-4208-98c5-158f4f2d184a_tex0e22xxpf6g"

function Write-Step($msg) {
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " >> " -NoNewline -ForegroundColor Black -BackgroundColor Cyan
    Write-Host " $msg" -ForegroundColor Cyan
}

function Write-OK($msg) {
    Write-Host "  " -NoNewline
    Write-Host " OK " -NoNewline -ForegroundColor Black -BackgroundColor Green
    Write-Host " $msg" -ForegroundColor Green
}

function Write-Fail($msg) {
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " ERRORE " -NoNewline -ForegroundColor White -BackgroundColor Red
    Write-Host " $msg" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Premi INVIO per chiudere..." -ForegroundColor DarkGray
    Read-Host
    exit 1
}

# Banner
Clear-Host
Write-Host ""
Write-Host "  +------------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |                                                |" -ForegroundColor Cyan
Write-Host "  |        Importa Foto  //  Uninstaller           |" -ForegroundColor Cyan
Write-Host "  |                                                |" -ForegroundColor Cyan
Write-Host "  +------------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

# 1. Verifica che l'app sia installata (silenzioso)
$pkg = Get-AppxPackage | Where-Object { $_.PackageFamilyName -eq $PackageFamilyName } | Select-Object -First 1
if (-not $pkg) {
    Write-Fail "$AppName non risulta installato su questo computer."
}

# 2. Rimuovi collegamento desktop se esiste
Write-Step "Rimozione collegamento Desktop..."
$lnk = [System.IO.Path]::Combine([System.Environment]::GetFolderPath("Desktop"), "Importa Foto.lnk")
if (Test-Path $lnk) {
    Remove-Item $lnk -Force
    Write-OK "Collegamento rimosso."
} else {
    Write-Host "  " -NoNewline
    Write-Host " -- " -NoNewline -ForegroundColor Black -BackgroundColor DarkGray
    Write-Host " Nessun collegamento trovato sul Desktop." -ForegroundColor DarkGray
}

# 3. Disinstalla il pacchetto
Write-Step "Disinstallazione $AppName..."
try {
    Remove-AppxPackage -Package $pkg.PackageFullName
} catch {
    Write-Fail "Impossibile disinstallare il pacchetto: $_"
}
Write-OK "$AppName disinstallato correttamente."

# 4. Rimuovi certificato self-signed dallo store
Write-Step "Rimozione certificato..."
try {
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("TrustedPeople", "LocalMachine")
    $store.Open("ReadWrite")
    $certs = $store.Certificates | Where-Object { $_.Subject -like "*Flavio*" }
    if ($certs) {
        foreach ($c in $certs) { $store.Remove($c) }
        Write-OK "Certificato rimosso."
    } else {
        Write-Host "  " -NoNewline
        Write-Host " -- " -NoNewline -ForegroundColor Black -BackgroundColor DarkGray
        Write-Host " Nessun certificato trovato." -ForegroundColor DarkGray
    }
    $store.Close()
} catch {
    Write-Host "  " -NoNewline
    Write-Host " AVVISO " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host " Impossibile rimuovere il certificato: $_" -ForegroundColor Yellow
}

# 5. Disabilita Developer Mode
Write-Step "Disabilitazione modalita sviluppatore..."
try {
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    if (Test-Path $regPath) {
        Set-ItemProperty -Path $regPath -Name "AllowDevelopmentWithoutDevLicense" -Value 0 -Type DWord -Force
        Write-OK "Modalita sviluppatore disabilitata."
    } else {
        Write-Host "  " -NoNewline
        Write-Host " -- " -NoNewline -ForegroundColor Black -BackgroundColor DarkGray
        Write-Host " Chiave registro non trovata, nessuna modifica." -ForegroundColor DarkGray
    }
} catch {
    Write-Host "  " -NoNewline
    Write-Host " AVVISO " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host " Impossibile disabilitare la modalita sviluppatore: $_" -ForegroundColor Yellow
}

# Fine
Write-Host ""
Write-Host "  +------------------------------------------------+" -ForegroundColor Green
Write-Host "  |                                                |" -ForegroundColor Green
Write-Host "  |    Disinstallazione completata con successo!   |" -ForegroundColor Green
Write-Host "  |                                                |" -ForegroundColor Green
Write-Host "  +------------------------------------------------+" -ForegroundColor Green
Write-Host ""
Write-Host "  Premi INVIO per chiudere..." -ForegroundColor DarkGray
Read-Host
exit# uninstaller.ps1 - Disinstalla ImportaFoto
# Eseguire come Amministratore in PowerShell

$ErrorActionPreference = "Stop"
$AppName           = "ImportaFoto"
$PackageFamilyName = "f3aa30ca-c500-4208-98c5-158f4f2d184a_tex0e22xxpf6g"

function Write-Step($msg) {
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " >> " -NoNewline -ForegroundColor Black -BackgroundColor Cyan
    Write-Host " $msg" -ForegroundColor Cyan
}

function Write-OK($msg) {
    Write-Host "  " -NoNewline
    Write-Host " OK " -NoNewline -ForegroundColor Black -BackgroundColor Green
    Write-Host " $msg" -ForegroundColor Green
}

function Write-Fail($msg) {
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host " ERRORE " -NoNewline -ForegroundColor White -BackgroundColor Red
    Write-Host " $msg" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Premi INVIO per chiudere..." -ForegroundColor DarkGray
    Read-Host
    exit 1
}

# Banner
Clear-Host
Write-Host ""
Write-Host "  +------------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |                                                |" -ForegroundColor Cyan
Write-Host "  |        Importa Foto  //  Uninstaller           |" -ForegroundColor Cyan
Write-Host "  |                                                |" -ForegroundColor Cyan
Write-Host "  +------------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

# 0. Verifica admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "  " -NoNewline
    Write-Host " ATTENZIONE " -NoNewline -ForegroundColor White -BackgroundColor DarkYellow
    Write-Host " Questo script deve essere eseguito come Amministratore." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Come fare:" -ForegroundColor White
    Write-Host "    1. Chiudi questa finestra" -ForegroundColor DarkGray
    Write-Host "    2. Cerca 'PowerShell' nel menu Start" -ForegroundColor DarkGray
    Write-Host "    3. Clic destro -> 'Esegui come amministratore'" -ForegroundColor DarkGray
    Write-Host "    4. Incolla di nuovo il comando e premi INVIO" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Premi INVIO per chiudere..." -ForegroundColor DarkGray
    Read-Host
    exit 1
}

# 1. Verifica che l'app sia installata (silenzioso)
$pkg = Get-AppxPackage | Where-Object { $_.PackageFamilyName -eq $PackageFamilyName } | Select-Object -First 1
if (-not $pkg) {
    Write-Fail "$AppName non risulta installato su questo computer."
}

# 2. Rimuovi collegamento desktop se esiste
Write-Step "Rimozione collegamento Desktop..."
$lnk = [System.IO.Path]::Combine([System.Environment]::GetFolderPath("Desktop"), "Importa Foto.lnk")
if (Test-Path $lnk) {
    Remove-Item $lnk -Force
    Write-OK "Collegamento rimosso."
} else {
    Write-Host "  " -NoNewline
    Write-Host " -- " -NoNewline -ForegroundColor Black -BackgroundColor DarkGray
    Write-Host " Nessun collegamento trovato sul Desktop." -ForegroundColor DarkGray
}

# 4. Disinstalla il pacchetto
Write-Step "Disinstallazione $AppName..."
try {
    Remove-AppxPackage -Package $pkg.PackageFullName
} catch {
    Write-Fail "Impossibile disinstallare il pacchetto: $_"
}
Write-OK "$AppName disinstallato correttamente."

# 5. Rimuovi certificato self-signed dallo store
Write-Step "Rimozione certificato..."
try {
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("TrustedPeople", "LocalMachine")
    $store.Open("ReadWrite")
    $certs = $store.Certificates | Where-Object { $_.Subject -like "*Flavio*" }
    if ($certs) {
        foreach ($c in $certs) { $store.Remove($c) }
        Write-OK "Certificato rimosso."
    } else {
        Write-Host "  " -NoNewline
        Write-Host " -- " -NoNewline -ForegroundColor Black -BackgroundColor DarkGray
        Write-Host " Nessun certificato trovato." -ForegroundColor DarkGray
    }
    $store.Close()
} catch {
    Write-Host "  " -NoNewline
    Write-Host " AVVISO " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host " Impossibile rimuovere il certificato: $_" -ForegroundColor Yellow
}

# 6. Disabilita Developer Mode
Write-Step "Disabilitazione modalita sviluppatore..."
try {
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    if (Test-Path $regPath) {
        Set-ItemProperty -Path $regPath -Name "AllowDevelopmentWithoutDevLicense" -Value 0 -Type DWord -Force
        Write-OK "Modalita sviluppatore disabilitata."
    } else {
        Write-Host "  " -NoNewline
        Write-Host " -- " -NoNewline -ForegroundColor Black -BackgroundColor DarkGray
        Write-Host " Chiave registro non trovata, nessuna modifica." -ForegroundColor DarkGray
    }
} catch {
    Write-Host "  " -NoNewline
    Write-Host " AVVISO " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
    Write-Host " Impossibile disabilitare la modalita sviluppatore: $_" -ForegroundColor Yellow
}

# Fine
Write-Host ""
Write-Host "  +------------------------------------------------+" -ForegroundColor Green
Write-Host "  |                                                |" -ForegroundColor Green
Write-Host "  |     Disinstallazione completata con successo!  |" -ForegroundColor Green
Write-Host "  |                                                |" -ForegroundColor Green
Write-Host "  +------------------------------------------------+" -ForegroundColor Green
Write-Host ""
Write-Host "  Premi INVIO per chiudere..." -ForegroundColor DarkGray
Read-Host
exit
