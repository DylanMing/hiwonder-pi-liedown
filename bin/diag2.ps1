[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=15) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== phone wifi ==="
$st = Run-Adb @('shell','cmd wifi status') 15
($st | Select-String 'Wifi is connected to').Line
Write-Output "=== relay process & listener ==="
Run-Adb @('shell','ps -A -o PID,NAME,ARGS 2>/dev/null | grep -E "relay|nc " | grep -v grep; ss -tln | grep 8022 || echo NO_LISTENER') 15
Write-Output "=== relay log ==="
Run-Adb @('shell','cat /data/local/tmp/relay.log 2>/dev/null | tail -5') 15
Write-Output "=== banner test direct 127.0.0.1:2222 ==="
$c = New-Object System.Net.Sockets.TcpClient
$ar = $c.BeginConnect('127.0.0.1',2222,$null,$null)
if ($ar.AsyncWaitHandle.WaitOne(4000) -and $c.Connected) {
  $s = $c.GetStream(); $s.ReadTimeout = 4000
  $buf = New-Object byte[] 100
  try { $n = $s.Read($buf,0,100); Write-Output ("BANNER: " + [Text.Encoding]::ASCII.GetString($buf,0,$n).Trim()) } catch { Write-Output "connected, no banner" }
  $c.Close()
} else { Write-Output "closed/timeout" }
