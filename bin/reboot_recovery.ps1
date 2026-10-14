[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=25) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== [1] phone ADB state ==="
Run-Adb @('devices') 15
Write-Output "=== [2] scan robot APs ==="
Run-Adb @('shell','cmd wifi start-scan') 10 | Out-Null
Start-Sleep -Seconds 5
$scan = Run-Adb @('shell','cmd wifi list-scan-results') 20 | Select-String 'HW-'
$scan
$ssid = 'HW-9E00B2EB'
$sec = 'open'; $pass = $null
if ($scan -match 'WPA') { $sec = 'wpa2'; $pass = 'hiwonder' }
Write-Output ">>> plan: connect $ssid ($sec)"
Write-Output "=== [3] phone wifi now ==="
$st = Run-Adb @('shell','cmd wifi status') 15
$line = ($st | Select-String 'Wifi is connected to').Line
Write-Output $line
if ($line -notmatch $ssid) {
  Write-Output ">>> forcing connect..."
  if ($pass) { Run-Adb @('shell',"cmd wifi connect-network $ssid $sec $pass") 20 | Out-Null }
  else { Run-Adb @('shell',"cmd wifi connect-network $ssid $sec") 20 | Out-Null }
  Start-Sleep -Seconds 6
  $st = Run-Adb @('shell','cmd wifi status') 15
  ($st | Select-String 'Wifi is connected to').Line
}
Write-Output "=== [4] phone IP -> robot IP ==="
$ipout = Run-Adb @('shell','ip -4 addr show wlan0') 15 | Select-String 'inet'
Write-Output $ipout
$gw = $null
if ("$ipout" -match 'inet\s+(10\.42\.0|192\.168\.149)\.\d+/') { $gw = $Matches[1] + '.1' }
if (-not $gw) { $neigh = Run-Adb @('shell','ip neigh') 15; if ("$neigh" -match '(10\.42\.0\.1|192\.168\.149\.1)') { $gw = $Matches[1] } }
Write-Output ">>> robot IP: $gw"
if ($gw) {
  Run-Adb @('shell',"ping -c 2 -W 2 $gw") 20 | Select-String 'bytes from'
  Write-Output "=== [5] update relay target & launch ==="
  Run-Adb @('shell',"sed -i 's/^ROBOT=.*/ROBOT=$gw/' /data/local/tmp/relay.sh && grep ROBOT /data/local/tmp/relay.sh | head -1") 15
  Run-Adb @('shell','sh /data/local/tmp/kill_relay_v2.sh 2>/dev/null | tail -3; rm -f /data/local/tmp/relay.log; setsid sh /data/local/tmp/relay.sh </dev/null >/data/local/tmp/relay.log 2>&1 & sleep 2; echo relaunched') 30
  Run-Adb @('shell','ss -tln | grep 8022 || echo NO_LISTENER') 15
  Write-Output "=== [6] re-add adb forward ==="
  Run-Adb @('forward','tcp:2222','tcp:8022') 12
  Run-Adb @('forward','--list') 12
} else {
  Write-Output "!!! could not determine robot IP - phone not on robot network?"
}
