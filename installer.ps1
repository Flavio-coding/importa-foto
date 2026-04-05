# installer.ps1 - Installa ImportaFoto
# Eseguire come Amministratore in PowerShell

$ErrorActionPreference = "Stop"
$GitHubUser = "Flavio-coding"
$GitHubRepo = "importa-foto"
$AppName    = "ImportaFoto"
$TempDir    = "$env:TEMP\$AppName-install"

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

function Download-WithProgress($url, $outFile, $label) {
    $uri        = [System.Uri]$url
    $request    = [System.Net.HttpWebRequest]::Create($uri)
    $response   = $request.GetResponse()
    $total      = $response.ContentLength
    $stream     = $response.GetResponseStream()
    $fileStream = [System.IO.File]::Create($outFile)
    $buffer     = New-Object byte[] 65536
    $totalRead  = 0
    $lastPct    = -1
    $width      = 34

    while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $fileStream.Write($buffer, 0, $read)
        $totalRead += $read
        if ($total -gt 0) {
            $pct = [math]::Min(100, [math]::Round($totalRead * 100 / $total))
            if ($pct -ne $lastPct) {
                $lastPct = $pct
                $filled  = [math]::Round($width * $pct / 100)
                $empty   = $width - $filled
                $bar     = ([string][char]0x2588) * $filled + ([string][char]0x2591) * $empty
                $pctStr  = "$pct%".PadLeft(4)
                Write-Host "`r  $label  [" -NoNewline -ForegroundColor DarkGray
                Write-Host $bar -NoNewline -ForegroundColor Cyan
                Write-Host "] $pctStr  " -NoNewline -ForegroundColor White
            }
        }
    }

    $fileStream.Close()
    $stream.Close()
    $response.Close()
    $bar = ([string][char]0x2588) * $width
    Write-Host "`r  $label  [" -NoNewline -ForegroundColor DarkGray
    Write-Host $bar -NoNewline -ForegroundColor Cyan
    Write-Host "] 100%  " -ForegroundColor White
}

# Banner
Clear-Host
Write-Host ""
Write-Host "  +------------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |                                                |" -ForegroundColor Cyan
Write-Host "  |       ImportaFoto  //  Installer              |" -ForegroundColor Cyan
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

# 1. Developer Mode
Write-Step "Abilitazione modalita sviluppatore..."
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
Set-ItemProperty -Path $regPath -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force
Write-OK "Modalita sviluppatore abilitata."

# 2. GitHub API
Write-Step "Contatto GitHub per l'ultima versione..."
try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$GitHubUser/$GitHubRepo/releases/latest" -Headers @{ "User-Agent" = "InstallScript" }
} catch {
    Write-Fail "Impossibile contattare GitHub. Controlla la connessione."
}
Write-OK "Versione: $($release.tag_name)"

# 3. Asset
$msixAsset = $release.assets | Where-Object { $_.name -like "*.msix" } | Select-Object -First 1
$cerAsset  = $release.assets | Where-Object { $_.name -like "*.cer"  } | Select-Object -First 1
if (-not $msixAsset) { Write-Fail "Nessun file .msix trovato nella release." }
if (-not $cerAsset)  { Write-Fail "Nessun file .cer trovato nella release."  }

# 4. Download
Write-Step "Download in corso..."
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
$msixPath = Join-Path $TempDir $msixAsset.name
$cerPath  = Join-Path $TempDir $cerAsset.name

try {
    Download-WithProgress $cerAsset.browser_download_url  $cerPath  "Certificato"
    Write-OK "Certificato scaricato."
    Download-WithProgress $msixAsset.browser_download_url $msixPath "Pacchetto  "
    Write-OK "Pacchetto scaricato."
} catch {
    Write-Fail "Errore durante il download: $_"
}

# 5. Certificato
Write-Step "Installazione certificato..."
try {
    $cert  = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cerPath)
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("TrustedPeople", "LocalMachine")
    $store.Open("ReadWrite")
    $store.Add($cert)
    $store.Close()
} catch {
    Write-Fail "Impossibile installare il certificato: $_"
}
Write-OK "Certificato installato."

# 6. MSIX
Write-Step "Installazione $AppName..."
try {
    Add-AppxPackage -Path $msixPath
} catch {
    Write-Fail "Impossibile installare il pacchetto: $_"
}
Write-OK "$AppName installato correttamente."

# 7. Pulizia
Write-Step "Pulizia..."
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-OK "File temporanei rimossi."

# 8. Collegamento Desktop
Write-Host ""
Write-Host "  +------------------------------------------------+" -ForegroundColor DarkCyan
Write-Host "  |                                                |" -ForegroundColor DarkCyan
Write-Host "  |   Vuoi aggiungere ImportaFoto al Desktop?     |" -ForegroundColor DarkCyan
Write-Host "  |                                                |" -ForegroundColor DarkCyan
Write-Host "  |     [S] Si        [N] No                      |" -ForegroundColor DarkCyan
Write-Host "  |                                                |" -ForegroundColor DarkCyan
Write-Host "  +------------------------------------------------+" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Risposta: " -NoNewline -ForegroundColor White
$risposta = Read-Host

if ($risposta -match "^[SsYy]") {
    try {
        # Trova l'app installata
        $pkg = Get-AppxPackage | Where-Object { $_.Name -like "*$AppName*" } | Select-Object -First 1
        if (-not $pkg) { Write-Fail "Impossibile trovare il pacchetto installato per creare il collegamento." }

        $appId      = (Get-AppxPackageManifest $pkg).Package.Applications.Application.Id
        $appUserModelId = "$($pkg.PackageFamilyName)!$appId"
        $shortcutPath   = [System.IO.Path]::Combine([System.Environment]::GetFolderPath("Desktop"), "$AppName.lnk")

        $wsh      = New-Object -ComObject WScript.Shell
        $shortcut = $wsh.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = "shell:AppsFolder\$appUserModelId"
        $shortcut.Save()

        Write-OK "Collegamento creato sul Desktop."
    } catch {
        Write-Host "  " -NoNewline
        Write-Host " AVVISO " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
        Write-Host " Impossibile creare il collegamento: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Nessun collegamento creato." -ForegroundColor DarkGray
}

# Fine
Write-Host ""
Write-Host "  +------------------------------------------------+" -ForegroundColor Green
Write-Host "  |                                                |" -ForegroundColor Green
Write-Host "  |    Installazione completata con successo!     |" -ForegroundColor Green
Write-Host "  |    Cerca ImportaFoto nel menu Start.          |" -ForegroundColor Green
Write-Host "  |                                                |" -ForegroundColor Green
Write-Host "  +------------------------------------------------+" -ForegroundColor Green
Write-Host ""
Write-Host "  Premi INVIO per chiudere..." -ForegroundColor DarkGray
Read-Host# installer.ps1 - Installa ImportaFoto
# Eseguire come Amministratore in PowerShell

# 0. Auto-elevazione: se non admin, riapre come admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/Flavio-coding/importa-foto/main/installer.ps1 | iex`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "Stop"
$GitHubUser = "Flavio-coding"
$GitHubRepo = "importa-foto"
$AppName    = "ImportaFoto"
$TempDir    = "$env:TEMP\$AppName-install"

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

function Download-WithProgress($url, $outFile, $label) {
    # Scarica in un file temporaneo misurando la dimensione ogni 100ms
    $uri      = [System.Uri]$url
    $request  = [System.Net.HttpWebRequest]::Create($uri)
    $response = $request.GetResponse()
    $total    = $response.ContentLength
    $stream   = $response.GetResponseStream()
    $fileStream = [System.IO.File]::Create($outFile)
    $buffer   = New-Object byte[] 65536
    $read     = 0
    $totalRead = 0
    $width    = 34
    $lastPct  = -1

    while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $fileStream.Write($buffer, 0, $read)
        $totalRead += $read
        if ($total -gt 0) {
            $pct    = [math]::Min(100, [math]::Round($totalRead * 100 / $total))
            if ($pct -ne $lastPct) {
                $lastPct = $pct
                $filled  = [math]::Round($width * $pct / 100)
                $empty   = $width - $filled
                $bar     = ([string][char]0x2588) * $filled + ([string][char]0x2591) * $empty
                $pctStr  = "$pct%".PadLeft(4)
                Write-Host "`r  $label  [" -NoNewline -ForegroundColor DarkGray
                Write-Host $bar -NoNewline -ForegroundColor Cyan
                Write-Host "] $pctStr  " -NoNewline -ForegroundColor White
            }
        }
    }

    $fileStream.Close()
    $stream.Close()
    $response.Close()

    # Riga finale pulita al 100%
    $bar = ([string][char]0x2588) * $width
    Write-Host "`r  $label  [" -NoNewline -ForegroundColor DarkGray
    Write-Host $bar -NoNewline -ForegroundColor Cyan
    Write-Host "] 100%  " -ForegroundColor White
}

# Banner
Clear-Host
Write-Host ""
Write-Host "  +------------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |                                                |" -ForegroundColor Cyan
Write-Host "  |        ImportaFoto  //  Installer              |" -ForegroundColor Cyan
Write-Host "  |                                                |" -ForegroundColor Cyan
Write-Host "  +------------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

# 1. Developer Mode
Write-Step "Abilitazione modalita sviluppatore..."
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
Set-ItemProperty -Path $regPath -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force
Write-OK "Modalita sviluppatore abilitata."

# 2. GitHub API
Write-Step "Contatto GitHub per l'ultima versione..."
try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$GitHubUser/$GitHubRepo/releases/latest" -Headers @{ "User-Agent" = "InstallScript" }
} catch {
    Write-Fail "Impossibile contattare GitHub. Controlla la connessione."
}
Write-OK "Versione: $($release.tag_name)"

# 3. Asset
$msixAsset = $release.assets | Where-Object { $_.name -like "*.msix" } | Select-Object -First 1
$cerAsset  = $release.assets | Where-Object { $_.name -like "*.cer"  } | Select-Object -First 1
if (-not $msixAsset) { Write-Fail "Nessun file .msix trovato nella release." }
if (-not $cerAsset)  { Write-Fail "Nessun file .cer trovato nella release."  }

# 4. Download
Write-Step "Download in corso..."
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
$msixPath = Join-Path $TempDir $msixAsset.name
$cerPath  = Join-Path $TempDir $cerAsset.name

try {
    Download-WithProgress $cerAsset.browser_download_url  $cerPath  "Certificato"
    Write-OK "Certificato scaricato."
    Download-WithProgress $msixAsset.browser_download_url $msixPath "Pacchetto  "
    Write-OK "Pacchetto scaricato."
} catch {
    Write-Fail "Errore durante il download: $_"
}

# 5. Certificato
Write-Step "Installazione certificato..."
try {
    $cert  = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cerPath)
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("TrustedPeople", "LocalMachine")
    $store.Open("ReadWrite")
    $store.Add($cert)
    $store.Close()
} catch {
    Write-Fail "Impossibile installare il certificato: $_"
}
Write-OK "Certificato installato."

# 6. MSIX
Write-Step "Installazione $AppName..."
try {
    Add-AppxPackage -Path $msixPath
} catch {
    Write-Fail "Impossibile installare il pacchetto: $_"
}
Write-OK "$AppName installato correttamente."

# 7. Pulizia
Write-Step "Pulizia..."
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-OK "File temporanei rimossi."

# Fine
Write-Host ""
Write-Host "  +------------------------------------------------+" -ForegroundColor Green
Write-Host "  |                                                |" -ForegroundColor Green
Write-Host "  |     Installazione completata con successo!     |" -ForegroundColor Green
Write-Host "  |     Cerca ImportaFoto nel menu Start.          |" -ForegroundColor Green
Write-Host "  |                                                |" -ForegroundColor Green
Write-Host "  +------------------------------------------------+" -ForegroundColor Green
Write-Host ""
Write-Host "  Premi INVIO per chiudere..." -ForegroundColor DarkGray
Read-Host
