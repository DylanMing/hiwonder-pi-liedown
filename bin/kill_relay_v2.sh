#!/system/bin/sh
# v2: kill relay loops + keepers + nc/netcat by name + ANY pid holding port 8022
echo "--- before ---"
ss -tlnp 2>/dev/null | grep ':8022 '
# kill relay loops
for p in $(ps -A -o PID,ARGS | grep "relay.sh" | grep -v grep | sed 's/^ *//' | cut -d' ' -f1); do
  kill -9 $p 2>/dev/null
done
# kill keepers
for p in $(ps -A -o PID,ARGS | grep "sleep 31536000" | grep -v grep | sed 's/^ *//' | cut -d' ' -f1); do
  kill -9 $p 2>/dev/null
done
# kill nc by both possible names
killall nc 2>/dev/null
killall netcat 2>/dev/null
sleep 1
# kill whatever still holds 8022 (parse pid from ss)
for p in $(ss -tlnp 2>/dev/null | grep ':8022 ' | grep -o 'pid=[0-9]*' | cut -d= -f2); do
  echo "killing port-holder pid $p"
  kill -9 $p 2>/dev/null
done
sleep 1
echo "--- after ---"
ss -tln | grep ':8022 ' && echo STILL_HELD || echo PORT_FREE
ps -A -o PID,ARGS | grep -E "relay\.sh|nc |netcat" | grep -v grep || echo NO_RELAY_PROCS
