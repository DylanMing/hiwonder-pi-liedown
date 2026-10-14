[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Output "=== USBSTOR (mass storage) ==="
Get-CimInstance Win32_PnPEntity -Filter "PNPDeviceID LIKE 'USBSTOR%'" | ForEach-Object { Write-Output ($_.PNPDeviceID + " | " + $_.Name) }
Write-Output "=== Ports (COM & LPT) class ==="
Get-CimInstance Win32_PnPEntity | Where-Object { $_.PNPClass -eq 'Ports' -or $_.Name -match 'COM\d|LPT' } | ForEach-Object { Write-Output ($_.PNPDeviceID + " | " + $_.Name) }
Write-Output "=== WPD / portable devices ==="
Get-CimInstance Win32_PnPEntity | Where-Object { $_.PNPClass -eq 'WPD' } | ForEach-Object { Write-Output ($_.PNPDeviceID + " | " + $_.Name) }
Write-Output "=== Re-poll: ALL present USB devices right now ==="
Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -like 'USB*' } | ForEach-Object { Write-Output ($_.Status + "  " + $_.Class + "  " + $_.InstanceId) }
Write-Output "=== Last USB-related setup events (any age, top 15) ==="
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Kernel-PnP/Configuration'} -MaxEvents 15 -ErrorAction SilentlyContinue | ForEach-Object { Write-Output ($_.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss') + "  [" + $_.Id + "]  " + ($_.Message -split "`n")[0]) }
