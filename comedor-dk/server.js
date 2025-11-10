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

// Simple proxy for /api/* to the Laravel API. This allows frontend code
// served by this server to call `/api/...` and have requests forwarded.
app.use('/api', async (req, res) => {
  try {
    const target = `${API_URL}${req.originalUrl}`;
    const opts = {
      method: req.method,
      headers: Object.assign({}, req.headers),
    };

    // Remove host header to avoid conflicts with target host
    delete opts.headers.host;

    // forward body for non-GET/HEAD
    if (req.method !== 'GET' && req.method !== 'HEAD') {
      // assume JSON
      opts.body = JSON.stringify(req.body || {});
      opts.headers['content-type'] = req.headers['content-type'] || 'application/json';
    }

    const r = await fetch(target, opts);
    // copy status and headers
    res.status(r.status);
    r.headers.forEach((v, k) => {
      // avoid sending hop-by-hop headers
      if (k.toLowerCase() === 'transfer-encoding') return;
      res.set(k, v);
    });
    const text = await r.text();
    // try to send JSON parsed if possible
    const ct = r.headers.get('content-type') || '';
    if (ct.includes('application/json')) {
      try { return res.send(JSON.parse(text)); } catch(e) { }
    }
    return res.send(text);
  } catch (err) {
    console.error('api proxy error', err && err.message);
    return res.status(502).json({ ok: false, msg: 'proxy error' });
  }
});

// --- RFID ---
app.post("/rfid", async (req, res) => {
  const { code, readerId, name } = req.body || {};
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
    submittedName: name || null,
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

const PORT = process.env.PORT || 3000;
app.use(express.static("public"));
server.listen(PORT, "0.0.0.0", () =>
  console.log(`RT en http://0.0.0.0:${PORT}`)
);
