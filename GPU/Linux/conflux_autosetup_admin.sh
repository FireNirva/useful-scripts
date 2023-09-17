#!/bin/bash

# Ensure the script is running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Define mining pool addresses
POOLS=(
  "stratum+tcp://de.conflux.herominers.com:1170"
  "stratum+tcp://fi.conflux.herominers.com:1170"
  "stratum+tcp://ru.conflux.herominers.com:1170"
  "stratum+tcp://ca.conflux.herominers.com:1170"
  "stratum+tcp://us.conflux.herominers.com:1170"
  "stratum+tcp://us2.conflux.herominers.com:1170"
  "stratum+tcp://br.conflux.herominers.com:1170"
  "stratum+tcp://hk.conflux.herominers.com:1170"
  "stratum+tcp://kr.conflux.herominers.com:1170"
  "stratum+tcp://in.conflux.herominers.com:1170"
  "stratum+tcp://sg.conflux.herominers.com:1170"
  "stratum+tcp://tr.conflux.herominers.com:1170"
  "stratum+tcp://au.conflux.herominers.com:1170"
)


# Find the pool with the lowest latency
BEST_POOL=""
LOWEST_LATENCY=1000000

for POOL in "${POOLS[@]}"; do
  HOST=$(echo $POOL | cut -d/ -f3 | cut -d: -f1)
  PORT=$(echo $POOL | cut -d: -f3)
  
  LATENCY=$(ping -c 1 -W 1 $HOST | sed -nE 's/^.*time=(.*) ms/\1/p')
  
  if [[ ! -z "$LATENCY" && $(echo "$LATENCY < $LOWEST_LATENCY" | bc) -eq 1 ]]; then
    LOWEST_LATENCY=$LATENCY
    BEST_POOL=$POOL
  fi
done

echo "Best pool: $BEST_POOL with latency $LOWEST_LATENCY ms"

# Define other variables
WALLET_ADDRESS="cfx:aanxwjsuf6e2yyntw1ecjyagrj24s9wvkjum1egd6m"
WORKER_NAME="worker1"
SETUP_SCRIPT_PATH="/path/to/your/setup_script.sh" # Adjust this path to your setup script

# Create a systemd service file to run the miner at boot
echo "[Unit]
Description=Run Miner on Boot

[Service]
ExecStart=$SETUP_SCRIPT_PATH $BEST_POOL $WALLET_ADDRESS $WORKER_NAME

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/miner.service

# Reload systemd, enable and start the service
systemctl daemon-reload
systemctl enable miner.service
systemctl start miner.service

echo "Miner service created, enabled and started"
