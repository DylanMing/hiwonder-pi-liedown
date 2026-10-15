# HTTP 触发方案（摔倒/起立 + 完成回调）

> 状态：**✅ 双机部署并闭环验收通过（2026-10-14）**
> 阶段 1（无回调冒烟）✅ + 阶段 2（本机回调）✅ 均通过；阶段 3（公网回调）待定目标
> 实际部署形态与本文档假设的差异：
> - **双机器人**：1号 `192.168.137.72` / 2号 `192.168.137.172`，协议完全相同（下文示例以 1号 为例，
>   换 IP 即可控制 2号；回调里的 `robot_ip` 字段自动区分是哪台）
> - 回调接收器实跑在 **Windows 本机**（`C:\robot\cb_listener.py`，标准库版，:9000）
>   → 回调地址填 `http://192.168.137.1:9000/robot-callback`（电脑热点网关）
> - **PowerShell 触发必须用 Invoke-RestMethod**（curl.exe 传 JSON 会被 PS 5.1 剥内层引号）
> - fall_server 由 **systemd 常驻**（`fall-server.service`，开机自启+崩溃自愈）
> 姊妹文档：[NOTES.md](NOTES.md)（架构与运维）、[部署手册.md](部署手册.md)（从零部署）

---

## 一、目标

1. **触发**：任何设备发一条 HTTP 消息 → 机器人执行摔倒/起立（无需 SSH）
2. **回调**：动作完成后，机器人主动 POST 通知指定地址（含结果、耗时、姿态）
3. **非阻塞**：触发请求立即返回 202，动作后台执行，完成靠回调得知

## 二、架构

```
┌─ 触发方（同一热点下的设备）─┐          ┌──────── 机器人 192.168.43.16 ────────┐
│  电脑 / 手机 / 其他程序    │          │  fall_server.py (Flask :8090)        │
│                           │  POST    │   ├─ /fall   → 202 + 后台线程执行    │
│  curl / PowerShell / 代码 │ ───────→ │   ├─ /stand  → 202 + 后台线程执行    │
│                           │          │   └─ /status → 当前状态              │
└───────────────────────────┘          │        │ 动作完成                    │
                                      │        ↓                             │
┌─ 回调接收方（任意）───────┐  ←POST── │   requests.post(callback_url)        │
│  同网段电脑 / 公网服务器  │          │   （失败重试 3 次，结果记入 /status）│
└───────────────────────────┘          └──────────────────────────────────────┘
```

**入站/出站能力不对称（重要）**：
- **入站触发**：机器人无公网 IP（热点 NAT 后面）→ 只有**同一热点下的设备**能直接触发
- **出站回调**：机器人有蜂窝外网 → **任意公网地址**都能回调 ✅
- 外网直接触发机器人需要内网穿透（frp/Tailscale，见"扩展方向"）

## 三、API 设计

### 3.1 `POST /fall` — 触发摔倒

请求体（JSON，全部字段可选）：

| 字段 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `action` | string | `lie_down` | 动作组名（须匹配 `^[a-zA-Z0-9_]+$`，如 `bow`） |
| `callback_url` | string | 无 | 完成后回调此 URL（http/https 均可） |
| `callback_data` | any | 无 | 附带在回调里的自定义数据（原样返回） |
| `request_id` | string | 自动生成 | 请求标识，回调时带回（用于对账） |
| `force` | bool | false | 已躺着时仍强行执行（默认 409 拒绝） |

响应 `202 Accepted`：
```json
{"status": "accepted", "request_id": "fall-1697178001", "action": "lie_down", "callback": true}
```
拒绝时 `409`：`{"status": "rejected", "reason": "already lying (...)", "pose": "lying"}`
机器人忙时也 `409`：`"robot busy (action in progress)"`

### 3.2 `POST /stand` — 触发起立

| 字段 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `mode` | string | `back` | `back` 仰卧起立 / `front` 俯卧起立 / `reset` 硬回站立 |
| 其余 | — | — | 同 /fall（callback_url / callback_data / request_id / force） |

响应同 /fall 模式（含换算后的 action 名）。

### 3.3 回调（机器人 → callback_url，POST JSON）

动作完成后发出（成功失败都回调）：

```json
{
  "event": "fall_done",            // 或 "stand_done"
  "request_id": "fall-1697178001", // 触发时的 request_id
  "ok": true,                      // 动作是否成功
  "error": null,                   // 失败原因
  "action": "lie_down",
  "duration": 4.12,                // 实际耗时秒
  "pose": "lying",                 // 完成后姿态
  "robot_ip": "192.168.43.16",
  "timestamp": "2026-10-13 15:30:22",
  "data": {}                       // 触发时带的 callback_data（原样）
}
```
回调重试：超时 5 秒/次，失败间隔 1 秒重试，共 3 次；最终结果记录在 `/status`。

### 3.4 `GET /status` — 查状态

```json
{
  "busy": false,
  "pose": "standing",
  "last_action": {"mode": "stand", "action": "stand_up_back", "ok": true, "error": null, "duration": 3.8, "finished_at": "..."},
  "last_callback": {"url": "...", "ok": true, "attempt": 1, "status_code": 200, "at_time": "..."},
  "robot_ip": "192.168.43.16",
  "server_time": "2026-10-13 15:31:00"
}
```

### 3.5 状态机

```
unknown（服务刚启动，姿态未知，fall/stand 均允许）
   │ fall 成功                │ stand 成功
   ↓                          ↓
 lying ──── /stand ────→ standing
   ↑                      │
   └────── /fall ─────────┘
```
- 执行中（busy）任何新动作请求 → 409
- 重复姿态（standing 又 /fall 之外的…已站着 /stand）→ 409，`force: true` 可越过
- 服务重启后 pose 回到 unknown（不跨重启记忆）

## 四、机器人端代码（fall_server.py，完整可部署）

已核对：导入模式与实测通过的 fall.py/stand.py 完全一致（`rrc.Board()` 初始化
+ `enable_reception()` 后才可 `AGC.runActionGroup`，官方 Fall_and_Stand.py 同款）。

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fall_server.py — TonyPi HTTP 触发服务（摔倒/起立 + 完成回调）
部署: /home/pi/fall_server.py    端口: 8090
依赖: flask(已装) requests(已装) hiwonder SDK(自带)
"""
import re
import threading
import time
import socket
from datetime import datetime

from flask import Flask, request, jsonify
import requests

import hiwonder.ros_robot_controller_sdk as rrc
import hiwonder.ActionGroupControl as AGC

HOST = "0.0.0.0"
PORT = 8090
TOKEN = ""                    # 非空时要求请求头 X-Token 匹配（空=不鉴权）
ACTION_RE = re.compile(r"^[a-zA-Z0-9_]+$")   # 防路径注入
CALLBACK_TIMEOUT = 5
CALLBACK_RETRIES = 3

app = Flask(__name__)

# ---- 控制板初始化（服务启动时一次，动作前必须，与 fall.py 一致）----
print("init board ...")
board = rrc.Board()
board.enable_reception()
time.sleep(1)
print("board ready")

_lock = threading.Lock()
_state = {"busy": False, "pose": "unknown", "last_action": None, "last_callback": None}
STAND_ACTIONS = {"back": "stand_up_back", "front": "stand_up_front", "reset": "stand"}

def _now():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def _my_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("223.5.5.5", 80))
        ip = s.getsockname()[0]; s.close(); return ip
    except Exception:
        return "unknown"

def _send_callback(url, payload):
    last_err = None
    for i in range(1, CALLBACK_RETRIES + 1):
        try:
            r = requests.post(url, json=payload, timeout=CALLBACK_TIMEOUT)
            return {"ok": True, "attempt": i, "status_code": r.status_code}
        except Exception as e:
            last_err = str(e); time.sleep(1)
    return {"ok": False, "attempts": CALLBACK_RETRIES, "error": last_err}

def _worker(mode, action, cb_url, req_id, cb_data):
    t0 = time.time(); err = None
    try:
        print(f"[{_now()}] {mode.upper()}: {action} ...")
        AGC.runActionGroup(action)
    except Exception as e:
        err = str(e)
    dur = round(time.time() - t0, 2); ok = err is None
    with _lock:
        _state["busy"] = False
        if ok:
            _state["pose"] = "lying" if mode == "fall" else "standing"
        _state["last_action"] = {"mode": mode, "action": action, "ok": ok,
                                 "error": err, "duration": dur, "finished_at": _now()}
    if cb_url:
        payload = {"event": f"{mode}_done", "request_id": req_id, "ok": ok, "error": err,
                   "action": action, "duration": dur, "pose": _state["pose"],
                   "robot_ip": _my_ip(), "timestamp": _now()}
        if cb_data is not None:
            payload["data"] = cb_data
        print(f"[{_now()}] callback -> {cb_url}")
        res = _send_callback(cb_url, payload)
        with _lock:
            _state["last_callback"] = {"url": cb_url, **res, "at_time": _now()}
        print(f"[{_now()}] callback result: {res}")
    print(f"[{_now()}] {mode} done ok={ok} dur={dur}s err={err}")

def _accept(mode, force):
    with _lock:
        if _state["busy"]:
            return False, 409, "robot busy (action in progress)"
        if not force:
            if mode == "fall" and _state["pose"] == "lying":
                return False, 409, "already lying (use /stand or force=true)"
            if mode == "stand" and _state["pose"] == "standing":
                return False, 409, "already standing (use /fall or force=true)"
        _state["busy"] = True
        return True, 202, "accepted"

@app.route("/fall", methods=["POST"])
def fall():
    if TOKEN and request.headers.get("X-Token") != TOKEN:
        return jsonify({"status": "rejected", "reason": "bad token"}), 401
    body = request.get_json(silent=True) or {}
    action = body.get("action", "lie_down")
    if not ACTION_RE.match(action or ""):
        return jsonify({"status": "rejected", "reason": "bad action name"}), 400
    ok, code, msg = _accept("fall", bool(body.get("force", False)))
    if not ok:
        return jsonify({"status": "rejected", "reason": msg, "pose": _state["pose"]}), code
    req_id = body.get("request_id") or f"fall-{int(time.time())}"
    threading.Thread(target=_worker, daemon=True,
                     args=("fall", action, body.get("callback_url"), req_id,
                           body.get("callback_data"))).start()
    return jsonify({"status": "accepted", "request_id": req_id,
                    "action": action, "callback": bool(body.get("callback_url"))}), 202

@app.route("/stand", methods=["POST"])
def stand():
    if TOKEN and request.headers.get("X-Token") != TOKEN:
        return jsonify({"status": "rejected", "reason": "bad token"}), 401
    body = request.get_json(silent=True) or {}
    mode = body.get("mode", "back")
    if mode not in STAND_ACTIONS:
        return jsonify({"status": "rejected",
                        "reason": f"mode must be one of {sorted(STAND_ACTIONS)}"}), 400
    action = STAND_ACTIONS[mode]
    ok, code, msg = _accept("stand", bool(body.get("force", False)))
    if not ok:
        return jsonify({"status": "rejected", "reason": msg, "pose": _state["pose"]}), code
    req_id = body.get("request_id") or f"stand-{int(time.time())}"
    threading.Thread(target=_worker, daemon=True,
                     args=("stand", action, body.get("callback_url"), req_id,
                           body.get("callback_data"))).start()
    return jsonify({"status": "accepted", "request_id": req_id, "mode": mode,
                    "action": action, "callback": bool(body.get("callback_url"))}), 202

@app.route("/status", methods=["GET"])
def status():
    with _lock:
        s = dict(_state)
    s["robot_ip"] = _my_ip(); s["server_time"] = _now()
    return jsonify(s)

if __name__ == "__main__":
    print(f"[{_now()}] fall_server on {HOST}:{PORT}")
    app.run(host=HOST, port=PORT, threaded=True)
```

## 五、电脑端：测试回调接收器（cb_listener.py）

阶段 2 测试用，跑在电脑上（WSL2 或 Windows，监听 0.0.0.0:9000）：

```python
#!/usr/bin/env python3
# cb_listener.py — 接收机器人回调并打印
from flask import Flask, request
app = Flask(__name__)

@app.route("/robot-callback", methods=["POST"])
def cb():
    data = request.get_json(silent=True) or {}
    print("=" * 50)
    print(f"CALLBACK  event={data.get('event')}  ok={data.get('ok')}  "
          f"duration={data.get('duration')}s  pose={data.get('pose')}")
    print(f"          request_id={data.get('request_id')}  data={data.get('data')}")
    print("=" * 50)
    return "ok", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=9000)
```

## 六、部署步骤

```bash
# 1. 推送（从 WSL2，直连 IP）
scp /home/administrator/hiwonder/src/fall_server.py pi@192.168.43.16:/home/pi/

# 2. 首次手动启动（验证用）
ssh pi@192.168.43.16 "nohup python3 /home/pi/fall_server.py > /home/pi/fall_server.log 2>&1 &"

# 3. 验证
curl http://192.168.43.16:8090/status
```

**开机自启（systemd，验证通过后做）**：
`ssh pi@192.168.43.16 "sudo tee /etc/systemd/system/fall-server.service" << EOF`
```ini
[Unit]
Description=TonyPi HTTP fall/stand server
After=network-online.target

[Service]
ExecStart=/usr/bin/python3 /home/pi/fall_server.py
Restart=always
RestartSec=5
User=pi

[Install]
WantedBy=multi-user.target
```
启用：`sudo systemctl enable --now fall-server`（日志：journalctl -u fall-server -f）

## 七、触发方式速查（curl 实测规则，2026-10-13 验证）

> 💡 双机：把示例里的 IP 换成 `192.168.137.172` 就是控制 2号，协议一字不差。

### PowerShell（你的主终端）

```powershell
# ── GET（无 body，怎么写都对）──
curl.exe http://192.168.137.72:8090/status                    # 机器人状态
curl.exe http://192.168.137.1:9000/health                     # 本机监听器状态

# ── POST 无 body（安全简单）──
curl.exe -X POST http://192.168.137.72:8090/fall              # 摔倒
curl.exe -X POST http://192.168.137.72:8090/stand             # 起立

# ── POST 带 JSON（内层引号必须 \" 转义，实测可用）──
curl.exe -X POST http://192.168.137.72:8090/fall -H "Content-Type: application/json" -d '{\"action\":\"bow\"}'
curl.exe -X POST http://192.168.137.72:8090/stand -H "Content-Type: application/json" -d '{\"mode\":\"front\"}'
curl.exe -X POST http://192.168.137.72:8090/fall -H "Content-Type: application/json" -d '{\"callback_url\":\"http://192.168.137.1:9000/robot-callback\",\"request_id\":\"t1\"}'

# ── 或 PowerShell 原生写法（无需转义，最省心）──
Invoke-RestMethod http://192.168.137.72:8090/status
Invoke-RestMethod -Method Post -Uri http://192.168.137.72:8090/fall -ContentType "application/json" -Body '{"action":"bow"}'
```

⚠️ **PS 5.1 陷阱实测结论**：`-d '{"a":"b"}'`（裸引号）→ 服务器收到坏 JSON 静默用默认值
（症状：`callback:false`、request_id 变自动值）；`-d '{\"a\":\"b\"}'`（转义）→ 正确解析 ✅

### CMD（cmd.exe）

```cmd
curl -X POST http://192.168.137.72:8090/fall -H "Content-Type: application/json" -d "{\"action\":\"bow\"}"
```

### Linux / 同热点其他设备（真 curl，引号原样）

```bash
curl -X POST http://192.168.137.72:8090/fall -H "Content-Type: application/json" \
  -d '{"action":"bow","callback_url":"http://192.168.137.1:9000/robot-callback","request_id":"t1","callback_data":{"who":"linux"}}'
```
（注：WSL2 → 机器人路由当前被 VPN 干扰不通，需从 Windows 侧发）

## 八、测试计划（三阶段）

| 阶段 | 内容 | 通过标准 |
|---|---|---|
| 1. 无回调冒烟 | `/status` → `/fall` → 观察 → `/stand` | 202 秒回；动作正常执行；pose 正确流转 |
| 2. 本机回调 | 电脑跑 cb_listener.py → `/fall` 带回调 | 电脑收到 fall_done JSON（≤动作耗时+5s） |
| 3. 公网回调 | 回调指向公网 URL（webhook 测试站或用户服务器） | 同上，经蜂窝网络送达 |

安全注意：测试时机器人放地板、周围清空（同 SSH 触发的安全包络）。

## 九、安全与限制

| 项 | 现状 | 建议 |
|---|---|---|
| 触发来源 | 仅同热点设备（NAT 挡外网） | 热点是自己的设备，风险可控 |
| 鉴权 | 默认无（TOKEN 空串） | 需要时设 TOKEN 常量 + X-Token 头 |
| 动作名注入 | 正则白名单 `^[a-zA-Z0-9_]+$` | 已防护 |
| 并发 | 忙时 409 拒绝 | 单动作队列足够，无需排队 |
| 误触发风险 | 摔倒有物理动作 | 部署后 IP 仅团队可见；必要时加 TOKEN |
| 依赖 | Flask 开发服务器 | 低流量场景够用；正式产品换 gunicorn |

## 十、决策点（部署前需确认）

1. **回调目标**选哪种？
   - A. 同热点电脑（测试方便，电脑须在线）✅ 推荐先做
   - B. 公网服务器（机器人经蜂窝外网回调，需提供 URL）
   - C. 暂时不用回调（只触发，靠 /status 轮询）
2. 是否启用 TOKEN 鉴权？
3. 端口 8090 是否 OK（当前空闲）？

## 十一、扩展方向（本期不做）

- **外网直触发**：Tailscale（机器人+电脑各装，零配置组网）或 frp（需公网服务器）
- 桌面快捷方式改用 HTTP（PowerShell `Invoke-RestMethod` 替代 ssh，响应更快）
- 动作速度参数化（`speed` 字段 → 调 make_fall 生成的慢速版本）
- IMU 上报（`/status` 里加实时姿态角）、异常倾倒主动回调
- 批量动作编排（一次 POST 一串动作）
