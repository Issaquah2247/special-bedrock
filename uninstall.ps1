# Special Bedrock Uninstaller
# One-Line Uninstall: irm https://raw.githubusercontent.com/Issaquah2247/special-bedrock/main/uninstall.ps1 | iex

$INSTALL_DIR = "$env:USERPROFILE\special-bedrock"
$APP_NAME = "Special Bedrock"

Write-Host "`n" -ForegroundColor Black
Write-Host "  " -BackgroundColor Red -NoNewline
Write-Host "  $APP_NAME Uninstaller  " -ForegroundColor White -BackgroundColor Red
Write-Host "  " -BackgroundColor Red
Write-Host "`n"

$confirm = Read-Host "Are you sure you want to completely remove $APP_NAME? (Y/N)"

if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Uninstall cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host "`nRemoving $APP_NAME...`n" -ForegroundColor Yellow

try {
    # Stop any running processes
    Write-Host "[1/5] Stopping running processes..." -ForegroundColor Cyan
    Get-Process | Where-Object {$_.Path -like "*special-bedrock*"} | Stop-Process -Force -ErrorAction SilentlyContinue
    Get-Process | Where-Object {$_.ProcessName -eq "SpecialBedrock"} | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "      DONE" -ForegroundColor Green
    
    # Remove shortcuts
    Write-Host "[2/5] Removing shortcuts..." -ForegroundColor Cyan
    
    $DesktopShortcut = "$env:USERPROFILE\Desktop\$APP_NAME.lnk"
    if (Test-Path $DesktopShortcut) {
        Remove-Item $DesktopShortcut -Force
    }
    
    $StartMenuShortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\$APP_NAME.lnk"
    if (Test-Path $StartMenuShortcut) {
        Remove-Item $StartMenuShortcut -Force
    }
    
    Write-Host "      DONE" -ForegroundColor Green
    
    # Remove installation directory
    Write-Host "[3/5] Removing installation files..." -ForegroundColor Cyan
    if (Test-Path $INSTALL_DIR) {
        Remove-Item $INSTALL_DIR -Recurse -Force
    }
    Write-Host "      DONE" -ForegroundColor Green
    
    # Remove firewall rules (if any)
    Write-Host "[4/5] Cleaning up firewall rules..." -ForegroundColor Cyan
    netsh advfirewall firewall delete rule name="Special Bedrock" 2>&1 | Out-Null
    Write-Host "      DONE" -ForegroundColor Green
    
    # Clean up any remaining traces
    Write-Host "[5/5] Removing remaining traces..." -ForegroundColor Cyan
    
    # Remove from Windows Registry (if we added anything)
    $regPath = "HKCU:\Software\SpecialBedrock"
    if (Test-Path $regPath) {
        Remove-Item $regPath -Recurse -Force
    }
    
    Write-Host "      DONE" -ForegroundColor Green
    
    Write-Host "`n" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "  UNINSTALL COMPLETE!" -ForegroundColor Green -BackgroundColor Black
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "`n"
    Write-Host "$APP_NAME has been completely removed from your system." -ForegroundColor White
    Write-Host "`n"
    Write-Host "To reinstall, run:" -ForegroundColor Yellow
    Write-Host "irm https://raw.githubusercontent.com/Issaquah2247/special-bedrock/main/install.ps1 | iex" -ForegroundColor Cyan
    Write-Host "`n"
    
} catch {
    Write-Host "`nERROR: Uninstall failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "`nSome files may need to be removed manually from:" -ForegroundColor Yellow
    Write-Host $INSTALL_DIR -ForegroundColor White
    exit 1
}

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
