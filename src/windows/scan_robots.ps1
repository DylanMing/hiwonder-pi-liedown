# scan_robots.ps1 — 扫描 192.168.137.0/24 找在线的机器人
# 用法：powershell -File scan_robots.ps1
# 原理：TCP 连 22 端口收 banner，认 "SSH-2.0-OpenSSH ... Debian"（防热点幻影连接误报）
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$found = @()
foreach ($i in 1..254) {
    $ip = "192.168.137.$i"
    $tc = New-Object System.Net.Sockets.TcpClient
    $ar = $tc.BeginConnect($ip, 22, $null, $null)
    if ($ar.AsyncWaitHandle.WaitOne(280) -and $tc.Connected) {
        $tc.ReceiveTimeout = 700
        try {
            $buf = New-Object byte[] 60
            $n = $tc.GetStream().Read($buf, 0, 60)
            $b = [System.Text.Encoding]::ASCII.GetString($buf, 0, $n).Trim()
            if ($b -like "*Debian*") {
                Write-Host "  找到机器人: $ip  ($b)" -ForegroundColor Green
                $found += $ip
            }
        } catch {}
    }
    $tc.Close()
}
if ($found.Count -eq 0) { Write-Host "没找到机器人（检查：机器人开机没？热点开了没？）" -ForegroundColor Red }
else { Write-Host ("合计: " + $found.Count + " 台 -> " + ($found -join ', ')) }
