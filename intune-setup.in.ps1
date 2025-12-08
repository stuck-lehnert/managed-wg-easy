$wireguardInstallerUrl = "https://download.wireguard.com/windows-client/wireguard-installer.exe"
$configUrl = "https://{{SERVICE_FQDN}}/registration/issue.php?token={{REGISTRATION_TOKEN}}&pcname=$([System.Environment]::MachineName)"
$configPath = "C:\Program Files\WireGuard\Config\{{SERVICE_FQDN}}.conf"
$configDir = Split-Path $configPath

function Is-WireGuardInstalled {
    $wgPath = "C:\Program Files\WireGuard\WireGuard.exe"
    return Test-Path $wgPath
}

if (-not (Is-WireGuardInstalled)) {
    Write-Output "WireGuard not found. Downloading and installing..."
    
    $installerPath = "$env:TEMP\wireguard-installer.exe"
    Invoke-WebRequest -Uri $wireguardInstallerUrl -OutFile $installerPath
    
    # Silent install
    Start-Process -FilePath $installerPath -ArgumentList "/install /quiet" -Wait
    Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
    
    Write-Output "WireGuard installation complete."
} else {
    Write-Output "WireGuard is already installed."
}

Write-Output "Downloading WireGuard configuration..."
New-Item -ItemType Directory -Force -Path $configDir
Invoke-WebRequest -Uri $configUrl -OutFile $configPath -UseBasicParsing

