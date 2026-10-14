[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=30) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Run-Adb @('push','\\wsl.localhost\Ubuntu-24.04\home\administrator\hiwonder\bin\kill_relay.sh','/data/local/tmp/kill_relay.sh') 20
Write-Output "=== [1] clean kill ==="
Run-Adb @('shell','sh /data/local/tmp/kill_relay.sh') 25
Write-Output "=== [2] launch v3 fresh ==="
Run-Adb @('shell','setsid sh /data/local/tmp/relay.sh </dev/null >/data/local/tmp/relay.log 2>&1 & sleep 2; echo launched') 15
Write-Output "=== [3] dance test x2 ==="
Run-Adb @('shell','printf "SSH-2.0-T\r\n" | timeout 6 nc 127.0.0.1 8022 | od -c | head -4; echo dance1_done; sleep 2; printf "SSH-2.0-T\r\n" | timeout 6 nc 127.0.0.1 8022 | od -c | head -4; echo dance2_done') 40
