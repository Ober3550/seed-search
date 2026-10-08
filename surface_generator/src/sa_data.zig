//! Map-generation data for the generic planet surface generator.
//!
//! Everything here comes from the game's own data stage (`factorio
//! --dump-data`, reduced by scripts/sa-build-data.py into
//! sa_noise_data.json): every named noise expression and noise function, the
//! autoplace expressions of every tile/entity (stored under the engine's
//! property names, e.g. "tile:lava:probability"), and per planet the
//! map_gen_settings wiring. No planet is special-cased in code: adding a
//! planet (or a mod's surfaces) means regenerating the data file.

const std = @import("std");
const json = @import("sa_json.zig");
const ast = @import("sa_expr.zig");

const embedded = @embedFile("sa_noise_data.json");

/// An expression body as stored in the data: source text or a plain number.
pub const Body = union(enum) { src: []const u8, num: f64 };

pub const Local = struct {
    name: []const u8,
    body: Body,
    node: ?*ast.Node = null, // parsed on first use
};

/// A named noise expression (no parameters) or noise function.
pub const Def = struct {
    name: []const u8,
    is_function: bool,
    params: []const []const u8,
    body: Body,
    locals: []Local,
    local_fns: []Def,
    root: ?*ast.Node = null, // parsed on first use
};

pub const Tile = struct {
    name: []const u8,
    layer: i32,
    color: [3]u8,
    /// collision layers as a bit set (see Data.layerBit): an entity cannot
    /// stand on a tile that shares a layer with its own mask
    mask: u64,
    /// shorthand: the mask has the "resource" layer (water, lava, ...)
    blocks_resource: bool,
};

/// An autoplaced resource entity (ore tile or fluid patch).
pub const Resource = struct {
    name: []const u8,
    /// autoplace order: resources sharing it compete in one placement group
    order: []const u8,
    color: [3]u8,
    /// footprint in tiles (1 for ores, 3 for fluid patches)
    size: u8,
};

/// Any autoplaced entity of a surface, for simulating the placement stream.
pub const Entity = struct {
    name: []const u8,
    order: []const u8,
    kind: enum { resource, water, land },
    /// collision layers (same bit set as Tile.mask)
    mask: u64,
    /// allowed[t] for each of the planet's tiles when the entity has a
    /// tile_restriction; null = any tile
    allowed: ?[]const bool,
    /// index into planet.resources for resources
    resource: ?u8,

    pub fn canStandOn(self: *const Entity, tile_index: usize, tile: *const Tile) bool {
        if (self.mask & tile.mask != 0) return false;
        if (self.allowed) |al| return al[tile_index];
        return true;
    }
};

pub const Prop = struct { key: []const u8, value: Body };

pub const Planet = struct {
    name: []const u8,
    /// surface seed = map seed + seed_offset (crc32 of the planet name; 0 for
    /// the map's own first surface)
    seed_offset: u32,
    /// map_gen_settings.property_expression_names: any reference to `key` is
    /// replaced by `value` (a named expression or a literal number)
    props: []const Prop,
    controls: []const []const u8,
    /// autoplaced ground tiles in prototype order (ties go to the first)
    tiles: []const Tile,
    entities: []const []const u8,
    /// resource entities in placement order (autoplace order, then name)
    resources: []const Resource,
    /// every autoplaced entity (resources, rocks, trees, enemies, fish),
    /// sorted by autoplace order: entities sharing an order form one
    /// placement group, and groups are placed in this sequence
    placed: []const Entity,
    cliff_richness: f64,
    cliff_elevation_0: f64,
    cliff_elevation_interval: f64,

    pub fn prop(self: *const Planet, key: []const u8) ?Body {
        for (self.props) |p| {
            if (std.mem.eql(u8, p.key, key)) return p.value;
        }
        return null;
    }

    pub fn surfaceSeed(self: *const Planet, map_seed: u32) u32 {
        return map_seed +% self.seed_offset;
    }
};

pub const LoadError = error{ OutOfMemory, BadData, InvalidJson };

pub const Data = struct {
    arena: std.mem.Allocator,
    defs: std.StringHashMapUnmanaged(*Def) = .empty,
    planets: []Planet = &.{},
    game_version: []const u8 = "",

    pub fn planet(self: *const Data, name: []const u8) ?*const Planet {
        for (self.planets) |*p| {
            if (std.mem.eql(u8, p.name, name)) return p;
        }
        return null;
    }

    pub fn def(self: *const Data, name: []const u8) ?*Def {
        return self.defs.get(name);
    }
};

fn body(v: json.Value) LoadError!Body {
    return switch (v) {
        .string => |s| .{ .src = s },
        .number => |n| .{ .num = n },
        .boolean => |b| .{ .num = if (b) 1 else 0 },
        else => error.BadData,
    };
}

fn obj(o: json.Object, key: []const u8) ?json.Object {
    const v = json.get(o, key) orelse return null;
    return if (v == .object) v.object else null;
}

fn num(o: json.Object, key: []const u8, default: f64) f64 {
    const v = json.get(o, key) orelse return default;
    return if (v == .number) v.number else default;
}

fn strings(a: std.mem.Allocator, o: json.Object, key: []const u8) LoadError![]const []const u8 {
    var out: std.ArrayList([]const u8) = .empty;
    if (json.get(o, key)) |v| {
        if (v == .array) for (v.array) |e| {
            if (e == .string) try out.append(a, e.string);
        };
    }
    return out.items;
}

/// Collision layer names -> bits, shared by tiles and entities of one load.
const Layers = struct {
    names: [64][]const u8 = undefined,
    n: usize = 0,

    fn mask(self: *Layers, o: json.Object) u64 {
        var m: u64 = 0;
        const v = json.get(o, "layers") orelse return 0;
        if (v != .array) return 0;
        for (v.array) |e| {
            if (e != .string) continue;
            var bit: ?usize = null;
            for (self.names[0..self.n], 0..) |nm, i| {
                if (std.mem.eql(u8, nm, e.string)) bit = i;
            }
            if (bit == null and self.n < 64) {
                self.names[self.n] = e.string;
                bit = self.n;
                self.n += 1;
            }
            if (bit) |b| m |= @as(u64, 1) << @intCast(b);
        }
        return m;
    }
};

fn hasLayer(o: json.Object, name: []const u8) bool {
    const v = json.get(o, "layers") orelse return false;
    if (v != .array) return false;
    for (v.array) |e| {
        if (e == .string and std.mem.eql(u8, e.string, name)) return true;
    }
    return false;
}

fn color(o: json.Object) [3]u8 {
    var col: [3]u8 = .{ 0, 0, 0 };
    if (json.get(o, "color")) |cv| {
        if (cv == .array and cv.array.len >= 3) {
            for (0..3) |i| col[i] = @intFromFloat(cv.array[i].number);
        }
    }
    return col;
}

fn parseDef(a: std.mem.Allocator, name: []const u8, o: json.Object, is_function: bool) LoadError!Def {
    var locals: std.ArrayList(Local) = .empty;
    if (obj(o, "local_expressions")) |lo| {
        for (lo) |kv| try locals.append(a, .{ .name = kv.key, .body = try body(kv.value) });
    }
    var fns: std.ArrayList(Def) = .empty;
    if (obj(o, "local_functions")) |lf| {
        for (lf) |kv| {
            if (kv.value == .object) try fns.append(a, try parseDef(a, kv.key, kv.value.object, true));
        }
    }
    return .{
        .name = name,
        .is_function = is_function,
        .params = try strings(a, o, "parameters"),
        .body = try body(json.get(o, "expression") orelse return error.BadData),
        .locals = locals.items,
        .local_fns = fns.items,
    };
}

/// Parse the embedded data file. `arena` must outlive every program compiled
/// from the result (definitions cache their parsed trees in it).
pub fn load(arena: std.mem.Allocator) LoadError!Data {
    return loadFrom(arena, embedded);
}

/// Parse a data file produced by scripts/sa-build-data.py (any mod set).
pub fn loadFrom(arena: std.mem.Allocator, text: []const u8) LoadError!Data {
    const root = try json.parse(arena, text);
    if (root != .object) return error.BadData;
    const ro = root.object;
    var d = Data{ .arena = arena };
    if (json.get(ro, "game_version")) |v| {
        if (v == .string) d.game_version = v.string;
    }

    inline for (.{ .{ "expressions", false }, .{ "functions", true } }) |spec| {
        const section = obj(ro, spec[0]) orelse return error.BadData;
        for (section) |kv| {
            if (kv.value != .object) continue;
            const def = try arena.create(Def);
            def.* = try parseDef(arena, kv.key, kv.value.object, spec[1]);
            try d.defs.put(arena, kv.key, def);
        }
    }

    const tile_meta = obj(ro, "tiles") orelse return error.BadData;
    const entity_meta = obj(ro, "entities") orelse return error.BadData;
    const planets = obj(ro, "planets") orelse return error.BadData;
    var list: std.ArrayList(Planet) = .empty;
    var layers = Layers{};
    for (planets) |kv| {
        if (kv.value != .object) continue;
        const po = kv.value.object;
        var props: std.ArrayList(Prop) = .empty;
        if (obj(po, "property_expression_names")) |pen| {
            for (pen) |p| try props.append(arena, .{ .key = p.key, .value = try body(p.value) });
        }
        var tiles: std.ArrayList(Tile) = .empty;
        for (try strings(arena, po, "tiles")) |tn| {
            const tm = obj(tile_meta, tn) orelse return error.BadData;
            try tiles.append(arena, .{ .name = tn, .layer = @intFromFloat(num(tm, "layer", 0)), .color = color(tm), .mask = layers.mask(tm), .blocks_resource = hasLayer(tm, "resource") });
        }
        var resources: std.ArrayList(Resource) = .empty;
        for (try strings(arena, po, "resources")) |rn| {
            const em = obj(entity_meta, rn) orelse return error.BadData;
            const order = if (json.get(em, "order")) |v| (if (v == .string) v.string else "") else "";
            try resources.append(arena, .{ .name = rn, .order = order, .color = color(em), .size = @intFromFloat(num(em, "size", 1)) });
        }
        var placed: std.ArrayList(Entity) = .empty;
        for (try strings(arena, po, "entities")) |en| {
            const em = obj(entity_meta, en) orelse continue;
            const order = if (json.get(em, "order")) |v| (if (v == .string) v.string else "") else "";
            const typ = if (json.get(em, "type")) |v| (if (v == .string) v.string else "") else "";
            var allowed: ?[]bool = null;
            if (json.get(em, "tile_restriction")) |rv| {
                if (rv == .array) {
                    const al = try arena.alloc(bool, tiles.items.len);
                    @memset(al, false);
                    for (rv.array) |tv| {
                        if (tv != .string) continue;
                        for (tiles.items, 0..) |t, ti| {
                            if (std.mem.eql(u8, t.name, tv.string)) al[ti] = true;
                        }
                    }
                    allowed = al;
                }
            }
            var res_index: ?u8 = null;
            for (resources.items, 0..) |r, ri| {
                if (std.mem.eql(u8, r.name, en)) res_index = @intCast(ri);
            }
            try placed.append(arena, .{
                .name = en,
                .order = order,
                .kind = if (std.mem.eql(u8, typ, "resource")) .resource else if (std.mem.eql(u8, typ, "fish")) .water else .land,
                .mask = layers.mask(em),
                .allowed = allowed,
                .resource = res_index,
            });
        }
        std.mem.sort(Entity, placed.items, {}, struct {
            fn lt(_: void, l: Entity, r: Entity) bool {
                return std.mem.order(u8, l.order, r.order) == .lt;
            }
        }.lt);
        const cliff = obj(po, "cliff_settings") orelse &.{};
        try list.append(arena, .{
            .name = kv.key,
            .seed_offset = @intFromFloat(num(po, "seed_offset", 0)),
            .props = props.items,
            .controls = try strings(arena, po, "autoplace_controls"),
            .tiles = tiles.items,
            .entities = try strings(arena, po, "entities"),
            .resources = resources.items,
            .placed = placed.items,
            .cliff_richness = num(cliff, "richness", 1),
            .cliff_elevation_0 = num(cliff, "cliff_elevation_0", 10),
            .cliff_elevation_interval = num(cliff, "cliff_elevation_interval", 40),
        });
    }
    d.planets = list.items;
    return d;
}
