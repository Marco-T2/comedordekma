@echo off
REM --- Laravel ---
start "Comedor-Laravel" cmd /k "cd /d C:\Users\marco\Desktop\comedor-api && php artisan serve --host=0.0.0.0 --port=8000"
REM --- Node RT ---
start "Comedor-Node" cmd /k "cd /d C:\Users\marco\Desktop\comedor-dk && node server.js"
REM --- Agente ---
start "Comedor-Agente" cmd /k "cd /d C:\Users\marco\Desktop\agente-rfid && call .\.venv\Scripts\activate.bat && python agent.py"
