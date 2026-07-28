// Port of biome.zig classifyIdx: argmax over 156 land biomes + 4 water tiles.
// Inputs t/m/a/e are fed per tile (from the CPU oracle in the conformance test,
// or from the tma/elevation kernels when chained). 158 generators are uploaded:
// one tv_gen per biome (idx 0..155), water_gen (156), crater_gen (157).

struct Params {
    origin_x : f32,
    origin_y : f32,
    width : u32,
    height : u32,
    n_biomes : u32,
};

// Padded to 48 bytes so the std430 array stride is unambiguous (matches the
// Zig extern struct byte-for-byte).
struct BiomeGPU {
    t_lo : f32, t_hi : f32,
    m_lo : f32, m_hi : f32,
    a_lo : f32, a_hi : f32,
    e_lo : f32, e_hi : f32,
    water_coef : f32,
    flags : u32,   // bit0 t, 1 m, 2 a, 3 e active; bit4 beach_neg; bit5 crater
    pad0 : u32, pad1 : u32,
};

@group(0) @binding(0) var<uniform>              P          : Params;
@group(0) @binding(1) var<storage, read>        perm1      : array<u32>;
@group(0) @binding(2) var<storage, read>        perm2      : array<u32>;
@group(0) @binding(3) var<storage, read>        grad       : array<f32>;
@group(0) @binding(4) var<storage, read>        seed_bytes : array<u32>;
@group(0) @binding(5) var<storage, read>        biomes     : array<BiomeGPU>;
@group(0) @binding(6) var<storage, read>        tmae       : array<f32>;   // 4*n: t|m|a|e
@group(0) @binding(7) var<storage, read_write>  out        : array<u32>;   // winning index per tile

const WATER_GI  : u32 = 156u;
const CRATER_GI : u32 = 157u;
const IDX_WATER     : u32 = 60000u;
const IDX_DEEPWATER : u32 = 60001u;
const IDX_SHALLOW   : u32 = 60002u;
const IDX_MUD       : u32 = 60003u;

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

// multioctave_noise with tile-space offset and output scale.
fn multioctaveG(gi : u32, x : f32, y : f32, octaves : u32, ampmul : f32, is : f32, os : f32, offx : f32, offy : f32) -> f32 {
    let xo = x + offx;
    let yo = y + offy;
    var value : f32 = 0.0;
    var amplitude : f32 = 1.0;
    var coordmul : f32 = 1.0;
    var sumsq : f32 = 0.0;
    var k : f32 = 0.0;
    for (var i : u32 = 0u; i < octaves; i = i + 1u) {
        let x_arg = (k * 17.17) / is + xo * coordmul;
        let y_arg = yo * coordmul;
        value = value + basisG(gi, x_arg, y_arg, is, 0.0, 0.0) * amplitude;
        sumsq = sumsq + amplitude * amplitude;
        coordmul = coordmul * 0.5;
        amplitude = amplitude * ampmul;
        k = k + 1.0;
    }
    return (value / sqrt(sumsq)) * os;
}

fn plateauPeak(v : f32, lo : f32, hi : f32) -> f32 {
    let center = (lo + hi) / 2.0;
    let range = abs(lo - hi) / 2.0;
    return min((range - abs(v - center)) * 20.0, 1.0);
}

const AMP075 : f32 = 1.0 / 0.75;

@compute @workgroup_size(8, 8)
fn main(@builtin(global_invocation_id) gid : vec3<u32>) {
    if (gid.x >= P.width || gid.y >= P.height) { return; }
    let n = P.width * P.height;
    let i = gid.y * P.width + gid.x;
    let x = P.origin_x + f32(gid.x);
    let y = P.origin_y + f32(gid.y);

    let tf = tmae[i];
    let mf = tmae[n + i];
    let af = tmae[2u * n + i];
    let ef = tmae[3u * n + i];

    let water_noise = multioctaveG(WATER_GI, x, y, 5u, AMP075, 1.0 / 6.0 / 8.0, 0.666, 0.0, 0.0);
    let crater_noise = multioctaveG(CRATER_GI, x, y, 5u, AMP075, 1.0 / 6.0, 0.666, 0.0, 0.0);
    let beach = min(0.0, ef / 5.0 - 1.0);

    var best_f : f32 = -3.4e38;
    var best_idx : u32 = 0u;
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
        f = f + 0.5 * multioctaveG(b, x, y, 6u, AMP075, 1.0 / 6.0 / 4.0, 0.666, 1000.0, 0.0);
        if (f > best_f) { best_f = f; best_idx = b; }
    }

    // water/wetland tiles compete on the same fitness scale.
    let wn_a = multioctaveG(WATER_GI, x, y, 5u, AMP075, 1.0 / 6.0 / 0.25, 0.666, 0.0, 0.0);
    let wn_b = multioctaveG(WATER_GI, x, y, 5u, AMP075, 1.0 / 6.0 / 0.314, 0.666, 0.0, 0.0);
    let mud = plateauPeak(tf, 0.0, 100.0) + 0.5 * min(wn_a, wn_b) + min(0.0, -1.0 + ef / 5.0) - 1.15;
    if (mud > best_f) { best_f = mud; best_idx = IDX_MUD; }
    if (ef < 0.0) {
        let fw = 100.0 * min(-ef, 1.0);
        if (fw > best_f) { best_f = fw; best_idx = IDX_WATER; }
        if (ef < -5.0) {
            let fd = 200.0 * min(-5.0 - ef, 1.0);
            if (fd > best_f) { best_f = fd; best_idx = IDX_DEEPWATER; }
        }
        let fs = 200.0 * min(-ef, 1.0) + wn_a * 50.0 + ef * 100.0 + min(tf, 0.0) * 10000.0;
        if (fs > best_f) { best_f = fs; best_idx = IDX_SHALLOW; }
    }

    out[i] = best_idx;
}
