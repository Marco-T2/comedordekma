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

REM --- Fallback seguro: cerrar solo procesos node/php/python iniciados desde este repo
echo Buscando procesos node/php/python cuyo comando contenga la ruta del repo (%~dp0)...

REM Ejecutar un comando PowerShell que encuentre procesos por nombre y cuyo CommandLine contenga el path del repo
powershell -NoProfile -Command "Try { $repo = '%~dp0'; $candidates = Get-CimInstance Win32_Process | Where-Object { @('node.exe','php.exe','python.exe') -contains $_.Name -and $_.CommandLine -and $_.CommandLine -like ('*' + $repo + '*') }; if ($candidates) { $candidates | ForEach-Object { Write-Output ('Cerrando proceso {0} ({1})' -f $_.ProcessId, $_.Name); try { Stop-Process -Id $_.ProcessId -Force } catch { Write-Output ('No se pudo cerrar {0}' -f $_.ProcessId) } } } else { Write-Output 'No se encontraron procesos relevantes iniciados desde este repo.' } } Catch { Write-Output 'Fallback seguro: error al enumerar procesos.' }"

REM Nota: este fallback es más seguro — solo cierra procesos cuya línea de comando contiene la ruta del repositorio.

echo Hecho.
exit /b 0
