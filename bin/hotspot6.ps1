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
$cfgType = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringAccessPointConfiguration,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime]
$resType = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime]

$profile = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::GetInternetConnectionProfile()
$manager = $mgrType::CreateFromConnectionProfile($profile)
Write-Output ("initial state: " + $manager.TetheringOperationalState)

$config = Await ($manager.GetCurrentAccessPointConfiguration()) ($cfgType)
Write-Output ("current SSID: '" + $config.Ssid + "'")
$config.Ssid = "RobotLink"
$config.Passphrase = "hiwonder"
$r = Await ($manager.ConfigureAccessPointAsync($config)) ($resType)
Write-Output ("configure result: " + $r.Status)

if ($manager.TetheringOperationalState -ne 'On') {
  $r2 = Await ($manager.StartTetheringAsync()) ($resType)
  Write-Output ("start result: " + $r2.Status)
}
$config3 = Await ($manager.GetCurrentAccessPointConfiguration()) ($cfgType)
Write-Output ("FINAL: state=" + $manager.TetheringOperationalState + "  SSID='" + $config3.Ssid + "'  password='hiwonder'")
