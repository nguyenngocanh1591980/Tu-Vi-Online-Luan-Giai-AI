@echo off
cd /d "%~dp0"
title Tu Vi Online - Backend Services

echo ========================================================
echo KHOI DONG BACKEND (AI + C# Data + C# Gateway)
echo ========================================================
echo.

echo Dang don dep cac tien trinh cu...
taskkill /f /im APIGateway_CS.exe >nul 2>&1
taskkill /f /im dotnet.exe >nul 2>&1
taskkill /f /im python.exe >nul 2>&1

for /f "tokens=5" %%a in ('netstat -aon ^| find "5000" ^| find "LISTENING"') do taskkill /f /pid %%a >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| find "5169" ^| find "LISTENING"') do taskkill /f /pid %%a >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| find "8000" ^| find "LISTENING"') do taskkill /f /pid %%a >nul 2>&1

echo Khoi dong AI Engine tren cong 8000...
start /b cmd /c "cd AIEngine_Python && python main.py >nul 2>&1"

echo Khoi dong Data Service tren cong 5169...
start /b cmd /c "cd data_service && dotnet run >nul 2>&1"

echo Khoi dong API Gateway tren cong 5000...
start /b cmd /c "cd APIGateway_CS && dotnet run >nul 2>&1"

echo ========================================================
echo Backend da san sang! 
echo Ban hay GIU NGUYEN CUA SO NAY.
echo Bay gio hay chay file "2_run_frontend_dev.bat" de bat Frontend.
echo ========================================================
pause
