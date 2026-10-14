[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Output "=== Currently connected USB entities (Win32_PnPEntity, PNPDeviceID like USB%) ==="
Get-CimInstance Win32_PnPEntity -Filter "PNPDeviceID LIKE 'USB%'" | ForEach-Object {
  Write-Output ($_.PNPDeviceID + "  |  " + $_.Name + "  |  Status:" + $_.Status + "  |  Desc:" + $_.Description)
}
Write-Output ""
Write-Output "=== Devices with problems (ConfigManagerErrorCode != 0) ==="
Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 } | ForEach-Object {
  Write-Output ($_.PNPDeviceID + "  |  " + $_.Name + "  |  Code:" + $_.ConfigManagerErrorCode)
}
Write-Output ""
Write-Output "=== USB Hubs & controllers ==="
Get-CimInstance Win32_USBHub | ForEach-Object {
  Write-Output ($_.DeviceID + "  |  " + $_.Name + "  |  " + $_.Description)
}
