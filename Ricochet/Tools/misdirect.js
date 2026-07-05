// Search for FAIR portal-misdirection levels across four flavors:
//   crossed  — two pairs, linkage crosses (near entrance sends you far)
//   twins    — two near-identical entrances, wildly different outcomes
//   chain    — portal exit drops into a second portal (>=2 teleports)
//   mixed    — bumper carom feeds a portal
// Fairness gate: solvable, no direct leak, special obstacles load-bearing,
// bounces 1-4, aim window >=1.5 deg, and distinct (<0.5 similarity) from the
// library and from each other. Misdirection quality is curated by eye from the
// printed winning path.
//   node Ricochet/Tools/misdirect.js
const fs = require("fs"), path = require("path");
const { solveBoard, similarity, castRay, buildGeo } = require("./band6.js");
const LIB = JSON.parse(fs.readFileSync(path.join(__dirname, "..", "editor-library.json"), "utf8"));
const ri = (a, b) => a + Math.floor(Math.random() * (b - a + 1));

function ev(b) {
  const m = solveBoard(b.recipes, b.tx);
  if (!m.bestPath) return { ok: false };
  const aim = m.windows.filter(w => w.b - w.a >= 0.15);
  const win = aim.filter(w => w.minB === m.effMinB).sort((x, y) => (y.b - y.a) - (x.b - x.a))[0];
  const w = win ? +(win.b - win.a).toFixed(1) : 0;
  const path = m.bestPath;
  const tpCount = path.filter(p => p[2] === "tp").length;
  const bumps = b.recipes.filter(r => r.kind === "bumper");
  const bumpTouched = bumps.filter(bp => path.some(p => Math.abs(Math.hypot(p[0] - bp.cx, p[1] - bp.cy) - bp.r) < 2.5)).length;
  return {
    ok: true, w, b: m.bestBounces, direct: +m.direct.toFixed(1),
    tpCount, bumpTouched, nBump: bumps.length, path,
  };
}

const families = {
  crossed() {                                  // entrances spread, exits swapped across
    const side = ri(0, 1) ? "R" : "L";
    const tx = side === "R" ? ri(140, 165) : ri(35, 60);
    const exWin = side === "R" ? ri(140, 165) : ri(35, 60);   // winning exit on target side
    const exDec = side === "R" ? ri(35, 60) : ri(140, 165);   // decoy exit on far side
    return { family: "crossed", tx, recipes: [
      { kind: "portal", ax: ri(55, 80), ay: ri(105, 125), bx: exWin, by: ri(165, 178), r: 12 },
      { kind: "portal", ax: ri(120, 145), ay: ri(105, 125), bx: exDec, by: ri(150, 170), r: 12 },
    ] };
  },
  twins() {                                     // two near-identical entrances
    const tx = ri(80, 120);
    const ex = ri(20, 45);                       // decoy exit, far corner
    return { family: "twins", tx, recipes: [
      { kind: "portal", ax: ri(88, 96), ay: ri(115, 128), bx: tx + ri(-6, 6), by: ri(166, 176), r: 11 },
      { kind: "portal", ax: ri(104, 112), ay: ri(115, 128), bx: ex, by: ri(55, 80), r: 11 },
    ] };
  },
  chain() {                                     // exit of pair 1 falls into pair 2
    // A chain is only load-bearing when it's the UNIQUE route, so both the
    // second portal's entry and the target are sealed in rooms. Ball path:
    // open P1-A -> relay room (P1-B + P2-A) -> target room (P2-B + target).
    // Heading is preserved through portals, so vertical alignment carries it.
    const relayLeft = ri(0, 1) === 0;
    const relayX = relayLeft ? ri(45, 62) : ri(138, 155);
    const tgtLeft = ri(0, 1) === 0;
    const tx = tgtLeft ? ri(40, 62) : ri(138, 160);
    const p1ax = ri(78, 122);
    const p1by = ri(110, 118), p2ay = ri(142, 150);
    return { family: "chain", tx, recipes: [
      { kind: "box", x1: relayX - 30, y1: 95, x2: relayX + 30, y2: 162 },
      { kind: "box", x1: tx - 32, y1: 158, x2: tx + 32, y2: 206 },
      { kind: "portal", ax: p1ax, ay: 70, bx: relayX, by: p1by, r: 12 },
      { kind: "portal", ax: relayX, ay: p2ay, bx: tx, by: 170, r: 12 },
    ] };
  },
  mixed() {                                      // bumper kicks into a portal
    const tx = ["L", "R"][ri(0, 1)] === "L" ? ri(35, 60) : ri(140, 165);
    const cw = ri(20, 28), ct = ri(110, 130);
    return { family: "mixed", tx, recipes: [
      { kind: "line", x1: 100 - cw / 2, y1: 42, x2: 100 - cw / 2, y2: ct },
      { kind: "line", x1: 100 + cw / 2, y1: 42, x2: 100 + cw / 2, y2: ct },
      { kind: "bumper", cx: ri(86, 114), cy: ct + ri(12, 26), r: ri(15, 19) },
      { kind: "portal", ax: ri(40, 160), ay: ri(120, 150), bx: tx + ri(-6, 6), by: ri(166, 178), r: 12 },
    ] };
  },
};

function valid(fam, e) {
  if (!e.ok) return false;
  if (e.direct !== 0) return false;
  if (e.b < 1 || e.b > 4) return false;
  // Chains are comprehension puzzles (read the wiring), so a wider window is
  // fine; the other families are precision-ish and stay tighter.
  const wMax = fam === "chain" ? 26 : 14;
  if (e.w < 1.5 || e.w > wMax) return false;
  if (fam === "chain") return e.tpCount >= 2;
  if (fam === "mixed") return e.tpCount >= 1 && e.bumpTouched >= 1;
  return e.tpCount >= 1;                          // crossed / twins
}

const CAP = 3;
const kept = [], famCount = {};
const distinct = c => [...LIB, ...kept].every(k => similarity(c, k) < 0.5);
const names = Object.keys(families);
for (let i = 0; i < 600000 && kept.length < 12; i++) {
  const fam = names[i % names.length];
  if ((famCount[fam] || 0) >= CAP) continue;
  const c = families[fam]();
  const e = ev(c);
  if (!valid(fam, e) || !distinct(c)) continue;
  c._e = e;
  kept.push(c); famCount[fam] = (famCount[fam] || 0) + 1;
}

console.log("kept", kept.length, "by family:", famCount);
for (const k of kept) {
  const e = k._e;
  const pts = e.path.map(p => `(${Math.round(p[0])},${Math.round(p[1])}${p[2] === "tp" ? "*" : ""})`).join(" ");
  console.log(`\n${k.family}  tx${k.tx}  b${e.b} win${e.w}° tp${e.tpCount}${k.recipes.some(r => r.kind === "bumper") ? " bump" + e.bumpTouched : ""}`);
  console.log("  " + pts);
}
fs.writeFileSync(path.join(__dirname, "misdirect-out.json"),
  JSON.stringify(kept.map(k => ({ name: k.family, slot: 10, tx: k.tx, recipes: k.recipes })), null, 0));
console.log("\n-> misdirect-out.json");
