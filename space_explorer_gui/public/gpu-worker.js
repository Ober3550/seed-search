// GPU surface worker (WebGPU compute). Ports gpu_compute's WGSL kernels into a
// browser worker: the host builds the per-seed BasisNoiseGen tables in JS
// (same triple-LFSR + fast-sin gradients as noise.zig), uploads them, and
// dispatches one kernel per requested surface stage.
//
// Protocol (like gen-worker.js): { id, type:"gpu-surface", req } -> { id, ok,
// summary, pixels?|grid? }. req: { seed, kind, rect:{x0,y0,x1,y1}, planet }
//   kind: "elevation"   -> f32 elevation grid (for water mask / debugging)
//         "water"       -> u8 tile index per px (0=land,1=water,2=deepwater)
// (later stages: fields moisture/aux + 21-tile competition kernel)
//
// Tables follow noise.zig: perm1/perm2 are u8 (stored as u32), grad is 512 f32
// (gx,gy interleaved per 256 gradient), seed_byte u32. elevation.wgsl packs 7
// gens (seed1 = 900,99584,700,1000,1100,500,600) into shared buffers.

// ── triple-LFSR (rng.zig port) ─────────────────────────────────────────────
const M32 = 0xffffffff;
function lfsrInit(seed) {
  const s = Math.max(seed >>> 0, 341);
  return { s1: s, s2: s, s3: s };
}
function lfsrNext(r) {
  r.s1 = (((r.s1 & 0xfffffffe) << 12) ^ (((r.s1 << 13) ^ r.s1) >>> 19)) >>> 0;
  r.s2 = (((r.s2 & 0xfffffff8) << 4) ^ (((r.s2 << 2) ^ r.s2) >>> 25)) >>> 0;
  r.s3 = (((r.s3 & 0xfffffff0) << 17) ^ (((r.s3 << 3) ^ r.s3) >>> 11)) >>> 0;
  return (r.s1 ^ r.s2 ^ r.s3) >>> 0;
}

// ── BasisNoiseGen (noise.zig port) ─────────────────────────────────────────
function gradPoly(phase) {
  const r = phase > 0 ? Math.trunc(phase + 0.5) : Math.trunc(phase - 0.5);
  const t = 0.25 - Math.abs(phase - r);
  const t2 = t * t, t4 = t2 * t2, t8 = t4 * t4;
  const poly = t8 * 39.65735524898863 + t2 * (-41.34167506665737) +
    6.283185269630412 + t4 * (t2 * (-76.56887678023256) + 81.60201529595571);
  return (t * poly * 4.2);
}
function baseGradient(i) {
  const ang = i * 0.02454369260617026; // *2pi/256
  const phaseX = ang * 0.15915494309189535; // /2pi
  const phaseY = phaseX - 0.25;
  return [gradPoly(phaseX), gradPoly(phaseY)];
}
function shuffle(arr, prng) { // Fisher-Yates, arr length 256 (or 256 elems of pairs)
  for (let i = 255; i >= 1; i--) {
    const j = lfsrNext(prng) % (i + 1);
    const t = arr[i]; arr[i] = arr[j]; arr[j] = t;
  }
}
// Build the tables for one (seed0, seed1). Returns
// { perm1: Uint32Array(256), perm2, grad: Float32Array(512), seedByte }
function buildGen(seed0, seed1) {
  seed0 >>>= 0; seed1 >>>= 0;
  const folded = (seed0 + (((seed1 >>> 8) & 0xffffff) * 7)) >>> 0;
  const s = folded < 342 ? 341 : folded;
  const prng = lfsrInit(s);

  const identity = new Uint8Array(256);
  const perm1 = new Uint8Array(256);
  const perm2 = new Uint8Array(256);
  const grad = new Float32Array(512);
  for (let i = 0; i < 256; i++) { identity[i] = i; perm1[i] = i; perm2[i] = i; const g = baseGradient(i); grad[2 * i] = g[0]; grad[2 * i + 1] = g[1]; }

  const temp = identity.slice();
  shuffle(temp, prng);
  const seedByte = temp[seed1 & 0xff];
  shuffle(perm1, prng);
  shuffle(perm2, prng);
  for (let i = 255; i >= 1; i--) { // shuffle grad pairs
    const j = lfsrNext(prng) % (i + 1);
    const a = grad[2 * i], b = grad[2 * i + 1];
    grad[2 * i] = grad[2 * j]; grad[2 * i + 1] = grad[2 * j + 1];
    grad[2 * j] = a; grad[2 * j + 1] = b;
  }
  return { perm1: toU32(perm1), perm2: toU32(perm2), grad, seedByte };
}
function toU32(bytes) {
  const out = new Uint32Array(256);
  for (let i = 0; i < 256; i++) out[i] = bytes[i];
  return out;
}

// ── Combined nauvis kernel (elevation + fields + 21-tile competition) ─────
// Fixed gen registry (order must match nauvis.wgsl GI_* slots), seed0 = map seed
// except the per-octave quick/lake gens (seed0+k).
const ELEV_S1 = [900, 99584, 700, 1000, 1100, 500, 600];
const TILE_S1 = [36, 37, 38, 13, 6, 7, 8, 9, 10, 11, 12, 19, 20, 21, 22, 30, 31, 32, 33];
function genList(mapSeed) {
  const g = [];
  for (const s1 of ELEV_S1) g.push([mapSeed, s1]);
  g.push([mapSeed, 1800]);
  for (let k = 0; k < 4; k++) g.push([(mapSeed + k) >>> 0, 6]);   // moisture quick
  for (let k = 0; k < 4; k++) g.push([(mapSeed + k) >>> 0, 7]);   // aux quick
  for (let k = 0; k < 4; k++) g.push([(mapSeed + k) >>> 0, 14]);  // starting lake
  for (const s1 of TILE_S1) g.push([mapSeed, s1]);
  return g;
}

// land rule table (12 f32/tile) mirroring biome.zig nauvis_rules:
// [loa, lom, hia, him, altloa, altlom, althia, althim, hasAlt, hasShore, 0, 0]
const LAND_RULES = [
  [-10, -10, 0.25, 0.15, 0, 0, 0, 0, 0, 1], // sand-1 (shore)
  [-10, 0.15, 0.3, 0.2, 0.25, -10, 0.3, 0.15, 1, 0],
  [-10, 0.2, 0.4, 0.25, 0.3, -10, 0.4, 0.2, 1, 0],
  [0.45, -10, 0.55, 0.35, 0, 0, 0, 0, 0, 0],            // dry-dirt
  [-10, 0.25, 0.45, 0.3, 0.4, -10, 0.45, 0.25, 1, 0],    // dirt-1
  [-10, 0.3, 0.45, 0.35, 0, 0, 0, 0, 0, 0],
  [-10, 0.35, 0.55, 0.4, 0, 0, 0, 0, 0, 0],
  [0.55, -10, 0.6, 0.35, 0.6, 0.3, 11, 0.35, 1, 0],      // dirt-4
  [-10, 0.4, 0.55, 0.45, 0, 0, 0, 0, 0, 0],
  [-10, 0.45, 0.55, 0.5, 0, 0, 0, 0, 0, 0],
  [-10, 0.5, 0.55, 0.55, 0, 0, 0, 0, 0, 0],
  [-10, 0.7, 11, 11, 0, 0, 0, 0, 0, 0],                   // grass-1
  [0.45, 0.45, 11, 0.8, 0, 0, 0, 0, 0, 0],
  [-10, 0.6, 0.65, 0.9, 0, 0, 0, 0, 0, 0],
  [-10, 0.5, 0.55, 0.7, 0, 0, 0, 0, 0, 0],
  [0.55, 0.35, 11, 0.5, 0, 0, 0, 0, 0, 0],                // red-desert-0
  [0.6, -10, 0.7, 0.3, 0.7, 0.25, 11, 0.3, 1, 0],
  [0.7, -10, 0.8, 0.25, 0.8, 0.2, 11, 0.25, 1, 0],
  [0.8, -10, 11, 0.2, 0, 0, 0, 0, 0, 0],
];

// starting lake centre (engine rule: R=74.25 ring at the map RNG's first draw)
function lakeCentre(mapSeed) {
  const r = lfsrInit(mapSeed);
  const f = lfsrNext(r) / 4294967296;
  const th = f * 2 * Math.PI;
  const R = 74.25;
  return [R * Math.cos(th), R * Math.sin(th)];
}

let nau = null; // { pipeline, dev }
let tablesCache = null; // { seed, bufs }
let rulesBuf = null;

async function nauvisPipeline() {
  if (nau) return nau;
  const dev = await getDevice();
  const code = await fetchShader("nauvis.wgsl");
  const module = dev.createShaderModule({ code });
  const info = await module.getCompilationInfo();
  const errs = (info.messages || []).filter((m) => m.type === "error");
  if (errs.length) throw new Error("nauvis.wgsl: " + errs.map((e) => e.lineNum + ":" + e.linePos + " " + e.message).join(" | "));
  const pipeline = dev.createComputePipeline({ layout: "auto", compute: { module, entryPoint: "main" } });
  nau = { pipeline, dev };
  return nau;
}

function uploadTables(dev, mapSeed) {
  if (tablesCache && tablesCache.seed === mapSeed) return tablesCache;
  const gl = genList(mapSeed);
  const n = gl.length;
  const perm1 = new Uint32Array(n * 256);
  const perm2 = new Uint32Array(n * 256);
  const grad = new Float32Array(n * 512);
  const sb = new Uint32Array(n);
  for (let gi = 0; gi < n; gi++) {
    const g = buildGen(gl[gi][0], gl[gi][1]);
    perm1.set(g.perm1, gi * 256);
    perm2.set(g.perm2, gi * 256);
    grad.set(g.grad, gi * 512);
    sb[gi] = g.seedByte;
  }
  const mk = (arr, usage) => {
    const b = dev.createBuffer({ size: arr.byteLength, usage });
    dev.queue.writeBuffer(b, 0, arr);
    return b;
  };
  tablesCache = { seed: mapSeed, count: n,
    perm1: mk(perm1, GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST),
    perm2: mk(perm2, GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST),
    grad: mk(grad, GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST),
    sb: mk(sb, GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST) };
  return tablesCache;
}

function rulesStorage(dev) {
  if (rulesBuf) return rulesBuf;
  const f = new Float32Array(19 * 12);
  LAND_RULES.forEach((r, t) => { for (let i = 0; i < 10; i++) f[t * 12 + i] = r[i]; });
  rulesBuf = dev.createBuffer({ size: f.byteLength, usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST });
  dev.queue.writeBuffer(rulesBuf, 0, f);
  return rulesBuf;
}

async function runNauvis(mapSeed, rect, mode) {
  const ctx = await nauvisPipeline();
  const dev = ctx.dev;
  const w = rect.x1 - rect.x0, h = rect.y1 - rect.y0;
  const uniSize = 96; // 20 f32 + 3 u32 padded to 16
  const uni = dev.createBuffer({ size: uniSize, usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST });
  const p = new Float32Array(20);
  const nsm = 1.5;
  const vals = [rect.x0, rect.y0, nsm, 1.0, 0, nsm / 90, nsm / 500, 0.6, nsm / 150,
    nsm / 1600, nsm / 1600, nsm / 14, 0.03, 10000 / nsm, nsm / 2,
    ((1 - 0.7) / Math.pow(2, 5) / (1 - Math.pow(0.7, 5))) * 0.5, 10000 / nsm, 0, 0, 0];
  const lc = lakeCentre(mapSeed);
  vals[17] = lc[0]; vals[18] = lc[1];
  for (let i = 0; i < 20; i++) p[i] = vals[i];
  const dv = new DataView(uniSize === 96 ? new ArrayBuffer(uniSize) : null);
  // write float part via Float32 view, u32s at the tail
  const arr = new ArrayBuffer(uniSize);
  new Float32Array(arr).set(p, 0);
  const d = new DataView(arr);
  d.setUint32(80, w, true); d.setUint32(84, h, true); d.setUint32(88, mode, true);
  dev.queue.writeBuffer(uni, 0, arr);

  const t = uploadTables(dev, mapSeed);
  const rules = rulesStorage(dev);
  const outF = dev.createBuffer({ size: w * h * 4, usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC });
  const outF2 = dev.createBuffer({ size: w * h * 4, usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC });
  const outIdx = dev.createBuffer({ size: w * h * 4, usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC });
  const bind = dev.createBindGroup({
    layout: ctx.pipeline.getBindGroupLayout(0),
    entries: [
      { binding: 0, resource: { buffer: uni } },
      { binding: 1, resource: { buffer: t.perm1 } },
      { binding: 2, resource: { buffer: t.perm2 } },
      { binding: 3, resource: { buffer: t.grad } },
      { binding: 4, resource: { buffer: t.sb } },
      { binding: 5, resource: { buffer: rules } },
      { binding: 6, resource: { buffer: outF } },
      { binding: 7, resource: { buffer: outF2 } },
      { binding: 8, resource: { buffer: outIdx } },
    ],
  });
  const enc = dev.createCommandEncoder();
  const pass = enc.beginComputePass();
  pass.setPipeline(ctx.pipeline);
  pass.setBindGroup(0, bind);
  pass.dispatchWorkgroups(Math.ceil(w / 8), Math.ceil(h / 8));
  pass.end();
  dev.pushErrorScope("validation");
  dev.queue.submit([enc.finish()]);
  const verr = await dev.popErrorScope();
  if (verr) throw new Error("gpu validation: " + verr.message);

  const readB = dev.createBuffer({ size: w * h * 4, usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ });
  const readB2 = dev.createBuffer({ size: w * h * 4, usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ });
  const readB3 = dev.createBuffer({ size: w * h * 4, usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ });
  const enc2 = dev.createCommandEncoder();
  enc2.copyBufferToBuffer(outF, 0, readB, 0, w * h * 4);
  enc2.copyBufferToBuffer(outF2, 0, readB2, 0, w * h * 4);
  enc2.copyBufferToBuffer(outIdx, 0, readB3, 0, w * h * 4);
  dev.queue.submit([enc2.finish()]);
  const f1 = await readbackFloat(dev, readB, w * h);
  const f2 = await readbackFloat(dev, readB2, w * h);
  const u3 = await readbackU32(dev, readB3, w * h);
  return { f1, f2, idx: u3, width: w, height: h };
}

// CPU-derived surface params for a zone (se_wasm.zig surfaceParams export) —
// so WGSL kernels get the same numbers the wasm renderer uses.
let surfWasmP = null;
function loadSurfaceWasm() {
  if (!surfWasmP) {
    surfWasmP = fetch(location.origin + "/static/surface.wasm")
      .then((r) => r.arrayBuffer())
      .then((b) => WebAssembly.instantiate(b, {}));
  }
  return surfWasmP;
}
async function cpuSurfaceParams(req) {
  const { instance } = await loadSurfaceWasm();
  const e = instance.exports;
  const bytes = new TextEncoder().encode(JSON.stringify(req));
  if (bytes.length > e.inputCap()) e.growInput(bytes.length);
  new Uint8Array(e.memory.buffer).set(bytes, e.inputPtr());
  e.surfaceParams(bytes.length);
  return JSON.parse(new TextDecoder().decode(new Uint8Array(e.memory.buffer, e.resultPtr(), e.resultLen())));
}

// ── SE zone elevation (se_zone.wgsl) ───────────────────────────────────────
const SE_ELEV_S1 = [900, 99584, 700, 1000, 1100, 500, 600];
let seP = null; // { pipeline, dev }
let seTables = null; // { seed, bufs }

async function sePipeline() {
  if (seP) return seP;
  const dev = await getDevice();
  const code = await fetchShader("se_zone.wgsl");
  const module = dev.createShaderModule({ code });
  const info = await module.getCompilationInfo();
  const errs = (info.messages || []).filter((m) => m.type === "error");
  if (errs.length) throw new Error("se_zone.wgsl: " + errs.map((e) => e.lineNum + ":" + e.linePos + " " + e.message).join(" | "));
  const pipeline = dev.createComputePipeline({ layout: "auto", compute: { module, entryPoint: "main" } });
  seP = { pipeline, dev };
  return seP;
}

function seTablesFor(dev, zoneSeed) {
  if (seTables && seTables.seed === zoneSeed) return seTables;
  const n = SE_ELEV_S1.length;
  const perm1 = new Uint32Array(n * 256);
  const perm2 = new Uint32Array(n * 256);
  const grad = new Float32Array(n * 512);
  const sb = new Uint32Array(n);
  for (let gi = 0; gi < n; gi++) {
    const g = buildGen(zoneSeed, SE_ELEV_S1[gi]);
    perm1.set(g.perm1, gi * 256);
    perm2.set(g.perm2, gi * 256);
    grad.set(g.grad, gi * 512);
    sb[gi] = g.seedByte;
  }
  const mk = (arr, usage) => { const b = dev.createBuffer({ size: arr.byteLength, usage }); dev.queue.writeBuffer(b, 0, arr); return b; };
  seTables = { seed: zoneSeed,
    perm1: mk(perm1, GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST),
    perm2: mk(perm2, GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST),
    grad: mk(grad, GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST),
    sb: mk(sb, GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST) };
  return seTables;
}

// Run se_zone.wgsl elevation (mode 0) or water mask (mode 1) for an SE zone.
// `zone` = universe row; cpu params come from surface.wasm (surfaceParams).
async function runSEZone(mapSeed, zone, rect, mode) {
  const cp = await cpuSurfaceParams({ seed: mapSeed, k2: !!zone.k2, zone });
  if (!cp.ok) throw new Error(cp.error || "surfaceParams failed");
  const ctx = await sePipeline();
  const dev = ctx.dev;
  const w = rect.x1 - rect.x0, h = rect.y1 - rect.y0;
  const nsm = 1.5 * cp.water_frequency;
  const seg = cp.water_frequency;
  const waterLevel = 10 * Math.log2(cp.water_size);
  const osPers = ((1 - 0.7) / Math.pow(2, 5) / (1 - Math.pow(0.7, 5))) * 0.5;
  // uniform: 17 floats then width/height/mode u32s (80 bytes)
  const arr = new ArrayBuffer(80);
  const f = new Float32Array(arr);
  const v = [rect.x0, rect.y0, nsm, seg, waterLevel,
    nsm / 90, nsm / 500, 0.6, nsm / 150, nsm / 1600, nsm / 1600,
    nsm / 14, 0.03, 10000 / nsm, nsm / 2, osPers, 10000 / nsm];
  for (let i = 0; i < 17; i++) f[i] = v[i];
  const d = new DataView(arr);
  d.setUint32(68, w, true); d.setUint32(72, h, true); d.setUint32(76, mode, true);
  const uni = dev.createBuffer({ size: 80, usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST });
  dev.queue.writeBuffer(uni, 0, arr);

  const t = seTablesFor(dev, cp.zone_seed);
  const outF = dev.createBuffer({ size: w * h * 4, usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC });
  const outIdx = dev.createBuffer({ size: w * h * 4, usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC });
  const bind = dev.createBindGroup({
    layout: ctx.pipeline.getBindGroupLayout(0),
    entries: [
      { binding: 0, resource: { buffer: uni } },
      { binding: 1, resource: { buffer: t.perm1 } },
      { binding: 2, resource: { buffer: t.perm2 } },
      { binding: 3, resource: { buffer: t.grad } },
      { binding: 4, resource: { buffer: t.sb } },
      { binding: 5, resource: { buffer: outF } },
      { binding: 6, resource: { buffer: outIdx } },
    ],
  });
  const enc = dev.createCommandEncoder();
  const pass = enc.beginComputePass();
  pass.setPipeline(ctx.pipeline);
  pass.setBindGroup(0, bind);
  pass.dispatchWorkgroups(Math.ceil(w / 8), Math.ceil(h / 8));
  pass.end();
  dev.pushErrorScope("validation");
  dev.queue.submit([enc.finish()]);
  const verr = await dev.popErrorScope();
  if (verr) throw new Error("gpu validation: " + verr.message);

  const rB = dev.createBuffer({ size: w * h * 4, usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ });
  const rI = dev.createBuffer({ size: w * h * 4, usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ });
  const enc2 = dev.createCommandEncoder();
  enc2.copyBufferToBuffer(outF, 0, rB, 0, w * h * 4);
  enc2.copyBufferToBuffer(outIdx, 0, rI, 0, w * h * 4);
  dev.queue.submit([enc2.finish()]);
  const elev = await readbackFloat(dev, rB, w * h);
  const idx = await readbackU32(dev, rI, w * h);
  return { elev, idx, width: w, height: h };
}

self.onmessage = async function (ev) {
  const msg = ev.data;
  if (!msg || msg.id == null) return;
  try {
    if (msg.type !== "gpu-surface") throw new Error("bad type " + msg.type);
    const req = msg.req;
    if (req.kind === "se-params") {
      const p = await cpuSurfaceParams({ seed: req.seed, k2: !!req.k2, zone: req.zone });
      self.postMessage({ id: msg.id, ok: !!p.ok, summary: p, error: p.ok ? null : p.error });
      return;
    }
    if (req.kind === "se" || req.kind === "se-elev") {
      const rect = req.rect;
      const r = await runSEZone(req.seed >>> 0, req.zone, rect, req.kind === "se" ? 1 : 0);
      let pixels;
      if (req.kind === "se") {
        const n = r.width * r.height;
        pixels = new Uint8Array(n);
        for (let i = 0; i < n; i++) pixels[i] = r.idx[i];
      } else {
        pixels = new Float32Array(r.elev);
      }
      self.postMessage({ id: msg.id, ok: true, summary: { kind: req.kind, width: r.width, height: r.height }, pixels }, [pixels.buffer]);
      return;
    }
    const mapSeed = req.seed >>> 0;
    const rect = req.rect || { x0: -req.radius, y0: -req.radius, x1: req.radius, y1: req.radius };
    const kind = req.kind;
    const mode = kind === "elevation" ? 0 : kind === "fields" ? 1 : kind === "tiles" ? 2 : kind === "debug" ? 9 : -1;
    if (mode < 0) throw new Error("unsupported kind " + kind);
    const r = await runNauvis(mapSeed, rect, mode);
    let pixels = null;
    if (mode === 2) {
      const n = r.width * r.height;
      pixels = new Uint8Array(n);
      for (let i = 0; i < n; i++) pixels[i] = r.idx[i];
    } else {
      pixels = mode === 0 ? new Float32Array(r.f1) : new Float32Array(r.f1);
    }
    const extra = mode === 1 ? new Float32Array(r.f2) : null;
    self.postMessage({ id: msg.id, ok: true, summary: { kind, width: r.width, height: r.height }, pixels, extra },
      pixels ? [pixels.buffer].concat(extra ? [extra.buffer] : []) : []);
  } catch (e) {
    self.postMessage({ id: msg.id, ok: false, error: (e && e.message) || String(e) });
  }
};


let device = null, deviceP = null, shaders = {};

async function getDevice() {
  if (device) return device;
  if (!navigator.gpu) throw new Error("WebGPU unavailable");
  const adapter = await navigator.gpu.requestAdapter();
  if (!adapter) throw new Error("no WebGPU adapter");
  device = await adapter.requestDevice();
  deviceP = device;
  return device;
}

async function fetchShader(name) {
  if (!shaders[name]) {
    const r = await fetch("/static/shaders/" + name + "?_=" + Date.now(), { cache: "no-store" });
    if (!r.ok) throw new Error("shader " + name + " fetch failed");
    shaders[name] = await r.text();
  }
  return shaders[name];
}

function readbackU32(device, buf, count) {
  return buf.mapAsync(GPUMapMode.READ).then(() => {
    const arr = new Uint32Array(buf.size / 4);
    arr.set(new Uint32Array(buf.getMappedRange()));
    buf.unmap();
    return arr.slice(0, count);
  });
}

function padF32Uniform(n) { // WGSL uniform struct size is rounded to 16
  return Math.ceil(n / 4) * 4;
}

function readbackFloat(device, buf, count) {
  const res = buf.mapAsync(GPUMapMode.READ).then(() => {
    const arr = new Float32Array(buf.size / 4);
    arr.set(new Float32Array(buf.getMappedRange()));
    buf.unmap();
    return arr.slice(0, count);
  });
  return res;
}
