// Client-side seed analysis. Generates a seed's universe in the browser (WASM),
// estimates each zone's ore client-side, and renders the zone table — with NO
// backend per-seed calls (only static assets: universe.wasm, surface.wasm,
// ore-model.json). Clicking a generatable zone's "🗺️ surface" button generates
// that zone's surface (terrain + ore) in the browser too and draws it to a
// canvas — again no backend.
(function () {
  var estimator = null;   // { estimateZoneOre }
  var state = { seed: null, k2: true, zones: [], sortKey: "radius", sortDir: "desc", q: "" };

  function loadEstimator() {
    if (estimator) return Promise.resolve(estimator);
    return fetch("/static/ore-model.json").then(function (r) { return r.json(); })
      .then(function (m) { estimator = window.createEstimator(m); return estimator; });
  }

  var GEN = { planet: 1, moon: 1, "asteroid-field": 1 };
  function nm(r) { return r.replace(/^se-/, "").replace(/^kr-/, "").replace(/-ore$/, ""); }
  function fmt(n) { return n >= 1e9 ? (n / 1e9).toFixed(2) + "B" : n >= 1e6 ? (n / 1e6).toFixed(1) + "M" : Math.round(n); }
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

  function sortZones(rows) {
    var k = state.sortKey, dir = state.sortDir === "asc" ? 1 : -1;
    return rows.slice().sort(function (a, b) {
      var va, vb;
      if (k === "radius") { va = a.r || 0; vb = b.r || 0; return (va - vb) * dir; }
      if (k === "primary") { va = a.p || ""; vb = b.p || ""; }
      else if (k === "type") { va = a.t; vb = b.t; }
      else { va = a.n; vb = b.n; }
      return String(va).localeCompare(String(vb)) * dir;
    });
  }

  function th(label, key) {
    var ind = state.sortKey === key ? (state.sortDir === "asc" ? " ▲" : " ▼") : "";
    return '<th class="sortable" data-key="' + key + '" style="cursor:pointer">' + label + '<span class="sort-ind">' + ind + "</span></th>";
  }

  function renderTable() {
    var q = state.q.toLowerCase();
    var rows = state.zones.filter(function (z) {
      if (!GEN[z.t]) return false;                              // generatable only
      if (!q) return true;
      return (z.n + " " + z.t + " " + (z.p || "")).toLowerCase().indexOf(q) !== -1;
    });
    rows = sortZones(rows);
    var body = rows.map(function (z) {
      var est = estimateZone(z);
      return '<tr>' +
        "<td><strong>" + esc(z.n) + "</strong></td>" +
        '<td><span class="badge zone-type">' + z.t + "</span></td>" +
        "<td>" + (z.r ? Math.round(z.r) : "—") + "</td>" +
        "<td>" + cw(z.water) + "</td>" +
        "<td>" + ce(z.enemy) + "</td>" +
        "<td>" + (z.p ? nm(z.p) : "—") + "</td>" +
        '<td class="yields-cell">' + resChips(est) + "</td>" +
        // data-surf must be the zone's index in state.zones (openSurface looks
        // it up there), NOT the position in the sorted/filtered rows.
        '<td><button type="button" class="btn-sm" data-surf="' + state.zones.indexOf(z) + '" title="Generate this zone\'s surface in your browser">🗺️</button></td>' +
        "</tr>";
    }).join("");
    document.getElementById("zt-body").innerHTML = body || '<tr><td colspan="8" class="hint">No generatable zones.</td></tr>';
    document.getElementById("zt-count").textContent = rows.length + " zones";
    document.querySelectorAll("#zt-head .sort-ind").forEach(function (s) { s.textContent = ""; });
    var active = document.querySelector('#zt-head th[data-key="' + state.sortKey + '"] .sort-ind');
    if (active) active.textContent = state.sortDir === "asc" ? " ▲" : " ▼";
  }

  function generate() {
    var seedVal = parseInt(document.getElementById("seed-input").value, 10);
    if (!Number.isFinite(seedVal) || seedVal < 0) return;
    state.seed = seedVal;
    state.k2 = document.getElementById("k2-input").checked;
    var status = document.getElementById("gen-status");
    status.textContent = "generating…";
    Promise.all([window.generateUniverse(seedVal, state.k2), loadEstimator()])
      .then(function (res) {
        var uni = res[0];
        var zones = uni.z.slice();
        // Synthetic Nauvis (the universe generator never emits it): default-FSR
        // planet, r5000. Estimated client-side (base ores + K2 rare-metal);
        // surface generation uses the game's default map-gen settings (nauvis).
        zones.unshift({ n: "Nauvis", t: "planet", s: seedVal, r: 5000, water: "none", enemy: "none", c: 1, nauvis: true });
        state.zones = zones;
        history.replaceState(null, "", "/analyze/" + seedVal + (state.k2 ? "?k2=1" : ""));
        status.textContent = uni.z.length + " zones · generated client-side";
        renderTable();
      })
      .catch(function (e) { status.textContent = "error: " + e.message; console.error(e); });
  }

  // ── Surface panel (client-side zone surface render) ──────────────────────
  var surf = { zone: null, busy: false };

  function surfStatus(msg) {
    document.getElementById("surf-status").textContent = msg || "";
  }

  // Draw the WASM RGBA buffer into the canvas at 1:1 (CSS scales it down).
  function drawSurface(summary, pixels) {
    var canvas = document.getElementById("surf-canvas");
    canvas.width = summary.width;
    canvas.height = summary.height;
    var ctx = canvas.getContext("2d");
    var img = ctx.createImageData(summary.width, summary.height);
    img.data.set(pixels);
    ctx.putImageData(img, 0, 0);
  }

  function surfSummaryChips(resources) {
    var keys = Object.keys(resources).sort(function (a, b) { return resources[b].amount - resources[a].amount; });
    if (!keys.length) return '<span class="hint">No resources placed in this disk (try a larger radius).</span>';
    return keys.map(function (r) {
      return '<span class="res-chip surf" title="exact — generated in your browser">' + nm(r) + " <strong>" + resources[r].display + "</strong></span>";
    }).join(" ");
  }

  function renderSurface() {
    if (!surf.zone || surf.busy) return;
    surf.busy = true;
    surfStatus("generating surface…");
    var radius = parseInt(document.getElementById("surf-radius").value, 10);
    if (!Number.isFinite(radius) || radius < 10) radius = 10;
    if (radius > 2000) radius = 2000;
    document.getElementById("surf-radius").value = radius;
    var layer = parseInt(document.getElementById("surf-layer").value, 10) || 0;
    window.generateSurface({ seed: state.seed, k2: state.k2, zone: surf.zone, radius: radius, layer: layer })
      .then(function (r) {
        surf.busy = false;
        drawSurface(r.summary, r.pixels);
        window.__LAST_SURF__ = r.summary; // test hook: exact per-resource amounts
        window.__LAST_SURF_AT__ = Date.now(); // test hook: completion time (worker)
        document.getElementById("surf-res").innerHTML = surfSummaryChips(r.summary.resources) +
          ' <span class="hint">· ' + r.summary.width + "×" + r.summary.height + " · generated client-side</span>";
        surfStatus("zone " + r.summary.zone + " · " + r.summary.type + " · r" + radius);
      })
      .catch(function (e) {
        surf.busy = false;
        surfStatus("error: " + e.message);
        console.error(e);
      });
  }

  function openSurface(idx) {
    var z = state.zones[idx];
    if (!z) return;
    surf.zone = z;
    document.getElementById("surf-title").textContent = "🗺️ " + z.n + " (" + z.t + ")";
    document.getElementById("surf-panel").hidden = false;
    renderSurface();
  }

  function closeSurface() {
    document.getElementById("surf-panel").hidden = true;
    surf.zone = null;
  }

  function bind() {
    document.getElementById("gen-btn").addEventListener("click", generate);
    document.getElementById("seed-input").addEventListener("keydown", function (e) { if (e.key === "Enter") generate(); });
    document.getElementById("zt-search").addEventListener("input", function (e) { state.q = e.target.value; renderTable(); });
    document.getElementById("zt-head").addEventListener("click", function (e) {
      var thEl = e.target.closest("th[data-key]"); if (!thEl) return;
      var k = thEl.dataset.key;
      state.sortDir = state.sortKey === k && state.sortDir === "asc" ? "desc" : "asc";
      state.sortKey = k; renderTable();
    });
    document.getElementById("zt-body").addEventListener("click", function (e) {
      var btn = e.target.closest("button[data-surf]"); if (!btn) return;
      openSurface(parseInt(btn.dataset.surf, 10));
    });
    document.getElementById("surf-gen").addEventListener("click", renderSurface);
    document.getElementById("surf-close").addEventListener("click", closeSurface);
    document.getElementById("surf-radius").addEventListener("change", renderSurface);
    document.getElementById("surf-layer").addEventListener("change", renderSurface);
    document.getElementById("surf-panel").addEventListener("click", function (e) {
      if (e.target === this) closeSurface();   // backdrop click
    });
    window.preloadUniverseWasm && window.preloadUniverseWasm();
    window.preloadSurfaceWasm && window.preloadSurfaceWasm();
    // Auto-generate if a seed was in the URL (/analyze/:seed).
    var pre = window.__ANALYZE_SEED__;
    if (pre != null) { document.getElementById("seed-input").value = pre; generate(); }
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", bind);
  else bind();
})();
