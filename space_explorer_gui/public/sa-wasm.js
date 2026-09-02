// Client-side Space Age planet terrain preview, run in the gen worker. Same
// pattern as surface-wasm.js:
//
//   window.generateSA(req) → Promise<{ summary, pixels }>
//   req: { seed, planet: "vulcanus|fulgora|gleba|aquilo", property?, radius? }
//   summary = { ok, planet, property, seed, radius, width, height }
(function () {
  window.generateSA = function (req) {
    return window.__genCall("sa", { req: req }).then(function (m) {
      return { summary: m.summary, pixels: m.pixels };
    });
  };
})();
