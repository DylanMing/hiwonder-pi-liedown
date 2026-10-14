[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=30) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Run-Adb @('push','\\wsl.localhost\Ubuntu-24.04\home\administrator\hiwonder\bin\relay_test.sh','/data/local/tmp/relay_test.sh') 20
Run-Adb @('shell','sh /data/local/tmp/relay_test.sh') 30
