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
    $s = $c.GetStream(); $s.ReadTimeout = 2500; $s.WriteTimeout = 2500
    if ($sendHttp) { $b=[Text.Encoding]::ASCII.GetBytes("GET / HTTP/1.0`r`n`r`n"); $s.Write($b,0,$b.Length) }
    $buf = New-Object byte[] 256
    try { $n = $s.Read($buf,0,256); return "OPEN: " + (([Text.Encoding]::ASCII.GetString($buf,0,[Math]::Min($n,120))) -replace "`r|`n"," ") } catch { return "OPEN (no banner)" }
  } else { return "closed" }
  $c.Close()
}
$ssid = 'HW-24353859'
Write-Output "=== connect $ssid ==="
Run-Adb @('shell',"cmd wifi connect-network $ssid wpa2 hiwonder") 20 | Out-Null
$connected = $false
for ($i=0; $i -lt 10; $i++) {
  Start-Sleep -Seconds 2
  $st = Run-Adb @('shell','cmd wifi status') 15
  $line = ($st | Select-String 'Wifi is connected to').Line
  if ($line -match [regex]::Escape($ssid)) { $connected = $true; Write-Output "connected (poll $i)"; break }
}
if (-not $connected) { Write-Output "FAILED to connect"; exit 1 }
Write-Output "=== set up forwards ==="
Run-Adb @('forward','--remove-all') 10 | Out-Null
Run-Adb @('forward','tcp:2222','tcp:192.168.149.1:22') 15 | Out-Null
Run-Adb @('forward','tcp:2280','tcp:192.168.149.1:80') 15 | Out-Null
Run-Adb @('forward','tcp:25900','tcp:192.168.149.1:5900') 15 | Out-Null
Run-Adb @('forward','tcp:28000','tcp:192.168.149.1:8000') 15 | Out-Null
Run-Adb @('forward','tcp:28080','tcp:192.168.149.1:8080') 15 | Out-Null
Run-Adb @('forward','--list') 15
Write-Output "=== port tests ==="
Write-Output ("SSH  22   : " + (Test-PortFast 2222 $false))
Write-Output ("HTTP 80   : " + (Test-PortFast 2280 $true))
Write-Output ("VNC  5900 : " + (Test-PortFast 25900 $false))
Write-Output ("HTTP 8000 : " + (Test-PortFast 28000 $true))
Write-Output ("HTTP 8080 : " + (Test-PortFast 28080 $true))
Write-Output "=== still connected? ==="
$st2 = Run-Adb @('shell','cmd wifi status') 15
($st2 | Select-String 'Wifi is connected to').Line
