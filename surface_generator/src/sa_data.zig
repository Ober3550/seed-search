//! Loader for the Space-Age surface data: parses the embedded per-planet
//! closure JSON files (see sa_embedded.zig — regenerated from
//! sa-data/surfaces/*.json by scripts/gen-sa-embed.mjs) into sa_expr node
//! trees, and attaches each planet's map-gen property-name mapping +
//! autoplace controls (from the embedded planets.json).
//!
//! Each surface file is self-contained for its property-expression roots:
//! `expressions` (parameterless noise expressions incl. the roots), `functions`
//! (parameterized helpers with locals), `property_expressions` (names the
//! planet's map_gen_settings.property_expression_names point at). Runtime
//! inputs (control:…, x/y/map_seed, x_from_start/…) are resolved by the
//! evaluator at eval time.

const std = @import("std");
const builtin = @import("builtin");
const json = @import("sa_json.zig");
const expr = @import("sa_expr.zig");
const embedded = @import("sa_embedded.zig");

pub const PlanetName = enum {
    vulcanus,
    fulgora,
    gleba,
    aquilo,
    nauvis,

    pub fn json(self: PlanetName) []const u8 {
        return switch (self) {
            .vulcanus => embedded.vulcanus,
            .fulgora => embedded.fulgora,
            .gleba => embedded.gleba,
            .aquilo => embedded.aquilo,
            .nauvis => embedded.nauvis,
        };
    }

    pub fn asStr(self: PlanetName) []const u8 {
        return @tagName(self);
    }
};

/// One autoplaced tile of a planet's ground competition.
pub const Tile = struct {
    name: []const u8,
    layer: i32,
    color: [3]u8,
};

/// A planet's parsed surface closure + its property/control wiring.
pub const Planet = struct {
    name: PlanetName,
    closure: expr.Closure,
    /// autoplaced ground tiles (name = closure entry whose expression is the
    /// tile's probability_expression; winner = highest value, argmax)
    tiles: []Tile,
    /// map_gen_settings.property_expression_names: property key (e.g.
    /// "elevation", "entity:iron-ore:probability") → closure entry name.
    properties: []const Property,
    /// autoplace controls that have explicit entries (empty = defaults).
    controls: []const []const u8,
    arena: std.mem.Allocator,

    pub const Property = struct { key: []const u8, entry: []const u8 };

    pub fn prop(self: *const Planet, key: []const u8) ?[]const u8 {
        for (self.properties) |p| {
            if (std.mem.eql(u8, p.key, key)) return p.entry;
        }
        return null;
    }
};

pub const LoadError = error{ OutOfMemory, BadData, InvalidJson };

fn objString(o: json.Object, key: []const u8) ?[]const u8 {
    const v = json.get(o, key) orelse return null;
    if (v != .string) return null;
    return v.string;
}

fn objObj(o: json.Object, key: []const u8) ?json.Object {
    const v = json.get(o, key) orelse return null;
    if (v != .object) return null;
    return v.object;
}

fn objArr(o: json.Object, key: []const u8) ?[]const json.Value {
    const v = json.get(o, key) orelse return null;
    if (v != .array) return null;
    return v.array;
}

pub fn load(arena: std.mem.Allocator, name: PlanetName) LoadError!Planet {
    const root = try json.parse(arena, name.json());
    if (root != .object) return error.BadData;
    const rootObj = root.object;

    var entries: std.ArrayList(expr.Closure.Entry) = .empty;
    const exprs = objObj(rootObj, "expressions") orelse return error.BadData;
    const funcs = objObj(rootObj, "functions");
    var seq: u32 = 0;
    try collect(arena, exprs, false, &entries, &seq);
    if (funcs) |f| try collect(arena, f, true, &entries, &seq);
    const node_count: usize = seq;

    // autoplaced tile competition metadata (closure entries share the tile
    // names, so evalRootMemoed can evaluate each tile's probability)
    var tiles: std.ArrayList(Tile) = .empty;
    if (objArr(rootObj, "tiles")) |tl| {
        for (tl) |v| {
            if (v != .object) continue;
            const to = v.object;
            const nm = objString(to, "name") orelse continue;
            const lay = if (json.get(to, "layer")) |lv| (if (lv == .number) @as(i32, @intFromFloat(lv.number)) else 0) else 0;
            var col: [3]u8 = .{ 0, 0, 0 };
            if (objArr(to, "color")) |cv| {
                if (cv.len >= 3 and cv[0] == .number and cv[1] == .number and cv[2] == .number) {
                    col = .{ @intFromFloat(cv[0].number), @intFromFloat(cv[1].number), @intFromFloat(cv[2].number) };
                }
            }
            try tiles.append(arena, .{ .name = nm, .layer = lay, .color = col });
        }
    }

    // property-expression roots: list of entry names
    var properties: std.ArrayList(Planet.Property) = .empty;
    if (objArr(rootObj, "property_expressions")) |pl| {
        for (pl) |v| {
            if (v == .string) try properties.append(arena, .{ .key = v.string, .entry = v.string });
        }
    }
    // autoplace controls + the mgs property-name mapping come from planets.json
    var controls: std.ArrayList([]const u8) = .empty;
    try wirePlanetMeta(arena, name, &properties, &controls);

    return .{
        .name = name,
        .closure = .{ .a = arena, .entries = entries.items, .node_count = node_count },
        .tiles = tiles.items,
        .properties = properties.items,
        .controls = controls.items,
        .arena = arena,
    };
}

fn wirePlanetMeta(arena: std.mem.Allocator, name: PlanetName, props: *std.ArrayList(Planet.Property), controls: *std.ArrayList([]const u8)) LoadError!void {
    const root = try json.parse(arena, embedded.planets);
    if (root != .object) return error.BadData;
    const entry = json.get(root.object, name.asStr()) orelse return;
    if (entry != .object) return;
    // property_expression_names / autoplace_controls sit directly on the
    // planet entry in the embedded planets.json (no map_gen_settings wrapper)
    const mgs = entry.object;
    if (objObj(mgs, "property_expression_names")) |pen| {
        for (pen) |kv| {
            if (kv.value == .string) try props.append(arena, .{ .key = kv.key, .entry = kv.value.string });
        }
    }
    // autoplace_controls keys
    if (objObj(mgs, "autoplace_controls")) |ac| {
        for (ac) |kv| try controls.append(arena, kv.key);
    }
}

fn collect(arena: std.mem.Allocator, obj: json.Object, is_function: bool, out: *std.ArrayList(expr.Closure.Entry), seq: *u32) LoadError!void {
    for (obj) |kv| {
        if (kv.value != .object) continue;
        const o = kv.value.object;
        const bodyVal = json.get(o, "expression") orelse continue;

        var params: std.ArrayList([]const u8) = .empty;
        if (json.get(o, "parameters")) |pv| {
            if (pv == .array) {
                for (pv.array) |p| {
                    if (p == .string) try params.append(arena, p.string);
                }
            }
        }
        var locals: std.ArrayList(expr.Closure.Local) = .empty;
        if (json.get(o, "local_expressions")) |lv| {
            if (lv == .object) {
                for (lv.object) |loc| {
                    const locNode = parseBody(arena, loc.value) catch |e| {
                        if (builtin.os.tag != .freestanding) {
                            std.debug.print("local parse fail {s}.{s} ({s})\n", .{ kv.key, loc.key, @errorName(e) });
                        }
                        return error.BadData;
                    };
                    try locals.append(arena, .{ .name = loc.key, .node = locNode });
                }
            }
        }
        const rootNode = parseBody(arena, bodyVal) catch |e| {
            if (builtin.os.tag != .freestanding) {
                std.debug.print("parse fail {s} ({s}): len {d}\n", .{ kv.key, @errorName(e), bodyVal.string.len });
                std.debug.print("  expr: {s}\n", .{bodyVal.string});
            }
            return error.BadData;
        };
        try out.append(arena, .{
            .name = kv.key,
            .is_function = is_function or params.items.len > 0,
            .params = params.items,
            .locals = locals.items,
            .root = rootNode,
        });
    }
    // unique node ids across the whole closure (memoization keys), and
    // precompute the local name/node tables for stackless binding.
    for (out.items) |*e| {
        expr.renumber(e.root, seq);
        var names: std.ArrayList([]const u8) = .empty;
        var nodes: std.ArrayList(*expr.Node) = .empty;
        for (e.locals) |loc| {
            expr.renumber(loc.node, seq);
            try names.append(arena, loc.name);
            try nodes.append(arena, loc.node);
        }
        e.loc_names = names.items;
        e.loc_nodes = nodes.items;
    }
}
fn parseExprOr(arena: std.mem.Allocator, body: ?[]const u8) error{OutOfMemory}!*expr.Node {
    if (body) |b| return expr.parseExpr(arena, b) catch return error.OutOfMemory;
    return expr.makeLit(arena, 0);
}

fn parseBody(arena: std.mem.Allocator, v: json.Value) (error{ ParseError, OutOfMemory } || expr.ParseError)!*expr.Node {
    switch (v) {
        .string => |s| return expr.parseExpr(arena, s),
        .number => |n| return expr.makeLit(arena, n),
        else => return error.ParseError,
    }
}
