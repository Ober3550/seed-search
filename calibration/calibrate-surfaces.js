#!/usr/bin/env node
// verifier/calibrate-surfaces.js
// Picks surface seeds from the 122-seed JSONL run with radius < 4k,
// computes Zig yield estimates, and generates calibration commands.
//
// Usage:
//   node verifier/calibrate-surfaces.js            # print candidates
//   node verifier/calibrate-surfaces.js --run      # generate batch script
//   node verifier/calibrate-surfaces.js --compare  # compare vs existing calibration data

const fs = require("fs");
const path = require("path");

// ── Zig-equivalent constants ─────────────────────────────────────────
const RESOURCE_NORM_PLANET = 22.02730826300005162466;

function resourceAmountScale(name) {
  const scales = {
    "iron-ore": 1.0, "copper-ore": 1.0, coal: 0.8, stone: 0.7,
    "uranium-ore": 0.6, "crude-oil": 0.012, "kr-mineral-water": 0.012,
  };
  return scales[name] ?? 1.0;
}

function landFraction(waterTag) {
  const fracs = {
    water_none: 0.95, water_low: 0.8, water_med: 0.5,
    water_high: 0.3, water_max: 0.15,
  };
  return fracs[waterTag] ?? 0.5;
}

function computeYield(score, radius, waterTag, resourceName) {
  const rawFsr = score * RESOURCE_NORM_PLANET;
  const area = Math.PI * radius * radius;
  const landFrac = waterTag ? landFraction(waterTag) : 0.5;
  return (rawFsr * area * landFrac * resourceAmountScale(resourceName)) / 1_000_000.0;
}

function formatYield(yieldM) {
  if (yieldM < 0.5) return "0";
  if (yieldM >= 1000) return (yieldM / 1000).toFixed(1) + "B";
  if (yieldM >= 1) return Math.floor(yieldM) + "M";
  return yieldM.toFixed(1) + "M";
}

function parseYield(y) {
  if (typeof y === "number") return y;
  if (y === "0" || !y) return 0;
  if (y.endsWith("B")) return parseFloat(y) * 1000;
  if (y.endsWith("M")) return parseFloat(y);
  return parseFloat(y) || 0;
}

// ── Load calibration data ───────────────────────────────────────────
function loadCalibrationData() {
  const calibDir = path.join(__dirname, "..", "calibration", "results");
  const files = fs
    .readdirSync(calibDir)
    .filter((f) => f.startsWith("seed-") && f.endsWith(".json"));
  const bySeed = {};
  for (const f of files) {
    const data = JSON.parse(fs.readFileSync(path.join(calibDir, f), "utf8"));
    bySeed[data.seed] = data;
  }
  return bySeed;
}

// ── Load all zones from JSONL ────────────────────────────────────────
function loadAllZones() {
  const outputDir = path.join(__dirname, "..", "output");
  const files = fs
    .readdirSync(outputDir)
    .filter((f) => f.startsWith("seeds_") && f.endsWith(".jsonl"));

  const zones = [];
  for (const fname of files) {
    const content = fs.readFileSync(path.join(outputDir, fname), "utf8");
    for (const line of content.split("\n")) {
      if (!line.startsWith("{")) continue;
      let seed;
      try { seed = JSON.parse(line); } catch (e) { continue; }
      if (!seed.z) continue;
      for (const z of seed.z) {
        if ((z.t === "planet" || z.t === "moon") && z.r > 0) {
          zones.push({
            universeSeed: seed.s,
            loot: seed.l,
            zoneName: z.n,
            type: z.t,
            surfaceSeed: z.s,
            radius: z.r,
            water: z.water || null,
            enemy: z.enemy || null,
            primary: z.p || null,
            yields: z.y || {},
            scores: z.rs || {},
            dv: z.dv || 0,
          });
        }
      }
    }
  }
  return zones;
}

// ── Main ─────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const mode = args.includes("--compare") ? "compare"
  : args.includes("--run") ? "run"
  : "candidates";

const allZones = loadAllZones();
const calibData = loadCalibrationData();
const smallZones = allZones.filter((z) => z.radius < 4000);

console.log(
  `Loaded: ${allZones.length} zones total, ${smallZones.length} with r<4k, ${Object.keys(calibData).length} calibration results\n`
);

if (mode === "compare") {
  // Compare Zig estimates vs calibration data for any matching surface seeds
  console.log("=== Comparing Zig Estimates vs Calibration Data ===\n");

  let matched = 0;
  for (const z of smallZones) {
    const calib = calibData[z.surfaceSeed];
    if (!calib) continue;
    matched++;

    console.log(
      `── ${z.zoneName} (surface seed ${z.surfaceSeed}, r=${z.radius}, water=${z.water}) ──`
    );
    console.log(
      `  Calibration: r=${calib.radius}, land=${calib.land_tiles.toLocaleString()} tiles`
    );
    console.log(
      `  ${"Resource".padEnd(18)} ${"Zig est".padStart(8)} ${"Actual".padStart(12)} ${"Ratio".padStart(8)} ${"Score".padStart(8)}`
    );
    console.log("  " + "─".repeat(58));

    for (const res of ["iron-ore", "copper-ore", "coal", "stone"]) {
      const score = (z.scores || {})[res] || 0;
      const zigYield = computeYield(score, z.radius, z.water, res);
      const zigItems = Math.round(zigYield * 1_000_000);
      const actual = ((calib.resources || {})[res] || {}).total || 0;
      const ratio = actual > 0 ? (zigItems / actual).toFixed(2) : "-";

      console.log(
        `  ${res.padEnd(18)} ${formatYield(zigYield).padStart(8)} ${String(Math.floor(actual).toLocaleString()).padStart(12)} ${ratio.padStart(8)} ${score.toFixed(4).padStart(8)}`
      );
    }
    console.log();
  }

  if (matched === 0) {
    console.log(
      "No small-radius surface seeds matched existing calibration data.\n"
    );
    console.log(
      "Run calibration for some surface seeds, then re-run with --compare.\n"
    );
  } else {
    console.log(`${matched} zones matched.\n`);
  }
} else if (mode === "run") {
  // Generate a batch script for calibration
  console.log("=== Generating Calibration Batch Script ===\n");

  // Pick interesting candidates: diverse water levels, radii, and primaries
  const waterLevels = ["none", "low", "med", "high", "max"];

  // For each water level, pick the zone with the most interesting resources
  const candidates = [];
  for (const wl of waterLevels) {
    const waterTag = `${wl}`;
    // Prefer zones with more resource types and moderate radius (500-2000)
    const matches = smallZones
      .filter((z) => z.water === waterTag)
      .sort((a, b) => Object.keys(b.yields).length - Object.keys(a.yields).length);

    // Take top 3 most resource-diverse
    for (const m of matches.slice(0, 3)) {
      candidates.push(m);
    }
  }

  // Also pick smallest overall and most resource-diverse
  const sorted = [...smallZones].sort((a, b) => a.radius - b.radius);
  for (const z of sorted.slice(0, 5)) {
    if (!candidates.find((c) => c.surfaceSeed === z.surfaceSeed)) {
      candidates.push(z);
    }
  }

  // Deduplicate by surface seed
  const seen = new Set();
  const unique = [];
  for (const c of candidates) {
    if (seen.has(c.surfaceSeed)) continue;
    seen.add(c.surfaceSeed);
    unique.push(c);
  }

  // Generate commands
  const lines = ["#!/usr/bin/env bash", "# Auto-generated calibration batch", "# Generated by calibrate-surfaces.js", "", "set -euo pipefail", 'SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"', "", `echo "=== Calibrating ${unique.length} surfaces ==="`, "echo", ""];

  for (const z of unique.slice(0, 15)) {
    const water = z.water ? z.water : "med";
    lines.push(
      `echo "--- ${z.zoneName} (r=${z.radius}, w=${water}, surface_seed=${z.surfaceSeed}) ---"`
    );
    lines.push(
      `"$SCRIPT_DIR/calibration/run.sh" ${z.surfaceSeed} ${z.radius} ${water}`
    );
    lines.push(`echo`);
    lines.push(`sleep 2  # let Docker cool down`);
    lines.push("");
  }

  lines.push(`echo "=== Done ==="`);
  lines.push(`ls -la "$SCRIPT_DIR/calibration/results/"seed-*.json`);

  const script = lines.join("\n");
  const scriptPath = path.join(__dirname, "..", "calibrate-batch.sh");
  fs.writeFileSync(scriptPath, script);
  fs.chmodSync(scriptPath, "755");
  console.log(`Batch script written: ${scriptPath}`);
  console.log(`Contains ${unique.slice(0, 15).length} calibration commands\n`);

  // Also show what we're calibrating
  console.log("Selected surfaces:\n");
  for (const z of unique.slice(0, 15)) {
    const water = z.water ? z.water : "?";
    const yields = Object.entries(z.yields)
      .sort((a, b) => parseYield(b[1]) - parseYield(a[1]))
      .slice(0, 4)
      .map(([k, v]) => `${k}=${v}`)
      .join(", ");
    console.log(
      `  r=${String(z.radius).padStart(4)} w=${water.padEnd(5)} ${z.zoneName.padEnd(16)} ` +
        `s=${z.surfaceSeed.toString().padStart(10)}  ${yields || "(no yields)"}`
    );
  }
} else {
  // Default: show candidates summary
  console.log("=== Small-radius Surface Candidates for Calibration ===\n");

  // Show a representative sample
  const waterLevels = ["none", "low", "med", "high", "max"];
  for (const wl of waterLevels) {
    const waterTag = `${wl}`;
    const matches = smallZones
      .filter((z) => z.water === waterTag)
      .slice(0, 5);

    if (matches.length === 0) continue;
    console.log(`--- water=${wl} (${smallZones.filter((z) => z.water === waterTag).length} total) ---`);

    for (const z of matches) {
      const yields = Object.entries(z.yields)
        .sort((a, b) => parseYield(b[1]) - parseYield(a[1]))
        .slice(0, 3)
        .map(([k, v]) => `${k}=${v}`)
        .join(", ");
      console.log(
        `  r=${String(z.radius).padStart(4)} ${z.zoneName.padEnd(16)} ` +
          `s=${z.surfaceSeed.toString().padStart(10)} ` +
          `primary=${(z.primary || "-").padEnd(18)} ${yields || "(empty)"}`
      );
    }
    console.log();
  }

  console.log(
    "Use --run to generate a calibration batch script."
  );
  console.log(
    "Use --compare after running calibrations to verify estimates."
  );
}
