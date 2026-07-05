// Tiny zero-dependency bridge so the level editor can persist to a file
// Claude can read. Run:  node Ricochet/editor-server.js
// Then open the editor (file:// is fine — it POSTs here with CORS), or
// browse http://localhost:8777/ to load it served.
//
// Every Save / Add / Import / Reset in the editor writes the whole library
// to Ricochet/editor-library.json. That file is the thing Claude reads.

const http = require("http");
const fs = require("fs");
const path = require("path");

const DIR = __dirname;
const LIB = path.join(DIR, "editor-library.json");
const HTML = path.join(DIR, "RicochetLevelEditor.html");
const PORT = 8777;

function cors(res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
}

const server = http.createServer((req, res) => {
  cors(res);
  if (req.method === "OPTIONS") { res.writeHead(204); res.end(); return; }

  if (req.method === "GET" && req.url === "/ping") {
    res.writeHead(200, { "Content-Type": "text/plain" }); res.end("ok"); return;
  }

  if (req.method === "GET" && (req.url === "/" || req.url === "/index.html")) {
    fs.readFile(HTML, (e, buf) => {
      if (e) { res.writeHead(500); res.end("editor html not found"); return; }
      res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" }); res.end(buf);
    });
    return;
  }

  if (req.method === "GET" && req.url === "/library") {
    fs.readFile(LIB, "utf8", (e, txt) => {
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(e ? "null" : txt);
    });
    return;
  }

  if (req.method === "POST" && req.url === "/save") {
    let body = "";
    req.on("data", c => { body += c; if (body.length > 8e6) req.destroy(); });
    req.on("end", () => {
      try { JSON.parse(body); } catch (_) { res.writeHead(400); res.end("bad json"); return; }
      fs.writeFile(LIB, body, e => {
        if (e) { res.writeHead(500); res.end("write failed"); return; }
        const n = (() => { try { return JSON.parse(body).length; } catch (_) { return "?"; } })();
        console.log(`saved ${n} boards → editor-library.json  (${new Date().toLocaleTimeString()})`);
        res.writeHead(200); res.end("ok");
      });
    });
    return;
  }

  res.writeHead(404); res.end("not found");
});

server.listen(PORT, "127.0.0.1", () => {
  console.log(`Ricochet editor bridge running`);
  console.log(`  open editor : http://localhost:${PORT}/   (or your existing file:// tab — it syncs here too)`);
  console.log(`  writes file : ${LIB}`);
});
