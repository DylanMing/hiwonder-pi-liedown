[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=25) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== [1] clean old relay remnants ==="
Run-Adb @('shell','killall nc 2>/dev/null; sleep 1; echo ok') 15
Write-Output "=== [2] push relay (new robot IP 10.42.0.1) & launch ==="
Run-Adb @('push','\\wsl.localhost\Ubuntu-24.04\home\administrator\hiwonder\bin\relay.sh','/data/local/tmp/relay.sh') 20
Run-Adb @('shell','setsid sh /data/local/tmp/relay.sh </dev/null >/data/local/tmp/relay.log 2>&1 & sleep 2; echo launched') 15
Write-Output "=== [3] listener + local dance test ==="
Run-Adb @('shell','ss -tln | grep 8022 || echo NO_LISTENER') 15
Run-Adb @('shell','printf "SSH-2.0-T\r\n" | timeout 6 nc 127.0.0.1 8022 | od -c | head -4') 30
Write-Output "=== [4] re-add adb forward ==="
Run-Adb @('forward','tcp:2222','tcp:8022') 12
Run-Adb @('forward','--list') 12
Write-Output "=== [5] banner via Windows loopback ==="
$c = New-Object System.Net.Sockets.TcpClient
$ar = $c.BeginConnect('127.0.0.1',2222,$null,$null)
if ($ar.AsyncWaitHandle.WaitOne(4000) -and $c.Connected) {
  $s = $c.GetStream(); $s.ReadTimeout = 4000; $buf = New-Object byte[] 100
  try { $n = $s.Read($buf,0,100); Write-Output ("BANNER: " + [Text.Encoding]::ASCII.GetString($buf,0,$n).Trim()) } catch { Write-Output "no banner" }
  $c.Close()
} else { Write-Output "closed" }
