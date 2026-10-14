[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=30) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Run-Adb @('push','\\wsl.localhost\Ubuntu-24.04\home\administrator\hiwonder\bin\kill_relay_v2.sh','/data/local/tmp/kill_relay_v2.sh') 20
Write-Output "=== [1] v2 kill ==="
Run-Adb @('shell','sh /data/local/tmp/kill_relay_v2.sh') 30
Write-Output "=== [2] launch fresh relay ==="
Run-Adb @('shell','rm -f /data/local/tmp/relay.log; setsid sh /data/local/tmp/relay.sh </dev/null >/data/local/tmp/relay.log 2>&1 & sleep 2; echo launched') 15
Write-Output "=== [3] verify ==="
Run-Adb @('shell','ss -tln | grep 8022 || echo NO_LISTENER; cat /data/local/tmp/relay.log; echo ---log-end---') 15
