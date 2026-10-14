[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=30) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
function Test-Banner($port) {
  $c = New-Object System.Net.Sockets.TcpClient
  $ar = $c.BeginConnect('127.0.0.1',$port,$null,$null)
  if ($ar.AsyncWaitHandle.WaitOne(4000) -and $c.Connected) {
    $s = $c.GetStream(); $s.ReadTimeout = 4000
    $buf = New-Object byte[] 128
    try { $n = $s.Read($buf,0,128); return ("BANNER: " + ([Text.Encoding]::ASCII.GetString($buf,0,$n)).Trim()) } catch { return "connected but no banner" }
  } else { return "PORT CLOSED/UNREACHABLE" }
  $c.Close()
}
Write-Output "=== [0] scan results (phone view) ==="
Run-Adb @('shell','cmd wifi start-scan') 10 | Out-Null
Start-Sleep -Seconds 4
Run-Adb @('shell','cmd wifi list-scan-results') 15 | Select-String 'HW-'
foreach ($ssid in @('HW-24353859','HW-9E00C2F4')) {
  Write-Output ""
  Write-Output "########## PROBING $ssid ##########"
  Run-Adb @('forward','--remove','tcp:2222') 10 | Out-Null
  Run-Adb @('shell',"cmd wifi connect-network $ssid wpa2 hiwonder") 20 | Out-Null
  $connected = $false
  for ($i=0; $i -lt 9; $i++) {
    Start-Sleep -Seconds 2
    $st = Run-Adb @('shell','cmd wifi status') 15
    $line = ($st | Select-String 'Wifi is connected to').Line
    Write-Output ("  poll$i : $line")
    if ($line -match [regex]::Escape($ssid)) { $connected = $true; break }
    if ($line -match 'Wifi is connected') { Run-Adb @('shell',"cmd wifi connect-network $ssid wpa2 hiwonder") 20 | Out-Null }
  }
  if ($connected) {
    Write-Output "  === CONNECTED to $ssid, getting IP/gateway ==="
    $ipinfo = Run-Adb @('shell','ip -4 addr show wlan0') 15 | Select-String 'inet'
    $route = Run-Adb @('shell','ip route') 15 | Select-String 'default'
    Write-Output ("  phone IP: $ipinfo")
    Write-Output ("  route: $route")
    $gw = $null
    if ($route -match 'via\s+(\d+\.\d+\.\d+\.\d+)') { $gw = $Matches[1] }
    if (-not $gw) {
      $route2 = Run-Adb @('shell','ip route') 15
      if ($route2 -match 'dev wlan0 proto kernel[\s\S]*?src') { }
      if ($route2 -match '^(\d+\.\d+\.\d+\.\d+/\d+) dev wlan0') { $net = $Matches[1] }
      # try neighbor/gateway alternatives
      $neigh = Run-Adb @('shell','ip neigh') 15
      Write-Output "  neigh: $neigh"
      if ($neigh -match '(\d+\.\d+\.\d+\.\d+).*REACHABLE') { $gw = $Matches[1] }
    }
    Write-Output ("  gateway candidate: $gw")
    if ($gw) {
      Run-Adb @('forward','tcp:2222',"tcp:${gw}:22") 15 | Out-Null
      Write-Output ("  SSH test via $gw -> " + (Test-Banner 2222))
    } else { Write-Output "  no gateway found" }
  } else { Write-Output "  FAILED to stay connected to $ssid" }
}
