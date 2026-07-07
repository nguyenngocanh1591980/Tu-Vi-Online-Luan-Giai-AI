@echo off
cd /d "%~dp0"
title Tu Vi Online - E2E FOMO Test

echo ========================================================
echo CHIEN DICH DAU NOI LOI LOGIC (PHASE 2) - TEST E2E
echo ========================================================
echo.

echo [1/4] Dang don dep cac tien trinh cu...
taskkill /f /im APIGateway_CS.exe >nul 2>&1
taskkill /f /im dotnet.exe >nul 2>&1
taskkill /f /im python.exe >nul 2>&1
taskkill /f /im dart.exe >nul 2>&1

for /f "tokens=5" %%a in ('netstat -aon ^| find "5000" ^| find "LISTENING"') do taskkill /f /pid %%a >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| find "5169" ^| find "LISTENING"') do taskkill /f /pid %%a >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| find "8000" ^| find "LISTENING"') do taskkill /f /pid %%a >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| find "8080" ^| find "LISTENING"') do taskkill /f /pid %%a >nul 2>&1

echo [2/5] Khoi dong AI Engine (Python) chay ngam tren cong 8000...
start /b cmd /c "cd AIEngine_Python && python main.py >nul 2>&1"

echo [3/5] Khoi dong Data Service (C# Auth) chay ngam tren cong 5169...
start /b cmd /c "cd data_service && dotnet run >nul 2>&1"

echo [4/5] Khoi dong API Gateway (C# Logic) chay ngam tren cong 5000...
echo Luu y: Backend C# se tu dong reset DB va tao tai khoan 'tester_vip_001' (50 Coin).
start /b cmd /c "cd APIGateway_CS && dotnet run >nul 2>&1"

echo [5/5] Khoi dong Frontend (Flutter)...
echo Dang Build Giao Dien va Mo Chrome... Vui long doi khoang 15-30 giay!
cd frontend

REM Thu chay bang lenh flutter (neu da co trong PATH), neu khong thi dung duong dan E:\flutter\bin\flutter.bat
flutter run -d chrome || call E:\flutter\bin\flutter.bat run -d chrome

echo.
echo =========================================
echo He thong da tat hoac co loi xay ra.
echo =========================================
taskkill /f /im dotnet.exe >nul 2>&1
taskkill /f /im python.exe >nul 2>&1
taskkill /f /im dart.exe >nul 2>&1
pause
