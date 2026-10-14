#!/system/bin/sh
# v4: COMMAND-mode relay - fresh robot connection per client, 5s connect timeout
ROBOT=192.168.149.1
while true; do
  nc -l -p 8022 nc -w 5 "$ROBOT" 22
  sleep 0.2
done
