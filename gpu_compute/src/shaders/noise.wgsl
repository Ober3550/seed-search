// Port of noise.zig `multioctaveNoiseOffset` over a seeded BasisNoiseGen.
// The CPU builds perm1/perm2/grad + seed_byte (Fisher-Yates, once per seed) and
// uploads them; this kernel only does the per-tile evaluation. All math is f32,
// matching the engine's fastVectorMultioctaveNoise and our f32 CPU path.

struct Params {
    origin_x : f32,
    origin_y : f32,
    input_scale : f32,
    output_scale : f32,
    ampmul : f32,        // 1.0 / persistence
    offset_x : f32,
    offset_y : f32,
    width : u32,
    height : u32,
    octaves : u32,
    seed_byte : u32,
};

@group(0) @binding(0) var<uniform>              P     : Params;
@group(0) @binding(1) var<storage, read>        perm1 : array<u32>;   // 256
@group(0) @binding(2) var<storage, read>        perm2 : array<u32>;   // 256
@group(0) @binding(3) var<storage, read>        grad  : array<f32>;   // 512 (gx,gy interleaved)
@group(0) @binding(4) var<storage, read_write>  out   : array<f32>;

// basis_noise (evalOffset with offset 0, output_scale 1): surflet gradient noise.
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

fn multioctave(x : f32, y : f32) -> f32 {
    let is = P.input_scale;
    let xo = x + P.offset_x;   // tile-space offset (added before per-octave scale)
    let yo = y + P.offset_y;
    var value : f32 = 0.0;
    var amplitude : f32 = 1.0;
    var coordmul : f32 = 1.0;
    var sumsq : f32 = 0.0;
    var k : f32 = 0.0;
    for (var i : u32 = 0u; i < P.octaves; i = i + 1u) {
        let x_arg = (k * 17.17) / is + xo * coordmul;   // per-octave decorrelation in noise space
        let y_arg = yo * coordmul;
        value = value + basis(x_arg, y_arg, is) * amplitude;
        sumsq = sumsq + amplitude * amplitude;
        coordmul = coordmul * 0.5;      // octaves get coarser
        amplitude = amplitude * P.ampmul;
        k = k + 1.0;
    }
    return (value / sqrt(sumsq)) * P.output_scale;
}

@compute @workgroup_size(8, 8)
fn main(@builtin(global_invocation_id) gid : vec3<u32>) {
    if (gid.x >= P.width || gid.y >= P.height) { return; }
    let x = P.origin_x + f32(gid.x);
    let y = P.origin_y + f32(gid.y);
    out[gid.y * P.width + gid.x] = multioctave(x, y);
}
