#!/usr/bin/env node
// Lean READ-ONLY explorer: browse the seeds/zones the generator wrote to
// Postgres (Cloud SQL). No job system — that's re-added later. Uses pgdb.js
// (read-only `explorer_ro` role) and the existing public/style.css shell.
// Run:  node read-server.js   (PORT env, default 3100)
const express = require("express");
const path = require("path");
const db = require("./pgdb");

const app = express();
const PORT = process.env.READ_PORT || process.env.PORT || 3100;
app.use("/static", express.static(path.join(__dirname, "public")));

const esc = (s) => String(s ?? "").replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
const nm = (r) => (r ? String(r).replace(/^se-/, "").replace(/^kr-/, "").replace(/-ore$/, "") : "—");
const dv = (v) => (v == null ? "—" : v >= 10000000 ? "none" : Number(v).toLocaleString());

// Same shell as the main GUI (.app > .sidebar + main) so style.css applies.
function page(title, content) {
  return `<!DOCTYPE html><html lang="en"><head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${esc(title)} — SE Explorer</title>
  <link rel="stylesheet" href="/static/style.css">
</head><body>
  <div class="app">
    <nav class="sidebar">
      <h1>🌌 SE Explorer</h1>
      <ul class="nav-links">
        <li><a href="/seeds">Seeds</a></li>
      </ul>
      <div class="sidebar-footer"><small>read-only · Cloud SQL<br>generator → db → explorer</small></div>
    </nav>
    <main id="main">${content}</main>
  </div>
</body></html>`;
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
    const cur = db.ORDERS[req.query.sort] ? req.query.sort : db.DEFAULT_ORDER;
    const qs = (extra) => "?" + new URLSearchParams({ ...req.query, ...extra }).toString();

    // Clickable sort headers (toggle asc/desc), matching the main GUI's feel.
    const sortTh = (label, col, title = "") => {
      const asc = `${col}_asc`, desc = `${col}_desc`;
      const next = cur === desc ? asc : desc;
      const arrow = cur === desc ? " ▾" : cur === asc ? " ▴" : "";
      return `<th class="sortable"${title ? ` title="${esc(title)}"` : ""}><a href="${qs({ sort: next, page: 0 })}">${label}${arrow}</a></th>`;
    };

    const bodyRows = rows.map((s) => `<tr>
      <td><a href="/seed/${s.seed}">${s.seed}</a></td>
      <td>${s.k2 ? "✓" : ""}</td><td>${s.npl ?? "—"}</td><td>${s.npm ?? "—"}</td>
      <td>${dv(s.naqdv)}</td><td>${dv(s.fdv)}</td><td>${s.ed ?? "—"}</td>
      <td>${s.wp ?? "—"}</td><td>${s.ef ?? "—"}</td><td>${s.score ?? "—"}</td></tr>`).join("");

    res.send(page("Seeds", `
      <h2>Seeds <small style="color:var(--muted)">${total.toLocaleString()} in Cloud SQL</small></h2>
      <form method="get" style="display:flex;gap:1rem;align-items:flex-end;flex-wrap:wrap;margin:0 0 1rem">
        <label>Seed<br><input name="seed" value="${esc(req.query.seed || "")}" placeholder="search"></label>
        <label>K2<br><select name="k2"><option value="">any</option>
          <option value="1"${req.query.k2 == "1" ? " selected" : ""}>yes</option>
          <option value="0"${req.query.k2 == "0" ? " selected" : ""}>no</option></select></label>
        <label>Planets ≥<br><input type="number" name="npl_min" value="${esc(req.query.npl_min || "")}"></label>
        <label>≤<br><input type="number" name="npl_max" value="${esc(req.query.npl_max || "")}"></label>
        <input type="hidden" name="sort" value="${esc(cur)}">
        <button type="submit" class="btn">Apply</button>
      </form>
      <table class="data-table" id="seeds-table">
        <thead><tr>
          ${sortTh("Seed", "seed")}<th>K2</th>
          ${sortTh("Planets", "npl", "Calidus planets (incl. Nauvis)")}
          ${sortTh("P+M", "npm", "Calidus planets + moons")}
          ${sortTh("Naq Δv", "naqdv", "Δv to nearest naquium-primary field")}
          ${sortTh("Field Δv", "fdv", "Δv to nearest any asteroid field")}
          ${sortTh("Enemy", "ed", "signed enemy value")}
          ${sortTh("Water%", "wp")}${sortTh("Hostile%", "ef")}${sortTh("Score", "score")}
        </tr></thead>
        <tbody>${bodyRows || `<tr><td colspan="10" style="color:var(--muted)">no seeds match</td></tr>`}</tbody>
      </table>
      <p style="display:flex;gap:1rem;align-items:center;margin-top:1rem">
        ${pageN > 0 ? `<a href="${qs({ page: pageN - 1 })}">← prev</a>` : `<span style="color:var(--muted)">← prev</span>`}
        <span style="color:var(--muted)">page ${pageN + 1}</span>
        ${rows.length === 100 ? `<a href="${qs({ page: pageN + 1 })}">next →</a>` : `<span style="color:var(--muted)">next →</span>`}
      </p>`));
  } catch (e) { res.status(500).send(page("error", `<pre>${esc(e.stack || e.message)}</pre>`)); }
});

// ── seed detail ─────────────────────────────────────────────────────────
app.get("/seed/:seed", async (req, res) => {
  try {
    const seed = Number(req.params.seed);
    const [s, zones] = await Promise.all([db.getSeed(seed), db.getZones(seed)]);
    if (!s) return res.status(404).send(page("not found", `<h2>Seed ${seed} not in DB</h2><p><a href="/seeds">← back to seeds</a></p>`));
    const zrows = zones.map((z) => `<tr>
      <td>${esc(z.name)}</td><td>${esc(z.kind)}</td><td>${esc(z.star || "—")}</td>
      <td>${esc(z.parent || "—")}</td><td>${nm(z.primary)}</td>
      <td>${z.radius == null ? "—" : Math.round(z.radius)}</td><td>${dv(z.dv)}</td>
      <td>${esc(z.temperature || "")}</td><td>${esc(z.water || "")}</td><td>${esc(z.enemy || "")}</td></tr>`).join("");
    res.send(page(`Seed ${seed}`, `
      <p><a href="/seeds">← seeds</a></p>
      <h2>Seed ${seed} ${s.k2 ? '<span style="color:var(--purple)">[K2]</span>' : ""}</h2>
      <p style="color:var(--muted)">planets ${s.npl} · P+M ${s.npm} · naq Δv ${dv(s.naqdv)} · field Δv ${dv(s.fdv)} · enemy ${s.ed} · water% ${s.wp} · hostile% ${s.ef} · vault ${esc(s.vault_loot || "—")}</p>
      <h3>Zones <small style="color:var(--muted)">${zones.length}</small></h3>
      <table class="data-table" id="zone-table">
        <thead><tr><th>Name</th><th>Kind</th><th>Star</th><th>Parent</th><th>Primary</th><th>Radius</th><th>Δv</th><th>Temp</th><th>Water</th><th>Enemy</th></tr></thead>
        <tbody>${zrows}</tbody></table>`));
  } catch (e) { res.status(500).send(page("error", `<pre>${esc(e.stack || e.message)}</pre>`)); }
});

app.get("/healthz", async (req, res) => {
  try { res.json({ ok: true, seeds: await db.countSeeds() }); }
  catch (e) { res.status(500).json({ ok: false, error: e.message }); }
});

app.listen(PORT, () => console.log(`read-only explorer on http://localhost:${PORT}  (reading Cloud SQL via explorer_ro)`));
