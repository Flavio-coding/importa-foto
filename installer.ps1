# installer.ps1 - ImportaFoto Installer
# Eseguire come Amministratore in PowerShell

$ErrorActionPreference = "Stop"

# ── Verifica admin ────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host ""
    Write-Host "  ATTENZIONE: Eseguire come Amministratore." -ForegroundColor Yellow
    Write-Host "    1. Chiudi questa finestra" -ForegroundColor DarkGray
    Write-Host "    2. Cerca PowerShell nel menu Start" -ForegroundColor DarkGray
    Write-Host "    3. Clic destro -> Esegui come amministratore" -ForegroundColor DarkGray
    Write-Host "    4. Incolla di nuovo il comando" -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "  Premi INVIO per chiudere"
    exit 1
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# ── Colore accento reale di Windows ──────────────────────────
function Get-AccentColor {
    try {
        $raw = (Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Accent" -Name "AccentColorMenu").AccentColorMenu
        $b = [byte](($raw -shr 0)  -band 0xFF)
        $g = [byte](($raw -shr 8)  -band 0xFF)
        $r = [byte](($raw -shr 16) -band 0xFF)
        return [System.Windows.Media.Color]::FromRgb($r, $g, $b)
    } catch {
        return [System.Windows.Media.Color]::FromRgb(0, 103, 192)
    }
}
$accentColor = Get-AccentColor
$accentBrush = New-Object System.Windows.Media.SolidColorBrush($accentColor)
$accentHex   = "#{0:X2}{1:X2}{2:X2}" -f $accentColor.R, $accentColor.G, $accentColor.B

# ── XAML ──────────────────────────────────────────────────────
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Importa Foto — Installer"
    Width="520" Height="340"
    ResizeMode="NoResize"
    WindowStartupLocation="CenterScreen"
    Background="#FFFFFF"
    FontFamily="Segoe UI">
    <Window.Resources>
        <Style x:Key="AccentBtn" TargetType="Button">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="15"/>
            <Setter Property="Height" Value="44"/>
            <Setter Property="Width" Value="180"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="22">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Opacity" Value="0.85"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="bd" Property="Opacity" Value="0.7"/>
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

        <StackPanel Grid.Row="1" HorizontalAlignment="Center" Width="440" Spacing="0">

            <!-- Testo principale -->
            <TextBlock x:Name="TxtTitolo"
                       Text="Clicca per installare Importa Foto"
                       FontSize="22" FontWeight="SemiBold" Foreground="#1C1C1C"
                       TextAlignment="Center" HorizontalAlignment="Center"
                       Height="64" TextWrapping="Wrap" VerticalAlignment="Center"/>

            <!-- Bottone / Barra sovrapposti -->
            <Grid Height="44">
                <Button x:Name="BtnInstalla" Content="Installa"
                        Style="{StaticResource AccentBtn}"
                        Background="#0067C0"
                        HorizontalAlignment="Center"/>
                <Grid x:Name="GridProgresso" Visibility="Collapsed" VerticalAlignment="Center" Margin="16,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock x:Name="TxtPerc" Grid.Column="0"
                               Text="0%" FontSize="12" Foreground="#555555"
                               VerticalAlignment="Center" Margin="0,0,10,0"/>
                    <ProgressBar x:Name="Barra" Grid.Column="1"
                                 Minimum="0" Maximum="100" Value="0"
                                 Height="3" VerticalAlignment="Center"/>
                </Grid>
            </Grid>

            <!-- Messaggio stato sotto la barra -->
            <TextBlock x:Name="TxtMsg"
                       Text=""
                       FontSize="12" FontFamily="Segoe UI"
                       Foreground="#555555"
                       TextAlignment="Center" HorizontalAlignment="Center"
                       TextTrimming="CharacterEllipsis"
                       MaxWidth="420"
                       Margin="0,10,0,0"
                       Height="20"/>

        </StackPanel>

        <CheckBox x:Name="ChkDesktop" Grid.Row="2"
                  Content="Crea un collegamento sul desktop"
                  FontSize="12" Foreground="#555555"
                  HorizontalAlignment="Center" VerticalAlignment="Center"
                  IsChecked="True" Margin="0,0,0,16"/>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$TxtTitolo     = $window.FindName("TxtTitolo")
$BtnInstalla   = $window.FindName("BtnInstalla")
$GridProgresso = $window.FindName("GridProgresso")
$Barra         = $window.FindName("Barra")
$TxtPerc       = $window.FindName("TxtPerc")
$TxtMsg        = $window.FindName("TxtMsg")
$ChkDesktop    = $window.FindName("ChkDesktop")

# Applica colore accento reale via codice (non XAML) dopo il load
$BtnInstalla.Background = $accentBrush
$Barra.Foreground       = $accentBrush

# ── Hashtable condiviso UI <-> worker ─────────────────────────
$shared = [hashtable]::Synchronized(@{
    Pct    = 0
    Msg    = ""
    Done   = $false
    Error  = $false
    ErrMsg = ""
})

# ── DispatcherTimer: legge $shared ogni 80ms e aggiorna UI ────
$timer          = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(80)
$timer.Add_Tick({
    $Barra.Value  = $shared.Pct
    $TxtPerc.Text = "$($shared.Pct)%"
    $TxtMsg.Text  = $shared.Msg

    if ($shared.Done) {
        $timer.Stop()
        $GridProgresso.Visibility = [System.Windows.Visibility]::Collapsed
        $TxtMsg.Text              = ""
        $TxtTitolo.Text           = "Fatto!`nPuoi chiudere questa finestra"
    }
    if ($shared.Error) {
        $timer.Stop()
        $GridProgresso.Visibility = [System.Windows.Visibility]::Collapsed
        $TxtTitolo.Text           = "Errore durante l'installazione."
        $TxtMsg.Foreground        = [System.Windows.Media.Brushes]::Red
        $TxtMsg.Text              = $shared.ErrMsg
    }
})

# ── Click Installa ────────────────────────────────────────────
$BtnInstalla.Add_Click({
    $BtnInstalla.Visibility   = [System.Windows.Visibility]::Collapsed
    $ChkDesktop.Visibility    = [System.Windows.Visibility]::Collapsed
    $GridProgresso.Visibility = [System.Windows.Visibility]::Visible
    $TxtTitolo.Text           = "Installazione in corso…"
    $addDesktop               = [bool]$ChkDesktop.IsChecked

    $cfg = @{
        GhUser   = "Flavio-coding"
        GhRepo   = "importa-foto"
        TempDir  = "$env:TEMP\ImportaFoto-install"
        AppUMID  = "f3aa30ca-c500-4208-98c5-158f4f2d184a_tex0e22xxpf6g!App"
        Desktop  = $addDesktop
        Shared   = $shared
    }

    $timer.Start()

    # Fix PS5: usa New-Object invece di [Thread]::new() che è ambiguo
    $ts = [System.Threading.ThreadStart]{
        param()
        # Legge $cfg e $shared dal closure tramite script:
    }

    # Approccio affidabile su PS5: RunspacePool con ArgumentList
    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.Open()
    $rs.SessionStateProxy.SetVariable("cfg", $cfg)

    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs
    $null = $ps.AddScript({
        $s = $cfg.Shared
        function SP($pct, $msg) { $s.Pct = $pct; $s.Msg = $msg }

        try {
            SP 2 "Abilitazione modalita sviluppatore…"
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
            if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
            Set-ItemProperty -Path $regPath -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force

            SP 6 "Contatto GitHub per l'ultima versione…"
            $release   = Invoke-RestMethod -Uri "https://api.github.com/repos/$($cfg.GhUser)/$($cfg.GhRepo)/releases/latest" -Headers @{ "User-Agent" = "InstallScript" }
            $msixAsset = $release.assets | Where-Object { $_.name -like "*.msix" } | Select-Object -First 1
            $cerAsset  = $release.assets | Where-Object { $_.name -like "*.cer"  } | Select-Object -First 1
            if (-not $msixAsset -or -not $cerAsset) { throw "Asset .msix o .cer non trovati nella release." }

            New-Item -ItemType Directory -Path $cfg.TempDir -Force | Out-Null
            $cerPath  = Join-Path $cfg.TempDir $cerAsset.name
            $msixPath = Join-Path $cfg.TempDir $msixAsset.name
            $buf      = New-Object byte[] 65536

            # Download certificato 8→38%
            SP 8 "Download del certificato…"
            $req  = [System.Net.HttpWebRequest]::Create([System.Uri]$cerAsset.browser_download_url)
            $resp = $req.GetResponse(); $tot = $resp.ContentLength
            $stm  = $resp.GetResponseStream()
            $fs   = [System.IO.File]::Create($cerPath)
            $tr   = 0
            while (($r = $stm.Read($buf, 0, $buf.Length)) -gt 0) {
                $fs.Write($buf, 0, $r); $tr += $r
                if ($tot -gt 0) { SP ([math]::Round(8 + ($tr / $tot) * 30)) "Download del certificato…" }
            }
            $fs.Close(); $stm.Close(); $resp.Close()

            # Download MSIX 40→88%
            SP 40 "Download dell'app…"
            $req  = [System.Net.HttpWebRequest]::Create([System.Uri]$msixAsset.browser_download_url)
            $resp = $req.GetResponse(); $tot = $resp.ContentLength
            $stm  = $resp.GetResponseStream()
            $fs   = [System.IO.File]::Create($msixPath)
            $tr   = 0
            while (($r = $stm.Read($buf, 0, $buf.Length)) -gt 0) {
                $fs.Write($buf, 0, $r); $tr += $r
                if ($tot -gt 0) { SP ([math]::Round(40 + ($tr / $tot) * 48)) "Download dell'app…" }
            }
            $fs.Close(); $stm.Close(); $resp.Close()

            SP 90 "Installazione del certificato…"
            $cert  = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cerPath)
            $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("TrustedPeople", "LocalMachine")
            $store.Open("ReadWrite"); $store.Add($cert); $store.Close()

            SP 95 "Installazione dell'app…"
            Add-AppxPackage -Path $msixPath

            if ($cfg.Desktop) {
                SP 98 "Creazione collegamento sul desktop…"
                $lnk = [System.IO.Path]::Combine([System.Environment]::GetFolderPath("Desktop"), "Importa Foto.lnk")
                $wsh = New-Object -ComObject WScript.Shell
                $sc  = $wsh.CreateShortcut($lnk)
                $sc.TargetPath = "shell:AppsFolder\$($cfg.AppUMID)"
                $sc.Save()
            }

            Remove-Item -Path $cfg.TempDir -Recurse -Force -ErrorAction SilentlyContinue

            SP 100 ""
            $s.Done = $true

        } catch {
            $s.ErrMsg = $_.Exception.Message
            $s.Error  = $true
        }
    })

    $null = $ps.BeginInvoke()
})

$window.ShowDialog() | Out-Null
