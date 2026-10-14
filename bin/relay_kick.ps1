[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=30) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== current state ==="
Run-Adb @('shell','ss -tln | grep 8022 || echo NO_LISTENER; ps -A -o PID,ARGS | grep relay.sh | grep -v grep || echo NO_PROC; cat /data/local/tmp/relay.log 2>/dev/null; echo ---log-end---') 15
Write-Output "=== relaunch ==="
Run-Adb @('shell','setsid sh /data/local/tmp/relay.sh </dev/null >/data/local/tmp/relay.log 2>&1 & sleep 3; echo relaunched') 20
Write-Output "=== verify (after 3s wait inside same shell) ==="
Run-Adb @('shell','ss -tln | grep 8022 || echo NO_LISTENER; ps -A -o PID,ARGS | grep relay.sh | grep -v grep || echo NO_PROC; cat /data/local/tmp/relay.log 2>/dev/null; echo ---log-end---') 15
