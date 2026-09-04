// se_zone.wgsl - Space Exploration zone surface kernel (stage 1: elevation).
// Per invocation: SE elevation_nauvis (Elevation.at, NO starting lake - moons
// have none) -> f32 elevation, using the CPU-derived per-zone water controls
// (nsm/seg/water_level from surfaceParams: water_frequency/size).
// Later stages add ZoneTerrain temp/moist/aux + the alien-biomes classifier.
//
// Gen tables packed by gi (order must match the worker's SE registry):
//   0 (map_seed,900) 1 (map_seed,99584) 2 (map_seed,700) 3 (map_seed,1000)
//   4 (map_seed,1100) 5 (map_seed,500) 6 (map_seed,600)
// Modes: 0 elevation (outF = f32 e), 1 water mask (outIdx: 0 land 1 water
// 2 deep), 2 reserved.

struct Params {
    origin_x : f32,
    origin_y : f32,
    nsm : f32,
    seg : f32,
    water_level : f32,
    is_hills : f32,
    is_cliff : f32,
    os_cliff : f32,
    is_bridge : f32,
    is_macro1 : f32,
    is_macro2 : f32,
    is_detail : f32,
    os_detail : f32,
    offx_detail : f32,
    is_pers : f32,
    os_pers : f32,
    offx_pers : f32,
    width : u32,
    height : u32,
    mode : u32,
};

@group(0) @binding(0) var<uniform>             P     : Params;
@group(0) @binding(1) var<storage, read>       perm1 : array<u32>;
@group(0) @binding(2) var<storage, read>       perm2 : array<u32>;
@group(0) @binding(3) var<storage, read>       grad  : array<f32>;
@group(0) @binding(4) var<storage, read>       sbytes: array<u32>;
@group(0) @binding(5) var<storage, read_write> outF  : array<f32>;
@group(0) @binding(6) var<storage, read_write> outIdx: array<u32>;

const GI_HILLS : u32 = 0u;
const GI_CLIFF : u32 = 1u;
const GI_BRIDGE: u32 = 2u;
const GI_MACRO1: u32 = 3u;
const GI_MACRO2: u32 = 4u;
const GI_PERS  : u32 = 5u;
const GI_DET   : u32 = 6u;

fn basisG(gi : u32, x : f32, y : f32, scale : f32, offx : f32, offy : f32) -> f32 {
    let po = gi * 256u;
    let go = gi * 512u;
    let sb = sbytes[gi];
    let X = (x + offx) * scale;
    let Y = (y + offy) * scale;
    let ix = i32(floor(X));
    let iy = i32(floor(Y));
    let fx = X - f32(ix);
    let fy = Y - f32(iy);
    var sum : f32 = 0.0;
    for (var cy : i32 = 0; cy <= 1; cy = cy + 1) {
        for (var cx : i32 = 0; cx <= 1; cx = cx + 1) {
            let p1 = perm1[po + (bitcast<u32>(iy + cy) & 255u)];
            let p2 = perm2[po + (bitcast<u32>(ix + cx) & 255u)];
            let g2 = (p1 ^ sb ^ p2);
            let dx = fx - f32(cx);
            let dy = fy - f32(cy);
            let d2 = dx * dx + dy * dy;
            if (d2 < 1.0) {
                let w = 1.0 - d2;
                sum = sum + (grad[go + 2u * g2] * dx + grad[go + 2u * g2 + 1u] * dy) * w * w * w;
            }
        }
    }
    return sum;
}

fn multioctaveG(gi : u32, x : f32, y : f32, octaves : u32, ampmul : f32, is : f32) -> f32 {
    var value : f32 = 0.0;
    var amplitude : f32 = 1.0;
    var coordmul : f32 = 1.0;
    var sumsq : f32 = 0.0;
    var k : f32 = 0.0;
    for (var i : u32 = 0u; i < octaves; i = i + 1u) {
        let xa = (k * 17.17) / is + x * coordmul;
        let ya = y * coordmul;
        value = value + basisG(gi, xa, ya, is, 0.0, 0.0) * amplitude;
        sumsq = sumsq + amplitude * amplitude;
        coordmul = coordmul * 0.5;
        amplitude = amplitude * ampmul;
        k = k + 1.0;
    }
    return value / sqrt(sumsq);
}

fn variablePersistenceG(gi : u32, x : f32, y : f32, octaves : u32, is : f32,
                        os : f32, offx : f32, persistence : f32) -> f32 {
    var is_k = is * 0.5;
    var acc : f32 = 0.0;
    for (var k : u32 = 0u; k < octaves; k = k + 1u) {
        acc = acc * persistence + basisG(gi, x, y, is_k, offx, 0.0);
        is_k = is_k * 0.5;
    }
    return acc * os * pow(2.0, f32(octaves));
}

fn elevationAt(x : f32, y : f32) -> f32 {
    let hills = abs(multioctaveG(GI_HILLS, x, y, 4u, 2.0, P.is_hills));
    let cliff_level = clamp(0.65 + basisG(GI_CLIFF, x, y, P.is_cliff, 0.0, 0.0) * P.os_cliff, 0.15, 1.15);
    let plateaus = 0.5 + clamp((hills - cliff_level) * 10.0, -0.5, 0.5);
    let hp = 0.1 * hills + 0.8 * plateaus;
    let bb = abs(multioctaveG(GI_BRIDGE, x, y, 4u, 2.0, P.is_bridge));
    let bridges = 1.0 - 0.1 * bb - 0.9 * max(0.0, -0.1 + bb);
    let macroN = multioctaveG(GI_MACRO1, x, y, 2u, 1.0 / 0.6, P.is_macro1) *
                 max(0.0, multioctaveG(GI_MACRO2, x, y, 1u, 1.0 / 0.6, P.is_macro2));
    let persist = clamp(variablePersistenceG(GI_PERS, x, y, 5u, P.is_pers, P.os_pers, P.offx_pers, 0.7) + 0.55, 0.5, 0.65);
    let detail = variablePersistenceG(GI_DET, x, y, 5u, P.is_detail, P.os_detail, P.offx_detail, persist);
    let dist = sqrt(x * x + y * y);
    let smm = clamp(dist * P.nsm / 2000.0, 0.0, 1.0);
    let main = 20.0 * (mix(0.5 * hp - 0.6, 1.9 * hp + 1.6, 0.1 + 0.5 * bridges) +
                       0.25 * detail + 3.0 * macroN * smm);
    let island = main + 20.0 * (2.5 - dist * P.seg / 200.0);
    return max(main - P.water_level * 2.0, island);
}

@compute @workgroup_size(8, 8)
fn main(@builtin(global_invocation_id) gid : vec3<u32>) {
    if (gid.x >= P.width || gid.y >= P.height) { return; }
    let x = P.origin_x + f32(gid.x);
    let y = P.origin_y + f32(gid.y);
    let i = gid.y * P.width + gid.x;
    let e = elevationAt(x, y);
    if (P.mode == 0u) { outF[i] = e; return; }
    var m : u32 = 0u;
    if (e < 0.0) { m = 1u; }
    if (e < -2.0) { m = 2u; }
    outIdx[i] = m;
}
