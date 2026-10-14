[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=30) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== [1] clean kill all ==="
Run-Adb @('shell','sh /data/local/tmp/kill_relay.sh; echo KILL_DONE') 30
Write-Output "=== [2] port 8022 free? ==="
Run-Adb @('shell','ss -tln | grep 8022 && echo STILL_HELD || echo PORT_FREE') 15
Write-Output "=== [3] launch ONE fresh relay ==="
Run-Adb @('shell','rm -f /data/local/tmp/relay.log; setsid sh /data/local/tmp/relay.sh </dev/null >/data/local/tmp/relay.log 2>&1 & sleep 2; echo launched') 15
Write-Output "=== [4] verify listener ==="
Run-Adb @('shell','ss -tln | grep 8022 || echo NO_LISTENER; ps -A -o PID,ARGS | grep relay.sh | grep -v grep') 15
Write-Output "=== [5] dance test (expect banner + kex) ==="
Run-Adb @('shell','printf "SSH-2.0-T\r\n" | timeout 8 nc 127.0.0.1 8022 | od -c | head -8') 30
Write-Output "=== [6] relay.log (should be empty) ==="
Run-Adb @('shell','cat /data/local/tmp/relay.log; echo ---end---') 15
