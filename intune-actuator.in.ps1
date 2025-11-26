$ServiceFQDN = '{{SERVICE_FQDN}}'
$WiFiGateway = "{{WIFI_GATEWAY}}"
$EthernetGateway = "{{ETH_GATEWAY}}"

$TaskName = "$ServiceFQDN Actuator"
$ScriptPath = "C:\Scripts\$ServiceFQDN.actuator.ps1"

$Script = @"
function Is-InLocalIntranet {
	`$ipAdapters = Get-NetIPConfiguration | ? { `$_.NetAdapter.Status -eq 'Up' }
	`$wifiAdapters = `$ipAdapters | ? { `$_.InterfaceDescription -match "wireless" -or `$_.InterfaceAlias -match "wlan" -or `$_.InterfaceAlias -match "wifi" -or `$_.InterfaceAlias -match "wi-fi" }
	`$ethernetAdapters = `$ipAdapters | ? { `$_.InterfaceDescription -match "ethernet" -or `$_.InterfaceAlias -match "ethernet" }

	return (`$wifiAdapters | ? { "`$(`$_.IPv4DefaultGateway.NextHop)" -eq '$WiFiGateway' }).Count ``
		-or (`$ethernetAdapters | ? { "`$(`$_.IPv4DefaultGateway.NextHop)" -eq '$EthernetGateway' }).Count
}

if (Is-InLocalIntranet) {
	& 'C:\Program Files\WireGuard\wireguard.exe' /uninstalltunnelservice '$ServiceFQDN'
} else {
	& 'C:\Program Files\WireGuard\wireguard.exe' /installtunnelservice 'C:\Program Files\WireGuard\Config\$ServiceFQDN.conf'
}
"@



Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

$_ = New-Item -ItemType Directory -Path 'C:\Scripts' -Force
Set-Content -Path $ScriptPath -Value $Script.Trim()

$action = New-ScheduledTaskAction -Execute powershell.exe `
	-Argument "-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""

$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) `
	-RepetitionInterval (New-TimeSpan -Minutes 2)

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

$_ = Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -User "SYSTEM" -RunLevel Highest
