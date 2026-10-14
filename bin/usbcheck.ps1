[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Output "=== ALL present USB devices ==="
Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -like 'USB*' } | ForEach-Object { Write-Output ($_.Status + "  " + $_.Class + "  " + $_.InstanceId + "  " + $_.FriendlyName) }
Write-Output ""
Write-Output "=== COM ports ==="
Get-CimInstance Win32_PnPEntity | Where-Object { $_.Name -match 'COM\d' } | ForEach-Object { Write-Output ($_.Name + "  ->  " + $_.PNPDeviceID) }
Write-Output ""
Write-Output "=== PnP events last 15 min ==="
$cutoff = (Get-Date).AddMinutes(-15)
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Kernel-PnP/Configuration'; StartTime=$cutoff} -ErrorAction SilentlyContinue | Select-Object -First 30 | ForEach-Object { Write-Output ($_.TimeCreated.ToString('HH:mm:ss') + "  [" + $_.Id + "]  " + ($_.Message -split "`n")[0]) }
