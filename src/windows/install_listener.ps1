# install_listener.ps1 — 在 Windows 上部署回调接收器（cb_listener）
# 用法：powershell -File install_listener.ps1 [-Install]
# 加 -Install 参数：复制文件+建防火墙规则+启动；不加参数仅启动
param([switch]$Install)
$dst = "C:\robot"
if ($Install) {
    Write-Host "== [1/3] 复制 cb_listener.py 到 $dst ==" -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    Copy-Item (Join-Path $PSScriptRoot "..\cb_listener.py") $dst -Force
    Write-Host "== [2/3] 防火墙放行 TCP 9000 =="
    $rule = netsh advfirewall firewall show rule name="robot-callback-9000" 2>$null
    if (-not $rule) { netsh advfirewall firewall add rule name="robot-callback-9000" dir=in action=allow protocol=TCP localport=9000 | Out-Null }
    Write-Host "== [3/3] 启动（隐藏窗口）=="
}
# 杀旧实例再启动，避免端口占用
Get-CimInstance Win32_Process -Filter "Name like 'python%'" 2>$null |
    Where-Object { $_.CommandLine -like "*cb_listener*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Process -WindowStyle Hidden python -ArgumentList "$dst\cb_listener.py"
Start-Sleep -Seconds 2
try {
    $h = Invoke-RestMethod http://127.0.0.1:9000/health -TimeoutSec 3
    Write-Host ("listener 在线 ✓  " + ($h | ConvertTo-Json -Compress)) -ForegroundColor Green
} catch { Write-Host "listener 健康检查失败，查日志: $dst\listener.log" -ForegroundColor Red }
