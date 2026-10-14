[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=25) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== [1] kill ALL old relay stuff ==="
Run-Adb @('shell','for p in $(ps -A -o PID,ARGS | grep "relay.sh" | grep -v grep | sed "s/^ *//" | cut -d" " -f1); do kill $p; done; for p in $(ps -A -o PID,ARGS | grep "sleep 31536000" | grep -v grep | sed "s/^ *//" | cut -d" " -f1); do kill $p; done; killall nc 2>/dev/null; sleep 1; echo cleaned') 20
Write-Output "=== [2] push v3 & launch ==="
Run-Adb @('push','\\wsl.localhost\Ubuntu-24.04\home\administrator\hiwonder\bin\relay.sh','/data/local/tmp/relay.sh') 20
Run-Adb @('shell','setsid sh /data/local/tmp/relay.sh </dev/null >/data/local/tmp/relay.log 2>&1 & sleep 2; echo launched') 15
Write-Output "=== [3] dance test x2 through 8022 ==="
Run-Adb @('shell','printf "SSH-2.0-T\r\n" | timeout 6 nc 127.0.0.1 8022 | od -c | head -4; echo "=== dance1 done ==="; sleep 2; printf "SSH-2.0-T\r\n" | timeout 6 nc 127.0.0.1 8022 | od -c | head -4; echo "=== dance2 done ==="') 40
