// Client-side seed analysis. Generates a seed's universe in the browser (WASM),
// estimates each zone's ore client-side, and renders the zone table — with NO
// backend per-seed calls (only static assets: universe.wasm, ore-model.json).
// Clicking a row opens that surface's dedicated page (/surface/:seed/:name),
// which generates terrain + ore in the browser on its own route.
(function () {
  var estimator = null;   // { estimateZoneOre }
  var MODS = { base: "Base", sa: "Space Age", se: "Space Exploration", k2se: "SE + K2" };
  var modQ = new URLSearchParams(location.search).get("mod");
  if (modQ === "se+k2") modQ = "k2se"; // legacy alias
  var state = { mod: MODS[modQ] ? modQ : (window.__ANALYZE_MOD__ || "k2se"), k2: true, zones: [], sortKey: "dv", sortDir: "asc", q: "", calidus: true };
  state.k2 = state.mod === "k2se";

  function loadEstimator() {
    if (estimator) return Promise.resolve(estimator);
    return fetch("/static/ore-model.json").then(function (r) { return r.json(); })
      .then(function (m) { estimator = window.createEstimator(m); return estimator; });
  }

  var GEN = { planet: 1, moon: 1, "asteroid-field": 1 };

  // Space Age / base surfaces — static row descriptors (the SA data stage has
  // no universe generator; these five surfaces always exist for any seed).
  // kind: "se" = SE universe zone; "surface-nauvis" = Nauvis via the game's
  // default map-gen path (terrain + ores); "sa" = SA planet terrain (ok when
  // the engine has every op the planet's expressions need).
  var SA_SURFACES = [
    { n: "Nauvis",   icon: "🌍", t: "planet", water: "some", enemy: "some", kind: "surface-nauvis" },
    { n: "Vulcanus", icon: "🌋", t: "planet", water: "none", enemy: "yes",  kind: "sa", planet: "vulcanus", ok: false, why: "needs the multisample autoplace op (not ported yet)" },
    { n: "Fulgora",  icon: "⚡", t: "planet", water: "none", enemy: "none", kind: "sa", planet: "fulgora",  ok: true },
    { n: "Gleba",    icon: "🍄", t: "planet", water: "some", enemy: "yes",  kind: "sa", planet: "gleba",    ok: false, why: "needs spot_noise sub-expression evaluation (not ported yet)" },
    { n: "Aquilo",   icon: "🧊", t: "planet", water: "none", enemy: "none", kind: "sa", planet: "aquilo",   ok: false, why: "needs spot_noise sub-expression evaluation (not ported yet)" }
  ];

  function listSurfaces() {
    // base → Nauvis only; sa → the five surfaces (Nauvis + 4 SA planets).
    var defs = state.mod === "base" ? SA_SURFACES.slice(0, 1) : SA_SURFACES;
    state.zones = defs.map(function (d) {
      var z = { n: d.n, icon: d.icon, t: d.t, water: d.water, enemy: d.enemy, p: null, r: null, infinity: true, kind: d.kind };
      if (d.kind === "sa") { z.planet = d.planet; z.ok = !!d.ok; z.why = d.why || ""; }
      else if (d.kind === "surface-nauvis") { z.nauvis = true; z.s = state.seed || 0; z.r = 5000; }
      return z;
    });
    renderTable();
    var st = document.getElementById("gen-status");
    if (st) st.textContent = "";
  }
  function nm(r) { return r.replace(/^se-/, "").replace(/^kr-/, "").replace(/-ore$/, ""); }
  function fmt(n) { return n >= 1e9 ? (n / 1e9).toFixed(2) + "B" : n >= 1e6 ? (n / 1e6).toFixed(1) + "M" : Math.round(n); }
  function fmtDv(v) { return v == null || isNaN(v) ? "—" : v >= 1e6 ? (v / 1e6).toFixed(2) + "M" : v >= 1000 ? (v / 1000).toFixed(1) + "k" : String(v); }
  function cw(w) { return (w || "none").replace(/^water[_-]?/, "") || "none"; }
  function ce(e) { return (e || "none").replace(/^enemy[_-]?/, "").replace("very_", "v") || "none"; }
  function esc(s) { return String(s).replace(/[&<>"]/g, function (c) { return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]; }); }

  // Map a WASM zone to the estimator's shape and estimate its ore.
  function estimateZone(z) {
    return estimator.estimateZoneOre(
      { name: z.n, zone_type: z.t, radius: z.r, water: z.water, primary_resource: z.p, resource_scores: z.rs },
      { k2: state.k2 });
  }

  function resChips(est) {
    var keys = Object.keys(est).sort(function (a, b) { return est[b] - est[a]; });
    if (!keys.length) return '<span class="hint">—</span>';
    return keys.map(function (r) {
      return '<span class="res-chip est" title="calibrated estimate">' + nm(r) + ' <strong>~' + fmt(est[r]) + "</strong></span>";
    }).join(" ");
  }

  function applyMod() {} // mod-mode element was removed from the /seed layout

  function sortZones(rows) {
    var k = state.sortKey, dir = state.sortDir === "asc" ? 1 : -1;
    return rows.slice().sort(function (a, b) {
      var va, vb;
      if (k === "radius") { va = a.r || 0; vb = b.r || 0; return (va - vb) * dir; }
      if (k === "dv") { va = a.dv == null ? -1 : a.dv; vb = b.dv == null ? -1 : b.dv; return (va - vb) * dir; }
      if (k === "primary") { va = a.p || ""; vb = b.p || ""; }
      else if (k === "type") { va = a.t; vb = b.t; }
      else { va = a.n; vb = b.n; }
      return String(va).localeCompare(String(vb)) * dir;
    });
  }

  // Dedicated route for generating one surface on its own page.
  function surfHref(z) {
    if (state.seed == null) return null;
    var u = "/surface/" + state.seed + "/" + encodeURIComponent(z.n) + "?mod=" + encodeURIComponent(state.mod);
    // Open at the zone's ACTUAL radius (disk-cropped to it). Asteroid fields
    // carry no radius in the universe data — open them at 5000 (SE's default
    // field radius, same as the Nauvis default). Max SE zone radius is 10000,
    // which is also the page slider max; ?r is clamped to that only.
    var r0 = z.r ? Math.round(z.r) : (z.t === "asteroid-field" ? 5000 : null);
    if (r0) u += "&r=" + Math.min(r0, 10000);
    return u;
  }
  // True when the row can open a surface (seed present + engine support).
  function rowOpen(z) {
    if (z.kind === "sa") return !!z.ok && state.seed != null;
    return state.seed != null;
  }

  function renderTable() {
    var q = state.q.toLowerCase();
    var rows = state.zones.filter(function (z) {
      // SA/base planet rows pass via GEN (they're "planet" type); SE rows only
      // when their zone type is generatable.
      if (!GEN[z.t]) return false;
      // Default view = the Calidus home system PLUS every asteroid field:
      // fields orbit other stars (incl. the naquium-primary one), so a strict
      // Calidus membership test would drop all of them.
      if (state.calidus && z.kind === "se" && z.c !== 1 && z.t !== "asteroid-field") return false;
      if (!q) return true;
      return (z.n + " " + z.t + " " + (z.p || "")).toLowerCase().indexOf(q) !== -1;
    });
    rows = sortZones(rows);
    var body = rows.map(function (z) {
      var estCell;
      if (z.kind === "se") estCell = resChips(estimateZone(z));
      else estCell = '<span class="hint" title="ore estimates for this surface are not modelled yet">—</span>';
      var openCell;
      var gated = null;
      if (z.kind === "sa" && !z.ok) {
        gated = z.why || "not supported yet";
        openCell = '<button type="button" class="btn-sm" disabled title="' + esc(z.n) + ': ' + esc(gated) + '">🚧</button>';
      } else {
        var href = surfHref(z);
        var glyph = z.kind === "sa" ? "🪐" : "🗺️";
        var ttl = z.kind === "sa"
          ? "Open " + esc(z.n) + " terrain on its own page"
          : "Open " + esc(z.n) + " surface on its own page";
        openCell = href
          ? '<a class="btn-sm" href="' + esc(href) + '" title="' + ttl + '">' + glyph + '</a>'
          : '<button type="button" class="btn-sm" title="enter a seed first">' + glyph + "</button>";
      }
      return '<tr' + (rowOpen(z) ? ' data-href="' + esc(surfHref(z)) + '"' : ' class="row-closed"' + (gated ? ' data-why="' + esc(gated) + '"' : '')) + ">" +
        "<td><strong>" + (z.icon ? z.icon + " " : "") + esc(z.n) + "</strong></td>" +
        '<td><span class="badge zone-type">' + z.t + "</span></td>" +
        "<td>" + (z.infinity ? "∞" : (z.r ? Math.round(z.r) : "—")) + "</td>" +
        "<td class=\"num\">" + fmtDv(z.dv) + "</td>" +
        "<td>" + cw(z.water) + "</td>" +
        "<td>" + ce(z.enemy) + "</td>" +
        "<td>" + (z.p ? nm(z.p) : "—") + "</td>" +
        '<td class="yields-cell">' + estCell + "</td>" +
        "<td>" + openCell + "</td>" +
        "</tr>";
    }).join("");
    document.getElementById("zt-body").innerHTML = body || '<tr><td colspan="9" class="hint">No generatable zones.</td></tr>';
    var zc = document.getElementById("zt-count");
    if (zc) zc.textContent = rows.length +
      (state.zones.length && state.zones[0].kind === "se" ? " zones" : " surfaces");
    document.querySelectorAll("#zt-head .sort-ind").forEach(function (s) { s.textContent = ""; });
    var active = document.querySelector('#zt-head th[data-key="' + state.sortKey + '"] .sort-ind');
    if (active) active.textContent = state.sortDir === "asc" ? " ▲" : " ▼";
  }

  function generate() {
    var seedVal = parseInt(document.getElementById("seed-input").value, 10);
    if (!Number.isFinite(seedVal) || seedVal < 0) return;
    state.seed = seedVal;
    var q = "mod=" + encodeURIComponent(state.mod);
    history.replaceState(null, "", "/seed?" + q + "&seed=" + seedVal);
    var status = document.getElementById("gen-status");
    if (status) status.textContent = "";
    // base / sa: the surfaces are static (no universe to enumerate) — list them.
    if (state.mod === "base" || state.mod === "sa") {
      listSurfaces();
      return;
    }
    status.textContent = "generating…";
    Promise.all([window.generateUniverse(seedVal, state.k2), loadEstimator()])
      .then(function (res) {
        var uni = res[0];
        var zones = uni.z.slice();
        // Synthetic Nauvis (the universe generator never emits it): default-FSR
        // planet, r5000. Estimated client-side (base ores + K2 rare-metal);
        // surface generation uses the game's default map-gen settings (nauvis).
        zones.unshift({ n: "Nauvis", t: "planet", s: seedVal, r: 5000, water: "none", enemy: "none", c: 1, dv: 0, nauvis: true, kind: "se" });
        zones.forEach(function (z) { z.kind = "se"; });
        state.zones = zones;
        status.textContent = uni.z.length + " zones · generated client-side";
        renderTable();
      })
      .catch(function (e) { if (status) status.textContent = "error: " + e.message; console.error(e); });
  }

  function bind() {
    document.getElementById("gen-btn").addEventListener("click", generate);
    document.getElementById("seed-input").addEventListener("keydown", function (e) { if (e.key === "Enter") generate(); });
    document.getElementById("zt-search").addEventListener("input", function (e) { state.q = e.target.value; renderTable(); });
    var calEl = document.getElementById("cal-filter");
    if (calEl) calEl.addEventListener("change", function (e) { state.calidus = e.target.checked; renderTable(); });
    document.getElementById("zt-head").addEventListener("click", function (e) {
      var thEl = e.target.closest("th[data-key]"); if (!thEl) return;
      var k = thEl.dataset.key;
      state.sortDir = state.sortKey === k && state.sortDir === "asc" ? "desc" : "asc";
      state.sortKey = k; renderTable();
    });
    document.getElementById("zt-body").addEventListener("click", function (e) {
      // Ignore clicks on disabled cells but let anything else on an open row
      // navigate (whole row opens the surface's own page).
      if (e.target.closest("button[disabled]")) return;
      if (e.target.closest("a")) return; // links handle themselves
      var row = e.target.closest("tr[data-href]");
      if (row) { location.href = row.dataset.href; return; }
      // Rows listed before a seed is entered (or not yet supported): explain.
      var closed = e.target.closest("tr.row-closed");
      if (closed) {
        var st = document.getElementById("gen-status");
        if (st) st.textContent = closed.getAttribute("data-why") || "enter a seed first";
      }
    });
    window.preloadUniverseWasm && window.preloadUniverseWasm();
    applyMod();
    // Auto-generate / list if a seed was in the URL (/seed?seed=...).
    var pre = window.__ANALYZE_SEED__;
    if (pre != null) {
      document.getElementById("seed-input").value = pre;
      generate();
    } else if (state.mod === "sa" || state.mod === "base") {
      listSurfaces();  // static surface lists need no seed
    }
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", bind);
  else bind();
})();
