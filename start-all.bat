@echo off
REM Start services using paths relative to this script's folder (%~dp0)
REM Ensure this batch file lives in the repository root.

REM --- Laravel ---
start "Comedor-Laravel" cmd /k "cd /d "%~dp0comedor-api" && php artisan serve --host=0.0.0.0 --port=8000"

REM --- Node RT ---
start "Comedor-Node" cmd /k "cd /d "%~dp0comedor-dk" && node server.js"

REM --- Agente ---
start "Comedor-Agente" cmd /k "cd /d "%~dp0agente-rfid" && if exist ".venv\Scripts\activate.bat" (call ".venv\Scripts\activate.bat" ) && python agent.py"
