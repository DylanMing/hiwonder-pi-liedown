[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Output "=== present USB devices ==="
Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -like 'USB*' } | ForEach-Object { Write-Output ($_.Status + "  " + $_.Class + "  " + $_.InstanceId + "  " + $_.FriendlyName) }
Write-Output "=== COM ports ==="
Get-CimInstance Win32_PnPEntity | Where-Object { $_.Name -match 'COM\d' } | ForEach-Object { Write-Output ($_.Name + " -> " + $_.PNPDeviceID) }
Write-Output "=== network adapters status ==="
Get-NetAdapter | ForEach-Object { Write-Output ($_.Name + "  [" + $_.InterfaceDescription + "]  Status:" + $_.Status + "  Mac:" + $_.MacAddress) }
Write-Output "=== hotspot capability ==="
netsh wlan show drivers | Select-String -Pattern 'Hosted network|驱动程序|Driver|Hosted'
