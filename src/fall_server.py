#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fall_server.py — TonyPi HTTP 触发服务（摔倒/起立 + 完成回调）
部署: /home/pi/fall_server.py    端口: 8090
依赖: flask(已装) requests(已装) hiwonder SDK(自带)
设计文档: /home/administrator/hiwonder/HTTP触发方案.md
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
