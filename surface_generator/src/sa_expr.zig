//! Factorio noise-expression DSL evaluator for the Space Age planet surfaces.
//!
//! The per-surface closure files (sa-data/surfaces/<planet>.json) hold every
//! named expression/function the planet's property expressions reference,
//! self-contained except for the engine native noise ops (noise.zig) and a
//! small set of runtime scalars (x, y, map_seed, control:name:field ...).
//! This module lexes/parses each expression once into a node tree and
//! evaluates it per (x, y, seed, controls) with f32 arithmetic matching the
//! engine's compiled noise-program semantics.
//!
//! DSL grammar (subset actually used by the SA data):
//!   expr    := or
//!   or      := and ("or" and)*
//!   and     := not ("and" not)*
//!   not     := "not" not | cmp
//!   cmp     := add (("=="|"!="|"<"|">"|"<="|">=") add)*   (result 1.0/0.0)
//!   add     := mul (("+"|"-") mul)*
//!   mul     := pow (("*"|"/"|"%") pow)*
//!   pow     := unary ("^" pow)?
//!   unary   := "-" unary | postfix
//!   postfix := atom | atom "(" args ")" | atom "{" k=v,... "}"
//!   atom    := number | string | identifier[:...] | "(" expr ")"
//!
//! Table-style calls pass named args; paren calls pass positional args bound
//! to the callee's parameter list in order (engine semantics). Bare
//! identifiers resolve to (in order): local bindings, runtime scalars,
//! `control:` values, then closure names (other expressions/functions) and
//! native ops — handled at eval time through an environment chain.

const std = @import("std");
const json = @import("sa_json.zig");
const noise = @import("noise.zig");
const rng = @import("rng.zig");

// ---------------------------------------------------------------------------
// Nodes
// ---------------------------------------------------------------------------

pub const Op = enum {
    add,
    sub,
    mul,
    div,
    mod,
    pow_op,
    eq,
    ne,
    lt,
    gt,
    le,
    ge,
    and_op,
    or_op,
    neg,
    not_op,
};

pub const Node = struct {
    id: u32 = 0,
    kind: Kind,

    pub const Kind = union(enum) {
        lit: f64,
        str: []const u8, // string literal (seed names, distance types, var() names)
        name: []const u8, // bare identifier incl. control:...
        bin: struct { op: Op, l: *Node, r: *Node },
        un: struct { op: Op, x: *Node },
        call: struct {
            name: []const u8,
            // named (table-style) args, then positional ones appended with
            // name == "" in order
            args: []const Arg,
        },
        // reference to a closure expression by name (evaluated lazily)
        ref: []const u8,
    };

    pub const Arg = struct { name: []const u8, value: *Node };
};

// ---------------------------------------------------------------------------
// Lexer
// ---------------------------------------------------------------------------

const Tok = union(enum) {
    num: f64,
    str: []const u8,
    ident: []const u8, // includes colon suffixes (control:foo:size)
    lparen,
    rparen,
    lbrace,
    rbrace,
    comma,
    eq, // = (named-arg separator / equality in data uses ==)
    op: Op,
    eof,
};

const Lexer = struct {
    s: []const u8,
    i: usize = 0,

    fn peek(self: *Lexer) ?u8 {
        if (self.i >= self.s.len) return null;
        return self.s[self.i];
    }

    fn skipWs(self: *Lexer) void {
        while (self.i < self.s.len) : (self.i += 1) {
            switch (self.s[self.i]) {
                ' ', '\t', '\r', '\n' => {},
                else => break,
            }
        }
    }

    fn next(self: *Lexer) error{ LexError }!Tok {
        self.skipWs();
        const start = self.i;
        if (self.i >= self.s.len) return .eof;
        const c = self.s[self.i];
        if (std.ascii.isDigit(c) or c == '.') return self.lexNumber();
        if (c == '\'' or c == '"') return .{ .str = try self.lexString() };
        if (std.ascii.isAlphabetic(c) or c == '_') return self.lexIdent();
        self.i += 1;
        return switch (c) {
            '(' => .lparen,
            ')' => .rparen,
            '{' => .lbrace,
            '}' => .rbrace,
            ',' => .comma,
            '=' => blk: {
                if (self.peek() == '=') {
                    self.i += 1;
                    break :blk .{ .op = .eq };
                }
                break :blk .eq;
            },
            '+' => .{ .op = .add },
            '-' => .{ .op = .sub },
            '*' => .{ .op = .mul },
            '/' => .{ .op = .div },
            '%' => .{ .op = .mod },
            '^' => .{ .op = .pow_op },
            '!' => blk: {
                if (self.peek() == '=') {
                    self.i += 1;
                    break :blk .{ .op = .ne };
                }
                break :blk .{ .op = .not_op };
            },
            '<' => blk: {
                if (self.peek() == '=') {
                    self.i += 1;
                    break :blk .{ .op = .le };
                }
                break :blk .{ .op = .lt };
            },
            '>' => blk: {
                if (self.peek() == '=') {
                    self.i += 1;
                    break :blk .{ .op = .ge };
                }
                break :blk .{ .op = .gt };
            },
            '&' => blk: {
                if (self.peek() == '&') {
                    self.i += 1;
                    break :blk .{ .op = .and_op };
                }
                return error.LexError;
            },
            '|' => blk: {
                if (self.peek() == '|') {
                    self.i += 1;
                    break :blk .{ .op = .or_op };
                }
                return error.LexError;
            },
            else => {
                _ = start;
                return error.LexError;
            },
        };
    }

    fn lexNumber(self: *Lexer) error{LexError}!Tok {
        const start = self.i;
        if (self.peek() == '.') {
            // leading '.5' style — rare; support via lookahead
            if (self.i + 1 >= self.s.len or !std.ascii.isDigit(self.s[self.i + 1])) {
                return error.LexError;
            }
        }
        while (self.i < self.s.len and std.ascii.isDigit(self.s[self.i])) : (self.i += 1) {}
        if (self.i < self.s.len and self.s[self.i] == '.') {
            self.i += 1;
            while (self.i < self.s.len and std.ascii.isDigit(self.s[self.i])) : (self.i += 1) {}
        }
        if (self.i < self.s.len and (self.s[self.i] == 'e' or self.s[self.i] == 'E')) {
            const save = self.i;
            self.i += 1;
            if (self.i < self.s.len and (self.s[self.i] == '+' or self.s[self.i] == '-')) self.i += 1;
            if (self.i < self.s.len and std.ascii.isDigit(self.s[self.i])) {
                while (self.i < self.s.len and std.ascii.isDigit(self.s[self.i])) : (self.i += 1) {}
            } else {
                self.i = save;
            }
        }
        const text = self.s[start..self.i];
        return .{ .num = std.fmt.parseFloat(f64, text) catch return error.LexError };
    }

    fn lexString(self: *Lexer) error{LexError}![]const u8 {
        const quote = self.s[self.i];
        self.i += 1;
        const start = self.i;
        while (self.i < self.s.len and self.s[self.i] != quote) : (self.i += 1) {}
        if (self.i >= self.s.len) return error.LexError;
        const out = self.s[start..self.i];
        self.i += 1;
        return out;
    }

    fn lexIdent(self: *Lexer) error{LexError}!Tok {
        const start = self.i;
        self.i += 1;
        while (self.i < self.s.len) : (self.i += 1) {
            const c = self.s[self.i];
            if (std.ascii.isAlphanumeric(c) or c == '_' or c == ':' or c == '-') continue;
            break;
        }
        const ident = self.s[start..self.i];
        // word operators
        if (std.mem.eql(u8, ident, "and")) return .{ .op = .and_op };
        if (std.mem.eql(u8, ident, "or")) return .{ .op = .or_op };
        if (std.mem.eql(u8, ident, "not")) return .{ .op = .not_op };
        return .{ .ident = ident };
    }
};

// ---------------------------------------------------------------------------
// Parser
// ---------------------------------------------------------------------------

const ParseContext = struct {
    a: std.mem.Allocator,
    tokens: std.ArrayList(Tok),
    ti: usize = 0,
    nodes: std.ArrayList(*Node) = undefined, // for numbering

    fn cur(self: *ParseContext) Tok {
        if (self.ti >= self.tokens.items.len) return .eof;
        return self.tokens.items[self.ti];
    }

    fn bump(self: *ParseContext) void {
        if (self.ti < self.tokens.items.len) self.ti += 1;
    }

    fn mk(self: *ParseContext, kind: Node.Kind) error{OutOfMemory}!*Node {
        const n = try self.a.create(Node);
        n.* = .{ .kind = kind };
        try self.nodes.append(self.a, n);
        n.id = @intCast(self.nodes.items.len - 1);
        return n;
    }
};

const ParseError = error{ ParseError, OutOfMemory };

pub const Compiled = struct {
    root: *Node,
    arena: std.mem.Allocator, // owns root (caller's arena)
};

/// Parse a single expression string into a node tree. `arena` must outlive
/// evaluation.
/// Build a literal node (used for numeric expression entries in the data).
pub fn makeLit(arena: std.mem.Allocator, v: f64) error{OutOfMemory}!*Node {
    const n = try arena.create(Node);
    n.* = .{ .id = 0, .kind = .{ .lit = v } };
    return n;
}

pub fn parseExpr(arena: std.mem.Allocator, src: []const u8) ParseError!*Node {
    var lex = Lexer{ .s = src };
    var toks: std.ArrayList(Tok) = .empty;
    while (true) {
        const t = lex.next() catch return error.ParseError;
        if (t == .eof) break;
        try toks.append(arena, t);
    }
    var p = ParseContext{ .a = arena, .tokens = toks };
    p.nodes = .empty;
    const node = try parseOr(&p);
    if (p.cur() != .eof) return error.ParseError;
    return node;
}

fn parseOr(self: *ParseContext) ParseError!*Node {
    var l = try parseAnd(self);
    while (self.cur() == .op and self.cur().op == .or_op) {
        self.bump();
        const r = try parseAnd(self);
        l = try self.mk(.{ .bin = .{ .op = .or_op, .l = l, .r = r } });
    }
    return l;
}

fn parseAnd(self: *ParseContext) ParseError!*Node {
    var l = try parseNot(self);
    while (self.cur() == .op and self.cur().op == .and_op) {
        self.bump();
        const r = try parseNot(self);
        l = try self.mk(.{ .bin = .{ .op = .and_op, .l = l, .r = r } });
    }
    return l;
}

fn parseNot(self: *ParseContext) ParseError!*Node {
    if (self.cur() == .op and self.cur().op == .not_op) {
        self.bump();
        const x = try parseNot(self);
        return self.mk(.{ .un = .{ .op = .not_op, .x = x } });
    }
    return parseCmp(self);
}

fn cmpOp(t: Tok) ?Op {
    if (t != .op) return null;
    return switch (t.op) {
        .eq, .ne, .lt, .gt, .le, .ge => t.op,
        else => null,
    };
}

fn parseCmp(self: *ParseContext) ParseError!*Node {
    var l = try parseAdd(self);
    while (cmpOp(self.cur())) |op| {
        self.bump();
        const r = try parseAdd(self);
        l = try self.mk(.{ .bin = .{ .op = op, .l = l, .r = r } });
    }
    return l;
}

fn parseAdd(self: *ParseContext) ParseError!*Node {
    var l = try parseMul(self);
    while (self.cur() == .op and (self.cur().op == .add or self.cur().op == .sub)) {
        const op = self.cur().op;
        self.bump();
        const r = try parseMul(self);
        l = try self.mk(.{ .bin = .{ .op = op, .l = l, .r = r } });
    }
    return l;
}

fn parseMul(self: *ParseContext) ParseError!*Node {
    var l = try parsePow(self);
    while (self.cur() == .op and (self.cur().op == .mul or self.cur().op == .div or self.cur().op == .mod)) {
        const op = self.cur().op;
        self.bump();
        const r = try parsePow(self);
        l = try self.mk(.{ .bin = .{ .op = op, .l = l, .r = r } });
    }
    return l;
}

fn parsePow(self: *ParseContext) ParseError!*Node {
    const l = try parseUnary(self);
    if (self.cur() == .op and self.cur().op == .pow_op) {
        self.bump();
        const r = try parsePow(self); // right-assoc
        return self.mk(.{ .bin = .{ .op = .pow_op, .l = l, .r = r } });
    }
    return l;
}

fn parseUnary(self: *ParseContext) ParseError!*Node {
    if (self.cur() == .op and self.cur().op == .sub) {
        self.bump();
        const x = try parseUnary(self);
        return self.mk(.{ .un = .{ .op = .neg, .x = x } });
    }
    return parsePostfix(self);
}

fn parsePostfix(self: *ParseContext) ParseError!*Node {
    const atom = try parseAtom(self);
    if (self.cur() == .lparen or self.cur() == .lbrace) {
        if (atom.kind != .name) return error.ParseError;
        const name = atom.kind.name;
        if (self.cur() == .lparen) {
            self.bump();
            var args: std.ArrayList(Node.Arg) = .empty;
            while (self.cur() != .rparen) {
                const v = try parseOr(self);
                try args.append(self.a, .{ .name = "", .value = v });
                if (self.cur() == .comma) {
                    self.bump();
                } else break;
            }
            if (self.cur() != .rparen) return error.ParseError;
            self.bump();
            return self.mk(.{ .call = .{ .name = name, .args = args.items } });
        } else {
            self.bump();
            var args: std.ArrayList(Node.Arg) = .empty;
            while (self.cur() != .rbrace) {
                // key = value  OR positional value
                if (self.cur() == .ident and self.ti + 1 < self.tokens.items.len and self.tokens.items[self.ti + 1] == .eq) {
                    const key = self.cur().ident;
                    self.bump();
                    self.bump(); // '='
                    const v = try parseOr(self);
                    try args.append(self.a, .{ .name = key, .value = v });
                } else {
                    const v = try parseOr(self);
                    try args.append(self.a, .{ .name = "", .value = v });
                }
                if (self.cur() == .comma) {
                    self.bump();
                } else break;
            }
            if (self.cur() != .rbrace) return error.ParseError;
            self.bump();
            return self.mk(.{ .call = .{ .name = name, .args = args.items } });
        }
    }
    return atom;
}

fn parseAtom(self: *ParseContext) ParseError!*Node {
    const t = self.cur();
    switch (t) {
        .num => {
            self.bump();
            return self.mk(.{ .lit = t.num });
        },
        .str => {
            self.bump();
            return self.mk(.{ .str = t.str });
        },
        .ident => {
            self.bump();
            return self.mk(.{ .name = t.ident });
        },
        .lparen => {
            self.bump();
            const e = try parseOr(self);
            if (self.cur() != .rparen) return error.ParseError;
            self.bump();
            return e;
        },
        else => return error.ParseError,
    }
}

// ---------------------------------------------------------------------------
// Evaluation
// ---------------------------------------------------------------------------

pub const EvalError = error{ UnknownName, UnknownNative, BadCall, OutOfMemory, Unsupported, DivideByZero };

/// Scalars that the engine exposes to noise expressions per evaluation.
pub const Scalars = struct {
    x: f64 = 0,
    y: f64 = 0,
    seed: u32 = 0,
    x_from_start: f64 = 0, // distance from the starting-area centre
    y_from_start: f64 = 0,
    map_seed_normalized: f64 = 0, // derived; filled by the loader when known
    map_seed_small: f64 = 0,
};

/// control:name:field resolver. Default: every control = 1.
pub const Controls = struct {
    ctx: *const anyopaque = undefined,
    lookup: *const fn (ctx: *const anyopaque, name: []const u8, field: []const u8) f64,

    pub fn value(self: Controls, name: []const u8, field: []const u8) f64 {
        return self.lookup(self.ctx, name, field);
    }
};

/// A parsed closure (one planet surface). Entries are expressions (no
/// parameters) and helper functions (parameterized).
pub const Closure = struct {
    a: std.mem.Allocator,
    entries: []const Entry,

    pub const Entry = struct {
        name: []const u8,
        is_function: bool,
        params: []const []const u8,
        locals: []const Local,
        root: *Node,
    };

    pub const Local = struct { name: []const u8, node: *Node };

    /// find an entry by name (linear; closures are small)
    pub fn find(self: *const Closure, name: []const u8) ?*const Entry {
        for (self.entries) |*e| {
            if (std.mem.eql(u8, e.name, name)) return e;
        }
        return null;
    }
};

/// Bindings stack: locals/parameters of the entry currently being evaluated.
/// Each stack item maps one entry's bindings (params + locals) that shadow
/// lower frames by name.
const Bindings = struct {
    names: []const []const u8,
    nodes: []const *Node,
    parent: ?*const Bindings,

    fn lookup(self: ?*const Bindings, name: []const u8) ?*Node {
        var b = self;
        while (b) |bb| {
            for (bb.names, bb.nodes) |n, nd| {
                if (std.mem.eql(u8, n, name)) return nd;
            }
            b = bb.parent;
        }
        return null;
    }
};

const EvalCtx = struct {
    closure: *const Closure,
    scalars: Scalars,
    controls: Controls,
    arena: std.mem.Allocator,
};

fn rf32(v: f64) f64 {
    return @as(f32, @floatCast(v));
}

fn ctrlValue(name: []const u8, c: Controls) f64 {
    // control:name:field
    const rest = if (std.mem.startsWith(u8, name, "control:")) name["control:".len..] else name;
    const colon = std.mem.indexOfScalar(u8, rest, ':') orelse return c.value("", "");
    return c.value(rest[0..colon], rest[colon + 1 ..]);
}

pub fn eval(closure: *const Closure, s: Scalars, controls: Controls, arena: std.mem.Allocator, root: *const Node) EvalError!f64 {
    var ctx = EvalCtx{ .closure = closure, .scalars = s, .controls = controls, .arena = arena };
    return evalNode(&ctx, null, root);
}

pub fn evalRoot(closure: *const Closure, s: Scalars, controls: Controls, arena: std.mem.Allocator, name: []const u8) EvalError!f64 {
    const e = closure.find(name) orelse return error.UnknownName;
    if (e.is_function) return error.BadCall;
    return eval(closure, s, controls, arena, e.root);
}

fn bindEntry(entry: *const Closure.Entry, args: []const Node.Arg, ctx: *EvalCtx, bindings: ?*const Bindings) EvalError!?*const Bindings {
    // bind params (by name or positionally) + locals
    const nParams = entry.params.len;
    var names = try ctx.arena.alloc([]const u8, nParams + entry.locals.len);
    var nodes = try ctx.arena.alloc(*Node, nParams + entry.locals.len);
    // params: match table-style args by name; positional args fill the
    // unnamed params in order
    var nextPos: usize = 0;
    for (entry.params, 0..) |pname, i| {
        names[i] = pname;
        nodes[i] = undefined;
        var found: ?*Node = null;
        for (args) |a| {
            if (a.name.len > 0 and std.mem.eql(u8, a.name, pname)) {
                found = a.value;
                break;
            }
        }
        if (found == null) {
            while (nextPos < args.len and args[nextPos].name.len > 0) nextPos += 1;
            if (nextPos < args.len) {
                found = args[nextPos].value;
                nextPos += 1;
            }
        }
        if (found == null) return error.BadCall;
        nodes[i] = found.?;
    }
    for (entry.locals, 0..) |loc, k| {
        names[nParams + k] = loc.name;
        nodes[nParams + k] = loc.node;
    }
    const frame = try ctx.arena.create(Bindings);
    frame.* = .{ .names = names, .nodes = nodes, .parent = bindings };
    return frame;
}

fn evalNode(ctx: *EvalCtx, bindings: ?*const Bindings, node: *const Node) EvalError!f64 {
    switch (node.kind) {
        .lit => return rf32(node.kind.lit),
        .str => return error.BadCall, // bare string as value is invalid
        .name => return resolveName(ctx, bindings, node.kind.name),
        .bin => {
            const l = try evalNode(ctx, bindings, node.kind.bin.l);
            const r = try evalNode(ctx, bindings, node.kind.bin.r);
            return switch (node.kind.bin.op) {
                .add => rf32(l + r),
                .sub => rf32(l - r),
                .mul => rf32(l * r),
                .div => rf32(l / r),
                .mod => rf32(@mod(l, r)),
                .pow_op => powF(l, r),
                .eq => if (l == r) 1 else 0,
                .ne => if (l != r) 1 else 0,
                .lt => if (l < r) 1 else 0,
                .gt => if (l > r) 1 else 0,
                .le => if (l <= r) 1 else 0,
                .ge => if (l >= r) 1 else 0,
                .and_op => if ((l != 0) and (r != 0)) 1 else 0,
                .or_op => if ((l != 0) or (r != 0)) 1 else 0,
                else => unreachable,
            };
        },
        .un => {
            const x = try evalNode(ctx, bindings, node.kind.un.x);
            return switch (node.kind.un.op) {
                .neg => -x,
                .not_op => if (x == 0) 1 else 0,
                else => unreachable,
            };
        },
        .call => return evalCall(ctx, bindings, node.kind.call.name, node.kind.call.args),
        .ref => unreachable,
    }
}

/// pow in the engine = exp2f(y * log2f(x))-style? calibrated against the game
/// in the natives glue; placeholder uses double pow then f32 (to be verified).
fn powF(l: f64, r: f64) f64 {
    if (r == 0.5) return rf32(@sqrt(l));
    return rf32(std.math.pow(f64, @abs(l), r) * @as(f64, if (l < 0) -1 else 1));
}

fn resolveName(ctx: *EvalCtx, bindings: ?*const Bindings, name: []const u8) EvalError!f64 {
    // control:...
    if (std.mem.startsWith(u8, name, "control:")) return rf32(ctrlValue(name, ctx.controls));
    // local/param binding
    if (bindings) |b| {
        if (b.lookup(name)) |nd| return evalNode(ctx, b, nd);
    }
    // runtime scalars
    if (std.mem.eql(u8, name, "x")) return ctx.scalars.x;
    if (std.mem.eql(u8, name, "y")) return ctx.scalars.y;
    if (std.mem.eql(u8, name, "map_seed")) return @floatFromInt(ctx.scalars.seed);
    if (std.mem.eql(u8, name, "x_from_start")) return ctx.scalars.x_from_start;
    if (std.mem.eql(u8, name, "y_from_start")) return ctx.scalars.y_from_start;
    if (std.mem.eql(u8, name, "map_seed_normalized")) return ctx.scalars.map_seed_normalized;
    if (std.mem.eql(u8, name, "map_seed_small")) return ctx.scalars.map_seed_small;
    if (std.mem.eql(u8, name, "pi")) return std.math.pi;
    if (std.mem.eql(u8, name, "e")) return std.math.e;
    // global closure reference (expression) — evaluate its root under its own
    // frame; functions are only callable, but treat a bare ref to a function
    // (zero args, parameterless bodies) defensively as its root too.
    if (ctx.closure.find(name)) |e| {
        const frame = if (e.is_function) try bindEntry(e, &.{}, ctx, bindings) else null;
        return evalNode(ctx, frame orelse bindings, e.root);
    }
    std.debug.print("unknown name: {s}\n", .{name});
    return error.UnknownName;
}

fn evalCall(ctx: *EvalCtx, bindings: ?*const Bindings, name: []const u8, args: []const Node.Arg) EvalError!f64 {
    // data function (parameterized closure entry)
    if (ctx.closure.find(name)) |e| {
        if (e.is_function) {
            const frame = bindEntry(e, args, ctx, bindings) catch |err| {
                std.debug.print("bind {s}: {s}\n", .{ name, @errorName(err) });
                return err;
            };
            return evalNode(ctx, frame, e.root) catch |err| {
                std.debug.print("datafn {s}: {s}\n", .{ name, @errorName(err) });
                return err;
            };
        }
    }
    // builtin math
    return callNative(ctx, bindings, name, args) catch |err| {
        std.debug.print("native {s}: {s}\n", .{ name, @errorName(err) });
        return err;
    };
}

fn argN(ctx: *EvalCtx, bindings: ?*const Bindings, args: []const Node.Arg, key: []const u8, idx: usize) EvalError!f64 {
    for (args, 0..) |a, i| {
        if (a.name.len > 0) {
            if (std.mem.eql(u8, a.name, key)) return evalNode(ctx, bindings, a.value);
        } else if (i == idx) {
            return evalNode(ctx, bindings, a.value);
        }
    }
    return error.BadCall;
}

fn argOr(ctx: *EvalCtx, bindings: ?*const Bindings, args: []const Node.Arg, key: []const u8, idx: usize, def: f64) EvalError!f64 {
    return argN(ctx, bindings, args, key, idx) catch |e| if (e == error.BadCall) def else return e;
}

fn argStr(args: []const Node.Arg, key: []const u8) ?[]const u8 {
    for (args) |arg| {
        if (std.mem.eql(u8, arg.name, key) and arg.value.kind == .str) return arg.value.kind.str;
    }
    return null;
}

fn callNative(ctx: *EvalCtx, bindings: ?*const Bindings, name: []const u8, args: []const Node.Arg) EvalError!f64 {
    if (std.mem.eql(u8, name, "min")) return @min(try argN(ctx, bindings, args, "", 0), try argN(ctx, bindings, args, "", 1));
    if (std.mem.eql(u8, name, "max")) return @max(try argN(ctx, bindings, args, "", 0), try argN(ctx, bindings, args, "", 1));
    if (std.mem.eql(u8, name, "abs")) return @abs(try argN(ctx, bindings, args, "", 0));
    if (std.mem.eql(u8, name, "clamp")) {
        const v = try argN(ctx, bindings, args, "", 0);
        const lo = try argN(ctx, bindings, args, "", 1);
        const hi = try argN(ctx, bindings, args, "", 2);
        return @min(@max(v, lo), hi);
    }
    if (std.mem.eql(u8, name, "if")) {
        const c = try argN(ctx, bindings, args, "", 0);
        return if (c >= 0) try argN(ctx, bindings, args, "", 1) else try argN(ctx, bindings, args, "", 2);
    }
    if (std.mem.eql(u8, name, "sin")) return rf32(@sin(try argN(ctx, bindings, args, "", 0)));
    if (std.mem.eql(u8, name, "cos")) return rf32(@cos(try argN(ctx, bindings, args, "", 0)));
    if (std.mem.eql(u8, name, "sqrt")) return rf32(@sqrt(@abs(try argN(ctx, bindings, args, "", 0))));
    if (std.mem.eql(u8, name, "floor")) return @floor(try argN(ctx, bindings, args, "", 0));
    if (std.mem.eql(u8, name, "ceil")) return @ceil(try argN(ctx, bindings, args, "", 0));
    if (std.mem.eql(u8, name, "pow")) return powF(try argN(ctx, bindings, args, "", 0), try argN(ctx, bindings, args, "", 1));
    if (std.mem.eql(u8, name, "exp")) return rf32(@exp(try argN(ctx, bindings, args, "", 0)));
    if (std.mem.eql(u8, name, "log2")) return noiseFastLog2(try argN(ctx, bindings, args, "", 0));
    if (std.mem.eql(u8, name, "var")) {
        const target = argStr(args, "") orelse return error.BadCall;
        if (std.mem.startsWith(u8, target, "control:")) return rf32(ctrlValue(target, ctx.controls));
        // var('name') = named expression/function reference by string
        return resolveName(ctx, bindings, target);
    }
    if (std.mem.eql(u8, name, "rand") or std.mem.eql(u8, name, "random")) {
        return error.Unsupported; // per-tile RNG not needed for property exprs
    }
    if (std.mem.eql(u8, name, "lerp")) {
        // core data helper: lerp(a,b,alpha) = a + (b - a) * alpha
        const av = try argN(ctx, bindings, args, "", 0);
        const bv = try argN(ctx, bindings, args, "", 1);
        const al = try argN(ctx, bindings, args, "", 2);
        return rf32(av + rf32(bv - av) * al);
    }
    return natives(ctx, bindings, name, args);
}

// ---------------------------------------------------------------------------
// Natives glue into noise.zig — arithmetic matches the engine f32 semantics;
// native noise ops take their (already f32-rounded) scalar/string params.
// ---------------------------------------------------------------------------

const NativeSeed = struct { seed0: u32 = 0, seed1: u32 = 0 };

fn noiseFastLog2(x: f64) f64 {
    return noise.preciseLog2(@floatCast(x));
}

fn nativeSeed0(ctx: *EvalCtx, bindings: ?*const Bindings, args: []const Node.Arg) EvalError!u32 {
    const v = try argN(ctx, bindings, args, "seed0", 0);
    return @intFromFloat(@round(v));
}

fn nativeSeed1(ctx: *EvalCtx, bindings: ?*const Bindings, args: []const Node.Arg) EvalError!u32 {
    if (argStr(args, "seed1")) |s| return std.hash.Crc32.hash(s);
    const v = try argN(ctx, bindings, args, "seed1", 1);
    return @intFromFloat(@round(v));
}

fn natives(ctx: *EvalCtx, bindings: ?*const Bindings, name: []const u8, args: []const Node.Arg) EvalError!f64 {
    // ---- multioctave_noise / basis / quick / variable-persistence ----
    if (std.mem.eql(u8, name, "basis_noise")) {
        const x = try argN(ctx, bindings, args, "x", 0);
        const y = try argN(ctx, bindings, args, "y", 1);
        const s0 = try nativeSeed0(ctx, bindings, args);
        const s1 = try nativeSeed1(ctx, bindings, args);
        const is = try argN(ctx, bindings, args, "input_scale", 2);
        const os = try argOr(ctx, bindings, args, "output_scale", 3, 1.0);
        const gen = try ctx.arena.create(noise.BasisNoiseGen);
        gen.* = noise.BasisNoiseGen.init(s0, s1);
        const ox = try argOr(ctx, bindings, args, "offset_x", 4, 0.0);
        const oy = try argOr(ctx, bindings, args, "offset_y", 5, 0.0);
        return gen.evalOffset(x, y, is, os, ox, oy);
    }
    if (std.mem.eql(u8, name, "multioctave_noise")) {
        const x = try argN(ctx, bindings, args, "x", 0);
        const y = try argN(ctx, bindings, args, "y", 1);
        const s0 = try nativeSeed0(ctx, bindings, args);
        const s1 = try nativeSeed1(ctx, bindings, args);
        const oct = try argN(ctx, bindings, args, "octaves", 2);
        const per = try argN(ctx, bindings, args, "persistence", 3);
        const is = try argN(ctx, bindings, args, "input_scale", 4);
        const os = try argOr(ctx, bindings, args, "output_scale", 5, 1.0);
        const ox = try argOr(ctx, bindings, args, "offset_x", 6, 0.0);
        const oy = try argOr(ctx, bindings, args, "offset_y", 7, 0.0);
        const gen = try ctx.arena.create(noise.BasisNoiseGen);
        gen.* = noise.BasisNoiseGen.init(s0, s1);
        return noise.multioctaveNoiseOffset(gen, x, y, @intFromFloat(@round(oct)), per, is, os, ox, oy);
    }
    if (std.mem.eql(u8, name, "quick_multioctave_noise")) {
        const x = try argN(ctx, bindings, args, "x", 0);
        const y = try argN(ctx, bindings, args, "y", 1);
        const s0 = try nativeSeed0(ctx, bindings, args);
        const s1 = try nativeSeed1(ctx, bindings, args);
        const oct = try argN(ctx, bindings, args, "octaves", 2);
        const per = try argN(ctx, bindings, args, "persistence", 3);
        const is = try argN(ctx, bindings, args, "input_scale", 4);
        const os = try argN(ctx, bindings, args, "output_scale", 5);
        return quickMultioctave(ctx, x, y, s0, s1, oct, per, is, os);
    }
    if (std.mem.eql(u8, name, "variable_persistence_multioctave_noise")) {
        const x = try argN(ctx, bindings, args, "x", 0);
        const y = try argN(ctx, bindings, args, "y", 1);
        const s0 = try nativeSeed0(ctx, bindings, args);
        const s1 = try nativeSeed1(ctx, bindings, args);
        const oct = try argN(ctx, bindings, args, "octaves", 2);
        const per = try argN(ctx, bindings, args, "persistence", 3);
        const is = try argN(ctx, bindings, args, "input_scale", 4);
        const os = try argN(ctx, bindings, args, "output_scale", 5);
        const gen = try ctx.arena.create(noise.BasisNoiseGen);
        gen.* = noise.BasisNoiseGen.init(s0, s1);
        return noise.variablePersistence(gen, x, y, @intFromFloat(@round(oct)), is, os, 0, 0, per);
    }
    // ---- random_penalty ----
    if (std.mem.eql(u8, name, "random_penalty")) {
        const x = try argN(ctx, bindings, args, "x", 0);
        const y = try argN(ctx, bindings, args, "y", 1);
        const src = try argN(ctx, bindings, args, "source", 2);
        const amp = try argN(ctx, bindings, args, "amplitude", 3);
        return noise.randomPenalty(x, y, src, amp);
    }
    // ---- voronoi ----
    if (std.mem.eql(u8, name, "voronoi_cell_id") or std.mem.eql(u8, name, "voronoi_spot_noise") or
        std.mem.eql(u8, name, "voronoi_facet_noise") or std.mem.eql(u8, name, "voronoi_pyramid_noise"))
    {
        const x = try argN(ctx, bindings, args, "x", 0);
        const y = try argN(ctx, bindings, args, "y", 1);
        const s0 = try nativeSeed0(ctx, bindings, args);
        const s1 = try nativeSeed1(ctx, bindings, args);
        const grid = try argN(ctx, bindings, args, "grid_size", 2);
        const jit = try argN(ctx, bindings, args, "jitter", 3);
        const dt: noise.VoronoiDistanceType = blk: {
            if (argStr(args, "distance_type")) |s| {
                if (std.mem.eql(u8, s, "euclidean")) break :blk .euclidean;
                if (std.mem.eql(u8, s, "manhattan")) break :blk .manhattan;
                if (std.mem.eql(u8, s, "chebyshev")) break :blk .chebyshev;
                if (std.mem.eql(u8, s, "minkowski3")) break :blk .minkowski3;
            }
            const d = try argN(ctx, bindings, args, "distance_type", 4);
            break :blk @enumFromInt(@as(u8, @intFromFloat(@round(d))));
        };
        const v = noise.VoronoiNoise.init(s0, s1, @intFromFloat(@round(grid)), dt, @floatCast(jit));
        const r = v.evalAt(x, y);
        if (std.mem.eql(u8, name, "voronoi_cell_id")) return r.cell_id;
        if (std.mem.eql(u8, name, "voronoi_spot_noise")) return r.nearest;
        if (std.mem.eql(u8, name, "voronoi_facet_noise")) return r.gap;
        return r.pyramid;
    }
    // ---- terrace ----
    if (std.mem.eql(u8, name, "terrace")) {
        const value = try argN(ctx, bindings, args, "value", 0);
        const off = try argN(ctx, bindings, args, "offset", 1);
        const width = try argN(ctx, bindings, args, "width", 2);
        const strength = try argN(ctx, bindings, args, "strength", 3);
        return noise.terrace(value, @floatCast(off), @floatCast(width), @floatCast(strength));
    }
    std.debug.print("unhandled native {s}\n", .{name});
    return error.UnknownNative;
}

fn quickMultioctave(ctx: *EvalCtx, x: f64, y: f64, s0: u32, s1: u32, octaves: f64, persistence: f64, input_scale: f64, output_scale: f64) EvalError!f64 {
    // quick_multioctave_noise: one basis gen per octave (seed0+k, seed1); the
    // per-octave coords follow terrain.qmoGens' calibrated scheme (see
    // noise-system notes + terrain.zig). Approximation of the engine op for
    // now: matches noise.zig's multioctave offset pattern but with the
    // octave_input/output scale multipliers the SA data passes are fixed at
    // the engine defaults (0.5/0.5) inside noise.zig multioctave.
    _ = ctx;
    const gen = noise.BasisNoiseGen.init(s0, s1);
    return noise.multioctaveNoisePrebuilt(&gen, x, y, @intFromFloat(@round(octaves)), persistence, input_scale, output_scale);
}
