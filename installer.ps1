# installer.ps1 - Installa ImportaFoto
# Eseguire come Amministratore in PowerShell

$ErrorActionPreference = "Stop"
$GitHubUser = "Flavio-coding"
$GitHubRepo = "importa-foto"
$AppName = "ImportaFoto"
$TempDir = "$env:TEMP\$AppName-install"

function Write-Step($msg) { Write-Host "" ; Write-Host "  >> $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Fail($msg) { Write-Host "  [ERRORE] $msg" -ForegroundColor Red ; exit 1 }

# 0. Verifica amministratore
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Write-Fail "Esegui questo script come Amministratore." }

Write-Host ""
Write-Host "  ================================================" -ForegroundColor White
Write-Host "   Installazione $AppName" -ForegroundColor White
Write-Host "  ================================================" -ForegroundColor White

# 1. Abilita Developer Mode
Write-Step "Abilitazione modalita sviluppatore..."
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
Set-ItemProperty -Path $regPath -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force
Write-OK "Modalita sviluppatore abilitata."

# 2. Recupera ultima release da GitHub
Write-Step "Recupero ultima versione da GitHub..."
$apiUrl = "https://api.github.com/repos/$GitHubUser/$GitHubRepo/releases/latest"
$release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "InstallScript" }
Write-OK "Versione trovata: $($release.tag_name)"

# 3. Trova asset .msix e .cer
$msixAsset = $release.assets | Where-Object { $_.name -like "*.msix" } | Select-Object -First 1
$cerAsset  = $release.assets | Where-Object { $_.name -like "*.cer"  } | Select-Object -First 1
if (-not $msixAsset) { Write-Fail "Nessun file .msix trovato nella release." }
if (-not $cerAsset)  { Write-Fail "Nessun file .cer trovato nella release."  }

# 4. Download
Write-Step "Download file in corso..."
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
$msixPath = Join-Path $TempDir $msixAsset.name
$cerPath  = Join-Path $TempDir $cerAsset.name
Invoke-WebRequest -Uri $msixAsset.browser_download_url -OutFile $msixPath -UseBasicParsing
Write-OK "Scaricato: $($msixAsset.name)"
Invoke-WebRequest -Uri $cerAsset.browser_download_url -OutFile $cerPath -UseBasicParsing
Write-OK "Scaricato: $($cerAsset.name)"

# 5. Installa certificato
Write-Step "Installazione certificato..."
$cert  = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cerPath)
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store("TrustedPeople", "LocalMachine")
$store.Open("ReadWrite")
$store.Add($cert)
$store.Close()
Write-OK "Certificato installato."

# 6. Installa MSIX
Write-Step "Installazione $AppName..."
Add-AppxPackage -Path $msixPath
Write-OK "$AppName installato correttamente."

# 7. Pulizia
Write-Step "Pulizia file temporanei..."
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-OK "Pulizia completata."

Write-Host ""
Write-Host "  ================================================" -ForegroundColor Green
Write-Host "   $AppName installato con successo!" -ForegroundColor Green
Write-Host "  ================================================" -ForegroundColor Green
Write-Host ""