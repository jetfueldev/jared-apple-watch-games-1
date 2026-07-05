// Board validator — loads the editor's REAL solver (solveBoard) out of
// RicochetLevelEditor.html via a stubbed-DOM eval, then grades boards with the
// same rubric drawStats() uses. Drives band-6 authoring.
//
//   node Ricochet/Tools/band6.js                 # grade candidates.json
//   node Ricochet/Tools/band6.js lib 41 50       # grade editor-library.json slots 41..50
//
// Rubric (from drawStats): solvable, no direct leak for slot>=4,
// effMinB >= bandMin(slot), total window >= 0.15 deg, best shot <= 1400pt.

const fs = require("fs");
const path = require("path");

const HTML = path.join(__dirname, "..", "RicochetLevelEditor.html");
const LIB = path.join(__dirname, "..", "editor-library.json");
const CAND = path.join(__dirname, "candidates.json");

// ── load solver from the editor ────────────────────────────────────────────
function loadSolver() {
  const html = fs.readFileSync(HTML, "utf8");
  const body = html.match(/<script>([\s\S]*?)<\/script>/)[1];
  const P = { then() { return P; }, catch() { return P; } };
  const makeEl = () => new Proxy(function () {}, {
    get(t, k) {
      if (k === Symbol.toPrimitive) return () => 0;
      if (k === "valueOf") return () => 0;
      if (k === "toString") return () => "";
      if (k === "getContext") return () => makeEl();
      return makeEl();
    },
    set() { return true; }, apply() { return makeEl(); },
  });
  const document = {
    getElementById: () => makeEl(), createElement: () => makeEl(),
    querySelectorAll: () => [], querySelector: () => makeEl(),
    addEventListener: () => {}, body: makeEl(),
  };
  const window = { addEventListener: () => {}, devicePixelRatio: 1 };
  const localStorage = { getItem: () => null, setItem: () => {}, removeItem: () => {} };
  const navigator = { clipboard: { writeText: () => P } };
  const location = { protocol: "http:" };
  const fn = new Function(
    "document", "window", "localStorage", "navigator", "location",
    "requestAnimationFrame", "fetch", "confirm", "alert", "setTimeout",
    body + "\nreturn { solveBoard, flatten, bandMin, castRay, buildGeo };"
  );
  return fn(document, window, localStorage, navigator, location,
    () => 0, () => P, () => true, () => {}, () => 0);
}

const { solveBoard, flatten, bandMin, castRay, buildGeo } = loadSolver();

// canonical segment set for similarity: endpoints sorted, rounded to int
function sig(board) {
  const out = flatten(board.recipes).map(s => {
    let [x1, y1, x2, y2] = s.map(Math.round);
    if (x1 > x2 || (x1 === x2 && y1 > y2)) { [x1, y1, x2, y2] = [x2, y2, x1, y1]; }
    return [x1, y1, x2, y2];
  });
  for (const r of board.recipes) {
    if (r.kind === "bumper") out.push([Math.round(r.cx), Math.round(r.cy), Math.round(r.cx), Math.round(r.cy)]);
    else if (r.kind === "portal") {
      let [x1, y1, x2, y2] = [r.ax, r.ay, r.bx, r.by].map(Math.round);
      if (x1 > x2 || (x1 === x2 && y1 > y2)) { [x1, y1, x2, y2] = [x2, y2, x1, y1]; }
      out.push([x1, y1, x2, y2]);
    }
  }
  return out;
}
function segDist(a, b) { return Math.abs(a[0] - b[0]) + Math.abs(a[1] - b[1]) + Math.abs(a[2] - b[2]) + Math.abs(a[3] - b[3]); }
// fraction of A's segments that have a close partner in B (greedy), avg over both directions
function similarity(A, B, tol = 28) {
  const sA = sig(A), sB = sig(B);
  const match = (xs, ys) => {
    const used = new Array(ys.length).fill(false); let m = 0;
    for (const x of xs) { let bi = -1, bd = 1e9; for (let j = 0; j < ys.length; j++) { if (used[j]) continue; const d = segDist(x, ys[j]); if (d < bd) { bd = d; bi = j; } } if (bi >= 0 && bd <= tol) { used[bi] = true; m++; } }
    return m;
  };
  const m1 = match(sA, sB), m2 = match(sB, sA);
  const denom = Math.max(sA.length, sB.length) || 1;
  const txClose = Math.abs((A.tx || 0) - (B.tx || 0)) <= 8 ? 0 : -0.15;
  return Math.min(m1, m2) / denom + txClose;
}

function grade(board, slot) {
  const m = solveBoard(board.recipes, board.tx);
  const want = bandMin(slot);
  // window that actually carries the effMinB solution
  const aimable = m.windows.filter(w => w.b - w.a >= 0.15);
  const win = aimable.filter(w => w.minB === m.effMinB).sort((a, b) => (b.b - b.a) - (a.b - a.a))[0];
  const winW = win ? +(win.b - win.a).toFixed(2) : 0;
  let ok = true, why = `OK ${m.effMinB}+b  best ${m.bestBounces}b ${Math.round(m.bestLen)}pt  win ${winW}°  total ${m.total.toFixed(1)}°`;
  if (!m.windows.length) { ok = false; why = "✗ UNSOLVABLE"; }
  else if (slot >= 4 && m.direct > 0) { ok = false; why = `✗ DIRECT ${m.direct.toFixed(1)}° leak`; }
  else if (m.effMinB < want) { ok = false; why = `✗ LOW minB ${m.effMinB} < ${want}`; }
  else if (m.total < 0.15) { ok = false; why = `✗ BRUTAL ${m.total.toFixed(2)}°`; }
  else if (m.bestLen > 1400) { ok = false; why = `✗ LONG ${Math.round(m.bestLen)}pt > 1400`; }
  return { ok, why, effMinB: m.effMinB, winW, total: +m.total.toFixed(2), bestLen: Math.round(m.bestLen), bestB: m.bestBounces };
}

// ── generative search over distinct mechanic families ───────────────────────
const ri = (a, b) => a + Math.floor(Math.random() * (b - a + 1));
const pick = arr => arr[Math.floor(Math.random() * arr.length)];
const L = (x1, y1, x2, y2, abs) => ({ kind: "line", x1, y1, x2, y2, abs: !!abs });

const FAMILIES = {
  // clean: concentric/offset rings the ball must wrap around
  rings() {
    const tx = pick([ri(30, 70), ri(130, 170)]);
    const recipes = [];
    const n = ri(1, 2);
    for (let i = 0; i < n; i++) recipes.push({ kind: "ring", cx: ri(45, 155), cy: ri(95, 165), r: ri(24, 42), gapA: Math.random() * 2 * Math.PI - Math.PI, gapS: Math.PI / 4 + Math.random() * Math.PI / 1.6, segs: 16, abs: false });
    return { tx, recipes };
  },
  // clean: alternating diagonal staircase
  chevron() {
    const tx = ri(60, 140);
    const recipes = []; let y = ri(70, 95);
    const n = ri(3, 4);
    for (let i = 0; i < n; i++) { const left = i % 2 === 0; const x1 = left ? ri(10, 40) : ri(120, 175); const x2 = left ? ri(95, 140) : ri(40, 90); recipes.push(L(x1, y, x2, y + ri(18, 34))); y += ri(28, 42); }
    return { tx, recipes };
  },
  // chaotic: scattered short bumpers
  pinball() {
    const tx = ri(35, 165);
    const recipes = []; const n = ri(4, 5);
    for (let i = 0; i < n; i++) { const x = ri(20, 180), y = ri(60, 195), len = ri(18, 40), ang = (ri(20, 160)) * Math.PI / 180; recipes.push(L(x, y, Math.round(x + Math.cos(ang) * len), Math.round(y + Math.sin(ang) * len))); }
    return { tx, recipes };
  },
  // mixed: box wall the ball must go around
  boxweave() {
    const tx = pick([ri(30, 70), ri(130, 170)]);
    const recipes = [];
    recipes.push({ kind: "box", x1: ri(60, 90), y1: ri(120, 150), x2: ri(110, 150), y2: ri(150, 185), abs: false });
    recipes.push(L(ri(10, 50), ri(80, 110), ri(60, 110), ri(95, 130)));
    if (Math.random() < 0.6) recipes.push(L(ri(120, 180), ri(80, 120), ri(150, 195), ri(100, 140)));
    return { tx, recipes };
  },
  // corner funnel with a side hazard
  funnel() {
    const left = Math.random() < 0.5; const tx = left ? ri(24, 44) : ri(156, 176);
    const recipes = [];
    recipes.push(L(ri(40, 80), ri(150, 175), ri(110, 160), ri(150, 175)));
    recipes.push(L(left ? ri(60, 90) : ri(110, 140), ri(95, 125), left ? ri(110, 150) : ri(50, 90), ri(110, 130)));
    if (Math.random() < 0.5) recipes.push(L(left ? 8 : 192, ri(120, 150), left ? 8 : 192, ri(150, 185), true));
    return { tx, recipes };
  },
  // totem: vertical pillars at varied heights + one lintel (NOT the periscope)
  totem() {
    const tx = ri(70, 130);
    const recipes = [];
    recipes.push(L(ri(40, 70), ri(120, 160), ri(40, 70), ri(160, 200)));
    recipes.push(L(ri(130, 160), ri(110, 150), ri(130, 160), ri(150, 195)));
    recipes.push(L(ri(15, 60), ri(85, 105), ri(140, 185), ri(85, 105)));
    return { tx, recipes };
  },
  // sparse: 1-2 angled deflectors — good for low bounce counts (bands 2-3)
  sparse() {
    const tx = ri(25, 175);
    const recipes = [L(ri(20, 110), ri(80, 170), ri(70, 185), ri(70, 175))];
    if (Math.random() < 0.7) recipes.push(L(ri(60, 150), ri(95, 160), ri(110, 195), ri(85, 150)));
    if (Math.random() < 0.25) recipes.push({ kind: "ring", cx: ri(45, 155), cy: ri(100, 160), r: ri(26, 42), gapA: Math.random() * 2 * Math.PI - Math.PI, gapS: Math.PI / 3 + Math.random() * Math.PI / 1.6, segs: 16, abs: false });
    return { tx, recipes };
  },
  // mixed: 2-3 random primitives (lines + occasional box/ring/hazard)
  mixed() {
    const tx = ri(25, 175);
    const n = ri(2, 3);
    const recipes = [];
    for (let i = 0; i < n; i++) {
      const r = Math.random();
      if (r < 0.7) { const x = ri(20, 180), y = ri(70, 195), len = ri(40, 90), ang = ri(15, 165) * Math.PI / 180; recipes.push(L(x, y, Math.round(x + Math.cos(ang) * len), Math.round(y + Math.sin(ang) * len), Math.random() < 0.12)); }
      else if (r < 0.85) recipes.push({ kind: "box", x1: ri(50, 110), y1: ri(110, 160), x2: ri(120, 170), y2: ri(150, 190), abs: false });
      else recipes.push({ kind: "ring", cx: ri(45, 155), cy: ri(95, 165), r: ri(24, 42), gapA: Math.random() * 2 * Math.PI - Math.PI, gapS: Math.PI / 4 + Math.random() * Math.PI / 1.6, segs: 16, abs: false });
    }
    return { tx, recipes };
  },
};

// search a family for boards whose effMinB is in [bLo,bHi], graded at `slot`,
// intended solution is the easy one (bestB close to effMinB), window aimable.
function search(famName, n, slot, bLo, bHi, wLo, wHi) {
  const out = [];
  const fam = FAMILIES[famName];
  for (let t = 0; t < 120000 && out.length < n; t++) {
    const b = fam();
    const g = grade(b, slot);
    if (!g.ok) continue;
    if (g.effMinB < bLo || g.effMinB > bHi) continue;
    if (g.bestB > g.effMinB + 1) continue;        // no hidden thin cheese shot
    if (g.winW < wLo || g.winW > wHi) continue;
    b.family = famName; b.g = g;
    out.push(b);
  }
  return out;
}

module.exports = { solveBoard, flatten, bandMin, grade, similarity, sig, castRay, buildGeo };

// ── run ─────────────────────────────────────────────────────────────────────
const args = require.main === module ? process.argv.slice(2) : ["__noop__"];
if (args[0] === "sim") {
  const lib = JSON.parse(fs.readFileSync(LIB, "utf8"));
  const thresh = +(args[1] || 0.6);
  const pairs = [];
  for (let i = 0; i < lib.length; i++)
    for (let j = i + 1; j < lib.length; j++) {
      const s = similarity(lib[i], lib[j]);
      if (s >= thresh) pairs.push([i + 1, j + 1, +s.toFixed(2)]);
    }
  pairs.sort((a, b) => b[2] - a[2]);
  console.log(`near-duplicate pairs (similarity >= ${thresh}):`);
  for (const [a, b, s] of pairs) console.log(`  L${a} ~ L${b}   ${s}`);
  // cluster: connected components
  const adj = {}; for (const [a, b] of pairs) { (adj[a] ||= []).push(b); (adj[b] ||= []).push(a); }
  const seen = new Set(), clusters = [];
  for (const n of Object.keys(adj).map(Number)) { if (seen.has(n)) continue; const stack = [n], c = []; while (stack.length) { const x = stack.pop(); if (seen.has(x)) continue; seen.add(x); c.push(x); for (const y of adj[x]) if (!seen.has(y)) stack.push(y); } clusters.push(c.sort((a, b) => a - b)); }
  console.log(`\nclusters:`); for (const c of clusters) console.log(`  [${c.join(", ")}]`);
}
else if (args[0] === "gen") {
  // gen <slot> <minB> <maxB> <winLo> <winHi>  → pool.json
  const slot = +(args[1] || 45), bLo = +(args[2] || 5), bHi = +(args[3] || 12);
  const wLo = +(args[4] || 0.2), wHi = +(args[5] || 1.6);
  const fams = Object.keys(FAMILIES);
  const pool = [];
  for (const f of fams) {
    const got = search(f, 10, slot, bLo, bHi, wLo, wHi);
    for (const b of got) pool.push(b);
    console.log(`-- ${f}: found ${got.length}`);
  }
  pool.sort((a, b) => b.g.winW - a.g.winW); // easy→hard
  for (const b of pool) console.log(`${b.family.padEnd(9)} winW ${b.g.winW}°  minB ${b.g.effMinB}  best ${b.g.bestB}b ${b.g.bestLen}pt  tx ${b.tx}  ::  ${JSON.stringify(b.recipes)}`);
  fs.writeFileSync(path.join(__dirname, "pool.json"), JSON.stringify(pool, null, 0));
  console.log(`\npool: ${pool.length} boards → Tools/pool.json`);
}
else if (args[0] === "lib") {
  const lib = JSON.parse(fs.readFileSync(LIB, "utf8"));
  const a = +(args[1] || 1), b = +(args[2] || lib.length);
  for (let i = a; i <= b; i++) { const g = grade(lib[i - 1], i); console.log(`L${i}  ${g.ok ? "✓" : " "} ${g.why}`); }
} else if (args[0] !== "__noop__") {
  const cands = JSON.parse(fs.readFileSync(CAND, "utf8"));
  for (const c of cands) {
    const slot = c.slot || 45;
    const g = grade(c, slot);
    console.log(`[${slot}] ${c.name || ""}  ${g.ok ? "✓" : "✗"}  ${g.why}`);
  }
}
