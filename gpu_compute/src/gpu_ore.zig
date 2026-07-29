//! GPU ore placement for asteroid fields (prototype). Reads a --dump produced by
//! `segen --gpu-ore-dump` (per-resource params + precomputed spots), runs the
//! asteroid mask + ore.wgsl per-tile eval on the GPU, and writes ore.jsonl (same
//! format as the CPU path). The CPU stays the exact oracle; this is the fast
//! approximate (f32) path. See shaders/ore.wgsl.

const std = @import("std");
const wgpu = @import("wgpu.zig");
const c = wgpu.c;
const surfgen = @import("surfgen");
const se = surfgen.se_ore;
const noise = surfgen.noise;

const ore_wgsl = @embedFile("shaders/ore.wgsl");
const asteroid_wgsl = @embedFile("shaders/asteroid.wgsl");

fn getStr(args: []const []const u8, flag: []const u8) ?[]const u8 {
    for (args, 0..) |arg, i| {
        if (std.mem.eql(u8, arg, flag) and i + 1 < args.len) return args[i + 1];
    }
    return null;
}
fn err(msg: []const u8) error{Usage} {
    std.debug.print("gpu_ore error: {s}\n  usage: gpu_ore --dump <gore.bin> --out <ore.jsonl>\n", .{msg});
    return error.Usage;
}

const AsteroidParams = extern struct {
    origin_x: f32,
    origin_y: f32,
    size: f32,
    freq: f32,
    planet_radius: f32,
    width: u32,
    height: u32,
    seed_byte: u32,
};

// MUST match shaders/ore.wgsl `Params` (all scalars; padded to a multiple of 16).
const OreParams = extern struct {
    origin_x: f32,
    origin_y: f32,
    width: u32,
    height: u32,
    zone_radius: f32,
    base_density: f32,
    freq_mult: f32,
    size_mult: f32,
    base_spots_per_km2: f32,
    rq: f32,
    smin: f32,
    smax: f32,
    basement_value: f32,
    richness_mult: f32,
    additional_richness: f32,
    random_probability: f32,
    roll_salt: u32,
    seed_byte: u32,
    res_index: u32,
    has_starting: u32,
    starting_blob_amplitude: f32,
    nspots: u32,
    nstart: u32,
    pad0: u32 = 0, // pad 92 -> 96 bytes (uniform size multiple of 16)
};

fn buildGen(a: std.mem.Allocator, map_seed: u32, seed1: u32) !struct { perm1: []u32, perm2: []u32, grad: []f32, sb: u32 } {
    const g = noise.BasisNoiseGen.init(map_seed, seed1);
    const perm1 = try a.alloc(u32, 256);
    const perm2 = try a.alloc(u32, 256);
    const grad = try a.alloc(f32, 512);
    for (0..256) |i| {
        perm1[i] = g.perm1[i];
        perm2[i] = g.perm2[i];
        grad[2 * i] = @floatCast(g.grad[i][0]);
        grad[2 * i + 1] = @floatCast(g.grad[i][1]);
    }
    return .{ .perm1 = perm1, .perm2 = perm2, .grad = grad, .sb = g.seed_byte };
}

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const args = try init.minimal.args.toSlice(a);

    const dump_path = getStr(args, "--dump") orelse return err("missing --dump");
    const out_path = getStr(args, "--out") orelse return err("missing --out");

    const bytes = try std.Io.Dir.readFileAlloc(.cwd(), init.io, dump_path, a, .unlimited);
    var off: usize = 0;
    const H = std.mem.bytesToValue(se.GpuOreHeader, bytes[off..][0..@sizeOf(se.GpuOreHeader)]);
    off += @sizeOf(se.GpuOreHeader);
    if (H.magic != 0x45524f47) return err("bad dump magic");
    const width: u32 = @intCast(H.x1 - H.x0);
    const height: u32 = @intCast(H.y1 - H.y0);
    const npx: usize = @as(usize, width) * height;
    std.debug.print("gpu_ore: {d} resources, {d}x{d} ({d} tiles), map_seed {d}, field {d}\n", .{ H.nres, width, height, npx, H.map_seed, H.is_field });

    var ctx = try wgpu.Context.init();
    defer ctx.deinit();
    std.debug.print("adapter: {s}\n", .{ctx.adapterName()});

    // ── Asteroid mask (0=space,1=asteroid,2=out-of-map) on the GPU ──────────
    const mask_bytes: u64 = npx * @sizeOf(u32);
    const buf_mask = ctx.makeBuffer(mask_bytes, c.WGPUBufferUsage_Storage | c.WGPUBufferUsage_CopySrc);
    defer c.wgpuBufferRelease(buf_mask);
    {
        const ag = try buildGen(a, H.map_seed, 1);
        const size: f64 = surfgen.asteroid.FIELD_SIZE;
        const freq: f64 = surfgen.asteroid.FIELD_FREQ;
        const planet_radius = 10000.0 / 6.0 * (6.0 + std.math.log2(1.0 / freq / 6.0));
        const p = AsteroidParams{
            .origin_x = @floatFromInt(H.x0),
            .origin_y = @floatFromInt(H.y0),
            .size = @floatCast(size),
            .freq = @floatCast(freq),
            .planet_radius = @floatCast(planet_radius),
            .width = width,
            .height = height,
            .seed_byte = ag.sb,
        };
        const pipe = try ctx.computePipeline(asteroid_wgsl, "main");
        defer c.wgpuComputePipelineRelease(pipe);
        const bp = ctx.uploadBuffer(AsteroidParams, &.{p}, c.WGPUBufferUsage_Uniform);
        defer c.wgpuBufferRelease(bp);
        const b1 = ctx.uploadBuffer(u32, ag.perm1, c.WGPUBufferUsage_Storage);
        const b2 = ctx.uploadBuffer(u32, ag.perm2, c.WGPUBufferUsage_Storage);
        const b3 = ctx.uploadBuffer(f32, ag.grad, c.WGPUBufferUsage_Storage);
        defer c.wgpuBufferRelease(b1);
        defer c.wgpuBufferRelease(b2);
        defer c.wgpuBufferRelease(b3);
        const bgl = c.wgpuComputePipelineGetBindGroupLayout(pipe, 0);
        defer c.wgpuBindGroupLayoutRelease(bgl);
        var e = [_]c.WGPUBindGroupEntry{
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 0, .buffer = bp, .size = @sizeOf(AsteroidParams) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 1, .buffer = b1, .size = ag.perm1.len * @sizeOf(u32) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 2, .buffer = b2, .size = ag.perm2.len * @sizeOf(u32) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 3, .buffer = b3, .size = ag.grad.len * @sizeOf(f32) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 4, .buffer = buf_mask, .size = mask_bytes }),
        };
        var bgd = std.mem.zeroInit(c.WGPUBindGroupDescriptor, .{ .layout = bgl, .entryCount = e.len, .entries = &e });
        const bg = c.wgpuDeviceCreateBindGroup(ctx.device, &bgd);
        defer c.wgpuBindGroupRelease(bg);
        const enc = c.wgpuDeviceCreateCommandEncoder(ctx.device, null);
        var pd = std.mem.zeroInit(c.WGPUComputePassDescriptor, .{});
        const pass = c.wgpuCommandEncoderBeginComputePass(enc, &pd);
        c.wgpuComputePassEncoderSetPipeline(pass, pipe);
        c.wgpuComputePassEncoderSetBindGroup(pass, 0, bg, 0, null);
        c.wgpuComputePassEncoderDispatchWorkgroups(pass, (width + 7) / 8, (height + 7) / 8, 1);
        c.wgpuComputePassEncoderEnd(pass);
        c.wgpuComputePassEncoderRelease(pass);
        const cmd = c.wgpuCommandEncoderFinish(enc, null);
        c.wgpuCommandEncoderRelease(enc);
        c.wgpuQueueSubmit(ctx.queue, 1, &cmd);
        c.wgpuCommandBufferRelease(cmd);
        ctx.poll();
    }

    // ── Winner buffer (per tile: vec4<u32> [prob,rich,res,amount], zeroed) ──
    const win_bytes: u64 = npx * 16;
    const zeros = try a.alloc(u32, npx * 4);
    @memset(zeros, 0);
    const buf_win = ctx.uploadBuffer(u32, zeros, c.WGPUBufferUsage_Storage | c.WGPUBufferUsage_CopySrc);
    defer c.wgpuBufferRelease(buf_win);

    const ore_pipe = try ctx.computePipeline(ore_wgsl, "main");
    defer c.wgpuComputePipelineRelease(ore_pipe);
    const ore_bgl = c.wgpuComputePipelineGetBindGroupLayout(ore_pipe, 0);
    defer c.wgpuBindGroupLayoutRelease(ore_bgl);

    // ── One ore dispatch per resource (RMW into buf_win) ────────────────────
    var names = try a.alloc([]const u8, H.nres);
    const t0 = wgpu.nowNs();
    var ri: u32 = 0;
    while (ri < H.nres) : (ri += 1) {
        const rh = std.mem.bytesToValue(se.GpuResHeader, bytes[off..][0..@sizeOf(se.GpuResHeader)]);
        off += @sizeOf(se.GpuResHeader);
        const name = bytes[off .. off + rh.name_len];
        off += rh.name_len;
        names[ri] = name;
        // spots (noise.Spot f64 x4) -> vec4<f32>
        const nsp: usize = rh.nspots;
        const nst: usize = rh.nstart;
        const sp_f = try a.alloc(f32, @max(nsp, 1) * 4);
        for (0..nsp) |k| {
            const s = std.mem.bytesToValue(noise.Spot, bytes[off + k * @sizeOf(noise.Spot) ..][0..@sizeOf(noise.Spot)]);
            sp_f[k * 4 + 0] = @floatCast(s.x);
            sp_f[k * 4 + 1] = @floatCast(s.y);
            sp_f[k * 4 + 2] = @floatCast(s.peak);
            sp_f[k * 4 + 3] = @floatCast(s.slope);
        }
        off += nsp * @sizeOf(noise.Spot);
        const st_f = try a.alloc(f32, @max(nst, 1) * 4);
        for (0..nst) |k| {
            const s = std.mem.bytesToValue(noise.Spot, bytes[off + k * @sizeOf(noise.Spot) ..][0..@sizeOf(noise.Spot)]);
            st_f[k * 4 + 0] = @floatCast(s.x);
            st_f[k * 4 + 1] = @floatCast(s.y);
            st_f[k * 4 + 2] = @floatCast(s.peak);
            st_f[k * 4 + 3] = @floatCast(s.slope);
        }
        off += nst * @sizeOf(noise.Spot);
        if (nsp == 0) continue; // no regular spots -> no ore

        const gen = try buildGen(a, H.map_seed, rh.seed1);
        const P = OreParams{
            .origin_x = @floatFromInt(H.x0),
            .origin_y = @floatFromInt(H.y0),
            .width = width,
            .height = height,
            .zone_radius = @floatCast(H.zone_radius),
            .base_density = @floatCast(rh.base_density),
            .freq_mult = @floatCast(rh.freq_mult),
            .size_mult = @floatCast(rh.size_mult),
            .base_spots_per_km2 = @floatCast(rh.base_spots_per_km2),
            .rq = @floatCast(rh.rq),
            .smin = @floatCast(rh.smin),
            .smax = @floatCast(rh.smax),
            .basement_value = @floatCast(rh.basement_value),
            .richness_mult = @floatCast(rh.richness_mult),
            .additional_richness = @floatCast(rh.additional_richness),
            .random_probability = @floatCast(rh.random_probability),
            .roll_salt = rh.roll_salt,
            .seed_byte = gen.sb,
            .res_index = ri,
            .has_starting = rh.has_starting,
            .starting_blob_amplitude = @floatCast(rh.starting_blob_amplitude),
            .nspots = rh.nspots,
            .nstart = rh.nstart,
        };
        const bP = ctx.uploadBuffer(OreParams, &.{P}, c.WGPUBufferUsage_Uniform);
        defer c.wgpuBufferRelease(bP);
        const b1 = ctx.uploadBuffer(u32, gen.perm1, c.WGPUBufferUsage_Storage);
        const b2 = ctx.uploadBuffer(u32, gen.perm2, c.WGPUBufferUsage_Storage);
        const b3 = ctx.uploadBuffer(f32, gen.grad, c.WGPUBufferUsage_Storage);
        const bSp = ctx.uploadBuffer(f32, sp_f, c.WGPUBufferUsage_Storage);
        const bSt = ctx.uploadBuffer(f32, st_f, c.WGPUBufferUsage_Storage);
        defer c.wgpuBufferRelease(b1);
        defer c.wgpuBufferRelease(b2);
        defer c.wgpuBufferRelease(b3);
        defer c.wgpuBufferRelease(bSp);
        defer c.wgpuBufferRelease(bSt);
        var e = [_]c.WGPUBindGroupEntry{
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 0, .buffer = bP, .size = @sizeOf(OreParams) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 1, .buffer = b1, .size = gen.perm1.len * @sizeOf(u32) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 2, .buffer = b2, .size = gen.perm2.len * @sizeOf(u32) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 3, .buffer = b3, .size = gen.grad.len * @sizeOf(f32) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 4, .buffer = bSp, .size = sp_f.len * @sizeOf(f32) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 5, .buffer = bSt, .size = st_f.len * @sizeOf(f32) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 6, .buffer = buf_mask, .size = mask_bytes }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 7, .buffer = buf_win, .size = win_bytes }),
        };
        var bgd = std.mem.zeroInit(c.WGPUBindGroupDescriptor, .{ .layout = ore_bgl, .entryCount = e.len, .entries = &e });
        const bg = c.wgpuDeviceCreateBindGroup(ctx.device, &bgd);
        defer c.wgpuBindGroupRelease(bg);
        const enc = c.wgpuDeviceCreateCommandEncoder(ctx.device, null);
        var pd = std.mem.zeroInit(c.WGPUComputePassDescriptor, .{});
        const pass = c.wgpuCommandEncoderBeginComputePass(enc, &pd);
        c.wgpuComputePassEncoderSetPipeline(pass, ore_pipe);
        c.wgpuComputePassEncoderSetBindGroup(pass, 0, bg, 0, null);
        c.wgpuComputePassEncoderDispatchWorkgroups(pass, (width + 7) / 8, (height + 7) / 8, 1);
        c.wgpuComputePassEncoderEnd(pass);
        c.wgpuComputePassEncoderRelease(pass);
        const cmd = c.wgpuCommandEncoderFinish(enc, null);
        c.wgpuCommandEncoderRelease(enc);
        c.wgpuQueueSubmit(ctx.queue, 1, &cmd);
        c.wgpuCommandBufferRelease(cmd);
        ctx.poll();
        std.debug.print("  {s}: {d} spots, {d} start\n", .{ name, nsp, nst });
    }

    // ── Read back winners + emit ore.jsonl ──────────────────────────────────
    const staging = ctx.makeBuffer(win_bytes, c.WGPUBufferUsage_MapRead | c.WGPUBufferUsage_CopyDst);
    defer c.wgpuBufferRelease(staging);
    {
        const enc = c.wgpuDeviceCreateCommandEncoder(ctx.device, null);
        c.wgpuCommandEncoderCopyBufferToBuffer(enc, buf_win, 0, staging, 0, win_bytes);
        const cmd = c.wgpuCommandEncoderFinish(enc, null);
        c.wgpuCommandEncoderRelease(enc);
        c.wgpuQueueSubmit(ctx.queue, 1, &cmd);
        c.wgpuCommandBufferRelease(cmd);
    }
    const win = try a.alloc(u32, npx * 4);
    try ctx.readBuffer(staging, u32, win);
    const dt_ms = @as(f64, @floatFromInt(wgpu.nowNs() - t0)) / 1e6;

    var out: std.ArrayList(u8) = .empty;
    var count: usize = 0;
    for (0..npx) |i| {
        const amount = win[i * 4 + 3];
        if (amount == 0) continue;
        const res = win[i * 4 + 2];
        const ix = H.x0 + @as(i32, @intCast(i % width));
        const iy = H.y0 + @as(i32, @intCast(i / width));
        const line = try std.fmt.allocPrint(a, "{{\"x\":{d},\"y\":{d},\"n\":\"{s}\",\"a\":{d}}}\n", .{ ix, iy, names[res], amount });
        try out.appendSlice(a, line);
        count += 1;
    }
    const f = try std.Io.Dir.createFile(.cwd(), init.io, out_path, .{});
    defer f.close(init.io);
    try f.writePositionalAll(init.io, out.items, 0);
    std.debug.print("gpu_ore: {d} ore entities -> {s}  (kernel {d:.1} ms)\n", .{ count, out_path, dt_ms });
}
