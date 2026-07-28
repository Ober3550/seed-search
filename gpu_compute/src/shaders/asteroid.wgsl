// Asteroid-field surface (SE prototypes/phase-3/noise-programs.lua), ported from
// surface_generator/src/asteroid.zig. One generator (seed1=1): asteroid wins
// where the billows margin > 0, else space; out-of-map beyond the field disk.
// Output per tile: 0 = se-space, 1 = se-asteroid, 2 = out-of-map.

struct Params {
    origin_x : f32,
    origin_y : f32,
    size : f32,
    freq : f32,
    planet_radius : f32,
    width : u32,
    height : u32,
    seed_byte : u32,
};

@group(0) @binding(0) var<uniform>              P     : Params;
@group(0) @binding(1) var<storage, read>        perm1 : array<u32>;  // 256
@group(0) @binding(2) var<storage, read>        perm2 : array<u32>;  // 256
@group(0) @binding(3) var<storage, read>        grad  : array<f32>;  // 512
@group(0) @binding(4) var<storage, read_write>  out   : array<u32>;

fn basis(x : f32, y : f32, scale : f32) -> f32 {
    let sb = P.seed_byte;
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
            let idx = (p1 ^ sb ^ p2);
            let dx = fx - f32(cx);
            let dy = fy - f32(cy);
            let d2 = dx * dx + dy * dy;
            if (d2 < 1.0) {
                let w = 1.0 - d2;
                sum = sum + (grad[2u * idx] * dx + grad[2u * idx + 1u] * dy) * w * w * w;
            }
        }
    }
    return sum;
}

// multioctave_noise{persistence=0.7, octaves=4, input_scale=1/6, output_scale=1}
fn billows_mo(x : f32, y : f32) -> f32 {
    let is = 1.0 / 6.0;
    let ampmul = 1.0 / 0.7;
    var value : f32 = 0.0;
    var amplitude : f32 = 1.0;
    var coordmul : f32 = 1.0;
    var sumsq : f32 = 0.0;
    var k : f32 = 0.0;
    for (var i : u32 = 0u; i < 4u; i = i + 1u) {
        value = value + basis((k * 17.17) / is + x * coordmul, y * coordmul, is) * amplitude;
        sumsq = sumsq + amplitude * amplitude;
        coordmul = coordmul * 0.5;
        amplitude = amplitude * ampmul;
        k = k + 1.0;
    }
    return value / sqrt(sumsq);
}

@compute @workgroup_size(8, 8)
fn main(@builtin(global_invocation_id) gid : vec3<u32>) {
    if (gid.x >= P.width || gid.y >= P.height) { return; }
    let x = P.origin_x + f32(gid.x);
    let y = P.origin_y + f32(gid.y);
    let i = gid.y * P.width + gid.x;

    let dist = sqrt(x * x + y * y);
    if (10000.0 * (dist - P.planet_radius) > (1.0 / P.freq - 100.0) * 1000.0) {
        out[i] = 2u; // out-of-map
        return;
    }
    let billows = abs(billows_mo(x / 5.0, y / 5.0));
    let size_term = max(-25.0, min(0.0, P.size - 25.0));
    let ridge = min(y / P.size, -y / P.size);
    let margin = -1.0 + size_term + ridge + billows;
    out[i] = select(0u, 1u, margin > 0.0); // 0=space, 1=asteroid
}
