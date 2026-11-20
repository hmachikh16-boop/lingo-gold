@echo off
cd /d "%~dp0.."
start "Lingo Gold Dashboard" /MIN node admin\serve.cjs
timeout /t 2 /nobreak >nul
start http://localhost:8080
