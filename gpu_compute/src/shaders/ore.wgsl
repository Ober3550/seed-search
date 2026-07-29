// SE ore placement — per-tile eval on the GPU. Ported from
// surface_generator/src/se_ore_placement.zig (allPatchesValueDirect +
// evalTileForState). The CPU generates the spots (region RNG) and per-resource
// params and uploads them; this kernel does the hot per-tile work. All math f32
// (the CPU f64 path stays the exact oracle). One dispatch PER RESOURCE; each
// updates a per-tile winner buffer (highest probability, ties by richness).
//
// The asteroid mask (0=space,1=asteroid,2=out-of-map) is precomputed and bound;
// only asteroid tiles are evaluated. Placement roll is a position hash, so
// gating by the mask is exact (no RNG-stream dependency).

struct Params {
    origin_x : f32,
    origin_y : f32,
    width : u32,
    height : u32,
    zone_radius : f32,
    // SEField params (for blobAmplitudeAt + density)
    base_density : f32,
    freq_mult : f32,
    size_mult : f32,
    base_spots_per_km2 : f32,
    rq : f32,
    smin : f32,
    smax : f32,
    basement_value : f32,
    // richness + roll
    richness_mult : f32,
    additional_richness : f32,
    random_probability : f32,
    roll_salt : u32,
    seed_byte : u32,
    res_index : u32,
    has_starting : u32,
    starting_blob_amplitude : f32,
    nspots : u32,
    nstart : u32,
};

@group(0) @binding(0) var<uniform>             P      : Params;
@group(0) @binding(1) var<storage, read>       perm1  : array<u32>;   // 256
@group(0) @binding(2) var<storage, read>       perm2  : array<u32>;   // 256
@group(0) @binding(3) var<storage, read>       grad   : array<f32>;   // 512
@group(0) @binding(4) var<storage, read>       spots  : array<vec4<f32>>; // x,y,peak,slope
@group(0) @binding(5) var<storage, read>       sspots : array<vec4<f32>>; // starting spots
@group(0) @binding(6) var<storage, read>       mask   : array<u32>;   // asteroid mask
@group(0) @binding(7) var<storage, read_write> win    : array<vec4<u32>>; // [prob,rich,res,amount] bitcast

const PI : f32 = 3.14159265358979;
const MAX_BASEMENT_RADIUS : f32 = 128.0;
const START_MAX_BASEMENT_RADIUS : f32 = 64.0;
const STARTING_RADIUS : f32 = 140.0;
const REGULAR_FADE_IN : f32 = 320.0;
const DOUBLE_DENSITY : f32 = 5000.0;
const SPOT_ENLARGE_MAX : f32 = 5320.0; // DOUBLE_DENSITY + REGULAR_FADE_IN

fn clamp01(v : f32) -> f32 { return clamp(v, 0.0, 1.0); }
fn cbrtf(v : f32) -> f32 { return pow(max(v, 0.0), 1.0 / 3.0); }

// --- basis (surflet gradient noise), identical to noise.wgsl/asteroid.wgsl ---
fn basis(x : f32, y : f32, scale : f32) -> f32 {
    let X = x * scale;
    let Y = y * scale;
    let ix = i32(floor(X));
    let iy = i32(floor(Y));
    let fx = X - f32(ix);
    let fy = Y - f32(iy);
    var sum : f32 = 0.0;
    for (var cy : i32 = 0; cy <= 1; cy = cy + 1) {
        for (var cx : i32 = 0; cx <= 1; cx = cx + 1) {
            let p1 = perm1[(bitcast<u32>(iy + cy)) & 255u];
            let p2 = perm2[(bitcast<u32>(ix + cx)) & 255u];
            let gi = (p1 ^ P.seed_byte ^ p2);
            let dx = fx - f32(cx);
            let dy = fy - f32(cy);
            let d2 = dx * dx + dy * dy;
            if (d2 < 1.0) {
                let w = 1.0 - d2;
                sum = sum + (grad[2u * gi] * dx + grad[2u * gi + 1u] * dy) * w * w * w;
            }
        }
    }
    return sum;
}

// multioctaveNoisePrebuilt(x, y, octaves, persistence, input_scale, output_scale=1)
fn multioctave(x : f32, y : f32, octaves : u32, ampmul : f32, is : f32) -> f32 {
    var value : f32 = 0.0;
    var amplitude : f32 = 1.0;
    var coordmul : f32 = 1.0;
    var sumsq : f32 = 0.0;
    var k : f32 = 0.0;
    for (var i : u32 = 0u; i < octaves; i = i + 1u) {
        value = value + basis((k * 17.17) / is + x * coordmul, y * coordmul, is) * amplitude;
        sumsq = sumsq + amplitude * amplitude;
        coordmul = coordmul * 0.5;
        amplitude = amplitude * ampmul;
        k = k + 1.0;
    }
    return value / sqrt(sumsq);
}

// max cone over spots within basement_radius: max(basement, peak - dist*slope)
fn spotValue(is_start : bool, basement : f32, basement_radius : f32, x : f32, y : f32) -> f32 {
    var value = basement;
    let n = select(P.nspots, P.nstart, is_start);
    for (var i : u32 = 0u; i < n; i = i + 1u) {
        let sp = select(spots[i], sspots[i], is_start);
        let ddx = x - sp.x;
        let ddy = y - sp.y;
        let dist = sqrt(ddx * ddx + ddy * ddy);
        if (dist <= basement_radius) {
            let v = sp.z - dist * sp.w;
            if (v > value) { value = v; }
        }
    }
    return value;
}

fn regularDensityAt(dist : f32) -> f32 {
    let fade = clamp01((dist - STARTING_RADIUS) / REGULAR_FADE_IN);
    let size_eff = dist - REGULAR_FADE_IN;
    let doubling = 1.0 + clamp01(size_eff / DOUBLE_DENSITY);
    return P.base_density * P.freq_mult * P.size_mult * fade * doubling;
}
fn typicalHeightAt(dist : f32) -> f32 {
    let q_base = regularDensityAt(dist) * 1000000.0 / (P.base_spots_per_km2 * P.freq_mult);
    return cbrtf((P.smin + P.smax) / 2.0 * q_base) / (PI / 3.0 * P.rq * P.rq);
}
fn blobAmplitudeAt(x : f32, y : f32) -> f32 {
    let dist = sqrt(x * x + y * y);
    return (1.0 / 8.0) * min(typicalHeightAt(SPOT_ENLARGE_MAX), typicalHeightAt(dist));
}
fn richnessDistance(x : f32, y : f32) -> f32 {
    let dist = min(sqrt(x * x + y * y), DOUBLE_DENSITY);
    let sed = dist - REGULAR_FADE_IN;
    return max(1.0, (DOUBLE_DENSITY + sed) / (DOUBLE_DENSITY + DOUBLE_DENSITY));
}

// allPatchesValueDirect
fn allPatches(x : f32, y : f32, blob_amp : f32, start_blob_amp : f32, blobs0 : f32) -> f32 {
    let spot_v = spotValue(false, P.basement_value, MAX_BASEMENT_RADIUS, x, y);
    let blob = blobs0 + 1.5 * basis(x, y, 1.0 / 64.0) - 1.0 / 3.0;
    let vein = 1.0 - 10.0 * abs(multioctave(x, y, 6u, 2.0, 1.0 / 4.0));
    let regular = spot_v + (blob + 0.8 * vein) * blob_amp;
    if (P.has_starting == 1u) {
        let ssv = spotValue(true, P.basement_value, START_MAX_BASEMENT_RADIUS, x, y);
        let start_vein = 1.0 - 10.0 * abs(multioctave(x, y, 6u, 2.0, 1.0));
        let starting = ssv + (0.4 * (blobs0 - 0.25) + 0.2 * start_vein) * start_blob_amp;
        return max(regular, starting);
    }
    return regular;
}

// triple-LFSR placement roll (position-hashed) -> uniform f32 in [0,1)
fn lfsr(s : ptr<function, vec3<u32>>) -> u32 {
    (*s).x = (((*s).x & 0xFFFFFFFEu) << 12u) ^ ((((*s).x << 13u) ^ (*s).x) >> 19u);
    (*s).y = (((*s).y & 0xFFFFFFF8u) << 4u)  ^ ((((*s).y << 2u)  ^ (*s).y) >> 25u);
    (*s).z = (((*s).z & 0xFFFFFFF0u) << 17u) ^ ((((*s).z << 3u)  ^ (*s).z) >> 11u);
    return (*s).x ^ (*s).y ^ (*s).z;
}
fn placementRoll(ix : i32, iy : i32) -> f32 {
    var seed = (bitcast<u32>(ix) * 73856093u) ^ (bitcast<u32>(iy) * 19349663u) ^ P.roll_salt;
    if (seed < 341u) { seed = 341u; }
    var s = vec3<u32>(seed, seed, seed);
    let _d = lfsr(&s);            // warmup discard
    let v = lfsr(&s);
    return f32(v) * 2.3283064365386963e-10;
}

@compute @workgroup_size(8, 8)
fn main(@builtin(global_invocation_id) gid : vec3<u32>) {
    if (gid.x >= P.width || gid.y >= P.height) { return; }
    let i = gid.y * P.width + gid.x;
    if (mask[i] != 1u) { return; }               // asteroid tiles only
    let x = P.origin_x + f32(gid.x);
    let y = P.origin_y + f32(gid.y);
    if (sqrt(x * x + y * y) > P.zone_radius) { return; }

    let blob_amp = blobAmplitudeAt(x, y);
    let blobs0 = basis(x, y, 1.0 / 8.0) + basis(x, y, 1.0 / 24.0);
    let value = allPatches(x, y, blob_amp, P.starting_blob_amplitude, blobs0);
    var p = clamp01(value);
    if (p <= 0.0) { return; }
    // (field resources have random_probability == 1: no per-chunk penalty)
    if (placementRoll(i32(x), i32(y)) >= p) { return; }

    var richness = value;
    if (P.additional_richness > 0.0) { richness = richness + P.additional_richness; }
    richness = richness * richnessDistance(x, y) * P.richness_mult;
    let amount = u32(floor(richness));
    if (amount == 0u) { return; }

    // winner: higher probability, ties by higher richness
    let cur = win[i];
    let cur_p = bitcast<f32>(cur.x);
    let cur_r = bitcast<f32>(cur.y);
    if (p > cur_p || (p == cur_p && richness > cur_r)) {
        win[i] = vec4<u32>(bitcast<u32>(p), bitcast<u32>(richness), P.res_index, amount);
    }
}
