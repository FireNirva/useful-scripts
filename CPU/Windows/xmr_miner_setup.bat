@echo off
setlocal

:: Capture the passed arguments for wallet address and worker name
set "MINING_POOL_ADDRESS=%~1"
set "XMR_WALLET_ADDRESS=%~2"
set "WORKER_NAME=%~3"

echo Latest Version:
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; $LatestRelease = Invoke-WebRequest -Uri 'https://api.github.com/repos/xmrig/xmrig/releases/latest' -UseBasicParsing | ConvertFrom-Json; $LatestVersion = $LatestRelease.tag_name; Write-Host $LatestVersion"

echo Latest URL:
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; $LatestRelease = Invoke-WebRequest -Uri 'https://api.github.com/repos/xmrig/xmrig/releases/latest' -UseBasicParsing | ConvertFrom-Json; $LatestUrl = ($LatestRelease.assets | Where-Object { $_.name -like '*gcc-win64.zip' }).browser_download_url; Write-Host $LatestUrl"

echo Latest File Name:
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; $LatestRelease = Invoke-WebRequest -Uri 'https://api.github.com/repos/xmrig/xmrig/releases/latest' -UseBasicParsing | ConvertFrom-Json; $LatestFileName = ($LatestRelease.assets | Where-Object { $_.name -like '*gcc-win64.zip' }).name; Write-Host $LatestFileName"

:: Get the URL of the latest release
set "LATEST_URL="
for /f "usebackq delims=" %%a in (`powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; $LatestRelease = Invoke-WebRequest -Uri 'https://api.github.com/repos/xmrig/xmrig/releases/latest' -UseBasicParsing | ConvertFrom-Json; $LatestUrl = ($LatestRelease.assets | Where-Object { $_.name -like '*gcc-win64.zip' }).browser_download_url; Write-Host $LatestUrl"`) do set "LATEST_URL=%%a"

:: Get the file name of the latest release
for %%i in (%LATEST_URL%) do set LATEST_FILE_NAME=%%~nxi

:: Set the extraction path
set "DESKTOP_PATH=%USERPROFILE%\Desktop\xmrig_miner"

:: Create the folder if it does not exist
if not exist "%DESKTOP_PATH%" (
    mkdir "%DESKTOP_PATH%"
)

:: Set the folder name to be created during extraction
set "LATEST_FOLDER_NAME=%LATEST_FILE_NAME:-gcc-win64.zip=%"

:: Set the full path of the folder to be created
set "LATEST_FOLDER_PATH=%DESKTOP_PATH%\%LATEST_FOLDER_NAME%"

echo Verifying extraction to: "%LATEST_FOLDER_PATH%"

:: Check if the latest version is already downloaded
if exist "%LATEST_FOLDER_PATH%" (
    echo Latest version already downloaded
) else (
    :: Delete existing files and directories if any
    if exist xmrig-*-gcc-win64.zip (
        del /q xmrig-*-gcc-win64.zip
    )
    if exist xmrig-*-gcc-win64 (
        rd /s /q xmrig-*-gcc-win64
    )
    :: Download the latest release
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; Invoke-WebRequest -Uri '%LATEST_URL%' -OutFile '%DESKTOP_PATH%\xmrig.zip'"
    :: Extract the downloaded zip file
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; Expand-Archive -Path '%DESKTOP_PATH%\xmrig.zip' -DestinationPath '%DESKTOP_PATH%' -Force"
)

:: Run the XMRig miner with the necessary parameters
"%DESKTOP_PATH%\%LATEST_FOLDER_NAME%\xmrig.exe" -a rx/0 -o %MINING_POOL_ADDRESS% -u %XMR_WALLET_ADDRESS% -k --tls -p %WORKER_NAME%

:: Add a timeout before closing the script
timeout /t 5

pause
