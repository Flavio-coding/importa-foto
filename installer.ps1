# installer.ps1 - ImportaFoto Installer
# Eseguire come Amministratore in PowerShell

$ErrorActionPreference = "Stop"
$GitHubUser        = "Flavio-coding"
$GitHubRepo        = "importa-foto"
$AppName           = "ImportaFoto"
$TempDir           = "$env:TEMP\$AppName-install"
$PackageFamilyName = "f3aa30ca-c500-4208-98c5-158f4f2d184a_tex0e22xxpf6g"
$AppUserModelId    = "$PackageFamilyName!App"

# ── Verifica admin ────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host ""
    Write-Host "  ATTENZIONE: Questo script deve essere eseguito come Amministratore." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Come fare:" -ForegroundColor White
    Write-Host "    1. Chiudi questa finestra" -ForegroundColor DarkGray
    Write-Host "    2. Cerca 'PowerShell' nel menu Start" -ForegroundColor DarkGray
    Write-Host "    3. Clic destro -> 'Esegui come amministratore'" -ForegroundColor DarkGray
    Write-Host "    4. Incolla di nuovo il comando e premi INVIO" -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "  Premi INVIO per chiudere"
    exit 1
}

# ── Carica WPF ────────────────────────────────────────────────
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ── XAML della finestra ───────────────────────────────────────
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Importa Foto — Installer"
    Width="520" Height="340"
    MinWidth="520" MinHeight="340"
    MaxWidth="520" MaxHeight="340"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
    Background="#FFFFFF"
    FontFamily="Segoe UI">

    <Window.Resources>
        <Style x:Key="AccentButton" TargetType="Button">
            <Setter Property="Background" Value="{DynamicResource {x:Static SystemColors.HighlightBrushKey}}"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="Height" Value="42"/>
            <Setter Property="Width" Value="160"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border"
                                Background="{TemplateBinding Background}"
                                CornerRadius="21"
                                Padding="16,0">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Opacity" Value="0.85"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Opacity" Value="0.7"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="SecondaryButton" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#555555"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="Height" Value="36"/>
            <Setter Property="Width" Value="120"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#DDDDDD"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="8">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#F5F5F5"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Contenuto centrale -->
        <StackPanel Grid.Row="1"
                    HorizontalAlignment="Center"
                    Width="400">

            <!-- Titolo principale -->
            <TextBlock x:Name="TxtTitolo"
                       Text="Hai 1 app da installare"
                       FontSize="24"
                       FontWeight="SemiBold"
                       Foreground="#1C1C1C"
                       TextAlignment="Center"
                       HorizontalAlignment="Center"
                       Height="64"
                       VerticalAlignment="Center"
                       TextWrapping="Wrap"/>

            <!-- Zona bottone / barra progresso (stessa altezza, sovrapposta) -->
            <Grid Height="44" Margin="0,0,0,0">

                <!-- Bottone Installa -->
                <Button x:Name="BtnInstalla"
                        Content="Installa"
                        Style="{StaticResource AccentButton}"
                        HorizontalAlignment="Center"/>

                <!-- Barra progresso + percentuale -->
                <Grid x:Name="GridProgresso"
                      Visibility="Collapsed"
                      VerticalAlignment="Center"
                      Margin="8,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock x:Name="TxtPerc"
                               Grid.Column="0"
                               Text="0%"
                               FontSize="12"
                               Foreground="#555555"
                               VerticalAlignment="Center"
                               Margin="0,0,10,0"/>
                    <ProgressBar x:Name="Barra"
                                 Grid.Column="1"
                                 Minimum="0" Maximum="100" Value="0"
                                 Height="3"
                                 VerticalAlignment="Center"
                                 Foreground="{DynamicResource {x:Static SystemColors.HighlightBrushKey}}"/>
                </Grid>

            </Grid>

            <!-- Path file corrente -->
            <TextBlock x:Name="TxtPathCorrente"
                       Text=""
                       FontSize="11"
                       Foreground="#888888"
                       TextAlignment="Center"
                       HorizontalAlignment="Center"
                       TextTrimming="CharacterEllipsis"
                       MaxWidth="380"
                       Margin="0,8,0,0"/>

        </StackPanel>

        <!-- Checkbox desktop in basso -->
        <CheckBox x:Name="ChkDesktop"
                  Grid.Row="2"
                  Content="Aggiungi al Desktop"
                  FontSize="12"
                  Foreground="#555555"
                  HorizontalAlignment="Center"
                  VerticalAlignment="Center"
                  IsChecked="True"
                  Margin="0,0,0,12"/>

    </Grid>
</Window>
"@

# ── Crea la finestra ──────────────────────────────────────────
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Riferimenti ai controlli
$TxtTitolo      = $window.FindName("TxtTitolo")
$BtnInstalla    = $window.FindName("BtnInstalla")
$GridProgresso  = $window.FindName("GridProgresso")
$Barra          = $window.FindName("Barra")
$TxtPerc        = $window.FindName("TxtPerc")
$TxtPathCorrente= $window.FindName("TxtPathCorrente")
$ChkDesktop     = $window.FindName("ChkDesktop")

# ── Helper: aggiorna UI dal thread di background ──────────────
function Update-UI($action) {
    $window.Dispatcher.Invoke([Action]$action)
}

# ── Funzione download con progress ───────────────────────────
function Download-File($url, $outFile, $label) {
    $uri        = [System.Uri]$url
    $request    = [System.Net.HttpWebRequest]::Create($uri)
    $response   = $request.GetResponse()
    $total      = $response.ContentLength
    $stream     = $response.GetResponseStream()
    $fileStream = [System.IO.File]::Create($outFile)
    $buffer     = New-Object byte[] 65536
    $totalRead  = 0

    while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $fileStream.Write($buffer, 0, $read)
        $totalRead += $read
        if ($total -gt 0) {
            $pct = [math]::Min(100, [math]::Round($totalRead * 100 / $total))
            $p   = $pct
            $l   = $label
            Update-UI {
                $Barra.Value   = $p
                $TxtPerc.Text  = "$p%"
                $TxtPathCorrente.Text = $l
            }
        }
    }
    $fileStream.Close()
    $stream.Close()
    $response.Close()
}

# ── Click Installa ────────────────────────────────────────────
$BtnInstalla.Add_Click({
    $BtnInstalla.IsEnabled = $false
    $addDesktop = $ChkDesktop.IsChecked

    # Nascondi bottone e checkbox, mostra barra
    Update-UI {
        $BtnInstalla.Visibility   = [System.Windows.Visibility]::Collapsed
        $ChkDesktop.Visibility    = [System.Windows.Visibility]::Collapsed
        $GridProgresso.Visibility = [System.Windows.Visibility]::Visible
        $TxtTitolo.Text           = "Installazione in corso…"
    }

    $job = [System.Threading.Thread]::new({
        try {
            # 1. Developer Mode
            Update-UI { $TxtPathCorrente.Text = "Abilitazione modalita sviluppatore…" }
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
            if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
            Set-ItemProperty -Path $regPath -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force

            # 2. GitHub API
            Update-UI {
                $Barra.Value = 5
                $TxtPerc.Text = "5%"
                $TxtPathCorrente.Text = "Contatto GitHub…"
            }
            $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$GitHubUser/$GitHubRepo/releases/latest" -Headers @{ "User-Agent" = "InstallScript" }

            $msixAsset = $release.assets | Where-Object { $_.name -like "*.msix" } | Select-Object -First 1
            $cerAsset  = $release.assets | Where-Object { $_.name -like "*.cer"  } | Select-Object -First 1
            if (-not $msixAsset -or -not $cerAsset) { throw "Asset non trovati nella release." }

            # 3. Download certificato (0-40%)
            New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
            $cerPath  = Join-Path $TempDir $cerAsset.name
            $msixPath = Join-Path $TempDir $msixAsset.name

            Update-UI { $TxtPathCorrente.Text = "Download certificato…" }
            $uri     = [System.Uri]$cerAsset.browser_download_url
            $request = [System.Net.HttpWebRequest]::Create($uri)
            $resp    = $request.GetResponse()
            $total   = $resp.ContentLength
            $stream  = $resp.GetResponseStream()
            $fs      = [System.IO.File]::Create($cerPath)
            $buf     = New-Object byte[] 65536
            $tr      = 0
            while (($r = $stream.Read($buf, 0, $buf.Length)) -gt 0) {
                $fs.Write($buf, 0, $r); $tr += $r
                if ($total -gt 0) {
                    $p = [math]::Round(5 + ($tr / $total) * 35)
                    Update-UI { $Barra.Value = $p; $TxtPerc.Text = "$p%" }
                }
            }
            $fs.Close(); $stream.Close(); $resp.Close()

            # 4. Download MSIX (40-90%)
            Update-UI { $TxtPathCorrente.Text = "Download pacchetto…" }
            $uri     = [System.Uri]$msixAsset.browser_download_url
            $request = [System.Net.HttpWebRequest]::Create($uri)
            $resp    = $request.GetResponse()
            $total   = $resp.ContentLength
            $stream  = $resp.GetResponseStream()
            $fs      = [System.IO.File]::Create($msixPath)
            $tr      = 0
            while (($r = $stream.Read($buf, 0, $buf.Length)) -gt 0) {
                $fs.Write($buf, 0, $r); $tr += $r
                if ($total -gt 0) {
                    $p = [math]::Round(40 + ($tr / $total) * 50)
                    Update-UI { $Barra.Value = $p; $TxtPerc.Text = "$p%" }
                }
            }
            $fs.Close(); $stream.Close(); $resp.Close()

            # 5. Certificato
            Update-UI { $TxtPathCorrente.Text = "Installazione certificato…"; $Barra.Value = 92; $TxtPerc.Text = "92%" }
            $cert  = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cerPath)
            $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("TrustedPeople", "LocalMachine")
            $store.Open("ReadWrite"); $store.Add($cert); $store.Close()

            # 6. MSIX
            Update-UI { $TxtPathCorrente.Text = "Installazione app…"; $Barra.Value = 96; $TxtPerc.Text = "96%" }
            Add-AppxPackage -Path $msixPath

            # 7. Collegamento desktop
            if ($addDesktop) {
                $shortcutPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath("Desktop"), "Importa Foto.lnk")
                $wsh      = New-Object -ComObject WScript.Shell
                $shortcut = $wsh.CreateShortcut($shortcutPath)
                $shortcut.TargetPath = "shell:AppsFolder\$AppUserModelId"
                $shortcut.Save()
            }

            # 8. Pulizia
            Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue

            # Fine
            Update-UI {
                $Barra.Value          = 100
                $TxtPerc.Text         = "100%"
                $GridProgresso.Visibility = [System.Windows.Visibility]::Collapsed
                $TxtPathCorrente.Text = ""
                $TxtTitolo.Text       = "Fatto!`nPuoi chiudere questa finestra"
            }

        } catch {
            $errMsg = $_.Exception.Message
            Update-UI {
                $TxtTitolo.Text       = "Errore durante l'installazione."
                $TxtPathCorrente.Text = $errMsg
                $GridProgresso.Visibility = [System.Windows.Visibility]::Collapsed
            }
        }
    })
    $job.IsBackground = $true
    $job.Start()
})

# ── Mostra la finestra ────────────────────────────────────────
$window.ShowDialog() | Out-Null# installer.ps1 - Installa ImportaFoto
# Eseguire come Amministratore in PowerShell

$ErrorActionPreference = "Stop"
$GitHubUser       = "Flavio-coding"
$GitHubRepo       = "importa-foto"
$AppName          = "ImportaFoto"
$TempDir          = "$env:TEMP\$AppName-install"
$PackageFamilyName = "f3aa30ca-c500-4208-98c5-158f4f2d184a_tex0e22xxpf6g"
$AppUserModelId    = "$PackageFamilyName!App"

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
Write-Host "  |        ImportaFoto  //  Installer              |" -ForegroundColor Cyan
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
Write-Host "  |     Vuoi aggiungere ImportaFoto al Desktop?    |" -ForegroundColor DarkCyan
Write-Host "  |                                                |" -ForegroundColor DarkCyan
Write-Host "  |       [S] Si              [N] No               |" -ForegroundColor DarkCyan
Write-Host "  |                                                |" -ForegroundColor DarkCyan
Write-Host "  +------------------------------------------------+" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Risposta: " -NoNewline -ForegroundColor White
$risposta = Read-Host

if ($risposta -match "^[SsYy]") {
    try {
        $shortcutPath = [System.IO.Path]::Combine(
            [System.Environment]::GetFolderPath("Desktop"),
            "Importa Foto.lnk"
        )
        $wsh      = New-Object -ComObject WScript.Shell
        $shortcut = $wsh.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = "shell:AppsFolder\$AppUserModelId"
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
Write-Host "  |     Installazione completata con successo!     |" -ForegroundColor Green
Write-Host "  |     Cerca ImportaFoto nel menu Start.          |" -ForegroundColor Green
Write-Host "  |                                                |" -ForegroundColor Green
Write-Host "  +------------------------------------------------+" -ForegroundColor Green
Write-Host ""
Write-Host "  Premi INVIO per chiudere..." -ForegroundColor DarkGray
Read-Host
