// Chained end-to-end terrain render: per tile computes elevation + temperature
// + moisture + aux, classifies the biome, and writes the winning tile index.
// Combines the Phase 2/3a/3b kernels into one dispatch. All 192 generators are
// packed into shared table buffers:
//   elevation  0..6    (hills,cliff,bridge,macro1,macro2,pers,detail)
//   temperature 7..17  moisture 18..25  aux 26..33
//   biome tv   34..189  water 190  crater 191

struct Params {
    origin_x : f32, origin_y : f32,
    nsm : f32, seg : f32, water_level : f32,
    is_hills : f32, is_cliff : f32, os_cliff : f32, is_bridge : f32,
    is_macro1 : f32, is_macro2 : f32,
    is_detail : f32, os_detail : f32, offx_detail : f32,
    is_pers : f32, os_pers : f32, offx_pers : f32,
    cold_size : f32, hot_size : f32, cold_freq : f32, hot_freq : f32,
    moist_freq : f32, moist_bias : f32, aux_freq : f32, aux_bias : f32,
    width : u32, height : u32, n_biomes : u32,
    has_water : u32,        // 0 → force elevation = 1.0 (no water tiles)
    pad0 : u32, pad1 : u32, pad2 : u32,
};

struct BiomeGPU {
    t_lo : f32, t_hi : f32, m_lo : f32, m_hi : f32,
    a_lo : f32, a_hi : f32, e_lo : f32, e_hi : f32,
    water_coef : f32, flags : u32, pad0 : u32, pad1 : u32,
};

@group(0) @binding(0) var<uniform>              P          : Params;
@group(0) @binding(1) var<storage, read>        perm1      : array<u32>;
@group(0) @binding(2) var<storage, read>        perm2      : array<u32>;
@group(0) @binding(3) var<storage, read>        grad       : array<f32>;
@group(0) @binding(4) var<storage, read>        seed_bytes : array<u32>;
@group(0) @binding(5) var<storage, read>        biomes     : array<BiomeGPU>;
@group(0) @binding(6) var<storage, read_write>  out        : array<u32>;

const ELEV_HILLS : u32 = 0u; const ELEV_CLIFF : u32 = 1u; const ELEV_BRIDGE : u32 = 2u;
const ELEV_MACRO1 : u32 = 3u; const ELEV_MACRO2 : u32 = 4u; const ELEV_PERS : u32 = 5u; const ELEV_DETAIL : u32 = 6u;
const TEMP_BASE : u32 = 7u; const MOIST_BASE : u32 = 18u; const AUX_BASE : u32 = 26u;
const TV_BASE : u32 = 34u; const WATER_GI : u32 = 190u; const CRATER_GI : u32 = 191u;
const AMP075 : f32 = 1.0 / 0.75;
const IDX_WATER : u32 = 60000u; const IDX_DEEPWATER : u32 = 60001u; const IDX_SHALLOW : u32 = 60002u; const IDX_MUD : u32 = 60003u;

fn basisG(gi : u32, x : f32, y : f32, scale : f32, offx : f32, offy : f32) -> f32 {
    let po = gi * 256u; let go = gi * 512u; let sb = seed_bytes[gi];
    let X = (x + offx) * scale; let Y = (y + offy) * scale;
    let ix = i32(floor(X)); let iy = i32(floor(Y));
    let fx = X - f32(ix); let fy = Y - f32(iy);
    var sum : f32 = 0.0;
    for (var cy : i32 = 0; cy <= 1; cy = cy + 1) {
        for (var cx : i32 = 0; cx <= 1; cx = cx + 1) {
            let p1 = perm1[po + ((bitcast<u32>(iy + cy)) & 255u)];
            let p2 = perm2[po + ((bitcast<u32>(ix + cx)) & 255u)];
            let idx = (p1 ^ sb ^ p2);
            let dx = fx - f32(cx); let dy = fy - f32(cy);
            let d2 = dx * dx + dy * dy;
            if (d2 < 1.0) {
                let w = 1.0 - d2;
                sum = sum + (grad[go + 2u * idx] * dx + grad[go + 2u * idx + 1u] * dy) * w * w * w;
            }
        }
    }
    return sum;
}

fn multioctaveG(gi : u32, x : f32, y : f32, octaves : u32, ampmul : f32, is : f32, os : f32, offx : f32, offy : f32) -> f32 {
    let xo = x + offx; let yo = y + offy;
    var value : f32 = 0.0; var amplitude : f32 = 1.0; var coordmul : f32 = 1.0; var sumsq : f32 = 0.0; var k : f32 = 0.0;
    for (var i : u32 = 0u; i < octaves; i = i + 1u) {
        value = value + basisG(gi, (k * 17.17) / is + xo * coordmul, yo * coordmul, is, 0.0, 0.0) * amplitude;
        sumsq = sumsq + amplitude * amplitude;
        coordmul = coordmul * 0.5; amplitude = amplitude * ampmul; k = k + 1.0;
    }
    return (value / sqrt(sumsq)) * os;
}

fn variablePersistenceG(gi : u32, x : f32, y : f32, octaves : u32, is : f32, os : f32, offx : f32, offy : f32, persistence : f32) -> f32 {
    var is_k = is * 0.5; var acc : f32 = 0.0;
    for (var k : u32 = 0u; k < octaves; k = k + 1u) { acc = acc * persistence + basisG(gi, x, y, is_k, offx, offy); is_k = is_k * 0.5; }
    return acc * os * pow(2.0, f32(octaves));
}

fn quickMulti(gbase : u32, x : f32, y : f32, octaves : u32, inscale : f32, outscale : f32, oism : f32, oosm : f32, offx : f32, offy : f32) -> f32 {
    var result : f32 = 0.0; var is = inscale; var os = outscale;
    for (var k : u32 = 0u; k < octaves; k = k + 1u) { result = result + basisG(gbase + k, x, y, is, offx, offy) * os; is = is * oism; os = os * oosm; }
    return result;
}

fn plateauPeak(v : f32, lo : f32, hi : f32) -> f32 {
    let center = (lo + hi) / 2.0; let range = abs(lo - hi) / 2.0;
    return min((range - abs(v - center)) * 20.0, 1.0);
}

fn elevationAt(x : f32, y : f32) -> f32 {
    let nauvis_hills = abs(multioctaveG(ELEV_HILLS, x, y, 4u, 2.0, P.is_hills, 1.0, 0.0, 0.0));
    let cliff_level = clamp(0.65 + basisG(ELEV_CLIFF, x, y, P.is_cliff, 0.0, 0.0) * P.os_cliff, 0.15, 1.15);
    let plateaus = 0.5 + clamp((nauvis_hills - cliff_level) * 10.0, -0.5, 0.5);
    let hills_plateaus = 0.1 * nauvis_hills + 0.8 * plateaus;
    let bb = abs(multioctaveG(ELEV_BRIDGE, x, y, 4u, 2.0, P.is_bridge, 1.0, 0.0, 0.0));
    let bridges = 1.0 - 0.1 * bb - 0.9 * max(0.0, -0.1 + bb);
    let nauvis_macro = multioctaveG(ELEV_MACRO1, x, y, 2u, 1.0 / 0.6, P.is_macro1, 1.0, 0.0, 0.0) * max(0.0, multioctaveG(ELEV_MACRO2, x, y, 1u, 1.0 / 0.6, P.is_macro2, 1.0, 0.0, 0.0));
    let persist = clamp(variablePersistenceG(ELEV_PERS, x, y, 5u, P.is_pers, P.os_pers, P.offx_pers, 0.0, 0.7) + 0.55, 0.5, 0.65);
    let detail = variablePersistenceG(ELEV_DETAIL, x, y, 5u, P.is_detail, P.os_detail, P.offx_detail, 0.0, persist);
    let dist = sqrt(x * x + y * y);
    let smm = clamp(dist * P.nsm / 2000.0, 0.0, 1.0);
    let cliff = hills_plateaus;
    let nauvis_main = 20.0 * (mix(0.5 * cliff - 0.6, 1.9 * cliff + 1.6, 0.1 + 0.5 * bridges) + 0.25 * detail + 3.0 * nauvis_macro * smm);
    let starting_island = nauvis_main + 20.0 * (2.5 - dist * P.seg / 200.0);
    return max(nauvis_main - P.water_level * 2.0, starting_island);
}

fn clampf(v : f32, lo : f32, hi : f32) -> f32 { return clamp(v, lo, hi); }

fn temperatureAt(x : f32, y : f32) -> f32 {
    let cold = P.cold_size; let hot = P.hot_size; let cf = P.cold_freq; let hf = P.hot_freq;
    let average = 50.0 - 125.0 * cold / 6.0 + 125.0 * hot / 6.0;
    let range = 50.0 * (clampf(cold, 0.0, 1.0) / 2.0 + cold / 10.0) + 50.0 * (clampf(hot, 0.0, 1.0) / 2.0 + hot / 10.0);
    let bfreq = (cf + hf) / 2.0;
    let main_noise = quickMulti(TEMP_BASE, x * bfreq, y * bfreq, 11u, 1.0 / 32.0, 1.0 / 20.0, 0.5, 1.4, 0.0, 40000.0);
    let base = average + range * clampf(0.25 * main_noise, -1.0, 1.0);
    let hn = quickMulti(TEMP_BASE, x * hf, y * hf, 10u, 1.0 / 8.0, 1.0 / 20.0, 0.5, 1.5, 40000.0, 0.0);
    let hotspots = (clampf(hot, 0.0, 1.0) / 2.0 + hot / 10.0) * 40.0 * clampf(-0.45 + hot / 6.0 + hn, 0.0, 4.0);
    let cn = quickMulti(TEMP_BASE, x * cf, y * cf, 10u, 1.0 / 30.0, 1.0 / 20.0, 0.5, 1.5, -40000.0, 0.0);
    let coldspots = (clampf(cold, 0.0, 1.0) / 2.0 + cold / 10.0) * 40.0 * clampf(-0.45 + cold / 6.0 + cn, 0.0, 4.0);
    let combined = clampf(base - coldspots + hotspots, -50.0, 110.0);
    let volcanic_area = clampf(combined - 100.0, 0.0, 10.0);
    let vhn = quickMulti(TEMP_BASE, x, y, 6u, 1.0, 1.0 / 20.0, 0.5, 1.5, 0.0, 0.0);
    return clampf(combined + clampf(0.5 + vhn, 0.0, 10.0) * volcanic_area * 4.0, -20.0, 150.0);
}

fn moistureAt(x : f32, y : f32) -> f32 {
    let q = quickMulti(MOIST_BASE, x * P.moist_freq, y * P.moist_freq, 8u, 1.0 / 2000.0, 1.0 / 8.0, 3.0, 0.5, 30000.0, 0.0);
    return clampf(0.5 + 2.2 * P.moist_bias + 2.5 * q, 0.0, 1.0);
}
fn auxAt(x : f32, y : f32) -> f32 {
    let q = quickMulti(AUX_BASE, x * P.aux_freq, y * P.aux_freq, 8u, 1.0 / 5000.0, 1.0 / 4.0, 3.0, 0.5, 20000.0, 0.0);
    return clampf(0.45 + 2.2 * P.aux_bias + 2.2 * q, 0.0, 1.0);
}

fn classify(x : f32, y : f32, tf : f32, mf : f32, af : f32, ef : f32) -> u32 {
    let water_noise = multioctaveG(WATER_GI, x, y, 5u, AMP075, 1.0 / 6.0 / 8.0, 0.666, 0.0, 0.0);
    let crater_noise = multioctaveG(CRATER_GI, x, y, 5u, AMP075, 1.0 / 6.0, 0.666, 0.0, 0.0);
    let beach = min(0.0, ef / 5.0 - 1.0);
    var best_f : f32 = -3.4e38; var best_idx : u32 = 0u;
    for (var b : u32 = 0u; b < P.n_biomes; b = b + 1u) {
        let bd = biomes[b];
        var f : f32 = 3.4e38;
        if ((bd.flags & 1u) != 0u) { f = min(f, plateauPeak(tf, bd.t_lo, bd.t_hi)); }
        if ((bd.flags & 2u) != 0u) { f = min(f, plateauPeak(mf, bd.m_lo, bd.m_hi)); }
        if ((bd.flags & 4u) != 0u) { f = min(f, plateauPeak(af, bd.a_lo, bd.a_hi)); }
        if ((bd.flags & 8u) != 0u) { f = min(f, plateauPeak(ef, bd.e_lo, bd.e_hi)); }
        if ((bd.flags & 16u) != 0u) { f = f + beach; }
        f = f + bd.water_coef * water_noise;
        if ((bd.flags & 32u) != 0u) { f = f + (-0.6 - 0.7 * crater_noise); }
        f = f + 0.5 * multioctaveG(TV_BASE + b, x, y, 6u, AMP075, 1.0 / 6.0 / 4.0, 0.666, 1000.0, 0.0);
        if (f > best_f) { best_f = f; best_idx = b; }
    }
    let wn_a = multioctaveG(WATER_GI, x, y, 5u, AMP075, 1.0 / 6.0 / 0.25, 0.666, 0.0, 0.0);
    let wn_b = multioctaveG(WATER_GI, x, y, 5u, AMP075, 1.0 / 6.0 / 0.314, 0.666, 0.0, 0.0);
    let mud = plateauPeak(tf, 0.0, 100.0) + 0.5 * min(wn_a, wn_b) + min(0.0, -1.0 + ef / 5.0) - 1.15;
    if (mud > best_f) { best_f = mud; best_idx = IDX_MUD; }
    if (ef < 0.0) {
        let fw = 100.0 * min(-ef, 1.0);
        if (fw > best_f) { best_f = fw; best_idx = IDX_WATER; }
        if (ef < -5.0) { let fd = 200.0 * min(-5.0 - ef, 1.0); if (fd > best_f) { best_f = fd; best_idx = IDX_DEEPWATER; } }
        let fs = 200.0 * min(-ef, 1.0) + wn_a * 50.0 + ef * 100.0 + min(tf, 0.0) * 10000.0;
        if (fs > best_f) { best_f = fs; best_idx = IDX_SHALLOW; }
    }
    return best_idx;
}

@compute @workgroup_size(8, 8)
fn main(@builtin(global_invocation_id) gid : vec3<u32>) {
    if (gid.x >= P.width || gid.y >= P.height) { return; }
    let x = P.origin_x + f32(gid.x);
    let y = P.origin_y + f32(gid.y);
    let e = select(1.0, elevationAt(x, y), P.has_water != 0u);
    let t = temperatureAt(x, y);
    let m = moistureAt(x, y);
    let a = auxAt(x, y);
    out[gid.y * P.width + gid.x] = classify(x, y, t, m, a, e);
}
