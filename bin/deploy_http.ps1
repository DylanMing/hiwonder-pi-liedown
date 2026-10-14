[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Output "=== [1] deploy fall_server.py (Windows scp) ==="
scp -o StrictHostKeyChecking=accept-new "\\wsl.localhost\Ubuntu-24.04\home\administrator\hiwonder\src\fall_server.py" pi@192.168.137.72:/home/pi/fall_server.py
Write-Output "=== [2] start server ==="
ssh pi@192.168.137.72 "pkill -f fall_server.py 2>/dev/null; sleep 1; nohup python3 /home/pi/fall_server.py > /home/pi/fall_server.log 2>&1 & sleep 4; tail -5 /home/pi/fall_server.log"
Write-Output "=== [3] status check ==="
Start-Sleep -Seconds 2
curl.exe -s -m 5 http://192.168.137.72:8090/status
Write-Output ""
Write-Output "=== [4] python on Windows? ==="
python --version 2>&1
py --version 2>&1
