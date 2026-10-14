[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=15) {
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
Write-Output "=== [1] kill old adb, start persistent server ==="
Stop-Process -Name adb -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 800
Start-Process -FilePath $adb -ArgumentList 'start-server' -WindowStyle Hidden -RedirectStandardOutput 'C:\Users\Public\adbsrv.out' -RedirectStandardError 'C:\Users\Public\adbsrv.err'
Start-Sleep -Seconds 4
Write-Output "=== [2] devices (persistent server test) ==="
Run-Adb @('devices') 15
Write-Output "=== [3] set forwards ==="
Run-Adb @('forward','tcp:2222','tcp:192.168.149.1:22') 12
Run-Adb @('forward','tcp:25900','tcp:192.168.149.1:5900') 12
Run-Adb @('forward','tcp:2280','tcp:192.168.149.1:80') 12
Run-Adb @('forward','tcp:28080','tcp:192.168.149.1:8080') 12
Run-Adb @('forward','tcp:28000','tcp:192.168.149.1:8000') 12
Run-Adb @('forward','tcp:22001','tcp:192.168.149.1:2001') 12
Write-Output "=== [4] forward list (must be non-empty!) ==="
Run-Adb @('forward','--list') 12
Write-Output "=== [5] PORT TESTS (robot 192.168.149.1 via phone) ==="
Write-Output ("SSH  22    : " + (Test-PortFast 2222 $false))
Write-Output ("VNC  5900  : " + (Test-PortFast 25900 $false))
Write-Output ("HTTP 80    : " + (Test-PortFast 2280 $true))
Write-Output ("HTTP 8080  : " + (Test-PortFast 28080 $true))
Write-Output ("HTTP 8000  : " + (Test-PortFast 28000 $true))
Write-Output ("RAW  2001  : " + (Test-PortFast 22001 $false))
