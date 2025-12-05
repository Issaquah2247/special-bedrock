# ==========================================
# Special Bedrock - Production Installer
# One-Line Install: irm https://raw.githubusercontent.com/Issaquah2247/special-bedrock/main/install.ps1 | iex
# ==========================================

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# Configuration
$REPO_URL = "https://github.com/Issaquah2247/special-bedrock.git"
$INSTALL_DIR = "$env:USERPROFILE\special-bedrock"
$STATE_FILE = "$INSTALL_DIR\.state.json"
$VERSION_URL = "https://raw.githubusercontent.com/Issaquah2247/special-bedrock/main/version.json"
$APP_NAME = "Special Bedrock"

function Show-Banner {
    Clear-Host
    Write-Host "`n" -ForegroundColor Black
    Write-Host "  " -BackgroundColor White -NoNewline
    Write-Host "  $APP_NAME Installer  " -ForegroundColor Black -BackgroundColor White
    Write-Host "  " -BackgroundColor White
    Write-Host "`n"
}

function Save-State {
    param($State)
    $State | ConvertTo-Json | Out-File $STATE_FILE -Force
}

function Load-State {
    if (Test-Path $STATE_FILE) {
        return Get-Content $STATE_FILE | ConvertFrom-Json
    }
    return @{
        installed = $false
        version = "0.0.0"
        nodejs_installed = $false
        git_installed = $false
        pkg_installed = $false
        exe_built = $false
        shortcuts_created = $false
    }
}

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-Chocolatey {
    Write-Host "[1/8] Installing Chocolatey..." -ForegroundColor Cyan
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "      DONE" -ForegroundColor Green
}

function Install-NodeJS {
    param($State)
    if ($State.nodejs_installed) {
        Write-Host "[2/8] Node.js already installed" -ForegroundColor Green
        return $State
    }
    
    Write-Host "[2/8] Installing Node.js LTS..." -ForegroundColor Cyan
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Install-Chocolatey
    }
    choco install nodejs-lts -y | Out-Null
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    $State.nodejs_installed = $true
    Save-State $State
    Write-Host "      DONE" -ForegroundColor Green
    return $State
}

function Install-Git {
    param($State)
    if ($State.git_installed) {
        Write-Host "[3/8] Git already installed" -ForegroundColor Green
        return $State
    }
    
    Write-Host "[3/8] Installing Git..." -ForegroundColor Cyan
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Install-Chocolatey
    }
    choco install git -y | Out-Null
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    $State.git_installed = $true
    Save-State $State
    Write-Host "      DONE" -ForegroundColor Green
    return $State
}

function Install-Repository {
    Write-Host "[4/8] Setting up repository..." -ForegroundColor Cyan
    if (Test-Path $INSTALL_DIR) {
        cd $INSTALL_DIR
        git pull origin main | Out-Null
    } else {
        git clone $REPO_URL $INSTALL_DIR | Out-Null
        cd $INSTALL_DIR
    }
    Write-Host "      DONE" -ForegroundColor Green
}

function Install-Dependencies {
    Write-Host "[5/8] Installing dependencies..." -ForegroundColor Cyan
    cd $INSTALL_DIR
    npm install --silent | Out-Null
    Write-Host "      DONE" -ForegroundColor Green
}

function Install-PKG {
    param($State)
    if ($State.pkg_installed) {
        Write-Host "[6/8] PKG already installed" -ForegroundColor Green
        return $State
    }
    
    Write-Host "[6/8] Installing PKG..." -ForegroundColor Cyan
    npm install -g pkg --silent | Out-Null
    $State.pkg_installed = $true
    Save-State $State
    Write-Host "      DONE" -ForegroundColor Green
    return $State
}

function Build-Executable {
    param($State)
    if ($State.exe_built -and (Test-Path "$INSTALL_DIR\SpecialBedrock.exe")) {
        Write-Host "[7/8] EXE already built" -ForegroundColor Green
        return $State
    }
    
    Write-Host "[7/8] Building executable..." -ForegroundColor Cyan
    cd $INSTALL_DIR
    pkg server/index.js --targets node18-win-x64 --output SpecialBedrock.exe 2>&1 | Out-Null
    $State.exe_built = $true
    Save-State $State
    Write-Host "      DONE" -ForegroundColor Green
    return $State
}

function Create-Shortcuts {
    param($State)
    if ($State.shortcuts_created) {
        Write-Host "[8/8] Shortcuts already created" -ForegroundColor Green
        return $State
    }
    
    Write-Host "[8/8] Creating shortcuts..." -ForegroundColor Cyan
    $WshShell = New-Object -comObject WScript.Shell
    
    # Desktop shortcut
    $DesktopShortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\$APP_NAME.lnk")
    $DesktopShortcut.TargetPath = "powershell.exe"
    $DesktopShortcut.Arguments = "-WindowStyle Hidden -File `"$INSTALL_DIR\launcher.ps1`""
    $DesktopShortcut.WorkingDirectory = $INSTALL_DIR
    $DesktopShortcut.IconLocation = "$INSTALL_DIR\SpecialBedrock.exe,0"
    $DesktopShortcut.Description = "$APP_NAME - Minecraft Bedrock Proxy"
    $DesktopShortcut.Save()
    
    # Start Menu shortcut
    $StartMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
    $StartShortcut = $WshShell.CreateShortcut("$StartMenuPath\$APP_NAME.lnk")
    $StartShortcut.TargetPath = "powershell.exe"
    $StartShortcut.Arguments = "-WindowStyle Hidden -File `"$INSTALL_DIR\launcher.ps1`""
    $StartShortcut.WorkingDirectory = $INSTALL_DIR
    $StartShortcut.IconLocation = "$INSTALL_DIR\SpecialBedrock.exe,0"
    $StartShortcut.Description = "$APP_NAME - Minecraft Bedrock Proxy"
    $StartShortcut.Save()
    
    $State.shortcuts_created = $true
    Save-State $State
    Write-Host "      DONE" -ForegroundColor Green
    return $State
}

function Show-Splash {
    Add-Type -AssemblyName System.Windows.Forms
    $splash = New-Object System.Windows.Forms.Form
    $splash.Text = ""
    $splash.Width = 400
    $splash.Height = 200
    $splash.BackColor = [System.Drawing.Color]::Black
    $splash.FormBorderStyle = 'None'
    $splash.StartPosition = 'CenterScreen'
    $splash.TopMost = $true
    
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "COMPLETED"
    $label.Font = New-Object System.Drawing.Font("Arial", 32, [System.Drawing.FontStyle]::Bold)
    $label.ForeColor = [System.Drawing.Color]::White
    $label.AutoSize = $true
    $label.Left = ($splash.Width - 250) / 2
    $label.Top = ($splash.Height - 50) / 2
    $splash.Controls.Add($label)
    
    $splash.Show()
    Start-Sleep -Seconds 2
    $splash.Close()
}

function Start-Application {
    Write-Host "`n"
    Write-Host "Starting $APP_NAME..." -ForegroundColor Green
    Start-Process "$INSTALL_DIR\SpecialBedrock.exe" -WindowStyle Hidden
    Start-Sleep -Seconds 2
    Start-Process "http://localhost:3000"
}

# Main Installation Flow
try {
    Show-Banner
    
    if (-not (Test-Admin)) {
        Write-Host "ERROR: This installer requires Administrator privileges" -ForegroundColor Red
        Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
        pause
        exit 1
    }
    
    $State = Load-State
    
    Write-Host "Installing $APP_NAME...`n" -ForegroundColor White
    
    $State = Install-NodeJS $State
    $State = Install-Git $State
    Install-Repository
    Install-Dependencies
    $State = Install-PKG $State
    $State = Build-Executable $State
    $State = Create-Shortcuts $State
    
    $State.installed = $true
    $State.version = "1.0.0"
    Save-State $State
    
    Write-Host "`n"
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "  INSTALLATION COMPLETE!" -ForegroundColor Green -BackgroundColor Black
    Write-Host "=========================================="  -ForegroundColor Green
    Write-Host "`n"
    
    Show-Splash
    Start-Application
    
} catch {
    Write-Host "`nERROR: Installation failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
