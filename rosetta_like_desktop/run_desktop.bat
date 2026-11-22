@echo off
cd /d "%~dp0"
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --app=http://localhost:8099 --window-size=1280,800
node serve.cjs
