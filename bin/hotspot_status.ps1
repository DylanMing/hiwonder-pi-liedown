[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$mgrType = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime]
$profile = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::GetInternetConnectionProfile()
if ($null -eq $profile) { Write-Output "no internet profile"; exit }
$manager = $mgrType::CreateFromConnectionProfile($profile)
Write-Output ("hotspot state: " + $manager.TetheringOperationalState)
Write-Output ("PC internet via: " + $profile.ProfileName)
