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

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use("/static", express.static(path.join(__dirname, "public")));
app.use("/output", express.static(jobs.OUTPUT_DIR));

// ── Layout ───────────────────────────────────────────────────────────────

function htmxPage(title, content) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} — SE Explorer</title>
  <script src="/static/htmx.min.js"></script>
  <link rel="stylesheet" href="/static/style.css">
</head>
<body>
  <div class="app">
    <nav class="sidebar">
      <h1>🌌 SE Explorer</h1>
      <ul class="nav-links">
        <li><a href="/universe" hx-get="/universe" hx-target="#main" hx-push-url="true">Universe Buckets</a></li>
        <li><a href="/seeds" hx-get="/seeds" hx-target="#main" hx-push-url="true">Seeds</a></li>
        <li><a href="/presets" hx-get="/presets" hx-target="#main" hx-push-url="true">Filter Presets</a></li>
        <li><a href="/filters" hx-get="/filters" hx-target="#main" hx-push-url="true">Filtered Sets</a></li>
        <li><a href="/surfaces" hx-get="/surfaces" hx-target="#main" hx-push-url="true">Surface Jobs</a></li>
      </ul>
      <div class="sidebar-footer">
        <small>buckets → seeds → filtered → seed → zone</small>
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
    <h2>🌠 Universe Generation</h2>
    <p class="hint">Every job is a fixed 100k-seed bucket. Requesting 10M queues 100 buckets;
    each writes <code>output/&lt;bucket&gt;/seeds.jsonl</code> (seedgen's rough pass).</p>
    <div class="job-form">
      <form hx-post="/api/universe/create" hx-swap="none"
            hx-on::after-request="htmx.ajax('GET','/universe/table',{target:'#jobs-table'})">
        <label title="Each unit = one 100k bucket">Buckets (×100k): <input type="number" name="units" value="10" min="1" max="1000" required></label>
        <label title="Buckets run at once">Concurrency: <input type="number" name="concurrency" value="4" min="1" max="16"></label>
        <label class="disabled-check"><input type="checkbox" checked disabled> Min 4 Prod Modules</label>
        <label class="disabled-check"><input type="checkbox" checked disabled> Nearby Naq Field</label>
        <label>K2: <input type="checkbox" name="k2_enabled"></label>
        <button type="submit" class="btn">Queue Buckets</button>
      </form>
    </div>
    <div id="jobs-table" hx-get="/universe/table" hx-trigger="every 3s">${renderBucketsTable(jobsList)}</div>
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

  const def = defId ? db.getFilterDef(defId) : null;
  const rules = def ? JSON.parse(def.rules) : [];

  let seeds = db.getSeeds({ bucket: bucket || undefined, loot: loot || undefined });
  seeds = seeds.filter(s => {
    const c = seedCriteria(s); if (!c) return rules.length === 0;
    return analyze.matchFilter(c, rules).match;
  });
  const buckets = [...new Set(db.getUniverseJobs().filter(j => j.status === "done").map(j => j.bucket))];
  const defs = db.getFilterDefs();
  page(req, res, "Seeds", renderSeedsPage(seeds, buckets, defs, { bucket, defId, def, loot }));
});

function renderSeedsPage(seeds, buckets, defs, f) {
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
      ${f.bucket && f.defId ? `
      <form class="save-filter" hx-post="/api/filter/create" hx-swap="none"
            hx-on::after-request="htmx.ajax('GET','/filters?bucket=${f.bucket}',{target:'#main'})">
        <input type="hidden" name="bucket" value="${f.bucket}">
        <input type="hidden" name="def" value="${f.defId}">
        <input type="hidden" name="loot" value="${f.loot}">
        <input type="text" name="name" placeholder="Save as a filtered set…" value="${f.def ? f.def.name.replace(/[^a-zA-Z0-9_-]/g, "_") : ""}" required>
        <button type="submit" class="btn">💾 Save filtered set (${seeds.length})</button>
      </form>` : `<p class="hint">Pick a bucket and a filter to save a filtered set.</p>`}
    </div>
    <table class="data-table">
      <thead><tr><th>Seed</th><th>Bucket</th><th>Loot</th><th>Zones</th><th>Specials</th><th>Pairs</th><th>Naq</th><th></th></tr></thead>
      <tbody>
        ${seeds.slice(0, 500).map(s => {
          const c = seedCriteria(s) || {};
          return `
        <tr>
          <td><strong>${s.seed}</strong></td><td>${s.bucket}</td><td><code>${s.loot}</code></td>
          <td>${s.zone_count}</td><td>${c.numSpecials ?? "—"}/6</td><td>${c.numPairs ?? "—"}/5</td>
          <td>${c.naqField || "—"}</td>
          <td><a href="/seed/${s.seed}" hx-get="/seed/${s.seed}" hx-target="#main" hx-push-url="true" class="btn-sm">Zones →</a></td>
        </tr>`;}).join("")}
        ${seeds.length === 0 ? `<tr><td colspan="8">No seeds match.</td></tr>` : ""}
      </tbody>
    </table>
    ${seeds.length > 500 ? `<p class="hint">Showing first 500 of ${seeds.length}.</p>` : ""}
  </div>`;
}

// ── Level 3: Filtered Sets (saved second-layer subsets) ────────────────

app.get("/filters", (req, res) => {
  const bucket = req.query.bucket || "";
  const filters = db.getSeedFilters(bucket || undefined);
  page(req, res, "Filtered Sets", renderFiltersPage(filters, bucket));
});

function renderFiltersPage(filters, bucket) {
  return `
  <div class="page">
    ${crumbs([{ label: "Buckets", href: "/universe" }, { label: "Seeds", href: bucket ? `/seeds?bucket=${bucket}` : "/seeds" }, { label: "Filtered Sets" }])}
    <h2>🔎 Filtered Sets ${bucket ? `<span class="badge zone-type">${bucket}</span>` : ""}</h2>
    <p class="hint">Saved second-layer filters over each bucket's rough-passed seeds. The membership
    file lives at <code>output/&lt;bucket&gt;/&lt;name&gt;.jsonl</code> (zones trimmed to relevant ones).</p>
    <table class="data-table">
      <thead><tr><th>Name</th><th>Bucket</th><th>Criteria</th><th>Matched</th><th>Created</th><th></th></tr></thead>
      <tbody>
        ${filters.map(f => `
        <tr>
          <td><strong>${f.name}</strong></td>
          <td>${f.bucket}</td>
          <td>${filterRulesLabel(f)}${f.loot ? `, loot ${f.loot}*` : ""}</td>
          <td>${f.matched}</td>
          <td>${f.created_at}</td>
          <td>
            <a href="/filter/${f.id}" hx-get="/filter/${f.id}" hx-target="#main" hx-push-url="true" class="btn-sm">Seeds →</a>
            <button class="btn-sm danger" hx-delete="/api/filter/${f.id}" hx-swap="none"
              hx-on::after-request="htmx.ajax('GET','/filters${bucket ? `?bucket=${bucket}` : ""}',{target:'#main'})">🗑</button>
          </td>
        </tr>`).join("")}
        ${filters.length === 0 ? `<tr><td colspan="6">No saved filters. Create one from the Seeds page.</td></tr>` : ""}
      </tbody>
    </table>
  </div>`;
}

app.get("/filter/:id", (req, res) => {
  const f = db.getSeedFilter(parseInt(req.params.id));
  if (!f) return res.status(404).send(htmxPage("Not Found", "<h2>Filter not found</h2>"));
  const seeds = db.getFilterSeeds(f.id);
  page(req, res, `Filter ${f.name}`, renderFilterSeeds(f, seeds));
});

function renderFilterSeeds(f, seeds) {
  return `
  <div class="page">
    ${crumbs([{ label: "Buckets", href: "/universe" }, { label: "Seeds", href: `/seeds?bucket=${f.bucket}` }, { label: "Filtered Sets", href: `/filters?bucket=${f.bucket}` }, { label: f.name }])}
    <h2>🔎 ${f.name} <span class="badge zone-type">${f.bucket}</span> <span class="badge done">${seeds.length} seeds</span></h2>
    <p class="hint">${filterRulesLabel(f)}${f.loot ? `, loot ${f.loot}*` : ""}</p>
    <table class="data-table">
      <thead><tr><th>Seed</th><th>Loot</th><th>Zones</th><th>Specials</th><th>Pairs</th><th></th></tr></thead>
      <tbody>
        ${seeds.map(s => {
          const c = seedCriteria(s) || {};
          return `
        <tr>
          <td><strong>${s.seed}</strong></td><td><code>${s.loot}</code></td><td>${s.zone_count}</td>
          <td>${c.numSpecials ?? "—"}/6</td><td>${c.numPairs ?? "—"}/5</td>
          <td><a href="/seed/${s.seed}?filter=${f.id}" hx-get="/seed/${s.seed}?filter=${f.id}" hx-target="#main" hx-push-url="true" class="btn-sm">Zones →</a></td>
        </tr>`;}).join("")}
        ${seeds.length === 0 ? `<tr><td colspan="6">Empty set.</td></tr>` : ""}
      </tbody>
    </table>
  </div>`;
}

// ── Level 4: Seed detail — zones (relevant-only by default) ────────────

app.get("/seed/:seed", (req, res) => {
  const s = db.getSeed(parseInt(req.params.seed));
  if (!s) return res.status(404).send(htmxPage("Not Found", "<h2>Seed not found</h2>"));
  const c = seedCriteria(s) || { selectedZones: [], specials: {}, pairs: {} };
  const relevantOnly = req.query.relevant !== "0";
  const filterId = req.query.filter || null;

  const zones = db.getZonesForSeed(s.seed).filter(z => ["planet", "moon"].includes(z.zone_type));
  const shown = relevantOnly ? zones.filter(z => (c.selectedZones || []).includes(z.name)) : zones;

  // Record the drill-down: zones.jsonl reflects exactly the zones in view.
  try { jobs.writeSeedZonesFile(s, relevantOnly ? c.selectedZones : null); }
  catch (e) { console.error("writeSeedZonesFile:", e.message); }

  page(req, res, `Seed ${s.seed}`, renderSeedDetail(s, c, shown, relevantOnly, filterId));
});

function renderSeedDetail(s, c, zones, relevantOnly, filterId) {
  const back = filterId
    ? { label: "Filtered Set", href: `/filter/${filterId}` }
    : { label: "Seeds", href: `/seeds?bucket=${s.bucket}` };
  const filterQ = filterId ? `&filter=${filterId}` : "";
  const specialsList = Object.entries(c.specials || {}).map(([r, z]) => `${r.replace("se-", "").replace("-ore", "")}→${z}`).join(", ");
  const pairsList = Object.entries(c.pairs || {}).map(([p, z]) => `${p}→${z}`).join(", ");
  return `
  <div class="page">
    ${crumbs([{ label: "Buckets", href: "/universe" }, back, { label: `Seed ${s.seed}` }])}
    <h2>🌱 Seed ${s.seed} <span class="badge zone-type">${s.bucket}</span> <code>${s.loot}</code></h2>
    <p class="hint">Specials: ${specialsList || "none"}<br>Pairs: ${pairsList || "none"}${c.naqField ? `<br>Naq field: ${c.naqField}` : ""}</p>
    <div class="filter-bar">
      <label class="checkbox-label">
        <input type="checkbox" ${relevantOnly ? "checked" : ""}
          hx-get="/seed/${s.seed}?relevant=${relevantOnly ? "0" : "1"}${filterQ}" hx-target="#main" hx-push-url="true">
        Only criteria-relevant zones (writes <code>zones.jsonl</code> for the generator)
      </label>
    </div>
    <form id="zone-batch">
      <input type="hidden" name="seed" value="${s.seed}">
      <div class="batch-actions">
        <button type="button" class="btn"
          hx-post="/api/surface/batch?kind=ore" hx-include="#zone-batch input[name=seed], #zone-batch input[name=zone]:checked" hx-swap="none"
          hx-on::after-request="setTimeout(() => htmx.ajax('GET','/seed/${s.seed}?relevant=${relevantOnly ? "1" : "0"}${filterQ}',{target:'#main'}), 700)">
          ⛏ Generate ores — selected zones
        </button>
        <button type="button" class="btn btn-secondary"
          hx-post="/api/surface/batch?kind=surface" hx-include="#zone-batch input[name=seed], #zone-batch input[name=zone]:checked" hx-swap="none"
          hx-on::after-request="setTimeout(() => htmx.ajax('GET','/seed/${s.seed}?relevant=${relevantOnly ? "1" : "0"}${filterQ}',{target:'#main'}), 700)">
          🗺️ Generate surfaces (biome+water) — selected zones
        </button>
      </div>
      <table class="data-table">
        <thead><tr>
          <th><input type="checkbox" onclick="document.querySelectorAll('#zone-batch input[name=zone]').forEach(c=>c.checked=this.checked)"></th>
          <th>Zone</th><th>Type</th><th>Radius</th><th>Primary</th><th>Δv</th><th>★</th><th>Ore estimates</th><th></th>
        </tr></thead>
        <tbody>
          ${zones.map(z => {
            const relevant = (c.selectedZones || []).includes(z.name);
            const summary = zoneSurfaceSummary(s.bucket, s.seed, z.name);
            const orePng = zoneSurfacePng(s.bucket, s.seed, z.name, "ore");
            const surfPng = zoneSurfacePng(s.bucket, s.seed, z.name, "surface");
            const ore = summary ? Object.entries(summary.resources || {})
              .sort((a, b) => (b[1].amount || 0) - (a[1].amount || 0)).slice(0, 4)
              .map(([r, v]) => `${r.replace("se-", "").replace("kr-", "").replace("-ore", "")}: <strong>${v.display || fmtAmount(v.amount)}</strong>`).join(", ") : "";
            const genArgs = `hx-vals='${JSON.stringify({ zone_id: z.id, seed: s.seed, zone_name: z.name, radius: Math.round(z.radius || 500) })}'`;
            const after = `hx-on::after-request="setTimeout(() => htmx.ajax('GET','/seed/${s.seed}?relevant=${relevantOnly ? "1" : "0"}${filterQ}',{target:'#main'}), 700)"`;
            return `
          <tr>
            <td><input type="checkbox" name="zone" value="${z.name}" ${relevant ? "checked" : ""}></td>
            <td><strong>${z.name}</strong></td>
            <td><span class="badge zone-type">${z.zone_type}</span></td>
            <td>${z.radius ? Math.round(z.radius) : "—"}</td>
            <td>${z.primary_resource || "—"}</td>
            <td class="num">${z.delta_v ? Math.round(z.delta_v) : "—"}</td>
            <td>${relevant ? "⭐" : ""}</td>
            <td class="yields-cell">${summary ? `✅ ${ore}` : "—"}</td>
            <td class="row-actions">
              ${orePng ? `<a class="btn-sm" href="${orePng}" target="_blank" title="ore map">⛏</a>` : ""}
              ${surfPng ? `<a class="btn-sm" href="${surfPng}" target="_blank" title="surface map">🗺️</a>` : ""}
              <button type="button" class="btn-sm" hx-post="/api/surface/create?kind=ore" ${genArgs} hx-swap="none" ${after}>${summary ? "↻ ore" : "⛏ ore"}</button>
              <button type="button" class="btn-sm btn-secondary" hx-post="/api/surface/create?kind=surface" ${genArgs} hx-swap="none" ${after}>🗺️ surface</button>
            </td>
          </tr>`;}).join("")}
          ${zones.length === 0 ? `<tr><td colspan="9">No zones in this view.</td></tr>` : ""}
        </tbody>
      </table>
    </form>
  </div>`;
}

// ── Surface jobs + viewer ──────────────────────────────────────────────

app.get("/surfaces", (req, res) => page(req, res, "Surface Jobs", renderSurfaceJobsPage(db.getSurfaceJobs(50))));

function renderSurfaceJobsPage(jobsList) {
  return `
  <div class="page" hx-get="/surfaces" hx-trigger="every 3s" hx-swap="outerHTML">
    <h2>🗺️ Surface Generation Jobs</h2>
    <table class="data-table">
      <thead><tr><th>ID</th><th>Zone</th><th>Kind</th><th>Seed</th><th>Bucket</th><th>Status</th><th>Ore tiles</th><th>Created</th><th></th></tr></thead>
      <tbody>
        ${jobsList.map(j => `
        <tr class="row-${j.status}">
          <td>${j.id}</td><td><strong>${j.zone_name}</strong></td>
          <td><span class="badge">${j.kind || "ore"}</span></td>
          <td><a href="/seed/${j.seed}" hx-get="/seed/${j.seed}" hx-target="#main" hx-push-url="true">${j.seed}</a></td>
          <td>${j.bucket || "—"}</td>
          <td><span class="badge ${j.status}">${j.status}</span></td>
          <td>${j.ore_count || "—"}</td><td>${j.created_at}</td>
          <td>${j.status === "done" ? `<a href="/surface/${j.id}" hx-get="/surface/${j.id}" hx-target="#main" hx-push-url="true" class="btn-sm">🖼️</a>` : ""}</td>
        </tr>`).join("")}
        ${jobsList.length === 0 ? `<tr><td colspan="9">No surface jobs yet.</td></tr>` : ""}
      </tbody>
    </table>
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
      : job.status === "running" ? `<div class="loading"><p>⏳ Generating… <span hx-get="/surface/${job.id}" hx-trigger="every 2s" hx-target="closest .page" hx-swap="outerHTML"></span></p></div>` : ""}
    </div>
  </div>`;
}

// ── API ────────────────────────────────────────────────────────────────

app.post("/api/universe/create", (req, res) => {
  const units = parseInt(req.body.units || req.body.total_units) || 1;
  const conc = parseInt(req.body.concurrency) || 4;
  const k2 = req.body.k2_enabled === "on" || req.body.k2_enabled === "1";
  jobs.setUniverseConcurrency(conc);
  const ids = jobs.createUniverseBuckets(units, k2);
  res.json({ ok: true, job_ids: ids, message: `Queued ${units} × 100k buckets` });
});

app.post("/api/filter/create", (req, res) => {
  const bucket = req.body.bucket;
  const name = (req.body.name || "filter").trim();
  const loot = req.body.loot || "";
  const def = req.body.def ? db.getFilterDef(parseInt(req.body.def)) : null;
  const rules = def ? JSON.parse(def.rules) : [];
  try {
    const r = jobs.createFilteredSet(bucket, name, rules, loot);
    res.json({ ok: true, ...r });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

// ── Filter presets (reusable rulesets) ────────────────────────────────

app.get("/presets", (req, res) => page(req, res, "Filter Presets", renderPresetsPage(db.getFilterDefs())));

function renderPresetsPage(defs) {
  const kinds = ["primary", "present", "combo", "specials", "pairs"];
  return `
  <div class="page">
    ${crumbs([{ label: "Buckets", href: "/universe" }, { label: "Filter Presets" }])}
    <h2>⚙ Filter Presets</h2>
    <p class="hint">A preset is a named set of rules (all must hold). Use them on the Seeds page and save matches as a Filtered Set.</p>
    <table class="data-table">
      <thead><tr><th>Name</th><th>Rules (AND)</th><th></th></tr></thead>
      <tbody>
        ${defs.map(d => {
          let rl = "—"; try { rl = JSON.parse(d.rules).map(analyze.ruleLabel).join(" AND "); } catch (_) {}
          return `<tr>
            <td><strong>${d.name}</strong>${d.builtin ? ' <span class="badge">preset</span>' : ""}</td>
            <td>${rl}</td>
            <td>${d.builtin ? "" : `<button class="btn-sm danger" hx-delete="/api/preset/${d.id}" hx-swap="none" hx-on::after-request="htmx.ajax('GET','/presets',{target:'#main'})">🗑</button>`}</td>
          </tr>`;
        }).join("")}
      </tbody>
    </table>
    <h3>New preset</h3>
    <form id="preset-form" hx-post="/api/preset/create" hx-swap="none"
          hx-on::after-request="htmx.ajax('GET','/presets',{target:'#main'})">
      <label>Name: <input type="text" name="name" required></label>
      <div id="rules-rows">
        ${renderRuleRow(kinds)}
      </div>
      <button type="button" class="btn-sm" onclick="const d=document.getElementById('rules-rows'); d.insertAdjacentHTML('beforeend', d.firstElementChild.outerHTML);">+ rule</button>
      <button type="submit" class="btn">Create preset</button>
    </form>
  </div>`;
}

function renderRuleRow(kinds) {
  const opts = (arr, blank) => (blank ? `<option value="">${blank}</option>` : "") + arr.map(o => `<option value="${o}">${o}</option>`).join("");
  return `<div class="rule-row">
    <select name="kind">${opts(kinds)}</select>
    <select name="res">${opts([""].concat(RESOURCES).filter(Boolean), "(resource)")}</select>
    <select name="res2">${opts([""].concat(RESOURCES).filter(Boolean), "(secondary, for combo)")}</select>
    <input type="number" name="n" placeholder="n (for specials/pairs)" min="1" max="6" style="width:120px">
  </div>`;
}

app.post("/api/preset/create", (req, res) => {
  const name = (req.body.name || "").trim();
  if (!name) return res.status(400).json({ ok: false, error: "name required" });
  // rule rows arrive as parallel arrays (or scalars for a single row)
  const arr = (v) => (v === undefined ? [] : Array.isArray(v) ? v : [v]);
  const kinds = arr(req.body.kind), r1 = arr(req.body.res), r2 = arr(req.body.res2), ns = arr(req.body.n);
  const rules = [];
  for (let i = 0; i < kinds.length; i++) {
    const kind = kinds[i];
    if (kind === "primary" || kind === "present") { if (r1[i]) rules.push({ kind, res: r1[i] }); }
    else if (kind === "combo") { if (r1[i] && r2[i]) rules.push({ kind, res: r1[i], res2: r2[i] }); }
    else if (kind === "specials" || kind === "pairs") { const n = parseInt(ns[i]); if (n > 0) rules.push({ kind, n }); }
  }
  if (rules.length === 0) return res.status(400).json({ ok: false, error: "no valid rules" });
  const id = db.createFilterDef(name, rules);
  res.json({ ok: true, id, rules });
});

app.delete("/api/preset/:id", (req, res) => { db.deleteFilterDef(parseInt(req.params.id)); res.json({ ok: true }); });

app.delete("/api/filter/:id", (req, res) => {
  db.deleteSeedFilter(parseInt(req.params.id));
  res.json({ ok: true });
});

// Queue jobs for one zone. kind=ore → a single ore job. kind=surface → one job
// per grid cell that intersects the disk (parallel tiles, stitched on complete).
function queueZone(zone, seed, kind) {
  const radius = Math.round(zone.radius || 500);
  if (kind !== "surface") {
    return [db.createSurfaceJob({ zone_id: zone.id, seed, zone_name: zone.name, radius, kind: "ore" })];
  }
  const n = jobs.surfaceGridFor(radius);
  const cells = jobs.planSurfaceCells(radius, n);
  return cells.map(cell => db.createSurfaceJob({
    zone_id: zone.id, seed, zone_name: zone.name, radius,
    kind: "surface", grid_n: n, grid_cell: n > 1 ? cell : -1,
  }));
}

app.post("/api/surface/create", (req, res) => {
  const kind = req.query.kind === "surface" ? "surface" : "ore";
  const seed = parseInt(req.body.seed);
  const zone = db.getZonesForSeed(seed).find(z => z.id === parseInt(req.body.zone_id));
  if (!zone) return res.status(404).json({ ok: false, error: "zone not found" });
  const ids = queueZone(zone, seed, kind);
  res.json({ ok: true, kind, queued: ids.length, job_ids: ids });
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
  jobs.startPolling();
});

process.on("SIGINT", () => { jobs.stopPolling(); process.exit(0); });
process.on("SIGTERM", () => { jobs.stopPolling(); process.exit(0); });
