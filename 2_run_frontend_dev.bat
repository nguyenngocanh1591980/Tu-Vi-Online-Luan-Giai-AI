@echo off
cd /d "%~dp0"
title Tu Vi Online - Frontend Dev Server (Web-Server)

echo ========================================================
echo KHOI DONG FLUTTER WEB-SERVER (HOT REFRESH MODE)
echo ========================================================
echo.

echo [1/2] Dang don dep tien trinh Flutter cu...
taskkill /f /im dart.exe >nul 2>&1

echo [2/2] Khoi dong Frontend (Flutter)...
echo Dang Build Giao Dien va Mo Chrome... Vui long doi khoang 15-30 giay!
echo.
echo ========================================================
echo LUU Y: Vui long chay file 1_run_backend_services.bat TRUOC
echo de Backend C# va Python khoi dong xong, tranh loi CORS.
echo ========================================================
cd frontend

REM Thu chay bang lenh flutter (neu da co trong PATH), neu khong thi dung duong dan E:\flutter\bin\flutter.bat
flutter run -d chrome || call E:\flutter\bin\flutter.bat run -d chrome

pause
