# Special Bedrock One-Line Installer for Windows 11
# Run this in PowerShell as Administrator:
# irm https://raw.githubusercontent.com/Issaquah2247/special-bedrock/main/install.ps1 | iex

Write-Host "🎮 Special Bedrock Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "⚠️  This script requires Administrator privileges!" -ForegroundColor Yellow
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

# Check if Node.js is installed
Write-Host "✓ Checking for Node.js..." -ForegroundColor Green
$nodeInstalled = Get-Command node -ErrorAction SilentlyContinue

if (-not $nodeInstalled) {
    Write-Host "Node.js not found. Installing Node.js LTS..." -ForegroundColor Yellow
    
    # Install Chocolatey if not installed
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Chocolatey package manager..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
    
    # Install Node.js
    choco install nodejs-lts -y
    
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "✓ Node.js installed successfully!" -ForegroundColor Green
} else {
    Write-Host "✓ Node.js already installed" -ForegroundColor Green
}

# Check if Git is installed
Write-Host "✓ Checking for Git..." -ForegroundColor Green
$gitInstalled = Get-Command git -ErrorAction SilentlyContinue

if (-not $gitInstalled) {
    Write-Host "Git not found. Installing Git..." -ForegroundColor Yellow
    choco install git -y
    
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "✓ Git installed successfully!" -ForegroundColor Green
} else {
    Write-Host "✓ Git already installed" -ForegroundColor Green
}

# Create installation directory
$installDir = "$env:USERPROFILE\special-bedrock"
Write-Host ""
Write-Host "Installing to: $installDir" -ForegroundColor Cyan

# Clone repository
if (Test-Path $installDir) {
    Write-Host "Existing installation found. Updating..." -ForegroundColor Yellow
    cd $installDir
    git pull
} else {
    Write-Host "Cloning Special Bedrock repository..." -ForegroundColor Yellow
    git clone https://github.com/Issaquah2247/special-bedrock.git $installDir
    cd $installDir
}

# Install dependencies
Write-Host ""
Write-Host "✓ Installing dependencies..." -ForegroundColor Green
npm install

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To start Special Bedrock:" -ForegroundColor Yellow
Write-Host "1. cd $installDir" -ForegroundColor White
Write-Host "2. npm start" -ForegroundColor White
Write-Host ""
Write-Host "Or create a desktop shortcut with this script!" -ForegroundColor Yellow
Write-Host ""

# Ask if user wants to create desktop shortcut
$createShortcut = Read-Host "Create desktop shortcut? (Y/N)"
if ($createShortcut -eq "Y" -or $createShortcut -eq "y") {
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Special Bedrock.lnk")
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-NoExit -Command `"cd '$installDir'; npm start`""
    $Shortcut.WorkingDirectory = $installDir
    $Shortcut.IconLocation = "powershell.exe,0"
    $Shortcut.Description = "Special Bedrock Minecraft Proxy"
    $Shortcut.Save()
    
    Write-Host "✓ Desktop shortcut created!" -ForegroundColor Green
}

Write-Host ""
$startNow = Read-Host "Start Special Bedrock now? (Y/N)"
if ($startNow -eq "Y" -or $startNow -eq "y") {
    Write-Host ""
    Write-Host "Starting Special Bedrock..." -ForegroundColor Green
    Write-Host "Open http://localhost:3000 in your browser" -ForegroundColor Cyan
    Write-Host ""
    npm start
}
