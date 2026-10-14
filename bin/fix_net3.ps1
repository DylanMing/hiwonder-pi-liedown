[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=30) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== [1] clean kill via pushed script ==="
Run-Adb @('shell','sh /data/local/tmp/kill_relay.sh') 30
Write-Output "=== [2] relaunch relay (192.168.149.1) ==="
Run-Adb @('shell','setsid sh /data/local/tmp/relay.sh </dev/null >/data/local/tmp/relay.log 2>&1 & sleep 2; echo launched') 15
Write-Output "=== [3] dance test (expect banner + kex) ==="
Run-Adb @('shell','printf "SSH-2.0-T\r\n" | timeout 6 nc 127.0.0.1 8022 | od -c | head -6') 30
