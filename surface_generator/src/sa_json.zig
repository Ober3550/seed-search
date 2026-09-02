//! Minimal JSON reader for the embedded Space-Age surface data files
//! (surface_generator/sa-data/surfaces/<planet>.json, planets.json). The files
//! are small (~12-30 KB each) and structurally simple: objects whose values are
//! objects/strings/numbers/arrays/bools. Written by hand so the WASM/native
//! build needs no third-party JSON and no pre-generation step.
//!
//! API mirrors the data's shape:
//!   - `Object` = ordered map name -> Value
//!   - Value = .object/.string/.number/.bool/.null/.array
//!   - helpers: obj.get("expression").?.string etc.

const std = @import("std");

pub const Value = union(enum) {
    null,
    boolean: bool,
    number: f64,
    string: []const u8,
    array: []const Value,
    object: []const KV, // sorted? no — insertion order kept
};

pub const KV = struct { key: []const u8, value: Value };

pub const Object = []const KV;

pub fn isObject(v: Value) bool {
    return v == .object;
}
pub fn isString(v: Value) bool {
    return v == .string;
}

/// Look up a key in an object value. O(n) — fine for these small files.
pub fn get(obj: Object, key: []const u8) ?Value {
    for (obj) |kv| {
        if (std.mem.eql(u8, kv.key, key)) return kv.value;
    }
    return null;
}

pub const ParseError = error{ InvalidJson, OutOfMemory };

const Parser = struct {
    s: []const u8,
    i: usize = 0,
    a: std.mem.Allocator,
    arena: std.mem.Allocator,

    fn ws(self: *Parser) void {
        while (self.i < self.s.len) : (self.i += 1) {
            switch (self.s[self.i]) {
                ' ', '\t', '\r', '\n' => {},
                else => break,
            }
        }
    }

    fn peek(self: *Parser) ?u8 {
        self.ws();
        if (self.i >= self.s.len) return null;
        return self.s[self.i];
    }

    fn eat(self: *Parser, c: u8) bool {
        self.ws();
        if (self.i < self.s.len and self.s[self.i] == c) {
            self.i += 1;
            return true;
        }
        return false;
    }

    fn value(self: *Parser) ParseError!Value {
        const c = self.peek() orelse return error.InvalidJson;
        return switch (c) {
            '{' => self.obj(),
            '[' => self.arr(),
            '"' => blk: {
                const s = try self.str();
                break :blk .{ .string = s };
            },
            't' => blk: {
                try self.lit("true");
                break :blk .{ .boolean = true };
            },
            'f' => blk: {
                try self.lit("false");
                break :blk .{ .boolean = false };
            },
            'n' => blk: {
                try self.lit("null");
                break :blk .{ .null = {} };
            },
            '-', '0'...'9' => .{ .number = try self.num() },
            else => error.InvalidJson,
        };
    }

    fn lit(self: *Parser, text: []const u8) ParseError!void {
        self.ws();
        if (!std.mem.startsWith(u8, self.s[self.i..], text)) return error.InvalidJson;
        self.i += text.len;
    }

    fn num(self: *Parser) ParseError!f64 {
        self.ws();
        const start = self.i;
        if (self.i < self.s.len and self.s[self.i] == '-') self.i += 1;
        while (self.i < self.s.len and std.ascii.isDigit(self.s[self.i])) : (self.i += 1) {}
        if (self.i < self.s.len and self.s[self.i] == '.') {
            self.i += 1;
            while (self.i < self.s.len and std.ascii.isDigit(self.s[self.i])) : (self.i += 1) {}
        }
        if (self.i < self.s.len and (self.s[self.i] == 'e' or self.s[self.i] == 'E')) {
            self.i += 1;
            if (self.i < self.s.len and (self.s[self.i] == '+' or self.s[self.i] == '-')) self.i += 1;
            while (self.i < self.s.len and std.ascii.isDigit(self.s[self.i])) : (self.i += 1) {}
        }
        const text = self.s[start..self.i];
        return std.fmt.parseFloat(f64, text) catch error.InvalidJson;
    }

    fn str(self: *Parser) ParseError![]const u8 {
        self.ws();
        if (!self.eat('"')) return error.InvalidJson;
        var out: std.ArrayList(u8) = .empty;
        while (true) {
            if (self.i >= self.s.len) return error.InvalidJson;
            const c = self.s[self.i];
            self.i += 1;
            if (c == '"') break;
            if (c == '\\') {
                if (self.i >= self.s.len) return error.InvalidJson;
                const e = self.s[self.i];
                self.i += 1;
                switch (e) {
                    '"' => try out.append(self.arena, '"'),
                    '\\' => try out.append(self.arena, '\\'),
                    '/' => try out.append(self.arena, '/'),
                    'n' => try out.append(self.arena, '\n'),
                    't' => try out.append(self.arena, '\t'),
                    'r' => try out.append(self.arena, '\r'),
                    'b' => try out.append(self.arena, 8),
                    'f' => try out.append(self.arena, 12),
                    'u' => {
                        if (self.i + 4 > self.s.len) return error.InvalidJson;
                        const code = std.fmt.parseInt(u21, self.s[self.i .. self.i + 4], 16) catch return error.InvalidJson;
                        self.i += 4;
                        var buf: [4]u8 = undefined;
                        const n = std.unicode.utf8Encode(code, &buf) catch return error.InvalidJson;
                        try out.appendSlice(self.arena, buf[0..n]);
                    },
                    else => return error.InvalidJson,
                }
            } else {
                try out.append(self.arena, c);
            }
        }
        return out.toOwnedSlice(self.arena);
    }

    fn obj(self: *Parser) ParseError!Value {
        if (!self.eat('{')) return error.InvalidJson;
        var items: std.ArrayList(KV) = .empty;
        if (self.eat('}')) return .{ .object = items.items };
        while (true) {
            const k = try self.str();
            if (!self.eat(':')) return error.InvalidJson;
            const v = try self.value();
            try items.append(self.arena, .{ .key = k, .value = v });
            if (self.eat('}')) break;
            if (!self.eat(',')) return error.InvalidJson;
        }
        return .{ .object = items.items };
    }

    fn arr(self: *Parser) ParseError!Value {
        if (!self.eat('[')) return error.InvalidJson;
        var items: std.ArrayList(Value) = .empty;
        if (self.eat(']')) return .{ .array = items.items };
        while (true) {
            try items.append(self.arena, try self.value());
            if (self.eat(']')) break;
            if (!self.eat(',')) return error.InvalidJson;
        }
        return .{ .array = items.items };
    }
};

/// Parse a JSON document into arena-allocated Values.
pub fn parse(a: std.mem.Allocator, src: []const u8) ParseError!Value {
    var p = Parser{ .s = src, .a = a, .arena = a };
    const v = try p.value();
    p.ws();
    if (p.i != p.s.len) return error.InvalidJson;
    return v;
}

test "parse a small surface-style object" {
    const src =
        \\{"expressions": {"a": {"expression": "x + 1", "type": "noise-expression"},
        \\ "b": {"expression": "control:x:size > 0", "parameters": []}}, "n": 3}
    ;
    var aa = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer aa.deinit();
    const v = try parse(aa.allocator(), src);
    try std.testing.expect(v == .object);
    const root = v.object;
    const exprs = get(root, "expressions").?;
    try std.testing.expect(exprs == .object);
    const a = get(exprs.object, "a").?;
    try std.testing.expectEqualStrings("x + 1", get(a.object, "expression").?.string);
    const n = get(root, "n").?;
    try std.testing.expectEqual(@as(f64, 3), n.number);
    const b = get(exprs.object, "b").?;
    try std.testing.expectEqualStrings("control:x:size > 0", get(b.object, "expression").?.string);
}
