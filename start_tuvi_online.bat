@echo off
cd /d "%~dp0"
title Tu Vi Online - System Console

echo Dang don dep he thong cu...
taskkill /f /im APIGateway_CS.exe >nul 2>&1
taskkill /f /im dotnet.exe >nul 2>&1
taskkill /f /im python.exe >nul 2>&1
taskkill /f /im dart.exe >nul 2>&1

REM Don dep cong mang bi treo
for /f "tokens=5" %%a in ('netstat -aon ^| find "5000" ^| find "LISTENING"') do taskkill /f /pid %%a >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| find "8000" ^| find "LISTENING"') do taskkill /f /pid %%a >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| find "8080" ^| find "LISTENING"') do taskkill /f /pid %%a >nul 2>&1

echo =========================================================
echo Khoi dong AI (Python) tren cong 8000...
start /b cmd /c "cd AIEngine_Python && python main.py >nul 2>&1"

echo Khoi dong Backend (C#) tren cong 5000...
start /b cmd /c "cd APIGateway_CS && dotnet run >nul 2>&1"

echo =========================================================
echo Dang chuan bi giao dien Frontend... (SE MAT KHOANG 1-2 PHUT)
echo Vui long theo doi tien trinh chay o ben duoi.
echo Neu trinh duyet hien mau trang, hay nhan F5 de tai lai trang!
echo =========================================================

cd frontend
REM Hen gio tu dong mo trinh duyet sau 45 giay
start /b cmd /c "ping 127.0.0.1 -n 45 >nul && start http://localhost:8080"

REM Chay flutter hien thi log ra man hinh chinh
call E:\flutter\bin\flutter.bat run -d web-server --web-port 8080

echo.
echo =========================================
echo He thong da tat hoac co loi xay ra.
echo =========================================
taskkill /f /im dotnet.exe >nul 2>&1
taskkill /f /im python.exe >nul 2>&1
taskkill /f /im dart.exe >nul 2>&1
pause
