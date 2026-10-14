[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Output "=== [1] copy listener to C:\robot\ ==="
New-Item -ItemType Directory -Force -Path C:\robot | Out-Null
Copy-Item "\\wsl.localhost\Ubuntu-24.04\home\administrator\hiwonder\src\cb_listener.py" C:\robot\cb_listener.py -Force
Write-Output "copied"
Write-Output "=== [2] firewall allow 9000 ==="
netsh advfirewall firewall delete rule name="robot-callback-9000" | Out-Null
netsh advfirewall firewall add rule name="robot-callback-9000" dir=in action=allow protocol=TCP localport=9000 | Out-Null
Write-Output "firewall ok"
Write-Output "=== [3] start listener (detached) ==="
Get-Process python* -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq "" } | Out-Null
$existing = Get-CimInstance Win32_Process -Filter "Name='python.exe'" | Where-Object { $_.CommandLine -like "*cb_listener*" }
if ($existing) { Write-Output "listener already running (pid $($existing.ProcessId))" }
else {
  Start-Process -WindowStyle Hidden python -ArgumentList "C:\robot\cb_listener.py" `
    -RedirectStandardOutput C:\robot\listener.log -RedirectStandardError C:\robot\listener.err
  Start-Sleep -Seconds 2
  Write-Output "listener started"
}
Write-Output "=== [4] verify local ==="
curl.exe -s -m 4 http://192.168.137.1:9000/health
Write-Output ""
Get-Content C:\robot\listener.log -ErrorAction SilentlyContinue | Select-Object -First 3
