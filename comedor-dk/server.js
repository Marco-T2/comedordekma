// server.js
const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const cors = require("cors");

// import dinámico de node-fetch (CommonJS)
const fetch = (...a) => import("node-fetch").then(({ default: f }) => f(...a));

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

app.use(cors());
app.use(express.json());

const ROOM = "comedor-1";
const API_URL = "http://127.0.0.1:8000"; // Laravel

// --- RFID ---
app.post("/rfid", async (req, res) => {
  const { code, readerId } = req.body || {};
  if (!code) return res.status(400).json({ ok: false, msg: "code requerido" });

  let result = { ok: false, msg: "Laravel no responde" };
  try {
    const r = await fetch(`${API_URL}/api/validar/${encodeURIComponent(code)}`);
    if (r.ok) {
      result = await r.json();
    } else {
      const body = await r.json().catch(() => ({}));
      result = { ok: false, msg: body?.msg || `Error ${r.status}` };
    }
  } catch (_) {}

  io.to(ROOM).emit("access-event", {
    type: "rfid",
    code,
    readerId: readerId || "lector-1",
    result,
    ts: Date.now()
  });

  return res.json({ ok: true });
});

// --- BIOMETRIC ---
app.post("/biometric", async (req, res) => {
  const { cardId, readerId } = req.body || {};
  if (!cardId) return res.status(400).json({ ok: false, msg: "cardId requerido" });

  let result = { ok: false, msg: "Laravel no responde" };
  try {
    const r = await fetch(`${API_URL}/api/validar-card/${encodeURIComponent(cardId)}`);
    if (r.ok) {
      result = await r.json();
    } else {
      const body = await r.json().catch(() => ({}));
      result = { ok: false, msg: body?.msg || `Error ${r.status}` };
    }
  } catch (_) {}

  io.to(ROOM).emit("access-event", {
    type: "finger",
    cardId,
    readerId: readerId || "huella-1",
    result,
    ts: Date.now()
  });

  return res.json({ ok: true });
});

// --- Conexión de clientes ---
io.on("connection", (socket) => {
  socket.join(ROOM);
  socket.emit("joined", { room: ROOM });
});

const PORT = 3000;
app.use(express.static("public"));

server.listen(PORT, "0.0.0.0", () =>
  console.log(`RT en http://0.0.0.0:${PORT}`)
);
