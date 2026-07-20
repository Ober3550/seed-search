#!/usr/bin/env node
// calibration/derive.js
// Derives the calibration constant k:
//   estimated_total_ore = k × fsr × area × land_factor
//
// Reads all seed-*.json results files and computes k per resource.
const fs = require("fs");
const path = require("path");

const resultsDir = path.join(__dirname, "results");
const files = fs
  .readdirSync(resultsDir)
  .filter((f) => f.startsWith("seed-") && f.endsWith(".json"));

if (files.length === 0) {
  console.log("No calibration results found. Run run.sh first.");
  process.exit(0);
}

// Freq multiplier used for each run (extracted from filename isn't easy, so we
// group by seed and infer from data patterns)
const allResults = [];
for (const fn of files) {
  const data = JSON.parse(fs.readFileSync(path.join(resultsDir, fn), "utf8"));
  allResults.push(data);
}

// For each result, compute: ore_per_tile = ore / land_tiles
// The FSR for freq=f, size=f, rich=1.0 is: f × f × 1.0 = f²
// But we don't know which freq was used. Let's infer from the iron count:
// We know radius=300 was used for the freq sweep, radius=500 for baseline
console.log("=== Calibration Results ===\n");

// Group by radius
const groups = {};
for (const r of allResults) {
  const key = `r${r.radius}`;
  if (!groups[key]) groups[key] = [];
  groups[key].push(r);
}

for (const [key, results] of Object.entries(groups)) {
  const radius = results[0].radius;
  const area = results[0].total_tiles;

  console.log(
    `--- radius=${radius}, area=${area.toLocaleString()} tiles (${results.length} tests) ---`,
  );

  // Compute stats per resource type
  const resources = ["iron-ore", "copper-ore", "coal"];
  for (const res of resources) {
    const oreTotals = results
      .map(
        (r) =>
          ((r.resources[res] || {}).total || 0) / (r.land_tiles || area),
      )
      .sort((a, b) => a - b);

    const avg = oreTotals.reduce((a, b) => a + b, 0) / oreTotals.length;
    const median = oreTotals[Math.floor(oreTotals.length / 2)];
    const min = oreTotals[0];
    const max = oreTotals[oreTotals.length - 1];

    // For freq=1, size=1, rich=1: FSR = 1.0
    // k = avg_ore_per_tile / 1.0
    console.log(
      `  ${res.padEnd(14)} ore/tile: avg=${avg.toFixed(2)} median=${median.toFixed(2)} min=${min.toFixed(2)} max=${max.toFixed(2)}`,
    );
    console.log(`                    k (FSR→ore):  ${avg.toFixed(2)}`);
  }
  console.log();
}

// Now: for each run that used freq=f, size=f, rich=1, compute:
//   k = ore / (land_tiles × f × f × 1)
// We need to know freq. Let's look for patterns in the data.
// Seeds 10001, 10002, 10003 had freq=1, 2, 4 sweeps.
// The freq can be inferred by comparing iron counts across runs for same seed.
console.log("=== Per-seed freq analysis ===\n");

// Group by seed
const bySeed = {};
for (const r of allResults) {
  const s = String(r.seed);
  if (!bySeed[s]) bySeed[s] = [];
  bySeed[s].push(r);
}

for (const [seed, runs] of Object.entries(bySeed)) {
  if (runs.length < 2) continue;

  // Sort by total iron to identify freq levels
  runs.sort(
    (a, b) =>
      ((a.resources["iron-ore"] || {}).total || 0) -
      ((b.resources["iron-ore"] || {}).total || 0),
  );

  console.log(`--- seed ${seed} (${runs.length} freq levels) ---`);
  const baseIron =
    ((runs[0].resources["iron-ore"] || {}).total || 0) /
    runs[0].land_tiles;

  for (const run of runs) {
    const iron =
      ((run.resources["iron-ore"] || {}).total || 0) / run.land_tiles;
    const ratio = (iron / baseIron).toFixed(2);
    console.log(
      `  iron/tile=${iron.toFixed(2)}  ratio_vs_lowest=${ratio}x`,
    );
  }
  console.log();
}

// Summary: recommended k values
console.log("=== Recommended calibration constants ===\n");
console.log("For solid resources (iron, copper, coal, stone,");
console.log("vulcanite, cryonite, holmium, beryllium, iridium,");
console.log("vitamelange, imersite, naquium, rare metals):\n");

const allIron = allResults
  .filter((r) => r.radius <= 500) // exclude larger radii
  .map((r) => ((r.resources["iron-ore"] || {}).total || 0) / r.land_tiles);

const averageOrePerTile = allIron.reduce((a, b) => a + b, 0) / allIron.length;

console.log(
  `  k_solid ≈ ${averageOrePerTile.toFixed(2)} ore/tile per FSR unit`,
);
console.log(
  `  (based on ${allIron.length} samples, radius 300-500, freq 1-4)`,
);
console.log();
console.log(
  `  Yield = k × FSR × πr² × water_factor`,
);
console.log(
  `  Example: planet r=5000, water=med, FSR=1.0`,
);
const r = 5000;
const area = Math.PI * r * r;
const waterFactor = 0.5; // med
const estimatedYield =
  averageOrePerTile * 1.0 * area * waterFactor;
console.log(
  `    = ${averageOrePerTile.toFixed(2)} × 1.0 × ${(area / 1e6).toFixed(1)}M × ${waterFactor} ≈ ${(estimatedYield / 1e6).toFixed(1)}M items`,
);
