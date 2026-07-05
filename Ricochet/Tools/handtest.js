// Trace hand-designed boards: prints bounce count, aim window, and the actual
// solution path (corner points) so I can confirm the shot reads as a clean bank.
//   node Ricochet/Tools/handtest.js hand.json
const fs = require("fs"), path = require("path");
const { solveBoard, grade } = require("./band6.js");
const file = process.argv[2] || path.join(__dirname, "hand.json");
const boards = JSON.parse(fs.readFileSync(file, "utf8"));
for (const b of boards) {
  const m = solveBoard(b.recipes, b.tx);
  const slot = b.slot || 10;
  const g = grade(b, slot);
  const pts = (m.bestPath || []).map(p => `(${Math.round(p[0])},${Math.round(p[1])})`).join(" → ");
  const aim = m.windows.filter(w => w.b - w.a >= 0.15);
  const win = aim.filter(w => w.minB === m.effMinB).sort((x, y) => (y.b - y.a) - (x.b - x.a))[0];
  const w = win ? +(win.b - win.a).toFixed(2) : 0;
  console.log(`${b.name || "?"}  [slot ${slot}, tx ${b.tx}]`);
  console.log(`  ${g.ok ? "✓" : "✗"} ${g.why.split("  ")[0]}   bounces ${m.bestBounces}   aim-window ${w}°   (total ${m.total.toFixed(1)}°)`);
  console.log(`  path: ship ${pts}`);
  console.log("");
}
