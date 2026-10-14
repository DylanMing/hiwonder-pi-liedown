[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=25) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
function Test-PortFast($port, $sendHttp) {
  $c = New-Object System.Net.Sockets.TcpClient
  $ar = $c.BeginConnect('127.0.0.1',$port,$null,$null)
  if ($ar.AsyncWaitHandle.WaitOne(2200) -and $c.Connected) {
    $s = $c.GetStream(); $s.ReadTimeout = 2200
    if ($sendHttp) { $b=[Text.Encoding]::ASCII.GetBytes("GET / HTTP/1.0`r`n`r`n"); $s.Write($b,0,$b.Length) }
    $buf = New-Object byte[] 200
    try { $n = $s.Read($buf,0,200); return "OPEN: " + (([Text.Encoding]::ASCII.GetString($buf,0,[Math]::Min($n,110))) -replace "`r|`n"," ") } catch { return "OPEN (silent)" }
  } else { return "closed" }
  $c.Close()
}
Write-Output "=== check still on robot AP ==="
$st = Run-Adb @('shell','cmd wifi status') 15
$line = ($st | Select-String 'Wifi is connected to').Line
Write-Output $line
if ($line -notmatch 'HW-9E00C2F4') {
  Write-Output "bounced off, reconnecting..."
  Run-Adb @('shell','cmd wifi connect-network HW-9E00C2F4 open') 20 | Out-Null
  $ok = $false
  for ($i=0; $i -lt 8; $i++) { Start-Sleep -Seconds 2; $st = Run-Adb @('shell','cmd wifi status') 15; $l = ($st | Select-String 'Wifi is connected to').Line; if ($l -match 'HW-9E00C2F4') { $ok=$true; break } }
  if (-not $ok) { Write-Output "FAILED to reconnect"; exit 1 }
}
Write-Output "=== forwards to 10.42.0.1 ==="
Run-Adb @('forward','--remove-all') 10 | Out-Null
$ports = @{2222=22; 25900=5900; 2280=80; 28080=8080; 28000=8000; 22001=2001; 29000=9000; 25555=5555; 29030=9030; 28527=8527}
foreach ($k in $ports.Keys) { Run-Adb @('forward',"tcp:$k","tcp:10.42.0.1:$($ports[$k])") 12 | Out-Null }
Write-Output "=== port tests (10.42.0.1 via phone) ==="
Write-Output ("SSH   22    : " + (Test-PortFast 2222 $false))
Write-Output ("VNC   5900  : " + (Test-PortFast 25900 $false))
Write-Output ("HTTP  80    : " + (Test-PortFast 2280 $true))
Write-Output ("HTTP  8080  : " + (Test-PortFast 28080 $true))
Write-Output ("HTTP  8000  : " + (Test-PortFast 28000 $true))
Write-Output ("RAW   2001  : " + (Test-PortFast 22001 $false))
Write-Output ("RAW   9000  : " + (Test-PortFast 29000 $false))
Write-Output ("RAW   5555  : " + (Test-PortFast 25555 $false))
Write-Output ("RAW   9030  : " + (Test-PortFast 29030 $false))
Write-Output ("RAW   8527  : " + (Test-PortFast 28527 $false))
Write-Output "=== final: still connected? ==="
$st2 = Run-Adb @('shell','cmd wifi status') 15
($st2 | Select-String 'Wifi is connected to').Line
