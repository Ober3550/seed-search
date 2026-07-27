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
        <small>buckets → seeds → zone → surface</small>
      </div>
    </nav>
    <main id="main">${content}</main>
  </div>
</body>
</html>`;
}

function page(req, res, title, content) {
  if (req.headers["hx-request"]) res.send(content);
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
function renderZoneCell(bucket, seed, zone, withResOob = false) {
  const zjobs = db.getSurfaceJobsForZone(zone.id);
  const active = (kind) => zjobs.filter(j => j.kind === kind && (j.status === "queued" || j.status === "running"));
  const failed = (kind) => zjobs.filter(j => j.kind === kind && j.status === "failed").length > 0;
  const oreActive = active("ore");
  const surfActive = active("surface");
  const anyActive = oreActive.length > 0 || surfActive.length > 0;

  const orePng = zoneSurfacePng(bucket, seed, zone.name, "ore");
  const surfPng = zoneSurfacePng(bucket, seed, zone.name, "surface");
  const summary = !!zoneSurfaceSummary(bucket, seed, zone.name);
  const genArgs = `hx-vals='${JSON.stringify({ zone_id: zone.id, seed, zone_name: zone.name, radius: Math.round(zone.radius || 500) })}'`;
  const tgt = `hx-target="#zcell-${zone.id}" hx-swap="outerHTML"`;

  // Ore control
  let oreCtl;
  if (oreActive.length) oreCtl = `<span class="gen-status running">⏳ ore…</span>`;
  else oreCtl = `<button type="button" class="btn-sm" hx-post="/api/surface/create?kind=ore" ${genArgs} ${tgt}>${summary ? "↻ ore" : "⛏ ore"}</button>`;

  // Surface control (may be many cell jobs)
  let surfCtl;
  if (surfActive.length) {
    const total = surfActive.length + zjobs.filter(j => j.kind === "surface" && j.status === "done").length;
    surfCtl = `<span class="gen-status running">⏳ surface ${total - surfActive.length}/${total}…</span>`;
  } else {
    surfCtl = `<button type="button" class="btn-sm btn-secondary" hx-post="/api/surface/create?kind=surface" ${genArgs} ${tgt}>${surfPng ? "↻ 🗺️" : "🗺️ surface"}</button>`;
  }

  // Watch link: available whenever a surface has been generated OR cells are
  // still rendering — opens the live tiled grid.
  const hasSurfaceWork = surfPng || zjobs.some(j => j.kind === "surface");
  const watch = hasSurfaceWork
    ? `<a class="btn-sm" href="/surface/watch?seed=${seed}&zone_id=${zone.id}" hx-get="/surface/watch?seed=${seed}&zone_id=${zone.id}" hx-target="#main" hx-push-url="true" title="watch grid">👁</a>`
    : "";
  const links = `${orePng ? `<a class="btn-sm" href="${orePng}" target="_blank" title="ore map">⛏</a>` : ""}${surfPng ? `<a class="btn-sm" href="${surfPng}" target="_blank" title="surface map">🗺️</a>` : ""}${watch}`;
  const fail = (failed("ore") || failed("surface")) && !anyActive ? `<span class="gen-status failed" title="see Surface Jobs">⚠️</span>` : "";

  const poll = anyActive
    ? `hx-get="/api/zone/cell?seed=${seed}&zone_id=${zone.id}" hx-trigger="every 2s" hx-swap="outerHTML" hx-sync="#main:drop"`
    : "";

  // OOB refresh of the Resources cell so est→measured flips as jobs land.
  // Only emitted on poll/create responses — never in the initial full-page
  // render, where a second <td> would duplicate the column.
  const resOob = withResOob
    ? `<td class="yields-cell" id="zres-${zone.id}" hx-swap-oob="true">${renderZoneResources(bucket, seed, zone)}</td>`
    : "";

  return `<td class="row-actions" id="zcell-${zone.id}" ${poll}>${links}${oreCtl}${surfCtl}${fail}</td>${resOob}`;
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
  return `
  <div class="page">
    <div class="page-head">
      <h2>🌠 Universe Generation</h2>
      <div class="head-actions">
        <button class="btn danger" hx-post="/api/jobs/cancel-all" hx-swap="none"
          hx-confirm="Cancel ALL queued and running jobs (universe + surface) and kill their processes?"
          hx-on::after-request="htmx.ajax('GET','/universe',{target:'#main'})">
          ✖ Cancel all jobs
        </button>
        <button class="btn" hx-post="/api/jobs/clear-cancelled" hx-swap="none"
          hx-confirm="Delete all CANCELLED job entries and their on-disk bucket data? (surviving buckets are kept)"
          hx-on::after-request="htmx.ajax('GET','/universe',{target:'#main'})">
          🧹 Clear cancelled
        </button>
      </div>
    </div>
    <p class="hint">Every job is a fixed 100k-seed bucket. Requesting 10M queues 100 buckets;
    each writes <code>output/&lt;bucket&gt;/seeds.jsonl</code> (seedgen's rough pass).</p>
    <div class="job-form">
      <form hx-post="/api/universe/create" hx-swap="none"
            hx-on::after-request="htmx.ajax('GET','/universe/table',{target:'#jobs-table'})">
        <label title="Each unit = one 100k bucket">Buckets (×100k): <input type="number" name="units" value="10" min="1" max="1000" required></label>
        <label class="disabled-check"><input type="checkbox" checked disabled> Min 4 Prod Modules</label>
        <label class="disabled-check"><input type="checkbox" checked disabled> Nearby Naq Field</label>
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

  let seeds = db.getSeeds({ bucket: bucket || undefined, loot: loot || undefined, k2: k2filter });
  seeds = seeds.filter(s => {
    const c = seedCriteria(s); if (!c) return rules.length === 0;
    return analyze.matchFilter(c, rules).match;
  });
  const buckets = [...new Set(db.getUniverseJobs().filter(j => j.status === "done").map(j => j.bucket))];
  const defs = db.getFilterDefs();
  const genCounts = db.getGeneratedZoneCounts();
  page(req, res, "Seeds", renderSeedsPage(seeds, buckets, defs, { bucket, defId, def, loot, k2: k2q }, genCounts));
});

function renderSeedsPage(seeds, buckets, defs, f, genCounts = {}) {
  const rules = f.def ? JSON.parse(f.def.rules) : [];
  const ruleStr = rules.map(analyze.ruleLabel).join(" AND ") || "no filter";
  return `
  <div class="page">
    ${crumbs([{ label: "Buckets", href: "/universe" }, { label: `Seeds ${f.bucket || "(all)"}` }])}
    <h2>🌱 Rough-passed Seeds ${f.bucket ? `<span class="badge zone-type">${f.bucket}</span>` : ""}</h2>
    <div class="filter-bar">
      <form id="seed-filters" hx-get="/seeds" hx-target="closest .page" hx-swap="outerHTML">
        <select name="bucket" hx-get="/seeds" hx-target="closest .page" hx-swap="outerHTML" hx-include="#seed-filters" hx-trigger="change">
          <option value="">All buckets</option>
          ${buckets.map(b => `<option value="${b}" ${f.bucket === b ? "selected" : ""}>${b}</option>`).join("")}
        </select>
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
        <input type="text" name="loot" placeholder="Loot prefix" value="${f.loot}"
          hx-get="/seeds" hx-target="closest .page" hx-swap="outerHTML" hx-include="#seed-filters" hx-trigger="keyup changed delay:400ms">
        <a href="/presets" hx-get="/presets" hx-target="#main" hx-push-url="true" class="btn-sm">⚙ manage presets</a>
      </form>
      <p class="hint">Filter: <strong>${ruleStr}</strong> — ${seeds.length} seed(s) match</p>
    </div>
    <table class="data-table" id="seeds-table">
      <thead><tr>
        <th class="sortable" data-key="seed" onclick="sortSeeds('seed')">Seed <span class="sort-ind"></span></th>
        <th>Bucket</th><th>K2</th><th>Loot</th>
        <th class="sortable" data-key="zones" onclick="sortSeeds('zones')" title="generated / total zones — sort desc groups generated seeds (by most generated) above the rest (by most zones)">Zones <span class="sort-ind"></span></th>
        <th>Naq</th><th></th>
      </tr></thead>
      <tbody>
        ${seeds.slice(0, 500).map(s => {
          const c = seedCriteria(s) || {};
          const gen = genCounts[s.seed] || 0;
          return `
        <tr data-seed="${s.seed}" data-zones="${s.zone_count || 0}" data-gen="${gen}">
          <td><strong>${s.seed}</strong></td><td>${s.bucket}</td><td>${s.k2 ? "✅" : "—"}</td><td><code>${s.loot}</code></td>
          <td>${gen > 0 ? `<strong>${gen}</strong>/${s.zone_count}` : s.zone_count}</td>
          <td>${c.naqField || "—"}</td>
          <td><a href="/seed/${s.seed}" hx-get="/seed/${s.seed}" hx-target="#main" hx-push-url="true" class="btn-sm">Zones →</a></td>
        </tr>`;}).join("")}
        ${seeds.length === 0 ? `<tr><td colspan="7">No seeds match.</td></tr>` : ""}
      </tbody>
    </table>
    ${seeds.length > 500 ? `<p class="hint">Showing first 500 of ${seeds.length}.</p>` : ""}
    <script>
      (function () {
        var st = { key: null, dir: "desc" };
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
const GEN_TYPES = ["planet", "moon"];

app.get("/seed/:seed", (req, res) => {
  const s = db.getSeed(parseInt(req.params.seed));
  if (!s) return res.status(404).send(htmxPage("Not Found", "<h2>Seed not found</h2>"));
  const c = seedCriteria(s) || { selectedZones: [], specials: {}, pairs: {} };
  const filterId = req.query.filter || null;

  // Show ALL zones; criteria-relevant ones are pinned to the top and pre-checked.
  const sel = new Set(c.selectedZones || []);
  const zones = db.getZonesForSeed(s.seed).sort((a, b) => {
    const ra = sel.has(a.name) ? 0 : 1, rb = sel.has(b.name) ? 0 : 1;
    return ra - rb || (a.name || "").localeCompare(b.name || "");
  });

  // zones.jsonl always carries the criteria-relevant zones for the generator.
  try { jobs.writeSeedZonesFile(s, null); }
  catch (e) { console.error("writeSeedZonesFile:", e.message); }

  page(req, res, `Seed ${s.seed}`, renderSeedDetail(s, c, zones, filterId));
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

function renderSeedDetail(s, c, zones, filterId) {
  const back = { label: "Seeds", href: `/seeds?bucket=${s.bucket}` };
  const reload = `/seed/${s.seed}`;
  const sel = new Set(c.selectedZones || []);
  const th = (label, key) => `<th class="sortable" data-key="${key}" onclick="sortZones('${key}')">${label} <span class="sort-ind"></span></th>`;

  return `
  <div class="page">
    ${crumbs([{ label: "Buckets", href: "/universe" }, back, { label: `Seed ${s.seed}` }])}
    <h2>🌱 Seed ${s.seed} <span class="badge zone-type">${s.bucket}</span> <code>${s.loot}</code></h2>
    <div class="filter-bar">
      <input type="text" id="zone-search" placeholder="🔍 Search name or resource…" oninput="filterZones()" autocomplete="off">
      <span class="hint">All zones shown; ⭐ criteria-relevant are pinned to the top and pre-selected. Click a header to sort.</span>
    </div>
    <form id="zone-batch">
      <input type="hidden" name="seed" value="${s.seed}">
      <div class="batch-actions">
        <button type="button" class="btn"
          hx-post="/api/surface/batch?kind=ore" hx-include="#zone-batch input[name=seed], #zone-batch input[name=zone]:checked" hx-swap="none"
          hx-disabled-elt="this" hx-on::after-request="htmx.ajax('GET','${reload}',{target:'#main'})">
          ⛏ Generate ores — selected zones
        </button>
        <button type="button" class="btn btn-secondary"
          hx-post="/api/surface/batch?kind=surface" hx-include="#zone-batch input[name=seed], #zone-batch input[name=zone]:checked" hx-swap="none"
          hx-disabled-elt="this" hx-on::after-request="htmx.ajax('GET','${reload}',{target:'#main'})">
          🗺️ Generate surfaces (biome+water) — selected zones
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
          ${zones.map(z => {
            const relevant = sel.has(z.name);
            const gen = GEN_TYPES.includes(z.zone_type);
            const water = (z.water || "none").replace(/^water[_-]?/, "") || "none";
            const enemy = (z.enemy || "none").replace(/^enemy[_-]?/, "").replace("very_", "v") || "none";
            const data = `data-zone="${(z.name || "").replace(/"/g, "")}" data-type="${z.zone_type}" data-radius="${z.radius || 0}" data-dv="${z.delta_v || 0}" data-water="${water}" data-enemy="${enemy}" data-relevant="${relevant ? 1 : 0}" data-search="${zoneSearchText(s.bucket, s.seed, z)}"`;
            return `
          <tr class="${gen ? "" : "zone-info"}" ${data}>
            <td>${gen ? `<input type="checkbox" name="zone" value="${z.name}" ${relevant ? "checked" : ""}>` : ""}</td>
            <td><strong>${z.name}</strong></td>
            <td><span class="badge zone-type">${z.zone_type}</span></td>
            <td>${z.radius ? Math.round(z.radius) : "—"}</td>
            <td class="num">${z.delta_v ? Math.round(z.delta_v) : "—"}</td>
            <td>${water}</td>
            <td>${enemy}</td>
            <td>${relevant ? "⭐" : ""}</td>
            <td class="yields-cell" id="zres-${z.id}">${renderZoneResources(s.bucket, s.seed, z)}</td>
            ${gen ? renderZoneCell(s.bucket, s.seed, z) : `<td class="row-actions muted">—</td>`}
          </tr>`;}).join("")}
          ${zones.length === 0 ? `<tr><td colspan="10">No zones.</td></tr>` : ""}
        </tbody>
      </table>
    </form>
    <script>
      (function () {
        var sortState = { key: null, dir: "asc" };
        var NUMERIC = { radius: 1, dv: 1 };
        window.sortZones = function (key) {
          sortState.dir = (sortState.key === key && sortState.dir === "asc") ? "desc" : "asc";
          sortState.key = key;
          var tb = document.querySelector("#zone-table tbody");
          var rows = [].slice.call(tb.querySelectorAll("tr[data-zone]"));
          rows.sort(function (a, b) {
            var ra = +a.dataset.relevant, rb = +b.dataset.relevant;
            if (ra !== rb) return rb - ra;            // ⭐ relevant pinned to top
            var va = a.dataset[key], vb = b.dataset[key], cmp;
            if (NUMERIC[key]) cmp = (parseFloat(va) || 0) - (parseFloat(vb) || 0);
            else cmp = String(va).localeCompare(String(vb));
            return sortState.dir === "asc" ? cmp : -cmp;
          });
          rows.forEach(function (r) { tb.appendChild(r); });
          document.querySelectorAll("#zone-table th.sortable .sort-ind").forEach(function (s) { s.textContent = ""; });
          var thh = document.querySelector('#zone-table th[data-key="' + key + '"] .sort-ind');
          if (thh) thh.textContent = sortState.dir === "asc" ? "▲" : "▼";
        };
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
        };
      })();
    </script>
  </div>`;
}

// ── Live surface watch (tiled grid) ────────────────────────────────────

function zoneCellPng(bucket, seed, zoneName, n, cell) {
  const file = n > 1 ? `surface_${n}_${cell}.png` : "surface.png";
  const rel = path.join(bucket, `seed_${seed}`, zoneName, file);
  return fs.existsSync(path.join(jobs.OUTPUT_DIR, rel)) ? `/output/${rel}` : null;
}

// The tiled grid fragment. Each planned cell is absolutely positioned as a % of
// the 2r canvas (matches the stitched surface.png exactly). Polls itself every
// 1.5s until every cell has a PNG, then stops.
function renderSurfaceGrid(seed, zoneId) {
  const zone = db.getZonesForSeed(seed).find(z => z.id === zoneId);
  if (!zone) return `<div class="surf-grid-wrap" id="surfgrid-${zoneId}"><p class="hint">Zone not found.</p></div>`;
  const bucket = (db.getSeed(seed) || {}).bucket || zone.bucket;
  const radius = Math.round(zone.radius || 500);
  const { n, cells } = jobs.surfaceCellLayout(radius);

  const surfJobs = db.getSurfaceJobsForZone(zoneId).filter(j => j.kind === "surface");
  const byCell = {};
  for (const j of surfJobs) byCell[j.grid_cell] = j;
  const anyActive = surfJobs.some(j => j.status === "queued" || j.status === "running");

  // Fallback for surfaces stitched before per-cell PNGs existed: no cell PNGs on
  // disk, nothing running, but surface.png present → just show the full image.
  const hasCellPngs = cells.some(c => zoneCellPng(bucket, seed, zone.name, n, c.cell));
  const stitchedRel = zoneCellPng(bucket, seed, zone.name, 1, 0);
  if (n > 1 && !hasCellPngs && !anyActive && stitchedRel) {
    return `<div class="surf-grid-wrap" id="surfgrid-${zoneId}">
      <div class="surf-grid-head"><strong>${zone.name}</strong> · <span class="gen-status">✅ stitched</span>
        <a class="btn-sm" href="${stitchedRel}" target="_blank" title="full-res">⤢ full image</a></div>
      <div class="surf-grid"><img class="surf-full" src="${stitchedRel}" alt="${zone.name} surface"></div>
    </div>`;
  }

  let done = 0, failed = 0;
  const slots = cells.map(c => {
    const png = zoneCellPng(bucket, seed, zone.name, n, c.cell);
    const job = byCell[n > 1 ? c.cell : -1];
    const style = `left:${c.leftPct}%;top:${c.topPct}%;width:${c.wPct}%;height:${c.hPct}%`;
    let state, inner;
    if (png) { state = "done"; done++; inner = `<img loading="lazy" src="${png}" alt="cell ${c.cell}">`; }
    else if (job && job.status === "failed") { state = "failed"; failed++; inner = `<span>⚠️</span>`; }
    else if (job && job.status === "running") { state = "running"; inner = `<span>⏳</span>`; }
    else { state = "queued"; inner = ""; }
    return `<div class="surf-cell ${state}" style="${style}" title="cell ${c.cell}">${inner}</div>`;
  }).join("");

  const total = cells.length;
  const complete = done + failed >= total;
  const poll = complete ? "" : `hx-get="/api/surface/grid?seed=${seed}&zone_id=${zoneId}" hx-trigger="every 1500ms" hx-swap="outerHTML" hx-sync="#main:drop"`;
  const status = complete
    ? (failed ? `⚠️ ${done}/${total} cells (${failed} failed)` : `✅ ${done}/${total} cells`)
    : `⏳ ${done}/${total} cells…`;

  return `<div class="surf-grid-wrap" id="surfgrid-${zoneId}" ${poll}>
    <div class="surf-grid-head">
      <strong>${zone.name}</strong> · grid ${n}×${n} · <span class="gen-status ${complete ? "" : "running"}">${status}</span>
      ${complete && stitchedRel ? `<a class="btn-sm" href="${stitchedRel}" target="_blank" title="stitched full-res">⤢ full image</a>` : ""}
    </div>
    <div class="surf-grid">${slots}</div>
  </div>`;
}

// Poll target for the live grid.
app.get("/api/surface/grid", (req, res) => {
  res.send(renderSurfaceGrid(parseInt(req.query.seed), parseInt(req.query.zone_id)));
});

// Full watch page (breadcrumb + embedded live grid).
app.get("/surface/watch", (req, res) => {
  const seed = parseInt(req.query.seed);
  const zoneId = parseInt(req.query.zone_id);
  const s = db.getSeed(seed);
  const zone = db.getZonesForSeed(seed).find(z => z.id === zoneId);
  if (!s || !zone) return page(req, res, "Watch", `<div class="page"><p class="hint">Seed or zone not found.</p></div>`);
  const content = `
  <div class="page">
    ${crumbs([{ label: "Buckets", href: "/universe" }, { label: `Seed ${seed}`, href: `/seed/${seed}` }, { label: `${zone.name} surface` }])}
    <h2>👁 Watching <strong>${zone.name}</strong> surface</h2>
    <p class="hint">Each tile appears as its generation cell finishes; the grid matches the final stitched image.</p>
    ${renderSurfaceGrid(seed, zoneId)}
  </div>`;
  page(req, res, `Watch ${zone.name}`, content);
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
      ? `<a class="btn-sm" href="/surface/watch?seed=${first.seed}&zone_id=${first.zone_id}" hx-get="/surface/watch?seed=${first.seed}&zone_id=${first.zone_id}" hx-target="#main" hx-push-url="true" title="watch grid">👁</a>`
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
              <td>${j.status === "done" && j.kind !== "ore" ? `<a href="/surface/${j.id}" hx-get="/surface/${j.id}" hx-target="#main" hx-push-url="true" class="btn-sm">🖼️</a>` : ""}</td>
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
      <button class="btn danger" hx-post="/api/jobs/cancel-all" hx-swap="none"
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

app.get("/surface/:id", (req, res) => {
  const job = db.getSurfaceJob(req.params.id);
  if (!job) return res.status(404).send(htmxPage("Not Found", "<h2>Surface job not found</h2>"));
  page(req, res, `Surface: ${job.zone_name}`, renderSurfaceViewer(job));
});

function renderSurfaceViewer(job) {
  const imgSrc = job.png_file ? `/output/${job.png_file}` : null;
  let summary = null; try { summary = JSON.parse(job.summary); } catch (_) {}
  return `
  <div class="page">
    <h2>🖼️ ${job.zone_name} <span class="badge done">seed ${job.seed}</span> <span class="badge zone-type">${job.bucket || ""}</span></h2>
    <div class="surface-viewer">
      <div class="surface-meta">
        <p><strong>Seed:</strong> <a href="/seed/${job.seed}" hx-get="/seed/${job.seed}" hx-target="#main" hx-push-url="true">${job.seed}</a></p>
        <p><strong>Status:</strong> <span class="badge ${job.status}">${job.status}</span></p>
        ${job.error ? `<p class="error">Error: ${job.error}</p>` : ""}
        ${summary ? `
        <h3>Ore estimates</h3>
        <table class="data-table"><thead><tr><th>Resource</th><th>Ore</th><th>Tiles</th></tr></thead><tbody>
          ${Object.entries(summary.resources || {}).sort((a, b) => (b[1].amount || 0) - (a[1].amount || 0))
            .map(([r, v]) => `<tr><td>${r}</td><td class="num"><strong>${v.display || fmtAmount(v.amount)}</strong></td><td class="num">${v.tiles}</td></tr>`).join("")}
        </tbody></table>` : ""}
      </div>
      ${imgSrc ? `<div class="surface-image-container">
        <img src="${imgSrc}" class="surface-image" style="max-width:100%; image-rendering:pixelated; border:1px solid #333;">
        <p class="image-info">1 px = 1 tile</p></div>`
      : job.status === "running" ? `<div class="loading"><p>⏳ Generating… <span hx-get="/surface/${job.id}" hx-trigger="every 2s" hx-target="closest .page" hx-swap="outerHTML" hx-sync="#main:drop"></span></p></div>` : ""}
    </div>
  </div>`;
}

// ── API ────────────────────────────────────────────────────────────────

app.post("/api/universe/create", (req, res) => {
  const units = parseInt(req.body.units || req.body.total_units) || 1;
  const k2 = req.body.k2_enabled === "on" || req.body.k2_enabled === "1";
  const ids = jobs.createUniverseBuckets(units, k2);
  res.json({ ok: true, job_ids: ids, message: `Queued ${units} × 100k buckets` });
});

// ── Workers ────────────────────────────────────────────────────────────

app.get("/workers", (req, res) => page(req, res, "Workers", renderWorkersPage(jobs.workerStatus())));

function renderWorkersPage(st) {
  const watchLink = (j) => j.zone_id
    ? ` <a class="btn-sm" href="/surface/watch?seed=${j.seed}&zone_id=${j.zone_id}" hx-get="/surface/watch?seed=${j.seed}&zone_id=${j.zone_id}" hx-target="#main" hx-push-url="true" hx-sync="#main:replace" title="watch grid">👁</a>`
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
  return `<div class="rule-row">
    <label class="prim-check" title="require this body's PRIMARY to be the first resource (core fragments)">
      <input type="checkbox" name="primary" ${primChecked} ${dis}> primary</label>
    <span class="res-selects">${resList.map(v => resSelect(v, disabled)).join("")}</span>
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
          return res.length ? { primary: !!(chk && chk.checked), res: res } : null;
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
    .map(r => ({ primary: !!r.primary, res: Array.isArray(r.res) ? r.res.filter(Boolean) : [] }))
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
function queueZone(zone, seed, kind) {
  const radius = Math.round(zone.radius || 500);
  if (kind !== "surface") {
    return [db.createSurfaceJob({ zone_id: zone.id, seed, zone_name: zone.name, radius, kind: "ore" })];
  }
  const n = jobs.surfaceGridFor(radius);
  const cells = jobs.planSurfaceCells(radius, n);
  // Small planet (no tiling): a single render job computes its own ore.
  if (n <= 1) {
    return [db.createSurfaceJob({
      zone_id: zone.id, seed, zone_name: zone.name, radius, kind: "surface", grid_n: 1, grid_cell: -1,
    })];
  }
  // Tiled: run the ore pass ONCE (a prep job writes ore.jsonl), then every cell
  // render depends on it and reads that cache (--load-ore) rather than
  // recomputing zone-wide ore per cell.
  const prep = db.createSurfaceJob({ zone_id: zone.id, seed, zone_name: zone.name, radius, kind: "ore" });
  const cellIds = cells.map(cell => db.createSurfaceJob({
    zone_id: zone.id, seed, zone_name: zone.name, radius,
    kind: "surface", grid_n: n, grid_cell: cell, depends_on: prep, load_ore: 1,
  }));
  return [prep, ...cellIds];
}

app.post("/api/surface/create", (req, res) => {
  const kind = req.query.kind === "surface" ? "surface" : "ore";
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

// Batch: queue for each checked zone of a seed (kind = ore | surface).
app.post("/api/surface/batch", (req, res) => {
  const kind = req.query.kind === "surface" ? "surface" : "ore";
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

const htmxPath = path.join(__dirname, "public", "htmx.min.js");
if (!fs.existsSync(htmxPath)) fs.writeFileSync(htmxPath, "// htmx placeholder — download from https://unpkg.com/htmx.org@2.0.4/dist/htmx.min.js");

app.listen(PORT, () => {
  console.log(`\n🌌 SE Explorer GUI at http://localhost:${PORT}`);
  console.log("  buckets → seeds → filtered → seed → zone\n");
  if (process.env.SE_GUI_NO_WORKER) console.log("  ⚠️  worker disabled (SE_GUI_NO_WORKER)\n");
  else jobs.startPolling();
});

process.on("SIGINT", () => { jobs.stopPolling(); process.exit(0); });
process.on("SIGTERM", () => { jobs.stopPolling(); process.exit(0); });
