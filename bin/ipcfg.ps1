[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch 'Loopback' } | ForEach-Object { Write-Output ($_.InterfaceAlias + "  " + $_.IPAddress + "/" + $_.PrefixLength + "  " + $_.AddressState) }
Write-Output "--- WSL mode ---"
$wslconf = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss" -ErrorAction SilentlyContinue
if ($wslconf) { $wslconf | Format-List | Out-String }
