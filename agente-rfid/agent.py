import os
import time
import requests
import keyboard
from dotenv import load_dotenv

load_dotenv()
SERVER = os.getenv("SERVER", "http://localhost:3000")
READER_ID = os.getenv("READER_ID", "lector-entrada-1")
PREFIX = os.getenv("PREFIX", "")  # ej: "[" si lo configuraste en el lector

buffer = ""
last_ts = 0


def flush_if_card():
    global buffer
    card = buffer
    buffer = ""
    if not card:
        return

    if PREFIX and card.startswith(PREFIX):
        card = card[len(PREFIX):]

    # Ajusta si tus tarjetas no son solo dígitos/letras
    card = "".join(ch for ch in card if ch.isalnum())
    if not card:
        return

    try:
        r = requests.post(
            f"{SERVER}/rfid",
            json={"code": card, "readerId": READER_ID},
            timeout=2
        )
        print("Enviado:", card, "->", r.status_code)
    except Exception as e:
        print("Error enviando:", e)


def on_key(e):
    # La lectora “teclea” muy rápido; humano no. Cortamos si hay pausa larga.
    global buffer, last_ts
    t = time.time()
    if (t - last_ts) > 0.3:
        buffer = ""
    last_ts = t

    if e.event_type != "down":
        return

    k = e.name
    if k == "enter":
        flush_if_card()
        return

    if k.startswith("num "):  # teclado numérico
        k = k.replace("num ", "")

    if len(k) == 1 and (k.isalnum() or (PREFIX and k == PREFIX)):
        buffer += k


if __name__ == "__main__":
    print("Agente activo. Pasa una tarjeta… (Ctrl+C para salir)")
    keyboard.hook(on_key)
    keyboard.wait()
