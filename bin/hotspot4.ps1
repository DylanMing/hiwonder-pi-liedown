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
$profile = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::GetInternetConnectionProfile()
$manager = $mgrType::CreateFromConnectionProfile($profile)
Write-Output ("state: " + $manager.TetheringOperationalState)

# resolve result type from the runtime async-op object
$op = $null
try { $op = $manager.GetCurrentAccessPointConfiguration() } catch { Write-Output ("GetCurrentAccessPointConfiguration call failed: " + $_.Exception.Message) }
if ($op) {
  $iface = $op.GetType().GetInterfaces() | Where-Object { $_.Name -like 'IAsyncOperation*' -and $_.IsGenericType } | Select-Object -First 1
  if ($iface) {
    $cfgType = $iface.GetGenericArguments()[0]
    Write-Output ("runtime type: " + $cfgType.FullName)
    $config = Await ($op) ($cfgType)
    Write-Output ("current SSID: '" + $config.Ssid + "'")
    $config.Ssid = "RobotLink"
    $config.Passphrase = "hiwonder"
    $op2 = $manager.ConfigureAccessPointAsync($config)
    $iface2 = $op2.GetType().GetInterfaces() | Where-Object { $_.Name -like 'IAsyncOperation*' -and $_.IsGenericType } | Select-Object -First 1
    $r = Await ($op2) ($iface2.GetGenericArguments()[0])
    Write-Output ("configure: " + $r.Status + " " + $r.AdditionalErrorMessage)
    $config3 = Await ($manager.GetCurrentAccessPointConfiguration()) ($cfgType)
    Write-Output ("VERIFIED SSID: '" + $config3.Ssid + "'")
  } else { Write-Output "no generic IAsyncOperation iface on op object" }
}
# keep hotspot always on (disable auto-off when no clients)
try { $manager.DisableNoConnectionsTimeout(); Write-Output ("NoConnectionsTimeout (auto-off) now: " + $manager.IsNoConnectionsTimeoutEnabled()) } catch { Write-Output ("DisableNoConnectionsTimeout failed: " + $_.Exception.Message) }
Write-Output ("final state: " + $manager.TetheringOperationalState)
