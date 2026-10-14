[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=30) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== relay.sh content ==="
Run-Adb @('shell','cat /data/local/tmp/relay.sh') 15
Write-Output "=== relay processes now ==="
Run-Adb @('shell','ps -A -o PID,PPID,ARGS | grep -E "relay|nc |netcat" | grep -v grep || echo NONE') 15
Write-Output "=== foreground test (3s) ==="
Run-Adb @('shell','timeout 3 sh /data/local/tmp/relay.sh 2>&1 | head -5; echo FOREGROUND_DONE') 20
Write-Output "=== listener after foreground test? ==="
Run-Adb @('shell','ss -tln | grep 8022 || echo NO_LISTENER') 15
