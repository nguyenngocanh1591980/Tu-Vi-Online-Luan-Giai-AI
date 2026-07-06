@echo off
cd /d "%~dp0"

echo Starting ngrok tunnel on port 5000 in the background...
powershell -WindowStyle Hidden -Command "Start-Process .\ngrok.exe -ArgumentList 'http 5000' -WindowStyle Hidden"

echo Starting C# Backend...
cd APIGateway_CS
set ASPNETCORE_ENVIRONMENT=Development
cmd /k "dotnet run"
