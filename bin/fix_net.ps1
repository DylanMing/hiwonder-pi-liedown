[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=20) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== [1] phone IP & network now ==="
Run-Adb @('shell','ip -4 addr show wlan0') 15 | Select-String 'inet'
Run-Adb @('shell','ip neigh') 15 | Select-String 'REACHABLE|DELAY|STALE'
Write-Output "=== [2] ping candidates ==="
Run-Adb @('shell','ping -c 2 -W 2 10.42.0.1') 20 | Select-String 'bytes from'
Run-Adb @('shell','ping -c 2 -W 2 192.168.149.1') 20 | Select-String 'bytes from'
