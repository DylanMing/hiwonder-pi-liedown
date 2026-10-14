[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=40) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== timing test: launch & watch within same shell ==="
Run-Adb @('shell','setsid sh /data/local/tmp/relay.sh </dev/null >/data/local/tmp/relay.log 2>&1 & sleep 1; echo T1_plus1s; ss -tln | grep 8022 || echo T1_NO_LISTENER; sleep 4; echo T2_plus5s; ss -tln | grep 8022 || echo T2_NO_LISTENER; sleep 5; echo T3_plus10s; ss -tln | grep 8022 || echo T3_NO_LISTENER') 40
Write-Output "=== T4: after launching shell exited (separate call) ==="
Start-Sleep -Seconds 2
Run-Adb @('shell','ss -tln | grep 8022 || echo T4_NO_LISTENER; ps -A -o PID,ARGS | grep relay.sh | grep -v grep || echo NO_PROC') 15
