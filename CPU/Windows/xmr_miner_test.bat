@echo off
set "XMR_MINER_SETUP_FILE=xmr_miner_setup.bat"
set "XMR_WALLET_ADDRESS=48EEXMKVeXnAFw3St68HivG4vXELaujKvSQfqvUq6QvqUwyu2YGvYnpdTBZongUkiJMY7hgFFtCyCeVknwK5CSsz2e8MLHg"
set "WORKER_NAME=worker1"
set "MINING_POOL_ADDRESS=stratum+tcp://ca.monero.herominers.com:1111"

echo Running as administrator...
powershell -Command "Start-Process 'cmd.exe' -ArgumentList '/c %~dp0%XMR_MINER_SETUP_FILE% %MINING_POOL_ADDRESS% %XMR_WALLET_ADDRESS% %WORKER_NAME%' -Verb runAs"