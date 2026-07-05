// Search portal/bumper families for VALIDATED, LOAD-BEARING, mutually-DISTINCT
// levels. A board is kept only if: solvable, no direct leak, the special obstacle
// is actually used by the winning line, bounces 1-3, aim window 1.5-7deg, and it
// is < 0.5 similar to every board already kept (and to the existing library).
//   node Ricochet/Tools/genset.js [count]
const fs = require("fs"), path = require("path");
const { solveBoard, similarity } = require("./band6.js");
const LIB = JSON.parse(fs.readFileSync(path.join(__dirname, "..", "editor-library.json"), "utf8"));
const ri = (a, b) => a + Math.floor(Math.random() * (b - a + 1));
const pickTx = side => side === "L" ? ri(35, 70) : side === "R" ? ri(130, 165) : ri(85, 115);

function ev(b) {
  const m = solveBoard(b.recipes, b.tx);
  const aim = m.windows.filter(w => w.b - w.a >= 0.15);
  const win = aim.filter(w => w.minB === m.effMinB).sort((x, y) => (y.b - y.a) - (x.b - x.a))[0];
  const w = win ? +(win.b - win.a).toFixed(2) : 0;
  const path = m.bestPath || [];
  const tp = path.some(p => p[2] === "tp");
  const bumps = b.recipes.filter(r => r.kind === "bumper");
  const allTouched = bumps.every(bp => path.some(p => Math.abs(Math.hypot(p[0] - bp.cx, p[1] - bp.cy) - bp.r) < 2.5));
  const usesPortal = b.recipes.some(r => r.kind === "portal");
  const ok = !!m.bestPath && m.direct === 0 && m.bestBounces >= 1 && m.bestBounces <= 3
    && w >= 1.5 && w <= 7 && (!usesPortal || tp) && allTouched;
  return { ok, w, b: m.bestBounces };
}

const families = {
  sealedRoom() {                         // target walled in; portal is the only door
    const tx = pickTx(["L", "C", "R"][ri(0, 2)]);
    const hw = ri(26, 30);
    return { family: "sealedRoom", tx, recipes: [
      { kind: "line", x1: tx - hw, y1: 170, x2: tx + hw, y2: 170 },
      { kind: "line", x1: tx - hw, y1: 170, x2: tx - hw, y2: 216 },
      { kind: "line", x1: tx + hw, y1: 170, x2: tx + hw, y2: 216 },
      { kind: "portal", ax: tx, ay: ri(112, 132), bx: tx, by: 176, r: ri(10, 13) } ] };
  },
  throughWall() {                        // full wall splits board; portal teleports across
    const side = ri(0, 1) ? "R" : "L";
    const wx = side === "R" ? ri(112, 125) : ri(75, 88);
    const tx = side === "R" ? ri(150, 170) : ri(30, 50);
    const ax = side === "R" ? ri(60, 95) : ri(105, 140);
    return { family: "throughWall", tx, recipes: [
      { kind: "line", x1: wx, y1: 0, x2: wx, y2: 214 },
      { kind: "portal", ax, ay: ri(115, 140), bx: tx + ri(-8, 8), by: ri(140, 160), r: ri(11, 13) } ] };
  },
  bankPortal() {                         // a ledge blocks the portal mouth; bank into it
    const tx = pickTx("C");
    const hw = 28;
    const led = ri(0, 1) ? "L" : "R";
    const ledge = led === "L"
      ? { kind: "line", x1: 0, y1: ri(120, 140), x2: ri(70, 90), y2: ri(120, 140) }
      : { kind: "line", x1: ri(110, 130), y1: ri(120, 140), x2: 200, y2: ri(120, 140) };
    return { family: "bankPortal", tx, recipes: [
      { kind: "line", x1: tx - hw, y1: 170, x2: tx + hw, y2: 170 },
      { kind: "line", x1: tx - hw, y1: 170, x2: tx - hw, y2: 216 },
      { kind: "line", x1: tx + hw, y1: 170, x2: tx + hw, y2: 216 },
      ledge,
      { kind: "portal", ax: ri(40, 160), ay: ri(95, 120), bx: tx, by: 176, r: ri(10, 13) } ] };
  },
  chuteBumper() {                        // up the chute, glance off the peg to a side target
    const tx = ["L", "R"][ri(0, 1)] === "L" ? ri(35, 60) : ri(140, 165);
    const cw = ri(22, 32), ct = ri(108, 135);
    return { family: "chuteBumper", tx, recipes: [
      { kind: "line", x1: 100 - cw / 2, y1: 42, x2: 100 - cw / 2, y2: ct },
      { kind: "line", x1: 100 + cw / 2, y1: 42, x2: 100 + cw / 2, y2: ct },
      { kind: "bumper", cx: ri(84, 118), cy: ct + ri(10, 28), r: ri(14, 20) } ] };
  },
  twoPortal() {                          // two pairs, only one exit reaches the alien
    const tx = pickTx(["L", "R"][ri(0, 1)]);
    return { family: "twoPortal", tx, recipes: [
      { kind: "portal", ax: ri(60, 90), ay: ri(100, 130), bx: tx + ri(-6, 6), by: ri(150, 168), r: 11 },
      { kind: "portal", ax: ri(110, 140), ay: ri(100, 130), bx: ri(20, 40), by: ri(60, 90), r: 11 } ] };
  },
};

const want = parseInt(process.argv[2] || "15", 10);
const kept = [], famCount = {};
const CAP = 3;
const distinct = c => [...LIB, ...kept].every(k => similarity(c, k) < 0.5);
for (let i = 0; i < 400000 && kept.length < want; i++) {
  const names = Object.keys(families);
  const fam = names[i % names.length];
  if ((famCount[fam] || 0) >= CAP) continue;
  const c = families[fam]();
  const e = ev(c);
  if (!e.ok || !distinct(c)) continue;
  c._w = e.w; c._b = e.b;
  kept.push(c); famCount[fam] = (famCount[fam] || 0) + 1;
}
console.log(`kept ${kept.length}/${want}   by family:`, famCount);
for (const k of kept) console.log(`  ${k.family.padEnd(12)} tx${k.tx} b${k._b} win${k._w}°`);
fs.writeFileSync(path.join(__dirname, "genset-out.json"),
  JSON.stringify(kept.map(k => ({ name: k.family, slot: 10, tx: k.tx, recipes: k.recipes })), null, 0));
console.log("-> genset-out.json");
