@echo off
cd /d "%~dp0"

where node >nul 2>nul
if errorlevel 1 (
  echo Node.js is not installed or not on PATH.
  pause
  exit /b 1
)

echo Starting Lingo Gold server on http://localhost:8099 ...
start "LingoGoldServer" /b node serve.cjs
timeout /t 3 /nobreak >nul

start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --app=http://localhost:8099 --window-size=1280,800

echo.
echo Server is running. Close the Chrome window to exit, then press any key here.
pause >nul
