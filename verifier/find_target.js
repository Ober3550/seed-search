#!/usr/bin/env node
// Find a concrete verification target: a <2k-radius body that is primary of a
// special SE resource, on a seed with good resource-pair coverage.
// Streams chunk files (avoids Node's readFileSync string-size limit).
const fs = require("fs");

const SPECIALS = ["se-vulcanite","se-cryonite","se-vitamelange","se-iridium-ore","se-holmium-ore","se-beryllium-ore"];
const COMBOS = [
  ["se-iridium-ore","se-vulcanite"],
  ["se-beryllium-ore","se-cryonite"],
  ["se-holmium-ore","kr-mineral-water"],
  ["se-vitamelange","kr-mineral-water","stone"],
  ["kr-imersite","kr-mineral-water"],
];
const MAX_R = 2000, MIN_R = 200;

function combosSatisfied(zones) {
  // count combos where all resources present (>0 rs) on some detailed body
  let n = 0;
  for (const c of COMBOS) {
    const ok = zones.some(z => z.rs && c.every(r => (z.rs[r]||0) > 0));
    if (ok) n++;
  }
  return n;
}

const files = process.argv.slice(2);
const candidates = [];
for (const f of files) {
  const content = fs.readFileSync(f, "utf8");
  for (const line of content.split("\n")) {
    if (!line.startsWith("{")) continue;
    let seed;
    try { seed = JSON.parse(line); } catch { continue; }
    const zones = seed.z || [];
    const combos = combosSatisfied(zones);
    for (const z of zones) {
      if (!z.r || z.r < MIN_R || z.r > MAX_R) continue;
      if (!z.rs || !z.p) continue;
      if (!SPECIALS.includes(z.p)) continue;
      if (z.water === "none") continue;
      if (z.enemy === "max" || z.enemy === "very_high") continue;
      // score: prefer more combos, then more distinct resources on the body, then smaller radius
      const nres = Object.values(z.rs).filter(v => v > 0.0001).length;
      candidates.push({
        worldSeed: seed.s, combos, name: z.n, type: z.t, zoneSeed: z.s,
        radius: z.r, primary: z.p, dv: z.dv, nres,
        temperature: z.temperature, water: z.water, moisture: z.moisture,
        aux: z.aux, enemy: z.enemy, trees: z.trees, cliff: z.cliff,
        score: combos * 1000 + nres * 10 - z.r / 500,
      });
    }
  }
}
candidates.sort((a,b) => b.score - a.score);
console.log(`# ${candidates.length} candidate <${MAX_R} bodies with special primary\n`);
for (const c of candidates.slice(0, 15)) {
  console.log(`world=${c.worldSeed} combos=${c.combos} ${c.name} (${c.type}) zoneSeed=${c.zoneSeed} r=${c.radius} primary=${c.primary} dv=${c.dv} nres=${c.nres} temp=${c.temperature} water=${c.water} enemy=${c.enemy}`);
}
