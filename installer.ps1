# ============================================================
#  installer.ps1
#  Scarica e installa ImportaFoto dalla pagina GitHub releases
#  Eseguire come Amministratore in PowerShell
# ============================================================

$ErrorActionPreference = "Stop"

# ── CONFIG ───────────────────────────────────────────────────
$GitHubUser    = "Flavio-coding"
$GitHubRepo    = "importa-foto"
$AppName       = "ImportaFoto"
$TempDir       = "$env:TEMP\$AppName-install"
# ─────────────────────────────────────────────────────────────

function Write-Step($msg) {
    Write-Host ""
    Write-Host "  >> $msg" -ForegroundColor Cyan
}

function Write-OK($msg) {
    Write-Host "  [OK] $msg" -ForegroundColor Green
}

function Write-Fail($msg) {
    Write-Host "  [ERRORE] $msg" -ForegroundColor Red
    exit 1
}

# ── 0. Verifica amministratore ────────────────────────────────
if (-not ([Security.Principal.WindowsPrincipal]
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Fail "Esegui questo script come Amministratore."
}

Write-Host ""
Write-Host "  ================================================" -ForegroundColor White
Write-Host "   Installazione $AppName" -ForegroundColor White
Write-Host "  ================================================" -ForegroundColor White

# ── 1. Abilita Developer Mode (necessario per sideload) ───────
Write-Step "Abilitazione modalita sviluppatore..."
try {
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force
    Write-OK "Modalita sviluppatore abilitata."
} catch {
    Write-Fail "Impossibile abilitare la modalita sviluppatore: $_"
}

# ── 2. Scarica info ultima release da GitHub API ──────────────
Write-Step "Recupero ultima versione da GitHub..."
try {
    $apiUrl  = "https://api.github.com/repos/$GitHubUser/$GitHubRepo/releases/latest"
    $headers = @{ "User-Agent" = "InstallScript" }
    $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
    $version = $release.tag_name
    Write-OK "Versione trovata: $version"
} catch {
    Write-Fail "Impossibile contattare GitHub. Controlla la connessione: $_"
}

# ── 3. Trova gli asset .msix e .cer nella release ─────────────
$msixAsset = $release.assets | Where-Object { $_.name -like "*.msix" } | Select-Object -First 1
$cerAsset  = $release.assets | Where-Object { $_.name -like "*.cer"  } | Select-Object -First 1

if (-not $msixAsset) { Write-Fail "Nessun file .msix trovato nella release $version." }
if (-not $cerAsset)  { Write-Fail "Nessun file .cer trovato nella release $version."  }

# ── 4. Crea cartella temporanea e scarica i file ──────────────
Write-Step "Download file in corso..."
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

$msixPath = Join-Path $TempDir $msixAsset.name
$cerPath  = Join-Path $TempDir $cerAsset.name

try {
    Invoke-WebRequest -Uri $msixAsset.browser_download_url -OutFile $msixPath -UseBasicParsing
    Write-OK "Scaricato: $($msixAsset.name)"
    Invoke-WebRequest -Uri $cerAsset.browser_download_url  -OutFile $cerPath  -UseBasicParsing
    Write-OK "Scaricato: $($cerAsset.name)"
} catch {
    Write-Fail "Errore durante il download: $_"
}

# ── 5. Installa il certificato self-signed ────────────────────
Write-Step "Installazione certificato..."
try {
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cerPath)
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store(
        [System.Security.Cryptography.X509Certificates.StoreName]::TrustedPeople,
        [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine
    )
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    $store.Add($cert)
    $store.Close()
    Write-OK "Certificato installato in LocalMachine\TrustedPeople."
} catch {
    Write-Fail "Impossibile installare il certificato: $_"
}

# ── 6. Installa il pacchetto MSIX ─────────────────────────────
Write-Step "Installazione $AppName..."
try {
    Add-AppxPackage -Path $msixPath
    Write-OK "$AppName installato correttamente."
} catch {
    Write-Fail "Impossibile installare il pacchetto MSIX: $_"
}

# ── 7. Pulizia file temporanei ────────────────────────────────
Write-Step "Pulizia file temporanei..."
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-OK "Pulizia completata."

Write-Host ""
Write-Host "  ================================================" -ForegroundColor Green
Write-Host "   $AppName installato con successo!" -ForegroundColor Green
Write-Host "  ================================================" -ForegroundColor Green
Write-Host ""