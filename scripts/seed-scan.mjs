#!/usr/bin/env node
// Coarse seed scan: reduce the whole seed space to the short list of seeds
// worth looking at, storing ONLY the seed numbers.
//
//   node scripts/seed-scan.mjs --mod se [--range 0:4294967296] [--workers N]
//   node scripts/seed-scan.mjs --mod se --status
//   node scripts/seed-scan.mjs --mod se --pack
//   node scripts/seed-scan.mjs --mod se --from seedlists/se.u32 [--criteria file --out seedlists/se-web.u32] [--csv file] [--limit N]
// (scripts/scan-se.sh and scripts/scan-k2se.sh wrap this per config.)
//
// A universe is fully reproducible from its seed (seedgen natively,
// universe.wasm in the browser), so nothing else needs storing: any finer
// filter, score or preset is evaluated later by regenerating the kept seeds.
// The criteria (scripts/seed-criteria/<mod>.json) are therefore LOOSE tails -
// a seed dropped here is gone until a rescan.
//
// Only even seeds are generated: the game's random generator ignores a seed's
// lowest bit, so seed 2k+1 has the same universe as 2k. The full range
// 0..4294967295 holds about 2.147 billion distinct universes.
//
// Output: seedlists/<mod>/
//   manifest.json              criteria, file / block size, generator commit
//   <start>-<end>.u32          kept seeds of a finished 1M range, ascending u32 LE
//   <start>-<end>.u32.part     the same for a range still being scanned
//   <start>-<end>.pos          how far that range has got (next seed number)
// A range is scanned in 100k blocks and each block's seeds are appended to the
// .part file as soon as the block finishes, so a crash or Ctrl-C loses under
// a minute of work per worker. The next run continues every .part from its
// .pos; a finished range is renamed to .u32 and skipped from then on.
// --pack concatenates the finished ranges into seedlists/<mod>.u32.
//
// --from regenerates the seeds of an existing list instead of a range (about
// two minutes for a full list on 10 cores, so nothing is saved along the way)
// and prints how its metrics are distributed. With --criteria it also counts
// the seeds that pass, and --out writes those as a smaller list (plus
// <out>.json saying how it was made). The criteria are "tails" as above or a
// "filter" (a Filter DSL document, docs/filter-dsl-reference.md). --csv saves
// the per-seed metrics, --limit N looks at the first N seeds only. Paths are
// relative to the repository root.
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import readline from "node:readline";
import { execFileSync, spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const arg = (name, fallback) => {
  const i = process.argv.indexOf(name);
  return i !== -1 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
};
const K2 = { se: 0, k2se: 1 };
const TAIL_KEYS = ["PLANETS_HIGH", "PLANETS_LOW", "NAQ_DV_LOW", "NAQ_DV_HIGH", "ENEMY_PCT_LOW", "ENEMY_PCT_HIGH", "WATER_PCT_LOW", "WATER_PCT_HIGH"];
const mod = arg("--mod", null);
if (!(mod in K2)) {
  console.error("usage: seed-scan.mjs --mod se|k2se [--range lo:hi] [--workers N] [--criteria file] | --status | --pack | --from list.u32 [--criteria file] [--out list.u32] [--csv file] [--limit N]");
  process.exit(1);
}
const LISTS = process.env.SEEDLISTS_DIR ? path.resolve(process.env.SEEDLISTS_DIR) : path.join(ROOT, "seedlists"); // override for trial runs
const DIR = path.join(LISTS, mod);
const MANIFEST = path.join(DIR, "manifest.json");
const CHUNK = 1_000_000; // one output file
const BLOCK = 100_000; // appended to the file as each finishes (~40 s for one worker)
const SEED_SPACE = 4294967296;

const nameOf = (a, b) => path.join(DIR, `${a}-${b}`);
function chunks() {
  if (!fs.existsSync(DIR)) return [];
  return fs.readdirSync(DIR).filter((f) => /^\d+-\d+\.u32$/.test(f))
    .map((f) => { const [a, b] = f.replace(".u32", "").split("-").map(Number); return { file: path.join(DIR, f), a, b }; })
    .sort((x, y) => x.a - y.a);
}
// Where an unfinished range has got to, and its seeds so far. The position
// file is written after the append, so seeds at or beyond it (a block that
// was appended just before a crash) are dropped and that block is redone.
function readPart(a, b) {
  const part = nameOf(a, b) + ".u32.part", posFile = nameOf(a, b) + ".pos";
  let pos = a;
  if (fs.existsSync(posFile)) pos = Math.min(b, Math.max(a, Number(fs.readFileSync(posFile, "utf8")) || a));
  let seeds = [];
  if (fs.existsSync(part)) {
    const buf = fs.readFileSync(part);
    for (let i = 0; i + 4 <= buf.length; i += 4) { const v = buf.readUInt32LE(i); if (v < pos) seeds.push(v); }
    if (seeds.length * 4 !== buf.length) fs.writeFileSync(part, Buffer.from(Uint32Array.from(seeds).buffer));
  }
  return { pos, seeds: seeds.length };
}
function parts() {
  if (!fs.existsSync(DIR)) return [];
  return fs.readdirSync(DIR).filter((f) => /^\d+-\d+\.pos$/.test(f))
    .map((f) => { const [a, b] = f.replace(".pos", "").split("-").map(Number); return { a, b, ...readPart(a, b) }; });
}
function status() {
  const cs = chunks(), ps = parts();
  let seeds = 0, covered = 0;
  for (const c of cs) { covered += c.b - c.a; seeds += fs.statSync(c.file).size / 4; }
  for (const p of ps) { covered += p.pos - p.a; seeds += p.seeds; }
  const pct = (100 * covered / SEED_SPACE).toFixed(2);
  console.log(`${mod}: ${covered.toLocaleString()} seed numbers scanned (${pct}% of the seed space), ${seeds.toLocaleString()} seeds kept` +
    (seeds ? ` = 1 universe in ${Math.round(covered / 2 / seeds).toLocaleString()}, ${(seeds * 4 / 1048576).toFixed(2)} MB` : "") +
    `; ${cs.length} finished files` + (ps.length ? `, ${ps.length} in progress` : ""));
  return { cs, ps, seeds, covered };
}

if (process.argv.includes("--status")) { status(); process.exit(0); }
if (process.argv.includes("--pack")) {
  const { cs, ps } = status();
  if (ps.length) console.log(`WARNING: ${ps.length} range(s) are unfinished and are NOT in the packed list`);
  const seeds = cs.reduce((n, c) => n + fs.statSync(c.file).size / 4, 0);
  // warn about holes: a packed list should say what it covers
  let gaps = 0;
  for (let i = 1; i < cs.length; i++) if (cs[i].a !== cs[i - 1].b) gaps++;
  const out = path.join(LISTS, mod + ".u32");
  const fd = fs.openSync(out, "w");
  for (const c of cs) fs.writeSync(fd, fs.readFileSync(c.file));
  fs.closeSync(fd);
  console.log(`packed ${seeds.toLocaleString()} seeds -> ${path.relative(ROOT, out)}` + (gaps ? ` (WARNING: ${gaps} gap(s) between scanned chunks)` : ""));
  process.exit(0);
}

let [lo, hi] = arg("--range", `0:${SEED_SPACE}`).split(":").map(Number);
if (!Number.isFinite(lo) || !Number.isFinite(hi) || lo >= hi || lo < 0 || hi > SEED_SPACE) {
  console.error("--range lo:hi must lie within 0:4294967296");
  process.exit(1);
}
const workers = parseInt(arg("--workers", String(Math.max(1, os.cpus().length))), 10);
const BASE_CRITERIA = `scripts/seed-criteria/${mod}.json`;
function loadCriteria(file) {
  const criteria = JSON.parse(fs.readFileSync(file, "utf8"));
  if (criteria.mod && criteria.mod !== mod) {
    console.error(`${path.relative(ROOT, file)} is for "${criteria.mod}", not "${mod}"`);
    process.exit(1);
  }
  const tails = {};
  for (const [k, v] of Object.entries(criteria.tails || {})) {
    if (!TAIL_KEYS.includes(k)) { console.error(`unknown tail "${k}" in criteria`); process.exit(1); }
    if (v > 0) tails[k] = String(v);
  }
  return { criteria, tails };
}
const fromList = arg("--from", null);
const criteriaArg = arg("--criteria", fromList ? null : BASE_CRITERIA);
const criteriaFile = criteriaArg && path.resolve(ROOT, criteriaArg);
const { criteria, tails } = criteriaFile ? loadCriteria(criteriaFile) : { criteria: null, tails: {} };
if (criteria && !Object.keys(tails).length && !(fromList && criteria.filter)) {
  console.error(fromList ? "criteria has neither tails nor a filter" : "criteria has no tails: refusing to keep every seed");
  process.exit(1);
}
if (criteria && criteria.filter && (!fromList || Object.keys(tails).length)) {
  console.error(fromList ? "criteria has both tails and a filter: use one" : "a filter is only supported with --from: a range scan uses tails");
  process.exit(1);
}
const bin = path.join(ROOT, "universe_generator", "zig", process.platform === "win32" ? "seedgen.exe" : "seedgen");
if (!fs.existsSync(bin)) { console.error("seedgen not built (run: node install.mjs --seedgen-only)"); process.exit(1); }
const commit = execFileSync("git", ["rev-parse", "--short", "HEAD"], { cwd: ROOT, encoding: "utf8" }).trim();

// seedgen's own filter decides what is kept: the union of the tails, or the
// FILTER document
const baseEnv = { ...process.env, SE_K2: String(K2[mod]), SE_ENABLE_K2: String(K2[mod]), MIN_PROD_MODULES: "0", WORKER_ID: "0" };
for (const k of ["FILTER", "METRICS_SCAN", "ALL_ZONES", "MIN_NAQ_DV", "SEED_LIST", "SEED_LIST_SKIP", "SEED_LIST_COUNT", ...TAIL_KEYS]) delete baseEnv[k];
Object.assign(baseEnv, tails);
if (criteria && criteria.filter) baseEnv.FILTER = JSON.stringify(criteria.filter);

if (fromList) {
  await rescanList();
  process.exit(process.exitCode || 0);
}

// one list = one criterion: refuse to mix
fs.mkdirSync(DIR, { recursive: true });
if (fs.existsSync(MANIFEST)) {
  const m = JSON.parse(fs.readFileSync(MANIFEST, "utf8"));
  if (JSON.stringify(m.tails) !== JSON.stringify(tails)) {
    console.error(`seedlists/${mod} was scanned with different criteria; move it aside or use the same criteria file`);
    process.exit(1);
  }
} else {
  fs.writeFileSync(MANIFEST, JSON.stringify({ mod, chunk: CHUNK, block: BLOCK, generator_commit: commit, description: criteria.description, tails }, null, 1) + "\n");
}

const todo = [];
let totalNumbers = 0;
for (let a = Math.floor(lo / CHUNK) * CHUNK; a < hi; a += CHUNK) {
  const s = Math.max(a, lo), e = Math.min(a + CHUNK, hi);
  if (fs.existsSync(nameOf(s, e) + ".u32")) continue;
  const { pos } = readPart(s, e);
  todo.push([s, e, pos]);
  totalNumbers += e - pos;
}
const total = todo.length;
console.log(`${mod}: ${(totalNumbers / 1e6).toFixed(1)}M seed numbers left to scan in ${lo}:${hi} (${total} files of ${CHUNK.toLocaleString()}, saved every ${BLOCK.toLocaleString()}), ${workers} workers`);
console.log(`criteria: ${Object.entries(tails).map(([k, v]) => `${k}=${v}`).join(" ")}`);

let done = 0, kept = 0, stopping = false;
const running = new Set();
const t0 = Date.now();

// Progress: one line per saved block, with the overall position and rate.
let finishedNumbers = 0;
function progressLine() {
  const sec = (Date.now() - t0) / 1000;
  const rate = finishedNumbers / sec;
  const left = (totalNumbers - finishedNumbers) / rate / 3600;
  const m = (v) => (v / 1e6).toFixed(1) + "M";
  return `${m(finishedNumbers)} / ${m(totalNumbers)} (${(100 * finishedNumbers / totalNumbers).toFixed(3)}%), ` +
    `${Math.round(rate).toLocaleString()}/s, ${kept.toLocaleString()} kept, ~${left < 1.5 ? Math.round(left * 60) + " min" : left.toFixed(1) + " h"} left`;
}

// One block of seed numbers [s, e) -> its kept seeds (ascending), or null if stopped.
function runBlock(s, e) {
  return new Promise((resolve, reject) => {
    // seedgen's END_SEED is inclusive and it steps by 2 from an even start
    const start = s + (s % 2);
    const child = spawn(bin, [], { env: { ...baseEnv, START_SEED: String(start), END_SEED: String(e - 1) }, stdio: ["ignore", "pipe", "ignore"] });
    running.add(child);
    const seeds = [];
    readline.createInterface({ input: child.stdout }).on("line", (line) => {
      const m = /^\{"s":(\d+)/.exec(line); // only the seed is kept
      if (m) seeds.push(Number(m[1]));
    });
    child.on("error", reject);
    child.on("close", (code) => {
      running.delete(child);
      if (stopping) return resolve(null);
      if (code !== 0) return reject(new Error(`seedgen exited ${code} on ${s}-${e}`));
      resolve(seeds.sort((x, y) => x - y));
    });
  });
}

// One output file: scan it block by block from where it left off, appending
// each block's seeds and then recording the new position.
async function runChunk([s, e, from]) {
  const base = nameOf(s, e), part = base + ".u32.part", posFile = base + ".pos";
  for (let b = from; b < e; b += BLOCK) {
    const be = Math.min(e, b + BLOCK - ((b - s) % BLOCK));
    const seeds = await runBlock(b, be);
    if (seeds === null) return; // stopped: this block is redone next time
    const fd = fs.openSync(part, "a");
    fs.writeSync(fd, Buffer.from(Uint32Array.from(seeds).buffer));
    fs.fsyncSync(fd);
    fs.closeSync(fd);
    fs.writeFileSync(posFile + ".tmp", String(be));
    fs.renameSync(posFile + ".tmp", posFile);
    kept += seeds.length;
    finishedNumbers += be - b;
    console.log(`  saved ${s}-${e} up to ${be}: +${seeds.length} seeds | ${progressLine()}`);
  }
  if (!fs.existsSync(part)) fs.writeFileSync(part, "");
  fs.renameSync(part, base + ".u32"); // the finished file only ever appears complete
  fs.rmSync(posFile, { force: true });
  done++;
}
process.on("SIGINT", () => {
  stopping = true;
  process.exitCode = 130; // interrupted: the caller must not treat the list as complete
  console.log("\nstopping: every saved block is kept; only the blocks in progress are redone on the next run");
  for (const c of running) c.kill();
});
let next = 0;
await Promise.all(Array.from({ length: Math.min(workers, total) }, async () => {
  while (!stopping && next < todo.length) await runChunk(todo[next++]);
}));
for (const f of fs.readdirSync(DIR)) if (f.endsWith(".tmp")) fs.rmSync(path.join(DIR, f));
if (!stopping) console.log(`done: ${kept.toLocaleString()} seeds kept, ${done} files finished`);
status();

// --from: regenerate the seeds of an existing list, report how their metrics
// are distributed and, given criteria, keep the ones that pass.
async function rescanList() {
  const listFile = path.resolve(ROOT, fromList);
  const rel = (f) => path.relative(ROOT, f);
  const raw = fs.readFileSync(listFile);
  if (raw.length % 4) { console.error(`${rel(listFile)} is not a list of 4-byte seeds`); process.exit(1); }
  const limit = parseInt(arg("--limit", "0"), 10);
  const n = limit > 0 ? Math.min(limit, raw.length / 4) : raw.length / 4;
  const list = new Uint32Array(n);
  for (let i = 0; i < n; i++) list[i] = raw.readUInt32LE(i * 4);
  const outArg = arg("--out", null), csvArg = arg("--csv", null);
  const outFile = outArg && path.resolve(ROOT, outArg);
  if (outFile && !criteria) { console.error("--out needs --criteria: without one every seed would be kept"); process.exit(1); }
  if (outFile === listFile) { console.error("--out would overwrite the list being read"); process.exit(1); }
  const workers = parseInt(arg("--workers", String(Math.max(1, os.cpus().length))), 10);
  console.log(`${mod}: ${n.toLocaleString()} seeds of ${rel(listFile)}, ${workers} workers`);

  // seedgen's METRICS_SCAN row: seed, then these, then whether its filter keeps it
  const COLS = ["np", "nw", "ne", "wp", "ef", "naqdv", "fdv", "ed"];
  const m = Object.fromEntries(COLS.map((c) => [c, new Int32Array(n)]));
  const state = new Uint8Array(n); // 0 = no row (seedgen could not generate it), 1 = dropped, 2 = kept
  const SLICE = 2_000; // per seedgen run: small enough for steady progress
  const running = new Set();
  let stopping = false, next = 0, doneSeeds = 0, lastLine = 0;
  const t0 = Date.now();
  process.on("SIGINT", () => { stopping = true; process.exitCode = 130; for (const c of running) c.kill(); });
  const runSlice = (skip, count) => new Promise((resolve, reject) => {
    const child = spawn(bin, [], {
      env: { ...baseEnv, METRICS_SCAN: "1", SEED_LIST: listFile, SEED_LIST_SKIP: String(skip), SEED_LIST_COUNT: String(count) },
      stdio: ["ignore", "pipe", "ignore"],
    });
    running.add(child);
    let p = skip, stale = false;
    readline.createInterface({ input: child.stdout }).on("line", (line) => {
      const v = line.split(",").map(Number);
      // a row is missing where a seed failed to generate, so match by seed
      while (p < skip + count && list[p] !== v[0]) p++;
      if (v.length !== COLS.length + 2 || p >= skip + count) { stale = true; return; }
      COLS.forEach((c, i) => { m[c][p] = v[i + 1]; });
      state[p++] = 1 + v[COLS.length + 1];
    });
    child.on("error", reject);
    child.on("close", (code) => {
      running.delete(child);
      if (stopping) return resolve();
      if (stale) return reject(new Error("seedgen does not understand SEED_LIST: rebuild it (node install.mjs --seedgen-only)"));
      if (code !== 0) return reject(new Error(`seedgen exited ${code} on list entries ${skip}..${skip + count}`));
      doneSeeds += count;
      if (Date.now() - lastLine > 10_000 && doneSeeds < n) {
        lastLine = Date.now();
        const rate = doneSeeds / ((Date.now() - t0) / 1000);
        console.log(`  ${doneSeeds.toLocaleString()} / ${n.toLocaleString()} (${(100 * doneSeeds / n).toFixed(0)}%), ${Math.round(rate).toLocaleString()}/s, ~${Math.ceil((n - doneSeeds) / rate / 60)} min left`);
      }
      resolve();
    });
  });
  await Promise.all(Array.from({ length: workers }, async () => {
    while (!stopping && next < n) { const skip = next; next += SLICE; await runSlice(skip, Math.min(SLICE, n - skip)); }
  }));
  if (stopping) return;

  const rows = [];
  for (let i = 0; i < n; i++) if (state[i]) rows.push(i);
  if (rows.length < n) console.log(`WARNING: ${(n - rows.length).toLocaleString()} seeds could not be generated and are left out`);
  const num = (v) => Number(v).toLocaleString();
  const pad = (v, w) => String(v).padStart(w);

  // --- distribution ---
  const NO_NAQ = 10_000_000; // seedgen's "no such field"
  const sorted = (c) => Int32Array.from(rows, (i) => m[c][i]).filter((v) => v < NO_NAQ).sort();
  const QS = [0, 0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99, 1];
  const LABELS = { np: "bodies (planets + moons)", wp: "bodies with water, %", ef: "bodies with enemies, %", ed: "enemy danger, -100..100", naqdv: "nearest naquium field, dv", fdv: "nearest field of any kind, dv" };
  console.log(`\ndistribution over the ${num(rows.length)} seeds`);
  console.log(pad("", 30) + ["min", "1%", "5%", "25%", "50%", "75%", "95%", "99%", "max"].map((h) => pad(h, 8)).join(""));
  for (const [c, label] of Object.entries(LABELS)) {
    const s = sorted(c);
    if (!s.length) continue;
    const none = rows.length - s.length;
    console.log(label.padEnd(30) + QS.map((q) => pad(num(s[Math.round(q * (s.length - 1))]), 8)).join("") + (none ? `   (${num(none)} seeds have none)` : ""));
  }

  // --- tails: how many seeds each cutoff would keep ---
  // [metric, keeps values at or below the cutoff?]
  const TAILS = { PLANETS_HIGH: ["np", false], PLANETS_LOW: ["np", true], NAQ_DV_LOW: ["naqdv", true], NAQ_DV_HIGH: ["fdv", false], ENEMY_PCT_LOW: ["ef", true], ENEMY_PCT_HIGH: ["ef", false], WATER_PCT_LOW: ["wp", true], WATER_PCT_HIGH: ["wp", false] };
  const inTail = (k, cut) => { const [c, low] = TAILS[k]; let cnt = 0; for (const i of rows) if (low ? m[c][i] <= cut : m[c][i] >= cut) cnt++; return cnt; };
  const basePath = path.join(ROOT, BASE_CRITERIA);
  const base = fs.existsSync(basePath) ? loadCriteria(basePath).tails : {};
  console.log(`\nseeds a cutoff would keep, tightening from the one in ${BASE_CRITERIA} (a seed can be in several tails)`);
  for (const k of TAIL_KEYS) {
    if (!(k in base)) continue; // the list is not complete for a tail it was not scanned with
    const [c, low] = TAILS[k];
    // the tail's values, most extreme first
    const vals = sorted(c).filter((v) => (low ? v <= base[k] : v >= base[k]));
    if (!low) vals.reverse();
    if (!vals.length) continue;
    let cuts = [...new Set(vals)];
    if (cuts.length > 12) cuts = [...new Set([1, 0.5, 0.2, 0.1, 0.05, 0.02, 0.01, 0.005, 0.002, 0.001].map((f) => vals[Math.max(0, Math.ceil(f * vals.length) - 1)]))];
    else cuts.reverse();
    // count by the last position of the cutoff value: ties come along
    const counts = cuts.map((cut) => vals.lastIndexOf(cut) + 1);
    const w = Math.max(8, ...counts.map((v) => num(v).length + 2));
    console.log(`${k} (${LABELS[c]} ${low ? "<=" : ">="} cutoff)`);
    console.log("  cutoff" + cuts.map((v) => pad(v, w)).join(""));
    console.log("  seeds " + counts.map((v) => pad(num(v), w)).join(""));
  }

  if (csvArg) {
    const fd = fs.openSync(path.resolve(ROOT, csvArg), "w");
    let chunk = ["seed," + COLS.join(",") + (criteria ? ",keep" : "")];
    for (const i of rows) {
      chunk.push(list[i] + "," + COLS.map((c) => m[c][i]).join(",") + (criteria ? "," + (state[i] - 1) : ""));
      if (chunk.length >= 50_000) { fs.writeSync(fd, chunk.join("\n") + "\n"); chunk = []; }
    }
    if (chunk.length) fs.writeSync(fd, chunk.join("\n") + "\n");
    fs.closeSync(fd);
    console.log(`\nwrote the metrics of every seed to ${csvArg}`);
  }
  if (!criteria) return;

  // --- the smaller list ---
  const keptSeeds = Uint32Array.from(rows.filter((i) => state[i] === 2), (i) => list[i]);
  console.log(`\n${rel(criteriaFile)}: ${num(keptSeeds.length)} of ${num(rows.length)} seeds kept (${(100 * keptSeeds.length / rows.length).toFixed(2)}%)`);
  for (const [k, v] of Object.entries(tails)) {
    console.log(`  ${k}=${v}`.padEnd(24) + pad(num(inTail(k, Number(v))), 10) + " seeds" +
      (!(k in base) ? "   WARNING: not a tail of the base scan, so only what the list happens to hold"
        : (TAILS[k][1] ? Number(v) > Number(base[k]) : Number(v) < Number(base[k])) ? `   WARNING: looser than the base scan (${base[k]}), so incomplete` : ""));
  }
  if (!outFile) return;
  fs.writeFileSync(outFile, Buffer.from(keptSeeds.buffer));
  const meta = outFile + ".json";
  fs.writeFileSync(meta, JSON.stringify({
    mod, from: rel(listFile), from_seeds: n, seeds: keptSeeds.length, generator_commit: commit,
    description: criteria.description, ...(criteria.filter ? { filter: criteria.filter } : { tails }),
  }, null, 1) + "\n");
  console.log(`wrote ${num(keptSeeds.length)} seeds -> ${rel(outFile)} (how it was made: ${rel(meta)})`);
}
