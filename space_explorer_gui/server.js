#!/usr/bin/env node
const express = require("express");
const path = require("path");
const fs = require("fs");
const db = require("./db");
const jobs = require("./job-manager");
const analyze = require(path.join(__dirname, "..", "verifier", "analyze.js"));

const RESOURCES = [
  "se-vulcanite", "se-cryonite", "se-vitamelange", "se-holmium-ore",
  "se-beryllium-ore", "se-iridium-ore", "se-naquium-ore",
  "kr-imersite", "kr-mineral-water", "kr-rare-metal-ore",
  "iron-ore", "copper-ore", "coal", "stone", "uranium-ore", "crude-oil",
];

const app = express();
const PORT = process.env.PORT || 3456;

// Dev livereload: on in dev (default), off with NODE_ENV=production.
const DEV = process.env.NODE_ENV !== "production";
const START_EPOCH = Date.now(); // changes on every `node --watch` restart

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use("/static", express.static(path.join(__dirname, "public")));
app.use("/output", express.static(jobs.OUTPUT_DIR));

// Browser auto-reload (dev only, zero deps). The page holds this SSE stream
// open; when `node --watch` restarts the server the socket drops, EventSource
// auto-reconnects, sees a newer epoch, and reloads. See LIVERELOAD_SNIPPET.
if (DEV) {
  app.get("/__livereload", (req, res) => {
    res.set({ "Content-Type": "text/event-stream", "Cache-Control": "no-cache", Connection: "keep-alive" });
    res.flushHeaders();
    res.write(`event: hello\ndata: ${START_EPOCH}\n\n`);
    const ping = setInterval(() => res.write(": ping\n\n"), 30000);
    req.on("close", () => clearInterval(ping));
  });
}

const LIVERELOAD_SNIPPET = DEV ? `
  <script>
  (function () {
    var epoch = null;
    var es = new EventSource("/__livereload");
    es.addEventListener("hello", function (e) {
      if (epoch !== null && epoch !== e.data) location.reload();
      epoch = e.data;
    });
    // EventSource reconnects on its own after a restart — no onerror needed.
  })();
  </script>` : "";

// ── Layout ───────────────────────────────────────────────────────────────

function htmxPage(title, content) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} — SE Explorer</title>
  <script src="/static/htmx.min.js"></script>
  <link rel="stylesheet" href="/static/style.css">${LIVERELOAD_SNIPPET}
</head>
<body>
  <div class="app">
    <nav class="sidebar">
      <h1>🌌 SE Explorer</h1>
      <ul class="nav-links">
        <li><a href="/universe" hx-get="/universe" hx-target="#main" hx-push-url="true" hx-sync="#main:replace">Universe Buckets</a></li>
        <li><a href="/seeds" hx-get="/seeds" hx-target="#main" hx-push-url="true" hx-sync="#main:replace">Seeds</a></li>
        <li><a href="/presets" hx-get="/presets" hx-target="#main" hx-push-url="true" hx-sync="#main:replace">Filter Presets</a></li>
        <li><a href="/surfaces" hx-get="/surfaces" hx-target="#main" hx-push-url="true" hx-sync="#main:replace">Surface Jobs</a></li>
        <li><a href="/workers" hx-get="/workers" hx-target="#main" hx-push-url="true" hx-sync="#main:replace">Workers</a></li>
      </ul>
      <div class="sidebar-footer">
        <button type="button" class="btn danger wipe-btn" hx-post="/api/system/wipe" hx-swap="none"
          hx-confirm="⚠️ Wipe the whole system? This deletes ALL jobs, seeds, and generated surfaces (the database AND the output/ folder). This cannot be undone."
          hx-on::after-request="htmx.ajax('GET','/universe',{target:'#main'})">
          🗑 Wipe system
        </button>
        <small>buckets → seeds → zone → surface</small>
      </div>
    </nav>
    <main id="main">${content}</main>
  </div>
</body>
</html>`;
}

function page(req, res, title, content) {
  // htmx history restore (Back on a cache miss) sets hx-request too, but needs the
  // full page to rebuild the body — only serve the bare fragment for live swaps.
  if (req.headers["hx-request"] && !req.headers["hx-history-restore-request"])
    res.send(content);
  else res.send(htmxPage(title, content));
}

function fmtAmount(n) {
  if (n >= 1e9) return (n / 1e9).toFixed(2) + "B";
  if (n >= 1e6) return (n / 1e6).toFixed(2) + "M";
  return String(n);
}

function seedCriteria(s) { try { return JSON.parse(s.criteria); } catch (_) { return null; } }
function filterRulesLabel(f) {
  try { const r = JSON.parse(f.rules); return r.map(analyze.ruleLabel).join(" AND ") || "no rules"; }
  catch (_) { return "—"; }
}

function zoneSurfaceSummary(bucket, seed, zoneName) {
  try {
    return JSON.parse(fs.readFileSync(path.join(jobs.seedDir(bucket, seed), zoneName, "summary.json"), "utf8"));
  } catch (_) { return null; }
}
function zoneSurfacePng(bucket, seed, zoneName, base = "ore") {
  const rel = path.join(bucket, `seed_${seed}`, zoneName, `${base}.png`);
  return fs.existsSync(path.join(jobs.OUTPUT_DIR, rel)) ? `/output/${rel}` : null;
}

// All resource chips inline (a couple of wrapped rows is fine, no collapsing).
function resChips(prefix, chips) {
  if (!chips.length) return "—";
  return `${prefix}${chips.join(" ")}`;
}

// Inner HTML of the Resources cell: measured amounts if a summary exists,
// otherwise the universe-generator estimates. Highest quantity first, with the
// long tail collapsed behind a chevron.
function renderZoneResources(bucket, seed, zone) {
  const nm = (r) => r.replace("se-", "").replace("kr-", "").replace("-ore", "");
  const summary = zoneSurfaceSummary(bucket, seed, zone.name);
  if (summary) {
    const chips = Object.entries(summary.resources || {})
      .sort((a, b) => (b[1].amount || 0) - (a[1].amount || 0))
      .map(([r, v]) => `<span class="res-chip">${nm(r)} <strong>${v.display || fmtAmount(v.amount)}</strong></span>`);
    return resChips("✅ ", chips);
  }
  let y = {};
  try { y = JSON.parse(zone.resource_yields || "{}"); } catch (_) {}
  const mag = (v) => {
    const m = String(v).match(/([\d.]+)\s*([BMK]?)/i);
    if (!m) return 0;
    const s = { b: 1e9, m: 1e6, k: 1e3 }[(m[2] || "").toLowerCase()] || 1;
    return parseFloat(m[1]) * s;
  };
  const chips = Object.entries(y).sort((a, b) => mag(b[1]) - mag(a[1]))
    .map(([r, v]) => `<span class="res-chip est">${nm(r)} <strong>${v}</strong></span>`);
  return resChips("", chips);
}

// The actions/status cell for one zone row. Reflects live job state and, while
// anything is queued/running, polls itself every 2s. When ore work finishes it
// also pushes a fresh Resources cell out-of-band (est → measured).
// OOB refresh of the Resources cell so est→measured flips as jobs land. Emitted
// only on poll/create responses — never in the initial full-page render, where a
// second <td> would duplicate the column.
// The OOB target is a <div> (flow content), not a bare <td>: when the poll
// response leads with the control <span>, the HTML parser is in "in body" mode
// and would silently drop a stray <td>, leaking its chips next to the button.
function resOobTd(bucket, seed, zone) {
  return `<div id="zres-${zone.id}" hx-swap-oob="true">${renderZoneResources(bucket, seed, zone)}</div>`;
}

// One generate-control (ore or surface) for a zone row, in its own <span> that
// self-polls ONLY while its own job type is active. This keeps a running ore job
// from re-rendering (flashing) the surface button every 2s, and vice-versa. The
// button still re-renders the whole cell (#zcell-N) on click, so a surface job —
// which also queues the ore map — flips both controls at once.
// Max generation radius (default 5000 → ≤ ~78.5M tiles per disk). Big planets
// and asteroid fields are capped to this so we don't render the full surface.
const DEFAULT_MAX_RADIUS = 5000;
function getMaxRadius() {
  const v = parseInt(db.getSetting("max_radius"));
  return Number.isFinite(v) && v > 0 ? v : DEFAULT_MAX_RADIUS;
}
function effRadius(zone) {
  const m = getMaxRadius();
  return Math.min(Math.round(zone.radius || m), m);
}
// Global max-radius control (persisted setting). Caps NEW surface jobs to the
// inner N-radius disk; existing renders are untouched.
function maxRadiusInput() {
  return `<label class="hint max-radius-ctl" title="Cap surface generation to the inner N-tile-radius disk (default ${DEFAULT_MAX_RADIUS} ≈ 78.5M tiles). Applies to new renders only.">
    ⌀ Max radius: <input type="number" name="max_radius" value="${getMaxRadius()}" min="100" step="100" style="width:6em"
      hx-post="/api/settings/max-radius" hx-trigger="change" hx-swap="none"></label>`;
}

function renderZoneCtl(bucket, seed, zone, which) {
  const zjobs = db.getSurfaceJobsForZone(zone.id);
  // The ore map is a shared job, but each control tracks only its own half: the
  // ore control watches ore/oremap, the surface control watches terrain, and the
  // two buttons queue independent jobs (⛏ ore → oremap only, 🗺️ surface →
  // terrain only), so neither ever lights up (flashes) the other's control.
  const SURF_KINDS = ["surface", "terrain", "gputerrain"];
  const active = (kinds) => zjobs.filter(j => kinds.includes(j.kind) && (j.status === "queued" || j.status === "running"));
  const failed = (kinds) => zjobs.filter(j => kinds.includes(j.kind) && j.status === "failed").length > 0;
  const genArgs = `hx-vals='${JSON.stringify({ zone_id: zone.id, seed, zone_name: zone.name, radius: effRadius(zone) })}'`;
  const tgt = `hx-target="#zcell-${zone.id}" hx-swap="outerHTML"`;
  const id = which === "ore" ? `orectl-${zone.id}` : `surfctl-${zone.id}`;
  // Asteroid-field terrain (se-space/se-asteroid) renders on the GPU; its ore
  // layer — ices + naquium + base ores, masked to se-asteroid tiles — is the
  // same CPU oremap path as planets/moons (segen no longer skips fields).
  const isField = zone.zone_type === "asteroid-field";

  // Once a layer is generated we drop its button entirely (the row itself opens
  // the surface detail); the generate button only shows while nothing exists yet.
  let inner, activeNow;
  if (which === "ore") {
    // ore amounts + ore-map render
    activeNow = active(["ore", "oremap", "oredump", "gpuoremap"]).length > 0;
    const oremapPng = zoneSurfacePng(bucket, seed, zone.name, "oremap");
    inner = activeNow
      ? `<span class="gen-status running">⏳ ore…</span>`
      : oremapPng
        ? ""
        : `<button type="button" class="btn-sm" hx-post="/api/surface/create?kind=oremap" ${genArgs} ${tgt}>⛏ ore</button>`;
    if (!activeNow && !oremapPng && failed(["ore", "oremap", "oredump", "gpuoremap"]))
      inner += ` <span class="gen-status failed" title="see Surface Jobs">⚠️</span>`;
  } else {
    const surfActive = active(SURF_KINDS);
    activeNow = surfActive.length > 0;
    const surfDone = zjobs.filter(j => SURF_KINDS.includes(j.kind) && j.status === "done").length;
    // "generated" is decided by the file on disk, not the DB: tiled renders now
    // stitch into a whole terrain.png (or the legacy surface.png), so its
    // presence is authoritative. Deleting the zone folder immediately reverts
    // the zone to "not generated" (the generate button reappears).
    const surfPng = zoneSurfacePng(bucket, seed, zone.name, "terrain")
      || zoneSurfacePng(bucket, seed, zone.name, "surface");
    inner = activeNow
      ? `<span class="gen-status running">⏳ surface ${surfDone}/${surfActive.length + surfDone}</span>`
      : surfPng
        ? ""
        // One surface button for every zone type. gpu_segen is the surface
        // compute path now (same terrain.png output as the CPU oracle, ~80x
        // faster, and the only renderer for asteroid fields) — no separate
        // GPU button.
        : `<button type="button" class="btn-sm btn-secondary" hx-post="/api/surface/create?kind=gputerrain" ${genArgs} ${tgt}>🗺️ surface</button>`;
    if (!activeNow && !surfPng && failed(["terrain", "gputerrain"]))
      inner += ` <span class="gen-status failed" title="see Surface Jobs">⚠️</span>`;
  }

  const poll = activeNow
    ? `hx-get="/api/zone/control?seed=${seed}&zone_id=${zone.id}&which=${which}" hx-trigger="every 2s" hx-swap="outerHTML" hx-sync="#main:drop"`
    : "";
  return `<span class="zctl" id="${id}" ${poll}>${inner}</span>`;
}

function renderZoneCell(bucket, seed, zone, withResOob = false) {
  return `<td class="row-actions" id="zcell-${zone.id}">`
    + renderZoneCtl(bucket, seed, zone, "ore")
    + renderZoneCtl(bucket, seed, zone, "surf")
    + `</td>`
    + (withResOob ? resOobTd(bucket, seed, zone) : "");
}

// Breadcrumb trail for the drill-down.
function crumbs(parts) {
  return `<div class="crumbs">${parts.map((p, i) =>
    i === parts.length - 1
      ? `<span>${p.label}</span>`
      : `<a href="${p.href}" hx-get="${p.href}" hx-target="#main" hx-push-url="true">${p.label}</a> ›`
  ).join(" ")}</div>`;
}

app.get("/", (req, res) => res.redirect("/universe"));

// ── Level 1: Universe buckets ──────────────────────────────────────────

app.get("/universe/table", (req, res) => res.send(renderBucketsTable(db.getUniverseJobs())));
app.get("/universe", (req, res) => page(req, res, "Universe Buckets", renderUniversePage(db.getUniverseJobs())));

function renderUniversePage(jobsList) {
  const bs = jobs.BUCKET_SIZE;
  const bsLabel = bs >= 1e6 ? `${bs / 1e6}M` : `${bs / 1000}k`;
  return `
  <div class="page">
    <div class="page-head">
      <h2>🌠 Universe Generation</h2>
      <div class="head-actions">
        <button type="button" class="btn danger" hx-post="/api/jobs/cancel-all" hx-swap="none"
          hx-confirm="Cancel ALL queued and running jobs (universe + surface) and kill their processes?"
          hx-on::after-request="htmx.ajax('GET','/universe',{target:'#main'})">
          ✖ Cancel all jobs
        </button>
        <button type="button" class="btn" hx-post="/api/jobs/clear-cancelled" hx-swap="none"
          hx-confirm="Delete all CANCELLED job entries and their on-disk bucket data? (surviving buckets are kept)"
          hx-on::after-request="htmx.ajax('GET','/universe',{target:'#main'})">
          🧹 Clear cancelled
        </button>
      </div>
    </div>
    <p class="hint">Every job is a fixed ${bsLabel}-seed bucket; each writes
    <code>output/&lt;bucket&gt;/seeds.jsonl</code> (seedgen's rough pass).</p>
    <div class="job-form">
      <form hx-post="/api/universe/create" hx-swap="none"
            hx-on::after-request="htmx.ajax('GET','/universe/table',{target:'#jobs-table'})">
        <label title="Each unit = one ${bsLabel} bucket">Buckets (×${bsLabel}): <input type="number" name="units" value="10" min="1" max="1000" required></label>
        <label title="Dev shortcut: begin at this seed (snapped to a ${bsLabel} boundary). Blank = continue after the last bucket.">Start seed: <input type="number" name="start_seed" value="" min="0" step="${bs}" placeholder="auto (continue after last bucket)"></label>
        <fieldset class="tail-filter" style="border:1px solid var(--border,#333);padding:6px 10px;border-radius:6px">
          <legend class="hint">Extremity tails — keep a seed at EITHER end (union). Low ≥ metric ≥ High. Defaults ≈ 170/100k bucket (a 100k bucket is 50k seeds — seedgen steps by 2). Blank = end off.</legend>
          <div class="tail-row" title="low = nearest naquium-PRIMARY field Δv ≤ (closest, rich naq ~38/100k); high = nearest ANY field Δv ≥ (furthest — even a basic field is a long haul ~25/100k). Δv is now game-exact (launch+travel), so values are ~23k-160k.">
            <input type="number" name="naq_lo" value="23700" min="0" step="500" style="width:6em" placeholder="off"> ≥ naq-prim ≤ | any-field ≥ <input type="number" name="naq_hi" value="43400" min="0" step="500" style="width:6em" placeholder="off">
          </div>
          <div class="tail-row" title="keep seeds with ≤ the low value Calidus planets+moons incl. Nauvis (fewest) OR ≥ the high value (most, ~43/100k). NOTE: measured minimum P+M is 14, so a low cutoff below 14 never matches.">
            <input type="number" name="pl_lo" value="16" min="0" style="width:4em" placeholder="off"> ≥ P+M ≥ <input type="number" name="pl_hi" value="46" min="0" style="width:4em" placeholder="off">
          </div>
          <div class="tail-row" title="Share of Calidus planets+moons (excl. Nauvis) that HAVE water, as a %. 0 = nowhere has water, 100 = everywhere does. Normalised, not a count — raw counts just track system size. Population: mean 69%, p1 50%, p99 88%. Defaults ≈ 28/100k (parched) and 21/100k (wet).">
            <input type="number" name="wp_lo" value="40" min="0" max="100" style="width:4em" placeholder="off"> ≥ water % ≥ <input type="number" name="wp_hi" value="95" min="0" max="100" style="width:4em" placeholder="off">
          </div>
          <div class="tail-row" title="Share of Calidus planets+moons (excl. Nauvis) with an enemy tag above none, as a %. Population: mean 70%, p1 52%, p99 84%. Defaults ≈ 30/100k (quiet) and 11/100k (warzone); use 87 for the high side if you want ~48.">
            <input type="number" name="ef_lo" value="42" min="0" max="100" style="width:4em" placeholder="off"> ≥ hostile % ≥ <input type="number" name="ef_hi" value="88" min="0" max="100" style="width:4em" placeholder="off">
          </div>
        </fieldset>
        <label>K2: <input type="checkbox" name="k2_enabled"></label>
        <button type="submit" class="btn">Queue Buckets</button>
      </form>
    </div>
    <div id="jobs-table" hx-get="/universe/table" hx-trigger="every 3s" hx-sync="#main:drop">${renderBucketsTable(jobsList)}</div>
  </div>`;
}

function renderBucketsTable(jobsList) {
  return `
    <table class="data-table">
      <thead><tr><th>Bucket</th><th>Seed Range</th><th>K2</th><th>Status</th><th>Passed</th><th>Zones</th><th>Created</th><th></th></tr></thead>
      <tbody>
        ${jobsList.map(j => `
        <tr class="row-${j.status}">
          <td><strong>${j.bucket || "—"}</strong></td>
          <td>${j.seed_start.toLocaleString()} – ${j.seed_end.toLocaleString()}</td>
          <td>${j.k2_enabled ? "✅" : "—"}</td>
          <td><span class="badge ${j.status}">${j.status}</span></td>
          <td>${j.passed_seeds ?? "—"}</td>
          <td>${j.total_zones ?? "—"}</td>
          <td>${j.created_at}</td>
          <td>${j.status === "done" ? `<a href="/seeds?bucket=${j.bucket}" hx-get="/seeds?bucket=${j.bucket}" hx-target="#main" hx-push-url="true" class="btn-sm">Seeds →</a>` : ""}</td>
        </tr>`).join("")}
        ${jobsList.length === 0 ? `<tr><td colspan="8">No buckets yet.</td></tr>` : ""}
      </tbody>
    </table>`;
}

// ── Level 2: Seeds (raw rough-passed seeds for a bucket) ───────────────
// Live-filter controls here define a criteria you can SAVE as a filtered set.

app.get("/seeds", (req, res) => {
  const bucket = req.query.bucket || "";
  const defId = req.query.def ? parseInt(req.query.def) : null;
  const loot = req.query.loot || "";
  const k2q = req.query.k2 || ""; // "" any | "1" k2-only | "0" vanilla-only
  const k2filter = k2q === "1" ? true : k2q === "0" ? false : undefined;

  const def = defId ? db.getFilterDef(defId) : null;
  const rules = def ? JSON.parse(def.rules) : [];
  // Count mode: rank by how many rules each seed satisfies instead of dropping
  // partial matches. Only meaningful when a filter is selected.
  const countMode = (req.query.count === "1") && rules.length > 0;

  // Extremity range filters (Calidus planets+moons; nearest-naq Δv).
  const rng = { np_min: req.query.np_min, np_max: req.query.np_max, naqdv_min: req.query.naqdv_min, naqdv_max: req.query.naqdv_max, fdv_min: req.query.fdv_min, fdv_max: req.query.fdv_max, wp_min: req.query.wp_min, wp_max: req.query.wp_max, ef_min: req.query.ef_min, ef_max: req.query.ef_max };
  const seedQ = (req.query.seed || "").toString().trim();
  let seeds = db.getSeeds({ bucket: bucket || undefined, loot: loot || undefined, k2: k2filter, seed: seedQ || undefined, ...rng });
  if (countMode) {
    for (const s of seeds) {
      const c = seedCriteria(s);
      s._matches = c ? analyze.countMatches(c, rules) : 0;
    }
  } else {
    seeds = seeds.filter(s => {
      const c = seedCriteria(s); if (!c) return rules.length === 0;
      return analyze.matchFilter(c, rules).match;
    });
  }
  const defs = db.getFilterDefs();
  const genCounts = db.getGeneratedZoneCounts();
  page(req, res, "Seeds", renderSeedsPage(seeds, defs, { bucket, defId, def, loot, k2: k2q, count: countMode, ruleCount: rules.length, seed: seedQ, ...rng }, genCounts));
});

// ── Seed score ─────────────────────────────────────────────────────────
// One 0-100 number combining the four headline metrics so the list can be ranked
// directly. 100 = many planets, a close naquium-primary field, plenty of water,
// few enemies. 0 = few planets, a distant (or missing) field, parched, hostile.
//
// Each metric is normalised against the MEASURED population — a 50k-seed scan,
// the same one the tail cutoffs were tuned from — rather than against whatever
// is on screen. Normalising against the visible rows would make one seed's score
// change depending on how the list happened to be filtered.
//
// Ranges are p1..p99 so a handful of outliers can't flatten everything else;
// anything beyond clamps to 0 or 1.
//
// naqdv is LOG-scaled. It is heavily right-skewed (p1 10.2k, median 29k, p99
// 102k, max 157k), so a linear map puts the median at 0.21 and squeezes half the
// population into the bottom fifth of the scale. On a log scale the median lands
// at 0.46, so the weight is spread across the range people actually care about.
//
// Weights: planet count 60%, naquium access 20% (split below), hostility 15%,
// water 5%.
//
// Naquium access is TWO metrics, not one, because the good and bad ends are
// different questions — the same reason seedgen tracks both:
//   naqdv — Δv to the nearest naquium-PRIMARY field. A rich source next door is
//           what makes a seed great.
//   fdv   — Δv to the nearest field of ANY kind. Every field yields some
//           naquium, so this is what makes a seed genuinely bad: not "the rich
//           field is far" but "even the closest field of any sort is far".
// Scoring naqdv alone punished the 10% of seeds with a distant naq-primary but
// a generic field nearby, where naquium is in fact perfectly reachable.
//
// The two are NOT independent weighted terms. As separate terms fdv would move
// the ranking everywhere, including among the best seeds, where it has no
// business: a seed with a mediocre naq-primary (32,030) but a generic field next
// door (14,984) rode into the top purely on the fdv term. The rule is one metric
// per END of the scale — naqdv ranks the good end, fdv ranks the bad end.
//
// Both share ONE absolute scale — 10,000 Δv scores 100%, 50,000 scores 0%,
// linear between, clamped outside. Per-metric p1..p99 bands made them
// incomparable: the same 11,000 Δv read as a good naq-primary but a mediocre
// any-field purely because the two distributions differ.
const DV_BEST = 10000;  // Δv at or below this scores 100%
const DV_WORST = 50000; // Δv at or above this scores 0%
const NAQ_ACCESS_W = 0.20;

const SCORE_METRICS = [
  { key: "np", w: 0.60, lo: 16, hi: 40, higherIsBetter: true },
  { key: "ef", w: 0.15, lo: 52, hi: 84, higherIsBetter: false }, // hostile%
  { key: "wp", w: 0.05, lo: 50, hi: 88, higherIsBetter: true },  // water% — more is wetter
];
const NO_NAQ_DV = 10000000; // seedgen's "no naquium-primary field" sentinel

// 0..1, or null when neither distance is known. `reach` is how close ANY field
// is (fdv); `rich` is how close a naquium-PRIMARY field is (naqdv). fdv <= naqdv
// always holds — a naq-primary field IS a field — so reach >= rich, always.
//
// The scale is split into two bands, one metric each, so neither metric can
// influence the other's end:
//
//   rich > 0  (a naq-primary field within DV_WORST)
//        -> upper band 0.5..1.0, position set by `rich` ALONE. fdv contributes
//           nothing, so the good end is ranked purely by naq-primary distance.
//   rich = 0  (naq-primary beyond DV_WORST, or none at all)
//        -> lower band 0.0..0.5, position set by `reach` ALONE. naqdv is already
//           pinned at its worst and contributes nothing, so the bad end is
//           ranked purely by any-field distance.
//
// Continuous across the join: both bands meet at 0.5, where a seed has no
// reachable rich field but a field right on its doorstep.
function naqAccess(s) {
  const g = (v) => (v == null ? null
    : 1 - Math.max(0, Math.min(1, (v - DV_BEST) / (DV_WORST - DV_BEST))));
  // The clamp absorbs the NO_NAQ_DV sentinel: "no naquium-primary field exists"
  // arrives as 10,000,000, lands past DV_WORST, and pins to 0.
  const rich = g(s.naqdv), reach = g(s.fdv);
  if (rich == null && reach == null) return null;
  if (rich == null) return 0.5 * reach; // no naqdv: can only judge reachability
  if (reach == null) return rich > 0 ? 0.5 + 0.5 * rich : 0;
  return rich > 0 ? 0.5 + 0.5 * rich : 0.5 * reach;
}

function seedScore(s) {
  let sum = 0, wsum = 0;
  for (const m of SCORE_METRICS) {
    const v = s[m.key];
    if (v == null) continue; // metric missing (seed predates it) — renormalise
                             // over the metrics this seed actually has
    const t = Math.max(0, Math.min(1, (v - m.lo) / (m.hi - m.lo)));
    sum += m.w * (m.higherIsBetter ? t : 1 - t);
    wsum += m.w;
  }
  const naq = naqAccess(s);
  if (naq != null) { sum += NAQ_ACCESS_W * naq; wsum += NAQ_ACCESS_W; }
  return wsum === 0 ? null : Math.round((100 * sum) / wsum);
}

function renderSeedsPage(seeds, defs, f, genCounts = {}) {
  const rules = f.def ? JSON.parse(f.def.rules) : [];
  const ruleStr = rules.map(analyze.ruleLabel).join(" AND ") || "no filter";
  // Default order = score descending. This has to happen HERE, before the
  // 500-row slice below: client-side sorting only reorders the rows already
  // rendered, so ranking by score in the browser alone would miss the best seed
  // in a bucket whenever it fell outside the first 500.
  // Scores are integers 0..100, so ties are common — generated-first and then
  // most-zones break them, which is the ordering this list used to default to.
  const gen = (s) => genCounts[s.seed] || 0;
  seeds = [...seeds].sort((a, b) => {
    // In count mode, rank by rule-match count first so the best partial
    // matches float to the top; otherwise rank by score.
    if (f.count && (b._matches || 0) !== (a._matches || 0)) return (b._matches || 0) - (a._matches || 0);
    const as = seedScore(a), bs = seedScore(b);
    if ((as ?? -1) !== (bs ?? -1)) return (bs ?? -1) - (as ?? -1);
    const ag = gen(a) > 0, bg = gen(b) > 0;
    if (ag !== bg) return ag ? -1 : 1;
    if (ag) return gen(b) - gen(a);
    return (b.zone_count || 0) - (a.zone_count || 0);
  });
  return `
  <div class="page">
    ${crumbs([{ label: "Buckets", href: "/universe" }, { label: `Seeds ${f.bucket || "(all)"}` }])}
    <h2>🌱 Rough-passed Seeds ${f.bucket ? `<span class="badge zone-type">${f.bucket}</span>` : ""}</h2>
    <div class="filter-bar">
      <form hx-post="/api/seed/generate" hx-target="#gen-seed-status" hx-swap="innerHTML" hx-disabled-elt="find button"
            title="Generate the full universe for any seed, whether or not it passed the rough filters. It lands in the 'manual' bucket and is then searchable here.">
        <label>Any seed: <input type="number" name="seed" min="0" step="1" placeholder="e.g. 123456" style="width:9em" required></label>
        <label title="Krastorio 2">K2 <input type="checkbox" name="k2"></label>
        <button type="submit" class="btn-sm">⚙ Generate</button>
      </form>
      <span id="gen-seed-status" class="hint"></span>
    </div>
    <div class="filter-bar">
      <form id="seed-filters" hx-get="/seeds" hx-target="closest .page" hx-swap="outerHTML">
        <input type="search" name="seed" value="${f.seed || ""}" placeholder="🔍 Seed #" style="width:9em"
               title="Find a seed by number. Exact if you type the whole number, otherwise a partial match. Searched in the database, so it finds seeds beyond the 2000 shown."
               hx-get="/seeds" hx-target="closest .page" hx-swap="outerHTML" hx-include="#seed-filters"
               hx-trigger="search, keyup changed delay:400ms">
        <select name="k2" title="Krastorio 2" hx-get="/seeds" hx-target="closest .page" hx-swap="outerHTML" hx-include="#seed-filters" hx-trigger="change">
          <option value="" ${f.k2 === "" ? "selected" : ""}>K2: any</option>
          <option value="1" ${f.k2 === "1" ? "selected" : ""}>K2 only</option>
          <option value="0" ${f.k2 === "0" ? "selected" : ""}>Vanilla only</option>
        </select>
        <label>Filter:
          <select name="def" hx-get="/seeds" hx-target="closest .page" hx-swap="outerHTML" hx-include="#seed-filters" hx-trigger="change">
            <option value="">— none —</option>
            ${defs.map(d => `<option value="${d.id}" ${f.defId === d.id ? "selected" : ""}>${d.name}${d.builtin ? "" : " *"}</option>`).join("")}
          </select></label>
        <label title="Rank seeds by how many rules they satisfy instead of requiring all (needs a filter selected)">
          <input type="checkbox" name="count" value="1" ${f.count ? "checked" : ""} ${f.defId ? "" : "disabled"}
            hx-get="/seeds" hx-target="closest .page" hx-swap="outerHTML" hx-include="#seed-filters" hx-trigger="change">
          count &amp; rank</label>
        <a href="/presets" hx-get="/presets" hx-target="#main" hx-push-url="true" class="btn-sm">⚙ manage presets</a>
      </form>
      <p class="hint">Filter: <strong>${ruleStr}</strong> — ${seeds.length} seed(s) match</p>
    </div>
    <table class="data-table" id="seeds-table">
      <thead><tr>
        <th class="sortable" data-key="seed" onclick="sortSeeds('seed')">Seed <span class="sort-ind"></span></th>
        <th>Bucket</th><th>K2</th><th>Loot</th>
        ${f.count ? `<th class="sortable" data-key="matches" onclick="sortSeeds('matches')" title="how many of the filter's ${f.ruleCount} rule(s) this seed satisfies">Matches <span class="sort-ind">▼</span></th>` : ""}
        <th class="sortable" data-key="npl" onclick="sortSeeds('npl')" title="Calidus system planets only (incl. Nauvis) — click for most (desc) / fewest (asc)">Planets <span class="sort-ind"></span></th>
        <th class="sortable" data-key="np" onclick="sortSeeds('np')" title="Calidus system planets + moons (incl. Nauvis) — click for most (desc) / fewest (asc)">P+M <span class="sort-ind"></span></th>
        <th class="sortable" data-key="naqdv" onclick="sortSeeds('naqdv')" title="Δv to nearest naquium-PRIMARY field — click for furthest (desc) / closest (asc)">Naq Δv <span class="sort-ind"></span></th>
        <th class="sortable" data-key="fdv" onclick="sortSeeds('fdv')" title="Δv to nearest ANY asteroid field (any field yields some naquium) — click for furthest (desc) / closest (asc)">Field Δv <span class="sort-ind"></span></th>
        <th class="sortable" data-key="ef" onclick="sortSeeds('ef')" title="share of Calidus planets+moons (excl. Nauvis) carrying enemies — click for most hostile (desc) / quietest (asc)">Hostile% <span class="sort-ind"></span></th>
        <th class="sortable" data-key="wp" onclick="sortSeeds('wp')" title="share of Calidus planets+moons (excl. Nauvis) that HAVE water — 0% = nowhere has water, 100% = everywhere does. Click for wettest (desc) / driest (asc)">Water% <span class="sort-ind"></span></th>
        <th class="sortable" data-key="score" onclick="sortSeeds('score')" title="0–100 overall desirability: most Calidus planets+moons (60%), naquium access (20% — half nearest naq-PRIMARY field, half nearest ANY field, since every field yields some naquium), fewest enemies (15%), most water (5%). Normalised against the measured 50k-seed population, so it means the same thing on every page. Click for best (desc) / worst (asc)">Score <span class="sort-ind">${f.count ? "" : "▼"}</span></th>
      </tr></thead>
      <tbody>
        ${seeds.slice(0, 500).map(s => {
          // No seedCriteria() here any more: the naq-primary field moved to the
          // seed detail page, and it was this list's only use of the parsed
          // criteria — so 500 rows no longer each pay a JSON.parse.
          const gen = genCounts[s.seed] || 0;
          const score = seedScore(s);
          return `
        <tr class="clickable" data-seed="${s.seed}" data-zones="${s.zone_count || 0}" data-gen="${gen}" data-matches="${s._matches || 0}" data-np="${s.np ?? 0}" data-npl="${s.npl ?? 0}" data-naqdv="${s.naqdv ?? 0}" data-fdv="${s.fdv ?? 0}" data-ef="${s.ef ?? 0}" data-wp="${s.wp ?? 0}" data-score="${score ?? 0}"
          hx-get="/seed/${s.seed}" hx-target="#main" hx-swap="innerHTML" hx-push-url="true" style="cursor:pointer">
          <td><strong>${s.seed}</strong></td><td>${s.bucket}</td><td>${s.k2 ? "✅" : "—"}</td><td><code>${s.loot}</code></td>
          ${f.count ? `<td><strong>${s._matches || 0}</strong>/${f.ruleCount}</td>` : ""}
          <td>${s.npl ?? "—"}</td>
          <td>${s.np ?? "—"}</td>
          <td>${s.naqdv == null ? "—" : (s.naqdv >= NO_NAQ_DV ? "none" : s.naqdv.toLocaleString())}</td>
          <td>${s.fdv == null ? "—" : (s.fdv >= NO_NAQ_DV ? "none" : s.fdv.toLocaleString())}</td>
          <td>${s.ef == null ? "—" : s.ef + "%"}</td>
          <td>${s.wp == null ? "—" : s.wp + "%"}</td>
          <td><strong>${score == null ? "—" : score}</strong></td>
        </tr>`;}).join("")}
        ${seeds.length === 0 ? `<tr><td colspan="${f.count ? 12 : 11}">No seeds match.</td></tr>` : ""}
      </tbody>
    </table>
    ${seeds.length > 500 ? `<p class="hint">Showing first 500 of ${seeds.length}.</p>` : ""}
    <script>
      (function () {
        // Matches the server pre-sort, so the arrow starts on the column the
        // rows are actually ordered by.
        var st = { key: "${f.count ? "matches" : "score"}", dir: "desc" };
        // DESCENDING comparators (first click). Zones desc: generated seeds
        // first (by most generated), then the rest (by most total zones).
        function baseCmp(key, a, b) {
          if (key === "zones") {
            var ag = +a.dataset.gen, bg = +b.dataset.gen;
            if ((ag > 0) !== (bg > 0)) return ag > 0 ? -1 : 1;
            if (ag > 0) return bg - ag;
            return (+b.dataset.zones) - (+a.dataset.zones);
          }
          return (+b.dataset[key] || 0) - (+a.dataset[key] || 0);
        }
        window.sortSeeds = function (key) {
          st.dir = (st.key === key && st.dir === "desc") ? "asc" : "desc"; // first click = desc
          st.key = key;
          var tb = document.querySelector("#seeds-table tbody");
          [].slice.call(tb.querySelectorAll("tr[data-seed]")).sort(function (a, b) {
            var cmp = baseCmp(key, a, b);
            return st.dir === "desc" ? cmp : -cmp;
          }).forEach(function (r) { tb.appendChild(r); });
          document.querySelectorAll("#seeds-table th.sortable .sort-ind").forEach(function (s) { s.textContent = ""; });
          var h = document.querySelector('#seeds-table th[data-key="' + key + '"] .sort-ind');
          if (h) h.textContent = st.dir === "desc" ? "▼" : "▲";
        };
      })();
    </script>
  </div>`;
}

// ── Seed detail — zones ────────────────────────────────────────────────

// Generatable zone types (surfaces). Others are shown for reference only.
const GEN_TYPES = ["planet", "moon", "asteroid-field"];

// Severity order of the water and enemy tags, matching data.zig's Water and
// Enemy enums. Tags are DISPLAYED by name; this is the numeric representation
// underneath, used only for sorting — an index into these arrays. Sorting the
// names as strings gives dictionary order (high < low < max < med < none),
// which looks random because it is.
//
// Declared here, server-side, and interpolated into the zone-table script below
// so the ordering is stated once rather than kept in step by hand.
const WATER_LEVELS = ["none", "low", "med", "high", "max"];
const ENEMY_LEVELS = ["none", "vlow", "low", "med", "high", "vhigh", "max"];

// Zone types omitted from the seed's zone TABLE only — a display filter. The
// zones themselves still load and reconcile normally; these rows just carry
// nothing actionable, since neither type is in GEN_TYPES: no checkbox, no
// surface link, no resources.
//   asteroid-belt — outnumbers the asteroid fields that do matter ~19:1.
//   anomaly       — Foenestra, the only anomaly the generator emits.
// Nothing selectable is lost: criteria never pick either (checked across every
// seed's selectedZones + naqField).
const HIDDEN_ZONE_TYPES = new Set(["asteroid-belt", "anomaly"]);

// Authoritative resource → oremap map_color (dumped live). Drives the surface
// viewer's per-resource show/hide toggles: the oremap paints each resource in
// its unique colour, so the browser can filter the composite by colour.
const ORE_COLORS = (() => {
  try {
    return JSON.parse(fs.readFileSync(path.join(__dirname, "..", "calibration", "mod-dump", "ore-colors.json"), "utf8"));
  } catch (_) { return {}; }
})();

app.get("/seed/:seed", (req, res) => {
  const s = db.getSeed(parseInt(req.params.seed));
  if (!s) return res.status(404).send(htmxPage("Not Found", "<h2>Seed not found</h2>"));
  // Bulk generation only stored the Calidus home system. Opening the detail page
  // kicks off a background job to fill in the rest of the universe (all star
  // systems + asteroid fields). The banner (renderSeedDetail) polls until done.
  if (!s.expanded) jobs.expandSeed(s.seed);
  const c = seedCriteria(s) || { selectedZones: [], specials: {}, pairs: {} };
  const filterId = req.query.filter || null;

  // Show ALL zones; criteria-relevant ones are pinned to the top and pre-checked.
  const sel = new Set([...(c.selectedZones || []), ...(c.naqField ? [c.naqField] : [])]);
  const zones = db.getZonesForSeed(s.seed).sort((a, b) => {
    const ra = sel.has(a.name) ? 0 : 1, rb = sel.has(b.name) ? 0 : 1;
    return ra - rb || (a.name || "").localeCompare(b.name || "");
  });

  // Reconcile the DB to the filesystem: if the user deleted a zone's output
  // folder to force a regenerate, drop its stale 'done' surface-job rows so the
  // zone reads as unpopulated (folder is the source of truth).
  for (const z of zones)
    jobs.reconcileZoneSurfaces(z.id, path.join(jobs.seedDir(s.bucket, s.seed), z.name));

  // zones.jsonl always carries the criteria-relevant zones for the generator.
  try { jobs.writeSeedZonesFile(s, null); }
  catch (e) { console.error("writeSeedZonesFile:", e.message); }

  page(req, res, `Seed ${s.seed}`, renderSeedDetail(s, c, zones, filterId, req.query.all === "1"));
});

// Poll target for the "generating full universe" banner. While expanding it
// returns the spinner (keep polling); once the seed is expanded it returns a
// done chip with HTTP 286 (stops the poll) that reloads the detail once so the
// newly-ingested zones appear — a single swap, not incremental.
app.get("/api/seed/:seed/expand", (req, res) => {
  const seed = parseInt(req.params.seed);
  const s = db.getSeed(seed);
  if (!s) return res.status(404).send("");
  if (s.expanded) {
    return res.status(286).send(
      `<span class="expand-done" hx-get="/seed/${seed}" hx-trigger="load" hx-target="#main" hx-swap="innerHTML">✅ Full universe loaded (${s.zone_count} zones)</span>`);
  }
  if (!jobs.isExpanding(seed)) jobs.expandSeed(seed); // resume if it was dropped
  res.send(`<span class="hint">⏳ Generating the full universe (all star systems + asteroid fields)…</span>`);
});

// Lowercase "name type resource…" haystack for the client-side zone search.
function zoneSearchText(bucket, seed, zone) {
  const nm = (r) => r.replace("se-", "").replace("kr-", "").replace("-ore", "");
  const parts = [zone.name, zone.zone_type];
  const summary = zoneSurfaceSummary(bucket, seed, zone.name);
  if (summary) parts.push(...Object.keys(summary.resources || {}).map(nm));
  else { try { parts.push(...Object.keys(JSON.parse(zone.resource_yields || "{}")).map(nm)); } catch (_) {} }
  if (zone.primary_resource) parts.push(nm(zone.primary_resource));
  return parts.join(" ").toLowerCase().replace(/"/g, "");
}

function renderSeedDetail(s, c, zones, filterId, showAllSystems = false) {
  const back = { label: "Seeds", href: `/seeds?bucket=${s.bucket}` };
  const reload = `/seed/${s.seed}`;
  // The naquium-primary field is already IN `sel`, so it is pinned to the top and
  // pre-checked like any criteria zone. It is called out separately below because
  // being merely starred gave no way to tell it apart from the others.
  const naq = c.naqField || null;
  const sel = new Set([...(c.selectedZones || []), ...(naq ? [naq] : [])]);
  const th = (label, key) => `<th class="sortable" data-key="${key}" onclick="sortZones('${key}')">${label} <span class="sort-ind"></span></th>`;
  // Display filter only — `zones` stays whole for the caller (reconcile, etc.).
  //
  // Once a seed is expanded, ~95% of its zones belong to OTHER star systems
  // (measured: 616 of 652 for one seed), which buries the home system you
  // actually play in. So by default only Calidus planets and moons are listed.
  //
  // Asteroid fields are ALWAYS kept regardless of system — every field orbits
  // another star, including the naquium-primary one, so filtering them by
  // Calidus membership would remove all of them, the naq field included.
  //
  // in_calidus is NULL for rows ingested before seedgen emitted the flag; NULL
  // is treated as "show" so old data never silently vanishes.
  const KEEP_ANY_SYSTEM = new Set(["asteroid-field"]);
  const rows = zones.filter(z => {
    if (HIDDEN_ZONE_TYPES.has(z.zone_type)) return false;
    if (showAllSystems || KEEP_ANY_SYSTEM.has(z.zone_type)) return true;
    return z.in_calidus !== 0;
  });
  const hiddenBySystem = zones.filter(z =>
    !HIDDEN_ZONE_TYPES.has(z.zone_type) && !KEEP_ANY_SYSTEM.has(z.zone_type) && z.in_calidus === 0).length;

  return `
  <div class="page">
    ${crumbs([{ label: "Buckets", href: "/universe" }, back, { label: `Seed ${s.seed}` }])}
    <h2>🌱 Seed ${s.seed} <span class="badge zone-type">${s.bucket}</span> <code>${s.loot}</code>
      ${naq ? `<span class="badge zone-type" title="nearest asteroid field whose PRIMARY yield is naquium — pinned to the top of the table and pre-selected${s.naqdv != null && s.naqdv < 10000000 ? `, Δv ${s.naqdv.toLocaleString()}` : ""}">☄ naq: ${naq}</span>` : `<span class="hint" title="no asteroid field in this universe has naquium as its primary yield">☄ no naq-primary field</span>`}</h2>
    ${s.expanded ? "" : `<div id="expand-wrap" class="expand-banner" hx-get="/api/seed/${s.seed}/expand" hx-trigger="load delay:800ms, every 2s" hx-target="#expand-wrap" hx-swap="innerHTML"><span class="hint">⏳ Generating the full universe (all star systems + asteroid fields)…</span></div>`}
    <div class="filter-bar">
      <input type="text" id="zone-search" placeholder="🔍 Search name or resource…" oninput="filterZones()" autocomplete="off">
      ${maxRadiusInput()}
      <label class="hint" title="Off: only Calidus planets and moons, plus every asteroid field (fields all orbit other stars, including the naq-primary one). On: also list planets and moons from every other star system.">
        <input type="checkbox" ${showAllSystems ? "checked" : ""}
               hx-get="/seed/${s.seed}${showAllSystems ? "" : "?all=1"}" hx-target="#main" hx-swap="innerHTML" hx-push-url="true">
        Other star systems${hiddenBySystem && !showAllSystems ? ` <strong>(${hiddenBySystem} hidden)</strong>` : ""}
      </label>
      <span class="hint">Asteroid belts and anomalies hidden (nothing generatable); selected zones are pinned to the top (⭐ = criteria-relevant, ☄ = naquium-primary field — both pre-selected). Click a header to sort.</span>
    </div>
    <form id="zone-batch">
      <input type="hidden" name="seed" value="${s.seed}">
      <div class="batch-actions">
        <button type="button" class="btn"
          hx-post="/api/surface/batch?kind=oremap" hx-include="#zone-batch input[name=seed], #zone-batch input[name=zone]:checked" hx-swap="none"
          hx-disabled-elt="this" hx-on::after-request="htmx.ajax('GET','${reload}',{target:'#main'})">
          ⛏ Generate ore maps — selected zones
        </button>
        <button type="button" class="btn btn-secondary"
          hx-post="/api/surface/batch?kind=gputerrain" hx-include="#zone-batch input[name=seed], #zone-batch input[name=zone]:checked" hx-swap="none"
          hx-disabled-elt="this" hx-on::after-request="htmx.ajax('GET','${reload}',{target:'#main'})">
          🗺️ Generate surfaces — selected zones
        </button>
      </div>
      <table class="data-table" id="zone-table">
        <thead><tr>
          <th><input type="checkbox" onclick="selectAllVisible(this)"></th>
          ${th("Zone", "zone")}${th("Type", "type")}${th("Radius", "radius")}${th("Δv", "dv")}${th("Water", "water")}${th("Enemy", "enemy")}
          <th>★</th>
          <th>Resources <small>(measured if generated, else est.)</small></th><th></th>
        </tr></thead>
        <tbody>
          ${rows.map(z => {
            const relevant = sel.has(z.name);
            const gen = GEN_TYPES.includes(z.zone_type);
            const water = (z.water || "none").replace(/^water[_-]?/, "") || "none";
            const enemy = (z.enemy || "none").replace(/^enemy[_-]?/, "").replace("very_", "v") || "none";
            const data = `data-zone="${(z.name || "").replace(/"/g, "")}" data-type="${z.zone_type}" data-radius="${z.radius || 0}" data-dv="${z.delta_v || 0}" data-water="${water}" data-enemy="${enemy}" data-relevant="${relevant ? 1 : 0}" data-search="${zoneSearchText(s.bucket, s.seed, z)}"`;
            // generatable rows navigate to the surface detail on click via native
            // htmx (hx-push-url snapshots history so Chrome's Back restores the seed
            // page instantly); the trigger filter ignores clicks on buttons/inputs so
            // those keep working normally.
            const nav = gen
              ? `hx-get="/seed/${s.seed}/surface/${z.id}" hx-target="#main" hx-swap="innerHTML" hx-push-url="true" hx-trigger="click[shouldNav(event)]" hx-sync="#main:replace" hx-disinherit="*" style="cursor:pointer"`
              : "";
            return `
          <tr class="${gen ? "clickable" : "zone-info"}" ${data} ${nav}>
            <td>${gen ? `<input type="checkbox" name="zone" value="${z.name}" ${relevant ? "checked" : ""}>` : ""}</td>
            <td><strong>${z.name}</strong></td>
            <td><span class="badge zone-type">${z.zone_type}</span></td>
            <td>${z.radius ? Math.round(z.radius) : "—"}</td>
            <td class="num">${z.delta_v ? Math.round(z.delta_v) : "—"}</td>
            <td>${water}</td>
            <td>${enemy}</td>
            <td>${z.name === naq ? `<span title="naquium-primary asteroid field">☄</span>` : relevant ? "⭐" : ""}</td>
            <td class="yields-cell"><div id="zres-${z.id}">${renderZoneResources(s.bucket, s.seed, z)}</div></td>
            ${gen ? renderZoneCell(s.bucket, s.seed, z) : `<td class="row-actions muted">—</td>`}
          </tr>`;}).join("")}
          ${rows.length === 0 ? `<tr><td colspan="10">No zones.</td></tr>` : ""}
        </tbody>
      </table>
    </form>
    <script>
      (function () {
        var sortState = { key: "dv", dir: "asc" }; // default: sort by Δv ascending
        var NUMERIC = { radius: 1, dv: 1 };
        // Columns that mean nothing for an asteroid field. seedgen emits water
        // and enemy tags for fields as well as planets/moons — they come out of
        // the same tag draw — but a field has no surface, so no lakes and no
        // biters. Sorting on them would interleave fields among real results on
        // the strength of a meaningless value, so fields sink to the bottom in
        // BOTH directions instead of taking part.
        var TAGLESS_FOR_FIELDS = { water: 1, enemy: 1 };
        function isField(r) { return r.dataset.type === "asteroid-field" ? 1 : 0; }
        // Water and enemy display as tag NAMES but sort by severity. The rank is
        // the tag's index in these arrays (see WATER_LEVELS / ENEMY_LEVELS in
        // server.js — interpolated so the order is defined in one place).
        var ORDINAL = {
          water: ${JSON.stringify(WATER_LEVELS)},
          enemy: ${JSON.stringify(ENEMY_LEVELS)},
        };
        function rank(key, v) {
          var levels = ORDINAL[key];
          var i = levels.indexOf(v);
          // The DB stores very_low/very_high; the cell renders vlow/vhigh.
          if (i < 0) i = levels.indexOf(String(v).replace("very_", "v"));
          return i; // -1 for unknown/missing, which sorts below "none"
        }
        function isSel(r) {
          var cb = r.querySelector('input[type=checkbox][name=zone]');
          return cb && cb.checked ? 1 : 0;
        }
        // Re-order rows: selected (checked) zones pinned to the top, then the
        // active sort key. Runs on load, on sort, and whenever a checkbox toggles,
        // so manually-selected zones jump up beside the criteria-relevant ones.
        function reflow() {
          var tb = document.querySelector("#zone-table tbody");
          if (!tb) return;
          var rows = [].slice.call(tb.querySelectorAll("tr[data-zone]"));
          var key = sortState.key;
          rows.sort(function (a, b) {
            var ra = isSel(a), rb = isSel(b);
            if (ra !== rb) return rb - ra;            // selected pinned to top
            if (!key) return 0;                        // else keep DOM order (stable sort)
            if (TAGLESS_FOR_FIELDS[key]) {             // fields last, either direction
              var fa = isField(a), fb = isField(b);
              if (fa !== fb) return fa - fb;
              if (fa) return 0;                        // field vs field: leave as-is
            }
            var va = a.dataset[key], vb = b.dataset[key], cmp;
            if (NUMERIC[key]) cmp = (parseFloat(va) || 0) - (parseFloat(vb) || 0);
            else if (ORDINAL[key]) cmp = rank(key, va) - rank(key, vb);
            else cmp = String(va).localeCompare(String(vb));
            return sortState.dir === "asc" ? cmp : -cmp;
          });
          rows.forEach(function (r) { tb.appendChild(r); });
        }
        window.reflowZones = reflow;
        window.sortZones = function (key) {
          sortState.dir = (sortState.key === key && sortState.dir === "asc") ? "desc" : "asc";
          sortState.key = key;
          reflow();
          document.querySelectorAll("#zone-table th.sortable .sort-ind").forEach(function (s) { s.textContent = ""; });
          var thh = document.querySelector('#zone-table th[data-key="' + key + '"] .sort-ind');
          if (thh) thh.textContent = sortState.dir === "asc" ? "▲" : "▼";
        };
        // Re-pin whenever a zone checkbox toggles (delegated; survives htmx swaps).
        document.addEventListener("change", function (e) {
          if (e.target && e.target.matches && e.target.matches('#zone-table input[type=checkbox][name=zone]')) reflow();
        });
        reflow();  // default Δv-ascending sort (selected zones still pinned on top)
        (function () {
          var ind = document.querySelector('#zone-table th[data-key="dv"] .sort-ind');
          if (ind) ind.textContent = "▲";
        })();
        window.filterZones = function () {
          var q = (document.getElementById("zone-search").value || "").trim().toLowerCase();
          document.querySelectorAll("#zone-table tbody tr[data-zone]").forEach(function (r) {
            r.style.display = (!q || (r.dataset.search || "").indexOf(q) !== -1) ? "" : "none";
          });
        };
        window.selectAllVisible = function (master) {
          document.querySelectorAll("#zone-table tbody tr[data-zone]").forEach(function (r) {
            if (r.style.display === "none") return;
            var cb = r.querySelector('input[name=zone]');
            if (cb) cb.checked = master.checked;
          });
          if (window.reflowZones) window.reflowZones();  // re-pin the new selection
        };
        // Row click → surface detail, unless the click was on an interactive
        // control (button/input/link) — those keep their own behaviour.
        // htmx trigger filter: only let a row's hx-get fire when the click didn't
        // land on an interactive control. htmx handles the history push itself.
        window.shouldNav = function (e) {
          return !e.target.closest("button, input, a, select, label");
        };
      })();
    </script>
  </div>`;
}

// ── Live surface watch (tiled grid) ────────────────────────────────────

function zoneCellPng(bucket, seed, zoneName, n, cell, prefix = "surface") {
  const file = n > 1 ? `${prefix}_${n}_${cell}.png` : `${prefix}.png`;
  const rel = path.join(bucket, `seed_${seed}`, zoneName, file);
  try {
    // ?t=mtime busts the browser cache when a layer is regenerated (e.g. an old
    // opaque ore map replaced by the new transparent one).
    const t = Math.round(fs.statSync(path.join(jobs.OUTPUT_DIR, rel)).mtimeMs);
    return `/output/${rel}?t=${t}`;
  } catch (_) { return null; }
}

// Build the layered surface view (terrain dimmed + ore bright) as { grid, head }.
// The terrain layer carries CSS brightness(--terr-b); the ore layer composites
// with mix-blend-mode: lighten so its patches pop over the dimmed terrain.
function buildSurfaceGrid(seed, zoneId) {
  const zone = db.getZonesForSeed(seed).find(z => z.id === zoneId);
  if (!zone) return { grid: `<div class="surf-grid-wrap" id="surfgrid-${zoneId}"><p class="hint">Zone not found.</p></div>`, head: "" };
  const bucket = (db.getSeed(seed) || {}).bucket || zone.bucket;
  const radius = effRadius(zone);
  const { n, cells } = jobs.surfaceCellLayout(radius);
  const cp = (nn, cell, prefix) => zoneCellPng(bucket, seed, zone.name, nn, cell, prefix);

  const allJobs = db.getSurfaceJobsForZone(zoneId);
  const grp = (k) => allJobs.filter(j => j.kind === k);
  const active = (k) => grp(k).some(j => j.status === "queued" || j.status === "running");
  const anyActive = active("terrain") || active("gputerrain") || active("oremap") || active("surface") || active("ore") || active("oredump") || active("gpuoremap");
  // Poll a STABLE wrapper that swaps its own inner content (hx-swap=innerHTML,
  // hx-target=this) rather than replacing the polling element — a self-replacing
  // `every` poll can drop its timer, so the final swap (cells → stitched image)
  // never fires. The /api/surface/grid endpoint returns HTTP 286 once nothing is
  // active, which applies the last swap (the stitched image) and stops the poll.
  const poll = anyActive ? `hx-get="/api/surface/grid?seed=${seed}&zone_id=${zoneId}" hx-trigger="every 1500ms" hx-target="this" hx-swap="innerHTML" hx-sync="this:drop"` : "";

  const terrainFull = cp(1, 0, "terrain");   // stitched (n>1) or whole (n<=1)
  const legacy = cp(1, 0, "surface");        // old combined image
  const cellStyle = (c) => `left:${c.leftPct}%;top:${c.topPct}%;width:${c.wPct}%;height:${c.hPct}%`;

  // Each layer renders independently: its stitched/whole image if present, else
  // its live per-cell grid (so terrain cells still fill in under the ore layer).
  const layer = (prefix, cls, kind) => {
    const full = cp(1, 0, prefix);
    if (full) return `<img class="layer ${cls}" loading="lazy" src="${full}" alt="">`;
    if (n <= 1) return "";
    // Cells a worker is actively rendering right now (status="running"); queued
    // cells show nothing until they're picked up.
    const runningCells = new Set(grp(kind).filter(j => j.status === "running").map(j => j.grid_cell));
    const cellDivs = cells.map(c => {
      const png = cp(n, c.cell, prefix);
      if (png) return `<div class="surf-cell done" style="${cellStyle(c)}"><img loading="lazy" src="${png}" alt=""></div>`;
      // show the hourglass only on the terrain layer (the ore layer's gaps are
      // transparent) and only while that cell is actually being generated.
      if (cls === "terrain" && runningCells.has(c.cell)) return `<div class="surf-cell running" style="${cellStyle(c)}"><span>⏳</span></div>`;
      return "";
    }).join("");
    return cellDivs ? `<div class="layer ${cls} cell-layer">${cellDivs}</div>` : "";
  };

  const terrainLayer = layer("terrain", "terrain", "terrain");
  const oreLayer = layer("oremap", "ore", "oremap");

  let body;
  if (terrainLayer || oreLayer) {
    body = `<div class="surf-grid layered">${terrainLayer}${oreLayer}</div>`;
  } else if (legacy) {
    body = `<div class="surf-grid"><img class="surf-full" src="${legacy}" alt="${zone.name}"></div>`;
  } else {
    body = `<div class="surf-grid"><p class="hint" style="padding:20px">Not generated yet — use the buttons.</p></div>`;
  }

  // status head: per-layer done counts
  const cnt = (...ks) => { const g = ks.flatMap(grp); return { done: g.filter(j => j.status === "done").length, tot: g.length, fail: g.filter(j => j.status === "failed").length }; };
  const t = cnt("terrain", "gputerrain"), o = cnt("oremap", "gpuoremap", "oredump"), s = cnt("surface");
  const line = (label, c) => c.tot ? `${label} <span class="gen-status ${c.done + c.fail >= c.tot ? "" : "running"}">${c.fail ? "⚠️" : (c.done >= c.tot ? "✅" : "⏳")} ${c.done}/${c.tot}</span>` : "";
  const head = [line("terrain", t), line("ore", o), line("surface", s)].filter(Boolean).join(" · ") +
    (terrainFull ? ` <a class="btn-sm" href="${terrainFull}" target="_blank" title="terrain">⤢</a>` : "");

  const grid = `<div class="surf-grid-wrap" id="surfgrid-${zoneId}" ${poll}>${body}</div>`;
  return { grid, body, head, active: anyActive };
}

// Poll target for the live grid: swaps the wrapper's inner content + OOB-updates
// the panel status. Returns HTTP 286 once nothing is active so htmx applies the
// final swap (the stitched image, once cells are stitched+deleted) and stops.
app.get("/api/surface/grid", (req, res) => {
  const seed = parseInt(req.query.seed);
  const zoneId = parseInt(req.query.zone_id);
  const g = buildSurfaceGrid(seed, zoneId);
  // Once done, OOB-refresh the sidebar ore legend too (estimate → measured
  // table). Only on completion, so mid-generation polls don't reset checkboxes.
  const legend = g.active ? "" : renderOreLegend(seed, zoneId, true);
  if (!g.active) res.status(286);
  return res.send(`${g.body}<div id="gridstatus-${zoneId}" class="grid-status" hx-swap-oob="true">${g.head}</div>${legend}`);
});

// The sidebar ore legend: the per-resource show/hide table (checkbox + colour +
// amounts) once ore is measured, else the estimate. Rendered in the surface page
// and OOB-swapped by the grid poll on completion so it switches from estimate →
// measured without a full refresh. Pass oob=true to emit it as an OOB update.
function renderOreLegend(seed, zoneId, oob = false) {
  const s = db.getSeed(seed);
  const zone = s && db.getZonesForSeed(seed).find(z => z.id === zoneId);
  const wrap = (inner) => `<div id="orelegend-${zoneId}"${oob ? ' hx-swap-oob="true"' : ""}>${inner}</div>`;
  if (!zone) return wrap("");
  const nm = (r) => r.replace("se-", "").replace("kr-", "").replace("-ore", "");
  const summary = zoneSurfaceSummary(s.bucket, seed, zone.name);
  const swatch = (r) => { const c = ORE_COLORS[r]; return c ? `<span class="ore-swatch" style="background:rgb(${c[0]},${c[1]},${c[2]})"></span>` : `<span class="ore-swatch" style="background:transparent"></span>`; };
  const oreBlock = summary
    ? `<table class="data-table compact ore-legend"><thead><tr><th title="show/hide on the surface">👁</th><th>Resource</th><th>Ore</th><th>Tiles</th></tr></thead><tbody>
        ${Object.entries(summary.resources || {}).sort((a, b) => (b[1].amount || 0) - (a[1].amount || 0))
          .map(([r, v]) => `<tr><td><input type="checkbox" class="ore-toggle" data-res="${r}" checked></td><td>${swatch(r)}${nm(r)}</td><td class="num"><strong>${v.display || fmtAmount(v.amount)}</strong></td><td class="num">${v.tiles || 0}</td></tr>`).join("")}
      </tbody></table>
      <div class="ore-toggle-actions"><button type="button" class="btn-sm" onclick="oreToggleAll(true)">show all</button> <button type="button" class="btn-sm" onclick="oreToggleAll(false)">hide all</button></div>`
    : `<p class="hint">Ore not generated yet — estimates:</p><div class="yields-cell">${renderZoneResources(s.bucket, seed, zone)}</div>`;
  return wrap(`<h3>Ore ${summary ? "<span class='badge done'>measured</span>" : "<span class='badge'>estimate</span>"}</h3>${oreBlock}`);
}

// Full surface detail page (breadcrumb + embedded live grid) — nested under the
// seed. The old /surface/watch?seed&zone_id form redirects here.
app.get("/surface/watch", (req, res) =>
  res.redirect(`/seed/${parseInt(req.query.seed)}/surface/${parseInt(req.query.zone_id)}`));
app.get("/seed/:seed/surface/:zoneId", (req, res) => {
  const seed = parseInt(req.params.seed);
  const zoneId = parseInt(req.params.zoneId);
  const s = db.getSeed(seed);
  const zone = db.getZonesForSeed(seed).find(z => z.id === zoneId);
  if (!s || !zone) return page(req, res, "Watch", `<div class="page"><p class="hint">Seed or zone not found.</p></div>`);

  // Folder-is-truth: drop stale 'done' rows if this zone's output was deleted.
  jobs.reconcileZoneSurfaces(zoneId, path.join(jobs.seedDir(s.bucket, seed), zone.name));

  const nm = (r) => r.replace("se-", "").replace("kr-", "").replace("-ore", "");
  const water = (zone.water || "none").replace(/^water[_-]?/, "") || "none";
  const enemy = (zone.enemy || "none").replace(/^enemy[_-]?/, "").replace("very_", "v") || "none";
  const genArgs = `hx-vals='${JSON.stringify({ zone_id: zoneId, seed, zone_name: zone.name, radius: effRadius(zone) })}'`;
  const reload = `hx-on::after-request="htmx.ajax('GET','/seed/${seed}/surface/${zoneId}',{target:'#main'})"`;
  const g = buildSurfaceGrid(seed, zoneId);

  const content = `
  <div class="page">
    ${crumbs([{ label: "Buckets", href: "/universe" }, { label: `Seed ${seed}`, href: `/seed/${seed}` }, { label: zone.name }])}
    <h2><strong>${zone.name}</strong> <span class="badge zone-type">${zone.zone_type}</span> ${maxRadiusInput()}</h2>
    <div class="watch-layout">
      <aside class="surface-meta">
        <h3>Zone</h3>
        <dl>
          <dt>Radius</dt><dd>${zone.radius ? Math.round(zone.radius) : "—"}${effRadius(zone) < Math.round(zone.radius || Infinity) ? ` → <strong>${effRadius(zone)}</strong> (capped)` : ""}</dd>
          <dt>Δv</dt><dd>${zone.delta_v ? Math.round(zone.delta_v) : "—"}</dd>
          <dt>Water</dt><dd>${water}</dd>
          <dt>Enemy</dt><dd>${enemy}</dd>
          <dt>Primary</dt><dd>${zone.primary_resource ? nm(zone.primary_resource) : "—"}</dd>
        </dl>
        ${renderOreLegend(seed, zoneId)}
        <h3>Surface</h3>
        <div id="gridstatus-${zoneId}" class="grid-status">${g.head}</div>
        <label class="dim-slider">Terrain brightness
          <input type="range" min="0" max="100" value="45" oninput="setTerrB(this.value)">
        </label>
        <div class="preset-actions">
          <button type="button" class="btn-sm" hx-post="/api/surface/create?kind=oremap" ${genArgs} hx-swap="none" ${reload} title="ore patches">⛏ ore</button>
          <button type="button" class="btn-sm btn-secondary" hx-post="/api/surface/create?kind=gputerrain" ${genArgs} hx-swap="none" ${reload} title="biome + water">🗺️ surface</button>
        </div>
      </aside>
      <div class="watch-grid-col">${g.grid}</div>
    </div>
    <script>
      window.setTerrB = function (v) {
        document.querySelectorAll(".surf-grid").forEach(function (el) { el.style.setProperty("--terr-b", v / 100); });
      };
      setTerrB(document.querySelector(".dim-slider input") ? document.querySelector(".dim-slider input").value : 45);

      // Per-resource ore show/hide. By DEFAULT the plain stitched ore image is
      // shown (so it refreshes exactly like the terrain layer — no canvas in the
      // way). Only when the user hides a resource do we composite the image into
      // a canvas and drop that resource's pixels; unhiding everything removes the
      // canvas and restores the plain image.
      (function () {
        var ORE_COLORS = ${JSON.stringify(ORE_COLORS)};
        var ORE_DIM = ${effRadius(zone) * 2};
        var colorRes = {};
        for (var r in ORE_COLORS) { var c = ORE_COLORS[r]; colorRes[(c[0] << 16) | (c[1] << 8) | c[2]] = r; }
        var masterData = null, canvas = null;
        function toggles() { return document.querySelectorAll(".ore-toggle"); }
        function active() { var s = {}; toggles().forEach(function (cb) { if (cb.checked) s[cb.dataset.res] = 1; }); return s; }
        function allChecked() { var all = true; toggles().forEach(function (cb) { if (!cb.checked) all = false; }); return all; }
        function oreImg() {
          var g = document.querySelector(".surf-grid.layered"); if (!g) return null;
          var l = g.querySelector(".layer.ore:not(.ore-filter)");
          if (!l || l.querySelector(".surf-cell")) return null; // still tiling — leave cells alone
          return l.tagName === "IMG" ? l : l.querySelector("img");
        }
        function removeFilter() {
          if (canvas && canvas.parentElement) canvas.parentElement.removeChild(canvas);
          canvas = null; masterData = null;
          var img = oreImg(); if (img) img.style.display = "";
        }
        function apply() {
          if (allChecked()) { removeFilter(); return; } // nothing hidden → plain image
          var img = oreImg(); if (!img) return;
          if (!img.complete || !img.naturalWidth) { img.addEventListener("load", apply, { once: true }); return; }
          var grid = img.closest(".surf-grid.layered");
          var dim = img.naturalWidth || ORE_DIM || 800;
          if (!masterData) {
            var master = document.createElement("canvas"); master.width = dim; master.height = dim;
            var mc = master.getContext("2d"); mc.imageSmoothingEnabled = false;
            mc.drawImage(img, 0, 0, dim, dim);
            try { masterData = mc.getImageData(0, 0, dim, dim); } catch (e) { return; }
          }
          if (!canvas) {
            canvas = document.createElement("canvas"); canvas.className = "layer ore ore-filter";
            canvas.style.width = "100%"; canvas.style.height = "100%"; canvas.width = dim; canvas.height = dim;
          }
          var act = active(), src = masterData.data, ctx = canvas.getContext("2d");
          var out = ctx.createImageData(masterData.width, masterData.height), d = out.data;
          for (var i = 0; i < src.length; i += 4) {
            if (src[i + 3] === 0) { d[i + 3] = 0; continue; }
            var res = colorRes[(src[i] << 16) | (src[i + 1] << 8) | src[i + 2]];
            if (res && !act[res]) { d[i + 3] = 0; continue; }
            d[i] = src[i]; d[i + 1] = src[i + 1]; d[i + 2] = src[i + 2]; d[i + 3] = src[i + 3];
          }
          ctx.putImageData(out, 0, 0);
          img.style.display = "none";
          if (canvas.parentElement !== grid) grid.appendChild(canvas);
        }
        window.oreToggleAll = function (on) { toggles().forEach(function (cb) { cb.checked = on; }); apply(); };
        document.addEventListener("change", function (e) { if (e.target && e.target.classList && e.target.classList.contains("ore-toggle")) apply(); });
        // Every grid swap (poll / completion refresh) yields a fresh image — drop
        // the stale canvas refs and re-apply the filter only if one is currently
        // active, so by default the plain stitched image shows straight away.
        document.body.addEventListener("htmx:afterSettle", function () {
          masterData = null; canvas = null;
          if (!allChecked()) setTimeout(apply, 30);
        });
      })();
    </script>
  </div>`;
  page(req, res, zone.name, content);
});

// ── Surface jobs + viewer ──────────────────────────────────────────────

app.get("/surfaces", (req, res) => page(req, res, "Surface Jobs", renderSurfaceJobsPage(db.getAllSurfaceJobs())));

function renderSurfaceJobsPage(jobsList) {
  // group all jobs by (seed, zone) = one surface
  const groups = new Map();
  for (const j of jobsList) {
    const key = `${j.seed} ${j.zone_name}`;
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(j);
  }
  const isActive = (j) => j.status === "queued" || j.status === "running";
  const anyActive = jobsList.some(isActive);

  const arr = [...groups.values()].map((js) => {
    const c = { queued: 0, running: 0, done: 0, failed: 0, cancelled: 0 };
    for (const j of js) c[j.status] = (c[j.status] || 0) + 1;
    return { js, c, active: js.some(isActive), created: js[0].created_at || "" };
  });
  // active surfaces first, then most recent
  arr.sort((a, b) => (b.active - a.active) || b.created.localeCompare(a.created));

  const groupRow = (g) => {
    const js = g.js, c = g.c, first = js[0];
    const total = js.length;
    const status = c.failed ? `⚠️ ${c.done}/${total} · ${c.failed} failed`
      : (c.cancelled && !g.active) ? `⊘ ${c.done}/${total} · ${c.cancelled} cancelled`
        : g.active ? `⏳ ${c.done}/${total}` : `✅ ${c.done}/${total}`;
    const cls = c.failed ? "failed" : g.active ? "running" : (c.cancelled && !c.done) ? "cancelled" : "done";
    const gid = `grp-${first.seed}-${(first.zone_name || "").replace(/[^a-z0-9]/gi, "-")}`;
    const watch = first.zone_id
      ? `<a class="btn-sm" href="/seed/${first.seed}/surface/${first.zone_id}" hx-get="/seed/${first.seed}/surface/${first.zone_id}" hx-target="#main" hx-push-url="true" title="watch grid">👁</a>`
      : "";
    return `<details class="surf-group" id="${gid}">
      <summary>
        <span class="preset-name">${first.zone_name}</span>
        <a href="/seed/${first.seed}" hx-get="/seed/${first.seed}" hx-target="#main" hx-push-url="true" class="badge zone-type">seed ${first.seed}</a>
        <span class="badge">${first.bucket || "—"}</span>
        <span class="job-count">${total} job${total === 1 ? "" : "s"}</span>
        <span class="gen-status ${g.active ? "running" : ""}" style="margin-left:auto">${status}</span>
        ${watch}
      </summary>
      <div class="preset-body">
        <table class="data-table compact">
          <thead><tr><th>ID</th><th>Kind</th><th>Cell</th><th>Status</th><th>Created</th><th></th></tr></thead>
          <tbody>
            ${js.map(j => `<tr class="row-${j.status}">
              <td>${j.id}</td>
              <td><span class="badge">${j.kind || "ore"}</span></td>
              <td>${j.kind === "surface" && j.grid_cell >= 0 ? `${j.grid_cell}/${j.grid_n * j.grid_n}` : "—"}</td>
              <td><span class="badge ${j.status}">${j.status}</span></td>
              <td>${j.created_at}</td>
              <td>${j.status === "done" && j.kind !== "ore" && j.zone_id ? `<a href="/seed/${j.seed}/surface/${j.zone_id}" hx-get="/seed/${j.seed}/surface/${j.zone_id}" hx-target="#main" hx-push-url="true" class="btn-sm">🖼️</a>` : ""}</td>
            </tr>`).join("")}
          </tbody>
        </table>
      </div>
    </details>`;
  };

  return `
  <div class="page" ${anyActive ? `hx-get="/surfaces" hx-trigger="every 3s" hx-swap="outerHTML" hx-sync="#main:drop"` : ""}>
    <div class="page-head">
      <h2>🗺️ Surface Jobs <span class="hint">${arr.length} surface${arr.length === 1 ? "" : "s"}, ${jobsList.length} job${jobsList.length === 1 ? "" : "s"}</span></h2>
      <button type="button" class="btn danger" hx-post="/api/jobs/cancel-all" hx-swap="none"
        hx-confirm="Cancel ALL queued and running jobs (universe + surface) and kill their processes?"
        hx-on::after-request="htmx.ajax('GET','/surfaces',{target:'#main'})">
        ✖ Cancel all jobs
      </button>
    </div>
    <div class="preset-list">
      ${arr.map(groupRow).join("")}
      ${arr.length === 0 ? `<p class="hint">No surface jobs yet.</p>` : ""}
    </div>
    <script>
      (function () {
        var KEY = "surfOpenGroups";
        function save() {
          var open = [].slice.call(document.querySelectorAll(".surf-group[open]")).map(function (d) { return d.id; });
          sessionStorage.setItem(KEY, JSON.stringify(open));
        }
        try {
          var open = JSON.parse(sessionStorage.getItem(KEY) || "[]");
          open.forEach(function (id) { var d = document.getElementById(id); if (d) d.open = true; });
        } catch (e) {}
        document.querySelectorAll(".surf-group").forEach(function (d) { d.addEventListener("toggle", save); });
      })();
    </script>
  </div>`;
}

// Legacy single-image viewer — surfaces are now the CSS cell grid, so redirect
// to the zone's grid view (keeps old links/bookmarks working).
app.get("/surface/:id", (req, res) => {
  const job = db.getSurfaceJob(req.params.id);
  if (!job) return res.status(404).send(htmxPage("Not Found", "<h2>Surface job not found</h2>"));
  if (job.zone_id) return res.redirect(`/seed/${job.seed}/surface/${job.zone_id}`);
  return res.redirect(`/seed/${job.seed}`);
});

// ── API ────────────────────────────────────────────────────────────────

app.post("/api/universe/create", (req, res) => {
  const units = parseInt(req.body.units || req.body.total_units) || 1;
  const k2 = req.body.k2_enabled === "on" || req.body.k2_enabled === "1";
  const raw = (req.body.start_seed ?? "").toString().trim();
  const startSeed = raw === "" ? null : parseInt(raw);
  // Tail-filter cutoffs (blank/0 = that side off). A seed is kept if it's in a
  // tail of every enabled metric.
  const num = (v) => { const n = parseInt(v); return Number.isFinite(n) && n > 0 ? n : 0; };
  const filter = {
    naq_lo: num(req.body.naq_lo), naq_hi: num(req.body.naq_hi),
    pl_lo: num(req.body.pl_lo), pl_hi: num(req.body.pl_hi),
    // Percentages (0..100) of Calidus bodies, not counts.
    wp_lo: num(req.body.wp_lo), wp_hi: num(req.body.wp_hi),
    ef_lo: num(req.body.ef_lo), ef_hi: num(req.body.ef_hi),
  };
  const ids = jobs.createUniverseBuckets(units, k2, startSeed, filter);
  res.json({ ok: true, job_ids: ids, message: `Queued ${units} buckets` });
});

// Generate the full universe for one arbitrary seed and ingest it, so it can be
// opened and searched from the seed list. Returns an HTML fragment (the status
// span next to the form), not JSON — this is an htmx target.
app.post("/api/seed/generate", async (req, res) => {
  const seed = parseInt(req.body.seed);
  const k2 = req.body.k2 === "on" || req.body.k2 === "1";
  if (!Number.isFinite(seed) || seed < 0) {
    return res.send(`<span class="hint" style="color:var(--red)">Enter a non-negative whole seed number.</span>`);
  }
  try {
    const r = await jobs.generateSeed(seed, k2);
    const where = `<a href="/seeds?bucket=${encodeURIComponent(r.bucket)}">${r.bucket}</a>`;
    res.send(r.existed
      ? `<span class="hint">Seed <strong>${r.seed}</strong> was already known (${where}) — <a href="/seed/${r.seed}">open it</a>.</span>`
      : `<span class="hint" style="color:var(--green)">✅ Seed <strong>${r.seed}</strong> generated, ${r.zones} zones → ${where} — <a href="/seed/${r.seed}">open it</a>.</span>`);
  } catch (e) {
    res.send(`<span class="hint" style="color:var(--red)">${String(e.message).replace(/</g, "&lt;")}</span>`);
  }
});

// ── Workers ────────────────────────────────────────────────────────────

app.get("/workers", (req, res) => page(req, res, "Workers", renderWorkersPage(jobs.workerStatus())));

function renderWorkersPage(st) {
  const watchLink = (j) => j.zone_id
    ? ` <a class="btn-sm" href="/seed/${j.seed}/surface/${j.zone_id}" hx-get="/seed/${j.seed}/surface/${j.zone_id}" hx-target="#main" hx-push-url="true" hx-sync="#main:replace" title="watch grid">👁</a>`
    : "";
  const jobLabel = (type, j) => type === "universe"
    ? `<span class="wtag uni">universe</span> Bucket <strong>${j.bucket || "—"}</strong> · ${(j.seed_start || 0).toLocaleString()}–${(j.seed_end || 0).toLocaleString()}${j.k2_enabled ? " · K2" : ""}`
    : `<span class="wtag surf">surface</span> <strong>${j.zone_name}</strong> · seed ${j.seed} · ${j.kind || "ore"}${j.kind === "surface" && j.grid_cell >= 0 ? ` · cell ${j.grid_cell}/${j.grid_n * j.grid_n}` : ""}${watchLink(j)}`;

  // shared slot list: running universe jobs, then running surface jobs, then idle
  const active = [
    ...st.universe.jobs.map(j => ["universe", j]),
    ...st.surface.jobs.map(j => ["surface", j]),
  ];
  const slots = Array.from({ length: st.total }).map((_, i) => {
    const a = active[i];
    return a
      ? `<li><span class="dot running"></span> worker ${i + 1}: ${jobLabel(a[0], a[1])}</li>`
      : `<li class="idle"><span class="dot idle"></span> worker ${i + 1}: idle</li>`;
  }).join("");

  return `
  <div class="page" hx-get="/workers" hx-trigger="every 2s" hx-swap="outerHTML" hx-sync="#main:drop">
    ${crumbs([{ label: "Buckets", href: "/universe" }, { label: "Workers" }])}
    <h2>⚙ Workers</h2>
    <p class="hint">One shared pool — each worker (thread) picks up whichever job is next: universe
    (<code>seedgen</code>) or surface (<code>segen</code>). Optionally cap how many of the pool each
    type may use at once; set both caps to the total for a free-for-all.</p>
    <div class="worker-pool">
      <div class="pool-head">
        <span class="badge ${st.running ? "running" : "done"}">${st.running}/${st.total} busy</span>
        <span class="hint">universe ${st.universe.running}/${st.universe.cap} (${st.universe.queued} queued) ·
        surface ${st.surface.running}/${st.surface.cap} (${st.surface.queued} queued)</span>
        <form class="pool-form" hx-post="/api/workers/concurrency" hx-swap="none"
              hx-on::after-request="htmx.ajax('GET','/workers',{target:'#main'})">
          <label>Total <input type="number" name="total" value="${st.total}" min="1" max="32"></label>
          <label title="max pool slots universe may use">Universe cap <input type="number" name="universe" value="${st.universe.cap}" min="0" max="32"></label>
          <label title="max pool slots surface may use">Surface cap <input type="number" name="surface" value="${st.surface.cap}" min="0" max="32"></label>
          <button type="submit" class="btn-sm">Apply</button>
        </form>
      </div>
      <ul class="worker-list">${slots}</ul>
    </div>
  </div>`;
}

app.post("/api/workers/concurrency", (req, res) => {
  const num = (v) => (v === undefined || v === "" ? undefined : parseInt(v));
  jobs.setWorkerLimits({ total: num(req.body.total), universe: num(req.body.universe), surface: num(req.body.surface) });
  jobs.processQueue(); // fill any newly-freed worker slots right away
  res.json({ ok: true, status: jobs.workerStatus() });
});

// Persist the global max generation radius (caps new surface jobs to the inner disk).
app.post("/api/settings/max-radius", (req, res) => {
  const v = parseInt(req.body.max_radius);
  if (Number.isFinite(v) && v >= 100) db.setSetting("max_radius", String(v));
  res.json({ ok: true, max_radius: getMaxRadius() });
});

// ── Filter presets (reusable rulesets) ────────────────────────────────

app.get("/presets", (req, res) => page(req, res, "Filter Presets", renderPresetsPage(db.getFilterDefs())));

// One resource <select>. Reused for pre-filled rows and the clone templates.
function resSelect(val = "", disabled = false) {
  const dis = disabled ? "disabled" : "";
  return `<select name="res" ${dis}><option value="">(resource)</option>` +
    RESOURCES.map(o => `<option value="${o}" ${val === o ? "selected" : ""}>${o}</option>`).join("") +
    `</select>`;
}

// A rule row: [primary checkbox] [1..many resource selects] [+ add resource] [× remove rule].
// A rule = { primary: bool, res: [...] } — the body's primary must be res[0]
// (when checked, for core fragments) and all `res` must be present.
function renderRuleRow(rule = null, disabled = false) {
  const dis = disabled ? "disabled" : "";
  const nr = rule ? analyze.normalizeRule(rule) : null;
  if (rule && !nr) {
    // legacy count rule (specials/pairs) — show it, allow removal, no editing
    return `<div class="rule-row legacy"><em>legacy: ${analyze.ruleLabel(rule)}</em>` +
      (dis ? "" : `<button type="button" class="btn-sm ghost" title="remove" onclick="delRow(this)">−</button>`) + `</div>`;
  }
  const primChecked = nr && nr.primary ? "checked" : "";
  const resList = nr && nr.res.length ? nr.res : [""];
  const emVal = nr && nr.enemyMax != null ? nr.enemyMax : "";
  const emOpts = `<option value="">enemy: any</option>` +
    analyze.ENEMY_LEVELS.map((lvl, i) => `<option value="${i}" ${emVal === i ? "selected" : ""}>enemy ≤ ${lvl}</option>`).join("");
  const wmVal = nr && nr.waterMin != null ? nr.waterMin : "";
  const wmOpts = `<option value="">water: any</option>` +
    analyze.WATER_LEVELS.map((lvl, i) => `<option value="${i}" ${wmVal === i ? "selected" : ""}>water ≥ ${lvl}</option>`).join("");
  return `<div class="rule-row">
    <label class="prim-check" title="require this body's PRIMARY to be the first resource (core fragments)">
      <input type="checkbox" name="primary" ${primChecked} ${dis}> primary</label>
    <span class="res-selects">${resList.map(v => resSelect(v, disabled)).join("")}</span>
    <select name="enemyMax" title="only accept a surface whose enemy tag is at most this (blank = any)" ${dis}>${emOpts}</select>
    <select name="waterMin" title="only accept a surface whose water tag is at least this (blank = any)" ${dis}>${wmOpts}</select>
    <label class="radius-min" title="only accept a surface with radius ≥ this (blank = any; ~2000 = old 'viable' floor)">r ≥ <input type="number" name="radiusMin" value="${nr && nr.radiusMin != null ? nr.radiusMin : ""}" min="0" step="100" style="width:5em" placeholder="any" ${dis}></label>
    ${dis ? "" : `<button type="button" class="btn-sm" title="add another resource to this rule" onclick="addRes(this)">+</button>
    <button type="button" class="btn-sm ghost" title="remove a resource (or the rule if it's the last)" onclick="removeRes(this)">−</button>`}
  </div>`;
}

function renderPresetsPage(defs) {
  const refresh = `hx-on::after-request="htmx.ajax('GET','/presets',{target:'#main'})"`;
  // Serialize the rows to a `rules` JSON param at request time (checkboxes +
  // variable resource counts don't survive flat form arrays cleanly).
  const serialize = `hx-on::config-request="event.detail.parameters.rules = JSON.stringify(collectRules(this))"`;

  const item = (d) => {
    let rules = [];
    try { rules = JSON.parse(d.rules); } catch (_) {}
    const rl = rules.map(analyze.ruleLabel).join(" AND ") || "—";
    const badge = d.builtin ? '<span class="badge">preset</span>' : '<span class="badge custom">custom</span>';
    const summary = `<summary><span class="preset-name">${d.name}</span> ${badge}<span class="rule-sum">${rl}</span></summary>`;
    const post = d.builtin ? null : (d.id);
    if (d.builtin) {
      return `<details class="preset-item">${summary}
        <div class="preset-body">
          <p class="hint">Built-in preset — read-only.</p>
          <div class="rules-rows">${rules.map(r => renderRuleRow(r, true)).join("")}</div>
        </div></details>`;
    }
    return `<details class="preset-item">${summary}
      <div class="preset-body">
        <form hx-post="/api/preset/${post}/update" hx-swap="none" ${serialize} ${refresh}>
          <label>Name: <input type="text" name="name" value="${d.name}" required></label>
          <div class="rules-rows">${(rules.length ? rules : [null]).map(r => renderRuleRow(r)).join("")}</div>
          <button type="button" class="btn-sm" onclick="addRule(this)">+ rule</button>
          <div class="preset-actions">
            <button type="submit" class="btn">💾 Save changes</button>
            <button type="button" class="btn-sm danger" hx-delete="/api/preset/${post}" hx-swap="none" ${refresh}>🗑 Delete</button>
          </div>
        </form>
      </div></details>`;
  };

  return `
  <div class="page">
    ${crumbs([{ label: "Buckets", href: "/universe" }, { label: "Filter Presets" }])}
    <h2>⚙ Filter Presets</h2>
    <p class="hint">A preset is a set of rules (all must hold). Each rule = a body with the listed resource(s);
    tick <strong>primary</strong> to require it be that body's primary (core fragments). Add a resource with <strong>+</strong>,
    or repeat a rule to require another body. Use presets on the Seeds page.</p>
    <template id="rule-tpl">${renderRuleRow()}</template>
    <template id="res-tpl">${resSelect()}</template>
    <div class="preset-list">
      ${defs.map(item).join("")}
      <details class="preset-item new">
        <summary><span class="preset-name">➕ New preset</span></summary>
        <div class="preset-body">
          <form hx-post="/api/preset/create" hx-swap="none" ${serialize} ${refresh}>
            <label>Name: <input type="text" name="name" placeholder="e.g. vulcanite core + naq" required></label>
            <div class="rules-rows">${renderRuleRow()}</div>
            <button type="button" class="btn-sm" onclick="addRule(this)">+ rule</button>
            <div class="preset-actions"><button type="submit" class="btn">Create preset</button></div>
          </form>
        </div>
      </details>
    </div>
    <script>
      function collectRules(form) {
        return [...form.querySelectorAll(".rule-row")].map(function (row) {
          const chk = row.querySelector("input[name=primary]");
          const res = [...row.querySelectorAll("select[name=res]")].map(function (s) { return s.value; }).filter(Boolean);
          const em = row.querySelector("select[name=enemyMax]");
          const enemyMax = em && em.value !== "" ? Number(em.value) : null;
          const wm = row.querySelector("select[name=waterMin]");
          const waterMin = wm && wm.value !== "" ? Number(wm.value) : null;
          const rmEl = row.querySelector("input[name=radiusMin]");
          const radiusMin = rmEl && rmEl.value !== "" ? Number(rmEl.value) : null;
          return res.length ? { primary: !!(chk && chk.checked), res: res, enemyMax: enemyMax, waterMin: waterMin, radiusMin: radiusMin } : null;
        }).filter(Boolean);
      }
      function addRule(btn) {
        btn.closest("form").querySelector(".rules-rows")
          .appendChild(document.getElementById("rule-tpl").content.firstElementChild.cloneNode(true));
      }
      function addRes(btn) {
        btn.closest(".rule-row").querySelector(".res-selects")
          .appendChild(document.getElementById("res-tpl").content.firstElementChild.cloneNode(true));
      }
      function delRow(btn) {
        const row = btn.closest(".rule-row"), rows = btn.closest(".rules-rows");
        if (rows.querySelectorAll(".rule-row").length > 1) row.remove();
      }
      function removeRes(btn) {
        const row = btn.closest(".rule-row"), rows = btn.closest(".rules-rows");
        const selects = row.querySelectorAll("select[name=res]");
        if (selects.length > 1) { selects[selects.length - 1].remove(); return; }
        if (rows.querySelectorAll(".rule-row").length > 1) { row.remove(); return; }
        // last resource of the last rule → clear it rather than empty the form
        selects[0].value = "";
        const chk = row.querySelector("input[name=primary]");
        if (chk) chk.checked = false;
      }
    </script>
  </div>`;
}

// Parse the `rules` JSON param into normalized { primary, res:[...] } rules.
function parseRules(body) {
  let raw = [];
  try { raw = JSON.parse(body.rules || "[]"); } catch (_) {}
  if (!Array.isArray(raw)) return [];
  return raw
    .map(r => ({
      primary: !!r.primary,
      res: Array.isArray(r.res) ? r.res.filter(Boolean) : [],
      enemyMax: (r.enemyMax === 0 || (r.enemyMax != null && r.enemyMax !== "")) ? Number(r.enemyMax) : null,
      waterMin: (r.waterMin === 0 || (r.waterMin != null && r.waterMin !== "")) ? Number(r.waterMin) : null,
      radiusMin: (r.radiusMin != null && r.radiusMin !== "" && Number(r.radiusMin) > 0) ? Number(r.radiusMin) : null,
    }))
    .filter(r => r.res.length > 0);
}

app.post("/api/preset/create", (req, res) => {
  const name = (req.body.name || "").trim();
  if (!name) return res.status(400).json({ ok: false, error: "name required" });
  const rules = parseRules(req.body);
  if (rules.length === 0) return res.status(400).json({ ok: false, error: "no valid rules" });
  try {
    const id = db.createFilterDef(name, rules);
    res.json({ ok: true, id, rules });
  } catch (e) { res.status(400).json({ ok: false, error: String(e.message) }); }
});

app.post("/api/preset/:id/update", (req, res) => {
  const id = parseInt(req.params.id);
  const def = db.getFilterDef(id);
  if (!def) return res.status(404).json({ ok: false, error: "preset not found" });
  if (def.builtin) return res.status(400).json({ ok: false, error: "built-in presets are read-only" });
  const name = (req.body.name || "").trim();
  if (!name) return res.status(400).json({ ok: false, error: "name required" });
  const rules = parseRules(req.body);
  if (rules.length === 0) return res.status(400).json({ ok: false, error: "no valid rules" });
  try {
    db.updateFilterDef(id, name, rules);
    res.json({ ok: true, id, rules });
  } catch (e) { res.status(400).json({ ok: false, error: String(e.message) }); }
});

app.delete("/api/preset/:id", (req, res) => { db.deleteFilterDef(parseInt(req.params.id)); res.json({ ok: true }); });

// Queue jobs for one zone. kind=ore → a single ore job. kind=surface → one job
// per grid cell that intersects the disk (parallel tiles, stitched on complete).
// kind: 'ore' (amounts only), 'terrain' (biome layer), 'oremap' (ore layer,
// needs the ore pass), or 'surface' (both layers = terrain + oremap).
function queueZone(zone, seed, kind) {
  const radius = effRadius(zone);
  const base = { zone_id: zone.id, seed, zone_name: zone.name, radius };
  const n = jobs.surfaceGridFor(radius);
  const cellIdx = jobs.planSurfaceCells(radius, n);

  // Clear any stale stitched image(s) for the layers we're about to regenerate,
  // up front — so the surface view drops straight to the live cell grid instead
  // of flashing the previous whole image while the new render (including the
  // slow ore pass) runs. Cells stitch into a fresh single image only at the end.
  const bucket = (db.getSeed(seed) || {}).bucket || zone.bucket;
  const zDir = path.join(jobs.seedDir(bucket, seed), zone.name);
  const drop = (f) => { try { fs.unlinkSync(path.join(zDir, f)); } catch (_) {} };
  if (kind === "oremap" || kind === "surface") drop("oremap.png");
  if (kind === "terrain" || kind === "gputerrain" || kind === "surface") drop("terrain.png");
  if (kind === "surface") drop("surface.png");

  // One render job per cell (or a single whole job when n<=1).
  const renderCells = (renderKind, dep, loadOre) => (n <= 1
    ? [db.createSurfaceJob({ ...base, kind: renderKind, grid_n: 1, grid_cell: -1, depends_on: dep || null, load_ore: loadOre ? 1 : 0 })]
    : cellIdx.map(cell => db.createSurfaceJob({ ...base, kind: renderKind, grid_n: n, grid_cell: cell, depends_on: dep || null, load_ore: loadOre ? 1 : 0 })));

  if (kind === "ore") return [db.createSurfaceJob({ ...base, kind: "ore" })];
  if (kind === "terrain") return renderCells("terrain", null, false); // CPU terrain, no GPU mask

  // Shared classify: the biome/water/asteroid gate (biome_<n>_<cell>.bin) is
  // computed once and reused by BOTH the terrain (gpu_segen --mask) and ore
  // (gpu_ore --mask) passes. Whichever layer runs first produces it; the second
  // reuses the cached mask. Skip the classify job entirely if a fresh mask is
  // already on disk (e.g. the sibling layer was generated earlier).
  const dep = ensureClassifyJob(base, zDir, radius);   // job id to depend on, or null
  const ids = dep ? [dep] : [];

  // GPU whole-zone terrain: one gpu_segen job (it tiles internally at grid n).
  if (kind === "gputerrain") {
    ids.push(db.createSurfaceJob({ ...base, kind: "gputerrain", grid_n: 1, grid_cell: -1, depends_on: dep }));
    return ids;
  }

  // oremap / surface: the ore layer, all zone types via the GPU path — an
  // 'oredump' prep (segen --gpu-ore-dump = CPU spot generation) feeds gpu_ore,
  // which tiles + renders oremap cells on the GPU. Chain classify → oredump →
  // gpuoremap so the shared mask exists before gpu_ore reads it (--mask). Fields
  // use the asteroid mask; planets/moons the biome/water gate. Bit-exact vs the
  // CPU oracle within the render disk (segen --ores-only remains the oracle).
  if (kind === "surface") ids.push(db.createSurfaceJob({ ...base, kind: "gputerrain", grid_n: 1, grid_cell: -1, depends_on: dep }));
  const prep = db.createSurfaceJob({ ...base, kind: "oredump", depends_on: dep });
  ids.push(prep, db.createSurfaceJob({ ...base, kind: "gpuoremap", grid_n: n, grid_cell: -1, depends_on: prep }));
  return ids;
}

// Ensure a shared classify mask exists (or is being produced) for this zone at
// its current grid. Returns a job id the render passes should depend on, or null
// when a fresh on-disk mask means no classify is needed. Dedupes against an
// already-queued/running classify job for the same zone+grid.
function ensureClassifyJob(base, zDir, radius) {
  if (jobs.maskCellsPresent(zDir, radius)) return null;   // reuse cached mask
  const n = jobs.surfaceGridFor(radius);
  const inflight = db.getSurfaceJobsForZone(base.zone_id).find(j =>
    j.kind === "classify" && j.grid_n === n && (j.status === "queued" || j.status === "running"));
  if (inflight) return inflight.id;
  return db.createSurfaceJob({ ...base, kind: "classify", grid_n: n, grid_cell: -1 });
}

app.post("/api/surface/create", (req, res) => {
  const kind = ["ore", "oremap", "terrain", "surface", "gputerrain"].includes(req.query.kind) ? req.query.kind : "ore";
  const seed = parseInt(req.body.seed);
  const zone = db.getZonesForSeed(seed).find(z => z.id === parseInt(req.body.zone_id));
  if (!zone) return res.status(404).json({ ok: false, error: "zone not found" });
  const ids = queueZone(zone, seed, kind);
  // Row button targets #zcell-<id>: hand back the live cell so it immediately
  // shows "generating…" and starts polling. Non-htmx callers get JSON.
  if (req.headers["hx-request"]) {
    const bucket = (db.getSeed(seed) || {}).bucket || zone.bucket;
    return res.send(renderZoneCell(bucket, seed, zone, true));
  }
  res.json({ ok: true, kind, queued: ids.length, job_ids: ids });
});

// Poll target for a single zone's action cell. Re-renders live status and,
// via OOB, the Resources cell. Stops polling itself once nothing is active.
app.get("/api/zone/cell", (req, res) => {
  const seed = parseInt(req.query.seed);
  const zone = db.getZonesForSeed(seed).find(z => z.id === parseInt(req.query.zone_id));
  if (!zone) return res.status(404).send("");
  const bucket = (db.getSeed(seed) || {}).bucket || zone.bucket;
  res.send(renderZoneCell(bucket, seed, zone, true));
});

// Poll target for a single generate-control (ore or surface). Returns just that
// control's <span> so a running job only re-renders its own button, not both.
// The ore control also carries the Resources OOB refresh (yields flip
// est→measured once the ore amounts land).
app.get("/api/zone/control", (req, res) => {
  const seed = parseInt(req.query.seed);
  const which = req.query.which === "surf" ? "surf" : "ore";
  const zone = db.getZonesForSeed(seed).find(z => z.id === parseInt(req.query.zone_id));
  if (!zone) return res.status(404).send("");
  const bucket = (db.getSeed(seed) || {}).bucket || zone.bucket;
  let html = renderZoneCtl(bucket, seed, zone, which);
  if (which === "ore") html += resOobTd(bucket, seed, zone);
  res.send(html);
});

// Cancel every queued/running job (universe + surface) and kill their
// processes. Used e.g. when a batch was started with the wrong settings.
app.post("/api/jobs/cancel-all", (req, res) => {
  const r = jobs.cancelAllJobs();
  res.json({ ok: true, ...r });
});

// Remove cancelled job rows + their on-disk data (exclusively-cancelled buckets).
app.post("/api/jobs/clear-cancelled", (req, res) => {
  const r = jobs.clearCancelledJobs();
  res.json({ ok: true, ...r });
});

// FULL wipe (testing reset): clear generated data from the DB + empty output/.
app.post("/api/system/wipe", (req, res) => {
  const r = jobs.wipeSystem();
  res.json({ ok: true, ...r });
});

// Batch: queue for each checked zone of a seed (kind = ore | surface).
app.post("/api/surface/batch", (req, res) => {
  const kind = ["ore", "oremap", "terrain", "surface", "gputerrain"].includes(req.query.kind) ? req.query.kind : "ore";
  const seed = parseInt(req.body.seed);
  let names = req.body.zone || [];
  if (!Array.isArray(names)) names = [names];
  const zones = db.getZonesForSeed(seed);
  let queued = 0;
  for (const name of names) {
    const z = zones.find(zz => zz.name === name);
    if (z) queued += queueZone(z, seed, kind).length;
  }
  res.json({ ok: true, kind, zones: names.length, queued });
});

// ── Start ────────────────────────────────────────────────────────────────

// The whole UI is htmx-driven (hx-get/hx-post), so a missing htmx yields a page
// that renders correctly but where nothing responds to a click — no request is
// ever sent. Writing a placeholder file here (as this used to) only hid the
// problem: it satisfied every exists() check while leaving the GUI inert. Warn
// loudly instead, and treat an undersized file as missing.
const htmxPath = path.join(__dirname, "public", "htmx.min.js");
const htmxBytes = fs.existsSync(htmxPath) ? fs.statSync(htmxPath).size : 0;
if (htmxBytes < 10_000) {
  console.error(
    `\n⚠️  htmx is missing from ${htmxPath}` +
      (htmxBytes ? ` (found only ${htmxBytes} bytes — a stub)` : "") +
      "\n    The GUI will load but every button will do nothing: queueing a job" +
      "\n    sends no request at all. Fix it with:\n" +
      "\n      node install.mjs\n"
  );
}

app.listen(PORT, () => {
  console.log(`\n🌌 SE Explorer GUI at http://localhost:${PORT}`);
  console.log("  buckets → seeds → filtered → seed → zone\n");
  // Drop surface-job rows whose output folder was deleted while we were down.
  try { jobs.reconcileAllSurfaces(); } catch (e) { console.error("reconcile:", e.message); }
  if (process.env.SE_GUI_NO_WORKER) console.log("  ⚠️  worker disabled (SE_GUI_NO_WORKER)\n");
  else jobs.startPolling();
});

process.on("SIGINT", () => { jobs.stopPolling(); process.exit(0); });
process.on("SIGTERM", () => { jobs.stopPolling(); process.exit(0); });
