//! Shared GPU terrain classifier — extracted from gpu_segen so gpu_ore can reuse
//! it to gate ore on water + biome. Runs render.wgsl (elevation + t/m/aux +
//! biome classify) over a cell and returns a per-tile biome index; water tiles
//! come back as sentinels IDX_WATER(60000)..IDX_MUD(60003). Land tiles are the
//! biome index into surfgen.biome.biomes (so biomes[idx].restrict is valid).

const std = @import("std");
const wgpu = @import("wgpu.zig");
const c = wgpu.c;
const surfgen = @import("surfgen");
const noise = surfgen.noise;
const biome = surfgen.biome;

const render_wgsl = @embedFile("shaders/render.wgsl");

pub const IDX_WATER: u32 = 60000;

pub const Params = extern struct {
    origin_x: f32,
    origin_y: f32,
    nsm: f32,
    seg: f32,
    water_level: f32,
    is_hills: f32,
    is_cliff: f32,
    os_cliff: f32,
    is_bridge: f32,
    is_macro1: f32,
    is_macro2: f32,
    is_detail: f32,
    os_detail: f32,
    offx_detail: f32,
    is_pers: f32,
    os_pers: f32,
    offx_pers: f32,
    cold_size: f32,
    hot_size: f32,
    cold_freq: f32,
    hot_freq: f32,
    moist_freq: f32,
    moist_bias: f32,
    aux_freq: f32,
    aux_bias: f32,
    width: u32,
    height: u32,
    n_biomes: u32,
    has_water: u32,
    _pa: u32 = 0,
    _pb: u32 = 0,
    _pc: u32 = 0,
};

const BiomeGPU = extern struct {
    t_lo: f32 = 0,
    t_hi: f32 = 0,
    m_lo: f32 = 0,
    m_hi: f32 = 0,
    a_lo: f32 = 0,
    a_hi: f32 = 0,
    e_lo: f32 = 0,
    e_hi: f32 = 0,
    water_coef: f32 = 0,
    flags: u32 = 0,
    pad0: u32 = 0,
    pad1: u32 = 0,
};

const NGEN = 192;

const ColdHot = struct { cold_f: f64, cold_s: f64, hot_f: f64, hot_s: f64 };
pub fn tempControl(label: []const u8) ColdHot {
    const eq = std.mem.eql;
    if (eq(u8, label, "bland")) return .{ .cold_f = 0.5, .cold_s = 0, .hot_f = 0.5, .hot_s = 0 };
    if (eq(u8, label, "temperate")) return .{ .cold_f = 1, .cold_s = 0.25, .hot_f = 1, .hot_s = 0.25 };
    if (eq(u8, label, "midrange")) return .{ .cold_f = 1, .cold_s = 0.65, .hot_f = 1, .hot_s = 0.65 };
    if (eq(u8, label, "balanced")) return .{ .cold_f = 1, .cold_s = 1, .hot_f = 1, .hot_s = 1 };
    if (eq(u8, label, "wild")) return .{ .cold_f = 1, .cold_s = 3, .hot_f = 1, .hot_s = 3 };
    if (eq(u8, label, "extreme")) return .{ .cold_f = 1, .cold_s = 6, .hot_f = 1, .hot_s = 6 };
    if (eq(u8, label, "cool")) return .{ .cold_f = 0.75, .cold_s = 0.5, .hot_f = 0.75, .hot_s = 0 };
    if (eq(u8, label, "cold")) return .{ .cold_f = 0.75, .cold_s = 1, .hot_f = 0.75, .hot_s = 0 };
    if (eq(u8, label, "vcold")) return .{ .cold_f = 0.75, .cold_s = 2.2, .hot_f = 0.75, .hot_s = 0 };
    if (eq(u8, label, "frozen")) return .{ .cold_f = 0.75, .cold_s = 6, .hot_f = 0.75, .hot_s = 0 };
    if (eq(u8, label, "warm")) return .{ .cold_f = 0.75, .cold_s = 0, .hot_f = 0.75, .hot_s = 0.5 };
    if (eq(u8, label, "hot")) return .{ .cold_f = 0.75, .cold_s = 0, .hot_f = 0.75, .hot_s = 1 };
    if (eq(u8, label, "vhot")) return .{ .cold_f = 0.75, .cold_s = 0, .hot_f = 0.75, .hot_s = 2.2 };
    if (eq(u8, label, "volcanic")) return .{ .cold_f = 0.75, .cold_s = 0, .hot_f = 0.75, .hot_s = 6 };
    return .{ .cold_f = 1, .cold_s = 0.65, .hot_f = 1, .hot_s = 0.65 };
}
const FreqBias = struct { f: f64, bias: f64 };
pub fn moistControl(label: []const u8) FreqBias {
    const eq = std.mem.eql;
    if (eq(u8, label, "none")) return .{ .f = 2, .bias = -1 };
    if (eq(u8, label, "low")) return .{ .f = 1, .bias = -0.15 };
    if (eq(u8, label, "med")) return .{ .f = 1, .bias = 0 };
    if (eq(u8, label, "high")) return .{ .f = 1, .bias = 0.15 };
    if (eq(u8, label, "max")) return .{ .f = 2, .bias = 0.5 };
    return .{ .f = 1, .bias = 0 };
}
pub fn auxControl(label: []const u8) FreqBias {
    const eq = std.mem.eql;
    if (eq(u8, label, "very_low")) return .{ .f = 1, .bias = -0.5 };
    if (eq(u8, label, "low")) return .{ .f = 1, .bias = -0.3 };
    if (eq(u8, label, "med")) return .{ .f = 1, .bias = -0.1 };
    if (eq(u8, label, "high")) return .{ .f = 1, .bias = 0.2 };
    if (eq(u8, label, "very_high")) return .{ .f = 1, .bias = 0.5 };
    return .{ .f = 1, .bias = -0.1 };
}

fn packGen(gi: usize, g: noise.BasisNoiseGen, p1: []u32, p2: []u32, gr: []f32, sb: []u32) void {
    sb[gi] = g.seed_byte;
    for (0..256) |i| {
        p1[gi * 256 + i] = g.perm1[i];
        p2[gi * 256 + i] = g.perm2[i];
        gr[gi * 512 + 2 * i] = @floatCast(g.grad[i][0]);
        gr[gi * 512 + 2 * i + 1] = @floatCast(g.grad[i][1]);
    }
}

pub const ZoneInfo = struct {
    zone_seed: u32 = 0,
    radius: f64 = 0,
    has_water: bool = false,
    is_field: bool = false,
    temp_label: []const u8 = "midrange",
    moist_label: []const u8 = "med",
    aux_label: []const u8 = "med",
    found: bool = false,
};

/// Parse a zones.jsonl for (world_seed, zone_name) → terrain controls. Mirrors
/// gpu_segen's inline loader.
pub fn loadZone(a: std.mem.Allocator, io: std.Io, zones_path: []const u8, world_seed: u64, zone_name: []const u8) !ZoneInfo {
    const raw = try std.Io.Dir.readFileAlloc(.cwd(), io, zones_path, a, .unlimited);
    var z: ZoneInfo = .{};
    var it = std.mem.tokenizeScalar(u8, raw, '\n');
    outer: while (it.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \r\t");
        if (trimmed.len == 0 or trimmed[0] == '#') continue;
        const parsed = std.json.parseFromSlice(std.json.Value, a, trimmed, .{}) catch continue;
        const root = parsed.value;
        if (root != .object) continue;
        const s = root.object.get("s") orelse continue;
        if (s != .integer or @as(u64, @intCast(s.integer)) != world_seed) continue;
        const zs = root.object.get("z") orelse continue;
        if (zs != .array) continue;
        for (zs.array.items) |zj| {
            if (zj != .object) continue;
            const nm = zj.object.get("n") orelse continue;
            if (nm != .string or !std.mem.eql(u8, nm.string, zone_name)) continue;
            z.zone_seed = @intCast((zj.object.get("s") orelse continue).integer);
            if (zj.object.get("t")) |t| z.is_field = (t == .string) and std.mem.eql(u8, t.string, "asteroid-field");
            if (zj.object.get("r")) |rv| z.radius = switch (rv) {
                .integer => |v| @floatFromInt(v),
                .float => |v| v,
                else => 0,
            };
            if (zj.object.get("water")) |w| z.has_water = (w == .string) and !std.mem.eql(u8, w.string, "none");
            if (zj.object.get("temperature")) |v| if (v == .string) {
                z.temp_label = try a.dupe(u8, v.string);
            };
            if (zj.object.get("moisture")) |v| if (v == .string) {
                z.moist_label = try a.dupe(u8, v.string);
            };
            if (zj.object.get("aux")) |v| if (v == .string) {
                z.aux_label = try a.dupe(u8, v.string);
            };
            z.found = true;
            break :outer;
        }
    }
    return z;
}

/// Base Params for a zone (origin/width/height are overridden per cell in
/// classify). `radius` = the zone's TRUE radius (drives fm); `has_water` gates
/// elevation; the three labels are the SE control tags.
pub fn buildParams(radius: f64, has_water: bool, temp_label: []const u8, moist_label: []const u8, aux_label: []const u8) Params {
    const water_freq: f64 = 1.0;
    const water_size: f64 = if (has_water) 1.5 else 1.0;
    const fm: f64 = 5000.0 / radius;
    const nsm: f64 = 1.5 * water_freq;
    const temp = tempControl(temp_label);
    const moist = moistControl(moist_label);
    const aux = auxControl(aux_label);
    _ = moist;
    _ = aux;
    const os_pers = (1.0 - 0.7) / std.math.pow(f64, 2.0, 5.0) / (1.0 - std.math.pow(f64, 0.7, 5.0)) * 0.5;
    return Params{
        .origin_x = 0,
        .origin_y = 0,
        .nsm = @floatCast(nsm),
        .seg = @floatCast(water_freq),
        .water_level = @floatCast(10.0 * std.math.log2(water_size)),
        .is_hills = @floatCast(nsm / 90.0),
        .is_cliff = @floatCast(nsm / 500.0),
        .os_cliff = 0.6,
        .is_bridge = @floatCast(nsm / 150.0),
        .is_macro1 = @floatCast(nsm / 1600.0),
        .is_macro2 = @floatCast(nsm / 1600.0),
        .is_detail = @floatCast(nsm / 14.0),
        .os_detail = 0.03,
        .offx_detail = @floatCast(10000.0 / nsm),
        .is_pers = @floatCast(nsm / 2.0),
        .os_pers = @floatCast(os_pers),
        .offx_pers = @floatCast(10000.0 / nsm),
        .cold_size = @floatCast(temp.cold_s),
        .hot_size = @floatCast(temp.hot_s),
        .cold_freq = @floatCast(temp.cold_f * fm),
        .hot_freq = @floatCast(temp.hot_f * fm),
        .moist_freq = 1.0,
        .moist_bias = 0.0,
        .aux_freq = 1.0,
        .aux_bias = 0.0,
        .width = 0,
        .height = 0,
        .n_biomes = @intCast(biome.biomes.len),
        .has_water = if (has_water) 1 else 0,
    };
}

/// Per-biome restrict bitmask (se-vulcanite=1, se-cryonite=2, se-vitamelange=4),
/// uploaded so the ore kernel can gate the restricted resources.
pub fn restrictTable(a: std.mem.Allocator) ![]u32 {
    const t = try a.alloc(u32, biome.biomes.len);
    for (biome.biomes, 0..) |b, i| t[i] = @intCast(b.restrict);
    return t;
}

/// Holds the per-map-seed generators + biome table + pipeline; classify() runs
/// render.wgsl over one cell and returns a per-tile biome index buffer.
pub const Classifier = struct {
    ctx: *wgpu.Context,
    pipeline: c.WGPUComputePipeline,
    bgl: c.WGPUBindGroupLayout,
    b_perm1: c.WGPUBuffer,
    b_perm2: c.WGPUBuffer,
    b_grad: c.WGPUBuffer,
    b_sb: c.WGPUBuffer,
    b_table: c.WGPUBuffer,

    pub fn init(a: std.mem.Allocator, ctx: *wgpu.Context, map_seed: u32) !Classifier {
        const nb = biome.biomes.len;
        const perm1 = try a.alloc(u32, NGEN * 256);
        const perm2 = try a.alloc(u32, NGEN * 256);
        const grad = try a.alloc(f32, NGEN * 512);
        const seed_bytes = try a.alloc(u32, NGEN);
        const table = try a.alloc(BiomeGPU, nb);
        const elev_seed1 = [_]u32{ 900, 99584, 700, 1000, 1100, 500, 600 };
        for (elev_seed1, 0..) |s1, i| packGen(i, noise.BasisNoiseGen.init(map_seed, s1), perm1, perm2, grad, seed_bytes);
        for (0..11) |k| packGen(7 + k, noise.BasisNoiseGen.init(map_seed +% @as(u32, @intCast(k)), 5), perm1, perm2, grad, seed_bytes);
        for (0..8) |k| packGen(18 + k, noise.BasisNoiseGen.init(map_seed +% @as(u32, @intCast(k)), 6), perm1, perm2, grad, seed_bytes);
        for (0..8) |k| packGen(26 + k, noise.BasisNoiseGen.init(map_seed +% @as(u32, @intCast(k)), 7), perm1, perm2, grad, seed_bytes);
        for (biome.biomes, 0..) |b, i| {
            packGen(34 + i, noise.BasisNoiseGen.init(map_seed, b.tv_seed), perm1, perm2, grad, seed_bytes);
            var bd = BiomeGPU{ .water_coef = @floatCast(b.water_coef) };
            if (b.t) |r| {
                bd.t_lo = @floatCast(r[0]);
                bd.t_hi = @floatCast(r[1]);
                bd.flags |= 1;
            }
            if (b.m) |r| {
                bd.m_lo = @floatCast(r[0]);
                bd.m_hi = @floatCast(r[1]);
                bd.flags |= 2;
            }
            if (b.a) |r| {
                bd.a_lo = @floatCast(r[0]);
                bd.a_hi = @floatCast(r[1]);
                bd.flags |= 4;
            }
            if (b.e) |r| {
                bd.e_lo = @floatCast(r[0]);
                bd.e_hi = @floatCast(r[1]);
                bd.flags |= 8;
            }
            if (b.beach_weight < 0.0) bd.flags |= 16;
            if (b.crater) bd.flags |= 32;
            table[i] = bd;
        }
        packGen(190, noise.BasisNoiseGen.init(map_seed, biome.WATER_SEED), perm1, perm2, grad, seed_bytes);
        packGen(191, noise.BasisNoiseGen.init(map_seed, biome.CRATER_SEED), perm1, perm2, grad, seed_bytes);

        const pipeline = try ctx.computePipeline(render_wgsl, "main");
        return .{
            .ctx = ctx,
            .pipeline = pipeline,
            .bgl = c.wgpuComputePipelineGetBindGroupLayout(pipeline, 0),
            .b_perm1 = ctx.uploadBuffer(u32, perm1, c.WGPUBufferUsage_Storage),
            .b_perm2 = ctx.uploadBuffer(u32, perm2, c.WGPUBufferUsage_Storage),
            .b_grad = ctx.uploadBuffer(f32, grad, c.WGPUBufferUsage_Storage),
            .b_sb = ctx.uploadBuffer(u32, seed_bytes, c.WGPUBufferUsage_Storage),
            .b_table = ctx.uploadBuffer(BiomeGPU, table, c.WGPUBufferUsage_Storage),
        };
    }

    /// Classify one cell into `out` (len cw*ch) — per-tile biome index / water
    /// sentinel. `base` supplies the control params; origin/size are set here.
    pub fn classify(self: *Classifier, base: Params, x0: i32, y0: i32, cw: u32, ch: u32, out_buf: c.WGPUBuffer) void {
        var p = base;
        p.origin_x = @floatFromInt(x0);
        p.origin_y = @floatFromInt(y0);
        p.width = cw;
        p.height = ch;
        const ctx = self.ctx;
        const bp = ctx.uploadBuffer(Params, &.{p}, c.WGPUBufferUsage_Uniform);
        defer c.wgpuBufferRelease(bp);
        var e = [_]c.WGPUBindGroupEntry{
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 0, .buffer = bp, .size = @sizeOf(Params) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 1, .buffer = self.b_perm1, .size = NGEN * 256 * @sizeOf(u32) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 2, .buffer = self.b_perm2, .size = NGEN * 256 * @sizeOf(u32) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 3, .buffer = self.b_grad, .size = NGEN * 512 * @sizeOf(f32) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 4, .buffer = self.b_sb, .size = NGEN * @sizeOf(u32) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 5, .buffer = self.b_table, .size = biome.biomes.len * @sizeOf(BiomeGPU) }),
            std.mem.zeroInit(c.WGPUBindGroupEntry, .{ .binding = 6, .buffer = out_buf, .size = @as(u64, cw) * ch * @sizeOf(u32) }),
        };
        var bgd = std.mem.zeroInit(c.WGPUBindGroupDescriptor, .{ .layout = self.bgl, .entryCount = e.len, .entries = &e });
        const bg = c.wgpuDeviceCreateBindGroup(ctx.device, &bgd);
        defer c.wgpuBindGroupRelease(bg);
        const enc = c.wgpuDeviceCreateCommandEncoder(ctx.device, null);
        var pd = std.mem.zeroInit(c.WGPUComputePassDescriptor, .{});
        const pass = c.wgpuCommandEncoderBeginComputePass(enc, &pd);
        c.wgpuComputePassEncoderSetPipeline(pass, self.pipeline);
        c.wgpuComputePassEncoderSetBindGroup(pass, 0, bg, 0, null);
        c.wgpuComputePassEncoderDispatchWorkgroups(pass, (cw + 7) / 8, (ch + 7) / 8, 1);
        c.wgpuComputePassEncoderEnd(pass);
        c.wgpuComputePassEncoderRelease(pass);
        const cmd = c.wgpuCommandEncoderFinish(enc, null);
        c.wgpuCommandEncoderRelease(enc);
        c.wgpuQueueSubmit(ctx.queue, 1, &cmd);
        c.wgpuCommandBufferRelease(cmd);
        ctx.poll();
    }
};
