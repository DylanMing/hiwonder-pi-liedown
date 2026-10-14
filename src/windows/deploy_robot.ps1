# deploy_robot.ps1 — 一键部署：脚本 + systemd 服务到指定机器人
# 用法：powershell -File deploy_robot.ps1 [-RobotIP 192.168.137.172]
# 前提：该机器人已种好本机公钥（见 部署手册 第三章）
param([string]$RobotIP = "192.168.137.172")
$KIT = $PSScriptRoot          # 工具目录（src/windows）
$SRC = Join-Path $KIT ".."    # 源码根（src/）
$ErrorActionPreference = "Stop"

Write-Host "== [1/4] 推送控制脚本到 $RobotIP ==" -ForegroundColor Cyan
scp -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new `
    (Join-Path $SRC "fall.py") (Join-Path $SRC "stand.py") `
    (Join-Path $SRC "fall_demo.py") (Join-Path $SRC "fall_server.py") `
    "pi@$RobotIP`:/home/pi/"
if ($LASTEXITCODE -ne 0) { throw "scp 失败：检查 IP / 公钥 / 机器人在线" }

Write-Host "== [2/4] 安装 systemd 服务（开机自启+崩溃自动重启）=="
scp (Join-Path $KIT "..\..\deploy\fall-server.service") "pi@$RobotIP`:/tmp/"
ssh pi@$RobotIP "sudo cp /tmp/fall-server.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable --now fall-server"
if ($LASTEXITCODE -ne 0) { throw "systemd 安装失败" }

Write-Host "== [3/4] 等服务上线 =="
Start-Sleep -Seconds 4
$active = ssh pi@$RobotIP "systemctl is-active fall-server"
Write-Host ("   fall-server: " + $active)

Write-Host "== [4/4] HTTP 健康检查 =="
curl.exe -s -m 5 "http://${RobotIP}:8090/status"
Write-Host ""
if ($active -eq "active") { Write-Host "部署完成 ✓  (IP: $RobotIP)" -ForegroundColor Green }
else { Write-Host "服务未激活，手动检查: ssh pi@$RobotIP systemctl status fall-server" -ForegroundColor Red }
