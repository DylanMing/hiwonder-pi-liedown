[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=30) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT: adb $($cmdArgs -join ' ')" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== [1] current wifi ==="
$status = Run-Adb @('shell','cmd wifi status') 20
($status | Select-String 'Wifi is connected to').Line
Write-Output "=== [2] force connect to robot AP ==="
Run-Adb @('shell','cmd wifi connect-network HW-24353859 wpa2 hiwonder') 20
Start-Sleep -Seconds 10
Write-Output "=== [3] verify ==="
Run-Adb @('shell','cmd wifi status') 20 | Select-String 'Wifi is connected to|IP:'
Write-Output "=== [4] phone IP and gateway ==="
Run-Adb @('shell','ip -4 addr show wlan0') 20 | Select-String 'inet'
Run-Adb @('shell','ip route') 20 | Select-String 'default|wlan0'
