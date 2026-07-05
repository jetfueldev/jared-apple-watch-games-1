// Replace near-duplicate boards with distinct, band-appropriate ones from the pools.
// Keeps one representative per cluster; fills the rest greedily with boards that are
// dissimilar (< THRESH) to every other board in the resulting library.
const fs = require("fs"), path = require("path");
const { similarity, grade } = require("./band6.js");

const LIB = path.join(__dirname, "..", "editor-library.json");
const lib = JSON.parse(fs.readFileSync(LIB, "utf8"));
const pools = {
  2: JSON.parse(fs.readFileSync(path.join(__dirname, "pool-b2.json"), "utf8")),
  3: JSON.parse(fs.readFileSync(path.join(__dirname, "pool-b3.json"), "utf8")),
  4: JSON.parse(fs.readFileSync(path.join(__dirname, "pool-b4.json"), "utf8")),
};
const THRESH = 0.5;

// slot -> which band pool to draw from. Kept reps (15,21,31,38) are omitted.
const plan = [
  [18, 2], [20, 2],
  [22, 3], [23, 3], [24, 3], [28, 3], [29, 3], [30, 3],
  [32, 4], [34, 4], [35, 4], [36, 4], [37, 4], [40, 4],
];

// widest windows first so earlier slots in each band tend to be the gentler ones
for (const b of [...pools[2], ...pools[3], ...pools[4]]) b._w = b.g.winW;
const sortPool = p => [...p].sort((a, b) => b._w - a._w);

const used = new Set();
function maxSimToLib(cand, skipSlot) {
  let mx = 0;
  for (let i = 0; i < lib.length; i++) {
    if (i + 1 === skipSlot) continue;
    mx = Math.max(mx, similarity(cand, lib[i]));
  }
  return mx;
}

plan.sort((a, b) => a[0] - b[0]);
for (const [slot, band] of plan) {
  const candidates = sortPool(pools[band]);
  let chosen = null;
  for (const c of candidates) {
    if (used.has(c)) continue;
    if (maxSimToLib(c, slot) >= THRESH) continue;
    chosen = c; break;
  }
  if (!chosen) { console.error(`slot ${slot}: no distinct candidate found`); process.exit(1); }
  used.add(chosen);
  lib[slot - 1] = { tx: chosen.tx, recipes: chosen.recipes, edited: true };
  const g = grade(lib[slot - 1], slot);
  console.log(`L${slot} (band ${band})  ${chosen.family.padEnd(9)} minB ${g.effMinB}  ${g.bestB}b ${g.bestLen}pt  win ${g.winW}°`);
}

fs.writeFileSync(LIB, JSON.stringify(lib));
console.log(`\nreplaced ${plan.length} boards -> editor-library.json`);
