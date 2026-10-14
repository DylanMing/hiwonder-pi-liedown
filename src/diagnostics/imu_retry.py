import time
import hiwonder.ros_robot_controller_sdk as rrc
b = rrc.Board(); b.enable_reception()
for i in range(5):
    time.sleep(1.5)
    v = b.get_imu()
    print(f"try {i+1}: IMU = {v if v else 'None'}")
    if v: break
