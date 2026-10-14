#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
cb_listener.py — 电脑端回调接收器（零依赖，纯标准库）
跑在电脑上：python cb_listener.py   （Windows / WSL2 / 任意 Python3 均可）
监听 0.0.0.0:9000，机器人回调 POST 到 http://<电脑IP>:9000/robot-callback
"""
import json
from http.server import HTTPServer, BaseHTTPRequestHandler


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0) or 0)
        body = self.rfile.read(n) if n else b"{}"
        try:
            data = json.loads(body)
        except Exception:
            data = {"raw": body.decode(errors="replace")}
        print("=" * 60, flush=True)
        print(f"CALLBACK  event={data.get('event')}  ok={data.get('ok')}  "
              f"duration={data.get('duration')}s  pose={data.get('pose')}", flush=True)
        print(f"          request_id={data.get('request_id')}  "
              f"robot_ip={data.get('robot_ip')}  data={data.get('data')}", flush=True)
        print(f"          full: {data}", flush=True)
        print("=" * 60, flush=True)
        resp = b"ok"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(resp)))
        self.end_headers()
        self.wfile.write(resp)

    def do_GET(self):
        resp = b"listener alive"
        self.send_response(200)
        self.send_header("Content-Length", str(len(resp)))
        self.end_headers()
        self.wfile.write(resp)

    def log_message(self, *args):
        pass  # 静默访问日志


if __name__ == "__main__":
    print("callback listener on 0.0.0.0:9000  (waiting for robot ...)", flush=True)
    HTTPServer(("0.0.0.0", 9000), Handler).serve_forever()
