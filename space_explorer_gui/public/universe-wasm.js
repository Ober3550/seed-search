// Client-side universe generation. Loads universe.wasm (the Zig universe
// generator compiled to WebAssembly — same pure logic as the native seedgen, so
// FSR values are equivalent) and exposes window.generateUniverse(seed, k2).
//
// This lets the seed page compute a seed's full universe — zones, tags, primary
// ("p") and per-resource FSR scores ("rs", full ids) — with no backend call.
(function () {
  var _inst = null, _loading = null;

  function load() {
    if (_inst) return Promise.resolve(_inst);
    if (_loading) return _loading;
    // freestanding wasm needs no imports; plain instantiate (arrayBuffer avoids
    // needing an application/wasm Content-Type for instantiateStreaming).
    _loading = fetch("/static/universe.wasm")
      .then(function (r) { return r.arrayBuffer(); })
      .then(function (bytes) { return WebAssembly.instantiate(bytes, {}); })
      .then(function (res) { _inst = res.instance; return _inst; });
    return _loading;
  }

  // Generate one seed's full universe entirely in the browser. Returns a Promise
  // of the parsed object { s, k, z: [ { i, n, t, s, c, r, <tags>, p, rs }, ... ] }.
  // The result buffer is valid only until the next call (the wasm arena resets),
  // so we decode + JSON.parse before returning.
  window.generateUniverse = function (seed, k2) {
    return load().then(function (inst) {
      var e = inst.exports;
      e.generate(seed >>> 0, k2 ? 1 : 0);
      var bytes = new Uint8Array(e.memory.buffer, e.resultPtr(), e.resultLen());
      return JSON.parse(new TextDecoder("utf-8").decode(bytes));
    });
  };

  // Kick off the fetch/instantiate eagerly so the first generate() is instant.
  window.preloadUniverseWasm = load;
})();
