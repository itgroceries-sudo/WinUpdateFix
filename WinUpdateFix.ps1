<# : hybrid batch + powershell script
@echo off
chcp 65001 >nul
mode con: cols=85 lines=9999
title The Ultimate Fix for a Forced Windows Update

:: Auto-Admin Elevation
powershell -noprofile -c "$param='%*';$ScriptPath='%~f0';iex((Get-Content('%~f0') -Raw))"
exit /b
#>

# =========================================================
#  THE ULTIMATE FIX FOR A FORCED WINDOWS UPDATE
#  Version: 1.3 Build 26.02.2026
#  Framework: IT Groceries Shop (Layout Master)
# =========================================================

# [0] Force TLS 1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# ---------------------------------------------------------
# [1] CONFIG & LANGUAGE
# ---------------------------------------------------------
$AppVersion = "1.3 Build 26.02.2026"
$InstallDir = "$env:LOCALAPPDATA\ITG_WinUpdateFix"
$TempScript = "$env:TEMP\WinUpFix_Temp.ps1"
$SelfURL    = "https://raw.githubusercontent.com/itgroceries-sudo/WinUpdateFix/main/WinUpdateFix.ps1"
$TargetFile = if ($ScriptPath) { $ScriptPath } elseif ($PSScriptRoot) { $PSCommandPath } else { $null }

function Write-SafeTempScript {
    param([string]$FilePath, [string]$Content)
    [System.IO.File]::WriteAllText($FilePath, $Content, (New-Object System.Text.UTF8Encoding($True)))
}

$LangDict = @{
    "EN" = @{ 
        "Title"="WinUpdate Menu Fixer"; "Dev"="Developed by IT Groceries Shop ♥ ♥ ♥"; 
        "Facebook"="Facebook"; "GitHub"="GitHub"; "About"="About"; "Exit"="EXIT"; 
        "Processing"="Applying..."; "Finished"="Finished"; "Start"="Apply Fix";
        "LangLabel"="Language" 
    }
    "TH" = @{ 
        "Title"="แก้เมนูบังคับอัปเดต"; "Dev"="พัฒนาโดย IT Groceries Shop ♥ ♥ ♥"; 
        "Facebook"="Facebook"; "GitHub"="GitHub"; "About"="เกี่ยวกับ"; "Exit"="ออก"; 
        "Processing"="กำลังตั้งค่า..."; "Finished"="เสร็จสิ้น"; "Start"="ยืนยันการตั้งค่า";
        "LangLabel"="ภาษา" 
    }
}

$Global:UpdateModes = @(
    @{ Hex="0"; DescEN="0 = Normal Behavior"; DescTH="0 = โหมดปกติ (มีปุ่ม Shutdown/Restart)" }
    @{ Hex="3"; DescEN="3 = Update and Restart"; DescTH="3 = บังคับอัปเดต และ รีสตาร์ท" }
    @{ Hex="8"; DescEN="8 = Update and Shutdown"; DescTH="8 = บังคับอัปเดต และ ปิดเครื่อง" }
    @{ Hex="a"; DescEN="a = Upd & Shut, Upd & Rest"; DescTH="a = อัปเดตและปิดเครื่อง, อัปเดตและรีส" }
    @{ Hex="b"; DescEN="b = Upd & Shut, Upd & Rest, Rest"; DescTH="b = อัปเดตและปิด, อัปเดตและรีส, รีสปกติ" }
    @{ Hex="c"; DescEN="c = Upd & Shut, Rest, Shut"; DescTH="c = อัปเดตและปิด, รีสตาร์ทปกติ, ปิดปกติ" }
    @{ Hex="e"; DescEN="e = Upd & Shut, Upd & Rest, Shut"; DescTH="e = อัปเดตและปิด, อัปเดตและรีส, ปิดปกติ" }
    @{ Hex="f"; DescEN="f = All Available Options"; DescTH="f = แสดงตัวเลือกทั้งหมดแบบจัดเต็ม" }
)

$SysRegion = (Get-Culture).TwoLetterISOLanguageName
$script:CurrentLang = if ($SysRegion -eq "th") { "TH" } else { "EN" }

$Silent = $false
$AllArgs = @(); if ($args) { $AllArgs += $args }; if ($param) { $AllArgs += $param.Split(" ") }
for ($i = 0; $i -lt $AllArgs.Count; $i++) { if ($AllArgs[$i] -eq "-Silent") { $Silent = $true } }

# ---------------------------------------------------------
# [2] API IMPORTS
# ---------------------------------------------------------
try {
    $User32 = Add-Type -MemberDefinition '[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow(); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow); [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags); [DllImport("user32.dll")] public static extern IntPtr LoadImage(IntPtr hinst, string lpszName, uint uType, int cxDesired, int cyDesired, uint fuLoad); [DllImport("user32.dll")] public static extern int SendMessage(IntPtr hWnd, int msg, int wParam, IntPtr lParam);' -Name "User32" -Namespace Win32 -PassThru
    $ConsoleHandle = [Win32.User32]::GetConsoleWindow()
} catch {}

# ---------------------------------------------------------
# [3] ELEVATION & IN-MEMORY DOWNLOAD LOGIC
# ---------------------------------------------------------
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = [Security.Principal.WindowsPrincipal]$Identity
$IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $Silent -and -not $IsAdmin) {
    if ($ConsoleHandle) { [Win32.User32]::ShowWindow($ConsoleHandle, 5) | Out-Null }
    try { $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(85, 20) } catch {} 

    $host.UI.RawUI.BackgroundColor = "DarkBlue"; $host.UI.RawUI.ForegroundColor = "White"; Clear-Host
    Write-Host "`n====================================================================================" -ForegroundColor DarkGray
    Write-Host "                    WinUpdate Menu Fixer [ Cloud Edition ]                          " -ForegroundColor Cyan -BackgroundColor DarkBlue
    Write-Host "                         Powered by IT Groceries Shop                               " -ForegroundColor DarkCyan -BackgroundColor DarkBlue
    Write-Host "====================================================================================" -ForegroundColor DarkGray
    Write-Host ""; Write-Host "         [ PERMISSION CHECK ] Press Enter, then click 'Yes' to continue: " -NoNewline -ForegroundColor White
    $null = Read-Host
    
    $ArgStr = ""
    try {
        if ($TargetFile -and (Test-Path $TargetFile)) {
            if ($TargetFile -match '\.(cmd|bat)$') { Start-Process -FilePath "$TargetFile" -Verb RunAs }
            else { Start-Process "powershell" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$TargetFile`"" -Verb RunAs }
        } else {
            Write-Host "`n [INFO] Memory Execution Detected. Downloading with BOM to disk..." -ForegroundColor Yellow
            $WebClient = New-Object System.Net.WebClient; $WebClient.Encoding = [System.Text.Encoding]::UTF8
            $ScriptContent = $WebClient.DownloadString($SelfURL)
            $Utf8WithBom = New-Object System.Text.UTF8Encoding $True
            [System.IO.File]::WriteAllText($TempScript, $ScriptContent, $Utf8WithBom)
            Start-Process "powershell" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$TempScript`"" -Verb RunAs
        }
    } catch { Write-Host "`n [ERROR] Failed to elevate: $_" -ForegroundColor Red; Read-Host }
    exit 
}

# ---------------------------------------------------------
# [4] GUI PREP & CONSOLE LAYOUT
# ---------------------------------------------------------
Add-Type -AssemblyName PresentationFramework, System.Windows.Forms, System.Drawing
$Graphics = [System.Drawing.Graphics]::FromHwnd([IntPtr]::Zero); $Scale = $Graphics.DpiX / 96.0; $Graphics.Dispose()

$BaseW = 600; $BaseH = 800 
$ConsoleW_Px = [int]($BaseW * $Scale); $ConsoleH_Px = [int]($BaseH * $Scale)
$Scr = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

$TotalWidth_Px = $ConsoleW_Px * 2; $StartX_Px = ($Scr.Width - $TotalWidth_Px) / 2; $StartY_Px = ($Scr.Height - $ConsoleH_Px) / 2
$WindowX_WPF = ($StartX_Px + $ConsoleW_Px) / $Scale; $WindowY_WPF = $StartY_Px / $Scale

if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null }

$ConsoleIcon = "$InstallDir\ConsoleIcon.ico"
if (-not (Test-Path $ConsoleIcon) -or (Get-Item $ConsoleIcon).Length -lt 100) {
    try { (New-Object Net.WebClient).DownloadFile("https://itgroceries.blogspot.com/favicon.ico", $ConsoleIcon) } catch {}
}

if ($Silent) { if ($ConsoleHandle) { [Win32.User32]::ShowWindow($ConsoleHandle, 0) | Out-Null } } else {
    try { $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(120, 9999) } catch {}
    if ($ConsoleHandle) { 
        [Win32.User32]::ShowWindow($ConsoleHandle, 5) | Out-Null
        [Win32.User32]::SetWindowPos($ConsoleHandle, [IntPtr]0, [int]$StartX_Px, [int]$StartY_Px, [int]$ConsoleW_Px, [int]$ConsoleH_Px, 0x0040) | Out-Null
        
        if (Test-Path $ConsoleIcon) {
            $h = [Win32.User32]::LoadImage([IntPtr]::Zero, $ConsoleIcon, 1, 0, 0, 0x10)
            if ($h) {
                [Win32.User32]::SendMessage($ConsoleHandle, 0x80, [IntPtr]0, $h) | Out-Null
                [Win32.User32]::SendMessage($ConsoleHandle, 0x80, [IntPtr]1, $h) | Out-Null
            }
        }
    }
}

if (!$Silent) {
    $host.UI.RawUI.BackgroundColor = "Black"; $host.UI.RawUI.ForegroundColor = "Gray"; Clear-Host
    Write-Host "`n==========================================" -ForegroundColor Green
    Write-Host "   (V.1.3 Build 26.02.2026 : INIT)      " -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host " [INFO] Loading Modules and checking keys..." -ForegroundColor Green
}

function Play-Sound($Type) { try { switch ($Type) { "Click" { [System.Media.SystemSounds]::Beep.Play() } "Tick" { [System.Console]::Beep(2000, 20) } "Warn" { [System.Media.SystemSounds]::Hand.Play() } "Done" { [System.Media.SystemSounds]::Asterisk.Play() } } } catch {} }

# ---------------------------------------------------------
# [5] XAML UI
# ---------------------------------------------------------
try {
    if(!$Silent){ Write-Host " [INFO] Launching WPF GUI..." -ForegroundColor Yellow }

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
Title="WinUpdate Fixer" Height="$BaseH" Width="$BaseW" WindowStartupLocation="Manual" ResizeMode="NoResize" Background="#181818" WindowStyle="None" BorderBrush="#2196F3" BorderThickness="2">
    <Window.Resources>
        <Style x:Key="BlueSwitch" TargetType="{x:Type CheckBox}">
            <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="{x:Type CheckBox}"><Border x:Name="T" Width="44" Height="24" Background="#3E3E3E" CornerRadius="22" Cursor="Hand"><Border x:Name="D" Width="20" Height="20" Background="White" CornerRadius="20" HorizontalAlignment="Left" Margin="2,0,0,0"><Border.RenderTransform><TranslateTransform x:Name="Tr" X="0"/></Border.RenderTransform></Border></Border><ControlTemplate.Triggers><Trigger Property="IsChecked" Value="True"><Trigger.EnterActions><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetName="Tr" Storyboard.TargetProperty="X" To="20" Duration="0:0:0.2"/><ColorAnimation Storyboard.TargetName="T" Storyboard.TargetProperty="Background.Color" To="#2196F3" Duration="0:0:0.2"/></Storyboard></BeginStoryboard></Trigger.EnterActions><Trigger.ExitActions><BeginStoryboard><Storyboard><DoubleAnimation Storyboard.TargetName="Tr" Storyboard.TargetProperty="X" To="0" Duration="0:0:0.2"/><ColorAnimation Storyboard.TargetName="T" Storyboard.TargetProperty="Background.Color" To="#3E3E3E" Duration="0:0:0.2"/></Storyboard></BeginStoryboard></Trigger.ExitActions></Trigger><Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.5"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
        </Style>
        <Style x:Key="Btn" TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="b" Background="{TemplateBinding Background}" CornerRadius="22"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" TextElement.FontWeight="Bold"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.8"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
        <Style x:Key="LabeledBtn" TargetType="Button"><Setter Property="Background" Value="#333333"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/><Setter Property="Height" Value="50"/><Setter Property="Margin" Value="0,0,5,0"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="b" Background="{TemplateBinding Background}" CornerRadius="5" Padding="15,0,15,0"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" TextElement.FontWeight="Bold" TextElement.FontSize="16"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.8"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
    </Window.Resources>
    
    <Grid Margin="25">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="20"/><RowDefinition Height="*"/><RowDefinition Height="80"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <Grid Grid.Row="0">
            <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <Viewbox Grid.Column="0" Width="70" Height="70" Margin="0,0,15,0">
                <Path Fill="#2196F3" Data="M19.43 12.98c.04-.32.07-.64.07-.98s-.03-.66-.07-.98l2.11-1.65c.19-.15.24-.42.12-.64l-2-3.46c-.12-.22-.39-.3-.61-.22l-2.49 1c-.52-.4-1.08-.73-1.69-.98l-.38-2.65C14.46 2.18 14.25 2 14 2h-4c-.25 0-.46.18-.49.42l-.38 2.65c-.61.25-1.17.59-1.69.98l-2.49-1c-.23-.09-.49 0-.61.22l-2 3.46c-.13.22-.07-.49-.12-.64l2.11 1.65c-.04.32-.07.65-.07.98s.03.66.07.98l-2.11 1.65c-.19.15-.24.42-.12.64l2 3.46c.12.22.39.3.61.22l2.49-1c.52.4 1.08.73 1.69.98l.38 2.65c.03.24.24.42.49.42h4c.25 0 .46-.18.49-.42l.38-2.65c.61-.25 1.17-.59 1.69-.98l2.49 1c.23.09.49 0 .61-.22l2-3.46c.12-.22.07-.49-.12-.64l-2.11-1.65zM12 15.5c-1.93 0-3.5-1.57-3.5-3.5s1.57-3.5 3.5-3.5 3.5 1.57 3.5 3.5-1.57 3.5-3.5 3.5z"/>
            </Viewbox>
            <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="5,0,0,0">
                <TextBlock x:Name="T_Title" Text="WinUpdate Menu Fixer" Foreground="White" FontSize="28" FontWeight="Bold">
                    <TextBlock.Effect><DropShadowEffect Color="#2196F3" BlurRadius="15" Opacity="0.6"/></TextBlock.Effect>
                </TextBlock>
                <StackPanel Orientation="Horizontal" Margin="2,5,0,0">
                    <TextBlock x:Name="T_Dev" Text="Developed by IT Groceries Shop" Foreground="#2196F3" FontSize="14" FontWeight="Bold"/>
                </StackPanel>
            </StackPanel>
            <StackPanel Grid.Column="2" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,10,0,0">
                <Button x:Name="BCredit" Style="{StaticResource LabeledBtn}" Height="35" Background="#CC0000" Padding="10,0,10,0">
                    <StackPanel Orientation="Horizontal">
                        <Viewbox Width="18" Height="18" Margin="0,0,6,0">
                            <Path Fill="White" Data="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
                        </Viewbox>
                        <TextBlock Text="Credit" Foreground="White" VerticalAlignment="Center" FontWeight="Bold" FontSize="14"/>
                    </StackPanel>
                </Button>
            </StackPanel>
        </Grid>
        
        <Border Grid.Row="2" Background="#1E1E1E" CornerRadius="5">
            <ScrollViewer VerticalScrollBarVisibility="Hidden"><StackPanel x:Name="List"/></ScrollViewer>
        </Border>
        
        <Grid Grid.Row="3" Margin="0,15,0,8">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                <Button x:Name="BA" Content="Apply Fix" Width="300" Height="55" Background="#2E7D32" Foreground="White" Style="{StaticResource Btn}" Margin="0,0,0,0" Cursor="Hand" FontSize="18"/>
            </StackPanel>
        </Grid>
        
        <Grid Grid.Row="4">
            <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <StackPanel Orientation="Horizontal" Grid.Column="0">
                 <Button x:Name="BF" Style="{StaticResource LabeledBtn}"><StackPanel Orientation="Horizontal"><TextBlock Text="f" Foreground="#1877F2" FontSize="28" FontWeight="Bold" Margin="0,-4,8,0" VerticalAlignment="Center"/><TextBlock x:Name="T_FB" Text="Facebook" Foreground="White" VerticalAlignment="Center"/></StackPanel></Button>
                 <Button x:Name="BG" Style="{StaticResource LabeledBtn}"><StackPanel Orientation="Horizontal"><Viewbox Width="26" Height="26" Margin="0,0,8,0"><Path Fill="White" Data="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.
