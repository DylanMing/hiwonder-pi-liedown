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
function Probe-Network($label) {
  Write-Output "--- network info ($label) ---"
  $ipout = Run-Adb @('shell','ip -4 addr show wlan0') 15 | Select-String 'inet'
  Write-Output ("phone IP: " + $ipout)
  $gw = $null
  $route = Run-Adb @('shell','ip route') 15
  Write-Output ("routes: " + ($route -join ' ; '))
  if ($route -match 'via\s+(\d+\.\d+\.\d+\.\d+)') { $gw = $Matches[1] }
  if (-not $gw -and $ipout -match 'inet\s+(\d+\.\d+\.\d+)\.(\d+)/(\d+)') { $gw = $Matches[1] + ".1" }
  $neigh = Run-Adb @('shell','ip neigh') 15
  Write-Output ("neigh: " + ($neigh -join ' ; '))
  if (-not $gw) { foreach ($n in $neigh) { if ($n -match '(\d+\.\d+\.\d+\.\d+).*REACHABLE') { $gw = $Matches[1]; break } } }
  Write-Output ("gateway: $gw")
  if ($gw) {
    Run-Adb @('forward','--remove-all') 10 | Out-Null
    Run-Adb @('forward','tcp:2222',"tcp:${gw}:22") 12 | Out-Null
    Run-Adb @('forward','tcp:25900',"tcp:${gw}:5900") 12 | Out-Null
    Run-Adb @('forward','tcp:2280',"tcp:${gw}:80") 12 | Out-Null
    Run-Adb @('forward','tcp:28080',"tcp:${gw}:8080") 12 | Out-Null
    Run-Adb @('forward','tcp:28000',"tcp:${gw}:8000") 12 | Out-Null
    Write-Output ("SSH 22    : " + (Test-PortFast 2222 $false))
    Write-Output ("VNC 5900  : " + (Test-PortFast 25900 $false))
    Write-Output ("HTTP 80   : " + (Test-PortFast 2280 $true))
    Write-Output ("HTTP 8080 : " + (Test-PortFast 28080 $true))
    Write-Output ("HTTP 8000 : " + (Test-PortFast 28000 $true))
  }
}
function Try-Connect($ssid, $sec, $pass) {
  Write-Output "##### connect $ssid ($sec) #####"
  if ($pass) { Run-Adb @('shell',"cmd wifi connect-network $ssid $sec $pass") 20 | Out-Null }
  else { Run-Adb @('shell',"cmd wifi connect-network $ssid $sec") 20 | Out-Null }
  for ($i=0; $i -lt 8; $i++) {
    Start-Sleep -Seconds 2
    $st = Run-Adb @('shell','cmd wifi status') 15
    $line = ($st | Select-String 'Wifi is connected to').Line
    if ($line -match [regex]::Escape($ssid)) { Write-Output "connected ($i)"; return $true }
    if ($line -match 'Wifi is connected') {
      if ($pass) { Run-Adb @('shell',"cmd wifi connect-network $ssid $sec $pass") 20 | Out-Null }
      else { Run-Adb @('shell',"cmd wifi connect-network $ssid $sec") 20 | Out-Null }
    }
  }
  return $false
}
if (Try-Connect 'HW-9E00C2F4' 'wpa2' 'hiwonder') { Probe-Network 'HW-9E00C2F4' }
elseif (Try-Connect 'HW-24353859' 'open' $null) { Probe-Network 'HW-24353859' }
else { Write-Output "BOTH FAILED" }
Write-Output "=== final wifi ==="
$st2 = Run-Adb @('shell','cmd wifi status') 15
($st2 | Select-String 'Wifi is connected to').Line
