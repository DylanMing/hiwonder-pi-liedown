[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=20) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== phone IP on new AP ==="
Run-Adb @('shell','ip -4 addr show wlan0') 15 | Select-String 'inet'
Write-Output "=== routes ==="
Run-Adb @('shell','ip route') 15
Write-Output "=== neighbors ==="
Run-Adb @('shell','ip neigh') 15
Write-Output "=== ping 10.42.0.1 (NetworkManager-style gateway) ==="
Run-Adb @('shell','ping -c 2 -W 2 10.42.0.1') 20 | Select-String 'bytes from|packet loss'
Write-Output "=== ping 192.168.149.1 (HiWonder-standard gateway) ==="
Run-Adb @('shell','ping -c 2 -W 2 192.168.149.1') 20 | Select-String 'bytes from|packet loss'
