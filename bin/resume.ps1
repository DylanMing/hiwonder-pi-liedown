[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$adb = "C:\Users\Public\platform-tools\adb.exe"
function Run-Adb($cmdArgs, $timeout=25) {
  $job = Start-Job -ScriptBlock { param($a, $p) & $p @a 2>&1 } -ArgumentList (,$cmdArgs), $adb
  if (Wait-Job $job -Timeout $timeout) { Receive-Job $job | ForEach-Object { Write-Output $_ } }
  else { Write-Output "TIMEOUT" }
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}
Write-Output "=== [1] phone still authorized? ==="
Run-Adb @('devices') 15
Write-Output "=== [2] is robot AP broadcasting? ==="
Run-Adb @('shell','cmd wifi start-scan') 10 | Out-Null
Start-Sleep -Seconds 4
Run-Adb @('shell','cmd wifi list-scan-results') 15 | Select-String 'HW-'
