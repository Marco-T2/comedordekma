@echo off
REM Cierra por título de ventana
taskkill /FI "WINDOWTITLE eq Comedor-Agente"  /T /F
taskkill /FI "WINDOWTITLE eq Comedor-Node"    /T /F
taskkill /FI "WINDOWTITLE eq Comedor-Laravel" /T /F
