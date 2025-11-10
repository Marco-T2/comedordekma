# Run instructions for ComedorDekma

Este archivo resume los comandos y pasos útiles para arrancar y parar los servicios en desarrollo.

Recomendación general

- Ejecuta los scripts desde la carpeta raíz del repositorio (`C:\Users\marco\Desktop\ComedorDekma`).
- Para que el agente capture teclas globales en Windows (librería `keyboard` en `agent.py`) debes ejecutar la consola en modo Administrador (Run as Administrator).

1. Ejecutar desde los BAT (fácil)

- Dobleclic o botón derecho -> Ejecutar como Administrador en:
  - `start-all.bat` -> abre 3 consolas: Laravel, Node, Agente
  - `stop-all.bat` -> intenta cerrar las consolas abiertas por `start-all.bat`

2. Ejecutar manualmente (PowerShell)

- Abrir PowerShell como Administrador y ejecutar (ejemplos):

```powershell
# Ir al repo
Set-Location -Path 'C:\Users\marco\Desktop\ComedorDekma'

# Iniciar Laravel (desde carpeta comedor-api)
cd .\comedor-api
php artisan serve --host=0.0.0.0 --port=8000

# Iniciar Node (en otra consola)
cd ..\comedor-dk
node server.js

# Iniciar agente (en otra consola) - opcional activar venv si existe
Set-Location -Path 'C:\Users\marco\Desktop\ComedorDekma\agente-rfid'
if (Test-Path .\.venv\Scripts\Activate.ps1) { . .\.venv\Scripts\Activate.ps1 }
python agent.py
```

3. Crear tarea programada (ejemplo -- requiere PowerShell/Elevado o cmd con admin)

- Ejecuta este comando en una PowerShell con privilegios de administrador para crear la tarea que arranca `start-all.bat` al iniciar sesión:

```powershell
schtasks /Create /SC ONLOGON /RL HIGHEST /TN "ComedorDekma Start" /TR "C:\Users\marco\Desktop\ComedorDekma\start-all.bat" /F
```

4. Ejecutar scripts con elevación desde PowerShell (abrir UAC)

```powershell
Start-Process -FilePath "C:\Users\marco\Desktop\ComedorDekma\start-all.bat" -Verb RunAs
Start-Process -FilePath "C:\Users\marco\Desktop\ComedorDekma\stop-all.bat" -Verb RunAs
```

5. Seguridad / recomendaciones

- Evita subir archivos con secretos (`.env`, certificados, tokens). Si ya subiste `.env`, considera rotar credenciales y mover el archivo a un lugar seguro. En su lugar, sube un `.env.example` sin valores secretos.
- Subir `node_modules` o `vendor` suele inflar el repo; mejor usar `npm install` / `composer install` localmente. Si quieres, te ayudo a revertir esos commits.

6. Problemas comunes

- El agente no captura teclas: Ejecuta la consola como Administrador.
- Node no inicia: verifica `node --version` y que `server.js` no esté en uso por otro proceso (puerto 3000).
- Laravel falla: revisa `composer install` y `php --version`.

Si quieres que añada auto-elevación a `start-all.bat` (pide UAC automáticamente) o logging a `stop-all.bat`, lo implemento en el próximo paso.
