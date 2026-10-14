#!/usr/bin/env python3
# 起立控制（独立）
# 用法: python3 stand.py [back|front|reset]
#   back  = 仰卧起立（躺平在背，fall.py 之后用这个，默认）
#   front = 俯卧起立（脸朝下趴着时用）
#   reset = 直接回站立姿态（从任意姿态硬回位）
import sys, time
import hiwonder.ros_robot_controller_sdk as rrc
import hiwonder.ActionGroupControl as AGC
mode = sys.argv[1] if len(sys.argv) > 1 else 'back'
actions = {'back': 'stand_up_back', 'front': 'stand_up_front', 'reset': 'stand'}
action = actions.get(mode)
if not action:
    print(f"unknown mode: {mode} (use back|front|reset)"); sys.exit(1)
board = rrc.Board(); board.enable_reception(); time.sleep(1)
print(f"STAND UP: {action} ...")
AGC.runActionGroup(action)
print("stand done. (robot is upright)")
