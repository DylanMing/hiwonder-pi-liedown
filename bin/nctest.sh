#!/system/bin/sh
echo "=== TEST 1: direct nc to robot sshd (control) ==="
printf 'SSH-2.0-Test\r\n' | timeout 6 nc 192.168.149.1 22 | od -c | head -6
echo "--- t1 done ---"
echo "=== TEST 2: COMMAND-mode relay nc -l -p 8025 nc robot 22 ==="
kill $(ps -A -o PID,ARGS 2>/dev/null | grep "nc -l -p 8025" | grep -v grep | sed "s/^ *//" | cut -d" " -f1) 2>/dev/null
nc -l -p 8025 nc 192.168.149.1 22 &
BGPID=$!
sleep 2
echo "--- listener check ---"
ss -tln | grep 8025 || echo NO_LISTENER_8025
echo "--- client dance ---"
printf 'SSH-2.0-Test\r\n' | timeout 8 nc 127.0.0.1 8025 | od -c | head -10
echo "--- t2 done ---"
kill $BGPID 2>/dev/null
echo "=== TEST 3: listen-stdin behavior (does -l forward its stdin?) ==="
(sleep 1; echo "HELLO_FROM_LISTENER") | nc -l -p 8026 &
BGPID2=$!
sleep 2
timeout 4 nc 127.0.0.1 8026 | od -c | head -3
echo "--- t3 done ---"
kill $BGPID2 2>/dev/null
