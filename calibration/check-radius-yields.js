#!/usr/bin/env node
// check-radius-yields.js
// 1. Reads all JSONL seeds from output/, extracts zones (planets/moons) with radius < 4000
// 2. Cross-references with calibration data (actual Factorio ore counts)
// 3. Computes Zig-style yield estimates for comparison
//
// Usage: node verifier/check-radius-yields.js

const fs = require("fs");
const path = require("path");

// ── Zig-equivalent constants (from gen.zig) ───────────────────────────
const RESOURCE_NORM_PLANET = 22.02730826300005162466;
const RESOURCE_PRIMARY_BOOST = 0.5;
const RESOURCE_SECONDARY_IRREGULARITY = 0.75;
const RESOURCE_POWER = 1.5;

// resourceAmountScale (from gen.zig)
function resourceAmountScale(name) {
  switch (name) {
    case "iron-ore":
    case "copper-ore":
      return 1.0;
    case "coal":
      return 0.8;
    case "stone":
      return 0.7;
    case "uranium-ore":
      return 0.6;
    case "crude-oil":
      return 0.012;
    case "kr-mineral-water":
      return 0.012;
    default:
      return 1.0;
  }
}

// Water land fraction (from data.zig)
function landFraction(waterTag) {
  if (!waterTag) return 0.5;
  switch (waterTag) {
    case "water_none":
      return 0.95; // estimate
    case "water_low":
      return 0.8;
    case "water_med":
      return 0.5;
    case "water_high":
      return 0.3;
    case "water_max":
      return 0.15;
    default:
      return 0.5;
  }
}

// ── Yield estimation (replicates Zig computeYield) ────────────────────
function computeYield(score, radius, waterTag, resourceName) {
  const norm = RESOURCE_NORM_PLANET;
  const rawFsr = score * norm;
  const scale = resourceAmountScale(resourceName);
  const area = Math.PI * radius * radius;
  const landFrac = waterTag ? landFraction(waterTag) : 0.5;
  return (rawFsr * area * landFrac * scale) / 1_000_000.0;
}

function formatYield(yieldM) {
  if (yieldM < 0.5) return "0";
  if (yieldM >= 1000) return (yieldM / 1000).toFixed(1) + "B";
  if (yieldM >= 1) return Math.floor(yieldM) + "M";
  return yieldM.toFixed(1) + "M";
}

// ── Read calibration data ────────────────────────────────────────────
function loadCalibrationData() {
  const calibDir = path.join(__dirname, "..", "calibration", "results");
  const files = fs
    .readdirSync(calibDir)
    .filter((f) => f.startsWith("seed-") && f.endsWith(".json"));
  const bySeed = {};
  for (const f of files) {
    const data = JSON.parse(
      fs.readFileSync(path.join(calibDir, f), "utf8")
    );
    bySeed[data.seed] = data;
  }
  return bySeed;
}

// ── Parse yield string like "150M", "2.3B" to numeric millions ──────
function parseYield(y) {
  if (typeof y === "number") return y;
  if (y === "0" || !y) return 0;
  if (y.endsWith("B")) return parseFloat(y) * 1000;
  if (y.endsWith("M")) return parseFloat(y);
  return parseFloat(y) || 0;
}

// ── Main ──────────────────────────────────────────────────────────────
const outputDir = path.join(__dirname, "..", "output");
const jsonlFiles = fs
  .readdirSync(outputDir)
  .filter((f) => f.startsWith("seeds_") && f.endsWith(".jsonl"))
  .sort();

console.log("=== SEED DATA: Zones with radius < 4000 ===\n");
console.log(`Reading ${jsonlFiles.length} JSONL files...\n`);

const calibData = loadCalibrationData();
console.log(
  `Loaded ${Object.keys(calibData).length} calibration results (seeds: ${Object.keys(calibData).join(", ")})\n`
);

// Collect all zones with radius < 4k
const smallZones = [];
let totalSeeds = 0;

for (const fname of jsonlFiles) {
  const content = fs.readFileSync(path.join(outputDir, fname), "utf8");
  for (const line of content.split("\n")) {
    if (!line.startsWith("{")) continue;
    let seed;
    try {
      seed = JSON.parse(line);
    } catch (e) {
      continue;
    }
    totalSeeds++;
    if (!seed.z) continue;

    for (const z of seed.z) {
      const r = z.r || 0;
      if (
        r > 0 &&
        r < 4000 &&
        (z.t === "planet" || z.t === "moon")
      ) {
        smallZones.push({
          universeSeed: seed.s,
          loot: seed.l || "",
          zoneName: z.n,
          type: z.t,
          surfaceSeed: z.s,
          radius: r,
          water: z.water || null,
          enemy: z.enemy || null,
          primary: z.p || null,
          yields: z.y || {},
          scores: z.rs || {},
          dv: z.dv || 0,
          file: fname,
        });
      }
    }
  }
}

console.log(
  `Total seeds scanned: ${totalSeeds}`
);
console.log(
  `Zones with radius < 4000: ${smallZones.length}\n`
);

// ── Group by universe seed ─────────────────────────────────────────────
const byUniverseSeed = {};
for (const sz of smallZones) {
  const key = sz.universeSeed;
  if (!byUniverseSeed[key]) byUniverseSeed[key] = [];
  byUniverseSeed[key].push(sz);
}

const universeSeeds = Object.keys(byUniverseSeed)
  .map(Number)
  .sort((a, b) => a - b);

console.log(
  `=== Small-radii zones by universe seed (${universeSeeds.length} seeds) ===\n`
);

// Print zones grouped by universe seed
for (const us of universeSeeds) {
  const zones = byUniverseSeed[us];
  const loot = zones[0].loot;
  console.log(
    `── Seed ${us} (loot: ${loot}, ${zones.length} zones with r<4k) ──`
  );

  // Sort by radius ascending
  zones.sort((a, b) => a.radius - b.radius);

  for (const z of zones) {
    const waterShort = (z.water || "?")
      ;
    const enemyShort = (z.enemy || "?")
      .replace("enemy_", "")
      .replace("very_", "v");
    const yieldKeys = Object.keys(z.yields);
    const topYields = yieldKeys
      .sort(
        (a, b) =>
          parseYield(z.yields[b]) - parseYield(z.yields[a])
      )
      .slice(0, 4)
      .map((k) => `${k}=${z.yields[k]}`)
      .join(", ");

    console.log(
      `  r=${String(z.radius).padStart(4)} ${z.type.padEnd(6)} ${z.zoneName.padEnd(16)} ` +
        `s=${z.surfaceSeed.toString().padStart(10)} ` +
        `dv=${String(z.dv).padStart(6)} w=${waterShort.padEnd(5)} e=${enemyShort.padEnd(5)} ` +
        `primary=${(z.primary || "-").padEnd(18)} ${topYields}`
    );
  }
  console.log();
}

// ── Radius distribution ────────────────────────────────────────────────
console.log("=== Radius Distribution ===\n");
const buckets = {};
for (const sz of smallZones) {
  const bucket = Math.floor(sz.radius / 500) * 500;
  if (!buckets[bucket]) buckets[bucket] = 0;
  buckets[bucket]++;
}
const sortedBuckets = Object.keys(buckets)
  .map(Number)
  .sort((a, b) => a - b);
for (const b of sortedBuckets) {
  const bar = "█".repeat(Math.max(1, buckets[b]));
  console.log(
    `  ${String(b).padStart(5)}-${String(b + 499).padStart(5)}: ${String(buckets[b]).padStart(3)} ${bar}`
  );
}

// ── Cross-reference with calibration data ──────────────────────────────
console.log("\n=== Calibration Cross-Reference ===\n");

// Find zones whose surface seed matches calibration data
const matched = [];
for (const sz of smallZones) {
  if (calibData[sz.surfaceSeed]) {
    matched.push({
      ...sz,
      calib: calibData[sz.surfaceSeed],
    });
  }
}

if (matched.length > 0) {
  console.log(
    `${matched.length} small-radius zones have calibration data:\n`
  );
  for (const m of matched) {
    const c = m.calib;
    console.log(
      `── Zone: ${m.zoneName} (r=${m.radius}, water=${m.water}, surface seed=${m.surfaceSeed}) ──`
    );
    console.log(
      `  Calibration: r=${c.radius}, land_tiles=${c.land_tiles.toLocaleString()}, water_tiles=${c.water_tiles.toLocaleString()}`
    );

    // Zig prediction vs actual
    console.log(
      `  {"type": "resource", "prediction (Zig)": "prediction", "actual (Factorio)": "actual", "ratio": "ratio"}`
    );
    const resources = ["iron-ore", "copper-ore", "coal", "stone"];

    console.log(
      `  ${"Resource".padEnd(16)} ${"Zig est".padStart(10)} ${"Actual".padStart(12)} ${"Ratio".padStart(10)}`
    );
    console.log("  " + "─".repeat(52));

    for (const res of resources) {
      const score = (m.scores || {})[res] || 0;
      const zigYield = computeYield(score, m.radius, m.water, res);
      const zigStr = formatYield(zigYield);
      const zigItems = zigYield * 1_000_000;

      const actualItems =
        ((c.resources || {})[res] || {}).total || 0;

      const ratio =
        actualItems > 0 ? (zigItems / actualItems).toFixed(2) : "N/A";

      console.log(
        `  ${res.padEnd(16)} ${String(zigStr).padStart(10)} ${String(Math.floor(actualItems).toLocaleString()).padStart(12)} ${String(ratio).padStart(10)}`
      );
    }

    // Also show the raw Zig score for all resources
    console.log(`\n  Zig scores (rs):`);
    const scoreKeys = Object.keys(m.scores || {}).sort(
      (a, b) => (m.scores[b] || 0) - (m.scores[a] || 0)
    );
    const scoreLines = [];
    for (const sk of scoreKeys) {
      if ((m.scores[sk] || 0) > 0.0001) {
        scoreLines.push(`${sk}=${m.scores[sk].toFixed(4)}`);
      }
    }
    console.log(`  ${scoreLines.join(", ")}`);
    console.log();
  }
} else {
  console.log(
    "No small-radius zones matched existing calibration data."
  );
  console.log(
    "The calibration seeds don't appear in the current JSONL output.\n"
  );
}

// ── Suggest calibration surfaces ──────────────────────────────────────
console.log("=== Suggested Calibration Surfaces ===\n");
console.log(
  "To verify yield estimates, pick a few small-radius zones with known water levels\n" +
    "and run: calibration/run.sh <surface_seed> <radius> <water_level>\n"
);

// Pick interesting candidates: diverse radii + water levels
const waterLevels = ["none", "low", "med", "high", "max"];
const candidates = [];

for (const wl of waterLevels) {
  // Find one zone with each water level
  const match = smallZones.find(
    (z) => z.water === `${wl}` && z.radius < 2000
  );
  if (match) {
    candidates.push({
      water: wl,
      zone: match,
    });
  }
}

// Also pick smallest overall
const smallest = [...smallZones].sort(
  (a, b) => a.radius - b.radius
);
for (let i = 0; i < Math.min(5, smallest.length); i++) {
  const z = smallest[i];
  // Only add if not already in candidates
  if (!candidates.find((c) => c.zone.surfaceSeed === z.surfaceSeed)) {
    candidates.push({ water: z.water? || "?", zone: z });
  }
}

// Show unique candidates
const seen = new Set();
for (const c of candidates) {
  if (seen.has(c.zone.surfaceSeed)) continue;
  seen.add(c.zone.surfaceSeed);
  const z = c.zone;
  const water = z.water ? z.water : "?";
  console.log(
    `  ./calibration/run.sh ${z.surfaceSeed} ${z.radius} ${water}  ` +
      `# ${z.zoneName} (universe seed ${z.universeSeed}, primary=${z.primary || "?"})`
  );

  // Show predicted yields
  console.log(`    Zig predicts:`);
  for (const [res, yieldStr] of Object.entries(z.yields).slice(0, 5)) {
    console.log(`      ${res}: ${yieldStr}`);
  }
  console.log();
}

// ── Summary ────────────────────────────────────────────────────────────
console.log("=== Summary ===\n");
console.log(
  `Out of ${totalSeeds} universe seeds, ${smallZones.length} zones have radius < 4k`
);
console.log(
  `These span ${universeSeeds.length} different universe seeds`
);
console.log(
  `Smallest radius: ${smallest[0]?.radius || "N/A"} (${smallest[0]?.zoneName || ""})`
);
console.log(
  `Largest radius (under 4k): ${smallest[smallest.length - 1]?.radius || "N/A"}`
);

// What fraction of zones are small?
let totalZones = 0;
for (const fname of jsonlFiles) {
  const content = fs.readFileSync(path.join(outputDir, fname), "utf8");
  for (const line of content.split("\n")) {
    if (!line.startsWith("{")) continue;
    let seed;
    try {
      seed = JSON.parse(line);
    } catch (e) {
      continue;
    }
    if (!seed.z) continue;
    for (const z of seed.z) {
      if (z.t === "planet" || z.t === "moon") totalZones++;
    }
  }
}
console.log(
  `Fraction: ${smallZones.length}/${totalZones} = ${((smallZones.length / totalZones) * 100).toFixed(1)}% of all planet/moon zones`
);
