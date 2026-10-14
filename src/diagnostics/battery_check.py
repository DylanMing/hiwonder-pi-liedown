import time
import hiwonder.ros_robot_controller_sdk as rrc
b = rrc.Board(); b.enable_reception(); time.sleep(1.5)
v = b.get_battery()
print("battery raw:", v)
if v and isinstance(v, (list, tuple)):
    for x in v: print("  ", x)
