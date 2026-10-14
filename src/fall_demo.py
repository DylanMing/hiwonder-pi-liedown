#!/usr/bin/env python3
# 三合一演示：站立 → 摔倒 → 爬起
# 用法: python3 fall_demo.py [动作名]   默认 lie_down
import sys, time
import hiwonder.ros_robot_controller_sdk as rrc
import hiwonder.ActionGroupControl as AGC
action = sys.argv[1] if len(sys.argv) > 1 else 'lie_down'
board = rrc.Board(); board.enable_reception(); time.sleep(1)
print("DEMO: stand ..."); AGC.runActionGroup('stand'); time.sleep(1)
print(f"FALL: {action} ..."); AGC.runActionGroup(action); time.sleep(1)
print("STAND UP: stand_up_back ..."); AGC.runActionGroup('stand_up_back')
print("demo done. (robot is upright)")
