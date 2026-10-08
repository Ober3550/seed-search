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
    /// the tile's collision mask has the "resource" layer (water, lava, ...)
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
    const root = try json.parse(arena, embedded);
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
            const blocks = if (json.get(tm, "blocks_resource")) |v| v == .boolean and v.boolean else false;
            try tiles.append(arena, .{ .name = tn, .layer = @intFromFloat(num(tm, "layer", 0)), .color = color(tm), .blocks_resource = blocks });
        }
        var resources: std.ArrayList(Resource) = .empty;
        for (try strings(arena, po, "resources")) |rn| {
            const em = obj(entity_meta, rn) orelse return error.BadData;
            const order = if (json.get(em, "order")) |v| (if (v == .string) v.string else "") else "";
            try resources.append(arena, .{ .name = rn, .order = order, .color = color(em), .size = @intFromFloat(num(em, "size", 1)) });
        }
        const cliff = obj(po, "cliff_settings") orelse &.{};
        try list.append(arena, .{
            .name = kv.key,
            .seed_offset = @intFromFloat(num(po, "seed_offset", 0)),
            .props = props.items,
            .controls = try strings(arena, po, "autoplace_controls"),
            .tiles = tiles.items,
            .entities = try strings(arena, po, "entities"),
            .resources = resources.items,
            .cliff_richness = num(cliff, "richness", 1),
            .cliff_elevation_0 = num(cliff, "cliff_elevation_0", 10),
            .cliff_elevation_interval = num(cliff, "cliff_elevation_interval", 40),
        });
    }
    d.planets = list.items;
    return d;
}
