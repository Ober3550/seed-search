//! Filter DSL evaluator for seedgen.
//!
//! The frontend ships a single JSON filter document as the `FILTER` env var,
//! in the Filter DSL (docs/filter-dsl-reference.md). `Filter.parse` builds an
//! owned `Node` tree ONCE (allocated into the caller's arena); the per-seed hot
//! loop then calls `eval` with no allocation.

const std = @import("std");
const gen = @import("gen.zig");
const data = @import("data.zig");

/// How many surfaces the per-pass cache can hold before falling back to on-the-
/// fly recompute (which is still lazy — only computed when a predicate asks).
pub const MAX_SURFS = 1024;

/// Name of the key that carries a filter's own sub-filters when the element is a
/// plain `{ "count": ... }`-style object — not used directly; kept for clarity.
const internal = struct {};

// ---------------------------------------------------------------------------
// Parsed filter tree
// ---------------------------------------------------------------------------

/// Value comparison operators.
const CmpOp = enum { ge, le, eq, gt, lt };

/// A comparison bound: numeric, an ordered-enum label, or a string label.
const Bound = union(enum) {
    num: f64,
    label: []const u8,
};

const Cmp = struct { op: CmpOp, bound: Bound };

/// Surface property enum fields that order, plus kind mapping.
const OrderEnum = enum { water, enemy, cliff };
const orderRank = struct {
    fn waterRank(s: []const u8) ?i64 {
        if (std.mem.eql(u8, s, "none")) return 0;
        if (std.mem.eql(u8, s, "low")) return 1;
        if (std.mem.eql(u8, s, "med")) return 2;
        if (std.mem.eql(u8, s, "high")) return 3;
        if (std.mem.eql(u8, s, "max")) return 4;
        return null;
    }
    fn enemyRank(s: []const u8) ?i64 {
        if (std.mem.eql(u8, s, "none")) return 0;
        if (std.mem.eql(u8, s, "very_low")) return 1;
        if (std.mem.eql(u8, s, "low")) return 2;
        if (std.mem.eql(u8, s, "med")) return 3;
        if (std.mem.eql(u8, s, "high")) return 4;
        if (std.mem.eql(u8, s, "very_high")) return 5;
        if (std.mem.eql(u8, s, "max")) return 6;
        return null;
    }
};

/// Surface properties the DSL can test.
const Prop = union(enum) {
    type_kind,
    star_system,
    radius,
    delta_v,
    water,
    enemy,
    cliff,
    /// A resource's FSR score, by resource-index into `resource_order`.
    resource: u8,
};

/// Value filters that can nest (`>=`, `<=`, `==`, `>`, `<`, `&&`, `||`, `!`).
const ValueNode = union(enum) {
    cmp: Cmp,
    boolean: struct { all: bool, children: []const ValueNode },
    not: *const ValueNode,
};

/// Surface filters: a single property predicate or a boolean over surface
/// filters.
const SurfaceNode = union(enum) {
    prop: struct { prop: Prop, vf: *const ValueNode },
    boolean: struct { all: bool, children: []const SurfaceNode },
    not: *const SurfaceNode,
};

/// A seed filter: an aggregate or a boolean over seed filters.
const Node = union(enum) {
    count: struct { of: *const SurfaceNode, is: *const ValueNode },
    fraction: struct { of: *const SurfaceNode, matching: *const SurfaceNode, is: *const ValueNode },
    boolean: struct { all: bool, children: []const Node },
    not: *const Node,
};

// ---------------------------------------------------------------------------
// Parsing
// ---------------------------------------------------------------------------

pub const ParseError = error{
    ExpectedObject,
    ExpectedArray,
    ExpectedString,
    ExpectedNumber,
    InvalidNumber,
    InvalidBound,
    UnknownOperator,
    UnknownProperty,
    MissingOf,
    MissingMatching,
    MissingIs,
    AggregateAtWrongKind,
    PropAtWrongKind,
    ValueOpAtWrongKind,
    DuplicateOperator,
    MultiplePropsNoAnd,
    MixedOperatorAndProp,
    OutOfMemory,
};

fn isOperator(c: u8) bool {
    return !(c >= 'a' and c <= 'z') and !(c >= 'A' and c <= 'Z');
}

fn expectBound(bound: *Bound, v: std.json.Value) ParseError!void {
    switch (v) {
        .integer => |i| { bound.* = .{ .num = @floatFromInt(i) }; },
        .float => |f| { bound.* = .{ .num = f }; },
        .number_string => |s| {
            bound.* = .{ .num = std.fmt.parseFloat(f64, s) catch return error.InvalidNumber };
        },
        .bool => |b| { bound.* = .{ .num = if (b) 1.0 else 0.0 }; },
        .string => |s| { bound.* = .{ .label = s }; },
        else => return error.InvalidBound,
    }
}

fn parseCmpOp(key: []const u8) ?CmpOp {
    if (std.mem.eql(u8, key, ">=")) return .ge;
    if (std.mem.eql(u8, key, "<=")) return .le;
    if (std.mem.eql(u8, key, "==")) return .eq;
    if (std.mem.eql(u8, key, ">")) return .gt;
    if (std.mem.eql(u8, key, "<")) return .lt;
    return null;
}

/// Turn a `"water": "low"`-style label key into a rank bound for ordered enums.
fn orderBound(prop: Prop, s: []const u8) ?f64 {
    return switch (prop) {
        .water => @floatFromInt(orderRank.waterRank(s) orelse return null),
        .enemy => @floatFromInt(orderRank.enemyRank(s) orelse return null),
        .cliff => @floatFromInt(orderRank.waterRank(s) orelse return null), // cliff uses same 5 tiers
        else => null,
    };
}

fn parseValue(alloc: std.mem.Allocator, v: std.json.Value) ParseError!*const ValueNode {
    const node = try alloc.create(ValueNode);
    node.* = try parseValueInto(alloc, v);
    return node;
}

fn parseValueInto(alloc: std.mem.Allocator, v: std.json.Value) ParseError!ValueNode {
    switch (v) {
        .object => |obj| {
            // A value object is a boolean combination, or a comparison op.
            var op_key: ?[]const u8 = null;
            var iter = obj.iterator();
            while (iter.next()) |kv| {
                const k = kv.key_ptr.*;
                if (isOperator(k[0])) {
                    if (op_key != null) return error.DuplicateOperator;
                    op_key = k;
                } else return error.ValueOpAtWrongKind;
            }
            const k = op_key orelse return error.ExpectedObject;
            const val = obj.get(k).?;
            if (std.mem.eql(u8, k, "&&") or std.mem.eql(u8, k, "||")) {
                const all = std.mem.eql(u8, k, "&&");
                const arr = switch (val) {
                    .array => |a| a,
                    else => return error.ExpectedArray,
                };
                const children = try alloc.alloc(ValueNode, arr.items.len);
                for (arr.items, 0..) |item, i| {
                    children[i] = try parseValueInto(alloc, item);
                }
                return .{ .boolean = .{ .all = all, .children = children } };
            }
            if (std.mem.eql(u8, k, "!")) {
                const child = try parseValue(alloc, val);
                return .{ .not = child };
            }
            if (parseCmpOp(k)) |op| {
                var bound: Bound = undefined;
                try expectBound(&bound, val);
                return .{ .cmp = .{ .op = op, .bound = bound } };
            }
            return error.UnknownOperator;
        },
        else => return error.ExpectedObject,
    }
}

fn parsePropKey(key: []const u8) ParseError!Prop {
    // Fixed surface properties first.
    if (std.mem.eql(u8, key, "type")) return .type_kind;
    if (std.mem.eql(u8, key, "starSystem")) return .star_system;
    if (std.mem.eql(u8, key, "radius")) return .radius;
    if (std.mem.eql(u8, key, "deltaV")) return .delta_v;
    if (std.mem.eql(u8, key, "water")) return .water;
    if (std.mem.eql(u8, key, "enemy")) return .enemy;
    if (std.mem.eql(u8, key, "cliff")) return .cliff;
    // Otherwise it must be a resource name (camelCase output names).
    for (gen.resource_order, 0..) |_, i| {
        if (std.mem.eql(u8, gen.resource_name_output[i], key)) {
            return .{ .resource = @intCast(i) };
        }
    }
    return error.UnknownProperty;
}

fn parseSurface(alloc: std.mem.Allocator, v: std.json.Value) ParseError!*const SurfaceNode {
    const node = try alloc.create(SurfaceNode);
    node.* = try parseSurfaceInto(alloc, v);
    return node;
}

fn parseSurfaceInto(alloc: std.mem.Allocator, v: std.json.Value) ParseError!SurfaceNode {
    switch (v) {
        .object => |obj| {
            var op_key: ?[]const u8 = null;
            var prop_key: ?[]const u8 = null;
            var iter = obj.iterator();
            while (iter.next()) |kv| {
                const k = kv.key_ptr.*;
                if (isOperator(k[0])) {
                    if (op_key != null) return error.DuplicateOperator;
                    op_key = k;
                } else {
                    if (prop_key != null) return error.MultiplePropsNoAnd;
                    prop_key = k;
                }
            }
            if (op_key != null and prop_key != null) return error.MixedOperatorAndProp;
            if (op_key != null) {
                const k = op_key.?;
                const val = obj.get(k).?;
                if (std.mem.eql(u8, k, "&&") or std.mem.eql(u8, k, "||")) {
                    const all = std.mem.eql(u8, k, "&&");
                    const arr = switch (val) {
                        .array => |a| a,
                        else => return error.ExpectedArray,
                    };
                    const children = try alloc.alloc(SurfaceNode, arr.items.len);
                    for (arr.items, 0..) |item, i| {
                        children[i] = try parseSurfaceInto(alloc, item);
                    }
                    return .{ .boolean = .{ .all = all, .children = children } };
                }
                if (std.mem.eql(u8, k, "!")) {
                    const child = try parseSurface(alloc, val);
                    return .{ .not = child };
                }
                return error.UnknownOperator;
            }
            if (prop_key != null) {
                const k = prop_key.?;
                const val = obj.get(k).?;
                const prop = try parsePropKey(k);
                const vf = try parseValue(alloc, val);
                return .{ .prop = .{ .prop = prop, .vf = vf } };
            }
            // Empty object `{}` → vacuous true.
            const e = try alloc.alloc(SurfaceNode, 0);
            return .{ .boolean = .{ .all = true, .children = e } };
        },
        else => return error.ExpectedObject,
    }
}

fn parseSeed(alloc: std.mem.Allocator, v: std.json.Value) ParseError!Node {
    const r = try parseSeedInner(alloc, v);
    return r;
}
fn parseSeedInner(alloc: std.mem.Allocator, v: std.json.Value) ParseError!Node {
    switch (v) {
        .object => |obj| {
            if (obj.count() == 0) {
                const e = try alloc.alloc(Node, 0);
                return .{ .boolean = .{ .all = true, .children = e } };
            }
            // Must be exactly one operator key (a seed filter is not a property).
            var op_key: ?[]const u8 = null;
            var iter = obj.iterator();
            while (iter.next()) |kv| {
                const k = kv.key_ptr.*;
                if (isOperator(k[0])) {
                    if (op_key != null) return error.DuplicateOperator;
                    op_key = k;
                } else return error.PropAtWrongKind;
            }
            const k = op_key orelse return error.ExpectedObject;
            const val = obj.get(k).?;
            if (std.mem.eql(u8, k, "&&") or std.mem.eql(u8, k, "||")) {
                const all = std.mem.eql(u8, k, "&&");
                const arr = switch (val) {
                    .array => |a| a,
                    else => return error.ExpectedArray,
                };
                const children = try alloc.alloc(Node, arr.items.len);
                for (arr.items, 0..) |item, i| {
                    children[i] = try parseSeed(alloc, item);
                }
                return .{ .boolean = .{ .all = all, .children = children } };
            }
            if (std.mem.eql(u8, k, "!")) {
                const child = try alloc.create(Node);
                child.* = try parseSeed(alloc, val);
                return .{ .not = child };
            }
            if (std.mem.eql(u8, k, "$count") or std.mem.eql(u8, k, "$fraction")) {
                const ov = switch (val) {
                    .object => |o| o,
                    else => return error.ExpectedObject,
                };
                const of = try parseSurface(alloc, ov.get("of") orelse return error.MissingOf);
                const is = try parseValue(alloc, ov.get("is") orelse return error.MissingIs);
                if (std.mem.eql(u8, k, "$count")) {
                    return .{ .count = .{ .of = of, .is = is } };
                }
                const matching = try parseSurface(alloc, ov.get("matching") orelse return error.MissingMatching);
                return .{ .fraction = .{ .of = of, .matching = matching, .is = is } };
            }
            return error.UnknownOperator;
        },
        else => return error.ExpectedObject,
    }
}

// ---------------------------------------------------------------------------
// Evaluation
// ---------------------------------------------------------------------------

pub const EvalInput = struct {
    zones: []const gen.Zone,
    body_map: ?std.StringHashMapUnmanaged(data.Body),
    primaries: std.StringHashMap([]const u8),
    field_primaries: std.StringHashMap([]const u8),
    calidus_zi: usize,
    zone_end: usize,
    tail_start: usize,
    nauvis_sgw: f64,
    nauvis_pgw: f64,
    cx: f64,
    cy: f64,
};

const Tags = gen.Tags;

/// Per-pass lazy cache for tags/deltaV/resource-FSR. Fixed-size; older indices
/// fall back to recompute-on-demand. Caller owns this on the stack.
pub const SurfaceCache = struct {
    tags: [MAX_SURFS]Tags = undefined,
    tags_valid: [MAX_SURFS]bool = [_]bool{false} ** MAX_SURFS,
    dv: [MAX_SURFS]u32 = [_]u32{0} ** MAX_SURFS,
    dv_valid: [MAX_SURFS]bool = [_]bool{false} ** MAX_SURFS,
    res: [MAX_SURFS][18]f64 = undefined,
    res_valid: [MAX_SURFS]bool = [_]bool{false} ** MAX_SURFS,

    fn reset(self: *SurfaceCache, n: usize) void {
        const m = @min(n, MAX_SURFS);
        @memset(self.tags_valid[0..m], false);
        @memset(self.dv_valid[0..m], false);
        @memset(self.res_valid[0..m], false);
    }
};

pub const Filter = struct {
    root: Node,

    /// Parse `json` once. All tree nodes are allocated into `alloc`, which the
    /// caller keeps alive for the whole run. `Filter` itself is a plain value
    /// (the tree lives in `alloc`, not inside the Filter) — trivially copyable.
    pub fn parse(alloc: std.mem.Allocator, json: []const u8) ParseError!Filter {
        const value = std.json.parseFromSliceLeaky(std.json.Value, alloc, json, .{}) catch return error.ExpectedObject;
        const root = try parseSeed(alloc, value);
        return .{ .root = root };
    }

    /// Evaluate the filter for one seed. No allocation.
    pub fn eval(self: *const Filter, in: *const EvalInput, cache: *SurfaceCache) bool {
        cache.reset(in.zones.len);
        const r = evalSeed(&self.root, in, cache);
        return r;
    }
};

fn isSurface(z: gen.Zone) bool {
    return z.ztype == .planet or z.ztype == .moon or z.ztype == .@"asteroid-field";
}

fn starSystem(in: *const EvalInput, si: usize) []const u8 {
    const in_calidus = (si >= in.calidus_zi and si < in.zone_end) or si >= in.tail_start;
    return if (in_calidus) "Calidus" else "other";
}

fn dslTypeStr(z: gen.Zone) []const u8 {
    return switch (z.ztype) {
        .planet => "planet",
        .moon => "moon",
        .star => "star",
        .@"asteroid-field" => "asteroidField",
        else => "surface",
    };
}

fn zoneStellar(in: *const EvalInput, z: gen.Zone) struct { x: f64, y: f64 } {
    if (z.ztype == .@"asteroid-field") return .{ .x = z.stellar_x, .y = z.stellar_y };
    var p = z.parent_index;
    while (p >= 0 and z.ztype != .star and @as(usize, @intCast(p)) < in.zones.len) {
        if (in.zones[@intCast(p)].ztype == .star) break;
        p = in.zones[@intCast(p)].parent_index;
    }
    if (p >= 0) return .{ .x = in.zones[@intCast(p)].stellar_x, .y = in.zones[@intCast(p)].stellar_y };
    return .{ .x = z.stellar_x, .y = z.stellar_y };
}

fn deltaVFromNauvis(in: *const EvalInput, z: gen.Zone) f64 {
    const sp = zoneStellar(in, z);
    if (sp.x == in.cx and sp.y == in.cy) {
        if (@abs(z.star_gravity_well - in.nauvis_sgw) < 0.01)
            return 100.0 * @abs(z.planet_gravity_well - in.nauvis_pgw)
        else
            return 500.0 * @abs(z.star_gravity_well - in.nauvis_sgw) + 100.0 * in.nauvis_pgw + 100.0 * z.planet_gravity_well;
    }
    const dist = @sqrt((sp.x - in.cx) * (sp.x - in.cx) + (sp.y - in.cy) * (sp.y - in.cy));
    return 400.0 * dist + 500.0 * (in.nauvis_sgw + z.star_gravity_well) + 100.0 * (in.nauvis_pgw + z.planet_gravity_well);
}

fn getTags(in: *const EvalInput, cache: *SurfaceCache, si: usize, z: gen.Zone) Tags {
    if (si < MAX_SURFS) {
        if (!cache.tags_valid[si]) {
            cache.tags[si] = gen.computeTags(z.seed, z.name, in.body_map);
            cache.tags_valid[si] = true;
        }
        return cache.tags[si];
    }
    return gen.computeTags(z.seed, z.name, in.body_map);
}

fn getDeltaV(in: *const EvalInput, cache: *SurfaceCache, si: usize, z: gen.Zone) u32 {
    if (si < MAX_SURFS) {
        if (!cache.dv_valid[si]) {
            cache.dv[si] = @intFromFloat(@round(deltaVFromNauvis(in, z)));
            cache.dv_valid[si] = true;
        }
        return cache.dv[si];
    }
    return @intFromFloat(@round(deltaVFromNauvis(in, z)));
}

fn getResource(out: *[18]f64, in: *const EvalInput, cache: *SurfaceCache, si: usize, z: gen.Zone) void {
    if (si < MAX_SURFS) {
        if (!cache.res_valid[si]) {
            const primary = in.primaries.get(z.name) orelse in.field_primaries.get(z.name);
            const tags = getTags(in, cache, si, z);
            cache.res[si] = gen.computeZoneResources(z.seed, z.ztype, primary, tags);
            cache.res_valid[si] = true;
        }
        out.* = cache.res[si];
        return;
    }
    const primary = in.primaries.get(z.name) orelse in.field_primaries.get(z.name);
    const tags = getTags(in, cache, si, z);
    out.* = gen.computeZoneResources(z.seed, z.ztype, primary, tags);
}

const SurfaceValue = union(enum) {
    num: f64,
    order: struct { kind: OrderEnum, rank: i64 },
    str: []const u8,
};

fn surfaceValue(prop: Prop, in: *const EvalInput, cache: *SurfaceCache, si: usize, z: gen.Zone) SurfaceValue {
    switch (prop) {
        .type_kind => return .{ .str = dslTypeStr(z) },
        .star_system => return .{ .str = starSystem(in, si) },
        .radius => return .{ .num = z.radius },
        .delta_v => return .{ .num = @floatFromInt(getDeltaV(in, cache, si, z)) },
        .water => {
            const tags = getTags(in, cache, si, z);
            return .{ .order = .{ .kind = .water, .rank = if (tags.water) |t| @intFromEnum(t) else 0 } };
        },
        .enemy => {
            const tags = getTags(in, cache, si, z);
            return .{ .order = .{ .kind = .enemy, .rank = if (tags.enemy) |t| @intFromEnum(t) else 0 } };
        },
        .cliff => {
            const tags = getTags(in, cache, si, z);
            return .{ .order = .{ .kind = .cliff, .rank = if (tags.cliff) |t| @intFromEnum(t) else 0 } };
        },
        .resource => |ri| {
            var res: [18]f64 = undefined;
            getResource(&res, in, cache, si, z);
            return .{ .num = res[ri] };
        },
    }
}

/// Compare a rank against an ordered-enum bound label.
fn orderCmp(kind: OrderEnum, op: CmpOp, value_rank: i64, bound: Bound) bool {
    const brank = switch (kind) {
        .water, .cliff => orderRank.waterRank(bound.label) orelse return false,
        .enemy => orderRank.enemyRank(bound.label) orelse return false,
    };
    return switch (op) {
        .ge => value_rank >= brank,
        .le => value_rank <= brank,
        .eq => value_rank == brank,
        .gt => value_rank > brank,
        .lt => value_rank < brank,
    };
}

fn evalValue(vf: *const ValueNode, sv: SurfaceValue) bool {
    return switch (vf.*) {
        .cmp => |c| switch (sv) {
            .num => |n| switch (c.bound) {
                .num => |b| switch (c.op) {
                    .ge => n >= b,
                    .le => n <= b,
                    .eq => n == b,
                    .gt => n > b,
                    .lt => n < b,
                },
                .label => false, // numeric vs label → no match
            },
            .str => |s| switch (c.bound) {
                .label => |lb| switch (c.op) {
                    .eq => std.mem.eql(u8, s, lb),
                    else => false,
                },
                .num => false,
            },
            .order => |o| switch (c.bound) {
                .label => orderCmp(o.kind, c.op, o.rank, c.bound),
                .num => false,
            },
        },
        .boolean => |b| {
            for (b.children) |ch| {
                if (b.all and !evalValue(&ch, sv)) return false;
                if (!b.all and evalValue(&ch, sv)) return true;
            }
            return b.all;
        },
        .not => |ch| !evalValue(ch, sv),
    };
}

fn evalSurface(node: *const SurfaceNode, in: *const EvalInput, cache: *SurfaceCache, si: usize, z: gen.Zone) bool {
    return switch (node.*) {
        .boolean => |b| {
            for (b.children) |ch| {
                if (b.all and !evalSurface(&ch, in, cache, si, z)) return false;
                if (!b.all and evalSurface(&ch, in, cache, si, z)) return true;
            }
            return b.all;
        },
        .not => |ch| !evalSurface(ch, in, cache, si, z),
        .prop => |p| {
            const sv = surfaceValue(p.prop, in, cache, si, z);
            return evalValue(p.vf, sv);
        },
    };
}

fn countSurfaces(of: *const SurfaceNode, in: *const EvalInput, cache: *SurfaceCache) u32 {
    var n: u32 = 0;
    for (in.zones, 0..) |z, si| {
        if (!isSurface(z)) continue;
        if (evalSurface(of, in, cache, si, z)) n += 1;
    }
    return n;
}

fn countIntersect(of: *const SurfaceNode, matching: *const SurfaceNode, in: *const EvalInput, cache: *SurfaceCache) u32 {
    var n: u32 = 0;
    for (in.zones, 0..) |z, si| {
        if (!isSurface(z)) continue;
        if (evalSurface(of, in, cache, si, z) and evalSurface(matching, in, cache, si, z)) n += 1;
    }
    return n;
}

fn evalSeed(node: *const Node, in: *const EvalInput, cache: *SurfaceCache) bool {
    return switch (node.*) {
        .boolean => |b| {
            for (b.children) |ch| {
                if (b.all and !evalSeed(&ch, in, cache)) return false;
                if (!b.all and evalSeed(&ch, in, cache)) return true;
            }
            return b.all;
        },
        .not => |ch| !evalSeed(ch, in, cache),
        .count => |c| {
            const n = countSurfaces(c.of, in, cache);
            const sv = SurfaceValue{ .num = @floatFromInt(n) };
            return evalValue(c.is, sv);
        },
        .fraction => |f| {
            const denom = countSurfaces(f.of, in, cache);
            if (denom == 0) return false;
            const numer = countIntersect(f.of, f.matching, in, cache);
            const ratio: f64 = @as(f64, @floatFromInt(numer)) / @as(f64, @floatFromInt(denom));
            return evalValue(f.is, SurfaceValue{ .num = ratio });
        },
    };
}
