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
Write-Output "--- methods available on manager type ---"
$mgrType.GetMethods() | ForEach-Object { Write-Output $_.Name } | Sort-Object -Unique
$profile = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::GetInternetConnectionProfile()
$manager = $mgrType::CreateFromConnectionProfile($profile)
Write-Output ("state: " + $manager.TetheringOperationalState)
$m1 = $mgrType.GetMethods() | Where-Object { $_.Name -eq 'GetCurrentAccessPointConfiguration' } | Select-Object -First 1
if ($m1 -and $m1.ReturnType.GetGenericArguments().Count -gt 0) {
  $cfgType = $m1.ReturnType.GetGenericArguments()[0]
  Write-Output ("cfgType resolved: " + $cfgType.FullName)
  $config = Await ($manager.GetCurrentAccessPointConfiguration()) ($cfgType)
  Write-Output ("current SSID: '" + $config.Ssid + "'")
  $config.Ssid = "RobotLink"
  $config.Passphrase = "hiwonder"
  $m2 = $mgrType.GetMethods() | Where-Object { $_.Name -eq 'ConfigureAccessPointAsync' } | Select-Object -First 1
  $resType = $m2.ReturnType.GetGenericArguments()[0]
  $r = Await ($manager.ConfigureAccessPointAsync($config)) ($resType)
  Write-Output ("configure result: " + $r.Status + " " + $r.AdditionalErrorMessage)
  # verify
  $config2 = Await ($manager.GetCurrentAccessPointConfiguration()) ($cfgType)
  Write-Output ("AFTER: SSID='" + $config2.Ssid + "' (password set to 'hiwonder')")
} else {
  Write-Output "REFLECTION FAILED - user must read SSID from Settings"
}
