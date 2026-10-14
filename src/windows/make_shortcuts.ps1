# make_shortcuts.ps1 — 为一台机器人生成桌面快捷方式（.cmd 文件）
# 用法：powershell -File make_shortcuts.ps1 [-RobotIP 192.168.137.172] [-Prefix 机器人2]
param(
    [string]$RobotIP = "192.168.137.172",
    [string]$Prefix  = "机器人2"     # 快捷方式名前缀（另一台用 机器人）
)
$desk = "C:\Users\Public\Desktop"
$sshOpts = "-o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new"

# 摔倒（SSH 直控）
"ssh $sshOpts pi@$RobotIP `"python3 /home/pi/fall.py`"`npause" |
    Out-File "$desk\$Prefix-摔倒.cmd" -Encoding ascii
# 起立
"ssh $sshOpts pi@$RobotIP `"python3 /home/pi/stand.py`"`npause" |
    Out-File "$desk\$Prefix-起立.cmd" -Encoding ascii
# 状态
"ssh $sshOpts pi@$RobotIP `"uptime; ip -4 addr show wlan0 | grep inet`"`npause" |
    Out-File "$desk\$Prefix-状态.cmd" -Encoding ascii
# HTTP 摔倒（带回调）
$body = '{\"callback_url\":\"http://192.168.137.1:9000/robot-callback\"}'
"powershell -NoProfile -Command `"Invoke-RestMethod -Method Post -Uri http://${RobotIP}:8090/fall -ContentType 'application/json' -Body '$body' | ConvertTo-Json -Compress`"`npause" |
    Out-File "$desk\$Prefix-HTTP摔倒.cmd" -Encoding ascii

Write-Host "已生成 4 个快捷方式（$Prefix-*，指向 $RobotIP）✓" -ForegroundColor Green
Write-Host "回调监视窗口是全局共用一个（机器人-回调监视），不用每台建"
