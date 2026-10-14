[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=30) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== [1] fractional sleep supported? ==="
Run-Adb @('shell','sleep 0.2; echo SLEEP_OK') 15
Write-Output "=== [2] update relay.sh (sleep 0.2) ==="
Run-Adb @('shell',"sed -i 's/^  sleep 1$/  sleep 0.2/' /data/local/tmp/relay.sh && grep sleep /data/local/tmp/relay.sh") 15
Write-Output "=== [3] clean restart ==="
Run-Adb @('shell','sh /data/local/tmp/kill_relay_v2.sh; rm -f /data/local/tmp/relay.log; setsid sh /data/local/tmp/relay.sh </dev/null >/data/local/tmp/relay.log 2>&1 & sleep 1; echo relaunched') 30
Write-Output "=== [4] listener + log ==="
Run-Adb @('shell','ss -tln | grep 8022 || echo NO_LISTENER; cat /data/local/tmp/relay.log; echo ---end---') 15
