@echo off
REM -------------------------------------------------------------
REM Copia de start-all.bat renombrada a start-all_ModADM
REM Ejecutar SIEMPRE en modo Administrador (Run as Administrator)
REM -------------------------------------------------------------
echo ==========================================================
echo AVISO: Ejecuta este script como Administrador (Run as Administrator)
echo Si no lo ejecutas como Administrador algunas acciones (eg. hooks
echo de teclado del agente) pueden fallar.
echo ==========================================================

REM Start services using paths relative to this script's folder (%~dp0)

REM --- Laravel ---
start "Comedor-Laravel" cmd /k "cd /d "%~dp0comedor-api" && php artisan serve --host=0.0.0.0 --port=8000"

REM --- Node RT ---
start "Comedor-Node" cmd /k "cd /d "%~dp0comedor-dk" && node server.js"

REM --- Agente ---
start "Comedor-Agente" cmd /k "cd /d "%~dp0agente-rfid" && if exist ".venv\Scripts\activate.bat" (call ".venv\Scripts\activate.bat" ) && python agent.py"

exit /b 0
