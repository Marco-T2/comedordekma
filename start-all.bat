@echo off
REM ==============================================================
REM start-all.bat
REM
REM Uso: Ejecutar este archivo desde la raíz del repositorio.
REM Recomendado: Ejecutar como Administrador (Run as Administrator)
REM --------------------------------------------------------------
REM Qué hace:
REM  - Abre 3 consolas (Laravel, Node realtime, Agente Python) usando
REM    títulos de ventana fijos: "Comedor-Laravel", "Comedor-Node", "Comedor-Agente".
REM  - Cada consola queda abierta para que puedas ver logs.
REM
REM Notas:
REM  - Laravel: usa `php artisan serve` en 0.0.0.0:8000 (útil para pruebas locales).
REM  - Node: lanza `comedor-dk/server.js` (socket.io / puente realtime).
REM  - Agente: si existe `.venv\Scripts\activate.bat` lo activa y luego lanza `python agent.py`.
REM  - Si prefieres auto-elevación (UAC) puedo añadir un bloque que re-lance con RunAs.
REM ==============================================================

REM --- Laravel ---
start "Comedor-Laravel" cmd /k "cd /d "%~dp0comedor-api" && echo Iniciando Laravel (php artisan serve)... && php artisan serve --host=0.0.0.0 --port=8000"

REM --- Node RT ---
start "Comedor-Node" cmd /k "cd /d "%~dp0comedor-dk" && echo Iniciando Node realtime (server.js)... && node server.js"

REM --- Agente ---
start "Comedor-Agente" cmd /k "cd /d "%~dp0agente-rfid" && if exist ".venv\Scripts\activate.bat" (echo Activando venv && call ".venv\Scripts\activate.bat") && echo Ejecutando agent.py && python agent.py"

exit /b 0
