# print_agent/main.py
from flask import Flask, request, jsonify
try:
    # some brother_ql versions expose a module-level convert function
    from brother_ql.raster import BrotherQLRaster, convert as bq_convert
except Exception:
    from brother_ql.raster import BrotherQLRaster
    bq_convert = None
from brother_ql.backends.helpers import send
from PIL import Image
import io
import base64
import traceback
import logging
import tempfile
import os

PRINTER_MODEL = 'QL-700'
# Ajustar el identificador si cambia el VID:PID o usar spooler de Windows
# ejemplo VID:PID; ejecutar `python -m brother_ql` para listar
PRINTER_ID = 'usb://0x04f9:0x2042'
LABEL = '62'  # 62mm continuous

app = Flask(__name__)

# simple logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@app.after_request
def cors(r):
    r.headers['Access-Control-Allow-Origin'] = '*'
    r.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    r.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
    return r


@app.route('/print', methods=['POST', 'OPTIONS'])
def print_ticket():
    if request.method == 'OPTIONS':
        return ('', 204)
    # log basic request info to help debugging payload problems
    logger.info('Incoming print request: Content-Type=%s Content-Length=%s',
                request.content_type, request.content_length)
    # aceptar multipart/form-data con campo 'file' (blob) o JSON { png: dataURL }
    raw = None
    data_url = None
    # prioridad: archivo enviado por FormData
    if request.files and 'file' in request.files:
        f = request.files['file']
        try:
            raw = f.read()
        except Exception as e_f:
            logger.exception('No se pudo leer el archivo subido: %s', e_f)
            return jsonify(ok=False, msg=f'error leyendo archivo: {e_f}'), 400
    else:
        try:
            payload = request.get_json(force=True)
        except Exception:
            payload = {}
        data_url = payload.get('png')
        if not data_url:
            return jsonify(ok=False, msg='png dataURL o archivo requerido'), 400

        try:
            # soportar tanto dataURLs como raw base64
            if data_url.startswith('data:'):
                try:
                    b64 = data_url.split(',', 1)[1]
                except Exception:
                    return jsonify(ok=False, msg='dataURL malformado'), 400
            else:
                # puede que se envíe solo el base64 sin prefijo
                b64 = data_url

            try:
                raw = base64.b64decode(b64)
            except Exception as decode_err:
                logger.exception('Error decodificando base64: %s', decode_err)
                return jsonify(ok=False, msg=f'base64 inválido: {decode_err}'), 400
        except Exception as e_init:
            logger.exception('Error procesando payload: %s', e_init)
            return jsonify(ok=False, msg=f'payload inválido: {e_init}'), 400

    try:
        # escribir un volcado temporal para diagnóstico si PIL no lo reconoce
        diag_tmp = None
        try:
            diag_tmp = tempfile.NamedTemporaryFile(delete=False, suffix='.bin')
            diag_tmp.write(raw)
            diag_tmp.flush()
            diag_tmp.close()
            logger.info('Guardado temporal recibido en: %s (len=%d)',
                        diag_tmp.name, len(raw))
            # loguear primeros bytes en hex para detectar firma
            logger.info('Primeros bytes: %s', raw[:8].hex())
        except Exception as e_tmp:
            logger.warning(
                'No se pudo escribir archivo diagnóstico: %s', e_tmp)

        try:
            img = Image.open(io.BytesIO(raw)).convert('RGB')
        except Exception as img_err:
            logger.exception('PIL no identificó la imagen: %s', img_err)
            # devolver info útil para debugging local y mantener el archivo diagnóstico
            msg = 'PIL.UnidentifiedImageError: no se pudo identificar la imagen recibida.'
            if diag_tmp:
                msg += f' Volcado en: {diag_tmp.name}'
            return jsonify(ok=False, msg=msg), 400

        qlr = BrotherQLRaster(PRINTER_MODEL)
        qlr.exception_on_warning = True
        # brother_ql changed API across versions: try calling possible converters
        instructions = None
        # 1) try instance method first, but guard call in try/except
        if hasattr(qlr, 'convert'):
            try:
                instructions = qlr.convert(
                    [img], label=LABEL, rotate='90',  # 90° para “horizontal"
                    threshold=70, dither=False, compress=True, red=False,
                    dpi_600=False, cut=True  # << CORTE AUTOMÁTICO
                )
            except Exception as e_call:
                logger.warning("qlr.convert exists but failed: %s", e_call)
                instructions = None

        # 2) try module-level imported convert
        if instructions is None and bq_convert is not None:
            try:
                instructions = bq_convert(
                    [img], label=LABEL, rotate='90',
                    threshold=70, dither=False, compress=True, red=False,
                    dpi_600=False, cut=True
                )
            except Exception as e_call:
                logger.warning("bq_convert failed: %s", e_call)
                instructions = None

        # 3) nothing worked -> intentar fallback directo al spooler de Windows
        if instructions is None:
            logger.info(
                "No se encontraron métodos de conversión en brother_ql; usando fallback al spooler Windows")
            try:
                # guardar PNG temporal (usando el binario recibido)
                tmp = tempfile.NamedTemporaryFile(delete=False, suffix='.png')
                tmp.write(raw)
                tmp.close()
                try:
                    import win32print
                    import win32ui
                    import win32con
                    from PIL import ImageWin

                    printer_name = os.environ.get(
                        'PRINT_PRINTER') or win32print.GetDefaultPrinter()
                    logger.info(
                        "Fallback directo: enviando a impresora Windows: %s", printer_name)

                    hDC = win32ui.CreateDC()
                    hDC.CreatePrinterDC(printer_name)

                    # iniciar el documento/página antes de dibujar (GDI requiere StartDoc/StartPage antes del Draw)
                    hDC.StartDoc('Comedor Ticket')
                    hDC.StartPage()

                    bmp = Image.open(tmp.name)

                    printable_width = hDC.GetDeviceCaps(win32con.HORZRES)
                    printable_height = hDC.GetDeviceCaps(win32con.VERTRES)

                    dib = ImageWin.Dib(bmp)
                    # dib.draw debe llamarse dentro de la página; escalamos al área imprimible
                    dib.draw(hDC.GetHandleOutput(),
                             (0, 0, printable_width, printable_height))

                    hDC.EndPage()
                    hDC.EndDoc()
                    hDC.DeleteDC()

                    try:
                        os.unlink(tmp.name)
                    except Exception:
                        pass

                    return jsonify(ok=True, fallback='spooler')
                except Exception as win_err:
                    logger.exception(
                        "Fallback directo al spooler falló: %s", win_err)
                    try:
                        os.unlink(tmp.name)
                    except Exception:
                        pass
                    return jsonify(ok=False, msg=f"No se generaron instrucciones en brother_ql y fallback spooler falló: {win_err}"), 500
            except Exception as tmp_err:
                logger.exception(
                    "No se pudo crear archivo temporal para fallback: %s", tmp_err)
                return jsonify(ok=False, msg=f"No se generaron instrucciones en brother_ql y no se pudo crear tmp: {tmp_err}"), 500

        # Si llegamos aquí, tenemos 'instructions' válidas: intentamos enviar por USB
        try:
            send(instructions, printer_identifier=PRINTER_ID,
                 backend_identifier='pyusb')
            return jsonify(ok=True)
        except Exception as send_err:
            logger.warning("Error enviando por pyusb: %s", send_err)
            # intentar fallback a spooler de Windows
            try:
                # convertir la imagen original a un archivo temporal PNG
                tmp = tempfile.NamedTemporaryFile(delete=False, suffix='.png')
                tmp.write(raw)
                tmp.close()
                # intentar imprimir vía spooler de Windows
                try:
                    import win32print
                    import win32ui
                    import win32con
                    from PIL import ImageWin

                    printer_name = os.environ.get(
                        'PRINT_PRINTER') or win32print.GetDefaultPrinter()
                    logger.info(
                        "Fallback: enviando a impresora Windows: %s", printer_name)

                    hDC = win32ui.CreateDC()
                    hDC.CreatePrinterDC(printer_name)

                    # iniciar documento y página antes de dibujar
                    hDC.StartDoc('Comedor Ticket')
                    hDC.StartPage()

                    bmp = Image.open(tmp.name)

                    # obtener área imprimible
                    printable_width = hDC.GetDeviceCaps(win32con.HORZRES)
                    printable_height = hDC.GetDeviceCaps(win32con.VERTRES)

                    dib = ImageWin.Dib(bmp)
                    # escalar y dibujar dentro de la página
                    dib.draw(hDC.GetHandleOutput(),
                             (0, 0, printable_width, printable_height))

                    hDC.EndPage()
                    hDC.EndDoc()
                    hDC.DeleteDC()

                    try:
                        os.unlink(tmp.name)
                    except Exception:
                        pass

                    return jsonify(ok=True, fallback='spooler')
                except Exception as win_err:
                    logger.exception("Fallback spooler failed: %s", win_err)
                    try:
                        os.unlink(tmp.name)
                    except Exception:
                        pass
                    return jsonify(ok=False, msg=f"Error usb: {send_err}; fallback spooler error: {win_err}"), 500
            except Exception as tmp_err:
                logger.exception(
                    "No se pudo crear archivo temporal para fallback: %s", tmp_err)
                return jsonify(ok=False, msg=f"Error usb: {send_err}; no se pudo crear tmp: {tmp_err}"), 500
    except Exception as e:
        tb = traceback.format_exc()
        logger.exception("Error en print_ticket: %s", e)
        # devolver el traceback en el mensaje para debugging local (no recomendable en prod)
        return jsonify(ok=False, msg=str(e), traceback=tb), 500


if __name__ == '__main__':
    app.run(port=5001, host='127.0.0.1')
