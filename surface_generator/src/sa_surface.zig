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

/// Opacity of an enemy-area tile from the placement probability there, on a
/// log scale: faint at 0.001 (a nest somewhere in a thousand tiles), solid by
/// 0.25 (where the base game's spawner probability stops rising).
pub fn enemyAlpha(v: f32) u8 {
    const t = @min(1.0, @max(0.0, (@log10(@max(v, 1e-6)) + 3.0) / 2.4));
    return @intFromFloat(70.0 + 150.0 * t);
}

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
    /// the rocks, trees, plants and enemy buildings that end up on the
    /// surface, in placement order (only with Options.entities)
    ents: [MAX_ENTS]Placed,
    n_ents: usize,
};

/// One placed non-resource entity: index into planet.placed and its position
/// in 1/256 tile (the engine's fixed-point map position).
pub const Placed = struct { ent: u16, x: i32, y: i32 };
pub const MAX_ENTS = 4096;

/// Map colour of an entity class in the entities layer (null = not drawn).
pub fn classColor(c: sa_data.Entity.Class) ?[3]u8 {
    return switch (c) {
        .tree => .{ 38, 128, 54 },
        .plant => .{ 140, 190, 70 },
        .rock => .{ 168, 150, 128 },
        .spawner => .{ 255, 40, 40 },
        .worm => .{ 255, 150, 20 },
        .cliff => .{ 222, 205, 160 },
        .other => .{ 200, 130, 235 },
        .resource, .fish => null,
    };
}

/// Tiles and resources, generated chunk by chunk the way the game does.
///
/// Entity placement (EntityMapGenerationTask::generateEntities): the chunk is
/// one column of 1024 positions, so `random_penalty` draws from a single
/// stream seeded at the chunk origin. Every autoplaced entity of the surface
/// belongs to a group (its autoplace order); groups are placed in order and
/// share ONE random stream per chunk. A group sweeps the tiles last to first:
/// on each tile, among its entities that may stand there (collision layers
/// and tile restriction), the highest probability wins (ties: higher
/// richness); the tile takes one draw, and the winner is placed when the draw
/// falls below its probability. Rocks, trees, ruins and enemies then take two
/// more draws for their sub-tile offset; resources are centre-placed.
///
/// Only resources are kept, but every group up to the last resource group is
/// replayed, because where a resource's rolls start in the stream depends on
/// the groups before it. Overlap between entities is only tracked for
/// resources, within their chunk.
pub const World = struct {
    planet: *const sa_data.Planet,
    program: prog.Program,
    ws: prog.Program.Workspace,
    /// planet.placed entities taking part (through the last resource group)
    n_placed: usize,
    /// root index of each entity's probability / richness (null = none)
    ent_prob: []const usize,
    ent_rich: []const ?usize,
    /// tiles come from the caller (chunkWith) instead of the tile competition
    external_tiles: bool,
    /// Planets with autoplaced enemy buildings (spawners, worms): their
    /// placement probabilities compiled on their own, evaluated without the
    /// random penalty, so a positive value marks where a nest can appear -
    /// see render(). `enemy_ents` are their indices into planet.placed.
    enemy_program: ?prog.Program,
    enemy_ws: prog.Program.Workspace,
    enemy_ents: []const usize,
    /// Options.entities
    record: bool,
    /// the tile competition alone, for single tiles outside the chunk being
    /// generated (an entity's box can reach into a neighbouring chunk)
    tiles_program: ?prog.Program,
    tiles_ws: prog.Program.Workspace,
    xs: []f32,
    ys: []f32,

    pub const Options = struct {
        /// do not compile the tile competition; chunkWith() is given the tiles
        external_tiles: bool = false,
        /// place every autoplaced entity, not only the resources, and keep
        /// the ones that survive the collision checks in ChunkData.ents
        entities: bool = false,
    };

    pub fn init(a: std.mem.Allocator, data: *const sa_data.Data, planet: *const sa_data.Planet, map_seed: u32, controls: prog.Controls, err_out: ?*[]const u8) !World {
        return initWith(a, data, planet, map_seed, controls, .{}, err_out);
    }

    pub fn initWith(a: std.mem.Allocator, data: *const sa_data.Data, planet: *const sa_data.Planet, map_seed: u32, controls: prog.Controls, opts: Options, err_out: ?*[]const u8) !World {
        if (planet.tiles.len == 0) return error.NoTiles;
        if (planet.resources.len >= NO_RESOURCE) return error.TooManyResources;
        var names: std.ArrayList([]const u8) = .empty;
        if (!opts.external_tiles) {
            for (planet.tiles) |t| try names.append(a, try std.fmt.allocPrint(a, "tile:{s}:probability", .{t.name}));
        }
        // nothing after the last resource group can affect a resource
        var n_placed: usize = 0;
        for (planet.placed, 0..) |e, i| {
            if (e.kind == .resource or opts.entities) n_placed = i + 1;
        }
        while (n_placed < planet.placed.len and std.mem.eql(u8, planet.placed[n_placed].order, planet.placed[n_placed - 1].order)) n_placed += 1;
        const ent_prob = try a.alloc(usize, n_placed);
        const ent_rich = try a.alloc(?usize, n_placed);
        for (planet.placed[0..n_placed], 0..) |e, i| {
            ent_prob[i] = names.items.len;
            try names.append(a, try std.fmt.allocPrint(a, "entity:{s}:probability", .{e.name}));
            ent_rich[i] = null;
            if (e.kind != .resource) continue;
            const rich = try std.fmt.allocPrint(a, "entity:{s}:richness", .{e.name});
            if (data.def(rich) != null or planet.prop(rich) != null) {
                ent_rich[i] = names.items.len;
                try names.append(a, rich);
            }
        }
        var enemy_ents: std.ArrayList(usize) = .empty;
        var enemy_names: std.ArrayList([]const u8) = .empty;
        for (planet.placed, 0..) |e, i| {
            if (!e.enemy) continue;
            try enemy_ents.append(a, i);
            try enemy_names.append(a, try std.fmt.allocPrint(a, "entity:{s}:probability", .{e.name}));
        }
        var enemy_program: ?prog.Program = null;
        var enemy_ws: prog.Program.Workspace = undefined;
        if (enemy_ents.items.len > 0) {
            const ep = try prog.compile(a, data, planet, map_seed, controls, enemy_names.items, err_out);
            enemy_ws = try ep.workspaceN(a, AREA);
            enemy_ws.no_penalty = true;
            enemy_program = ep;
        }
        var tiles_program: ?prog.Program = null;
        var tiles_ws: prog.Program.Workspace = undefined;
        if (opts.entities and !opts.external_tiles) {
            const tp = try prog.compile(a, data, planet, map_seed, controls, names.items[0..planet.tiles.len], err_out);
            tiles_ws = try tp.workspaceN(a, 1);
            tiles_program = tp;
        }
        const program = try prog.compile(a, data, planet, map_seed, controls, names.items, err_out);
        var ws = try program.workspaceN(a, AREA);
        ws.column_rng = true;
        return .{
            .planet = planet,
            .program = program,
            .ws = ws,
            .n_placed = n_placed,
            .ent_prob = ent_prob,
            .ent_rich = ent_rich,
            .external_tiles = opts.external_tiles,
            .enemy_program = enemy_program,
            .enemy_ws = enemy_ws,
            .enemy_ents = enemy_ents.items,
            .record = opts.entities,
            .tiles_program = tiles_program,
            .tiles_ws = tiles_ws,
            .xs = try a.alloc(f32, AREA),
            .ys = try a.alloc(f32, AREA),
        };
    }

    /// Generate chunk (cx, cy): tiles (cx*32 .. cx*32+31, cy*32 .. cy*32+31).
    pub fn chunk(self: *World, cx: i32, cy: i32, out: *ChunkData) void {
        self.chunkWith(cx, cy, null, out);
    }

    /// As chunk(), with the chunk's tiles (indices into planet.tiles) supplied
    /// by the caller - required when the world was built with external_tiles.
    pub fn chunkWith(self: *World, cx: i32, cy: i32, tiles: ?*const [AREA]u16, out: *ChunkData) void {
        for (0..AREA) |i| {
            self.xs[i] = @as(f32, @floatFromInt(cx * CHUNK + @as(i32, @intCast(i % CHUNK)))) + SAMPLE_OFFSET;
            self.ys[i] = @as(f32, @floatFromInt(cy * CHUNK + @as(i32, @intCast(i / CHUNK)))) + SAMPLE_OFFSET;
        }
        self.program.eval(&self.ws, self.xs, self.ys);

        if (tiles) |t| {
            out.tile = t.*;
        } else {
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
        }
        @memset(&out.resource, NO_RESOURCE);
        @memset(&out.amount, 0);
        out.n_ents = 0;
        if (self.n_placed == 0) return;

        var blocked: [AREA]bool = undefined;
        for (0..AREA) |i| blocked[i] = self.planet.tiles[out.tile[i]].blocks_resource;

        // the chunk's placement stream (taus88 seeded from the chunk position)
        var seed: u32 = @bitCast(cy *% 7907 +% cx *% 7919 +% 0x3fbe2c);
        if (seed < 342) seed = 341;
        var prng = rng.Rng.init(seed);

        const placed = self.planet.placed[0..self.n_placed];
        var g0: usize = 0;
        while (g0 < placed.len) {
            var g1 = g0 + 1;
            while (g1 < placed.len and std.mem.eql(u8, placed[g1].order, placed[g0].order)) g1 += 1;
            var i: usize = AREA;
            while (i > 0) {
                i -= 1;
                const ti = out.tile[i];
                const tile = &self.planet.tiles[ti];
                var win: ?usize = null;
                var win_p: f32 = -std.math.inf(f32);
                var win_rich: f32 = 0;
                for (g0..g1) |e| {
                    if (!placed[e].canStandOn(ti, tile)) continue;
                    var p = self.program.out(&self.ws, self.ent_prob[e])[i];
                    if (!(p == p)) p = -std.math.inf(f32);
                    const rich: f32 = if (self.ent_rich[e]) |ri| self.program.out(&self.ws, ri)[i] else 1;
                    if (win == null or p > win_p or (p == win_p and rich > win_rich)) {
                        win = e;
                        win_p = p;
                        win_rich = rich;
                    }
                }
                // a tile nothing in the group can stand on takes no draw
                const e = win orelse continue;
                const ent = &placed[e];
                var attempt: u32 = 0;
                while (attempt < ent.density) : (attempt += 1) {
                    const draw: f32 = @floatCast(prng.float());
                    if (!(draw < win_p)) continue;
                    const r = ent.resource orelse {
                        // EntityMapGenerationTask::generateEntityOnTile: an
                        // off-grid entity takes two more draws for its
                        // position within the tile (in sixteenths); any other
                        // snaps to the grid and takes none.
                        var px: i32 = (cx * CHUNK + @as(i32, @intCast(i % CHUNK))) * 256;
                        var py: i32 = (cy * CHUNK + @as(i32, @intCast(i / CHUNK))) * 256;
                        if (ent.off_grid) {
                            px += @as(i32, @intFromFloat(prng.float() * 256.0)) & ~@as(i32, 0xf);
                            py += @as(i32, @intFromFloat(prng.float() * 256.0)) & ~@as(i32, 0xf);
                        } else {
                            // an odd-sized building is centred on its tile
                            if ((@divFloor(ent.box[2] - ent.box[0] + 255, 256) & 1) == 1) px += 128;
                            if ((@divFloor(ent.box[3] - ent.box[1] + 255, 256) & 1) == 1) py += 128;
                        }
                        // tryToAddEntity: dropped when its box touches a
                        // tile it collides with
                        if (self.record and out.n_ents < MAX_ENTS and self.boxOnTiles(out, cx, cy, ent, px, py)) {
                            out.ents[out.n_ents] = .{ .ent = @intCast(e), .x = px, .y = py };
                            out.n_ents += 1;
                        }
                        continue;
                    };
                    if (!(win_rich > 0)) continue;
                    const size = self.planet.resources[r].size;
                    if (!self.footprintFree(out, &blocked, i, size)) continue;
                    self.stamp(out, i, r, size);
                    out.amount[i] = @intFromFloat(@min(@max(win_rich, 1), 4.0e9));
                }
            }
            g0 = g1;
        }
        if (self.record) self.applyEntities(out);
    }

    /// EntityMapGenerationTask::wouldCollide: every tile under the entity's
    /// box must be one it does not collide with.
    fn boxOnTiles(self: *World, out: *const ChunkData, cx: i32, cy: i32, ent: *const sa_data.Entity, px: i32, py: i32) bool {
        const x0 = (ent.box[0] + px) >> 8;
        const x1 = (ent.box[2] + px) >> 8;
        const y0 = (ent.box[1] + py) >> 8;
        const y1 = (ent.box[3] + py) >> 8;
        var ty = y0;
        while (ty <= y1) : (ty += 1) {
            var tx = x0;
            while (tx <= x1) : (tx += 1) {
                const ti = self.tileAt(out, cx, cy, tx, ty);
                if (ent.mask & self.planet.tiles[ti].mask != 0) return false;
            }
        }
        return true;
    }

    fn tileAt(self: *World, out: *const ChunkData, cx: i32, cy: i32, tx: i32, ty: i32) u16 {
        const lx = tx - cx * CHUNK;
        const ly = ty - cy * CHUNK;
        if (lx >= 0 and ly >= 0 and lx < CHUNK and ly < CHUNK) return out.tile[@intCast(ly * CHUNK + lx)];
        if (self.tiles_program) |*tp| {
            tp.eval(&self.tiles_ws, &.{@as(f32, @floatFromInt(tx)) + SAMPLE_OFFSET}, &.{@as(f32, @floatFromInt(ty)) + SAMPLE_OFFSET});
            var best: f32 = -std.math.inf(f32);
            var bi: u16 = 0;
            for (0..self.planet.tiles.len) |t| {
                const p = tp.out(&self.tiles_ws, t)[0];
                if (p > best) {
                    best = p;
                    bi = @intCast(t);
                }
            }
            return bi;
        }
        // supplied tiles stop at the chunk: take the nearest one inside
        const kx: usize = @intCast(@min(@max(lx, 0), CHUNK - 1));
        const ky: usize = @intCast(@min(@max(ly, 0), CHUNK - 1));
        return out.tile[ky * CHUNK + kx];
    }

    /// EntityMapGenerationTask::applyEntities: the chunk's entities go onto
    /// the surface in the order they were generated, and one is dropped when
    /// its box overlaps an entity already there that shares a collision layer
    /// with it. Only this chunk's own entities are known here.
    fn applyEntities(self: *World, out: *ChunkData) void {
        const placed = self.planet.placed;
        var kept: usize = 0;
        for (out.ents[0..out.n_ents]) |c| {
            const ce = &placed[c.ent];
            var hit = false;
            for (out.ents[0..kept]) |k| {
                const ke = &placed[k.ent];
                if (ce.mask & ke.mask == 0) continue;
                if (c.x + ce.box[0] < k.x + ke.box[2] and c.x + ce.box[2] > k.x + ke.box[0] and
                    c.y + ce.box[1] < k.y + ke.box[3] and c.y + ce.box[3] > k.y + ke.box[1])
                {
                    hit = true;
                    break;
                }
            }
            if (hit) continue;
            out.ents[kept] = c;
            kept += 1;
        }
        out.n_ents = kept;
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

    /// Render a rectangle as RGBA8 layers, one tile per pixel: `terrain`
    /// (opaque tile colours), `overlay` (resource colours, transparent where
    /// there is none) and `enemies` (enemy base areas: translucent red on
    /// every tile where some enemy building could be placed - it may stand
    /// on the tile and its probability, before the random penalty, is
    /// positive - stronger where that is likelier; nothing on a planet
    /// without autoplaced enemies). These are the areas nests appear in, not
    /// the nests: their exact tiles also depend on every tree, rock and
    /// cliff placed before them. Any may be null. `tile_counts` (per
    /// planet.tiles) and `totals` (per planet.resources) are added to.
    /// A world built with Options.entities draws its entities into `enemies`
    /// instead: every rock, tree, plant and enemy building that survives
    /// placement, as its footprint in its class colour (classColor), counted
    /// per class in `class_counts`.
    /// Returns the number of enemy-area tiles / entities drawn.
    pub fn render(self: *World, x0: i32, y0: i32, width: usize, height: usize, terrain: ?[]u8, overlay: ?[]u8, enemies: ?[]u8, tile_counts: ?[]u32, totals: ?[]Totals, class_counts: ?*[9]u32) u64 {
        if (overlay) |o| @memset(o, 0);
        if (enemies) |o| @memset(o, 0);
        var enemy_tiles: u64 = 0;
        const x1 = x0 + @as(i32, @intCast(width));
        const y1 = y0 + @as(i32, @intCast(height));
        var data: ChunkData = undefined;
        var cy = @divFloor(y0, CHUNK);
        while (cy * CHUNK < y1) : (cy += 1) {
            var cx = @divFloor(x0, CHUNK);
            while (cx * CHUNK < x1) : (cx += 1) {
                self.chunk(cx, cy, &data);
                const want_enemy = self.enemy_program != null and !self.record;
                if (want_enemy) self.enemy_program.?.eval(&self.enemy_ws, self.xs, self.ys);
                for (data.ents[0..data.n_ents]) |pe| {
                    const ent = &self.planet.placed[pe.ent];
                    // counted where its position is, drawn wherever its box reaches
                    const ex = pe.x >> 8;
                    const ey = pe.y >> 8;
                    if (ex < x0 or ex >= x1 or ey < y0 or ey >= y1) continue;
                    enemy_tiles += 1;
                    if (class_counts) |cc| cc[@intFromEnum(ent.class)] += 1;
                    const col = classColor(ent.class) orelse continue;
                    const o = enemies orelse continue;
                    var ty = (pe.y + ent.box[1]) >> 8;
                    while (ty <= (pe.y + ent.box[3]) >> 8) : (ty += 1) {
                        var tx = (pe.x + ent.box[0]) >> 8;
                        while (tx <= (pe.x + ent.box[2]) >> 8) : (tx += 1) {
                            if (tx < x0 or tx >= x1 or ty < y0 or ty >= y1) continue;
                            const q = (@as(usize, @intCast(ty - y0)) * width + @as(usize, @intCast(tx - x0))) * 4;
                            o[q..][0..4].* = .{ col[0], col[1], col[2], 255 };
                        }
                    }
                }
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
                    if (want_enemy) {
                        const ti = data.tile[i];
                        var v: f32 = 0;
                        for (self.enemy_ents, 0..) |e, k| {
                            if (!self.planet.placed[e].canStandOn(ti, &self.planet.tiles[ti])) continue;
                            v = @max(v, self.enemy_program.?.out(&self.enemy_ws, k)[i]);
                        }
                        if (v > 0) {
                            enemy_tiles += 1;
                            if (enemies) |o| o[px..][0..4].* = .{ 255, 40, 40, enemyAlpha(v) };
                        }
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
        return enemy_tiles;
    }
};

// ---------------------------------------------------------------------------
// Placement stream of the non-resource entities
// ---------------------------------------------------------------------------

/// Where a resource group's rolls start in a chunk's placement stream.
///
/// Every autoplace group of a chunk draws from ONE random stream, in
/// autoplace-order: each group sweeps the chunk's tiles last to first and
/// takes one draw per tile it could stand on (fish: water; everything else:
/// land); an entity whose roll passes (draw < probability) and that is placed
/// off the grid - rocks, trees, worms - takes two more draws for its sub-tile
/// offset. So the rolls of a late group (crude oil is in "c") start
/// at a position that depends on how many rocks, trees and enemies were
/// attempted before it. This replays just those rolls - nothing is placed or
/// rendered - to count them.
pub const EntityRolls = struct {
    planet: *const sa_data.Planet,
    program: prog.Program,
    ws: prog.Program.Workspace,
    /// root index per planet.placed entry (unused for resources)
    roots: []const usize,
    xs: []f32,
    ys: []f32,

    pub fn init(a: std.mem.Allocator, data: *const sa_data.Data, planet: *const sa_data.Planet, map_seed: u32, controls: prog.Controls, err_out: ?*[]const u8) !EntityRolls {
        var names: std.ArrayList([]const u8) = .empty;
        const roots = try a.alloc(usize, planet.placed.len);
        for (planet.placed, 0..) |e, i| {
            roots[i] = names.items.len;
            if (e.kind == .resource) continue;
            try names.append(a, try std.fmt.allocPrint(a, "entity:{s}:probability", .{e.name}));
        }
        const program = try prog.compile(a, data, planet, map_seed, controls, names.items, err_out);
        var ws = try program.workspaceN(a, AREA);
        ws.column_rng = true;
        return .{ .planet = planet, .program = program, .ws = ws, .roots = roots, .xs = try a.alloc(f32, AREA), .ys = try a.alloc(f32, AREA) };
    }

    /// Replay chunk (cx, cy). `water[i]` marks the tiles only water entities
    /// can use. `out[k]` receives the number of passing non-resource rolls
    /// between resource group k-1 and resource group k (k = 0: before the
    /// first), for the first `out.len` resource groups in placement order.
    pub fn attempts(self: *EntityRolls, cx: i32, cy: i32, water: *const [AREA]bool, out: []u32) void {
        @memset(out, 0);
        for (0..AREA) |i| {
            self.xs[i] = @as(f32, @floatFromInt(cx * CHUNK + @as(i32, @intCast(i % CHUNK)))) + SAMPLE_OFFSET;
            self.ys[i] = @as(f32, @floatFromInt(cy * CHUNK + @as(i32, @intCast(i / CHUNK)))) + SAMPLE_OFFSET;
        }
        self.program.eval(&self.ws, self.xs, self.ys);
        var land_count: u32 = 0;
        for (water) |w| land_count += @intFromBool(!w);

        var seed: u32 = @bitCast(cy *% 7907 +% cx *% 7919 +% 0x3fbe2c);
        if (seed < 342) seed = 341;
        var prng = rng.Rng.init(seed);

        const placed = self.planet.placed;
        var slot: usize = 0; // resource groups passed so far
        var g0: usize = 0;
        while (g0 < placed.len and slot < out.len) {
            var g1 = g0 + 1;
            while (g1 < placed.len and std.mem.eql(u8, placed[g1].order, placed[g0].order)) g1 += 1;
            if (placed[g0].kind == .resource) {
                // resources are centre-placed: one draw per land tile, no more
                var k: u32 = 0;
                while (k < land_count) : (k += 1) _ = prng.next();
                slot += 1;
            } else {
                const on_water = placed[g0].kind == .water;
                var i: usize = AREA;
                while (i > 0) {
                    i -= 1;
                    if (water[i] != on_water) continue;
                    const draw: f32 = @floatCast(prng.float());
                    var p: f32 = 0;
                    var win: usize = g0;
                    for (g0..g1) |e| {
                        const v = self.program.out(&self.ws, self.roots[e])[i];
                        if (v > p) {
                            p = v;
                            win = e;
                        }
                    }
                    if (draw < p) {
                        out[slot] += 1;
                        // only an off-grid entity draws its sub-tile offset
                        // (biter and spitter spawners snap to the grid)
                        if (placed[win].off_grid) {
                            _ = prng.next();
                            _ = prng.next();
                        }
                    }
                }
            }
            g0 = g1;
        }
    }
};
