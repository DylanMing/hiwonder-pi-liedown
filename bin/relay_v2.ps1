[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=20) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== [1] ensure phone on robot wifi ==="
$st = Run-Adb @('shell','cmd wifi status') 15
$line = ($st | Select-String 'Wifi is connected to').Line
Write-Output $line
if ($line -notmatch 'HW-9E00C2F4') {
  Run-Adb @('shell','cmd wifi connect-network HW-9E00C2F4 wpa2 hiwonder') 20 | Out-Null
  Start-Sleep -Seconds 5
  $st = Run-Adb @('shell','cmd wifi status') 15
  ($st | Select-String 'Wifi is connected to').Line
}
Write-Output "=== [2] kill old relay ==="
Run-Adb @('shell','for p in $(ps -A -o PID,ARGS 2>/dev/null | grep relay.sh | grep -v grep | awk "{print \$1}"); do kill $p 2>/dev/null; done; killall nc 2>/dev/null; sleep 1; echo killed') 15
Write-Output "=== [3] push & launch v2 ==="
Run-Adb @('push','\\wsl.localhost\Ubuntu-24.04\home\administrator\hiwonder\bin\relay.sh','/data/local/tmp/relay.sh') 20
Run-Adb @('shell','setsid sh /data/local/tmp/relay.sh </dev/null >/data/local/tmp/relay.log 2>&1 & sleep 3; echo launched') 15
Write-Output "=== [4] listener up? ==="
Run-Adb @('shell','ss -tln | grep 8022 || echo NO_LISTENER') 15
Write-Output "=== [5] banner test #1 ==="
$c = New-Object System.Net.Sockets.TcpClient
$ar = $c.BeginConnect('127.0.0.1',2222,$null,$null)
if ($ar.AsyncWaitHandle.WaitOne(4000) -and $c.Connected) {
  $s = $c.GetStream(); $s.ReadTimeout = 4000; $buf = New-Object byte[] 100
  try { $n = $s.Read($buf,0,100); Write-Output ("BANNER1: " + [Text.Encoding]::ASCII.GetString($buf,0,$n).Trim()) } catch { Write-Output "no banner" }
  $c.Close()
} else { Write-Output "closed" }
Start-Sleep -Seconds 3
Write-Output "=== [6] banner test #2 (cycle recovery) ==="
$c = New-Object System.Net.Sockets.TcpClient
$ar = $c.BeginConnect('127.0.0.1',2222,$null,$null)
if ($ar.AsyncWaitHandle.WaitOne(4000) -and $c.Connected) {
  $s = $c.GetStream(); $s.ReadTimeout = 4000; $buf = New-Object byte[] 100
  try { $n = $s.Read($buf,0,100); Write-Output ("BANNER2: " + [Text.Encoding]::ASCII.GetString($buf,0,$n).Trim()) } catch { Write-Output "no banner" }
  $c.Close()
} else { Write-Output "closed" }
