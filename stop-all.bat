@echo off
REM ==============================================================
REM stop-all.bat
REM
REM Uso: Ejecutar este archivo desde la raíz del repositorio.
REM Recomendado: Ejecutar como Administrador (Run as Administrator)
REM --------------------------------------------------------------
REM Qué hace:
REM  - Cierra las consolas que fueron abiertas por `start-all.bat` buscando
REM    las ventanas por título (Comedor-Agente, Comedor-Node, Comedor-Laravel).
REM  - Es un método seguro ya que solo afecta a las ventanas creadas por
REM    este conjunto de scripts.
REM
REM Notas y alternativas:
REM  - Si hay procesos node/php/python que no se cierran por título, podemos
REM    cerrar por nombre de proceso o usar un fallback más seguro que verifique
REM    la línea de comando del proceso. Actualmente se cierra por título.
REM ==============================================================

REM Cierra por título de ventana (las ventanas se crean con start "Comedor-..." )
taskkill /FI "WINDOWTITLE eq Comedor-Agente"  /T /F
taskkill /FI "WINDOWTITLE eq Comedor-Node"    /T /F
taskkill /FI "WINDOWTITLE eq Comedor-Laravel" /T /F

exit /b 0
