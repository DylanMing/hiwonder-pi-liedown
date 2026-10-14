# fix_robot.ps1 — 机器人网络与时钟体检/调优（WiFi 优先级 + 兜底热点 + 时钟校准）
# 用法：powershell -File fix_robot.ps1 [-RobotIP 192.168.137.172] [-ApName HW-BACKUP2]
param(
    [string]$RobotIP = "192.168.137.172",
    [string]$ApName  = "HW-BACKUP2"    # 该机器人自己的兜底热点名（每台不同）
)
Write-Host "== [1/3] WiFi 优先级调优 ==" -ForegroundColor Cyan
ssh pi@$RobotIP "sudo nmcli con modify RobotLink connection.autoconnect yes connection.autoconnect-priority 20"
ssh pi@$RobotIP "nmcli -f NAME,AUTOCONNECT,AUTOCONNECT-PRIORITY con show"

Write-Host "== [2/3] 兜底热点（RobotLink 消失时自建 WiFi，密码 hiwonder）=="
$apCheck = ssh pi@$RobotIP "nmcli con show $ApName 2>/dev/null | head -1"
if (-not $apCheck) {
    ssh pi@$RobotIP "sudo nmcli con add type wifi con-name $ApName ifname wlan0 ssid $ApName 802-11-wireless.mode ap 802-11-wireless.band a 802-11-wireless.channel 36 wifi-sec.key-mgmt wpa-psk wifi-sec.psk hiwonder ipv4.method shared; sudo nmcli con modify $ApName connection.autoconnect-priority 1"
} else { Write-Host "   兜底热点 $ApName 已存在" }

Write-Host "== [3/3] 时钟校准（本机时间写入机器人）=="
$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
ssh pi@$RobotIP "sudo date -s '$now' >/dev/null && sudo hwclock --systohc 2>/dev/null; date '+校准后: %F %T'"
Write-Host "调优完成 ✓" -ForegroundColor Green
