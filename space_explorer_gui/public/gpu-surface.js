// Client loader for the WebGPU surface worker (gpu-worker.js). Same call shape
// as surface-wasm.js so the surface page can swap backends.
//
//   window.generateSurfaceGPU(req) -> Promise<{ summary, pixels }>
//     req: { seed, kind: "elevation"|"fields"|"tiles", rect:{x0,y0,x1,y1} }
//     tiles  -> pixels = Uint8Array of palette tile indices (0..20)
//     fields -> pixels = Float32Array aux, extra = Float32Array moisture
//   window.preloadSurfaceGPU()
//
// Palette order matches biome.zig nauvis_base_palette:
//   0 water, 1 deepwater, 2 sand-1, 3 sand-2, 4 sand-3, 5 dry-dirt, 6..12
//   dirt-1..7, 13..16 grass-1..4, 17..20 red-desert-0..3
(function () {
  var NAUVIS_COLORS = [
    [51, 83, 95], [38, 64, 73], [138, 103, 58], [128, 93, 52], [115, 83, 47],
    [94, 66, 37], [141, 104, 60], [136, 96, 59], [133, 92, 53], [103, 72, 43],
    [91, 63, 38], [80, 55, 31], [80, 54, 28], [55, 53, 11], [66, 57, 15],
    [65, 52, 28], [59, 40, 18], [103, 70, 32], [116, 81, 39], [116, 84, 43],
    [128, 93, 52]
  ];
  var worker = null;
  var nextId = 1;
  var pending = {};

  function ensure() {
    if (worker) return worker;
    worker = new Worker(location.origin + "/static/gpu-worker.js");
    worker.onmessage = function (ev) {
      var m = ev.data;
      var p = pending[m.id];
      if (!p) return;
      delete pending[m.id];
      if (m.ok) p.resolve(m);
      else p.reject(new Error(m.error || "gpu surface failed"));
    };
    worker.onerror = function (e) {
      try { window.__GPU_WORKER_ERR__ = String((e && e.message) || e); } catch (e2) {}
      var err = new Error("gpu worker crashed: " + (e.message || "unknown"));
      Object.keys(pending).forEach(function (id) { pending[id].reject(err); });
      pending = {};
      worker.terminate();
      worker = null;
    };
    return worker;
  }

  window.generateSurfaceGPU = function (req) {
    var w = ensure();
    var id = nextId++;
    return new Promise(function (resolve, reject) {
      pending[id] = { resolve: resolve, reject: reject };
      w.postMessage({ id: id, type: "gpu-surface", req: req });
    });
  };
  window.preloadSurfaceGPU = function () { return ensure(); };

  // Turn tile-index pixels into RGBA (terrain layer only).
  window.gpuIndicesToRgba = function (indices, w, h) {
    var out = new Uint8Array(w * h * 4);
    for (var i = 0; i < w * h; i++) {
      var c = NAUVIS_COLORS[indices[i]] || [0, 0, 0];
      var o = i * 4;
      out[o] = c[0]; out[o + 1] = c[1]; out[o + 2] = c[2]; out[o + 3] = 255;
    }
    return out;
  };

  // Render an SE (alien-biomes) zone disk with the se_zone classifier kernel.
  // Chunked into `cell`-sized dispatches so large radii stay memory-bounded;
  // pixels outside the radius disk are left transparent (matches the CPU map
  // which draws a disk on a transparent square). req: { seed, zone, radius,
  // onProgress?, cell? } -> { rgba: Uint8Array(2R*2R*4), width, height }
  window.generateSEZoneGPU = function (req) {
    var seed = req.seed, zone = req.zone, R = req.radius;
    var diskR = req.diskR || R;      // disk crop radius (<= R)
    var cell = req.cell || 512;
    var onProgress = req.onProgress || null;
    var size = 2 * R;
    var rgba = new Uint8Array(size * size * 4); // transparent background

    // cell squares over [-R, R) in absolute map coords; skip cells fully out
    // of the rendered disk (CPU renders transparent there).
    var cells = [];
    for (var ya = -R; ya < R; ya += cell) {
      var yb = Math.min(ya + cell, R);
      for (var xa = -R; xa < R; xa += cell) {
        var xb = Math.min(xa + cell, R);
        var cdx = Math.max(xa, Math.min(0, xb - 1));
        var cdy = Math.max(ya, Math.min(0, yb - 1));
        if (cdx * cdx + cdy * cdy > diskR * diskR) continue; // fully outside disk
        cells.push({ xa: xa, ya: ya, xb: xb, yb: yb });
      }
    }

    var done = 0;
    var run = cells.map(function (c) {
      return window.generateSurfaceGPU({ seed: seed, kind: "se-color", zone: zone, rect: { x0: c.xa, y0: c.ya, x1: c.xb, y1: c.yb } })
        .then(function (r) {
          var packed = new Uint32Array(r.pixels);
          var cw = c.xb - c.xa, ch = c.yb - c.ya;
          for (var i = 0; i < packed.length; i++) {
            var x = c.xa + (i % cw), y = c.ya + ((i / cw) | 0);
            if (x * x + y * y > diskR * diskR) continue;
            var o = ((y + R) * size + (x + R)) * 4;
            rgba[o] = (packed[i] >> 16) & 255;
            rgba[o + 1] = (packed[i] >> 8) & 255;
            rgba[o + 2] = packed[i] & 255;
            rgba[o + 3] = 255;
          }
          done++;
          if (onProgress) onProgress(done, cells.length);
        });
    });
    return Promise.all(run).then(function () { return { rgba: rgba, width: size, height: size, cells: cells.length }; });
  };
})();
