#!/usr/bin/env node
// Coarse seed scan: reduce the whole seed space to the short list of seeds
// worth looking at, storing ONLY the seed numbers.
//
//   node scripts/seed-scan.mjs --mod se [--range 0:4294967296] [--workers N]
//   node scripts/seed-scan.mjs --mod se --status
//   node scripts/seed-scan.mjs --mod se --pack
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
//   manifest.json            criteria, chunk size, generator commit
//   <start>-<end>.u32        kept seeds of one chunk, ascending u32 LE
// A chunk file appears only when its chunk has finished, so the scan can be
// stopped (Ctrl-C) and resumed at any time: finished chunks are skipped.
// --pack concatenates the chunks into seedlists/<mod>.u32.
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
  console.error("usage: seed-scan.mjs --mod se|k2se [--range lo:hi] [--workers N] [--criteria file] | --status | --pack");
  process.exit(1);
}
const DIR = path.join(ROOT, "seedlists", mod);
const MANIFEST = path.join(DIR, "manifest.json");
const CHUNK = 1_000_000;
const SEED_SPACE = 4294967296;

function chunks() {
  if (!fs.existsSync(DIR)) return [];
  return fs.readdirSync(DIR).filter((f) => /^\d+-\d+\.u32$/.test(f))
    .map((f) => { const [a, b] = f.replace(".u32", "").split("-").map(Number); return { file: path.join(DIR, f), a, b }; })
    .sort((x, y) => x.a - y.a);
}
function status() {
  const cs = chunks();
  let seeds = 0, covered = 0;
  for (const c of cs) { covered += c.b - c.a; seeds += fs.statSync(c.file).size / 4; }
  const pct = (100 * covered / SEED_SPACE).toFixed(2);
  console.log(`${mod}: ${covered.toLocaleString()} seed numbers scanned (${pct}% of the seed space), ${seeds.toLocaleString()} seeds kept` +
    (seeds ? ` = 1 universe in ${Math.round(covered / 2 / seeds).toLocaleString()}, ${(seeds * 4 / 1048576).toFixed(2)} MB` : ""));
  return { cs, seeds, covered };
}

if (process.argv.includes("--status")) { status(); process.exit(0); }
if (process.argv.includes("--pack")) {
  const { cs, seeds } = status();
  // warn about holes: a packed list should say what it covers
  let gaps = 0;
  for (let i = 1; i < cs.length; i++) if (cs[i].a !== cs[i - 1].b) gaps++;
  const out = path.join(ROOT, "seedlists", mod + ".u32");
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
const criteriaFile = path.resolve(ROOT, arg("--criteria", `scripts/seed-criteria/${mod}.json`));
const criteria = JSON.parse(fs.readFileSync(criteriaFile, "utf8"));
if (criteria.mod && criteria.mod !== mod) {
  console.error(`${path.relative(ROOT, criteriaFile)} is for "${criteria.mod}", not "${mod}"`);
  process.exit(1);
}
const tails = {};
for (const [k, v] of Object.entries(criteria.tails || {})) {
  if (!TAIL_KEYS.includes(k)) { console.error(`unknown tail "${k}" in criteria`); process.exit(1); }
  if (v > 0) tails[k] = String(v);
}
if (!Object.keys(tails).length) { console.error("criteria has no tails: refusing to keep every seed"); process.exit(1); }
const bin = path.join(ROOT, "universe_generator", "zig", process.platform === "win32" ? "seedgen.exe" : "seedgen");
if (!fs.existsSync(bin)) { console.error("seedgen not built (run: node install.mjs --seedgen-only)"); process.exit(1); }

// one list = one criterion: refuse to mix
fs.mkdirSync(DIR, { recursive: true });
const commit = execFileSync("git", ["rev-parse", "--short", "HEAD"], { cwd: ROOT, encoding: "utf8" }).trim();
if (fs.existsSync(MANIFEST)) {
  const m = JSON.parse(fs.readFileSync(MANIFEST, "utf8"));
  if (JSON.stringify(m.tails) !== JSON.stringify(tails)) {
    console.error(`seedlists/${mod} was scanned with different criteria; move it aside or use the same criteria file`);
    process.exit(1);
  }
} else {
  fs.writeFileSync(MANIFEST, JSON.stringify({ mod, chunk: CHUNK, generator_commit: commit, description: criteria.description, tails }, null, 1) + "\n");
}

const todo = [];
for (let a = Math.floor(lo / CHUNK) * CHUNK; a < hi; a += CHUNK) {
  const s = Math.max(a, lo), e = Math.min(a + CHUNK, hi);
  if (!fs.existsSync(path.join(DIR, `${s}-${e}.u32`))) todo.push([s, e]);
}
const total = todo.length;
console.log(`${mod}: ${total} chunks of ${CHUNK.toLocaleString()} seed numbers to scan in ${lo}:${hi}, ${workers} workers`);
console.log(`criteria: ${Object.entries(tails).map(([k, v]) => `${k}=${v}`).join(" ")}`);

// seedgen's own tail filter (no FILTER document): keep a seed in ANY tail
const baseEnv = { ...process.env, SE_K2: String(K2[mod]), SE_ENABLE_K2: String(K2[mod]), MIN_PROD_MODULES: "0", WORKER_ID: "0" };
for (const k of ["FILTER", "METRICS_SCAN", "ALL_ZONES", "MIN_NAQ_DV", ...TAIL_KEYS]) delete baseEnv[k];
Object.assign(baseEnv, tails);

let done = 0, kept = 0, stopping = false;
const running = new Set();
const t0 = Date.now();
function runChunk([s, e]) {
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
      if (stopping) return resolve();
      if (code !== 0) return reject(new Error(`seedgen exited ${code} on ${s}-${e}`));
      seeds.sort((x, y) => x - y);
      const buf = Buffer.alloc(seeds.length * 4);
      seeds.forEach((v, i) => buf.writeUInt32LE(v, i * 4));
      const file = path.join(DIR, `${s}-${e}.u32`);
      fs.writeFileSync(file + ".tmp", buf);
      fs.renameSync(file + ".tmp", file); // a chunk file only ever appears complete
      done++;
      kept += seeds.length;
      if (done % 10 === 0 || done === total) {
        const min = (Date.now() - t0) / 60000;
        const left = (total - done) * (min / done);
        console.log(`  ${done}/${total} chunks, ${kept.toLocaleString()} kept, ${min.toFixed(0)} min elapsed, ~${left < 90 ? left.toFixed(0) + " min" : (left / 60).toFixed(1) + " h"} left`);
      }
      resolve();
    });
  });
}
process.on("SIGINT", () => {
  stopping = true;
  console.log("\nstopping: unfinished chunks are discarded and will be rescanned on the next run");
  for (const c of running) c.kill();
});
let next = 0;
await Promise.all(Array.from({ length: Math.min(workers, total) }, async () => {
  while (!stopping && next < todo.length) await runChunk(todo[next++]);
}));
for (const f of fs.readdirSync(DIR)) if (f.endsWith(".tmp")) fs.rmSync(path.join(DIR, f));
if (!stopping) console.log(`done: ${kept.toLocaleString()} seeds kept from ${total} chunks`);
status();
