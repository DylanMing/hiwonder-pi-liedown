[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=20) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== [1] scan for robot APs (old one was HW-9E00C2F4 / HW-24353859) ==="
Run-Adb @('shell','cmd wifi start-scan') 10 | Out-Null
Start-Sleep -Seconds 5
Run-Adb @('shell','cmd wifi list-scan-results') 20 | Select-String 'HW-'
Write-Output "=== [2] phone current wifi ==="
$st = Run-Adb @('shell','cmd wifi status') 15
($st | Select-String 'Wifi is connected to').Line
Write-Output "=== [3] phone relay still alive? ==="
Run-Adb @('shell','ps -A -o PID,ARGS | grep relay.sh | grep -v grep || echo RELAY_DEAD') 15
Write-Output "=== [4] adb forward list ==="
Run-Adb @('forward','--list') 15
Write-Output "=== [5] portproxy state ==="
netsh interface portproxy show all
