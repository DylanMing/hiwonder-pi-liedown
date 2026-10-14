[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=25) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT: adb $($cmdArgs -join ' ')" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== devices ==="
Run-Adb @('devices')
Write-Output "=== phone wlan0 (robot AP subnet) ==="
Run-Adb @('shell','ip -4 addr show wlan0')
Write-Output "=== phone ARP neighbors (find robot) ==="
Run-Adb @('shell','ip neigh')
