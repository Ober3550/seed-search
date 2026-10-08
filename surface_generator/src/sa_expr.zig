//! Factorio noise-expression DSL parser.
//!
//! Lexes/parses one expression string (a noise-expression / noise-function
//! body, a local expression, or an autoplace probability expression) into a
//! Node tree. sa_program.zig lowers those trees into a compiled program.
//!
//! Grammar (operator precedence as in Lua, which the DSL mirrors):
//!   expr    := or
//!   or      := and ("or" and)*
//!   and     := not ("and" not)*
//!   not     := "not" not | cmp
//!   cmp     := add (("=="|"!="|"<"|">"|"<="|">=") add)*   (result 1.0/0.0)
//!   add     := mul (("+"|"-") mul)*
//!   mul     := unary (("*"|"/"|"%") unary)*
//!   unary   := "-" unary | pow
//!   pow     := postfix ("^" unary)?                        (right assoc)
//!   postfix := atom | atom "(" args ")" | atom "{" k=v,... "}"
//!   atom    := number | string | identifier[:...] | "(" expr ")"
//!
//! Table-style calls pass named args; paren calls pass positional args bound
//! to the callee's parameter list in order.

const std = @import("std");
const builtin = @import("builtin");

/// stderr debug output is unavailable (and pulls in std.Io.Threaded, which
/// does not compile freestanding) on the wasm target — no-op there.
const dbg = struct {
    fn print(comptime fmt: []const u8, args: anytype) void {
        if (builtin.os.tag != .freestanding) std.debug.print(fmt, args);
    }
};

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
    bitand,
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
                break :blk .{ .op = .bitand };
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
            if (std.ascii.isAlphanumeric(c) or c == '_' or c == ':') continue;
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

pub const ParseError = error{ ParseError, OutOfMemory };

/// Build a literal node (numeric expression entries in the data).
pub fn makeLit(arena: std.mem.Allocator, v: f64) error{OutOfMemory}!*Node {
    const n = try arena.create(Node);
    n.* = .{ .id = 0, .kind = .{ .lit = v } };
    return n;
}

fn pfail(self: *ParseContext) ParseError {
    if (builtin.os.tag != .freestanding) {
        const t = self.cur();
        const tag: []const u8 = @tagName(t);
        dbg.print("parse fail at tok {d}: {s}\n", .{ self.ti, tag });
    }
    return error.ParseError;
}

/// Parse a single expression string into a node tree owned by `arena`.
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
    var l = try parseUnary(self);
    while (self.cur() == .op and (self.cur().op == .mul or self.cur().op == .div or self.cur().op == .mod or self.cur().op == .bitand)) {
        const op = self.cur().op;
        self.bump();
        const r = try parseUnary(self);
        l = try self.mk(.{ .bin = .{ .op = op, .l = l, .r = r } });
    }
    return l;
}

fn parseUnary(self: *ParseContext) ParseError!*Node {
    if (self.cur() == .op and self.cur().op == .sub) {
        self.bump();
        const x = try parseUnary(self);
        // fold "-<number>" so negative literals stay exact constants
        if (x.kind == .lit) return self.mk(.{ .lit = -x.kind.lit });
        return self.mk(.{ .un = .{ .op = .neg, .x = x } });
    }
    return parsePow(self);
}

fn parsePow(self: *ParseContext) ParseError!*Node {
    const l = try parsePostfix(self);
    if (self.cur() == .op and self.cur().op == .pow_op) {
        self.bump();
        const r = try parseUnary(self); // right-assoc, binds tighter than unary minus
        return self.mk(.{ .bin = .{ .op = .pow_op, .l = l, .r = r } });
    }
    return l;
}

fn parsePostfix(self: *ParseContext) ParseError!*Node {
    const atom = try parseAtom(self);
    if (self.cur() == .lparen or self.cur() == .lbrace) {
        if (atom.kind != .name) return pfail(self);
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
            if (self.cur() != .rparen) return pfail(self);
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
            if (self.cur() != .rbrace) return pfail(self);
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
            if (self.cur() != .rparen) return pfail(self);
            self.bump();
            return e;
        },
        else => return error.ParseError,
    }
}
