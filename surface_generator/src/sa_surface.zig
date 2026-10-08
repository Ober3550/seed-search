//! Planet surface driver: the tile competition, straight from the data.
//!
//! For each position the game evaluates the probability expression of every
//! tile in the planet's autoplace_settings and places the tile with the
//! highest value. That is all this does: compile every
//! "tile:<name>:probability" of the planet into one program (shared
//! sub-expressions evaluated once) and take the argmax per position.

const std = @import("std");
const sa_data = @import("sa_data.zig");
const prog = @import("sa_program.zig");
const rng = @import("rng.zig");

/// The game evaluates a tile's expressions at the tile's integer coordinate
/// (its top-left corner), not its centre - verified against live tile dumps.
pub const SAMPLE_OFFSET: f32 = 0.0;

pub const Surface = struct {
    planet: *const sa_data.Planet,
    program: prog.Program,
    ws: prog.Program.Workspace,

    /// `err_out` receives a description when compilation fails.
    pub fn init(a: std.mem.Allocator, data: *const sa_data.Data, planet: *const sa_data.Planet, map_seed: u32, controls: prog.Controls, err_out: ?*[]const u8) !Surface {
        if (planet.tiles.len == 0) return error.NoTiles;
        const names = try a.alloc([]const u8, planet.tiles.len);
        for (planet.tiles, 0..) |t, i| names[i] = try std.fmt.allocPrint(a, "tile:{s}:probability", .{t.name});
        const program = try prog.compile(a, data, planet, map_seed, controls, names, err_out);
        return .{ .planet = planet, .program = program, .ws = try program.workspace(a) };
    }

    /// Winning tile index (into planet.tiles) for the `out.len` tiles of row
    /// `y` starting at tile `x0`.
    pub fn tileRow(self: *Surface, x0: i32, y: i32, out: []u16) void {
        const B = prog.Program.BATCH;
        var xs: [B]f32 = undefined;
        var ys: [B]f32 = undefined;
        var done: usize = 0;
        while (done < out.len) {
            const n = @min(B, out.len - done);
            for (0..n) |j| {
                xs[j] = @as(f32, @floatFromInt(x0 + @as(i32, @intCast(done + j)))) + SAMPLE_OFFSET;
                ys[j] = @as(f32, @floatFromInt(y)) + SAMPLE_OFFSET;
            }
            self.program.eval(&self.ws, xs[0..n], ys[0..n]);
            var best: [B]f32 = undefined;
            @memset(best[0..n], -std.math.inf(f32));
            @memset(out[done..][0..n], 0);
            for (0..self.planet.tiles.len) |t| {
                const p = self.program.out(&self.ws, t);
                for (0..n) |j| {
                    // on a tie the earlier tile (prototype order) wins
                    if (p[j] > best[j]) {
                        best[j] = p[j];
                        out[done + j] = @intCast(t);
                    }
                }
            }
            done += n;
        }
    }

    /// RGBA8 colours for a width x height rectangle whose top-left tile is
    /// (x0, y0), one tile per pixel.
    pub fn renderRgba(self: *Surface, a: std.mem.Allocator, x0: i32, y0: i32, width: usize, height: usize, pixels: []u8) !void {
        std.debug.assert(pixels.len == width * height * 4);
        const row = try a.alloc(u16, width);
        defer a.free(row);
        for (0..height) |r| {
            self.tileRow(x0, y0 + @as(i32, @intCast(r)), row);
            for (row, 0..) |t, cidx| {
                const col = self.planet.tiles[t].color;
                const px = pixels[(r * width + cidx) * 4 ..][0..4];
                px.* = .{ col[0], col[1], col[2], 255 };
            }
        }
    }
};

// ---------------------------------------------------------------------------
// Chunks: tiles + resource placement
// ---------------------------------------------------------------------------

pub const CHUNK = 32;
const AREA = CHUNK * CHUNK;
pub const NO_RESOURCE: u8 = 255;

/// One generated 32x32 chunk, row-major from the chunk's top-left tile.
pub const ChunkData = struct {
    /// winning tile (index into planet.tiles)
    tile: [AREA]u16,
    /// resource covering the tile (index into planet.resources) or NO_RESOURCE
    resource: [AREA]u8,
    /// amount of the resource entity centred on the tile (0 elsewhere)
    amount: [AREA]u32,
};

/// Tiles and resources, generated chunk by chunk the way the game does.
///
/// Entity placement (EntityMapGenerationTask::generateEntities): the chunk is
/// one column of 1024 positions, so `random_penalty` draws from a single
/// stream seeded at the chunk origin. Resources are placed group by group in
/// autoplace-order; within a group the highest probability wins a tile (ties:
/// higher richness) and is placed when a draw from the chunk's placement RNG
/// falls below it. A tile whose collision mask has the "resource" layer
/// (water, lava, oil) takes no resources.
///
/// Approximations: the placement RNG is shared with every other entity group
/// (rocks, trees, ruins) which are not generated, so the draws used here are
/// not the game's; that only matters where probability is between 0 and 1
/// (patch edges and sparse fluid patches). Multi-tile patches only avoid
/// overlaps within their own chunk.
pub const World = struct {
    planet: *const sa_data.Planet,
    program: prog.Program,
    ws: prog.Program.Workspace,
    /// root index of each resource's probability / richness (null = none)
    res_prob: []const usize,
    res_rich: []const ?usize,
    xs: []f32,
    ys: []f32,

    pub fn init(a: std.mem.Allocator, data: *const sa_data.Data, planet: *const sa_data.Planet, map_seed: u32, controls: prog.Controls, err_out: ?*[]const u8) !World {
        if (planet.tiles.len == 0) return error.NoTiles;
        if (planet.resources.len >= NO_RESOURCE) return error.TooManyResources;
        var names: std.ArrayList([]const u8) = .empty;
        for (planet.tiles) |t| try names.append(a, try std.fmt.allocPrint(a, "tile:{s}:probability", .{t.name}));
        const res_prob = try a.alloc(usize, planet.resources.len);
        const res_rich = try a.alloc(?usize, planet.resources.len);
        for (planet.resources, 0..) |r, i| {
            res_prob[i] = names.items.len;
            try names.append(a, try std.fmt.allocPrint(a, "entity:{s}:probability", .{r.name}));
            const rich = try std.fmt.allocPrint(a, "entity:{s}:richness", .{r.name});
            if (data.def(rich) != null or planet.prop(rich) != null) {
                res_rich[i] = names.items.len;
                try names.append(a, rich);
            } else res_rich[i] = null;
        }
        const program = try prog.compile(a, data, planet, map_seed, controls, names.items, err_out);
        var ws = try program.workspaceN(a, AREA);
        ws.column_rng = true;
        return .{
            .planet = planet,
            .program = program,
            .ws = ws,
            .res_prob = res_prob,
            .res_rich = res_rich,
            .xs = try a.alloc(f32, AREA),
            .ys = try a.alloc(f32, AREA),
        };
    }

    /// Generate chunk (cx, cy): tiles (cx*32 .. cx*32+31, cy*32 .. cy*32+31).
    pub fn chunk(self: *World, cx: i32, cy: i32, out: *ChunkData) void {
        for (0..AREA) |i| {
            self.xs[i] = @as(f32, @floatFromInt(cx * CHUNK + @as(i32, @intCast(i % CHUNK)))) + SAMPLE_OFFSET;
            self.ys[i] = @as(f32, @floatFromInt(cy * CHUNK + @as(i32, @intCast(i / CHUNK)))) + SAMPLE_OFFSET;
        }
        self.program.eval(&self.ws, self.xs, self.ys);

        // tile competition
        var best: [AREA]f32 = undefined;
        @memset(&best, -std.math.inf(f32));
        @memset(&out.tile, 0);
        for (0..self.planet.tiles.len) |t| {
            const p = self.program.out(&self.ws, t);
            for (0..AREA) |i| {
                if (p[i] > best[i]) {
                    best[i] = p[i];
                    out.tile[i] = @intCast(t);
                }
            }
        }
        @memset(&out.resource, NO_RESOURCE);
        @memset(&out.amount, 0);
        if (self.planet.resources.len == 0) return;

        var blocked: [AREA]bool = undefined;
        for (0..AREA) |i| blocked[i] = self.planet.tiles[out.tile[i]].blocks_resource;

        // the chunk's placement stream (taus88 seeded from the chunk position)
        var seed: u32 = @bitCast(cy *% 7907 +% cx *% 7919 +% 0x3fbe2c);
        if (seed < 342) seed = 341;
        var prng = rng.Rng.init(seed);

        const res = self.planet.resources;
        var g0: usize = 0;
        while (g0 < res.len) {
            var g1 = g0 + 1;
            while (g1 < res.len and std.mem.eql(u8, res[g1].order, res[g0].order)) g1 += 1;
            // tiles are swept last to first; every unblocked tile takes a draw
            var i: usize = AREA;
            while (i > 0) {
                i -= 1;
                if (blocked[i]) continue;
                const draw: f32 = @floatCast(prng.float());
                var win: ?usize = null;
                var win_p: f32 = 0;
                var win_rich: f32 = 0;
                for (g0..g1) |r| {
                    const p = self.program.out(&self.ws, self.res_prob[r])[i];
                    if (!(p > 0)) continue;
                    const rich: f32 = if (self.res_rich[r]) |ri| self.program.out(&self.ws, ri)[i] else 1;
                    if (win == null or p > win_p or (p == win_p and rich > win_rich)) {
                        win = r;
                        win_p = p;
                        win_rich = rich;
                    }
                }
                const r = win orelse continue;
                if (!(draw < win_p) or !(win_rich > 0)) continue;
                if (!self.footprintFree(out, &blocked, i, res[r].size)) continue;
                self.stamp(out, i, @intCast(r), res[r].size);
                out.amount[i] = @intFromFloat(@min(@max(win_rich, 1), 4.0e9));
            }
            g0 = g1;
        }
    }

    fn footprintFree(_: *const World, out: *const ChunkData, blocked: *const [AREA]bool, i: usize, size: u8) bool {
        if (size <= 1) return out.resource[i] == NO_RESOURCE;
        const h: i32 = @divTrunc(@as(i32, size), 2);
        const x: i32 = @intCast(i % CHUNK);
        const y: i32 = @intCast(i / CHUNK);
        var dy: i32 = -h;
        while (dy <= h) : (dy += 1) {
            var dx: i32 = -h;
            while (dx <= h) : (dx += 1) {
                const nx = x + dx;
                const ny = y + dy;
                if (nx < 0 or ny < 0 or nx >= CHUNK or ny >= CHUNK) continue;
                const j: usize = @intCast(ny * CHUNK + nx);
                if (blocked[j] or out.resource[j] != NO_RESOURCE) return false;
            }
        }
        return true;
    }

    fn stamp(_: *const World, out: *ChunkData, i: usize, r: u8, size: u8) void {
        const h: i32 = @divTrunc(@as(i32, size), 2);
        const x: i32 = @intCast(i % CHUNK);
        const y: i32 = @intCast(i / CHUNK);
        var dy: i32 = -h;
        while (dy <= h) : (dy += 1) {
            var dx: i32 = -h;
            while (dx <= h) : (dx += 1) {
                const nx = x + dx;
                const ny = y + dy;
                if (nx < 0 or ny < 0 or nx >= CHUNK or ny >= CHUNK) continue;
                out.resource[@intCast(ny * CHUNK + nx)] = r;
            }
        }
    }

    /// Per-resource totals, accumulated by render().
    pub const Totals = struct { count: u64 = 0, amount: u64 = 0 };

    /// Render a rectangle as two RGBA8 layers, one tile per pixel: `terrain`
    /// (opaque tile colours) and `overlay` (resource colours, transparent
    /// where there is none). Either may be null. `tile_counts` (per
    /// planet.tiles) and `totals` (per planet.resources) are added to.
    pub fn render(self: *World, x0: i32, y0: i32, width: usize, height: usize, terrain: ?[]u8, overlay: ?[]u8, tile_counts: ?[]u32, totals: ?[]Totals) void {
        if (overlay) |o| @memset(o, 0);
        const x1 = x0 + @as(i32, @intCast(width));
        const y1 = y0 + @as(i32, @intCast(height));
        var data: ChunkData = undefined;
        var cy = @divFloor(y0, CHUNK);
        while (cy * CHUNK < y1) : (cy += 1) {
            var cx = @divFloor(x0, CHUNK);
            while (cx * CHUNK < x1) : (cx += 1) {
                self.chunk(cx, cy, &data);
                for (0..AREA) |i| {
                    const tx = cx * CHUNK + @as(i32, @intCast(i % CHUNK));
                    const ty = cy * CHUNK + @as(i32, @intCast(i / CHUNK));
                    if (tx < x0 or tx >= x1 or ty < y0 or ty >= y1) continue;
                    const px = (@as(usize, @intCast(ty - y0)) * width + @as(usize, @intCast(tx - x0))) * 4;
                    if (tile_counts) |tc| tc[data.tile[i]] += 1;
                    if (terrain) |t| {
                        const c = self.planet.tiles[data.tile[i]].color;
                        t[px..][0..4].* = .{ c[0], c[1], c[2], 255 };
                    }
                    const r = data.resource[i];
                    if (r == NO_RESOURCE) continue;
                    if (overlay) |o| {
                        const c = self.planet.resources[r].color;
                        o[px..][0..4].* = .{ c[0], c[1], c[2], 255 };
                    }
                    if (totals) |t| {
                        if (data.amount[i] > 0) {
                            t[r].count += 1;
                            t[r].amount += data.amount[i];
                        }
                    }
                }
            }
        }
    }
};
