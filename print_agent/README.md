# Print Agent para Brother QL-700

Este pequeño servicio Flask recibe una imagen PNG en base64 y la envía a una Brother QL-700 con corte automático.

Requisitos (Windows):

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1  # o .venv\Scripts\activate
pip install -r requirements.txt
```

Ejecutar:

```powershell
python main.py
```

Configuración:

- Si usas el spooler de Windows (cola), edita `PRINTER_ID` y usa `backend_identifier='network'` y `printer_identifier='\\\\localhost\\Brother_QL_700'`.
- Para listar impresoras USB/VID:PID: `python -m brother_ql`.

## Fallback spooler Windows

Si el envío directo por USB con `brother_ql` no está disponible (por diferencias en la API o drivers), el agente ahora intenta automáticamente un fallback que envía la imagen al spooler de Windows.

Requisitos adicionales (Windows):

1. Instalar `pywin32` en el entorno virtual:

```powershell
Set-Location -Path 'C:\Users\marco\Desktop\ComedorDekma\print_agent'
.\.venv\Scripts\Activate.ps1
pip install pywin32
```

2. Asegúrate de que la impresora Brother está instalada en Windows (Get-Printer) y que la cola esté configurada para "62 mm Continuous" si vas a usar rollo.

3. Opcional: especificar una impresora concreta exportando la variable de entorno `PRINT_PRINTER` con el nombre de la cola Windows.

El comportamiento es:

- Intentar envío por `brother_ql`/pyusb.
- Si falla, guardar la imagen PNG en un temporal y enviarla al spooler de Windows.

Limitaciones:

- El corte automático depende de la configuración del driver/cola de Windows.
- Si necesitas control absoluto de corte/avance desde código, considera usar `brother_ql` con la API nativa y drivers WinUSB (Zadig) o implementar el generador de instrucciones con la API de bajo nivel (add_raster_data, add_print, ...).

Notas:

- Asegúrate de seleccionar en el driver la etiqueta "62 mm Continuous".
- Si la impresión sale rotada, ajusta `rotate='90'` a `None`.
