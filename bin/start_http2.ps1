[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$sshopts = "-o","StrictHostKeyChecking=accept-new","-o","ConnectTimeout=10"
Write-Output "=== step1: kill old (self-safe pattern) ==="
ssh @sshopts pi@192.168.137.72 "pkill -f 'fall_serve[r]'; echo KILL_DONE"
Write-Output "=== step2: start server ==="
ssh @sshopts pi@192.168.137.72 "nohup python3 /home/pi/fall_server.py > /home/pi/fall_server.log 2>&1 & sleep 4; tail -6 /home/pi/fall_server.log; echo START_OK"
Write-Output "=== step3: status ==="
Start-Sleep -Seconds 2
curl.exe -s -m 5 http://192.168.137.72:8090/status
Write-Output ""
