[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
Function Await($WinRtTask, $ResultType) {
  $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
  $netTask = $asTask.Invoke($null, @($WinRtTask))
  $netTask.Wait(-1) | Out-Null
  $netTask.Result
}
[Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime] | Out-Null
[Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationalState,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime] | Out-Null

$profile = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::GetInternetConnectionProfile()
if ($null -eq $profile) { Write-Output "ERROR: no internet connection profile (VPN may own it)"; exit 1 }
Write-Output ("internet profile: " + $profile.ProfileName)

$manager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager]::CreateFromConnectionProfile($profile)
$config = Await ($manager.GetCurrentAccessPointConfiguration()) ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringConfiguration])
Write-Output ("current hotspot: SSID=" + $config.Ssid + "  clients(max)=" + $config.ClientCount + "/" + $config.MaxClientCount)

# set a stable SSID/password
$config.Ssid = "RobotLink"
$config.Passphrase = "hiwonder"
Await ($manager.ConfigureAccessPointAsync($config)) ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult]) | Out-Null
Write-Output "hotspot configured: SSID=RobotLink password=hiwonder"

# current state
Write-Output ("tethering state: " + $manager.TetheringOperationalState)

if ($manager.TetheringOperationalState -ne 'On') {
  $result = Await ($manager.StartTetheringAsync()) ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult])
  Write-Output ("start result: " + $result.Status + "  " + $result.AdditionalErrorMessage)
  if ($result.Status -eq [Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationStatus]::Success) { Write-Output "HOTSPOT STARTED" }
} else {
  Write-Output "HOTSPOT ALREADY ON"
}
Start-Sleep -Seconds 3
Write-Output "=== final state ==="
Write-Output ($manager.TetheringOperationalState)
Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceAlias -match 'Local Area|本地连接|WSL|Microsoft Wi-Fi Direct' } | ForEach-Object { Write-Output ($_.InterfaceAlias + "  " + $_.IPAddress) }
Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object { Write-Output ("UP: " + $_.Name + " [" + $_.InterfaceDescription + "]") }
