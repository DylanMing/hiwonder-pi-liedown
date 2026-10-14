[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Output "=== USB devices (looking for phone) ==="
Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -like 'USB*' -and $_.Class -in @('USB','AndroidUsbDeviceClass','WPD','Ports','Net') } | ForEach-Object { Write-Output ($_.Status + "  " + $_.Class + "  " + $_.InstanceId + "  " + $_.FriendlyName) }
Write-Output "=== adb in PATH? ==="
$where = Get-Command adb -ErrorAction SilentlyContinue
if ($where) { Write-Output ("adb: " + $where.Source) } else { Write-Output "adb NOT in PATH" }
Write-Output "=== common adb locations ==="
foreach ($p in @("$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe", "$env:ProgramFiles\adb\adb.exe", "$env:USERPROFILE\platform-tools\adb.exe", "C:\platform-tools\adb.exe")) { if (Test-Path $p) { Write-Output ("found: " + $p) } }
