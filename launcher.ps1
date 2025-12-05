# Special Bedrock Launcher
# Checks for updates and launches the application

$INSTALL_DIR = "$env:USERPROFILE\special-bedrock"
$VERSION_URL = "https://raw.githubusercontent.com/Issaquah2247/special-bedrock/main/version.json"
$STATE_FILE = "$INSTALL_DIR\.state.json"

function Show-Splash {
    param($Text = "COMPLETED")
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
    $label.Text = $Text
    $label.Font = New-Object System.Drawing.Font("Arial", 32, [System.Drawing.FontStyle]::Bold)
    $label.ForeColor = [System.Drawing.Color]::White
    $label.AutoSize = $true
    $label.Left = ($splash.Width - 250) / 2
    $label.Top = ($splash.Height - 50) / 2
    $splash.Controls.Add($label)
    
    $splash.Show()
    $splash.Refresh()
    return $splash
}

function Check-Updates {
    try {
        $localVersion = "1.0.0"
        if (Test-Path $STATE_FILE) {
            $state = Get-Content $STATE_FILE | ConvertFrom-Json
            $localVersion = $state.version
        }
        
        $remoteVersion = (Invoke-WebRequest $VERSION_URL).Content | ConvertFrom-Json | Select -ExpandProperty version
        
        if ($remoteVersion -ne $localVersion) {
            return $true
        }
    } catch {
        # Silently fail if unable to check for updates
    }
    return $false
}

function Update-Application {
    $splash = Show-Splash "UPDATING..."
    
    cd $INSTALL_DIR
    git pull origin main | Out-Null
        & npm.cmd install --silent --no-audit --no-fund 2>$null | Out-Null
    pkg server/index.js --targets node18-win-x64 --output SpecialBedrock.exe 2>&1 | Out-Null
    
    $splash.Close()

# Main launcher logic
try {
    # Check for updates
    if (Check-Updates) {
        Update-Application
    } else {
        $splash = Show-Splash
        Start-Sleep -Milliseconds 1500
        $splash.Close()
    }
    
    # Start the application
    Start-Process "$INSTALL_DIR\SpecialBedrock.exe" -WindowStyle Hidden
    Start-Sleep -Seconds 2
    Start-Process "http://localhost:3000"
    
} catch {
    [System.Windows.Forms.MessageBox]::Show("Failed to start Special Bedrock: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
}
