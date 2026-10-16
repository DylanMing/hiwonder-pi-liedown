# TonyPi 双机器人 HTTP 控制系统

> 两台幻尔 TonyPi 人形机器人（各 18 舵机）的摔倒/起立控制与远程触发体系：
> **HTTP 触发 → 机器人执行 → 回调通知** 全闭环，双机同网，带硬件诊断方法论。

## 系统架构

```
                 ┌────────────── Windows 笔记本（操作入口）──────────────┐
                 │  移动热点 RobotLink/hiwonder ──→ 网关 192.168.137.1    │
                 │  cb_listener.py :9000 ←── 收机器人回执 → listener.log │
                 │  WSL2 = 本仓库（开发/文档；路由不通，操作走 Windows）  │
                 └───────────────┬──────────────────────┬───────────────┘
                                 │                      │
                            ┌────▼─────┐          ┌─────▼────┐
                            │ 1号 .72  │          │ 2号 .172 │
                            └──────────┘          └──────────┘
                       每台：fall_server.py (Flask :8090, systemd 常驻)
                       WiFi：RobotLink 优先级 20 > 自家兜底热点 1
```

## 核心特性

- **HTTP 闭环**：`POST /fall`、`POST /stand`（202 异步 + 后台执行 + 完成回调 3 次重试）
- **姿态状态机**：`GET /status`；躺着再摔返回 409，不假装执行
- **双机区分**：回调自带 `robot_ip` 字段，一台监听器管一个舰队
- **自愈能力**：systemd 开机自启 + 崩溃自动重启；WiFi 分优先级自动重连 + 兜底热点
- **一键部署**：7 个参数化 PowerShell 工具（扫描/部署/调优/验收），换新机器人约 10 分钟
- **硬件急诊**：诊断脚本 + 判读表（哔声 → IMU → 裸串口 → 重插排座）

## 快速开始

```powershell
# 1. 开热点
powershell -File C:\robot\kit\windows\hotspot_on.ps1
# 2. 扫描在线机器人
powershell -File C:\robot\kit\windows\scan_robots.ps1
# 3. 摔倒（带回调，机器人会真实运动！）
Invoke-RestMethod -Method Post -Uri http://192.168.137.72:8090/fall -ContentType "application/json" -Body '{"callback_url":"http://192.168.137.1:9000/robot-callback"}'
# 4. 看回执
Get-Content C:\robot\listener.log -Tail 10
```

> 从零部署/换新机器人：看 **[部署手册.md](部署手册.md)**（不依赖 AI，照做即可）。

## 仓库结构

```
├── NOTES.md              主文档：日常使用 + 运维 + 踩坑速查
├── HTTP触发方案.md        HTTP 协议设计文档（API/回调格式/各终端 curl 规则）
├── 部署手册.md            从裸机到完整系统的分章部署手册
├── src/
│   ├── fall_server.py    机器人侧 HTTP 服务（Flask :8090）
│   ├── cb_listener.py    PC 侧回调接收器（标准库 :9000）
│   ├── fall.py / stand.py / fall_demo.py    SSH 直控脚本
│   ├── diagnostics/      硬件诊断脚本 + 判读表（README）
│   └── windows/          7 个 PC 侧工具（扫描/部署/调优/验收…）
├── deploy/               systemd 单元（fall-server.service）
└── bin/                  历史一次性脚本（手机桥接时代遗物，考古用）
```

## 硬件急诊卡（"软件全绿但机器人不动"）

```
1. 听开机"哔"声     没哔 → MCU 没上电 → 查电池，整机断电 15 秒
2. imu_retry.py     None → 走第 3 步；有数据 → 查软件
3. raw_serial_test  静默 → 40 针排座松动 → 断电重插树莓派（实测案例）
铁律：回调 ok=True 只证明脚本跑完；IMU 重力向量翻转才是"真动了"的物证
```

## 精华坑（详见 NOTES.md 踩坑表）

| 坑 | 一句话解法 |
|---|---|
| PowerShell 5.1 吞 curl JSON 引号 | 用 `Invoke-RestMethod` |
| WSL2 连不上 192.168.137.x | VPN 路由，操作全走 Windows 侧 |
| 躺着执行 lie_down 不动 | 动作组是绝对姿态；先看 /status |
| 机器人时间倒退 | 无硬件时钟，崩溃断电后手动校准 |
| 机器人连不上热点 | 只支持 2.4GHz / 低段 5GHz 信道 |

## 硬件与凭据

- TonyPi（HiWonder）：Debian 12 · Pi 5 · 18 总线舵机 · 扩展板 MCU（串口 1Mbaud）
- 出厂凭据（公开默认值，非机密）：SSH `pi/raspberrypi`，热点密码 `hiwonder`
- 真实密钥均已 `.gitignore` 排除，不入库
