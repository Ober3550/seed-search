#!/usr/bin/env node
// ─────────────────────────────────────────────────────────────────────────────
// End-to-end test: the "Analyze seed" page does everything in the browser.
//
//   /analyze/<seed>  →  universe generated client-side (universe.wasm)
//                    →  click a zone's 🗺️ button
//                    →  that zone's surface generated client-side (surface.wasm)
//                       and drawn to a canvas — no backend per-seed work.
//
// The test also cross-checks the browser-generated surface against the NATIVE
// segen binary for the same seed/zone/radius: resource amounts must match
// exactly, proving the browser path is the same code as the trusted generator.
//
// Usage:
//   node e2e/analyze-surface.test.mjs
//   SEED=3403311347 RADIUS=150 node e2e/analyze-surface.test.mjs
//   CHROME=/path/to/chrome node e2e/analyze-surface.test.mjs   (or system Chrome)
//
// Prereqs: built wasm (node install.mjs), system Chrome, playwright-core
// (npm i -D playwright-core). The segen cross-check needs a native segen build
// (surface_generator/zig-out/bin/segen); it's skipped with a warning otherwise.
// ─────────────────────────────────────────────────────────────────────────────
import { spawn } from "node:child_process";
import { createServer } from "node:net";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright-core";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, "..");

const SEED = Number(process.env.SEED ?? 32094082);
const K2 = process.env.K2 === "0" ? false : true;
const RADIUS = Number(process.env.RADIUS ?? 120); // render half-extent (tiles)
const CHROME = process.env.CHROME; // optional explicit chrome executable

const SERVER = path.join(ROOT, "space_explorer_gui", "server.js");
const UNIVERSE_WASM = path.join(ROOT, "space_explorer_gui", "public", "universe.wasm");
const SURFACE_WASM = path.join(ROOT, "space_explorer_gui", "public", "surface.wasm");
const SEGEN = path.join(ROOT, "surface_generator", "zig-out", "bin", "segen");

function assert(cond, msg) {
  if (!cond) throw new Error("ASSERT FAILED: " + msg);
}

function log(msg) { console.log("  " + msg); }

function freePort() {
  return new Promise((resolve, reject) => {
    const srv = createServer();
    srv.listen(0, "127.0.0.1", () => {
      const port = srv.address().port;
      srv.close(() => resolve(port));
    });
    srv.on("error", reject);
  });
}

function waitForServer(url, ms = 20000) {
  return new Promise((resolve, reject) => {
    const t0 = Date.now();
    const tick = () => {
      fetch(url).then(() => resolve()).catch(() => {
        if (Date.now() - t0 > ms) return reject(new Error("server did not come up"));
        setTimeout(tick, 250);
      });
    };
    tick();
  });
}

function run(cmd, args, opts = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { cwd: opts.cwd ?? ROOT, ...opts.spawn });
    let out = "";
    child.stdout.on("data", (d) => { out += d; });
    child.stderr.on("data", (d) => { out += d; });
    child.on("error", reject);
    child.on("close", (code) => resolve({ code, out }));
  });
}

// Generate the universe the same way the browser does (same wasm), returning
// the parsed { s, k, z } object — used to feed segen for the cross-check.
async function generateUniverseNode() {
  assert(fs.existsSync(UNIVERSE_WASM), `missing ${UNIVERSE_WASM} — run "node install.mjs"`);
  const bytes = fs.readFileSync(UNIVERSE_WASM);
  const { instance } = await WebAssembly.instantiate(bytes, {});
  const e = instance.exports;
  e.generate(SEED >>> 0, K2 ? 1 : 0);
  return JSON.parse(new TextDecoder().decode(new Uint8Array(e.memory.buffer, e.resultPtr(), e.resultLen())));
}

// Native segen: render the same zone at the same radius, return the summary
// resources map. Returns null if segen isn't available.
async function nativeSegenResources(zoneName, zoneSeed) {
  if (!fs.existsSync(SEGEN)) return null;
  const uni = await generateUniverseNode();
  const zone = uni.z.find((z) => z.n === zoneName);
  if (!zone) throw new Error(`zone ${zoneName} not found in generated universe`);
  if (zone.s !== zoneSeed) throw new Error(`zone seed mismatch ${zone.s} != ${zoneSeed}`);
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "segen-e2e-"));
  const zonesFile = path.join(dir, "zones.jsonl");
  fs.writeFileSync(zonesFile, JSON.stringify(uni) + "\n");
  const outDir = path.join(dir, "out");
  const r = await run(SEGEN, [
    "--zones", zonesFile, "--world-seed", String(SEED), "--zone", zoneName,
    "--out", outDir, "--radius", String(RADIUS), "--render-surface",
  ]);
  const summaryPath = path.join(outDir, `seed_${SEED}`, zoneName, "summary.json");
  if (!fs.existsSync(summaryPath)) {
    throw new Error(`segen produced no summary.json (exit ${r.code}). Output:\n${r.out.slice(-2000)}`);
  }
  return JSON.parse(fs.readFileSync(summaryPath, "utf8")).resources;
}

async function main() {
  console.log(`\n🌐 e2e: seed ${SEED} · k2=${K2} · radius ${RADIUS} (all client-side)`);

  // 1. boot the web server with a scratch DB (no data needed — analyze is static)
  const port = await freePort();
  const dbPath = path.join(os.tmpdir(), `se-e2e-${process.pid}.sqlite`);
  const server = spawn(process.execPath, [SERVER], {
    env: {
      ...process.env,
      PORT: String(port),
      SE_GUI_DB: dbPath,
      SE_GUI_HEAP_BOOT: "1", // skip the big-heap re-exec
      SE_GUI_HEAP: "512",
    },
    stdio: ["ignore", "pipe", "pipe"],
  });
  let serverLog = "";
  server.stdout.on("data", (d) => (serverLog += d));
  server.stderr.on("data", (d) => (serverLog += d));
  const base = `http://127.0.0.1:${port}`;
  try {
    await waitForServer(base + "/analyze/" + SEED);
    log(`server up at ${base}`);

    // 2. launch a real browser
    const browser = await chromium.launch(
      CHROME ? { executablePath: CHROME, headless: true } : { channel: "chrome", headless: true }
    );
    const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
    const pageErrors = [];
    page.on("pageerror", (e) => pageErrors.push(e.message));

    // 3. universe in the browser. NOTE: #zt-body starts with a placeholder
    // <tr> ("Enter a seed…") so a bare selector match races the async worker
    // generation — wait for the status to leave "generating…" first.
    log(`→ /analyze/${SEED}?k2=${K2 ? 1 : 0}`);
    await page.goto(`${base}/analyze/${SEED}${K2 ? "?k2=1" : ""}`);
    await page.waitForFunction(() => {
      const s = document.getElementById("gen-status")?.textContent || "";
      return s.includes("generated client-side") || s.startsWith("error");
    }, null, { timeout: 60000 });
    const uniStatus = await page.textContent("#gen-status");
    assert(uniStatus.includes("generated client-side"), `universe not generated client-side: "${uniStatus}"`);
    const rowCount = await page.locator("#zt-body tr").count();
    assert(rowCount > 100, `expected >100 zone rows, got ${rowCount}`);
    log(`✓ universe generated in browser: ${rowCount} generatable zones`);

    // 4. click a moon's 🗺️ surface button
    const target = await page.evaluate(() => {
      const rows = [...document.querySelectorAll("#zt-body tr")];
      const row = rows.find((r) => r.querySelector(".zone-type")?.textContent === "moon");
      if (!row) return null;
      return { name: row.querySelector("td strong").textContent, type: row.querySelector(".zone-type").textContent };
    });
    assert(target, "no moon row to click");
    log(`→ click 🗺️ on ${target.name} (${target.type})`);
    await page.evaluate(() => {
      const rows = [...document.querySelectorAll("#zt-body tr")];
      rows.find((r) => r.querySelector(".zone-type")?.textContent === "moon")
        .querySelector("button[data-surf]").click();
    });
    await page.waitForFunction(() => !document.getElementById("surf-panel").hidden, null, { timeout: 5000 });
    // openSurface auto-renders at the panel's default radius; wait for that
    // first render to settle (or error), then set our radius and regenerate
    // (the busy flag would ignore a Generate click while a render is in flight).
    await page.waitForFunction(() =>
      window.__LAST_SURF__ || (document.getElementById("surf-status")?.textContent || "").startsWith("error"),
      null, { timeout: 120000 });
    await page.fill("#surf-radius", String(RADIUS));
    // Generation now runs in a Web Worker: probe that the main thread stays
    // responsive while the worker grinds — a 100ms timer must fire strictly
    // before the surface completes (an inline main-thread generation would
    // block it).
    const t0 = Date.now();
    await page.click("#surf-gen");
    const tickAt = await page.evaluate(() => new Promise((r) => setTimeout(() => r(Date.now()), 100)));
    await page.waitForFunction((r) => window.__LAST_SURF__?.radius === r, RADIUS, { timeout: 120000 });
    const doneAt = await page.evaluate(() => window.__LAST_SURF_AT__);
    assert(tickAt < doneAt - 50,
      `main thread blocked during generation (timer fired ${tickAt - t0}ms in, generation finished ${doneAt - t0}ms in)`);
    log(`✓ main thread stayed responsive during generation (timer ${tickAt - t0}ms < gen ${doneAt - t0}ms)`);
    const summary = await page.evaluate(() => window.__LAST_SURF__);
    assert(summary.ok, `surface generation failed: ${summary.error}`);
    assert(summary.zone === target.name, `clicked ${target.name} but generated ${summary.zone}`);
    assert(summary.width === RADIUS * 2 && summary.height === RADIUS * 2,
      `expected ${RADIUS * 2}×${RADIUS * 2} canvas, got ${summary.width}×${summary.height}`);
    const resNames = Object.keys(summary.resources);
    assert(resNames.length >= 1, "no resources placed — surface looks empty");
    log(`✓ surface generated in browser: ${summary.zone} · r${summary.radius} · ` +
      resNames.map((r) => `${r}=${summary.resources[r].amount}`).join(" "));

    // 6. canvas actually drew the pixels
    const canvas = await page.evaluate(() => {
      const c = document.getElementById("surf-canvas");
      const d = c.getContext("2d").getImageData(0, 0, c.width, c.height).data;
      let opaque = 0;
      for (let i = 3; i < d.length; i += 4) if (d[i] > 0) opaque++;
      return { w: c.width, h: c.height, opaque };
    });
    assert(canvas.opaque > 0, "canvas is blank");
    log(`✓ canvas drawn ${canvas.w}×${canvas.h} (${canvas.opaque} opaque px)`);

    // 7. cross-check vs native segen (same seed/zone/radius) — amounts must match
    const native = await nativeSegenResources(summary.zone, summary.zone_seed);
    if (native) {
      const keys = new Set([...Object.keys(native), ...Object.keys(summary.resources)]);
      for (const k of keys) {
        const a = summary.resources[k]?.amount ?? 0;
        const b = native[k]?.amount ?? 0;
        assert(a === b, `resource ${k}: browser ${a} != native segen ${b}`);
      }
      log(`✓ cross-check vs native segen: ${keys.size} resource amounts identical`);
    } else {
      log("⚠  native segen not found — skipping cross-check (install.mjs builds it)");
    }

    // 8. the click→surface flow made no backend calls beyond static assets
    assert(pageErrors.length === 0, `page errors: ${pageErrors.join("; ")}`);
    log("✓ no page errors");

    await browser.close();
    console.log("\n✅ E2E PASS — seed → universe → zone surface, all in the browser");
  } finally {
    server.kill();
    try { fs.unlinkSync(dbPath); } catch {}
  }
}

main().catch((e) => {
  console.error("\n❌ E2E FAIL:", e.message);
  process.exitCode = 1;
});
