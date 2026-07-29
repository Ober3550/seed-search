// SE ore placement — FUSED per-tile eval on the GPU. Ported from
// surface_generator/src/se_ore_placement.zig (allPatchesValueDirect +
// evalTileForState). ONE dispatch evaluates ALL resources per tile and writes
// the winner directly, packed (res+1, richness f32 bits) into `out`.
//
// The fusion is exact and a ~2x win because every SE ore resource shares the
// SAME spot-noise generator (seed1 == 100 everywhere — verified in the dump):
// perm1/perm2/grad/seed_byte are identical, so blobs0/blob/vein/start_vein are
// computed ONCE per tile and reused for all resources. Only the spot cones
// (per-resource spot lists), the density/richness params, and the placement-roll
// salt differ per resource. The shared per-tile gate (disk + water/asteroid mask)
// also runs once instead of once per resource.
//
// The asteroid mask (0=space,1=asteroid,2=out-of-map) / biome index (planets,
// water = >=60000) is precomputed and bound. Placement roll is a position hash,
// so gating by the mask is exact (no RNG-stream dependency). f32 math (the CPU
// f64 path stays the exact oracle).

struct Shared {
    origin_x : f32,
    origin_y : f32,
    width : u32,
    height : u32,
    zone_radius : f32,
    seed_byte : u32,   // shared generator (seed1 == 100 for every resource)
    is_field : u32,    // 1 → binding 6 is the asteroid mask (0/1/2); 0 → biome index
    nres : u32,
    has_any_start : u32, // any resource has a starting patch → compute start_vein
    pad0 : u32,
    pad1 : u32,
    pad2 : u32,
};

// Per-resource params (std430; 20 words = 80 B stride).
struct Res {
    base_density : f32,
    freq_mult : f32,
    size_mult : f32,
    base_spots_per_km2 : f32,
    rq : f32,
    smin : f32,
    smax : f32,
    basement_value : f32,
    richness_mult : f32,
    additional_richness : f32,
    starting_blob_amplitude : f32,
    roll_salt : u32,
    res_index : u32,
    has_starting : u32,
    restrict_bit : u32,  // se-vulcanite=1, se-cryonite=2, se-vitamelange=4, else 0
    spot_off : u32,      // start index of this resource's spots in `spots`
    nspots : u32,
    start_off : u32,     // start index in `sspots`
    nstart : u32,
    pad0 : u32,
};

// perm1+perm2 are merged into one buffer ([0,256)=perm1, [256,512)=perm2) to stay
// within the 8-storage-buffer-per-stage limit on Apple GPUs.
@group(0) @binding(0) var<uniform>             P      : Shared;
@group(0) @binding(1) var<storage, read>       perm   : array<u32>;   // 512, shared gen
@group(0) @binding(2) var<storage, read>       grad   : array<f32>;   // 512, shared gen
@group(0) @binding(3) var<storage, read>       spots  : array<vec4<f32>>; // all resources' spots concatenated
@group(0) @binding(4) var<storage, read>       sspots : array<vec4<f32>>; // all resources' starting spots
@group(0) @binding(5) var<storage, read>       terr   : array<u32>;   // field: asteroid mask; planet: biome index
@group(0) @binding(6) var<storage, read_write> out    : array<vec2<u32>>; // (res+1, richness f32 bits); (0,0)=empty
@group(0) @binding(7) var<storage, read>       restrict_tbl : array<u32>; // per-biome restrict bitmask (planets)
@group(0) @binding(8) var<storage, read>       resp   : array<Res>;   // per-resource params

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
            let p1 = perm[(bitcast<u32>(iy + cy)) & 255u];
            let p2 = perm[256u + ((bitcast<u32>(ix + cx)) & 255u)];
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

// max cone over spots[off .. off+n] within basement_radius: max(basement, peak - dist*slope)
fn spotCone(off : u32, n : u32, is_start : bool, basement : f32, basement_radius : f32, x : f32, y : f32) -> f32 {
    var value = basement;
    for (var i : u32 = 0u; i < n; i = i + 1u) {
        let sp = select(spots[off + i], sspots[off + i], is_start);
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

fn regularDensityAt(r : Res, dist : f32) -> f32 {
    let fade = clamp01((dist - STARTING_RADIUS) / REGULAR_FADE_IN);
    let size_eff = dist - REGULAR_FADE_IN;
    let doubling = 1.0 + clamp01(size_eff / DOUBLE_DENSITY);
    return r.base_density * r.freq_mult * r.size_mult * fade * doubling;
}
fn typicalHeightAt(r : Res, dist : f32) -> f32 {
    let q_base = regularDensityAt(r, dist) * 1000000.0 / (r.base_spots_per_km2 * r.freq_mult);
    return cbrtf((r.smin + r.smax) / 2.0 * q_base) / (PI / 3.0 * r.rq * r.rq);
}
fn blobAmplitudeAt(r : Res, x : f32, y : f32) -> f32 {
    let dist = sqrt(x * x + y * y);
    return (1.0 / 8.0) * min(typicalHeightAt(r, SPOT_ENLARGE_MAX), typicalHeightAt(r, dist));
}
fn richnessDistance(x : f32, y : f32) -> f32 {
    let dist = min(sqrt(x * x + y * y), DOUBLE_DENSITY);
    let sed = dist - REGULAR_FADE_IN;
    return max(1.0, (DOUBLE_DENSITY + sed) / (DOUBLE_DENSITY + DOUBLE_DENSITY));
}

// triple-LFSR placement roll (position-hashed) -> uniform f32 in [0,1)
fn lfsr(s : ptr<function, vec3<u32>>) -> u32 {
    (*s).x = (((*s).x & 0xFFFFFFFEu) << 12u) ^ ((((*s).x << 13u) ^ (*s).x) >> 19u);
    (*s).y = (((*s).y & 0xFFFFFFF8u) << 4u)  ^ ((((*s).y << 2u)  ^ (*s).y) >> 25u);
    (*s).z = (((*s).z & 0xFFFFFFF0u) << 17u) ^ ((((*s).z << 3u)  ^ (*s).z) >> 11u);
    return (*s).x ^ (*s).y ^ (*s).z;
}
fn placementRoll(ix : i32, iy : i32, salt : u32) -> f32 {
    var seed = (bitcast<u32>(ix) * 73856093u) ^ (bitcast<u32>(iy) * 19349663u) ^ salt;
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
    out[i] = vec2<u32>(0u, 0u); // default empty (gated tiles keep this)

    let t = terr[i];
    if (P.is_field == 1u) {
        if (t != 1u) { return; }        // asteroid tiles only
    } else {
        if (t >= 60000u) { return; }    // water tile → no ore
    }
    let x = P.origin_x + f32(gid.x);
    let y = P.origin_y + f32(gid.y);
    if (sqrt(x * x + y * y) > P.zone_radius) { return; }
    let ix = i32(x);
    let iy = i32(y);

    // Shared spot-noise field (identical for every resource — seed1 == 100).
    let blobs0 = basis(x, y, 1.0 / 8.0) + basis(x, y, 1.0 / 24.0);
    let blob = blobs0 + 1.5 * basis(x, y, 1.0 / 64.0) - 1.0 / 3.0;
    let vein = 1.0 - 10.0 * abs(multioctave(x, y, 6u, 2.0, 1.0 / 4.0));
    var start_vein : f32 = 0.0;
    if (P.has_any_start == 1u) {
        start_vein = 1.0 - 10.0 * abs(multioctave(x, y, 6u, 2.0, 1.0));
    }

    var best_p : f32 = 0.0;
    var best_rich : f32 = 0.0;
    var best_res : u32 = 0u;
    var have : bool = false;

    for (var r : u32 = 0u; r < P.nres; r = r + 1u) {
        let rp = resp[r];
        // biome tile_restriction (vulcanite/cryonite/vitamelange only)
        if (P.is_field == 0u && rp.restrict_bit != 0u && (restrict_tbl[t] & rp.restrict_bit) == 0u) { continue; }

        let blob_amp = blobAmplitudeAt(rp, x, y);
        let spot_v = spotCone(rp.spot_off, rp.nspots, false, rp.basement_value, MAX_BASEMENT_RADIUS, x, y);
        let regular = spot_v + (blob + 0.8 * vein) * blob_amp;
        var value = regular;
        if (rp.has_starting == 1u) {
            let ssv = spotCone(rp.start_off, rp.nstart, true, rp.basement_value, START_MAX_BASEMENT_RADIUS, x, y);
            let starting = ssv + (0.4 * (blobs0 - 0.25) + 0.2 * start_vein) * rp.starting_blob_amplitude;
            value = max(regular, starting);
        }
        let p = clamp01(value);
        if (p <= 0.0) { continue; }
        // (dumped resources have random_probability == 1: no per-chunk penalty)
        if (placementRoll(ix, iy, rp.roll_salt) >= p) { continue; }

        var richness = value;
        if (rp.additional_richness > 0.0) { richness = richness + rp.additional_richness; }
        richness = richness * richnessDistance(x, y) * rp.richness_mult;
        if (floor(richness) < 1.0) { continue; } // amount 0 → no ore

        if (!have || p > best_p || (p == best_p && richness > best_rich)) {
            best_p = p;
            best_rich = richness;
            best_res = rp.res_index;
            have = true;
        }
    }

    if (have) { out[i] = vec2<u32>(best_res + 1u, bitcast<u32>(best_rich)); }
}
