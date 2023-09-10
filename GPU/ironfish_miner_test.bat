@echo off
set "IRONFISH_MINER_FILE=ironfish_miner_setup.bat"
set "WALLET_ADDRESS=a0ace9efb58d290d84672351bca6c951587c93b14a870d18081329b72cf754d2"
set "WORKER_NAME=test4"
set "POOL_URL=stratum+tcp://hk.ironfish.herominers.com:1145"

echo Running as administrator...
powershell -Command "Start-Process 'cmd.exe' -ArgumentList '/c %~dp0%IRONFISH_MINER_FILE% %WALLET_ADDRESS% %WORKER_NAME% %POOL_URL%' -Verb runAs"
