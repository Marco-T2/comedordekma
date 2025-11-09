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
echo Cerrando consolas con títulos exactos: Comedor-Agente, Comedor-Node, Comedor-Laravel

REM Usar PowerShell para cerrar únicamente procesos cuya MainWindowTitle sea EXACTAMENTE
REM uno de los títulos que creamos — esto evita afectar a otras aplicaciones (ej. Visual Studio Code).
powershell -NoProfile -Command "Try {
	$titles = @('Comedor-Agente','Comedor-Node','Comedor-Laravel');
	foreach ($t in $titles) {
		$procs = Get-Process | Where-Object { $_.MainWindowTitle -and $_.MainWindowTitle -eq $t };
		foreach ($p in $procs) {
			Write-Output ("Cerrando ventana: {0} (PID {1})" -f $p.MainWindowTitle, $p.Id);
			try { $p.CloseMainWindow() | Out-Null; Start-Sleep -Milliseconds 300; if (-not $p.HasExited) { $p.Kill() } } catch { Write-Output ('No se pudo cerrar proceso {0}' -f $p.Id) }
		}
	}
} Catch { Write-Output 'Error al intentar cerrar ventanas via PowerShell.' }"

REM Nota: esto no cierra Visual Studio Code -- Code.exe no tendrá MainWindowTitle igual a los títulos exactos usados.

exit /b 0
