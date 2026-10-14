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
Write-Output "=== [A] forward list (current state) ==="
Run-Adb @('forward','--list') 15
Write-Output "=== [B] sanity: forward to phone-local port 7890 (Clash) ==="
Run-Adb @('forward','tcp:27890','tcp:127.0.0.1:7890') 12 | Out-Null
Run-Adb @('forward','--list') 15
Write-Output ("sanity test 7890 -> " + (Test-PortFast 27890 $false))
Write-Output "=== [C] phone ping gateway 192.168.149.1 ==="
Run-Adb @('shell','ping -c 2 -W 2 192.168.149.1') 20
Write-Output "=== [D] current wifi ==="
$st = Run-Adb @('shell','cmd wifi status') 15
($st | Select-String 'Wifi is connected to').Line
