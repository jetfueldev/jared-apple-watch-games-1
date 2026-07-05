// Validate bumper/portal boards. Reports verdict, bounces, aim window, the path,
// and crucially whether the winning shot actually USES each special obstacle
// (load-bearing) — a bumper/portal the solver routes around is dead weight.
//   node Ricochet/Tools/mech.js [hand.json]
const fs = require("fs"), path = require("path");
const { solveBoard, similarity } = require("./band6.js");
const file = process.argv[2] || path.join(__dirname, "hand.json");
const boards = JSON.parse(fs.readFileSync(file, "utf8"));

function analyze(b) {
  const m = solveBoard(b.recipes, b.tx);
  const aim = m.windows.filter(w => w.b - w.a >= 0.15);
  const win = aim.filter(w => w.minB === m.effMinB).sort((x, y) => (y.b - y.a) - (x.b - x.a))[0];
  const w = win ? +(win.b - win.a).toFixed(2) : 0;
  const path = m.bestPath || [];
  const usesPortal = path.some(p => p[2] === "tp");
  const bumpers = b.recipes.filter(r => r.kind === "bumper");
  const touched = bumpers.map(bp => path.some(p => Math.abs(Math.hypot(p[0] - bp.cx, p[1] - bp.cy) - bp.r) < 2.0));
  const hasPortal = b.recipes.some(r => r.kind === "portal");
  // load-bearing verdict
  const dead = [];
  if (hasPortal && !usesPortal) dead.push("portal");
  touched.forEach((t, i) => { if (!t) dead.push("bumper" + (i + 1)); });
  let verdict = "OK";
  if (!m.bestPath) verdict = "UNSOLVABLE";
  else if (m.direct > 0) verdict = "DIRECT-LEAK " + m.direct.toFixed(1) + "°";
  else if (w < 1.5) verdict = "BRUTAL win " + w + "°";
  else if (m.bestBounces > 3) verdict = "TOO-MANY " + m.bestBounces + "b";
  else if (dead.length) verdict = "DEAD: " + dead.join(",");
  return { verdict, b: m.bestBounces, w, direct: +m.direct.toFixed(1), usesPortal, touched, path };
}

for (const b of boards) {
  const a = analyze(b);
  const flag = a.verdict === "OK" ? "✓" : "✗";
  const tags = [a.usesPortal ? "PORTAL✓" : null, ...a.touched.map((t, i) => "BUMP" + (i + 1) + (t ? "✓" : "✗"))].filter(Boolean).join(" ");
  console.log(`${flag} ${(b.name || "?").padEnd(22)} ${a.verdict.padEnd(16)} b${a.b} win${a.w}° ${tags}`);
  console.log("   " + a.path.map(p => `(${Math.round(p[0])},${Math.round(p[1])}${p[2] ? "*" : ""})`).join(" "));
}
// mutual distinctness
console.log("--- mutual similarity ---");
let maxSim = 0;
for (let i = 0; i < boards.length; i++) for (let j = i + 1; j < boards.length; j++) {
  const s = similarity(boards[i], boards[j]);
  if (s > maxSim) maxSim = s;
  if (s >= 0.5) console.log(`  DUP ${boards[i].name} ~ ${boards[j].name} = ${s.toFixed(2)}`);
}
console.log("  max pairwise similarity =", maxSim.toFixed(2), maxSim < 0.5 ? "(all distinct)" : "(DUPES!)");
