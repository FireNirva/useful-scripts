@echo off
setlocal

:: Get the latest version details
echo Latest Version:
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $LatestRelease = Invoke-WebRequest -Uri 'https://api.github.com/repos/bzminer/bzminer/releases/latest' -UseBasicParsing | ConvertFrom-Json; $LatestVersion = $LatestRelease.tag_name; Write-Host $LatestVersion"

echo Latest URL:
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $LatestRelease = Invoke-WebRequest -Uri 'https://api.github.com/repos/bzminer/bzminer/releases/latest' -UseBasicParsing | ConvertFrom-Json; $LatestUrl = ($LatestRelease.assets | Where-Object { $_.name -like '*_windows.zip' }).browser_download_url; Write-Host $LatestUrl"

echo Latest File Name:
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $LatestRelease = Invoke-WebRequest -Uri 'https://api.github.com/repos/bzminer/bzminer/releases/latest' -UseBasicParsing | ConvertFrom-Json; $LatestFileName = ($LatestRelease.assets | Where-Object { $_.name -like '*_windows.zip' }).name; Write-Host $LatestFileName"

:: Set the latest URL variable
set "LATEST_URL="
for /f "usebackq delims=" %%a in (`powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $LatestRelease = Invoke-WebRequest -Uri 'https://api.github.com/repos/bzminer/bzminer/releases/latest' -UseBasicParsing | ConvertFrom-Json; $LatestUrl = ($LatestRelease.assets | Where-Object { $_.name -like '*_windows.zip' }).browser_download_url; Write-Host $LatestUrl"`) do set "LATEST_URL=%%a"

:: Set the latest file name and folder path variables
for %%i in (%LATEST_URL%) do set LATEST_FILE_NAME=%%~nxi
set "DESKTOP_PATH=%USERPROFILE%\Desktop\bzminer"

:: Create the folder if it does not exist
if not exist "%DESKTOP_PATH%" (
    mkdir "%DESKTOP_PATH%"
)

set "LATEST_FOLDER_NAME=%LATEST_FILE_NAME:.zip=%"
set "LATEST_FOLDER_NAME=%LATEST_FOLDER_NAME:_windows=%"
set "LATEST_FOLDER_PATH=%DESKTOP_PATH%\%LATEST_FOLDER_NAME%_windows"

:: Verify and extract the latest version if necessary
echo Verifying extraction to: "%LATEST_FOLDER_PATH%"
if exist "%LATEST_FOLDER_PATH%" (
    echo Latest version already downloaded
) else (
    if exist bzminer_*_windows.zip (
        del /q bzminer_*_windows.zip
    )
    if exist bzminer_*_windows (
        rd /s /q bzminer_*_windows
    )
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; Invoke-WebRequest -Uri '%LATEST_URL%' -OutFile '%DESKTOP_PATH%\bzminer.zip'"
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 ; Expand-Archive -Path '%DESKTOP_PATH%\bzminer.zip' -DestinationPath '%DESKTOP_PATH%' -Force"
)

:: Execute the miner with the passed parameters
"%LATEST_FOLDER_PATH%\bzminer.exe" -a ironfish -w %1.%2 -p %3 --nc 1

popd
timeout /t 5
pause
