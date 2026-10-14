import serial, time

# Phase 1: passive listen — does the MCU stream ANYTHING?
s = serial.Serial('/dev/ttyAMA0', 1000000, timeout=0.5)
s.rts = False; s.dtr = False
s.reset_input_buffer()
print("=== passive listen 4s ===")
got = b''
t0 = time.time()
while time.time() - t0 < 4:
    chunk = s.read(256)
    if chunk: got += chunk
print("received:", got.hex() if got else "(silence)")
s.close()
