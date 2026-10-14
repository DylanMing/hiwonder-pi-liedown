#!/system/bin/sh
echo "### A: current relay/nc processes"
ps -A -o PID,PPID,ARGS | grep -E "relay\.sh|nc -l|nc 192|sleep 3153" | grep -v grep
echo "### B: kill them all"
for p in $(ps -A -o PID,ARGS | grep -E "relay\.sh|nc -l|nc 192|sleep 3153" | grep -v grep | sed 's/^ *//' | cut -d' ' -f1); do
  echo "killing $p"
  kill -9 $p 2>/dev/null
done
sleep 1
echo "### C: after kill (empty=clean)"
ps -A -o PID,PPID,ARGS | grep -E "relay\.sh|nc -l|nc 192|sleep 3153" | grep -v grep
echo "### D: launch v3"
setsid sh /data/local/tmp/relay.sh </dev/null >/data/local/tmp/relay.log 2>&1 &
sleep 2
echo "### E: processes now"
ps -A -o PID,PPID,ARGS | grep -E "relay\.sh|nc -l|nc 192" | grep -v grep
echo "### F: listener on 8022"
ss -tln | grep 8022 || echo NO_LISTENER
echo "### G: relay.log content"
cat /data/local/tmp/relay.log 2>/dev/null
echo "(end log)"
echo "### H: dance test with live ps"
( sleep 2; echo "--- ps during dance:"; ps -A -o PID,PPID,ARGS | grep -E "nc -l|nc 192" | grep -v grep ) &
printf 'SSH-2.0-T\r\n' | timeout 6 nc 127.0.0.1 8022 | od -c | head -6
echo "### I: dance done"
