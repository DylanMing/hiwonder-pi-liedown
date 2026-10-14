[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=30) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
function Test-PortFast($port, $sendHttp) {
  $c = New-Object System.Net.Sockets.TcpClient
  $ar = $c.BeginConnect('127.0.0.1',$port,$null,$null)
  if ($ar.AsyncWaitHandle.WaitOne(2500) -and $c.Connected) {
    $s = $c.GetStream(); $s.ReadTimeout = 2500
    if ($sendHttp) { $b=[Text.Encoding]::ASCII.GetBytes("GET / HTTP/1.0`r`n`r`n"); $s.Write($b,0,$b.Length) }
    $buf = New-Object byte[] 200
    try { $n = $s.Read($buf,0,200); return "OPEN: " + (([Text.Encoding]::ASCII.GetString($buf,0,[Math]::Min($n,100))) -replace "`r|`n"," ") } catch { return "OPEN (silent)" }
  } else { return "closed" }
  $c.Close()
}
$ssid = 'HW-9E00C2F4'
Write-Output "=== connect $ssid (open) ==="
Run-Adb @('shell',"cmd wifi connect-network $ssid open") 20 | Out-Null
$connected = $false
for ($i=0; $i -lt 12; $i++) {
  Start-Sleep -Seconds 2
  $st = Run-Adb @('shell','cmd wifi status') 15
  $line = ($st | Select-String 'Wifi is connected to').Line
  Write-Output ("  poll$i : $line")
  if ($line -match [regex]::Escape($ssid)) { $connected = $true; break }
  if ($line -match 'Wifi is connected') { Run-Adb @('shell',"cmd wifi connect-network $ssid open") 20 | Out-Null }
}
if (-not $connected) { Write-Output "FAILED"; exit 1 }
Write-Output "=== network info ==="
Run-Adb @('shell','ip -4 addr show wlan0') 15 | Select-String 'inet'
Run-Adb @('shell','ip route') 15
Run-Adb @('shell','ip neigh') 15
Write-Output "=== phone TCP connections (app control trace) ==="
Run-Adb @('shell','ss -tn 2>/dev/null || netstat -tn 2>/dev/null') 15
