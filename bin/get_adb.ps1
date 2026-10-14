[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$zip = "C:\Users\Public\platform-tools.zip"
$dst = "C:\Users\Public"
if (-not (Test-Path "$dst\platform-tools\adb.exe")) {
  Write-Output "downloading platform-tools..."
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest -Uri "https://dl.google.com/android/repository/platform-tools-latest-windows.zip" -OutFile $zip -UseBasicParsing
  Write-Output ("downloaded: " + (Get-Item $zip).Length + " bytes")
  Expand-Archive -Path $zip -DestinationPath $dst -Force
  Write-Output "extracted"
} else { Write-Output "platform-tools already present" }
& "$dst\platform-tools\adb.exe" version
Write-Output "=== adb devices ==="
& "$dst\platform-tools\adb.exe" kill-server 2>&1 | Out-Null
& "$dst\platform-tools\adb.exe" start-server 2>&1 | Out-Null
& "$dst\platform-tools\adb.exe" devices -l
