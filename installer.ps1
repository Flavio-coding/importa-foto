# installer.ps1 - Installa ImportaFoto
# Eseguire come Amministratore in PowerShell

$ErrorActionPreference = "Stop"
$GitHubUser = "Flavio-coding"
$GitHubRepo = "importa-foto"
$AppName = "ImportaFoto"
$TempDir = "$env:TEMP\$AppName-install"

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
    exit 1
}

function Write-ProgressBar($label, $percent) {
    $width  = 34
    $filled = [math]::Round($width * $percent / 100)
    $empty  = $width - $filled
    $bar    = ([string][char]0x2588) * $filled + ([string][char]0x2591) * $empty
    $pct    = "$percent%".PadLeft(4)
    Write-Host "`r  $label [" -NoNewline -ForegroundColor DarkGray
    Write-Host $bar -NoNewline -ForegroundColor Cyan
    Write-Host "] $pct  " -NoNewline -ForegroundColor White
}

function Download-WithProgress($url, $outFile, $label) {
    $wc = New-Object System.Net.WebClient
    $wc.add_DownloadProgressChanged({
        param($s, $e)
        if ($e.ProgressPercentage -ge 0) {
            Write-ProgressBar $label $e.ProgressPercentage
        }
    })
    $task = $wc.DownloadFileTaskAsync($url, $outFile)
    while (-not $task.IsCompleted) { Start-Sleep -Milliseconds 80 }
    Write-ProgressBar $label 100
    Write-Host ""
    $wc.Dispose()
    if ($task.IsFaulted) { Write-Fail "Download fallito: $($task.Exception.InnerException.Message)" }
}

# Banner
Clear-Host
Write-Host ""
Write-Host "  +----------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |                                              |" -ForegroundColor Cyan
Write-Host "  |    " -NoNewline -ForegroundColor Cyan
Write-Host "ImportaFoto" -NoNewline -ForegroundColor White
Write-Host " // Installer                    |" -ForegroundColor Cyan
Write-Host "  |                                              |" -ForegroundColor Cyan
Write-Host "  +----------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

# 0. Admin check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Write-Fail "Esegui questo script come Amministratore." }

# 1. Developer Mode
Write-Step "Abilitazione modalita sviluppatore..."
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
Set-ItemProperty -Path $regPath -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force
Write-OK "Modalita sviluppatore abilitata."

# 2. GitHub API
Write-Step "Contatto GitHub per l'ultima versione..."
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$GitHubUser/$GitHubRepo/releases/latest" -Headers @{ "User-Agent" = "InstallScript" }
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

Download-WithProgress $cerAsset.browser_download_url  $cerPath  "  .cer "
Write-OK "Certificato scaricato."

Download-WithProgress $msixAsset.browser_download_url $msixPath " .msix "
Write-OK "Pacchetto scaricato."

# 5. Certificato
Write-Step "Installazione certificato..."
$cert  = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cerPath)
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store("TrustedPeople", "LocalMachine")
$store.Open("ReadWrite")
$store.Add($cert)
$store.Close()
Write-OK "Certificato installato in LocalMachine\TrustedPeople."

# 6. MSIX
Write-Step "Installazione $AppName..."
Add-AppxPackage -Path $msixPath
Write-OK "$AppName installato correttamente."

# 7. Pulizia
Write-Step "Pulizia..."
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-OK "File temporanei rimossi."

# Fine
Write-Host ""
Write-Host "  +----------------------------------------------+" -ForegroundColor Green
Write-Host "  |                                              |" -ForegroundColor Green
Write-Host "  |    " -NoNewline -ForegroundColor Green
Write-Host "Installazione completata con successo!" -NoNewline -ForegroundColor White
Write-Host "   |" -ForegroundColor Green
Write-Host "  |    Cerca ImportaFoto nel menu Start.        |" -ForegroundColor Green
Write-Host "  |                                              |" -ForegroundColor Green
Write-Host "  +----------------------------------------------+" -ForegroundColor Green
Write-Host ""
