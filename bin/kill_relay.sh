#!/system/bin/sh
# kill every relay loop, keeper, and nc instance
for p in $(ps -A -o PID,ARGS | grep "relay.sh" | grep -v grep | sed 's/^ *//' | cut -d' ' -f1); do
  kill -9 $p 2>/dev/null
done
for p in $(ps -A -o PID,ARGS | grep "sleep 31536000" | grep -v grep | sed 's/^ *//' | cut -d' ' -f1); do
  kill -9 $p 2>/dev/null
done
killall nc 2>/dev/null
sleep 1
echo "=== remaining relay/nc processes ==="
ps -A -o PID,ARGS | grep -E "relay\.sh|nc |sleep 3153" | grep -v grep
echo "=== (empty above = clean) ==="
