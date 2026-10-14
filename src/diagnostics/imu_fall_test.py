import time
import hiwonder.ros_robot_controller_sdk as rrc
import hiwonder.ActionGroupControl as AGC

board = rrc.Board(); board.enable_reception(); time.sleep(1.5)

def imu():
    vals = []
    for _ in range(3):
        v = board.get_imu()
        if v: vals.append(v)
        time.sleep(0.4)
    return vals[-1] if vals else None

print("IMU before (should be standing):", imu())
print("--- action: stand ---")
AGC.runActionGroup('stand'); time.sleep(1)
print("IMU after stand:", imu())
print("--- action: lie_down (THE FALL) ---")
AGC.runActionGroup('lie_down'); time.sleep(1)
print("IMU after fall (orientation should CHANGE):", imu())
print("--- action: stand_up_back ---")
AGC.runActionGroup('stand_up_back'); time.sleep(1)
print("IMU after stand-up:", imu())
print("DONE")
