import sys, time
import hiwonder.ros_robot_controller_sdk as rrc
print("=== serial devices ===")
import glob
print(glob.glob('/dev/ttyUSB*') + glob.glob('/dev/ttyAMA*') + glob.glob('/dev/serial*'))
print("=== board init ===")
board = rrc.Board()
board.enable_reception()
time.sleep(1)
print("=== IMU read test (MCU alive?) ===")
try:
    imu = board.get_imu()
    print("IMU:", imu)
except Exception as e:
    print("IMU FAILED:", e)
print("=== servo bus scan (first 3 IDs) ===")
try:
    for sid in (1, 2, 3):
        p = board.getBusServoPulse(sid)
        print(f"servo {sid}: {p}")
except Exception as e:
    print("SERVO READ FAILED:", e)
