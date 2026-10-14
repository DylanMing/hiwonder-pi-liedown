[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=15) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== which nc ==="
Run-Adb @('shell','which nc; ls -la /system/bin/nc 2>/dev/null; toybox nc --help 2>&1 | head -5') 15
Write-Output "=== /dev/tcp support (mksh)? ==="
Run-Adb @('shell','exec 3<>/dev/tcp/192.168.149.1/22 && echo TCP_SUPPORT_OK; cat <&3 | head -c 40') 15
Write-Output "=== current wifi still on robot? ==="
$st = Run-Adb @('shell','cmd wifi status') 15
($st | Select-String 'Wifi is connected to').Line
