@echo off
REM -------------------------------------------------------------
REM Copia de stop-all.bat renombrada a stop-all_ModADM
REM Ejecutar SIEMPRE en modo Administrador (Run as Administrator)
REM -------------------------------------------------------------
echo ==========================================================
echo AVISO: Ejecuta este script como Administrador (Run as Administrator)
echo Si no lo ejecutas como Administrador algunas acciones pueden fallar.
echo ==========================================================

REM --- Intento 1: Cerrar ventanas cuyo título contenga 'Comedor' usando PowerShell
echo Intentando cerrar ventanas con títulos que contengan "Comedor"...
powershell -NoProfile -Command "Try { Get-Process | Where-Object { $_.MainWindowTitle -and $_.MainWindowTitle -like '*Comedor*' } | ForEach-Object { try { $_.CloseMainWindow() | Out-Null; Start-Sleep -Milliseconds 500; if (-not $_.HasExited) { $_.Kill() } } catch { try { $_.Kill() } catch {} } } } Catch { Write-Output 'Warning: no se pudo enumerar procesos via PowerShell.' }"

REM Esperar un momento para que las ventanas se cierren
timeout /t 1 /nobreak >nul

REM --- Comprobación rápida: quedan procesos con ventanas 'Comedor'?
powershell -NoProfile -Command "$rem = Get-Process | Where-Object { $_.MainWindowTitle -and $_.MainWindowTitle -like '*Comedor*' }; if ($rem) { $rem | ForEach-Object { Write-Output ("Queda: {0} - {1}" -f $_.Id, $_.MainWindowTitle) } ; exit 1 } else { exit 0 }"
if %ERRORLEVEL% NEQ 0 (
	echo Algunas ventanas con 'Comedor' siguen activas.
)

REM --- Fallback: si aún hay procesos relevantes, terminarlos por nombre (ADVERTENCIA)
echo Si quedan procesos node/php/python, se intentará cerrarlos (esto puede afectar otras instancias).
tasklist | findstr /I "node.exe php.exe python.exe" >nul
if %ERRORLEVEL%==0 (
	echo Ejecutando fallback: taskkill /IM node.exe/php.exe/python.exe /F
	taskkill /IM node.exe /F 2>nul
	taskkill /IM php.exe /F 2>nul
	taskkill /IM python.exe /F 2>nul
)

echo Hecho.
exit /b 0
