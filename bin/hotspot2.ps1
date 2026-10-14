[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
Function Await($WinRtTask, $ResultType) {
  $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
  $netTask = $asTask.Invoke($null, @($WinRtTask))
  $netTask.Wait(-1) | Out-Null
  $netTask.Result
}
$mgrType = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime]
# derive config type via reflection (avoids the failing type literal)
$cfgType = $mgrType.GetMethod('GetCurrentAccessPointConfiguration').ReturnType.GetGenericArguments()[0]
Write-Output ("cfgType = " + $cfgType.FullName)

$profile = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::GetInternetConnectionProfile()
$manager = $mgrType::CreateFromConnectionProfile($profile)
Write-Output ("state: " + $manager.TetheringOperationalState)
try {
  $config = Await ($manager.GetCurrentAccessPointConfiguration()) ($cfgType)
  Write-Output ("CURRENT hotspot SSID: '" + $config.Ssid + "'")
  Write-Output ("band: " + $config.Band)
} catch { Write-Output ("read config failed: " + $_.Exception.Message) }
Write-Output "=== scan for own hotspot ==="
(netsh wlan show networks | Select-String -Pattern 'SSID \d+ : ')
Write-Output "=== all Up adapters with IPv4 ==="
Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
  $ips = (Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | ForEach-Object { $_.IPAddress }) -join ','
  Write-Output ($_.Name + "  [" + $_.InterfaceDescription + "]  IP:" + $ips)
}
