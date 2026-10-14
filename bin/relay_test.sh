#!/system/bin/sh
echo "=== relay processes ==="
ps -A -o PID,PPID,ARGS 2>/dev/null | grep -E "relay\.sh|nc" | grep -v grep
echo "=== local SSH dance test through relay (from phone itself) ==="
printf 'SSH-2.0-OpenSSH_9.6\r\n' | timeout 8 nc 127.0.0.1 8022 | head -c 300 | od -c | head -8
echo "=== exit code: $? ==="
