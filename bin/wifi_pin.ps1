[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=25) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== current wifi ==="
$st = Run-Adb @('shell','cmd wifi status') 15
($st | Select-String 'Wifi is connected to').Line
Write-Output "=== set avoid_bad_wifi=0 (stay on no-internet networks) ==="
Run-Adb @('shell','settings put global avoid_bad_wifi 0; settings get global avoid_bad_wifi') 15
Write-Output "=== force reconnect to robot AP ==="
Run-Adb @('shell','cmd wifi connect-network HW-9E00C2F4 wpa2 hiwonder') 20 | Out-Null
Start-Sleep -Seconds 6
$st = Run-Adb @('shell','cmd wifi status') 15
($st | Select-String 'Wifi is connected to').Line
Write-Output "=== ping robot ==="
Run-Adb @('shell','ping -c 2 -W 2 192.168.149.1') 20 | Select-String 'packet loss|ttl'
Write-Output "=== relay alive? ==="
Run-Adb @('shell','ps -A -o PID,ARGS | grep "relay.sh" | grep -v grep; ss -tln | grep 8022') 15
