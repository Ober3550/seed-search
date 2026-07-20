#!/usr/bin/env node
// verifier/db.js — SQLite database for seed-search calibration analysis
//
// Usage:
//   node verifier/db.js init              Create/init DB and populate from JSONL
//   node verifier/db.js import-calib       Import existing calibration results
//   node verifier/db.js query <sql>        Run arbitrary SQL query
//   node verifier/db.js stats              Show summary statistics
//   node verifier/db.js compare            Show Zig vs calibration comparison
//   node verifier/db.js calibrate [n]      Generate next N calibrations to run
//   node verifier/db.js pick <n> <water>   Pick N surface seeds with radius<4k

const fs = require("fs");
const path = require("path");
const Database = require("better-sqlite3");

const DB_PATH = path.join(__dirname, "seed-search.db");
const SCHEMA_PATH = path.join(__dirname, "schema.sql");
const OUTPUT_DIR = path.join(__dirname, "..", "output");
const CALIB_DIR = path.join(__dirname, "results");

// ── Helpers ─────────────────────────────────────────────────────────

function parseYield(y) {
  if (typeof y === "number") return y;
  if (y === "0" || !y) return 0;
  if (y.endsWith("B")) return parseFloat(y) * 1000;
  if (y.endsWith("M")) return parseFloat(y);
  return parseFloat(y) || 0;
}

function getDb() {
  const db = new Database(DB_PATH);
  db.pragma("journal_mode = WAL");
  db.pragma("foreign_keys = ON");
  return db;
}

// ── Init DB ─────────────────────────────────────────────────────────

function initDb() {
  // Remove old DB if exists
  if (fs.existsSync(DB_PATH)) fs.unlinkSync(DB_PATH);

  const db = getDb();
  const schema = fs.readFileSync(SCHEMA_PATH, "utf8");
  db.exec(schema);

  // Populate from JSONL
  const files = fs
    .readdirSync(OUTPUT_DIR)
    .filter((f) => f.startsWith("seeds_") && f.endsWith(".jsonl"));

  const insertSeed = db.prepare(
    "INSERT OR IGNORE INTO universe_seeds (universe_seed, loot, draws, k2_enabled) VALUES (?, ?, ?, ?)"
  );
  const insertZone = db.prepare(
    `INSERT OR IGNORE INTO zones 
     (universe_seed, zone_name, zone_index, zone_type, surface_seed, radius, water, temperature, moisture, trees, aux, cliff, enemy, primary_resource, delta_v)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
  );
  const insertEstimate = db.prepare(
    "INSERT OR IGNORE INTO zig_estimates (universe_seed, zone_name, resource_name, score, yield_millions) VALUES (?, ?, ?, ?, ?)"
  );

  let totalSeeds = 0, totalZones = 0, totalEstimates = 0;
  const insertAll = db.transaction(() => {
    for (const fname of files) {
      const content = fs.readFileSync(path.join(OUTPUT_DIR, fname), "utf8");
      for (const line of content.split("\n")) {
        if (!line.startsWith("{")) continue;
        let seed;
        try { seed = JSON.parse(line); } catch (e) { continue; }
        totalSeeds++;

        insertSeed.run(seed.s, seed.l || "", seed.d || 0, seed.k ? 1 : 0);

        if (!seed.z) continue;
        for (const z of seed.z) {
          totalZones++;
          insertZone.run(
            seed.s, z.n, z.i, z.t, z.s, z.r || 0,
            z.water ? ("water_" + z.water) : null,
            z.temperature ? ("temperature_" + z.temperature) : null,
            z.moisture ? ("moisture_" + z.moisture) : null,
            z.trees ? ("trees_" + z.trees) : null,
            z.aux ? ("aux_" + z.aux) : null,
            z.cliff ? ("cliff_" + z.cliff) : null,
            z.enemy ? ("enemy_" + z.enemy) : null, z.p || null, z.dv || null
          );

          // Zig estimates from "y" and "rs"
          const yields = z.y || {};
          const scores = z.rs || {};
          const allResources = new Set([
            ...Object.keys(yields),
            ...Object.keys(scores),
          ]);
          for (const res of allResources) {
            const score = scores[res] ?? 0;
            const yieldM = yields[res] ? parseYield(yields[res]) : 0;
            if (score > 0 || yieldM > 0) {
              totalEstimates++;
              insertEstimate.run(seed.s, z.n, res, score, yieldM);
            }
          }
        }
      }
    }
  });

  insertAll();
  console.log(
    `Populated DB: ${totalSeeds} universe seeds, ${totalZones} zones, ${totalEstimates} zig estimates`
  );

  // Import existing calibration data
  importCalibrations(db);
  db.close();

  console.log("DB ready at", DB_PATH);
}

// ── Import Calibration Data ─────────────────────────────────────────

function importCalibrations(db) {
  const files = fs
    .readdirSync(CALIB_DIR)
    .filter((f) => f.startsWith("seed-") && f.endsWith(".json"));

  if (files.length === 0) {
    console.log("No existing calibration results to import.");
    return;
  }

  const insertCalib = db.prepare(
    `INSERT OR REPLACE INTO calibrations 
     (surface_seed, radius, water, freq, size, rich, total_tiles, water_tiles, land_tiles)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
  );
  const insertRes = db.prepare(
    `INSERT OR REPLACE INTO calibration_resources
     (surface_seed, radius, freq, size, rich, resource_name, total, patches)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
  );

  let count = 0;
  const importAll = db.transaction(() => {
    for (const f of files) {
      const data = JSON.parse(fs.readFileSync(path.join(CALIB_DIR, f), "utf8"));
      count++;

      // Try to read FSR from JSON, then from filename, then default to 1.0
      const freq = data.freq ?? 1.0;
      const size = data.size ?? 1.0;
      const rich = data.rich ?? 1.0;
      const water = data.water || "unknown";

      // Parse filename: seed-{seed}-r{radius}-f{freq}-s{size}-r{rich}.json
      const fnMatch = f.match(/seed-(\d+)-r(\d+)-f([\d.]+)-s([\d.]+)-r([\d.]+)\.json/);
      const ffreq = fnMatch ? parseFloat(fnMatch[3]) : freq;
      const fsize = fnMatch ? parseFloat(fnMatch[4]) : size;
      const frich = fnMatch ? parseFloat(fnMatch[5]) : rich;

      // Also extract surface seed + radius from simpler filenames
      const simpleMatch = f.match(/seed-(\d+)\.json$/);
      const useFreq = simpleMatch ? (data.freq ?? 1.0) : ffreq;
      const useSize = simpleMatch ? (data.size ?? 1.0) : fsize;
      const useRich = simpleMatch ? (data.rich ?? 1.0) : frich;

      insertCalib.run(
        data.seed, data.radius, water,
        useFreq, useSize, useRich,
        data.total_tiles, data.water_tiles || 0, data.land_tiles
      );

      if (data.resources) {
        for (const [res, info] of Object.entries(data.resources)) {
          insertRes.run(data.seed, data.radius, useFreq, useSize, useRich,
            res, info.total, info.patches || 0);
        }
      }
    }
  });

  importAll();
  console.log(`Imported ${count} calibration results`);
}

// ── Compare ─────────────────────────────────────────────────────────

function showComparison(db) {
  console.log("=== Zig vs Calibration (FSR=1.0) ===\n");

  const rows = db.prepare(`
    SELECT * FROM comparison 
    ORDER BY zig_actual_ratio DESC
  `).all();

  if (rows.length === 0) {
    console.log("No matching data. Run some calibrations first.");
    console.log("Use: node verifier/db.js calibrate 5");
    return;
  }

  // Group by zone
  const byZone = {};
  for (const r of rows) {
    const key = `${r.universe_seed}/${r.zone_name}`;
    if (!byZone[key]) byZone[key] = { ...r, resources: [] };
    byZone[key].resources.push(r);
  }

  for (const [key, z] of Object.entries(byZone)) {
    console.log(
      `── ${z.zone_name} (seed ${z.universe_seed}, surface ${z.surface_seed}, r=${z.radius}, water=${z.water}) ──`
    );
    console.log(
      `  ${"Resource".padEnd(18)} ${"Zig(M)".padStart(8)} ${"Actual".padStart(10)} ${"Ratio".padStart(8)} ${"Score".padStart(8)} ${"Ore/t/FSR".padStart(12)}`
    );
    console.log("  " + "─".repeat(70));
    for (const r of z.resources) {
      const ratioColor = r.zig_actual_ratio > 2 ? " ⚠️" : r.zig_actual_ratio < 0.5 ? " ⚡" : "";
      console.log(
        `  ${r.resource_name.padEnd(18)} ${r.zig_yield_m.toFixed(1).padStart(8)} ${String(Math.round(r.actual_items).toLocaleString()).padStart(10)} ${r.zig_actual_ratio.toFixed(2).padStart(8)}${ratioColor} ${r.score.toFixed(4).padStart(8)} ${r.ore_per_tile_per_fsr.toFixed(4).padStart(12)}`
      );
    }
    console.log();
  }

  // Summary stats
  console.log("=== Per-Resource Summary ===\n");
  console.log(
    `  ${"Resource".padEnd(18)} ${"Samples".padStart(8)} ${"Avg Ratio".padStart(10)} ${"Min Ratio".padStart(10)} ${"Max Ratio".padStart(10)} ${"Avg Ore/t/FSR".padStart(14)}`
  );
  console.log("  " + "─".repeat(74));

  const byRes = {};
  for (const r of rows) {
    if (!byRes[r.resource_name]) byRes[r.resource_name] = [];
    byRes[r.resource_name].push(r);
  }

  for (const [res, vals] of Object.entries(byRes)) {
    const ratios = vals.map((v) => v.zig_actual_ratio);
    const orePerFsr = vals.map((v) => v.ore_per_tile_per_fsr);
    const avg = (arr) => arr.reduce((a, b) => a + b, 0) / arr.length;
    console.log(
      `  ${res.padEnd(18)} ${String(vals.length).padStart(8)} ${avg(ratios).toFixed(2).padStart(10)} ${Math.min(...ratios).toFixed(2).padStart(10)} ${Math.max(...ratios).toFixed(2).padStart(10)} ${avg(orePerFsr).toFixed(4).padStart(14)}`
    );
  }
}

// ── Stats ────────────────────────────────────────────────────────────

function showStats(db) {
  console.log("=== Database Statistics ===\n");

  const counts = db.prepare(`
    SELECT 
      (SELECT COUNT(*) FROM universe_seeds) as universe_seeds,
      (SELECT COUNT(*) FROM zones) as zones,
      (SELECT COUNT(*) FROM zones WHERE radius > 0 AND radius < 4000 AND zone_type IN ('planet','moon') AND zone_name != 'Nauvis') as small_zones,
      (SELECT COUNT(*) FROM zones WHERE zone_name = 'Nauvis') as nauvis_zones,
      (SELECT COUNT(*) FROM zig_estimates) as zig_estimates,
      (SELECT COUNT(*) FROM calibrations) as calibrations,
      (SELECT COUNT(*) FROM calibration_resources) as calib_resources
  `).get();

  for (const [k, v] of Object.entries(counts)) {
    console.log(`  ${k}: ${v}`);
  }

  console.log("\n=== Radius Distribution (r<4k) ===\n");
  const dist = db.prepare(`
    SELECT 
      CAST(radius/500 AS INT)*500 as bucket,
      COUNT(*) as cnt
    FROM zones 
    WHERE radius > 0 AND radius < 4000 AND zone_type IN ('planet','moon') AND zone_name != 'Nauvis'
    GROUP BY bucket ORDER BY bucket
  `).all();

  for (const d of dist) {
    const bar = "█".repeat(Math.max(1, Math.round(d.cnt / 10)));
    console.log(
      `  ${String(d.bucket).padStart(5)}-${String(d.bucket + 499).padStart(5)}: ${String(d.cnt).padStart(4)} ${bar}`
    );
  }

  console.log("\n=== Water Distribution (r<4k) ===\n");
  const waterDist = db.prepare(`
    SELECT water, COUNT(*) as cnt
    FROM zones 
    WHERE radius > 0 AND radius < 4000 AND zone_type IN ('planet','moon') AND zone_name != 'Nauvis'
    GROUP BY water ORDER BY cnt DESC
  `).all();

  for (const w of waterDist) {
    console.log(`  ${(w.water || "?").padEnd(12)}: ${w.cnt}`);
  }

  console.log("\n=== Calibration Coverage ===\n");
  const coverage = db.prepare(`
    SELECT 
      COUNT(DISTINCT z.surface_seed) as calibratable_zones,
      COUNT(DISTINCT c.surface_seed) as calibrated_surfaces
    FROM zones z
    LEFT JOIN calibrations c ON z.surface_seed = c.surface_seed
    WHERE z.radius < 4000 AND z.zone_type IN ('planet','moon')
      AND z.zone_name != 'Nauvis'
  `).get();

  console.log(`  Small zones (<4k, excl. Nauvis): ${coverage.calibratable_zones}`);
  console.log(`  Have calibration data: ${coverage.calibrated_surfaces}`);
  console.log(`  Coverage: ${(coverage.calibrated_surfaces / coverage.calibratable_zones * 100).toFixed(1)}%`);
}

// ── Pick Calibration Candidates ─────────────────────────────────────

function pickCalibrations(db, n, waterFilter) {
  n = parseInt(n) || 10;

  let query = `
    SELECT z.*, COUNT(ze.resource_name) as resource_count
    FROM zones z
    JOIN zig_estimates ze ON z.universe_seed = ze.universe_seed AND z.zone_name = ze.zone_name
    LEFT JOIN calibrations c ON z.surface_seed = c.surface_seed
    WHERE z.radius < 4000 
      AND z.radius > 0
      AND z.zone_type IN ('planet','moon')
      AND z.zone_name != 'Nauvis'
      AND c.surface_seed IS NULL
  `;
  const params = [];

  if (waterFilter) {
    query += ` AND z.water = ?`;
    params.push(`water_${waterFilter}`);
  }

  query += `
    GROUP BY z.universe_seed, z.zone_name
    ORDER BY resource_count DESC, z.radius ASC
    LIMIT ?
  `;
  params.push(n);

  const candidates = db.prepare(query).all(...params);

  if (candidates.length === 0) {
    console.log("No calibration candidates found.");
    return;
  }

  console.log(`=== Top ${candidates.length} Calibration Candidates ===\n`);

  for (const z of candidates) {
    const water = (z.water || "?");
    const yields = db.prepare(`
      SELECT resource_name, yield_millions FROM zig_estimates
      WHERE universe_seed = ? AND zone_name = ?
      ORDER BY yield_millions DESC LIMIT 5
    `).all(z.universe_seed, z.zone_name);

    const yieldStr = yields
      .map((y) => `${y.resource_name}=${y.yield_millions.toFixed(0)}M`)
      .join(", ");

    console.log(
      `  r=${String(Math.round(z.radius)).padStart(4)} w=${water.padEnd(5)} ${z.zone_name.padEnd(16)} ` +
        `surface=${String(z.surface_seed).padStart(10)} primary=${(z.primary_resource || "-").padEnd(18)} ` +
        `${yieldStr}`
    );
    console.log(
      `    → ./calibration/run-local.sh ${z.surface_seed} ${Math.round(z.radius)} ${water}`
    );
  }

  // Output batch script
  const lines = [
    "#!/usr/bin/env bash",
    "# Auto-generated by: node verifier/db.js pick " + n + (waterFilter ? " " + waterFilter : ""),
    "set -euo pipefail",
    'SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"',
    "",
  ];
  for (const z of candidates) {
    const water = (z.water || "?");
    lines.push(
      `echo "=== ${z.zone_name} (surface=${z.surface_seed}, r=${Math.round(z.radius)}, w=${water}) ==="`
    );
    lines.push(
      `"$SCRIPT_DIR/calibration/run-local.sh" ${z.surface_seed} ${Math.round(z.radius)} ${water}`
    );
    lines.push(`echo`);
    lines.push(`sleep 2`);
    lines.push("");
  }

  const scriptPath = path.join(__dirname, "calibrate-batch.sh");
  fs.writeFileSync(scriptPath, lines.join("\n"));
  fs.chmodSync(scriptPath, "755");
  console.log(`\nBatch script written: ${scriptPath}`);
}

// ── Main ─────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const command = args[0] || "stats";

let db;
try {
  if (command === "init") {
    initDb();
  } else {
    if (!fs.existsSync(DB_PATH)) {
      console.log("DB not found. Run 'node verifier/db.js init' first.");
      process.exit(1);
    }
    db = getDb();

    switch (command) {
      case "stats":
        showStats(db);
        break;
      case "compare":
        showComparison(db);
        break;
      case "import-calib":
        importCalibrations(db);
        console.log("Done.");
        break;
      case "pick":
        pickCalibrations(db, args[1], args[2]);
        break;
      case "query":
        const sql = args.slice(1).join(" ");
        const rows = db.prepare(sql).all();
        if (rows.length === 0) {
          console.log("(empty)");
        } else {
          console.log(JSON.stringify(rows, null, 2));
        }
        break;
      default:
        console.log("Unknown command:", command);
        console.log("Commands: init, stats, compare, import-calib, pick <n> [water], query <sql>");
    }
    db.close();
  }
} catch (e) {
  console.error("Error:", e.message);
  if (db) db.close();
  process.exit(1);
}
