[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=20) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== [1] push relay.sh ==="
Run-Adb @('push','\\wsl.localhost\Ubuntu-24.04\home\administrator\hiwonder\bin\relay.sh','/data/local/tmp/relay.sh') 20
Write-Output "=== [2] launch detached relay ==="
Run-Adb @('shell','killall sh-relay 2>/dev/null; setsid sh /data/local/tmp/relay.sh </dev/null >/data/local/tmp/relay.log 2>&1 & sleep 2; echo launched') 15
Start-Sleep -Seconds 3
Write-Output "=== [3] verify listener on phone ==="
Run-Adb @('shell','ss -tln 2>/dev/null | grep 8022 || netstat -tln 2>/dev/null | grep 8022 || echo NO_LISTENER') 15
Write-Output "=== [4] adb forward (port-only remote is legal) ==="
Run-Adb @('forward','tcp:2222','tcp:8022') 12
Run-Adb @('forward','tcp:0.0.0.0:2422','tcp:8022') 12
Run-Adb @('forward','--list') 12
Write-Output "=== [5] SSH BANNER TEST ==="
$c = New-Object System.Net.Sockets.TcpClient
$ar = $c.BeginConnect('127.0.0.1',2222,$null,$null)
if ($ar.AsyncWaitHandle.WaitOne(4000) -and $c.Connected) {
  $s = $c.GetStream(); $s.ReadTimeout = 4000
  $buf = New-Object byte[] 100
  try { $n = $s.Read($buf,0,100); Write-Output ("BANNER: " + [Text.Encoding]::ASCII.GetString($buf,0,$n).Trim()) } catch { Write-Output "connected, no banner" }
  $c.Close()
} else { Write-Output "closed/timeout" }
Write-Output "=== [6] phone still on robot wifi? ==="
$st = Run-Adb @('shell','cmd wifi status') 15
($st | Select-String 'Wifi is connected to').Line
