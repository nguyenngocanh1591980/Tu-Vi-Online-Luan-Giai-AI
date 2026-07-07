@echo off
cd /d "%~dp0"
title Tu Vi Online - Backend Services (Hidden)

echo ========================================================
echo KHOI DONG BACKEND (AI, DATA SERVICE, API GATEWAY)
echo ========================================================
echo.

echo [1/4] Dang don dep cac tien trinh cu...
taskkill /f /im APIGateway_CS.exe >nul 2>&1
taskkill /f /im dotnet.exe >nul 2>&1
taskkill /f /im python.exe >nul 2>&1

for /f "tokens=5" %%a in ('netstat -aon ^| find "5000" ^| find "LISTENING"') do taskkill /f /pid %%a >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| find "5169" ^| find "LISTENING"') do taskkill /f /pid %%a >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| find "8000" ^| find "LISTENING"') do taskkill /f /pid %%a >nul 2>&1

if not exist "logs" mkdir logs

echo [2/4] Khoi dong AI Engine (Python) chay ngam tren cong 8000...
start /b cmd /c "cd AIEngine_Python && python main.py > ..\logs\ai_engine.log 2>&1"

echo [3/4] Khoi dong Data Service (C# Auth) chay ngam tren cong 5169...
start /b cmd /c "cd data_service && dotnet run > ..\logs\data_service.log 2>&1"

echo [4/4] Khoi dong API Gateway (C# Logic) chay ngam tren cong 5000...
start /b cmd /c "cd APIGateway_CS && dotnet run > ..\logs\api_gateway.log 2>&1"

echo.
echo ========================================================
echo TAT CA BACKEND DA CHAY NGAM THANH CONG!
echo Log duoc ghi tai thu muc "logs".
echo Giu nguyen man hinh nay de duy tri Backend.
echo ========================================================

REM Giữ màn hình Master Console
:loop
ping 127.0.0.1 -n 3600 >nul
goto loop
