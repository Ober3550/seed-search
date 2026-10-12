#!/usr/bin/env node
// Search a seed list for seeds whose home system has particular surfaces, and
// show those surfaces: one block per seed in the layout of verifier/analyze.js
// (name, type, delta-v from Nauvis, radius, enemies, water, then the six
// largest resources).
//
//   node scripts/seed-surfaces.mjs --mod se --from seedlists/se.u32 --rules scripts/surface-rules/se-vulcanite-cryonite-holmium.json
//       [--top 50] [--out list.u32] [--emit worlds.jsonl] [--limit N] [--workers N] [--color | --no-color]
//
// The rules file:
//   min_planets     home-system planets (incl. Nauvis) a seed needs; 0 = any
//   min_amount      a resource below this counts as absent. Amounts are
//                   relative to the surface's primary resource (= 1); a
//                   secondary never gets much above 0.15
//   skip_waterless  drop surfaces without water before looking at them
//   surfaces        a seed is kept when EVERY entry is found on some planet or
//                   moon of the home system:
//     label         shown beside the surfaces it selected
//     has           resources the one surface must all hold
//     primary       (optional) the surface's primary resource
//     radius_min, dv_max, enemy_max ("none".."max")   (optional)
//
// Seeds are listed by planet count, then by the explorer's score. --top limits
// how many are printed (0 = all); --out writes every matching seed as a list
// (4-byte seeds, like the input); --emit writes their universes with only the
// selected surfaces, in seedgen's JSONL (the input of segen --zones).
// --limit N searches the first N seeds only. Paths are relative to the
// repository root.
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import readline from "node:readline";
import { spawn } from "node:child_process";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const require = createRequire(import.meta.url);
const { seedScore } = require(path.join(ROOT, "space_explorer_gui", "score.js"));
const { convertNewToOld, surfaceInfo, printTable, noColor, ENEMY_LEVELS } = require(path.join(ROOT, "verifier", "analyze.js"));

const arg = (name, fallback) => {
  const i = process.argv.indexOf(name);
  return i !== -1 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
};
const fail = (msg) => { console.error(msg); process.exit(1); };
const K2 = { se: 0, k2se: 1 };
const mod = arg("--mod", null), fromArg = arg("--from", null), rulesArg = arg("--rules", null);
if (!(mod in K2) || !fromArg || !rulesArg) fail("usage: seed-surfaces.mjs --mod se|k2se --from list.u32 --rules file.json [--top 50] [--out list.u32] [--emit worlds.jsonl] [--limit N] [--workers N]");
const rel = (f) => path.relative(ROOT, f);
const listFile = path.resolve(ROOT, fromArg), rulesFile = path.resolve(ROOT, rulesArg);
const rules = JSON.parse(fs.readFileSync(rulesFile, "utf8"));
if (rules.mod && rules.mod !== mod) fail(`${rel(rulesFile)} is for "${rules.mod}", not "${mod}"`);
const wanted = rules.surfaces || [];
if (!wanted.length) fail("the rules name no surfaces");
for (const w of wanted) {
  if (!Array.isArray(w.has) || !w.has.length) fail("every surface rule needs \"has\": [resources]");
  if (w.enemy_max != null && !ENEMY_LEVELS.includes(w.enemy_max)) fail(`enemy_max must be one of ${ENEMY_LEVELS.join(", ")}`);
  w.label ??= w.has.join("+");
}
const minPlanets = rules.min_planets || 0, minAmount = rules.min_amount || 0, skipWaterless = rules.skip_waterless !== false;
const outArg = arg("--out", null), emitArg = arg("--emit", null);
const outFile = outArg && path.resolve(ROOT, outArg);
if (outFile === listFile) fail("--out would overwrite the list being read");
const top = parseInt(arg("--top", "50"), 10);
const color = process.argv.includes("--color") || (process.stdout.isTTY && !process.argv.includes("--no-color"));
const bin = path.join(ROOT, "universe_generator", "zig", process.platform === "win32" ? "seedgen.exe" : "seedgen");
if (!fs.existsSync(bin)) fail("seedgen not built (run: node install.mjs --seedgen-only)");

const total = fs.statSync(listFile).size / 4;
const limit = parseInt(arg("--limit", "0"), 10);
const n = limit > 0 ? Math.min(limit, total) : total;
const workers = parseInt(arg("--workers", String(Math.max(1, os.cpus().length))), 10);
console.log(`${mod}: ${n.toLocaleString()} seeds of ${rel(listFile)}, rules ${rel(rulesFile)}, ${workers} workers`);

// does this surface (a seedgen zone) satisfy one rule?
const present = (z, res) => (z.rs[res] || 0) > 0 && z.rs[res] >= minAmount;
function satisfies(z, w) {
  if (w.primary && z.p !== w.primary) return false;
  if (w.radius_min != null && !(z.r > w.radius_min)) return false;
  if (w.dv_max != null && !(z.dv <= w.dv_max)) return false;
  if (w.enemy_max != null && ENEMY_LEVELS.indexOf(z.enemy || "none") > ENEMY_LEVELS.indexOf(w.enemy_max)) return false;
  return w.has.every((res) => present(z, res));
}
// A universe line -> the seed with its selected surfaces, or null.
function evaluate(line) {
  // the planet count sits in the line's header: skip most seeds unparsed
  if (minPlanets > 0 && Number(/"npl":(\d+)/.exec(line)?.[1]) < minPlanets) return null;
  const d = JSON.parse(line);
  const bodies = d.z.filter((z) => (z.t === "planet" || z.t === "moon") && z.rs && !(skipWaterless && (!z.water || z.water === "none")));
  const labels = new Map(); // surface name -> labels of the rules it satisfies
  for (const w of wanted) {
    const hits = bodies.filter((z) => satisfies(z, w));
    if (!hits.length) return null;
    for (const z of hits) labels.set(z.n, [...(labels.get(z.n) || []), w.label]);
  }
  const m = { seed: d.s, loot: d.l, npl: d.npl, npm: d.npm, naqdv: d.naqdv, fdv: d.fdv, ef: d.ef, wp: d.wp };
  m.score = seedScore(m);
  // seedgen lists the Krastorio 2 resources either way: without K2 they do not exist
  const rsOf = (z) => (K2[mod] ? z.rs : Object.fromEntries(Object.entries(z.rs).filter(([k]) => !k.startsWith("kr-"))));
  const world = { ...d, z: d.z.filter((z) => labels.has(z.n)).map((z) => ({ ...z, rs: rsOf(z) })) };
  return { ...m, labels: Object.fromEntries(labels), world };
}

const SLICE = 2_000; // list entries per seedgen run
const env = { ...process.env, SE_K2: String(K2[mod]), SE_ENABLE_K2: String(K2[mod]), MIN_PROD_MODULES: "0", WORKER_ID: "0", SEED_LIST: listFile };
for (const k of ["FILTER", "METRICS_SCAN", "ALL_ZONES", "NAQ_SCAN", "MIN_NAQ_DV", "PLANETS_HIGH", "PLANETS_LOW", "NAQ_DV_LOW", "NAQ_DV_HIGH", "ENEMY_PCT_LOW", "ENEMY_PCT_HIGH", "WATER_PCT_LOW", "WATER_PCT_HIGH"]) delete env[k];
const found = [], running = new Set();
let next = 0, done = 0, lines = 0, stopping = false, lastLine = Date.now();
const t0 = Date.now();
process.on("SIGINT", () => { stopping = true; process.exitCode = 130; for (const c of running) c.kill(); });
const runSlice = (skip, count) => new Promise((resolve, reject) => {
  const child = spawn(bin, [], { env: { ...env, SEED_LIST_SKIP: String(skip), SEED_LIST_COUNT: String(count) }, stdio: ["ignore", "pipe", "ignore"] });
  running.add(child);
  let got = 0;
  readline.createInterface({ input: child.stdout }).on("line", (line) => {
    if (!line.startsWith("{")) return;
    got++;
    const r = evaluate(line);
    if (r) found.push(r);
  });
  child.on("error", reject);
  child.on("close", (code) => {
    running.delete(child);
    if (stopping) return resolve();
    if (code !== 0) return reject(new Error(`seedgen exited ${code} on list entries ${skip}..${skip + count}`));
    // a seedgen without SEED_LIST support scans its default range instead
    if (got > count) return reject(new Error("seedgen does not understand SEED_LIST: rebuild it (node install.mjs --seedgen-only)"));
    done += count; lines += got;
    if (Date.now() - lastLine > 10_000 && done < n) {
      lastLine = Date.now();
      const rate = done / ((Date.now() - t0) / 1000);
      console.log(`  ${done.toLocaleString()} / ${n.toLocaleString()} (${(100 * done / n).toFixed(0)}%), ${found.length.toLocaleString()} found, ~${Math.ceil((n - done) / rate / 60)} min left`);
    }
    resolve();
  });
});
await Promise.all(Array.from({ length: workers }, async () => {
  while (!stopping && next < n) { const skip = next; next += SLICE; await runSlice(skip, Math.min(SLICE, n - skip)); }
}));
if (stopping) process.exit(130);
if (lines < n) console.log(`WARNING: ${(n - lines).toLocaleString()} seeds could not be generated and were not searched`);

found.sort((a, b) => b.npl - a.npl || b.score - a.score || a.seed - b.seed);
const shown = top > 0 ? found.slice(0, top) : found;
console.log(`${found.length.toLocaleString()} seeds found` + (shown.length < found.length ? `, showing the first ${shown.length} (--top 0 for all)` : "") + "\n");
const num = (v) => Number(v).toLocaleString();
for (const r of shown) {
  console.log(`seed: ${r.seed} loot: ${r.loot}   planets ${r.npl}  bodies ${r.npm}  score ${r.score}  naquium dv ${num(r.naqdv)}  nearest field dv ${num(r.fdv)}  hostile ${r.ef}%  water ${r.wp}%`);
  const old = convertNewToOld(r.world, false);
  const rows = [...old.planets, ...old.moons].sort((a, b) => a.delta_v - b.delta_v).map((s) => {
    const row = surfaceInfo(s);
    row[1] = row[1][0]; // p / m
    row[5] = Math.round(row[5]);
    return [...row.slice(0, 8), r.labels[s.name].join(", "), ...row.slice(8)];
  });
  printTable(color ? rows : rows.map((row) => row.map((c) => noColor(String(c)))));
  console.log();
}
if (outFile) {
  fs.writeFileSync(outFile, Buffer.from(Uint32Array.from(found.map((r) => r.seed).sort((a, b) => a - b)).buffer));
  console.log(`wrote ${found.length.toLocaleString()} seeds -> ${rel(outFile)}`);
}
if (emitArg) {
  fs.writeFileSync(path.resolve(ROOT, emitArg), found.map((r) => JSON.stringify(r.world) + "\n").join(""));
  console.log(`wrote ${found.length.toLocaleString()} universes with their selected surfaces -> ${emitArg}`);
}
