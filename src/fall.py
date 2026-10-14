#!/usr/bin/env python3
# 摔倒控制（独立）
# 用法: python3 fall.py [动作名]   默认 lie_down（4秒官方原速）
import sys, time
import hiwonder.ros_robot_controller_sdk as rrc
import hiwonder.ActionGroupControl as AGC
action = sys.argv[1] if len(sys.argv) > 1 else 'lie_down'
board = rrc.Board(); board.enable_reception(); time.sleep(1)
print(f"FALL: {action} ...")
AGC.runActionGroup(action)
print("fall done. (robot is now lying)")
