// Port of terrain.zig ZoneTerrain temperature/moisture/aux (alien-biomes).
// These use quick_multioctave_noise: a FRESH generator per octave (seed0+k), so
// we upload 27 generator sets — temp 11 (seed1=5, idx 0..10), moisture 8
// (seed1=6, idx 11..18), aux 8 (seed1=7, idx 19..26) — into shared table
// buffers. Field math is f32 on the CPU too, so this should track tightly.

struct Params {
    origin_x : f32,
    origin_y : f32,
    cold_size : f32,
    hot_size : f32,
    cold_freq : f32,
    hot_freq : f32,
    moist_freq : f32,
    moist_bias : f32,
    aux_freq : f32,
    aux_bias : f32,
    width : u32,
    height : u32,
};

@group(0) @binding(0) var<uniform>              P          : Params;
@group(0) @binding(1) var<storage, read>        perm1      : array<u32>;  // 27*256
@group(0) @binding(2) var<storage, read>        perm2      : array<u32>;  // 27*256
@group(0) @binding(3) var<storage, read>        grad       : array<f32>;  // 27*512
@group(0) @binding(4) var<storage, read>        seed_bytes : array<u32>;  // 27
@group(0) @binding(5) var<storage, read_write>  out        : array<f32>;   // 3*width*height

const TEMP_BASE  : u32 = 0u;
const MOIST_BASE : u32 = 11u;
const AUX_BASE   : u32 = 19u;

fn basisG(gi : u32, x : f32, y : f32, scale : f32, offx : f32, offy : f32) -> f32 {
    let po = gi * 256u;
    let go = gi * 512u;
    let sb = seed_bytes[gi];
    let X = (x + offx) * scale;
    let Y = (y + offy) * scale;
    let ix = i32(floor(X));
    let iy = i32(floor(Y));
    let fx = X - f32(ix);
    let fy = Y - f32(iy);
    var sum : f32 = 0.0;
    for (var cy : i32 = 0; cy <= 1; cy = cy + 1) {
        for (var cx : i32 = 0; cx <= 1; cx = cx + 1) {
            let p1 = perm1[po + ((bitcast<u32>(iy + cy)) & 255u)];
            let p2 = perm2[po + ((bitcast<u32>(ix + cx)) & 255u)];
            let idx = (p1 ^ sb ^ p2);
            let dx = fx - f32(cx);
            let dy = fy - f32(cy);
            let d2 = dx * dx + dy * dy;
            if (d2 < 1.0) {
                let w = 1.0 - d2;
                sum = sum + (grad[go + 2u * idx] * dx + grad[go + 2u * idx + 1u] * dy) * w * w * w;
            }
        }
    }
    return sum;
}

// quick_multioctave: fresh gen per octave (gbase+k), input/output scale multiply
// by oism/oosm each octave, tile-space offset.
fn quickMulti(gbase : u32, x : f32, y : f32, octaves : u32, inscale : f32, outscale : f32, oism : f32, oosm : f32, offx : f32, offy : f32) -> f32 {
    var result : f32 = 0.0;
    var is = inscale;
    var os = outscale;
    for (var k : u32 = 0u; k < octaves; k = k + 1u) {
        result = result + basisG(gbase + k, x, y, is, offx, offy) * os;
        is = is * oism;
        os = os * oosm;
    }
    return result;
}

fn clampf(v : f32, lo : f32, hi : f32) -> f32 { return clamp(v, lo, hi); }

fn temperature(x : f32, y : f32) -> f32 {
    let cold = P.cold_size;
    let hot = P.hot_size;
    let cf = P.cold_freq;
    let hf = P.hot_freq;
    let average = 50.0 - 125.0 * cold / 6.0 + 125.0 * hot / 6.0;
    let range = 50.0 * (clampf(cold, 0.0, 1.0) / 2.0 + cold / 10.0) + 50.0 * (clampf(hot, 0.0, 1.0) / 2.0 + hot / 10.0);

    let bfreq = (cf + hf) / 2.0;
    let main_noise = quickMulti(TEMP_BASE, x * bfreq, y * bfreq, 11u, 1.0 / 32.0, 1.0 / 20.0, 0.5, 1.4, 0.0, 40000.0);
    let base = average + range * clampf(0.25 * main_noise, -1.0, 1.0);

    let hotspots_noise = quickMulti(TEMP_BASE, x * hf, y * hf, 10u, 1.0 / 8.0, 1.0 / 20.0, 0.5, 1.5, 40000.0, 0.0);
    let hotspots = (clampf(hot, 0.0, 1.0) / 2.0 + hot / 10.0) * 40.0 * clampf(-0.45 + hot / 6.0 + hotspots_noise, 0.0, 4.0);

    let coldspots_noise = quickMulti(TEMP_BASE, x * cf, y * cf, 10u, 1.0 / 30.0, 1.0 / 20.0, 0.5, 1.5, -40000.0, 0.0);
    let coldspots = (clampf(cold, 0.0, 1.0) / 2.0 + cold / 10.0) * 40.0 * clampf(-0.45 + cold / 6.0 + coldspots_noise, 0.0, 4.0);

    let combined = clampf(base - coldspots + hotspots, -50.0, 110.0);
    let volcanic_area = clampf(combined - 100.0, 0.0, 10.0);
    let vhn = quickMulti(TEMP_BASE, x, y, 6u, 1.0, 1.0 / 20.0, 0.5, 1.5, 0.0, 0.0);
    let volcanic_hotspots = clampf(0.5 + vhn, 0.0, 10.0) * volcanic_area * 4.0;
    return clampf(combined + volcanic_hotspots, -20.0, 150.0);
}

fn moisture(x : f32, y : f32) -> f32 {
    let q = quickMulti(MOIST_BASE, x * P.moist_freq, y * P.moist_freq, 8u, 1.0 / 2000.0, 1.0 / 8.0, 3.0, 0.5, 30000.0, 0.0);
    return clampf(0.5 + 2.2 * P.moist_bias + 2.5 * q, 0.0, 1.0);
}

fn aux(x : f32, y : f32) -> f32 {
    let q = quickMulti(AUX_BASE, x * P.aux_freq, y * P.aux_freq, 8u, 1.0 / 5000.0, 1.0 / 4.0, 3.0, 0.5, 20000.0, 0.0);
    return clampf(0.45 + 2.2 * P.aux_bias + 2.2 * q, 0.0, 1.0);
}

@compute @workgroup_size(8, 8)
fn main(@builtin(global_invocation_id) gid : vec3<u32>) {
    if (gid.x >= P.width || gid.y >= P.height) { return; }
    let x = P.origin_x + f32(gid.x);
    let y = P.origin_y + f32(gid.y);
    let idx = gid.y * P.width + gid.x;
    let n = P.width * P.height;
    out[idx] = temperature(x, y);
    out[n + idx] = moisture(x, y);
    out[2u * n + idx] = aux(x, y);
}
