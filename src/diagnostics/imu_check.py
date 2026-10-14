import time
import hiwonder.ros_robot_controller_sdk as rrc
b = rrc.Board(); b.enable_reception(); time.sleep(1.5)
v = b.get_imu()
print("IMU:", v)
print("MCU_ALIVE" if v else "MCU_DEAD")
