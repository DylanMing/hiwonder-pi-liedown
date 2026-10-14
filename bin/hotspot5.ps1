[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$mgrType = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime]
$profile = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::GetInternetConnectionProfile()
$manager = $mgrType::CreateFromConnectionProfile($profile)
Write-Output ("initial state: " + $manager.TetheringOperationalState)

# attempt: generic method inference on AsTask
$ssidSet = $false
try {
  $task = [System.WindowsRuntimeSystemExtensions]::AsTask($manager.GetCurrentAccessPointConfiguration())
  $task.Wait(5000) | Out-Null
  $config = $task.Result
  Write-Output ("current SSID: '" + $config.Ssid + "'")
  $config.Ssid = "RobotLink"
  $config.Passphrase = "hiwonder"
  $t2 = [System.WindowsRuntimeSystemExtensions]::AsTask($manager.ConfigureAccessPointAsync($config))
  $t2.Wait(5000) | Out-Null
  Write-Output ("configure: " + $t2.Result.Status + " " + $t2.Result.AdditionalErrorMessage)
  $t3 = [System.WindowsRuntimeSystemExtensions]::AsTask($manager.GetCurrentAccessPointConfiguration())
  $t3.Wait(5000) | Out-Null
  Write-Output ("VERIFIED SSID: '" + $t3.Result.Ssid + "'")
  $ssidSet = $true
} catch { Write-Output ("AsTask inference failed: " + $_.Exception.Message) }

# disable auto-off via async method
try {
  $t4 = [System.WindowsRuntimeSystemExtensions]::AsTask($manager.DisableNoConnectionsTimeoutAsync())
  $t4.Wait(5000) | Out-Null
  Write-Output "auto-off timer DISABLED"
} catch { Write-Output ("disable timeout failed: " + $_.Exception.Message) }

# (re)start hotspot
if ($manager.TetheringOperationalState -ne 'On') {
  try {
    $t5 = [System.WindowsRuntimeSystemExtensions]::AsTask($manager.StartTetheringAsync())
    $t5.Wait(15000) | Out-Null
    Write-Output ("start: " + $t5.Result.Status)
  } catch { Write-Output ("start failed: " + $_.Exception.Message) }
}
Write-Output ("final state: " + $manager.TetheringOperationalState)
Write-Output ("timeout enabled (true=will auto-off): " + $manager.IsNoConnectionsTimeoutEnabled())
