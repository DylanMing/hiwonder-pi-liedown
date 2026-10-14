# hotspot_on.ps1 — 开启 Windows 移动热点（RobotLink）
# 用法：powershell -File hotspot_on.ps1
# 注意：热点跟随"当前联网的 WiFi"共享；若 ConfigureAccessPointAsync 后热点变 Off，
#       再跑一遍本脚本（StartTetheringAsync）即可
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]
$null = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime]

$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() |
    Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
                   $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
Function Await($WinRtTask, $ResultType) {
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    $netTask.Result
}

$profile = [Windows.Networking.Connectivity.NetworkInformation]::GetInternetConnectionProfile()
if ($null -eq $profile) { Write-Host "没有联网的 WiFi 配置（VPN 独占时会这样）——先恢复普通联网再开热点" -ForegroundColor Red; exit 1 }
$manager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager]::CreateFromConnectionProfile($profile)

# 只在 Off 时开启（On/Off 都不动）
if ($manager.TetheringOperationalState -eq 'On') {
    Write-Host "热点已经开着 ✓" -ForegroundColor Green
} else {
    $r = Await ($manager.StartTetheringAsync()) ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult])
    Write-Host ("启动结果: " + $r.Status)
}
$cfg = Await ($manager.GetCurrentAccessPointConfiguration()) ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringAccessPointConfiguration])
Write-Host ("SSID: " + $cfg.Ssid + "   网关: 192.168.137.1")
