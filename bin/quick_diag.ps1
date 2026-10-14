[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=20) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== phone wifi ==="
$st = Run-Adb @('shell','cmd wifi status') 15
($st | Select-String 'Wifi is connected to').Line
Write-Output "=== ping robot ==="
Run-Adb @('shell','ping -c 2 -W 2 192.168.149.1') 20 | Select-String 'bytes from|packet loss'
Write-Output "=== relay processes (count & identity) ==="
Run-Adb @('shell','ps -A -o PID,PPID,ARGS | grep -E "relay.sh|nc " | grep -v grep || echo NO_RELAY') 15
Write-Output "=== relay.log tail ==="
Run-Adb @('shell','tail -5 /data/local/tmp/relay.log 2>/dev/null; echo ---end---') 15
