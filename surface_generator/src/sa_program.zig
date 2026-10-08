//! Generic, data-driven noise program compiler + evaluator.
//!
//! Factorio compiles the noise expressions a surface needs into one
//! straight-line program and runs it over batches of positions. This module
//! does the same from the data in sa_data.zig:
//!
//!   compile   lower the requested root expressions (tile probabilities,
//!             properties, ...) into a DAG of primitive operations. Named
//!             expressions and function calls are inlined; identical
//!             sub-expressions are shared (hash-consing), so the elevation
//!             chain that every tile probability references is evaluated
//!             once; anything that only depends on the seed / controls is
//!             folded to a constant, which is also how noise-op parameters
//!             (seeds, octaves, grid sizes, ...) become prebuilt generators.
//!   evaluate  run the program over a column of positions (SoA, f32
//!             registers - the engine's arithmetic is f32).
//!
//! Nothing here knows about a particular planet. Scoping follows the data
//! stage: an expression/function sees its own parameters, local expressions
//! and local functions, then the surface's property_expression_names
//! overrides, the engine variables (x, y, map_seed, ...) and finally the
//! global named expressions.

const std = @import("std");
const builtin = @import("builtin");
const ast = @import("sa_expr.zig");
const sa_data = @import("sa_data.zig");
const noise = @import("noise.zig");
const rng = @import("rng.zig");

pub const VId = u32;
/// float type constant sub-expressions are folded in
const FOLD = f32;
const NONE: u32 = std.math.maxInt(u32);

pub const Tag = enum(u8) {
    konst,
    in_x,
    in_y,
    add,
    sub,
    mul,
    div,
    mod,
    pow,
    eq,
    ne,
    lt,
    gt,
    le,
    ge,
    and_,
    or_,
    bitand,
    min,
    max,
    hypot,
    neg,
    not_,
    abs,
    sin,
    cos,
    sqrt,
    floor,
    ceil,
    exp,
    log2,
    clamp,
    select,
    basis,
    multioctave,
    quick_multioctave,
    var_persistence,
    random_penalty,
    voronoi,
    terrace,
    spot,

    /// number of register inputs (a, b, c, d)
    fn arity(self: Tag) u3 {
        return switch (self) {
            .konst, .in_x, .in_y => 0,
            .neg, .not_, .abs, .sin, .cos, .sqrt, .floor, .ceil, .exp, .log2 => 1,
            .add, .sub, .mul, .div, .mod, .pow, .eq, .ne, .lt, .gt, .le, .ge, .and_, .or_, .bitand, .min, .max, .hypot => 2,
            .basis, .multioctave, .quick_multioctave, .voronoi, .terrace, .spot => 2,
            .clamp, .select, .var_persistence => 3,
            .random_penalty => 4,
        };
    }
};

pub const Inst = struct {
    tag: Tag,
    a: VId = 0,
    b: VId = 0,
    c: VId = 0,
    d: VId = 0,
    /// payload index; for .voronoi the output selector lives in the payload
    aux: u32 = 0,
    /// .konst: the value as f64 bits (kept exact so integer seeds survive;
    /// the runtime register holds it rounded to f32)
    k: u64 = 0,
};

pub const VoronoiOut = enum(u8) { spot, facet, pyramid, cell_id };

pub const Payload = union(enum) {
    basis: struct { gen: u32, is: f32, os: f32, ox: f32, oy: f32 },
    multi: struct { gen: u32, m: noise.exact.Multioctave },
    quick: struct { gens: u32, octaves: u32, is: f32, os: f32, oism: f32, oosm: f32, ox: f32, oy: f32 },
    varp: struct { gen: u32, v: noise.exact.VariablePersistence },
    randp: struct { seed: i32 },
    voronoi: struct { v: noise.VoronoiNoise, out: VoronoiOut },
    terrace: struct { offset: f32, width: f32 },
    spot: u32,
};

/// spot_noise configuration. The four sub-expressions are evaluated at the
/// candidate points of a region, not at the sampled position, so they are
/// compiled into their own program (`SpotOp.sub`).
pub const SpotCfg = struct {
    seed0: u32,
    seed1: u32,
    region_size: f64,
    point_count: u32,
    skip_span: u32,
    skip_offset: u32,
    spacing: f64,
    hard_target: bool,
    basement: f64,
    max_radius: f64,
};

pub const SpotOp = struct { cfg: SpotCfg, sub: Program };

/// control:<name>:<field> values (frequency/size/richness/bias).
pub const Controls = struct {
    ctx: *const anyopaque = undefined,
    lookup: *const fn (ctx: *const anyopaque, name: []const u8, field: []const u8) f64 = defaultControl,

    fn defaultControl(_: *const anyopaque, _: []const u8, field: []const u8) f64 {
        return if (std.mem.eql(u8, field, "bias")) 0.0 else 1.0;
    }
};

// ---------------------------------------------------------------------------
// Scalar semantics (shared by constant folding and the evaluator)
// ---------------------------------------------------------------------------

// The engine folds constants in double precision (NoiseExpressionConstant
// holds a double) and runs the per-position program in f32, so every scalar
// op exists for both types.

fn op1(comptime T: type, tag: Tag, a: T) T {
    return switch (tag) {
        .neg => -a,
        .not_ => if (a == 0) 1 else 0,
        .abs => @abs(a),
        .sin => @floatCast(@sin(@as(f64, a))),
        .cos => @floatCast(@cos(@as(f64, a))),
        .sqrt => @floatCast(@sqrt(@abs(@as(f64, a)))),
        .floor => @floor(a),
        .ceil => @ceil(a),
        .exp => @floatCast(@exp(@as(f64, a))),
        .log2 => @floatCast(@log2(@as(f64, a))),
        else => unreachable,
    };
}

fn op2(comptime T: type, tag: Tag, a: T, b: T) T {
    return switch (tag) {
        .add => a + b,
        .sub => a - b,
        .mul => a * b,
        .div => a / b,
        .mod => if (b == 0) std.math.nan(T) else @mod(a, b),
        .pow => blk: {
            if (b == 0.5) break :blk @sqrt(a);
            const m: f64 = std.math.pow(f64, @abs(@as(f64, a)), @as(f64, b));
            break :blk @floatCast(if (a < 0) -m else m);
        },
        .eq => if (a == b) 1 else 0,
        .ne => if (a != b) 1 else 0,
        .lt => if (a < b) 1 else 0,
        .gt => if (a > b) 1 else 0,
        .le => if (a <= b) 1 else 0,
        .ge => if (a >= b) 1 else 0,
        .and_ => if (a != 0 and b != 0) 1 else 0,
        .or_ => if (a != 0 or b != 0) 1 else 0,
        .bitand => @floatFromInt(@as(i64, @intFromFloat(a)) & @as(i64, @intFromFloat(b))),
        .min => @min(a, b),
        .max => @max(a, b),
        .hypot => @floatCast(@sqrt(@as(f64, a) * @as(f64, a) + @as(f64, b) * @as(f64, b))),
        else => unreachable,
    };
}

fn op3(comptime T: type, tag: Tag, a: T, b: T, c: T) T {
    return switch (tag) {
        .clamp => @min(@max(a, b), c),
        .select => if (a != 0) b else c,
        else => unreachable,
    };
}

// ---------------------------------------------------------------------------
// Compiler
// ---------------------------------------------------------------------------

pub const CompileError = error{ UnknownName, UnknownFunction, BadCall, NotConstant, Cycle, ParseError, Unsupported, OutOfMemory };

const PosCtx = struct { x: VId, y: VId };

const Thunk = struct {
    node: *ast.Node,
    env: ?*Frame,
    ctx: u32 = NONE,
    v: VId = 0,
    busy: bool = false,
};

/// Lexical scope of one expression / function body.
const Frame = struct {
    def: *sa_data.Def,
    names: []const []const u8,
    thunks: []Thunk,
    parent: ?*Frame,
};

const GlobalKey = struct { def: usize, ctx: u32 };

pub const Compiler = struct {
    a: std.mem.Allocator,
    data: *const sa_data.Data,
    planet: *const sa_data.Planet,
    seed: u32,
    controls: Controls,

    insts: std.ArrayList(Inst) = .empty,
    intern: std.AutoHashMapUnmanaged(Inst, VId) = .empty,
    payloads: std.ArrayList(Payload) = .empty,
    gens: std.ArrayList(noise.BasisNoiseGen) = .empty,
    gen_keys: std.ArrayList(u64) = .empty,
    quick_gens: std.ArrayList(u32) = .empty,
    spot_cfgs: std.ArrayList(SpotCfg) = .empty,
    /// density, quantity, radius, favorability roots of each spot_noise
    spot_roots: std.ArrayList([4]VId) = .empty,

    ctxs: std.ArrayList(PosCtx) = .empty,
    cur_ctx: u32 = 0,
    globals: std.AutoHashMapUnmanaged(GlobalKey, VId) = .empty,
    in_progress: std.AutoHashMapUnmanaged(GlobalKey, void) = .empty,

    /// human-readable description of the last compile failure
    err_buf: [512]u8 = undefined,
    err_len: usize = 0,

    /// `map_seed` is the MAP seed; the surface seed (what `map_seed` means
    /// inside noise expressions) adds the planet's offset.
    pub fn init(a: std.mem.Allocator, data: *const sa_data.Data, planet: *const sa_data.Planet, map_seed: u32, controls: Controls) CompileError!Compiler {
        var c = Compiler{ .a = a, .data = data, .planet = planet, .seed = planet.surfaceSeed(map_seed), .controls = controls };
        const x = try c.emitRaw(.{ .tag = .in_x });
        const y = try c.emitRaw(.{ .tag = .in_y });
        try c.ctxs.append(a, .{ .x = x, .y = y });
        return c;
    }

    pub fn errorMessage(self: *const Compiler) []const u8 {
        return self.err_buf[0..self.err_len];
    }

    fn fail(self: *Compiler, e: CompileError, comptime fmt: []const u8, args: anytype) CompileError {
        if (self.err_len == 0) {
            const s = std.fmt.bufPrint(&self.err_buf, fmt, args) catch self.err_buf[0..0];
            self.err_len = s.len;
        }
        return e;
    }

    fn note(self: *Compiler, where: []const u8) void {
        // append " <- name" so a failure shows the chain of definitions
        const rest = self.err_buf[self.err_len..];
        const s = std.fmt.bufPrint(rest, " <- {s}", .{where}) catch return;
        self.err_len += s.len;
    }

    // ---- DAG construction -------------------------------------------------

    fn emitRaw(self: *Compiler, inst: Inst) CompileError!VId {
        if (self.intern.get(inst)) |v| return v;
        const id: VId = @intCast(self.insts.items.len);
        try self.insts.append(self.a, inst);
        try self.intern.put(self.a, inst, id);
        return id;
    }

    pub fn konst(self: *Compiler, v: f64) CompileError!VId {
        return self.emitRaw(.{ .tag = .konst, .k = @bitCast(v) });
    }

    fn isK(self: *const Compiler, v: VId) bool {
        return self.insts.items[v].tag == .konst;
    }

    fn kval(self: *const Compiler, v: VId) f64 {
        return @bitCast(self.insts.items[v].k);
    }

    fn kf(self: *const Compiler, v: VId) FOLD {
        return @floatCast(self.kval(v));
    }

    fn emit1(self: *Compiler, tag: Tag, a: VId) CompileError!VId {
        if (self.isK(a)) return self.konst(op1(FOLD, tag, self.kf(a)));
        return self.emitRaw(.{ .tag = tag, .a = a });
    }

    fn emit2(self: *Compiler, tag: Tag, a: VId, b: VId) CompileError!VId {
        if (self.isK(a) and self.isK(b)) return self.konst(op2(FOLD, tag, self.kf(a), self.kf(b)));
        return self.emitRaw(.{ .tag = tag, .a = a, .b = b });
    }

    fn emit3(self: *Compiler, tag: Tag, a: VId, b: VId, c: VId) CompileError!VId {
        if (self.isK(a) and self.isK(b) and self.isK(c)) return self.konst(op3(FOLD, tag, self.kf(a), self.kf(b), self.kf(c)));
        // a constant condition picks its branch outright
        if (tag == .select and self.isK(a)) return if (self.kval(a) != 0) b else c;
        return self.emitRaw(.{ .tag = tag, .a = a, .b = b, .c = c });
    }

    fn payload(self: *Compiler, p: Payload) CompileError!u32 {
        for (self.payloads.items, 0..) |q, i| {
            if (std.meta.eql(p, q)) return @intCast(i);
        }
        try self.payloads.append(self.a, p);
        return @intCast(self.payloads.items.len - 1);
    }

    fn gen(self: *Compiler, s0: u32, s1: u32) CompileError!u32 {
        const key = (@as(u64, s0) << 32) | s1;
        for (self.gen_keys.items, 0..) |k, i| {
            if (k == key) return @intCast(i);
        }
        try self.gen_keys.append(self.a, key);
        try self.gens.append(self.a, noise.BasisNoiseGen.init(s0, s1));
        return @intCast(self.gens.items.len - 1);
    }

    fn posCtx(self: *Compiler, x: VId, y: VId) CompileError!u32 {
        for (self.ctxs.items, 0..) |p, i| {
            if (p.x == x and p.y == y) return @intCast(i);
        }
        try self.ctxs.append(self.a, .{ .x = x, .y = y });
        return @intCast(self.ctxs.items.len - 1);
    }

    // ---- definitions ------------------------------------------------------

    fn bodyNode(self: *Compiler, b: sa_data.Body, what: []const u8) CompileError!*ast.Node {
        return switch (b) {
            .num => |n| try ast.makeLit(self.data.arena, n),
            .src => |s| ast.parseExpr(self.data.arena, s) catch |e| switch (e) {
                error.OutOfMemory => return error.OutOfMemory,
                error.ParseError => return self.fail(error.ParseError, "cannot parse '{s}'", .{what}),
            },
        };
    }

    fn defRoot(self: *Compiler, def: *sa_data.Def) CompileError!*ast.Node {
        if (def.root == null) def.root = try self.bodyNode(def.body, def.name);
        return def.root.?;
    }

    /// New scope for `def`: parameters bound to the call's argument
    /// expressions (evaluated lazily in the CALLER's scope), locals bound to
    /// their own expressions (evaluated in this scope).
    fn makeFrame(self: *Compiler, def: *sa_data.Def, args: []const ast.Node.Arg, caller: ?*Frame, parent: ?*Frame) CompileError!*Frame {
        const np = def.params.len;
        const names = try self.a.alloc([]const u8, np + def.locals.len);
        const thunks = try self.a.alloc(Thunk, np + def.locals.len);
        const frame = try self.a.create(Frame);
        frame.* = .{ .def = def, .names = names, .thunks = thunks, .parent = parent };
        var next_pos: usize = 0;
        for (def.params, 0..) |pname, i| {
            var found: ?*ast.Node = null;
            for (args) |arg| {
                if (arg.name.len > 0 and std.mem.eql(u8, arg.name, pname)) {
                    found = arg.value;
                    break;
                }
            }
            if (found == null) {
                while (next_pos < args.len and args[next_pos].name.len > 0) next_pos += 1;
                if (next_pos < args.len) {
                    found = args[next_pos].value;
                    next_pos += 1;
                }
            }
            const node = found orelse return self.fail(error.BadCall, "call to '{s}' is missing argument '{s}'", .{ def.name, pname });
            names[i] = pname;
            thunks[i] = .{ .node = node, .env = caller };
        }
        for (def.locals, 0..) |*loc, k| {
            if (loc.node == null) loc.node = try self.bodyNode(loc.body, loc.name);
            names[np + k] = loc.name;
            thunks[np + k] = .{ .node = loc.node.?, .env = frame };
        }
        return frame;
    }

    fn force(self: *Compiler, t: *Thunk) CompileError!VId {
        if (t.ctx == self.cur_ctx) return t.v;
        if (t.busy) return self.fail(error.Cycle, "cyclic local expression", .{});
        t.busy = true;
        defer t.busy = false;
        const v = try self.lower(t.node, t.env);
        t.ctx = self.cur_ctx;
        t.v = v;
        return v;
    }

    /// Value of a parameterless named expression at the current position.
    fn lowerDef(self: *Compiler, def: *sa_data.Def) CompileError!VId {
        if (def.params.len > 0) return self.fail(error.BadCall, "function '{s}' referenced without arguments", .{def.name});
        const key = GlobalKey{ .def = @intFromPtr(def), .ctx = self.cur_ctx };
        if (self.globals.get(key)) |v| return v;
        if (self.in_progress.contains(key)) return self.fail(error.Cycle, "'{s}' references itself", .{def.name});
        try self.in_progress.put(self.a, key, {});
        defer _ = self.in_progress.remove(key);
        const frame = try self.makeFrame(def, &.{}, null, null);
        const v = self.lower(try self.defRoot(def), frame) catch |e| {
            self.note(def.name);
            return e;
        };
        try self.globals.put(self.a, key, v);
        return v;
    }

    /// Compile a root by name: a property key ("elevation"), a named
    /// expression, or an autoplace name ("tile:lava:probability").
    pub fn root(self: *Compiler, name: []const u8) CompileError!VId {
        return self.lowerName(name, null);
    }

    /// Compile an expression given as source text (global scope).
    pub fn expr(self: *Compiler, src: []const u8) CompileError!VId {
        return self.lower(try self.bodyNode(.{ .src = src }, src), null);
    }

    /// The value of `v` if it folded to a constant.
    pub fn constant(self: *const Compiler, v: VId) ?f64 {
        return if (self.isK(v)) self.kval(v) else null;
    }

    // ---- lowering ---------------------------------------------------------

    fn lower(self: *Compiler, node: *ast.Node, env: ?*Frame) CompileError!VId {
        switch (node.kind) {
            .lit => |v| return self.konst(v),
            .str => return self.fail(error.BadCall, "string used as a value", .{}),
            .name => |n| return self.lowerName(n, env),
            .un => |u| {
                const x = try self.lower(u.x, env);
                return self.emit1(if (u.op == .neg) .neg else .not_, x);
            },
            .bin => |b| {
                const l = try self.lower(b.l, env);
                const r = try self.lower(b.r, env);
                const tag: Tag = switch (b.op) {
                    .add => .add,
                    .sub => .sub,
                    .mul => .mul,
                    .div => .div,
                    .mod => .mod,
                    .pow_op => .pow,
                    .eq => .eq,
                    .ne => .ne,
                    .lt => .lt,
                    .gt => .gt,
                    .le => .le,
                    .ge => .ge,
                    .and_op => .and_,
                    .or_op => .or_,
                    .bitand => .bitand,
                    else => return self.fail(error.Unsupported, "unsupported operator", .{}),
                };
                return self.emit2(tag, l, r);
            },
            .call => |c| return self.lowerCall(c.name, c.args, env),
        }
    }

    fn lowerName(self: *Compiler, name: []const u8, env: ?*Frame) CompileError!VId {
        if (std.mem.startsWith(u8, name, "control:")) return self.control(name);
        // parameters / local expressions, innermost scope first
        var f = env;
        while (f) |fr| : (f = fr.parent) {
            for (fr.names, 0..) |n, i| {
                if (std.mem.eql(u8, n, name)) return self.force(&fr.thunks[i]);
            }
        }
        // the surface's property overrides
        if (self.planet.prop(name)) |target| switch (target) {
            .num => |n| return self.konst(n),
            .src => |t| {
                if (!std.mem.eql(u8, t, name)) return self.lowerPlain(t);
            },
        };
        return self.lowerPlain(name);
    }

    /// Engine variable or global named expression (no scope / override lookup).
    fn lowerPlain(self: *Compiler, name: []const u8) CompileError!VId {
        const ctx = self.ctxs.items[self.cur_ctx];
        const eql = std.mem.eql;
        if (eql(u8, name, "x")) return ctx.x;
        if (eql(u8, name, "y")) return ctx.y;
        if (eql(u8, name, "map_seed")) return self.konst(@floatFromInt(self.seed));
        // = f32(map_seed) * 2^-32 and map_seed mod 2^16 (both probed)
        if (eql(u8, name, "map_seed_normalized")) return self.konst(@as(f64, @as(f32, @floatFromInt(self.seed))) * 0x1p-32);
        if (eql(u8, name, "map_seed_small")) return self.konst(@floatFromInt(self.seed & 0xffff));
        if (eql(u8, name, "pi")) return self.konst(std.math.pi);
        if (eql(u8, name, "inf")) return self.konst(std.math.inf(f64));
        if (eql(u8, name, "starting_area_radius")) return self.konst(150);
        if (eql(u8, name, "cliff_richness")) return self.konst(self.planet.cliff_richness);
        if (eql(u8, name, "cliff_elevation_interval")) return self.konst(self.planet.cliff_elevation_interval);
        if (eql(u8, name, "no_enemies_mode")) return self.konst(0);
        if (self.data.def(name)) |def| return self.lowerDef(def);
        return self.fail(error.UnknownName, "unknown name '{s}'", .{name});
    }

    fn control(self: *Compiler, name: []const u8) CompileError!VId {
        const rest = name["control:".len..];
        const colon = std.mem.indexOfScalar(u8, rest, ':') orelse return self.fail(error.BadCall, "bad control '{s}'", .{name});
        return self.konst(self.controls.lookup(self.controls.ctx, rest[0..colon], rest[colon + 1 ..]));
    }

    fn findLocalFn(env: ?*Frame, name: []const u8) ?struct { def: *sa_data.Def, frame: *Frame } {
        var f = env;
        while (f) |fr| : (f = fr.parent) {
            for (fr.def.local_fns) |*lf| {
                if (std.mem.eql(u8, lf.name, name)) return .{ .def = lf, .frame = fr };
            }
        }
        return null;
    }

    fn lowerCall(self: *Compiler, name: []const u8, args: []const ast.Node.Arg, env: ?*Frame) CompileError!VId {
        if (findLocalFn(env, name)) |lf| {
            const frame = try self.makeFrame(lf.def, args, env, lf.frame);
            return self.lower(try self.defRoot(lf.def), frame) catch |e| {
                self.note(name);
                return e;
            };
        }
        if (self.data.def(name)) |def| {
            if (def.is_function) {
                const frame = try self.makeFrame(def, args, env, null);
                return self.lower(try self.defRoot(def), frame) catch |e| {
                    self.note(name);
                    return e;
                };
            }
        }
        return self.builtin(name, .{ .c = self, .args = args, .env = env });
    }

    // ---- builtins ---------------------------------------------------------

    const Args = struct {
        c: *Compiler,
        args: []const ast.Node.Arg,
        env: ?*Frame,

        /// argument by name (table call) or position (paren call)
        fn node(self: Args, name: []const u8, pos: usize) ?*ast.Node {
            for (self.args, 0..) |arg, i| {
                if (arg.name.len > 0) {
                    if (std.mem.eql(u8, arg.name, name)) return arg.value;
                } else if (i == pos) return arg.value;
            }
            return null;
        }

        fn val(self: Args, fname: []const u8, name: []const u8, pos: usize) CompileError!VId {
            const n = self.node(name, pos) orelse return self.c.fail(error.BadCall, "{s}: missing '{s}'", .{ fname, name });
            return self.c.lower(n, self.env);
        }

        fn valOr(self: Args, name: []const u8, pos: usize, default: f64) CompileError!VId {
            const n = self.node(name, pos) orelse return self.c.konst(default);
            return self.c.lower(n, self.env);
        }

        /// argument that must fold to a constant (noise-op configuration)
        fn num(self: Args, fname: []const u8, name: []const u8, pos: usize, default: ?f64) CompileError!f64 {
            const n = self.node(name, pos) orelse return default orelse self.c.fail(error.BadCall, "{s}: missing '{s}'", .{ fname, name });
            const v = try self.c.lower(n, self.env);
            if (!self.c.isK(v)) return self.c.fail(error.NotConstant, "{s}: '{s}' must be constant", .{ fname, name });
            return self.c.kval(v);
        }

        fn f32num(self: Args, fname: []const u8, name: []const u8, pos: usize, default: ?f64) CompileError!f32 {
            return @floatCast(try self.num(fname, name, pos, default));
        }

        fn str(self: Args, name: []const u8, pos: usize) ?[]const u8 {
            const n = self.node(name, pos) orelse return null;
            return if (n.kind == .str) n.kind.str else null;
        }

        fn seed0(self: Args, fname: []const u8) CompileError!u32 {
            return toU32(try self.num(fname, "seed0", NONE, null));
        }

        /// seed1 is a number or a name (hashed with crc32)
        fn seed1(self: Args, fname: []const u8) CompileError!u32 {
            if (self.str("seed1", NONE)) |s| return std.hash.Crc32.hash(s);
            return toU32(try self.num(fname, "seed1", NONE, null));
        }
    };

    fn toU32(v: f64) u32 {
        const i: i64 = @intFromFloat(@round(v));
        return @truncate(@as(u64, @bitCast(i)));
    }

    fn builtin(self: *Compiler, name: []const u8, ar: Args) CompileError!VId {
        const eql = std.mem.eql;
        const one = [_]struct { []const u8, Tag }{
            .{ "abs", .abs },   .{ "sin", .sin },     .{ "cos", .cos }, .{ "sqrt", .sqrt },
            .{ "floor", .floor }, .{ "ceil", .ceil }, .{ "exp", .exp }, .{ "log2", .log2 },
        };
        for (one) |o| {
            if (eql(u8, name, o[0])) return self.emit1(o[1], try ar.val(name, "", 0));
        }
        if (eql(u8, name, "min") or eql(u8, name, "max")) {
            const tag: Tag = if (name[1] == 'i') .min else .max;
            if (ar.args.len == 0) return self.fail(error.BadCall, "{s}: no arguments", .{name});
            var acc = try self.lower(ar.args[0].value, ar.env);
            for (ar.args[1..]) |arg| acc = try self.emit2(tag, acc, try self.lower(arg.value, ar.env));
            return acc;
        }
        if (eql(u8, name, "pow")) return self.emit2(.pow, try ar.val(name, "", 0), try ar.val(name, "", 1));
        if (eql(u8, name, "clamp")) return self.emit3(.clamp, try ar.val(name, "", 0), try ar.val(name, "", 1), try ar.val(name, "", 2));
        if (eql(u8, name, "if")) return self.emit3(.select, try ar.val(name, "", 0), try ar.val(name, "", 1), try ar.val(name, "", 2));
        if (eql(u8, name, "var")) {
            const target = ar.str("", 0) orelse return self.fail(error.BadCall, "var() needs a name", .{});
            return self.lowerName(target, ar.env);
        }
        if (eql(u8, name, "multisample")) {
            // the expression evaluated at an offset position
            const n = ar.node("", 0) orelse return self.fail(error.BadCall, "multisample: missing expression", .{});
            const dx = try ar.num(name, "offset_x", 1, null);
            const dy = try ar.num(name, "offset_y", 2, null);
            const here = self.ctxs.items[self.cur_ctx];
            const nx = try self.emit2(.add, here.x, try self.konst(dx));
            const ny = try self.emit2(.add, here.y, try self.konst(dy));
            const saved = self.cur_ctx;
            self.cur_ctx = try self.posCtx(nx, ny);
            defer self.cur_ctx = saved;
            return self.lower(n, ar.env);
        }
        if (std.mem.startsWith(u8, name, "distance_from_nearest_point")) {
            // points = starting_positions; a planet surface starts at (0, 0)
            const pts = ar.node("points", 2) orelse return self.fail(error.BadCall, "{s}: missing points", .{name});
            if (pts.kind != .name or !eql(u8, pts.kind.name, "starting_positions"))
                return self.fail(error.Unsupported, "{s}: only starting_positions is supported", .{name});
            const x = try ar.val(name, "x", 0);
            const y = try ar.val(name, "y", 1);
            if (std.mem.endsWith(u8, name, "_x")) return x;
            if (std.mem.endsWith(u8, name, "_y")) return y;
            const d = try self.emit2(.hypot, x, y);
            if (ar.node("maximum_distance", 3)) |m| return self.emit2(.min, d, try self.lower(m, ar.env));
            return d;
        }
        if (eql(u8, name, "basis_noise")) {
            const x = try ar.val(name, "x", 0);
            const y = try ar.val(name, "y", 1);
            const p = try self.payload(.{ .basis = .{
                .gen = try self.gen(try ar.seed0(name), try ar.seed1(name)),
                .is = try ar.f32num(name, "input_scale", NONE, 1),
                .os = try ar.f32num(name, "output_scale", NONE, 1),
                .ox = try ar.f32num(name, "offset_x", NONE, 0),
                .oy = try ar.f32num(name, "offset_y", NONE, 0),
            } });
            return self.emitRaw(.{ .tag = .basis, .a = x, .b = y, .aux = p });
        }
        if (eql(u8, name, "multioctave_noise")) {
            const x = try ar.val(name, "x", 0);
            const y = try ar.val(name, "y", 1);
            const p = try self.payload(.{ .multi = .{
                .gen = try self.gen(try ar.seed0(name), try ar.seed1(name)),
                .m = noise.exact.Multioctave.init(
                    try ar.f32num(name, "octaves", NONE, null),
                    try ar.f32num(name, "persistence", NONE, null),
                    try ar.f32num(name, "input_scale", NONE, 1),
                    try ar.f32num(name, "output_scale", NONE, 1),
                    try ar.f32num(name, "offset_x", NONE, 0),
                    try ar.f32num(name, "offset_y", NONE, 0),
                ),
            } });
            return self.emitRaw(.{ .tag = .multioctave, .a = x, .b = y, .aux = p });
        }
        if (eql(u8, name, "quick_multioctave_noise")) {
            // one generator per octave: (seed0 + k * octave_seed0_shift, seed1)
            const x = try ar.val(name, "x", 0);
            const y = try ar.val(name, "y", 1);
            const s0 = try ar.seed0(name);
            const s1 = try ar.seed1(name);
            const octaves = toU32(try ar.num(name, "octaves", NONE, null));
            const shift = toU32(try ar.num(name, "octave_seed0_shift", NONE, 1));
            const first: u32 = @intCast(self.quick_gens.items.len);
            for (0..octaves) |k| try self.quick_gens.append(self.a, try self.gen(s0 +% shift *% @as(u32, @intCast(k)), s1));
            const p = try self.payload(.{ .quick = .{
                .gens = first,
                .octaves = octaves,
                .is = try ar.f32num(name, "input_scale", NONE, 1),
                .os = try ar.f32num(name, "output_scale", NONE, 1),
                .oism = try ar.f32num(name, "octave_input_scale_multiplier", NONE, 0.5),
                .oosm = try ar.f32num(name, "octave_output_scale_multiplier", NONE, 0.5),
                .ox = try ar.f32num(name, "offset_x", NONE, 0),
                .oy = try ar.f32num(name, "offset_y", NONE, 0),
            } });
            return self.emitRaw(.{ .tag = .quick_multioctave, .a = x, .b = y, .aux = p });
        }
        if (eql(u8, name, "variable_persistence_multioctave_noise")) {
            const x = try ar.val(name, "x", 0);
            const y = try ar.val(name, "y", 1);
            const per = try ar.val(name, "persistence", NONE);
            const p = try self.payload(.{ .varp = .{
                .gen = try self.gen(try ar.seed0(name), try ar.seed1(name)),
                .v = noise.exact.VariablePersistence.init(
                    try ar.num(name, "octaves", NONE, null),
                    try ar.f32num(name, "input_scale", NONE, 1),
                    try ar.f32num(name, "output_scale", NONE, 1),
                    try ar.f32num(name, "offset_x", NONE, 0),
                    try ar.f32num(name, "offset_y", NONE, 0),
                ),
            } });
            return self.emitRaw(.{ .tag = .var_persistence, .a = x, .b = y, .c = per, .aux = p });
        }
        if (eql(u8, name, "random_penalty")) {
            const x = try ar.val(name, "x", 0);
            const y = try ar.val(name, "y", 1);
            const src = try ar.val(name, "source", 2);
            const amp = try ar.valOr("amplitude", 3, 1);
            const seed: i32 = @intFromFloat(try ar.num(name, "seed", NONE, 1));
            const p = try self.payload(.{ .randp = .{ .seed = seed } });
            return self.emitRaw(.{ .tag = .random_penalty, .a = x, .b = y, .c = src, .d = amp, .aux = p });
        }
        if (std.mem.startsWith(u8, name, "voronoi_")) {
            const out: VoronoiOut = if (eql(u8, name, "voronoi_spot_noise")) .spot else if (eql(u8, name, "voronoi_facet_noise")) .facet else if (eql(u8, name, "voronoi_pyramid_noise")) .pyramid else if (eql(u8, name, "voronoi_cell_id")) .cell_id else return self.fail(error.UnknownFunction, "unknown function '{s}'", .{name});
            const x = try ar.val(name, "x", 0);
            const y = try ar.val(name, "y", 1);
            const dt: noise.VoronoiDistanceType = blk: {
                if (ar.str("distance_type", NONE)) |s| {
                    if (eql(u8, s, "euclidean")) break :blk .euclidean;
                    if (eql(u8, s, "manhattan")) break :blk .manhattan;
                    if (eql(u8, s, "chebyshev")) break :blk .chebyshev;
                    if (eql(u8, s, "minkowski3")) break :blk .minkowski3;
                    return self.fail(error.BadCall, "{s}: unknown distance_type '{s}'", .{ name, s });
                }
                break :blk @enumFromInt(@as(u8, @intFromFloat(@round(try ar.num(name, "distance_type", NONE, 2)))));
            };
            const grid: u16 = @intFromFloat(try ar.num(name, "grid_size", NONE, null));
            const v = noise.VoronoiNoise.init(try ar.seed0(name), try ar.seed1(name), grid, dt, try ar.f32num(name, "jitter", NONE, 0.5));
            const p = try self.payload(.{ .voronoi = .{ .v = v, .out = out } });
            return self.emitRaw(.{ .tag = .voronoi, .a = x, .b = y, .aux = p });
        }
        if (eql(u8, name, "terrace")) {
            const value = try ar.val(name, "value", 0);
            const strength = try ar.val(name, "strength", 3);
            const p = try self.payload(.{ .terrace = .{
                .offset = try ar.f32num(name, "offset", 1, null),
                .width = try ar.f32num(name, "width", 2, null),
            } });
            return self.emitRaw(.{ .tag = .terrace, .a = value, .b = strength, .aux = p });
        }
        if (eql(u8, name, "spot_noise")) {
            const x = try ar.val(name, "x", 0);
            const y = try ar.val(name, "y", 1);
            const region_size = try ar.num(name, "region_size", NONE, 512);
            const skip_span = toU32(try ar.num(name, "skip_span", NONE, 1));
            var point_count: u32 = 256;
            if (ar.node("candidate_point_count", NONE) != null) {
                point_count = toU32(try ar.num(name, "candidate_point_count", NONE, null));
            } else if (ar.node("candidate_spot_count", NONE) != null) {
                point_count = toU32(try ar.num(name, "candidate_spot_count", NONE, null)) *% skip_span;
            }
            if (point_count > 10000) return self.fail(error.BadCall, "spot_noise: candidate_point_count too high", .{});
            const rs_i: u32 = @intFromFloat(region_size);
            const default_spacing: f64 = @sqrt(@as(f64, @floatFromInt(if (point_count != 0) (rs_i *% rs_i) / point_count else 0))) * 0.5;
            const cfg = SpotCfg{
                .seed0 = try ar.seed0(name),
                .seed1 = toU32(try ar.num(name, "seed1", NONE, null)),
                .region_size = region_size,
                .point_count = point_count,
                .skip_span = @max(skip_span, 1),
                .skip_offset = toU32(try ar.num(name, "skip_offset", NONE, 0)),
                .spacing = try ar.f32num(name, "suggested_minimum_candidate_point_spacing", NONE, default_spacing),
                .hard_target = (try ar.num(name, "hard_region_target_quantity", NONE, 1)) > 0,
                .basement = try ar.f32num(name, "basement_value", NONE, null),
                .max_radius = try ar.f32num(name, "maximum_spot_basement_radius", NONE, null),
            };
            // the sub-expressions see the candidate point as (x, y). Reserve
            // this op's slot first: a sub-expression may contain a spot_noise
            // of its own.
            const idx: u32 = @intCast(self.spot_cfgs.items.len);
            try self.spot_cfgs.append(self.a, cfg);
            try self.spot_roots.append(self.a, undefined);
            const sx = try self.emitRaw(.{ .tag = .in_x, .aux = idx + 1 });
            const sy = try self.emitRaw(.{ .tag = .in_y, .aux = idx + 1 });
            const saved = self.cur_ctx;
            self.cur_ctx = try self.posCtx(sx, sy);
            defer self.cur_ctx = saved;
            var roots: [4]VId = undefined;
            const subs = [4][]const u8{ "density_expression", "spot_quantity_expression", "spot_radius_expression", "spot_favorability_expression" };
            for (subs, 0..) |sn, i| roots[i] = try ar.val(name, sn, NONE);
            self.spot_roots.items[idx] = roots;
            const p = try self.payload(.{ .spot = idx });
            return self.emitRaw(.{ .tag = .spot, .a = x, .b = y, .aux = p });
        }
        if (eql(u8, name, "expression_in_range"))
            return self.fail(error.Unsupported, "'{s}' is not implemented yet", .{name});
        return self.fail(error.UnknownFunction, "unknown function '{s}'", .{name});
    }

    // ---- program extraction -----------------------------------------------

    /// Extract the instructions the given roots depend on, in evaluation
    /// order. Ids ascend with creation, and an instruction's inputs always
    /// exist before it, so creation order is a valid schedule.
    pub fn finish(self: *Compiler, roots: []const VId) CompileError!Program {
        const spots = try self.a.alloc(SpotOp, self.spot_cfgs.items.len);
        for (spots, 0..) |*sp, i| {
            sp.cfg = self.spot_cfgs.items[i];
            sp.sub = try self.extract(&self.spot_roots.items[i], spots);
        }
        return self.extract(roots, spots);
    }

    fn extract(self: *Compiler, roots: []const VId, spots: []const SpotOp) CompileError!Program {
        const n = self.insts.items.len;
        const map = try self.a.alloc(u32, n);
        @memset(map, NONE);
        var stack: std.ArrayList(VId) = .empty;
        for (roots) |r| try stack.append(self.a, r);
        const USED: u32 = NONE - 1;
        while (stack.pop()) |v| {
            if (map[v] != NONE) continue;
            map[v] = USED;
            const inst = self.insts.items[v];
            const ins = [4]VId{ inst.a, inst.b, inst.c, inst.d };
            for (ins[0..inst.tag.arity()]) |i| try stack.append(self.a, i);
        }
        var out: std.ArrayList(Inst) = .empty;
        for (self.insts.items, 0..) |inst, i| {
            if (map[i] == NONE) continue;
            map[i] = @intCast(out.items.len);
            var r = inst;
            const ar = inst.tag.arity();
            if (ar > 0) r.a = map[inst.a];
            if (ar > 1) r.b = map[inst.b];
            if (ar > 2) r.c = map[inst.c];
            if (ar > 3) r.d = map[inst.d];
            try out.append(self.a, r);
        }
        const rr = try self.a.alloc(u32, roots.len);
        for (roots, 0..) |r, i| rr[i] = map[r];
        return .{
            .insts = out.items,
            .roots = rr,
            .payloads = self.payloads.items,
            .gens = self.gens.items,
            .quick_gens = self.quick_gens.items,
            .spots = spots,
        };
    }
};

// ---------------------------------------------------------------------------
// Program
// ---------------------------------------------------------------------------

pub const Program = struct {
    insts: []const Inst,
    roots: []const u32,
    payloads: []const Payload,
    gens: []const noise.BasisNoiseGen,
    quick_gens: []const u32,
    spots: []const SpotOp,

    /// positions evaluated per call by the tile driver
    pub const BATCH = 64;

    const Spot = struct { x: f32, y: f32, peak: f32, slope: f32 };
    const RegionKey = struct { x: i32, y: i32 };

    /// Per-thread state of one spot_noise: its finished regions and the
    /// register file its sub-program runs in.
    const SpotState = struct {
        regions: std.AutoHashMapUnmanaged(RegionKey, []Spot) = .empty,
        ws: ?*Workspace = null,
    };

    /// Register file for one evaluating thread.
    pub const Workspace = struct {
        regs: []f32,
        batch: usize,
        a: std.mem.Allocator,
        spots: []SpotState,
        /// random_penalty draws from one stream per column (how the engine
        /// evaluates spot candidates) instead of one stream per position
        column_rng: bool = false,
    };

    pub fn workspace(self: *const Program, a: std.mem.Allocator) error{OutOfMemory}!Workspace {
        return self.workspaceN(a, BATCH);
    }

    pub fn workspaceN(self: *const Program, a: std.mem.Allocator, batch: usize) error{OutOfMemory}!Workspace {
        const regs = try a.alloc(f32, self.insts.len * batch);
        for (self.insts, 0..) |inst, i| {
            const v: f32 = if (inst.tag == .konst) @floatCast(@as(f64, @bitCast(inst.k))) else 0;
            @memset(regs[i * batch ..][0..batch], v);
        }
        const spots = try a.alloc(SpotState, self.spots.len);
        for (spots) |*s| s.* = .{};
        return .{ .regs = regs, .batch = batch, .a = a, .spots = spots };
    }

    /// Values of root `i` for the positions of the last eval().
    pub fn out(self: *const Program, ws: *const Workspace, i: usize) []const f32 {
        return ws.regs[self.roots[i] * ws.batch ..][0..ws.batch];
    }

    /// Evaluate every root at the positions (xs[j], ys[j]); xs.len <= ws.batch.
    pub fn eval(self: *const Program, ws: *Workspace, xs: []const f32, ys: []const f32) void {
        const n = xs.len;
        const W = ws.batch;
        std.debug.assert(n <= W and ys.len == n);
        const regs = ws.regs;
        for (self.insts, 0..) |inst, i| {
            const r = regs[i * W ..][0..n];
            const A = regs[inst.a * W ..][0..n];
            const B = regs[inst.b * W ..][0..n];
            const C = regs[inst.c * W ..][0..n];
            const D = regs[inst.d * W ..][0..n];
            switch (inst.tag) {
                .konst => {},
                .in_x => @memcpy(r, xs),
                .in_y => @memcpy(r, ys),
                .add => for (r, A, B) |*o, a, b| {
                    o.* = a + b;
                },
                .sub => for (r, A, B) |*o, a, b| {
                    o.* = a - b;
                },
                .mul => for (r, A, B) |*o, a, b| {
                    o.* = a * b;
                },
                .div => for (r, A, B) |*o, a, b| {
                    o.* = a / b;
                },
                .min => for (r, A, B) |*o, a, b| {
                    o.* = @min(a, b);
                },
                .max => for (r, A, B) |*o, a, b| {
                    o.* = @max(a, b);
                },
                .mod, .pow, .eq, .ne, .lt, .gt, .le, .ge, .and_, .or_, .bitand, .hypot => |t| for (r, A, B) |*o, a, b| {
                    o.* = op2(f32, t, a, b);
                },
                .neg, .not_, .abs, .sin, .cos, .sqrt, .floor, .ceil, .exp, .log2 => |t| for (r, A) |*o, a| {
                    o.* = op1(f32, t, a);
                },
                .clamp, .select => |t| for (r, A, B, C) |*o, a, b, c| {
                    o.* = op3(f32, t, a, b, c);
                },
                .basis => {
                    const p = self.payloads[inst.aux].basis;
                    const g = &self.gens[p.gen];
                    for (r, A, B) |*o, x, y| o.* = noise.exact.basisScaled(g, x, y, p.is, p.os, p.ox, p.oy);
                },
                .multioctave => {
                    const p = &self.payloads[inst.aux].multi;
                    const g = &self.gens[p.gen];
                    for (r, A, B) |*o, x, y| o.* = p.m.eval(g, x, y);
                },
                .quick_multioctave => {
                    const p = self.payloads[inst.aux].quick;
                    const gi = self.quick_gens[p.gens..][0..p.octaves];
                    for (r, A, B) |*o, x, y| o.* = noise.exact.quickMultioctave(self.gens, gi, x, y, p.is, p.os, p.oism, p.oosm, p.ox, p.oy);
                },
                .var_persistence => {
                    const p = &self.payloads[inst.aux].varp;
                    const g = &self.gens[p.gen];
                    for (r, A, B, C) |*o, x, y, per| o.* = p.v.eval(g, x, y, per);
                },
                .random_penalty => {
                    const p = self.payloads[inst.aux].randp;
                    if (ws.column_rng and n > 0) {
                        // one stream seeded from the column's first position,
                        // consumed from the last element to the first
                        var prng = rng.Rng.init(penaltySeed(A[0], B[0], p.seed));
                        var j = n;
                        while (j > 0) : (j -= 1) r[j - 1] = @floatCast(@as(f64, C[j - 1]) - prng.float() * @as(f64, D[j - 1]));
                    } else {
                        for (r, A, B, C, D) |*o, x, y, src, amp| {
                            var prng = rng.Rng.init(penaltySeed(x, y, p.seed));
                            o.* = @floatCast(@as(f64, src) - prng.float() * @as(f64, amp));
                        }
                    }
                },
                .voronoi => {
                    const p = self.payloads[inst.aux].voronoi;
                    for (r, A, B) |*o, x, y| {
                        const res = p.v.evalAt(x, y);
                        o.* = switch (p.out) {
                            .spot => res.nearest,
                            .facet => res.gap,
                            .pyramid => res.pyramid,
                            .cell_id => res.cell_id,
                        };
                    }
                },
                .terrace => {
                    const p = self.payloads[inst.aux].terrace;
                    for (r, A, B) |*o, v, strength| o.* = @floatCast(noise.terrace(v, p.offset, p.width, strength));
                },
                .spot => {
                    const idx = self.payloads[inst.aux].spot;
                    for (r, A, B) |*o, x, y| o.* = self.spotValue(ws, idx, x, y);
                },
            }
        }
    }

    fn penaltySeed(x: f32, y: f32, seed: i32) u32 {
        const xi: i32 = @intFromFloat(@floor(x));
        const yi: i32 = @as(i32, @intFromFloat(@floor(y))) +% seed;
        const s: u32 = (@as(u32, @bitCast(xi)) *% 7919) +% (@as(u32, @bitCast(yi)) *% 7907) +% 0x3fbe2c;
        return if (s < 342) 341 else s;
    }

    // ---- spot_noise ---------------------------------------------------------
    //
    // Generic form of the engine's SpotNoise op (see noise.zig SpotNoiseField
    // for the decompilation notes). Per region: Poisson-disk candidate
    // points; the density / quantity / radius / favorability sub-expressions
    // evaluated at each candidate; candidates taken in favorability order
    // until their quantity reaches mean(density) * region area; each taken
    // candidate becomes a cone. The value is the highest cone (or basement).

    fn spotValue(self: *const Program, ws: *Workspace, idx: u32, x: f32, y: f32) f32 {
        const cfg = &self.spots[idx].cfg;
        var value: f32 = @floatCast(cfg.basement);
        const max_radius: f32 = @floatCast(cfg.max_radius);
        // regions are centred on multiples of region_size
        const half: f64 = @floatFromInt(@as(u32, @intFromFloat(cfg.region_size)) / 2);
        const rx: i32 = @intFromFloat(@floor((@as(f64, x) + half) / cfg.region_size));
        const ry: i32 = @intFromFloat(@floor((@as(f64, y) + half) / cfg.region_size));
        var dy: i32 = -1;
        while (dy <= 1) : (dy += 1) {
            var dx: i32 = -1;
            while (dx <= 1) : (dx += 1) {
                for (self.spotRegion(ws, idx, rx + dx, ry + dy)) |sp| {
                    const dist: f32 = @sqrt((x - sp.x) * (x - sp.x) + (y - sp.y) * (y - sp.y));
                    if (dist <= max_radius) {
                        const v = sp.peak - dist * sp.slope;
                        if (value <= v) value = v;
                    }
                }
            }
        }
        return value;
    }

    fn spotRegion(self: *const Program, ws: *Workspace, idx: u32, rx: i32, ry: i32) []const Spot {
        const st = &ws.spots[idx];
        const key = RegionKey{ .x = rx, .y = ry };
        if (st.regions.get(key)) |s| return s;
        const spots = self.computeRegion(ws, idx, rx, ry) catch @panic("out of memory");
        st.regions.put(ws.a, key, spots) catch @panic("out of memory");
        return spots;
    }

    fn computeRegion(self: *const Program, ws: *Workspace, idx: u32, rx: i32, ry: i32) ![]Spot {
        const a = ws.a;
        const op = &self.spots[idx];
        const cfg = &op.cfg;
        const rsize: i32 = @intFromFloat(cfg.region_size);
        const n_points: usize = cfg.point_count;
        if (rsize <= 0 or n_points == 0 or cfg.skip_offset >= n_points) return &.{};
        const rsize_u: u32 = @intCast(rsize);
        const base_x: i32 = rx *% rsize -% @divTrunc(rsize, 2);
        const base_y: i32 = ry *% rsize -% @divTrunc(rsize, 2);

        // candidate points: integer positions in the region, kept apart by a
        // spacing that relaxes each time a draw lands too close
        const px = try a.alloc(f32, n_points);
        defer a.free(px);
        const py = try a.alloc(f32, n_points);
        defer a.free(py);
        var prng = rng.Rng.init(noise.regionSeed(cfg.seed0, cfg.seed1, rx, ry));
        const spacing: f32 = @floatCast(cfg.spacing);
        var spacing2: f32 = spacing * spacing;
        for (0..n_points) |i| {
            while (true) {
                const fx: f32 = @floatFromInt(base_x +% @as(i32, @bitCast(prng.next() % rsize_u)));
                const fy: f32 = @floatFromInt(base_y +% @as(i32, @bitCast(prng.next() % rsize_u)));
                var ok = true;
                for (0..i) |j| {
                    const ex = fx - px[j];
                    const ey = fy - py[j];
                    if (ex * ex + ey * ey < spacing2) {
                        spacing2 *= 0.9375;
                        ok = false;
                        break;
                    }
                }
                if (ok) {
                    px[i] = fx;
                    py[i] = fy;
                    break;
                }
            }
        }

        // this spot_noise's share of the candidates
        const nc = (n_points - 1 - cfg.skip_offset) / cfg.skip_span + 1;
        const cx = try a.alloc(f32, nc);
        defer a.free(cx);
        const cy = try a.alloc(f32, nc);
        defer a.free(cy);
        for (0..nc) |k| {
            cx[k] = px[cfg.skip_offset + k * cfg.skip_span];
            cy[k] = py[cfg.skip_offset + k * cfg.skip_span];
        }
        const st = &ws.spots[idx];
        if (st.ws == null) {
            const sub = try a.create(Workspace);
            sub.* = try op.sub.workspaceN(a, nc);
            sub.column_rng = true;
            st.ws = sub;
        }
        const sws = st.ws.?;
        op.sub.eval(sws, cx, cy);
        const density = op.sub.out(sws, 0);
        const quantity = op.sub.out(sws, 1);
        const radius = op.sub.out(sws, 2);
        const favor = op.sub.out(sws, 3);

        // placeSpots, in the engine's f32 arithmetic
        var dsum: f32 = 0;
        for (density[0..nc]) |d| dsum = dsum + d;
        const target: f32 = (dsum / @as(f32, @floatFromInt(nc))) * @as(f32, @floatFromInt(rsize_u *% rsize_u));
        var cones: std.ArrayList(Spot) = .empty;
        if (!(target > 0)) return cones.items;

        const order = try a.alloc(u32, nc);
        defer a.free(order);
        for (order, 0..) |*o, k| o.* = @intCast(k);
        std.mem.sort(u32, order, favor, struct {
            fn before(f: []const f32, l: u32, r: u32) bool {
                return f[l] > f[r];
            }
        }.before);

        const max_radius: f32 = @floatCast(cfg.max_radius);
        var taken: f32 = 0;
        for (order) |k| {
            var q: f32 = quantity[k];
            var r: f32 = if (radius[k] <= max_radius) radius[k] else max_radius;
            if (q > 0 and r > 0) {
                if (cfg.hard_target) {
                    const qc: f32 = if (target - taken <= q) target - taken else q;
                    r = r * noise.fastExp2f(noise.fastLog2(qc / q) * 0.33333334);
                    q = qc;
                }
                const peak: f32 = (q * 3.0) / (r * 3.1416 * r);
                try cones.append(a, .{ .x = cx[k], .y = cy[k], .peak = peak, .slope = peak / r });
                taken = taken + q;
            }
            if (!(taken < target)) break;
        }
        return cones.items;
    }
};

/// Compile a set of named roots for a planet (convenience wrapper).
pub fn compile(a: std.mem.Allocator, data: *const sa_data.Data, planet: *const sa_data.Planet, map_seed: u32, controls: Controls, names: []const []const u8, err_out: ?*[]const u8) CompileError!Program {
    const c = try a.create(Compiler);
    c.* = try Compiler.init(a, data, planet, map_seed, controls);
    const roots = try a.alloc(VId, names.len);
    for (names, 0..) |nm, i| {
        roots[i] = c.root(nm) catch |e| {
            if (err_out) |eo| eo.* = c.errorMessage();
            return e;
        };
    }
    return c.finish(roots);
}
