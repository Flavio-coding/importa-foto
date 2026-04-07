# installer.ps1 - ImportaFoto Installer
# Eseguire come Amministratore in PowerShell

$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host ""
    Write-Host "  ATTENZIONE: Esegui PowerShell come Amministratore." -ForegroundColor Yellow
    Write-Host "    1. Chiudi questa finestra" -ForegroundColor DarkGray
    Write-Host "    2. Cerca PowerShell nel menu Start" -ForegroundColor DarkGray
    Write-Host "    3. Clic destro -> Esegui come amministratore" -ForegroundColor DarkGray
    Write-Host "    4. Incolla di nuovo il comando" -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "  Premi INVIO per chiudere"
    exit 1
}

try {
    $accentDword = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent" -Name "AccentColorMenu").AccentColorMenu
    $b = ($accentDword -shr 16) -band 0xFF
    $g = ($accentDword -shr 8)  -band 0xFF
    $r = ($accentDword)          -band 0xFF
    $AccentHex = "#{0:X2}{1:X2}{2:X2}" -f $r, $g, $b
} catch { $AccentHex = "#0067C0" }

$GitHubUser        = "Flavio-coding"
$GitHubRepo        = "importa-foto"
$AppName           = "ImportaFoto"
$TempDir           = "$env:TEMP\$AppName-install"
$PackageFamilyName = "f3aa30ca-c500-4208-98c5-158f4f2d184a_tex0e22xxpf6g"
$AppUserModelId    = "$PackageFamilyName!App"

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Importa Foto - Installer"
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
            <Setter Property="Width" Value="200"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="22">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bd" Property="Opacity" Value="0.85"/></Trigger>
                            <Trigger Property="IsPressed" Value="True"><Setter TargetName="bd" Property="Opacity" Value="0.70"/></Trigger>
                            <Trigger Property="IsEnabled" Value="False"><Setter TargetName="bd" Property="Opacity" Value="0.5"/></Trigger>
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
        <StackPanel Grid.Row="1" HorizontalAlignment="Center" Width="420">
            <TextBlock x:Name="TxtTitolo"
                       Text="Clicca per installare Importa Foto"
                       FontSize="22" FontWeight="SemiBold" Foreground="#1C1C1C"
                       TextAlignment="Center" TextWrapping="Wrap"
                       Height="64" VerticalAlignment="Center"/>
            <Grid Height="44">
                <Button x:Name="BtnInstalla" Content="Installa"
                        Style="{StaticResource AccentBtn}" HorizontalAlignment="Center"/>
                <Grid x:Name="GridProgresso" Visibility="Collapsed" VerticalAlignment="Center" Margin="12,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock x:Name="TxtPerc" Grid.Column="0" Text="0%"
                               FontSize="12" Foreground="#555555" VerticalAlignment="Center" Margin="0,0,10,0"/>
                    <ProgressBar x:Name="Barra" Grid.Column="1"
                                 Minimum="0" Maximum="100" Value="0" Height="3" VerticalAlignment="Center"/>
                </Grid>
            </Grid>
            <TextBlock x:Name="TxtStato" Text="" FontSize="11" Foreground="#888888"
                       TextAlignment="Center" TextTrimming="CharacterEllipsis" MaxWidth="400" Margin="0,8,0,0"/>
        </StackPanel>
        <CheckBox x:Name="ChkDesktop" Grid.Row="2"
                  Content="Crea un collegamento sul Desktop"
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
$TxtStato      = $window.FindName("TxtStato")
$ChkDesktop    = $window.FindName("ChkDesktop")

$BtnInstalla.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)
$Barra.Foreground       = [System.Windows.Media.BrushConverter]::new().ConvertFromString($AccentHex)

$BtnInstalla.Add_Click({
    $BtnInstalla.IsEnabled = $false
    $desktop = $ChkDesktop.IsChecked

    $BtnInstalla.Visibility   = [System.Windows.Visibility]::Collapsed
    $ChkDesktop.Visibility    = [System.Windows.Visibility]::Collapsed
    $GridProgresso.Visibility = [System.Windows.Visibility]::Visible
    $TxtTitolo.Text           = "Installazione in corso..."

    $disp        = $window.Dispatcher
    $barraRef    = $Barra
    $percRef     = $TxtPerc
    $statoRef    = $TxtStato
    $titoloRef   = $TxtTitolo
    $progRef     = $GridProgresso
    $gh_user     = $GitHubUser
    $gh_repo     = $GitHubRepo
    $tmpDir      = $TempDir
    $pfn         = $PackageFamilyName
    $aumid       = $AppUserModelId

    $thread = [System.Threading.Thread]::new([System.Threading.ThreadStart]{
        function ui([scriptblock]$sb) { $disp.Invoke([Action]$sb) }
        try {
            ui { $statoRef.Text = "Abilitazione modalita sviluppatore..." }
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
            if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
            Set-ItemProperty -Path $regPath -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force

            ui { $barraRef.Value = 5; $percRef.Text = "5%"; $statoRef.Text = "Contatto GitHub..." }
            $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$gh_user/$gh_repo/releases/latest" -Headers @{ "User-Agent" = "InstallScript" }
            $msixAsset = $release.assets | Where-Object { $_.name -like "*.msix" } | Select-Object -First 1
            $cerAsset  = $release.assets | Where-Object { $_.name -like "*.cer"  } | Select-Object -First 1
            if (-not $msixAsset -or -not $cerAsset) { throw "Asset non trovati nella release." }

            New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
            $cerPath  = Join-Path $tmpDir $cerAsset.name
            $msixPath = Join-Path $tmpDir $msixAsset.name
            $buf      = New-Object byte[] 65536

            ui { $statoRef.Text = "Download certificato..." }
            $req = [System.Net.HttpWebRequest]::Create([System.Uri]$cerAsset.browser_download_url)
            $resp = $req.GetResponse(); $tot = $resp.ContentLength
            $stm = $resp.GetResponseStream(); $fs = [System.IO.File]::Create($cerPath); $tr = 0
            while (($r = $stm.Read($buf,0,$buf.Length)) -gt 0) {
                $fs.Write($buf,0,$r); $tr += $r
                if ($tot -gt 0) { $p = [math]::Round(5 + $tr/$tot*30); ui { $barraRef.Value=$p; $percRef.Text="$p%" } }
            }
            $fs.Close(); $stm.Close(); $resp.Close()

            ui { $statoRef.Text = "Download pacchetto..." }
            $req = [System.Net.HttpWebRequest]::Create([System.Uri]$msixAsset.browser_download_url)
            $resp = $req.GetResponse(); $tot = $resp.ContentLength
            $stm = $resp.GetResponseStream(); $fs = [System.IO.File]::Create($msixPath); $tr = 0
            while (($r = $stm.Read($buf,0,$buf.Length)) -gt 0) {
                $fs.Write($buf,0,$r); $tr += $r
                if ($tot -gt 0) { $p = [math]::Round(35 + $tr/$tot*50); ui { $barraRef.Value=$p; $percRef.Text="$p%" } }
            }
            $fs.Close(); $stm.Close(); $resp.Close()

            ui { $barraRef.Value=88; $percRef.Text="88%"; $statoRef.Text="Installazione certificato..." }
            $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cerPath)
            $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("TrustedPeople","LocalMachine")
            $store.Open("ReadWrite"); $store.Add($cert); $store.Close()

            ui { $barraRef.Value=93; $percRef.Text="93%"; $statoRef.Text="Installazione app..." }
            Add-AppxPackage -Path $msixPath

            if ($desktop) {
                $lnk = [System.IO.Path]::Combine([System.Environment]::GetFolderPath("Desktop"),"Importa Foto.lnk")
                $wsh = New-Object -ComObject WScript.Shell
                $sc  = $wsh.CreateShortcut($lnk)
                $sc.TargetPath = "shell:AppsFolder\$aumid"
                $sc.Save()
            }

            Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

            ui {
                $barraRef.Value=100; $percRef.Text="100%"
                $progRef.Visibility=[System.Windows.Visibility]::Collapsed
                $statoRef.Text=""
                $titoloRef.Text="Fatto!`nPuoi chiudere questa finestra"
            }
        } catch {
            $err = $_.Exception.Message
            ui {
                $progRef.Visibility=[System.Windows.Visibility]::Collapsed
                $titoloRef.Text="Errore durante l'installazione"
                $statoRef.Text=$err
            }
        }
    })
    $thread.IsBackground  = $true
    $thread.ApartmentState = [System.Threading.ApartmentState]::STA
    $thread.Start()
})

$window.ShowDialog() | Out-Null
