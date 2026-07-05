// Select 10 curated boards from pool.json and write them into editor-library.json
// slots 41-50 (edited:true), so they appear starred in the editor grid.
// Ramp: aim-window tightens 41->50; families alternate so neighbors differ.
const fs = require("fs"), path = require("path");
const pool = JSON.parse(fs.readFileSync(path.join(__dirname, "pool.json"), "utf8"));
const LIB = path.join(__dirname, "..", "editor-library.json");
const lib = JSON.parse(fs.readFileSync(LIB, "utf8"));

// each pick is unique by (family, tx, effMinB) within the pool
const picks = [
  { slot: 41, family: "chevron",  tx: 64,  minB: 6,  winW: 1.4 },
  { slot: 42, family: "rings",    tx: 153, minB: 6,  winW: 1.0 },
  { slot: 43, family: "totem",    tx: 74,  minB: 5,  winW: 0.7 },
  { slot: 44, family: "boxweave", tx: 68,  minB: 8,  winW: 0.7 },
  { slot: 45, family: "chevron",  tx: 63,  minB: 5,  winW: 0.5 },
  { slot: 46, family: "rings",    tx: 53,  minB: 7,  winW: 0.4 },
  { slot: 47, family: "funnel",   tx: 44,  minB: 6,  winW: 0.4 },
  { slot: 48, family: "totem",    tx: 91,  minB: 5,  winW: 0.4 },
  { slot: 49, family: "boxweave", tx: 46,  minB: 5,  winW: 0.2 },
  { slot: 50, family: "chevron",  tx: 67,  minB: 11, winW: 0.3 },
];

for (const p of picks) {
  const hits = pool.filter(b => b.family === p.family && b.tx === p.tx && b.g.effMinB === p.minB && b.g.winW === p.winW);
  if (hits.length !== 1) { console.error(`slot ${p.slot}: expected 1 match, got ${hits.length}`); process.exit(1); }
  const b = hits[0];
  lib[p.slot - 1] = { tx: b.tx, recipes: b.recipes, edited: true };
  console.log(`L${p.slot}  ${p.family.padEnd(9)} winW ${b.g.winW}°  minB ${b.g.effMinB}  ${b.g.bestB}b ${b.g.bestLen}pt`);
}
fs.writeFileSync(LIB, JSON.stringify(lib));
console.log("wrote slots 41-50 -> editor-library.json");
