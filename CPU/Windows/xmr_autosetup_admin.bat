@echo off

:: ------------------------------------------------------------------------------------------------
:: Script Name: XMRig Miner Setup with Best Pool Selector
:: Author: FireNirva
:: Version: 1.0
:: Date: 2023-09-10
:: 
:: Description:
:: This script performs the following operations:
:: - Requests administrative privileges upon execution.
:: - Sets up individual variables for each mining pool address and creates an array-like structure to hold all the addresses.
:: - Iterates over each mining pool address, extracting the host and port, and tests the latency using a PowerShell command.
:: - Records the pool with the lowest latency and stores its details.
:: - Creates an XML task definition for a Windows Task Scheduler job.
:: - Creates and runs a scheduled task using the task definition, to execute the XMRig miner with the optimal mining pool address and other predefined parameters upon system boot.
::
:: Instructions:
:: - Save this script as a .bat file and run it with administrative privileges.
:: - The script will automatically find the best pool based on latency and set up a scheduled task to run the XMRig miner at boot.
::
:: Note:
:: - The script assumes PowerShell and schtasks are available on the system.
:: - The script uses a try-catch block in PowerShell to handle exceptions and sets a high latency value in case of errors, to avoid choosing an unreachable pool.
:: 
:: ------------------------------------------------------------------------------------------------

:: -------------------------------------------
:: Elevate script to run with administrative privileges
:: -------------------------------------------
:RequestAdminPrivileges
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' ( 
    echo Requesting administrative privileges...
    goto :UACPrompt 
) else ( goto :gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"

:: -------------------------------------------
:: Initialization and Setup of Variables
:: -------------------------------------------
setlocal enabledelayedexpansion
:: Set the initial lowest latency to a high number
set "LOWEST_LATENCY=100000"

:: Define each pool address with a unique variable
set "POOL1=stratum+tcp://de.monero.herominers.com:1111"
set "POOL2=stratum+tcp://fi.monero.herominers.com:1111"
set "POOL3=stratum+tcp://ru.monero.herominers.com:1111"
set "POOL4=stratum+tcp://ca.monero.herominers.com:1111"
set "POOL5=stratum+tcp://us.monero.herominers.com:1111"
set "POOL6=stratum+tcp://us2.monero.herominers.com:1111"
set "POOL7=stratum+tcp://br.monero.herominers.com:1111"
set "POOL8=stratum+tcp://hk.monero.herominers.com:1111"
set "POOL9=stratum+tcp://kr.monero.herominers.com:1111"
set "POOL10=stratum+tcp://in.monero.herominers.com:1111"
set "POOL11=stratum+tcp://sg.monero.herominers.com:1111"
set "POOL12=stratum+tcp://tr.monero.herominers.com:1111"
set "POOL13=stratum+tcp://au.monero.herominers.com:1111"

:: Create an array-like structure using the defined pool variables
set "MINING_POOL_ADDRESSES=%POOL1% %POOL2% %POOL3% %POOL4% %POOL5% %POOL6% %POOL7% %POOL8% %POOL9% %POOL10% %POOL11% %POOL12% %POOL13%"

:: -------------------------------------------
:: Latency Testing
:: -------------------------------------------
:TestLatency
for %%A in (%MINING_POOL_ADDRESSES%) do (

    :: Extract the host and port from the current address
    for /F "tokens=2,3 delims=/: " %%B in ("%%A") do (
        set "HOST=%%B"
        set "PORT=%%C"
    )
    
    :: Test the latency to the current address
    for /F %%D in ('powershell -Command "try { $latency = [math]::Round((Measure-Command { $tcpclient = New-Object System.Net.Sockets.TcpClient; $tcpclient.Connect('!HOST!', !PORT!) }).TotalMilliseconds); Write-Host $latency } catch { Write-Host 100000 }"') do (
        set "LATENCY=%%D"
        if !LATENCY! lss !LOWEST_LATENCY! (
            set "LOWEST_LATENCY=!LATENCY!"
            set "BEST_MINING_POOL=%%A"
        )
    )
)

:: -------------------------------------------
:: Miner Setup File Retrieval
:: -------------------------------------------
:SetupFileRetrieval
set "XMR_MINER_SETUP_FILE=xmr_miner_setup.bat"
set "XMR_WALLET_ADDRESS=48EEXMKVeXnAFw3St68HivG4vXELaujKvSQfqvUq6QvqUwyu2YGvYnpdTBZongUkiJMY7hgFFtCyCeVknwK5CSsz2e8MLHg"
set "WORKER_NAME=worker1"
set "MINING_POOL_ADDRESS=!BEST_MINING_POOL!"
set "BASE_PATH=C:\Users"

:: Find the setup file
for /f "delims=" %%F in ('dir /s /b "%BASE_PATH%\%XMR_MINER_SETUP_FILE%" 2^>nul') do (
    set "XMR_MINER_SETUP_FILE_PATH=%%F"
    goto :found
)

:notfound
echo Could not find %XMR_MINER_SETUP_FILE%
echo Downloading setup file from GitHub...

:: Specify a directory where the file will be downloaded
set "DOWNLOAD_DIR=C:\Users\%USERNAME%\AppData\Local\Temp"

:: Create the download directory if it does not exist
if not exist "%DOWNLOAD_DIR%" (
    mkdir "%DOWNLOAD_DIR%"
)

:: Download the file using PowerShell
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/FireNirva/useful-scripts/main/GPU/conflux_miner_setup.bat' -OutFile '%DOWNLOAD_DIR%\%XMR_MINER_SETUP_FILE%'"

:: Check if the file was downloaded successfully
if exist "%DOWNLOAD_DIR%\%XMR_MINER_SETUP_FILE%" (
    echo Downloaded setup file successfully.
    set "XMR_MINER_SETUP_FILE_PATH=%DOWNLOAD_DIR%\%XMR_MINER_SETUP_FILE%"
    goto :found
) else (
    echo Failed to download the setup file.
    exit /b 1
)

:found
echo Found setup file at: !XMR_MINER_SETUP_FILE_PATH!

:: -------------------------------------------
:: Task Scheduler Setup
:: -------------------------------------------
:TaskSchedulerSetup

:: Create the XML task definition
(
echo ^<?xml version="1.0" encoding="UTF-16"?^>
echo ^<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^>
echo   ^<RegistrationInfo^>
echo     ^<Author^>Microsoft Corporation^</Author^>
echo   ^</RegistrationInfo^>
echo   ^<Triggers^>
echo     ^<BootTrigger^>
echo       ^<Enabled^>true^</Enabled^>
echo       ^<Delay^>PT10S^</Delay^>
echo     ^</BootTrigger^>
echo   ^</Triggers^>
echo   ^<Principals^>
echo     ^<Principal id="Author"^>
echo       ^<UserId^>S-1-5-18^</UserId^>
echo       ^<LogonType^>InteractiveToken^</LogonType^>
echo       ^<RunLevel^>HighestAvailable^</RunLevel^>
echo     ^</Principal^>
echo   ^</Principals^>
echo   ^<Settings^>
echo     ^<MultipleInstancesPolicy^>StopExisting^</MultipleInstancesPolicy^>
echo     ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^>
echo     ^<StopIfGoingOnBatteries^>false^</StopIfGoingOnBatteries^>
echo     ^<AllowHardTerminate^>true^</AllowHardTerminate^>
echo     ^<StartWhenAvailable^>false^</StartWhenAvailable^>
echo     ^<RunOnlyIfNetworkAvailable^>false^</RunOnlyIfNetworkAvailable^>
echo     ^<IdleSettings^>
echo       ^<StopOnIdleEnd^>false^</StopOnIdleEnd^>
echo       ^<RestartOnIdle^>false^</RestartOnIdle^>
echo     ^</IdleSettings^>
echo   ^</Settings^>
echo   ^<Actions Context="Author"^>
echo     ^<Exec^>
echo       ^<Command^>cmd.exe^</Command^>
echo       ^<Arguments^>/C "!XMR_MINER_SETUP_FILE_PATH!" %MINING_POOL_ADDRESS% %XMR_WALLET_ADDRESS% %WORKER_NAME%^</Arguments^>
echo     ^</Exec^>
echo   ^</Actions^>
echo ^</Task^>
) > TaskDefinition.xml
echo Task definition created.

:: Check if the task exists and stop and delete it if necessary
schtasks /query /tn "RunXMRMinerSetup" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    schtasks /end /tn "RunXMRMinerSetup"
    if %ERRORLEVEL% NEQ 0 (
        echo Failed to stop the existing scheduled task.
        exit /b 1
    )
    echo Existing scheduled task stopped.

    schtasks /delete /tn "RunXMRMinerSetup" /F
    if %ERRORLEVEL% NEQ 0 (
        echo Failed to delete the existing scheduled task.
        exit /b 1
    )
    echo Existing scheduled task deleted.
)

:: Create and run the scheduled task
schtasks /create /tn "RunXMRMinerSetup" /xml "TaskDefinition.xml"
if %ERRORLEVEL% NEQ 0 (
    echo Failed to create the scheduled task.
    exit /b 1
)
echo Scheduled task created.

:: Clean up the XML file
del TaskDefinition.xml

:: -------------------------------------------
:: Task Execution
:: -------------------------------------------
:TaskExecution

:: Run the scheduled task
schtasks /run /tn "RunXMRMinerSetup"
if %ERRORLEVEL% NEQ 0 (
    echo Failed to run the scheduled task.
    exit /b 1
)
echo Scheduled task started.