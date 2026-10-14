[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=25) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== [1] kill old relay ==="
Run-Adb @('shell','for p in $(ps -A -o PID,ARGS | grep relay.sh | grep -v grep | sed "s/^ *//" | cut -d" " -f1); do kill -9 $p; done; killall nc 2>/dev/null; sleep 1; echo killed') 20
Write-Output "=== [2] push new relay (192.168.149.1) & launch ==="
Run-Adb @('push','\\wsl.localhost\Ubuntu-24.04\home\administrator\hiwonder\bin\relay.sh','/data/local/tmp/relay.sh') 20
Run-Adb @('shell','setsid sh /data/local/tmp/relay.sh </dev/null >/data/local/tmp/relay.log 2>&1 & sleep 2; echo launched') 15
Write-Output "=== [3] dance test ==="
Run-Adb @('shell','ss -tln | grep 8022 || echo NO_LISTENER; printf "SSH-2.0-T\r\n" | timeout 6 nc 127.0.0.1 8022 | od -c | head -6') 30
Write-Output "=== [4] re-add adb forward ==="
Run-Adb @('forward','tcp:2222','tcp:8022') 12
Run-Adb @('forward','--list') 12
