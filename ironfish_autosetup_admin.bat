@echo off

:: BatchGotAdmin (Run as Admin code starts)
REM --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

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
:: BatchGotAdmin (Run as Admin code ends)

setlocal enabledelayedexpansion

:: Set your variables
set "IRONFISH_MINER_FILE=ironfish_miner_setup.bat"
set "WALLET_ADDRESS=a0ace9efb58d290d84672351bca6c951587c93b14a870d18081329b72cf754d2"
set "WORKER_NAME=test4"
set "POOL_URL=stratum+tcp://hk.ironfish.herominers.com:1145"
set "BASE_PATH=C:\Users"

:: Find the setup file
for /f "delims=" %%F in ('dir /s /b "%BASE_PATH%\%IRONFISH_MINER_FILE%" 2^>nul') do (
    set "IRONFISH_MINER_FILE_PATH=%%F"
    goto :found
)

:notfound
echo Could not find %IRONFISH_MINER_FILE%
exit /b 1

:found
echo Found setup file at: !IRONFISH_MINER_FILE_PATH!

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
:: Create and run the scheduled task
schtasks /create /tn "RunIronFishMinerSetup" /xml "TaskDefinition.xml"
if %ERRORLEVEL% NEQ 0 (
    echo Failed to create the scheduled task.
    exit /b 1
)
echo Scheduled task created.

:: Clean up the XML file
del TaskDefinition.xml

:: Run the scheduled task
schtasks /run /tn "RunIronFishMinerSetup"
if %ERRORLEVEL% NEQ 0 (
    echo Failed to run the scheduled task.
    exit /b 1
)
echo Scheduled task started.

