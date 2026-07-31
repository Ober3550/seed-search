#!/usr/bin/env node
// Lean READ-ONLY explorer: browse the seeds/zones the generator wrote to
// Postgres (Cloud SQL). No job system — that's re-added later. Uses pgdb.js
// (read-only `explorer_ro` role). Run:  node read-server.js   (PORT env, def 3100)
const express = require("express");
const path = require("path");
const db = require("./pgdb");

const app = express();
const PORT = process.env.READ_PORT || process.env.PORT || 3100;
app.use("/static", express.static(path.join(__dirname, "public")));

const esc = (s) => String(s ?? "").replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
const nm = (r) => (r ? String(r).replace(/^se-/, "").replace(/^kr-/, "").replace(/-ore$/, "") : "—");
const dv = (v) => (v == null ? "—" : v >= 10000000 ? "none" : Number(v).toLocaleString());

function page(title, body) {
  return `<!doctype html><html><head><meta charset="utf-8"><title>${esc(title)}</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="/static/style.css">
<style>
  body{font-family:system-ui,sans-serif;margin:0;padding:1rem 1.5rem;max-width:1100px}
  table{border-collapse:collapse;width:100%;font-size:14px}
  th,td{padding:4px 8px;border-bottom:1px solid #8883;text-align:right}
  th:first-child,td:first-child,th:nth-child(2),td:nth-child(2){text-align:left}
  a{color:#4ea1ff;text-decoration:none} a:hover{text-decoration:underline}
  .bar{display:flex;gap:.75rem;align-items:end;flex-wrap:wrap;margin:.5rem 0 1rem}
  .bar label{font-size:12px;color:#888;display:flex;flex-direction:column}
  input,select{padding:3px 6px}
  .muted{color:#888} .pill{background:#4ea1ff22;border-radius:4px;padding:0 6px}
</style></head><body>${body}</body></html>`;
}

// ── seeds list ──────────────────────────────────────────────────────────
app.get("/", (req, res) => res.redirect("/seeds"));

app.get("/seeds", async (req, res) => {
  try {
    const f = {
      seed: req.query.seed, k2: req.query.k2,
      npl_min: req.query.npl_min, npl_max: req.query.npl_max,
      sort: req.query.sort, page: req.query.page, pageSize: 100,
    };
    const [rows, total] = await Promise.all([db.getSeeds(f), db.countSeeds(f)]);
    const pageN = Math.max(0, Number(req.query.page) || 0);
    const sort = db.ORDERS[req.query.sort] ? req.query.sort : db.DEFAULT_ORDER;
    const sortOpts = Object.keys(db.ORDERS).map((k) => `<option value="${k}"${k === sort ? " selected" : ""}>${k}</option>`).join("");
    const qs = (extra) => {
      const p = new URLSearchParams({ ...req.query, ...extra });
      return "?" + p.toString();
    };
    const th = "<tr><th>Seed</th><th>K2</th><th>Planets</th><th>P+M</th><th>Naq Δv</th><th>Field Δv</th><th>Enemy</th><th>Water%</th><th>Hostile%</th><th>Score</th></tr>";
    const body = rows.map((s) => `<tr>
      <td><a href="/seed/${s.seed}">${s.seed}</a></td>
      <td>${s.k2 ? "✓" : ""}</td><td>${s.npl ?? "—"}</td><td>${s.npm ?? "—"}</td>
      <td>${dv(s.naqdv)}</td><td>${dv(s.fdv)}</td><td>${s.ed ?? "—"}</td>
      <td>${s.wp ?? "—"}</td><td>${s.ef ?? "—"}</td><td>${s.score ?? "—"}</td></tr>`).join("");
    res.send(page("Seeds", `
      <h1>Seeds <span class="muted">(${total.toLocaleString()} in Cloud SQL)</span></h1>
      <form class="bar" method="get">
        <label>seed<input name="seed" value="${esc(req.query.seed || "")}" size="10"></label>
        <label>K2<select name="k2"><option value="">any</option>
          <option value="1"${req.query.k2 == "1" ? " selected" : ""}>yes</option>
          <option value="0"${req.query.k2 == "0" ? " selected" : ""}>no</option></select></label>
        <label>planets ≥<input name="npl_min" value="${esc(req.query.npl_min || "")}" size="3"></label>
        <label>≤<input name="npl_max" value="${esc(req.query.npl_max || "")}" size="3"></label>
        <label>sort<select name="sort">${sortOpts}</select></label>
        <button>apply</button>
      </form>
      <table><thead>${th}</thead><tbody>${body || `<tr><td colspan="10" class="muted">no seeds match</td></tr>`}</tbody></table>
      <p class="bar">
        ${pageN > 0 ? `<a href="${qs({ page: pageN - 1 })}">← prev</a>` : `<span class="muted">← prev</span>`}
        <span class="muted">page ${pageN + 1}</span>
        ${rows.length === 100 ? `<a href="${qs({ page: pageN + 1 })}">next →</a>` : `<span class="muted">next →</span>`}
      </p>`));
  } catch (e) { res.status(500).send(page("error", `<pre>${esc(e.stack || e.message)}</pre>`)); }
});

// ── seed detail ─────────────────────────────────────────────────────────
app.get("/seed/:seed", async (req, res) => {
  try {
    const seed = Number(req.params.seed);
    const [s, zones] = await Promise.all([db.getSeed(seed), db.getZones(seed)]);
    if (!s) return res.status(404).send(page("not found", `<p>seed ${seed} not in DB. <a href="/seeds">back</a></p>`));
    const zrows = zones.map((z) => `<tr>
      <td>${esc(z.name)}</td><td>${esc(z.kind)}</td><td>${esc(z.star || "—")}</td>
      <td>${esc(z.parent || "—")}</td><td>${nm(z.primary)}</td>
      <td>${z.radius == null ? "—" : Math.round(z.radius)}</td><td>${dv(z.dv)}</td>
      <td>${esc(z.temperature || "")}</td><td>${esc(z.water || "")}</td><td>${esc(z.enemy || "")}</td></tr>`).join("");
    res.send(page(`Seed ${seed}`, `
      <p><a href="/seeds">← seeds</a></p>
      <h1>Seed ${seed} ${s.k2 ? '<span class="pill">K2</span>' : ""}</h1>
      <p class="muted">planets ${s.npl} · P+M ${s.npm} · naq Δv ${dv(s.naqdv)} · field Δv ${dv(s.fdv)} · enemy ${s.ed} · water% ${s.wp} · hostile% ${s.ef} · vault ${esc(s.vault_loot || "")}</p>
      <h2>Zones <span class="muted">(${zones.length})</span></h2>
      <table><thead><tr><th>Name</th><th>Kind</th><th>Star</th><th>Parent</th><th>Primary</th><th>Radius</th><th>Δv</th><th>Temp</th><th>Water</th><th>Enemy</th></tr></thead>
      <tbody>${zrows}</tbody></table>`));
  } catch (e) { res.status(500).send(page("error", `<pre>${esc(e.stack || e.message)}</pre>`)); }
});

app.get("/healthz", async (req, res) => {
  try { res.json({ ok: true, seeds: await db.countSeeds() }); }
  catch (e) { res.status(500).json({ ok: false, error: e.message }); }
});

app.listen(PORT, () => console.log(`read-only explorer on http://localhost:${PORT}  (reading Cloud SQL via explorer_ro)`));
