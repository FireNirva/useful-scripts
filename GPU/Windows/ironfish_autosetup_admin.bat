@echo off
:: ===================================================================
:: Script Title: IronFish Miner Auto Setup
:: Author: FireNirva
:: Version: 1.0
:: Date: 2023-09-10
:: 
:: Description:
:: This script automates the setup process for the IronFish Miner. 
:: It performs the following operations:
::
:: 1. Elevation to administrative privileges: Ensures that the script
::    runs with the necessary administrative rights.
::
:: 2. Initialization and Variable Setup: 
::    - Defines an array of mining pool addresses.
::    - Sets the initial lowest latency to a high number.
::
:: 3. Latency Testing: 
::    - Iterates through the array of mining pool addresses to test 
::      the latency to each address.
::    - Identifies the best mining pool with the lowest latency.
::
:: 4. Miner Setup File Retrieval: 
::    - Searches for the IronFish miner setup file in a specified path.
::    - If the file is not found, it attempts to download it from a 
::      predefined GitHub URL.
::
:: 5. Task Scheduler Setup: 
::    - Creates an XML task definition file for the Windows Task Scheduler.
::    - Registers a new task to run the IronFish miner setup file at 
::      system startup with a delay of 10 seconds.
::
:: 6. Task Execution: 
::    - Executes the newly created task immediately.
::
:: Note:
:: The script leverages PowerShell to perform latency testing and file 
:: downloading operations. It requires Windows Task Scheduler and 
:: administrative privileges to function correctly.
::
:: Usage:
:: Run the script in a command prompt with administrative rights.
:: The script will automate the IronFish miner setup using the best 
:: mining pool based on the latency tests.
:: 
:: ===================================================================

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
set "POOL1=stratum+tcp://de.ironfish.herominers.com:1145"
set "POOL2=stratum+tcp://fi.ironfish.herominers.com:1145"
set "POOL3=stratum+tcp://ru.ironfish.herominers.com:1145"
set "POOL4=stratum+tcp://ca.ironfish.herominers.com:1145"
set "POOL5=stratum+tcp://us.ironfish.herominers.com:1145"
set "POOL6=stratum+tcp://us2.ironfish.herominers.com:1145"
set "POOL7=stratum+tcp://br.ironfish.herominers.com:1145"
set "POOL8=stratum+tcp://hk.ironfish.herominers.com:1145"
set "POOL9=stratum+tcp://kr.ironfish.herominers.com:1145"
set "POOL10=stratum+tcp://in.ironfish.herominers.com:1145"
set "POOL11=stratum+tcp://sg.ironfish.herominers.com:1145"
set "POOL12=stratum+tcp://tr.ironfish.herominers.com:1145"
set "POOL13=stratum+tcp://au.ironfish.herominers.com:1145"

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
set "IRONFISH_MINER_FILE=ironfish_miner_setup.bat"
set "WALLET_ADDRESS=a0ace9efb58d290d84672351bca6c951587c93b14a870d18081329b72cf754d2"
set "WORKER_NAME=test4"
set "POOL_URL=!BEST_MINING_POOL!"
set "BASE_PATH=C:\Users"

:: Find the setup file
for /f "delims=" %%F in ('dir /s /b "%BASE_PATH%\%IRONFISH_MINER_FILE%" 2^>nul') do (
    set "IRONFISH_MINER_FILE_PATH=%%F"
    goto :found
)

:notfound
echo Could not find %IRONFISH_MINER_FILE%
echo Downloading setup file from GitHub...

:: Specify a directory where the file will be downloaded
set "DOWNLOAD_DIR=C:\Users\%USERNAME%\AppData\Local\Temp"

:: Create the download directory if it does not exist
if not exist "%DOWNLOAD_DIR%" (
    mkdir "%DOWNLOAD_DIR%"
)

:: Download the file using PowerShell
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/FireNirva/useful-scripts/main/GPU/ironfish_miner_setup.bat' -OutFile '%DOWNLOAD_DIR%\%IRONFISH_MINER_FILE_PATH%'"

:: Check if the file was downloaded successfully
if exist "%DOWNLOAD_DIR%\%IRONFISH_MINER_FILE_PATH%" (
    echo Downloaded setup file successfully.
    set "IRONFISH_MINER_FILE_PATH=%DOWNLOAD_DIR%\%IRONFISH_MINER_FILE_PATH%"
    goto :found
) else (
    echo Failed to download the setup file.
    exit /b 1
)

:found
echo Found setup file at: !IRONFISH_MINER_FILE_PATH!

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
echo       ^<Arguments^>/C "!IRONFISH_MINER_FILE_PATH!" %WALLET_ADDRESS% %WORKER_NAME% %POOL_URL%^</Arguments^>
echo     ^</Exec^>
echo   ^</Actions^>
echo ^</Task^>
) > TaskDefinition.xml
echo Task definition created.

:: Check if the task exists and stop and delete it if necessary
schtasks /query /tn "RunIronFishMinerSetup" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    schtasks /end /tn "RunIronFishMinerSetup"
    if %ERRORLEVEL% NEQ 0 (
        echo Failed to stop the existing scheduled task.
        exit /b 1
    )
    echo Existing scheduled task stopped.

    schtasks /delete /tn "RunIronFishMinerSetup" /F
    if %ERRORLEVEL% NEQ 0 (
        echo Failed to delete the existing scheduled task.
        exit /b 1
    )
    echo Existing scheduled task deleted.
)

:: Create and run the scheduled task
schtasks /create /tn "RunIronFishMinerSetup" /xml "TaskDefinition.xml"
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
:: Run the scheduled task
schtasks /run /tn "RunIronFishMinerSetup"
if %ERRORLEVEL% NEQ 0 (
    echo Failed to run the scheduled task.
    exit /b 1
)
echo Scheduled task started.

