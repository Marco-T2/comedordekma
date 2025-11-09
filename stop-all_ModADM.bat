@echo off
REM -------------------------------------------------------------
REM Copia de stop-all.bat renombrada a stop-all_ModADM
REM Ejecutar SIEMPRE en modo Administrador (Run as Administrator)
REM -------------------------------------------------------------
echo ==========================================================
echo AVISO: Ejecuta este script como Administrador (Run as Administrator)
echo Si no lo ejecutas como Administrador algunas acciones pueden fallar.
echo ==========================================================

REM Cierra por título de ventana
taskkill /FI "WINDOWTITLE eq Comedor-Agente"  /T /F
taskkill /FI "WINDOWTITLE eq Comedor-Node"    /T /F
taskkill /FI "WINDOWTITLE eq Comedor-Laravel" /T /F

exit /b 0
