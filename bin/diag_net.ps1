[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=20) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "===== [L2] phone ADB still connected? ====="
Run-Adb @('devices') 15
Write-Output "===== [L3] adb forward list ====="
Run-Adb @('forward','--list') 12
Write-Output "===== [L4] phone current wifi ====="
$st = Run-Adb @('shell','cmd wifi status') 15
($st | Select-String 'Wifi is connected to').Line
Write-Output "===== [L5] wifi scan: robot APs present? ====="
Run-Adb @('shell','cmd wifi start-scan') 10 | Out-Null
Start-Sleep -Seconds 5
Run-Adb @('shell','cmd wifi list-scan-results') 20 | Select-String 'HW-|RobotLink'
Write-Output "===== [L6] phone relay alive? ====="
Run-Adb @('shell','ps -A -o PID,ARGS | grep relay.sh | grep -v grep || echo RELAY_DEAD; ss -tln | grep 8022 || echo NO_LISTENER') 15
Write-Output "===== [L7] Windows portproxy ====="
netsh interface portproxy show all
