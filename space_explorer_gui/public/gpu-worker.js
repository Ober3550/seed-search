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

// elevation.wgsl gens: (seed0, seed1) = (map_seed, gi seed1s)
const ELEV_SEED1 = [900, 99584, 700, 1000, 1100, 500, 600];

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
    const r = await fetch("/static/shaders/" + name);
    if (!r.ok) throw new Error("shader " + name + " fetch failed");
    shaders[name] = await r.text();
  }
  return shaders[name];
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

// Elevation kernel context cached per device.
let elev = null;
async function elevationPipeline() {
  if (elev) return elev;
  const dev = await getDevice();
  const code = await fetchShader("elevation.wgsl");
  const module = dev.createShaderModule({ code });
  const pipeline = dev.createComputePipeline({
    layout: "auto",
    compute: { module, entryPoint: "main" },
  });
  // uniform buffer: 19 f32 floats -> padded 80
  const uniSize = 80;
  // table buffers: perm1 7*256 u32, perm2 7*256, grad 7*512 f32, seed_bytes 7 u32
  elev = { dev, pipeline, uniSize,
    perm1Size: 7 * 256 * 4, perm2Size: 7 * 256 * 4, gradSize: 7 * 512 * 4, sbSize: 7 * 4 };
  return elev;
}

// Compose the 7-gens table buffers for a map seed.
function buildElevTables(mapSeed) {
  const perm1 = new Uint32Array(7 * 256);
  const perm2 = new Uint32Array(7 * 256);
  const grad = new Float32Array(7 * 512);
  const sb = new Uint32Array(7);
  for (let gi = 0; gi < 7; gi++) {
    const g = buildGen(mapSeed, ELEV_SEED1[gi]);
    perm1.set(g.perm1, gi * 256);
    perm2.set(g.perm2, gi * 256);
    grad.set(g.grad, gi * 512);
    sb[gi] = g.seedByte;
  }
  return { perm1, perm2, grad, sb };
}

// Elevation params: mirror EParams field order in elevation.wgsl.
// origin_x, origin_y, nsm, seg, water_level, is_hills, is_cliff, os_cliff,
// is_bridge, is_macro1, is_macro2, is_detail, os_detail, offx_detail,
// is_pers, os_pers, offx_pers, width, height, slake_n
function setElevParams(buf, p) {
  const f = new Float32Array(buf);
  const o = [p.originX, p.originY, 1.5, 1.0, p.waterLevel,
    p.isHills, p.isCliff, 0.6, p.isBridge, p.isMacro1, p.isMacro2,
    p.isDetail, 0.03, p.offxDetail, p.isPers, p.osPers, p.offxPers,
    0, 0, 0];
  for (let i = 0; i < 17; i++) f[i] = o[i];
  // width/height/slake_n are u32 in EParams (offsets 17/18/19)
  const d = new DataView(buf);
  d.setUint32(17 * 4, p.width, true);
  d.setUint32(18 * 4, p.height, true);
  d.setUint32(19 * 4, 0, true);
}
// Elevation parameter values (terrain.Elevation defaults: nsm=1.5, seg=1).
function elevParamsFor(x0, y0, w, h) {
  const nsm = 1.5;
  return {
    originX: x0, originY: y0, waterLevel: 0,
    isHills: nsm / 90.0, isCliff: nsm / 500.0, isBridge: nsm / 150.0,
    isMacro1: nsm / 1600.0, isMacro2: nsm / 1600.0,
    isDetail: nsm / 14.0, offxDetail: 10000.0 / nsm,
    isPers: nsm / 2.0, osPers: ((1 - 0.7) / Math.pow(2, 5) / (1 - Math.pow(0.7, 5))) * 0.5,
    offxPers: 10000.0 / nsm,
    width: w, height: h,
  };
}

async function runElevation(mapSeed, rect) {
  const ctx = await elevationPipeline();
  const w = rect.x1 - rect.x0, h = rect.y1 - rect.y0;
  const dev = ctx.dev;

  const uni = dev.createBuffer({ size: ctx.uniSize, usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST });
  const paramsBuf = new ArrayBuffer(ctx.uniSize);
  setElevParams(paramsBuf, elevParamsFor(rect.x0, rect.y0, w, h));
  dev.queue.writeBuffer(uni, 0, paramsBuf);

  const tables = buildElevTables(mapSeed);
  const mk = (arr, usage) => {
    const b = dev.createBuffer({ size: arr.byteLength, usage });
    dev.queue.writeBuffer(b, 0, arr);
    return b;
  };
  const perm1B = mk(tables.perm1, GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST);
  const perm2B = mk(tables.perm2, GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST);
  const gradB = mk(tables.grad, GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST);
  const sbB = mk(tables.sb, GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST);
  const outB = dev.createBuffer({ size: w * h * 4, usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC });

  const bind = dev.createBindGroup({
    layout: ctx.pipeline.getBindGroupLayout(0),
    entries: [
      { binding: 0, resource: { buffer: uni } },
      { binding: 1, resource: { buffer: perm1B } },
      { binding: 2, resource: { buffer: perm2B } },
      { binding: 3, resource: { buffer: gradB } },
      { binding: 4, resource: { buffer: sbB } },
      { binding: 5, resource: { buffer: outB } },
    ],
  });

  const enc = dev.createCommandEncoder();
  const pass = enc.beginComputePass();
  pass.setPipeline(ctx.pipeline);
  pass.setBindGroup(0, bind);
  const gx = Math.ceil(w / 8), gy = Math.ceil(h / 8);
  pass.dispatchWorkgroups(gx, gy);
  pass.end();
  dev.queue.submit([enc.finish()]);

  // readback
  const readB = dev.createBuffer({ size: w * h * 4, usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ });
  const enc2 = dev.createCommandEncoder();
  enc2.copyBufferToBuffer(outB, 0, readB, 0, w * h * 4);
  dev.queue.submit([enc2.finish()]);
  return { grid: await readbackFloat(dev, readB, w * h), width: w, height: h };
}

self.onmessage = async function (ev) {
  const msg = ev.data;
  if (!msg || msg.id == null) return;
  try {
    if (msg.type !== "gpu-surface") throw new Error("bad type " + msg.type);
    const req = msg.req;
    const mapSeed = req.seed >>> 0;
    const rect = req.rect || { x0: -req.radius, y0: -req.radius, x1: req.radius, y1: req.radius };
    if (req.kind === "elevation" || req.kind === "water") {
      const r = await runElevation(mapSeed, rect);
      let pixels = null;
      if (req.kind === "water") {
        // tile index grid: 0 land, 1 water, 2 deepwater (e < 0; e < -2 deep)
        const n = r.width * r.height;
        pixels = new Uint8Array(n);
        for (let i = 0; i < n; i++) {
          const e = r.grid[i];
          pixels[i] = e < 0 ? (e < -2 ? 2 : 1) : 0;
        }
      } else {
        // return the raw f32 grid for debugging/comparison
        pixels = new Float32Array(r.grid);
      }
      self.postMessage({ id: msg.id, ok: true, summary: { kind: req.kind, width: r.width, height: r.height }, pixels }, pixels ? [pixels.buffer] : []);
    } else {
      throw new Error("unsupported kind " + req.kind);
    }
  } catch (e) {
    self.postMessage({ id: msg.id, ok: false, error: (e && e.message) || String(e) });
  }
};
