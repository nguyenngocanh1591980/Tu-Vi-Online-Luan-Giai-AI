@echo off
title Khoi dong TuViOnline Admin Portal (Port 3000)
color 0A

echo ===================================================
echo   KHOI DONG HE THONG ADMIN PORTAL - TU VI ONLINE
echo ===================================================
echo Kiem tra trang thai Backend (Port 5000)...
netstat -ano | find "5000" | find "LISTENING" >nul 2>&1
if %errorlevel% neq 0 (
    echo [THONG BAO] Backend chua chay. Dang tu dong khoi dong Backend Services...
    start /min cmd /c "cd /d "E:\Tu vi online" && call 1_run_backend_hidden.bat"
    timeout /t 3 /nobreak >nul 2>&1
    echo [OK] Backend da duoc khoi dong!
) else (
    echo [OK] Backend Services dang hoat dong san sang.
)

echo.
echo Kiem tra va giai phong Port 3000 neu dang bi chiem dung...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":3000" ^| findstr "LISTENING"') do (
    echo [THONG BAO] Dang giai phong Port 3000 tu tien trinh PID %%a...
    taskkill /f /pid %%a >nul 2>&1
)
timeout /t 1 /nobreak >nul 2>&1

echo.
echo Dang di chuyen vao thu muc du an...
cd /d "E:\Tu vi online\TuViOnline_AdminPortal"

echo.
echo Dang khoi chay Flutter Web tren Port 3000...
echo (Vui long cho giay lat de he thong bien dich code)
echo.

call "E:\flutter\bin\flutter.bat" run -d chrome --web-port 3000

echo.
echo ===================================================
if %errorlevel% neq 0 (
    color 0C
    echo [THONG BAO] Tien trinh Flutter da dung hoac gap su co.
) else (
    echo Da tat server Admin Portal.
)
echo ===================================================
pause
