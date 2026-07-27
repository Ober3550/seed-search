const express = require("express");
const path = require("path");
const fs = require("fs");
const db = require("./db");
const jobs = require("./job-manager");

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

function zoneSurfaceSummary(bucket, seed, zoneName) {
  try {
    return JSON.parse(fs.readFileSync(path.join(jobs.seedDir(bucket, seed), zoneName, "summary.json"), "utf8"));
  } catch (_) { return null; }
}
function zoneSurfacePng(bucket, seed, zoneName) {
  const rel = path.join(bucket, `seed_${seed}`, zoneName, "ore.png");
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
  const min_specials = parseInt(req.query.min_specials || "0");
  const min_pairs = parseInt(req.query.min_pairs || "0");
  const loot = req.query.loot || "";

  let seeds = db.getSeeds({ bucket: bucket || undefined, loot: loot || undefined });
  seeds = seeds.filter(s => {
    const c = seedCriteria(s); if (!c) return min_specials === 0 && min_pairs === 0;
    return c.numSpecials >= min_specials && c.numPairs >= min_pairs;
  });
  const buckets = [...new Set(db.getUniverseJobs().filter(j => j.status === "done").map(j => j.bucket))];
  page(req, res, "Seeds", renderSeedsPage(seeds, buckets, { bucket, min_specials, min_pairs, loot }));
});

function renderSeedsPage(seeds, buckets, f) {
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
        <label>Min specials:
          <select name="min_specials" hx-get="/seeds" hx-target="closest .page" hx-swap="outerHTML" hx-include="#seed-filters" hx-trigger="change">
            ${[0,1,2,3,4,5,6].map(n => `<option value="${n}" ${f.min_specials === n ? "selected" : ""}>${n}</option>`).join("")}
          </select></label>
        <label>Min pairs:
          <select name="min_pairs" hx-get="/seeds" hx-target="closest .page" hx-swap="outerHTML" hx-include="#seed-filters" hx-trigger="change">
            ${[0,1,2,3,4,5].map(n => `<option value="${n}" ${f.min_pairs === n ? "selected" : ""}>${n}</option>`).join("")}
          </select></label>
        <input type="text" name="loot" placeholder="Loot prefix" value="${f.loot}"
          hx-get="/seeds" hx-target="closest .page" hx-swap="outerHTML" hx-include="#seed-filters" hx-trigger="keyup changed delay:400ms">
      </form>
      ${f.bucket ? `
      <form class="save-filter" hx-post="/api/filter/create" hx-swap="none"
            hx-on::after-request="htmx.ajax('GET','/filters?bucket=${f.bucket}',{target:'#main'})">
        <input type="hidden" name="bucket" value="${f.bucket}">
        <input type="hidden" name="min_specials" value="${f.min_specials}">
        <input type="hidden" name="min_pairs" value="${f.min_pairs}">
        <input type="hidden" name="loot" value="${f.loot}">
        <input type="text" name="name" placeholder="Save these as a filtered set…" required>
        <button type="submit" class="btn">💾 Save filtered set (${seeds.length})</button>
      </form>` : `<p class="hint">Pick a bucket to save a filtered set.</p>`}
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
          <td>≥${f.min_specials} specials, ≥${f.min_pairs} pairs${f.loot ? `, loot ${f.loot}*` : ""}</td>
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
    <p class="hint">≥${f.min_specials} specials, ≥${f.min_pairs} pairs${f.loot ? `, loot ${f.loot}*` : ""}</p>
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
    <table class="data-table">
      <thead><tr><th>Zone</th><th>Type</th><th>Radius</th><th>Primary</th><th>Δv</th><th>★</th><th>Ore estimates</th><th></th></tr></thead>
      <tbody>
        ${zones.map(z => {
          const relevant = (c.selectedZones || []).includes(z.name);
          const summary = zoneSurfaceSummary(s.bucket, s.seed, z.name);
          const png = zoneSurfacePng(s.bucket, s.seed, z.name);
          const ore = summary ? Object.entries(summary.resources || {})
            .sort((a, b) => (b[1].amount || 0) - (a[1].amount || 0)).slice(0, 4)
            .map(([r, v]) => `${r.replace("se-", "").replace("kr-", "").replace("-ore", "")}: <strong>${v.display || fmtAmount(v.amount)}</strong>`).join(", ") : "";
          return `
        <tr>
          <td><strong>${z.name}</strong></td>
          <td><span class="badge zone-type">${z.zone_type}</span></td>
          <td>${z.radius ? Math.round(z.radius) : "—"}</td>
          <td>${z.primary_resource || "—"}</td>
          <td class="num">${z.delta_v ? Math.round(z.delta_v) : "—"}</td>
          <td>${relevant ? "⭐" : ""}</td>
          <td class="yields-cell">${summary ? `✅ ${ore}` : "—"}</td>
          <td>
            ${png ? `<a class="btn-sm" href="${png}" target="_blank">🖼️</a>` : ""}
            <form style="display:inline" hx-post="/api/surface/create" hx-swap="none"
                  hx-on::after-request="setTimeout(() => htmx.ajax('GET','/seed/${s.seed}?relevant=${relevantOnly ? "1" : "0"}${filterQ}',{target:'#main'}), 700)">
              <input type="hidden" name="zone_id" value="${z.id}">
              <input type="hidden" name="seed" value="${s.seed}">
              <input type="hidden" name="zone_name" value="${z.name}">
              <input type="hidden" name="radius" value="${Math.round(z.radius || 500)}">
              <button type="submit" class="btn-sm">${summary ? "↻ Regen" : "⚙ Generate"}</button>
            </form>
          </td>
        </tr>`;}).join("")}
        ${zones.length === 0 ? `<tr><td colspan="8">No zones in this view.</td></tr>` : ""}
      </tbody>
    </table>
  </div>`;
}

// ── Surface jobs + viewer ──────────────────────────────────────────────

app.get("/surfaces", (req, res) => page(req, res, "Surface Jobs", renderSurfaceJobsPage(db.getSurfaceJobs(50))));

function renderSurfaceJobsPage(jobsList) {
  return `
  <div class="page" hx-get="/surfaces" hx-trigger="every 3s" hx-swap="outerHTML">
    <h2>🗺️ Surface Generation Jobs</h2>
    <table class="data-table">
      <thead><tr><th>ID</th><th>Zone</th><th>Seed</th><th>Bucket</th><th>Status</th><th>Ore tiles</th><th>Created</th><th></th></tr></thead>
      <tbody>
        ${jobsList.map(j => `
        <tr class="row-${j.status}">
          <td>${j.id}</td><td><strong>${j.zone_name}</strong></td>
          <td><a href="/seed/${j.seed}" hx-get="/seed/${j.seed}" hx-target="#main" hx-push-url="true">${j.seed}</a></td>
          <td>${j.bucket || "—"}</td>
          <td><span class="badge ${j.status}">${j.status}</span></td>
          <td>${j.ore_count || "—"}</td><td>${j.created_at}</td>
          <td>${j.status === "done" ? `<a href="/surface/${j.id}" hx-get="/surface/${j.id}" hx-target="#main" hx-push-url="true" class="btn-sm">🖼️</a>` : ""}</td>
        </tr>`).join("")}
        ${jobsList.length === 0 ? `<tr><td colspan="8">No surface jobs yet.</td></tr>` : ""}
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
  const crit = {
    min_specials: parseInt(req.body.min_specials || "0"),
    min_pairs: parseInt(req.body.min_pairs || "0"),
    loot: req.body.loot || "",
  };
  try {
    const r = jobs.createFilteredSet(bucket, name, crit);
    res.json({ ok: true, ...r });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

app.delete("/api/filter/:id", (req, res) => {
  db.deleteSeedFilter(parseInt(req.params.id));
  res.json({ ok: true });
});

app.post("/api/surface/create", (req, res) => {
  const jobId = db.createSurfaceJob({
    zone_id: parseInt(req.body.zone_id),
    seed: parseInt(req.body.seed),
    zone_name: req.body.zone_name,
    radius: parseInt(req.body.radius) || 500,
    sample_step: 1,
  });
  res.json({ ok: true, job_id: jobId });
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
