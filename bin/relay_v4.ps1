[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=30) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Run-Adb @('push','\\wsl.localhost\Ubuntu-24.04\home\administrator\hiwonder\bin\relay.sh','/data/local/tmp/relay.sh') 20
Write-Output "=== clean kill ==="
Run-Adb @('shell','sh /data/local/tmp/kill_relay_v2.sh 2>/dev/null | tail -2') 30
Write-Output "=== launch with retry (up to 3) ==="
$up = $false
for ($i=1; $i -le 3; $i++) {
  Run-Adb @('shell',"setsid sh /data/local/tmp/relay.sh </dev/null >/data/local/tmp/relay.log 2>&1 & sleep 3; echo try-$i") 20
  $chk = Run-Adb @('shell','ss -tln | grep 8022') 15
  if ("$chk" -match 'LISTEN') { Write-Output "LISTENER UP on try $i"; $up = $true; break }
  Write-Output "try $i no listener, retrying..."
}
if ($up) {
  Write-Output "=== SSH chain test from WSL2 ==="
}
