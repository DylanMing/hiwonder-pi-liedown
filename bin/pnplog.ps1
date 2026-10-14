[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Output "=== Kernel-PnP device events (last 60 min) ==="
$cutoff = (Get-Date).AddMinutes(-60)
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Kernel-PnP/Configuration'; StartTime=$cutoff} -ErrorAction SilentlyContinue | Select-Object -First 40 | ForEach-Object {
  Write-Output ($_.TimeCreated.ToString('HH:mm:ss') + "  [" + $_.Id + "]  " + ($_.Message -split "`n")[0])
}
Write-Output ""
Write-Output "=== DriverFrameworks-UserMode events (last 60 min) ==="
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-DriverFrameworks-UserMode/Operational'; StartTime=$cutoff} -ErrorAction SilentlyContinue | Select-Object -First 20 | ForEach-Object {
  Write-Output ($_.TimeCreated.ToString('HH:mm:ss') + "  [" + $_.Id + "]  " + ($_.Message -split "`n")[0])
}
