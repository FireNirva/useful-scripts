@echo off
setlocal

:: Capture the passed arguments for wallet address and worker name
set "MINING_POOL_ADDRESS=%~1"
set "CONFLUX_WALLET_ADDRESS=%~2"
set "WORKER_NAME=%~3"

echo Latest Version:
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; $LatestRelease = Invoke-WebRequest -Uri 'https://api.github.com/repos/trexminer/T-Rex/releases/latest' -UseBasicParsing | ConvertFrom-Json; $LatestVersion = $LatestRelease.tag_name; Write-Host $LatestVersion"

echo Latest URL:
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; $LatestRelease = Invoke-WebRequest -Uri 'https://api.github.com/repos/trexminer/T-Rex/releases/latest' -UseBasicParsing | ConvertFrom-Json; $LatestUrl = ($LatestRelease.assets | Where-Object { $_.name -like '*win.zip' }).browser_download_url; Write-Host $LatestUrl"

echo Latest File Name:
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; $LatestRelease = Invoke-WebRequest -Uri 'https://api.github.com/repos/trexminer/T-Rex/releases/latest' -UseBasicParsing | ConvertFrom-Json; $LatestFileName = ($LatestRelease.assets | Where-Object { $_.name -like '*win.zip' }).name; Write-Host $LatestFileName"

:: Continue with the rest of the script as before...

set "LATEST_URL="
for /f "usebackq delims=" %%a in (`powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; $LatestRelease = Invoke-WebRequest -Uri 'https://api.github.com/repos/trexminer/T-Rex/releases/latest' -UseBasicParsing | ConvertFrom-Json; $LatestUrl = ($LatestRelease.assets | Where-Object { $_.name -like '*win.zip' }).browser_download_url; Write-Host $LatestUrl"`) do set "LATEST_URL=%%a"

for %%i in (%LATEST_URL%) do set LATEST_FILE_NAME=%%~nxi

set "DESKTOP_PATH=%USERPROFILE%\Desktop\trex_miner"

set "LATEST_FOLDER_NAME=%LATEST_FILE_NAME:.zip=%"

set "LATEST_FOLDER_PATH=%DESKTOP_PATH%\%LATEST_FOLDER_NAME%.zip"

echo Verifying extraction to: "%LATEST_FOLDER_PATH%"

if exist "%LATEST_FOLDER_PATH%" (
    echo Latest version already downloaded
) else (
    if exist trex-*-win.zip (
        del /q trex-*-win.zip
    )
    if exist trex-*-win (
        rd /s /q trex-*-win
    )
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; Invoke-WebRequest -Uri '%LATEST_URL%' -OutFile '%DESKTOP_PATH%\trex.zip'"
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; Expand-Archive -Path '%DESKTOP_PATH%\trex.zip' -DestinationPath '%DESKTOP_PATH%' -Force"
)

:: Add the execution command for the T-Rex miner with the necessary parameters for mining Conflux
"%DESKTOP_PATH%\t-rex.exe" -a octopus -o %MINING_POOL_ADDRESS% -u %CONFLUX_WALLET_ADDRESS%.%WORKER_NAME% -p x

popd

timeout /t 5

pause
