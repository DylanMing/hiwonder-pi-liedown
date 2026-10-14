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
Write-Output ("state: " + $manager.TetheringOperationalState)

$config = $manager.GetCurrentAccessPointConfiguration()
$ok = $false
try { $null = [void]$config.Ssid; $ok = $true } catch {}
if (-not $ok) { try { $config = Await ($config) ($cfgType); $ok = $true } catch { Write-Output ("await failed: " + $_.Exception.Message) } }
if ($ok) {
  Write-Output ("REAL current SSID: '" + $config.Ssid + "'")
  $config.Ssid = "RobotLink"
  $config.Passphrase = "hiwonder"
  $r = $manager.ConfigureAccessPointAsync($config)
  $done = $false
  try { $null = [void]$r.Status; $done = $true } catch {}
  if (-not $done) { try { $r = Await ($r) ($resType); $done = $true } catch { Write-Output ("cfg await failed: " + $_.Exception.Message) } }
  if ($done) { Write-Output ("configure result: " + $r.Status) }
  $v = $manager.GetCurrentAccessPointConfiguration()
  $ok2 = $false
  try { $null = [void]$v.Ssid; $ok2 = $true } catch {}
  if (-not $ok2) { try { $v = Await ($v) ($cfgType); $ok2 = $true } catch {} }
  if ($ok2) { Write-Output ("VERIFY SSID: '" + $v.Ssid + "'") }
} else {
  Write-Output "could not obtain config object"
}
Write-Output ("final state: " + $manager.TetheringOperationalState)
