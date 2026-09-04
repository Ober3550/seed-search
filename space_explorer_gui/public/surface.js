// Dedicated surface-generation page (/surface/:seed/:name). Renders ONE surface
// full-page. SE zones / Nauvis use surface.wasm; SA planets use sa.wasm.
//
// Why chunking: the surface.wasm work is split into SQUARE CELL chunks exactly
// like the backend segen job pages did it (surface.wasm gained an optional
// absolute-rect so any rect is renderable): an N×N grid of ~320-tile cells
// over the square, dispatched CENTRE-OUTWARD (nearest cell to spawn first) so
// the landing area appears first and the map grows outward, fanned out across
// a small pool of gen workers (one wasm instance each → cells run in parallel
// across CPU cores) and blitted onto the canvas as each cell lands —
// GPU-accelerated canvas2d putImageData. This mirrors job-manager.js
// planSurfaceCells() (the backend's cell plan + order), so the fill animation
// matches the old job pages' live grid.
//
// Terrain is chunked freely (it's per-tile deterministic — a union of cells is
// bit-identical to one whole call). Ore placement is NOT split across cell
// calls (the ore pass is rect-dependent: starting-area enrichment scans whole
// regions), so ores are computed once for the whole rect in a separate
// "terrainless" pass queued onto its own worker, and each cell composites its
// ore sub-rect over the terrain as it lands. Resource totals come from that
// pass. There's no backend process to reuse in a browser tab — surface.wasm IS
// the segen code compiled to WASM, and each gen worker is one segen worker's
// worth of parallelism; the pool replaces the backend's job queue.
(function () {
  var SEED = window.__SURF_SEED__;
  var TARGET = window.__SURF_TARGET__ || "";
  var MOD = window.__SURF_MOD__ || "k2se";
  var K2 = MOD === "k2se";
  // ?gpu=1 -> render base-Nauvis terrain with the WebGPU kernel (single dispatch)
  var USE_GPU = /[?&]gpu=1\b/.test(location.search);
  var GPU_MS = null;

  var PLANETS = {
    vulcanus: { label: "🌋 Vulcanus", ok: false, why: "Vulcanus terrain needs the multisample autoplace op — not ported yet" },
    fulgora:  { label: "⚡ Fulgora",  ok: true },
    gleba:    { label: "🍄 Gleba",    ok: false, why: "Gleba terrain needs spot_noise sub-expression evaluation — not ported yet" },
    aquilo:   { label: "🧊 Aquilo",   ok: false, why: "Aquilo terrain needs spot_noise sub-expression evaluation — not ported yet" }
  };

  var els = {
    badge: document.getElementById("sf-badge"),
    meta: document.getElementById("sf-meta"),
    radius: document.getElementById("sf-radius"),
    layerWrap: document.getElementById("sf-layer-wrap"),
    layer: document.getElementById("sf-layer"),
    go: document.getElementById("sf-go"),
    status: document.getElementById("sf-status"),
    canvas: document.getElementById("sf-canvas"),
    res: document.getElementById("sf-res"),
    progress: document.getElementById("sf-progress")
  };
  var busy = false;
  var kind = null;        // "nauvis" | "sa" | "zone"
  var planetKey = null;   // lower-cased planet name when kind === "sa"
  var zone = null;        // SE universe zone object when kind === "zone"
  var universe = null;    // cached generateUniverse result for this seed

  function nm(r) { return r.replace(/^se-/, "").replace(/^kr-/, "").replace(/-ore$/, ""); }
  function esc(s) { return String(s).replace(/[&<>"]/g, function (c) { return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]; }); }

  function status(msg) { els.status.textContent = msg || ""; }
  function setProgress(pct) {
    if (els.progress) {
      els.progress.style.width = Math.round(pct * 100) + "%";
      els.progress.title = Math.round(pct * 100) + "%";
    }
  }

  function surfChips(totals) {
    var keys = Object.keys(totals).sort(function (a, b) { return totals[b].amount - totals[a].amount; });
    if (!keys.length) return "";
    return keys.map(function (r) {
      return '<span class="res-chip surf" title="exact — generated in your browser">' + nm(r) + " <strong>" + totals[r].display + "</strong></span>";
    }).join(" ");
  }

  // ── Worker pool ───────────────────────────────────────────────────────────
  var pool = null;
  var pending = {};   // id -> { resolve, reject }
  var queue = [];     // [{ id, req, resolve, reject }]
  var nextId = 1;

  function spawnPool() {
    pool = [];
    var n = 2;
    // one worker per logical core (safety-capped at 16 for very large hosts).
    try { n = Math.max(1, Math.min(navigator.hardwareConcurrency || 4, 16)); } catch (e) {}
    for (var i = 0; i < n; i++) {
      var w = new Worker("/static/gen-worker.js");
      w.idle = true;
      (function (worker) {
        worker.onmessage = function (ev) {
          var m = ev.data;
          var p = pending[m.id];
          if (!p) return;
          delete pending[m.id];
          if (m.ok) p.resolve({ summary: m.summary, pixels: m.pixels });
          else p.reject(new Error(m.error || "surface call failed"));
          if (queue.length) {
            var j = queue.shift();
            pending[j.id] = { resolve: j.resolve, reject: j.reject };
            worker.postMessage({ id: j.id, type: "surface", req: j.req });
          } else worker.idle = true;
        };
      })(w);
      pool.push(w);
    }
  }

  function sendToPool(req) {
    return new Promise(function (resolve, reject) {
      var id = nextId++;
      var free = null;
      for (var i = 0; i < pool.length; i++) { if (pool[i].idle) { free = pool[i]; break; } }
      if (free) {
        free.idle = false;
        pending[id] = { resolve: resolve, reject: reject };
        free.postMessage({ id: id, type: "surface", req: req });
      } else {
        queue.push({ id: id, req: req, resolve: resolve, reject: reject });
      }
    });
  }

  function putImg(ctx, w, h, px, dx, dy) {
    var img = ctx.createImageData(w, h);
    img.data.set(px);
    ctx.putImageData(img, dx, dy);
  }

  // ── Map render orchestration ──────────────────────────────────────────────
  // Mirrors the backend segen cell scheduler (job-manager.js planSurfaceCells):
  // an N×N grid of ~CELL_TILES-tile SQUARE cells over [-R,R)², dispatched
  // centre-outward (nearest cell to spawn first, row-major tie-break) so the
  // map fills from the middle like the old job pages' live grids. Cells wholly
  // outside the rendered disk are skipped (they'd paint all-transparent
  // anyway). The disk radius is the ZONE's radius (the wasm clips to it, not
  // to the preview R — previews are usually smaller than the zone). A union of
  // cells is pixel-identical to one whole call (every tile depends only on its
  // own coords), so the partition never changes the image — only the order it
  // appears in.
  var CELL_TILES = 32; // one Factorio chunk (32x32 tiles) per cell — per-cell
  //    time is then directly comparable to in-game chunk generation. NOTE: a
  //    2000-tile radius needs a 125x125 grid; the per-call wasm setup (~ms)
  //    is paid once per cell, so this trades per-cell granularity for overhead.
  //    ?cells=N overrides the cell edge (tuning/benchmarks).
  try {
    var _qc = new URLSearchParams(location.search).get("cells");
    if (_qc) CELL_TILES = Math.max(1, Math.min(512, parseInt(_qc, 10) || 32));
  } catch (e) {}
  var GRID_CAP = 512;   // allow up to a 512x512 grid at CELL_TILES=32

  // disk radius the wasm clips to: zone radius (asteroid fields/Nauvis have no
  // zone radius — SE uses the field effective radius 5000; fall back to R).
  function zoneDiskRadius(zoneObj, R) {
    if (zoneObj.r) return zoneObj.r;
    if (zoneObj.t === "asteroid-field") return 5000;
    return R;
  }

  function planSurfaceCells(R, diskR) {
    var n = Math.max(1, Math.min(GRID_CAP, Math.ceil((2 * R) / CELL_TILES)));
    if (n === 1) return { n: 1, cells: [{ gx: 0, gy: 0, x0: -R, y0: -R, x1: R, y1: R, d2: 0, i: 0 }] };
    var full = 2 * R;
    var cellW = Math.ceil(full / n);
    var planned = [];
    for (var i = 0; i < n * n; i++) {
      var gx = i % n;
      var gy = Math.floor(i / n);
      var x0 = -R + gx * cellW;
      var x1 = Math.min(R, x0 + cellW);
      var y0 = -R + gy * cellW;
      var y1 = Math.min(R, y0 + cellW);
      if (x1 <= x0 || y1 <= y0) continue;
      // nearest point of this cell to the origin; skip when outside the disk.
      var nx = Math.max(x0, Math.min(0, x1 - 1));
      var ny = Math.max(y0, Math.min(0, y1 - 1));
      if (nx * nx + ny * ny > diskR * diskR) continue;
      var cx = (x0 + x1) / 2;
      var cy = (y0 + y1) / 2;
      planned.push({ gx: gx, gy: gy, x0: x0, y0: y0, x1: x1, y1: y1, d2: cx * cx + cy * cy, i: i });
    }
    // centre-out: nearest cell to (0,0) first; row-major breaks ties (stable).
    planned.sort(function (a, b) { return (a.d2 - b.d2) || (a.i - b.i); });
    return { n: n, cells: planned };
  }

  // layer 0: centre-out terrain cells + one whole-rect ore pass, composited
  //          per cell as each lands.
  // layer 1: terrain cells only.
  // layer 2: whole-rect ore-only call (legacy).
  function renderSurfaceMap(zoneObj, R, layer, palette, onCell) {
    var npx = 2 * R;
    var ctx = els.canvas.getContext("2d");
    els.canvas.width = npx;
    els.canvas.height = npx;
    var fullRect = { x0: -R, y0: -R, x1: R, y1: R };
    var plan = planSurfaceCells(R, zoneDiskRadius(zoneObj, R));
    var cells = plan.cells;
    // tuning/bench hook: cell edge, grid N and the number of planned cells
    window.__SURF_CELLS__ = { cellTiles: CELL_TILES, n: plan.n, cells: cells.length };

    var totals = {};
    return new Promise(function (resolve, reject) {
      var oreCanvas = null; // whole-rect ore pixels (layer 0) for per-cell composite
      var oreDone = false;
      var landed = [];      // cells drawn before the ore pass finished
      var done = 0;
      var failed = 0;

      function blitOreRect(cell) {
        if (!oreCanvas) return;
        var sx = cell.x0 + R;
        var sy = cell.y0 + R;
        var w = cell.x1 - cell.x0;
        var h = cell.y1 - cell.y0;
        // source-over: ore pixels are opaque only where patches are, so terrain
        // under the transparent pixels stays visible.
        ctx.drawImage(oreCanvas, sx, sy, w, h, sx, sy, w, h);
      }

      function oreReady() {
        oreDone = true;
        for (var i = 0; i < landed.length; i++) blitOreRect(landed[i]);
        landed = [];
      }

      // Whole-rect ore pass (single request) — queued first so a worker picks
      // it up while the pool streams terrain cells.
      var ore = layer === 1 ? Promise.resolve(null) : (function () {
        return sendToPool({
          seed: SEED, k2: K2, zone: zoneObj, layer: layer,
          terrainless: layer === 0, palette: palette, rect: fullRect
        }).then(function (r) {
          var res = r.summary.resources || {};
          Object.keys(res).forEach(function (rn) {
            totals[rn] = { amount: res[rn].amount, display: res[rn].display };
          });
          if (layer === 0) {
            oreCanvas = document.createElement("canvas");
            oreCanvas.width = r.summary.width;
            oreCanvas.height = r.summary.height;
            var octx = oreCanvas.getContext("2d");
            var img = octx.createImageData(r.summary.width, r.summary.height);
            img.data.set(r.pixels);
            octx.putImageData(img, 0, 0);
            oreReady();
          } else {
            // layer 2 ore-only view: whole-rect blit (transparent background).
            var cimg = ctx.createImageData(r.summary.width, r.summary.height);
            cimg.data.set(r.pixels);
            ctx.putImageData(cimg, 0, 0);
          }
        }).catch(function (e) {
          failed++;
          console.error("ore pass failed:", e);
        });
      })();

      function terrainCell(cell) {
        return sendToPool({
          seed: SEED, k2: K2, zone: zoneObj, layer: 1, palette: palette,
          rect: { x0: cell.x0, y0: cell.y0, x1: cell.x1, y1: cell.y1 }
        }).then(function (r) {
          // blit this cell (pixel data uploaded to the GPU-backed canvas).
          var img = ctx.createImageData(r.summary.width, r.summary.height);
          img.data.set(r.pixels);
          ctx.putImageData(img, cell.x0 + R, cell.y0 + R);
          if (oreDone) blitOreRect(cell);
          else landed.push(cell);
          done++;
          if (onCell) onCell(done, cells.length);
        }).catch(function (e) {
          failed++;
          console.error("cell (" + cell.gx + "," + cell.gy + ") failed:", e);
        });
      }

      function finish() {
        if (layer !== 1 && Object.keys(totals).length === 0) failed++;
        if (failed > 0) reject(new Error("render failed (" + failed + " stage(s))"));
        else resolve(totals);
      }

      if (layer === 2) {
        // no terrain to stream — blit the ore-only call when it lands.
        ore.then(finish, finish);
        return;
      }

      var jobs = [];
      for (var c = 0; c < cells.length; c++) jobs.push(terrainCell(cells[c]));
      // All terrain cells, then the ore overlay, then resolve.
      Promise.all(jobs).then(function () {
        return ore;
      }).then(finish, finish);
    });
  }

  function resolveKind() {
    if (TARGET === "Nauvis") return { kind: "nauvis" };
    var lower = TARGET.toLowerCase();
    if (PLANETS[lower]) return { kind: "sa", planetKey: lower };
    if (MOD !== "se" && MOD !== "k2se") {
      return { kind: "error", msg: TARGET + " is not an SE zone of seed " + SEED + " (mod " + MOD + " has no universe generator)." };
    }
    return { kind: "zone" };
  }

  function nauvisZone() {
    return { n: "Nauvis", t: "planet", s: SEED, r: 5000, water: "none", enemy: "none", c: 1, nauvis: true };
  }

  function zoneMeta(z) {
    var bits = [];
    if (z.t) bits.push('<span class="badge zone-type">' + esc(z.t) + "</span>");
    if (z.r) bits.push("radius " + Math.round(z.r));
    if (z.water) bits.push("water " + esc(z.water));
    if (z.enemy) bits.push("enemy " + esc(z.enemy));
    if (z.p) bits.push("primary " + esc(z.p));
    return bits.join(" · ");
  }

  function radiusLimits() {
    if (kind === "sa") return { min: 16, max: 512, step: 8, value: 96 };
    return { min: 10, max: 2000, step: 50, value: 200 };
  }

  function adaptForKind() {
    els.badge.textContent = kind === "sa" ? "planet" : kind === "nauvis" ? "planet (base)" : "zone";
    els.layerWrap.hidden = kind === "sa";
    var lim = radiusLimits();
    els.radius.min = lim.min; els.radius.max = lim.max; els.radius.step = lim.step; els.radius.value = lim.value;
  }

  function run() {
    if (busy) return;
    busy = true;
    els.go.disabled = true;
    setProgress(0);
    status("starting…");
    var t0 = Date.now();
    var radius = parseInt(els.radius.value, 10);
    if (!Number.isFinite(radius)) radius = 200;
    var layer = parseInt(els.layer.value, 10) || 0;
    var layerName = ["terrain + ore", "terrain only", "ore only"][layer];

    // WebGPU path (base Nauvis terrain only, single dispatch). ?gpu=1.
    if (USE_GPU && kind === "nauvis" && layer === 1) {
      els.canvas.width = 2 * radius;
      els.canvas.height = 2 * radius;
      status("gpu: dispatching nauvis tile kernel…");
      window.generateSurfaceGPU({
        seed: SEED, kind: "tiles",
        rect: { x0: -radius, y0: -radius, x1: radius, y1: radius }
      }).then(function (r) {
        var s = r.summary;
        var ctx = els.canvas.getContext("2d");
        var img = ctx.createImageData(s.width, s.height);
        img.data.set(window.gpuIndicesToRgba(r.pixels, s.width, s.height));
        ctx.putImageData(img, 0, 0);
        var ms = Date.now() - t0;
        GPU_MS = ms;
        window.__SURF_MS__ = ms;
        window.__LAST_SURF_AT__ = Date.now();
        window.__LAST_SURF__ = { zone: "Nauvis", type: "planet", resources: {}, layer: layer, gpu: true };
        busy = false;
        els.go.disabled = false;
        setProgress(1);
        status("zone Nauvis · planet · r" + radius + " (WebGPU)");
        var px = s.width * s.height;
        var cpu1 = Math.round(px * 0.08); // ~80 us/px single-thread wasm -> ms
        els.res.innerHTML = '<span class="hint">· ' + s.width + "×" + s.height + " · WebGPU kernel, 1 dispatch · " +
          ms + " ms (CPU-wasm 1-thread ~" + cpu1 + " ms ≈ " + (cpu1 / 1000).toFixed(1) + " s) · " +
          (px / ms / 1000).toFixed(2) + " Mpx/s</span>";
      }).catch(function (e) {
        busy = false;
        els.go.disabled = false;
        status("gpu error: " + e.message);
        console.error(e);
      });
      return;
    }

    if (kind === "sa") {
      var p = PLANETS[planetKey];
      if (!p.ok) {
        busy = false;
        els.go.disabled = false;
        els.res.innerHTML = '<span class="hint">' + esc(p.why) + "</span>";
        status("not supported yet");
        return;
      }
      window.generateSA({ seed: SEED, planet: planetKey, radius: radius })
        .then(function (r) {
          busy = false;
          els.go.disabled = false;
          var canvas = els.canvas;
          canvas.width = r.summary.width;
          canvas.height = r.summary.height;
          var ctx = canvas.getContext("2d");
          var img = ctx.createImageData(r.summary.width, r.summary.height);
          img.data.set(r.pixels);
          ctx.putImageData(img, 0, 0);
          window.__SURF_MS__ = Date.now() - t0;
          els.res.textContent =
            p.label + " · seed " + r.summary.seed + " · " + r.summary.width + "×" + r.summary.height +
            " · elevation height-map (the planet's tile layer isn't modelled yet) · " + window.__SURF_MS__ + " ms";
          status("ok");
        })
        .catch(function (e) { busy = false; els.go.disabled = false; status("error: " + e.message); console.error(e); });
      return;
    }

    // zone / nauvis → chunked surface.wasm pipeline.
    var palette = "se"; // alien-biomes ground is Space-Exploration-only
    if (kind === "nauvis" && MOD !== "se" && MOD !== "k2se") palette = "vanilla";
    var needZone = kind === "zone";
    if (!pool) spawnPool();
    Promise.resolve(needZone ? fetchZone() : nauvisZone())
      .then(function (z) {
        var R = radius;
        return renderSurfaceMap(z, R, layer, palette, function (done, total) {
          status("rendering terrain " + done + "/" + total + " cells…");
          setProgress(total ? done / total : 0);
        }).then(function (totals) {
          busy = false;
          els.go.disabled = false;
          setProgress(1);
          window.__LAST_SURF__ = { zone: z.n, type: z.t, resources: totals, layer: layer }; // test hook
          window.__LAST_SURF_AT__ = Date.now();
          window.__SURF_MS__ = window.__LAST_SURF_AT__ - t0;
          var width = 2 * R;
          var nres = Object.keys(totals).length;
          els.res.innerHTML =
            (layer !== 1 ? surfChips(totals) + " " : "") +
            '<span class="hint">· ' + width + "×" + width + " · " + layerName +
            (nres ? " · " + nres + " resources" : "") +
            " · generated client-side (" + pool.length + " workers) · " + window.__SURF_MS__ + " ms</span>";
          status("zone " + z.n + " · " + z.t + " · r" + radius);
        });
      })
      .catch(function (e) {
        busy = false;
        els.go.disabled = false;
        status("error: " + e.message);
        console.error(e);
      });
  }

  function fetchZone() {
    if (universe) return Promise.resolve(findZone());
    return window.generateUniverse(SEED, K2).then(function (uni) {
      universe = uni;
      return findZone();
    });
  }
  function findZone() {
    var found = null;
    for (var i = 0; i < universe.z.length; i++) {
      if (universe.z[i].n === TARGET) { found = universe.z[i]; break; }
    }
    if (!found) throw new Error("zone “" + TARGET + "” not found in seed " + SEED + "’s universe (mod " + MOD + ").");
    return found;
  }

  function init() {
    if (SEED == null || !TARGET) {
      status("missing seed or surface name in URL");
      return;
    }
    var r = resolveKind();
    if (r.kind === "error") { status(r.msg); return; }
    kind = r.kind;
    if (kind === "sa") planetKey = r.planetKey;
    els.badge.textContent = "…";
    adaptForKind();
    els.go.addEventListener("click", run);
    els.radius.addEventListener("change", run);
    els.layer.addEventListener("change", run);
    if (kind === "sa") {
      var p = PLANETS[planetKey];
      els.meta.innerHTML = p.label + ' <span class="hint">· seed ' + SEED + " · Space Age planet terrain (sa.wasm).</span>";
      els.badge.textContent = p.ok ? "planet" : "pending";
    } else if (kind === "nauvis") {
      var vanilla = MOD !== "se" && MOD !== "k2se";
      els.meta.innerHTML = "🌍 Nauvis <span class=\"hint\">· seed " + SEED + " · game-default map settings" +
        (vanilla
          ? ", base-game Nauvis tiles (real 2.0 tile palette; tile selection approximated until expression_in_range is ported)."
          : ", SE ground (alien-biomes, exact).") + "</span>";
    } else {
      els.meta.innerHTML = "SE zone of seed " + SEED + " <span class=\"hint\">· resolving universe…</span>";
      fetchZone().then(function (z) {
        zone = z;
        els.meta.innerHTML = zoneMeta(z) + ' <span class="hint">· seed ' + SEED + ", mod " + esc(MOD) + ".</span>";
      }).catch(function (e) {
        status(e.message);
        console.error(e);
      });
    }
    run();
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
