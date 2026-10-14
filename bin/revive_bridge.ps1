[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=25) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== [1] force phone back to robot AP ==="
Run-Adb @('shell','cmd wifi connect-network HW-9E00B2EB wpa2 hiwonder') 20 | Out-Null
Start-Sleep -Seconds 6
$st = Run-Adb @('shell','cmd wifi status') 15
($st | Select-String 'Wifi is connected to').Line
Write-Output "=== [2] relay alive? ==="
$r = Run-Adb @('shell','ps -A -o PID,ARGS | grep relay.sh | grep -v grep || echo NO_PROC; ss -tln | grep 8022 || echo NO_LISTENER') 15
Write-Output $r
if ("$r" -match 'NO_PROC') {
  Write-Output ">>> relaunch relay"
  Run-Adb @('shell','setsid sh /data/local/tmp/relay.sh </dev/null >/data/local/tmp/relay.log 2>&1 & sleep 2; echo relaunched') 15
  Run-Adb @('shell','ss -tln | grep 8022 || echo NO_LISTENER') 15
}
Write-Output "=== [3] adb forward still there? ==="
$f = Run-Adb @('forward','--list') 12
Write-Output $f
if ("$f" -notmatch '2222') { Run-Adb @('forward','tcp:2222','tcp:8022') 12; Run-Adb @('forward','--list') 12 }
