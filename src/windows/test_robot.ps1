# test_robot.ps1 — 全链路验收：HTTP 摔倒 → 回调 → 起立（机器人会真实运动！周围留空间）
# 用法：powershell -File test_robot.ps1 [-RobotIP 192.168.137.172]
param([string]$RobotIP = "192.168.137.172")
$cb = "http://192.168.137.1:9000/robot-callback"
Write-Host "== [1/3] 摔倒（观察机器人！）==" -ForegroundColor Cyan
Invoke-RestMethod -Method Post -Uri "http://${RobotIP}:8090/fall" -ContentType "application/json" `
    -Body ('{"callback_url":"' + $cb + '","request_id":"accept-test-fall"}') | ConvertTo-Json -Compress
Start-Sleep -Seconds 9

Write-Host "== [2/3] 起立 =="
Invoke-RestMethod -Method Post -Uri "http://${RobotIP}:8090/stand" -ContentType "application/json" `
    -Body ('{"callback_url":"' + $cb + '","request_id":"accept-test-stand"}') | ConvertTo-Json -Compress
Start-Sleep -Seconds 9

Write-Host "== [3/3] 终态与回执 =="
$s = Invoke-RestMethod "http://${RobotIP}:8090/status"
Write-Host ("   pose=" + $s.pose + "  last ok=" + $s.last_action.ok)
if (Test-Path C:\robot\listener.log) {
    Write-Host "   --- 本机收到的回调 ---"
    Get-Content C:\robot\listener.log -Tail 6 | Select-String "event=|robot_ip"
}
Write-Host ("验收结论: pose=" + $s.pose + " —— 机器人是否真动了请以肉眼为准（软件绿≠物理动）") -ForegroundColor Yellow
