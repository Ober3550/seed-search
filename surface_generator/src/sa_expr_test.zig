const std = @import("std");
const expr = @import("sa_expr.zig");
const json = @import("sa_json.zig");
const data = @import("sa_data.zig");

const Scalars = expr.Scalars;

fn ctrlLookup(_: *const anyopaque, name: []const u8, field: []const u8) f64 {
    _ = name;
    _ = field;
    return 1.0;
}

const defaultControls = expr.Controls{ .lookup = ctrlLookup };

test "arithmetic + precedence + calls" {
    var aa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer aa.deinit();
    const arena = aa.allocator();
    const closure = expr.Closure{ .a = arena, .entries = &.{} };
    const cases = [_][2][]const u8{
        .{ "2 + 3 * 4", "14" },
        .{ "(2 + 3) * 4", "20" },
        .{ "max(3, 7) + min(9, 2)", "9" },
        .{ "2 ^ 3", "8" },
        .{ "-2 + 5", "3" },
        .{ "clamp(10, 0, 4)", "4" },
        .{ "10 / 4", "2.5" },
        .{ "if(3 > 2, 5, -5)", "5" },
        .{ "not (1 == 2)", "1" },
    };
    for (cases) |c| {
        const root = try expr.parseExpr(arena, c[0]);
        const v = expr.eval(&closure, .{}, defaultControls, arena, root) catch |e| {
            std.debug.print("FAIL {s}: {s}\n", .{ c[0], @errorName(e) });
            return error.TestUnexpectedError;
        };
        const expected = try std.fmt.parseFloat(f64, c[1]);
        try std.testing.expectApproxEqAbs(expected, v, 1e-6);
    }
}

test "load fulgora surface + evaluate simple constants and a voronoi leaf" {
    var aa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer aa.deinit();
    const arena = aa.allocator();
    const planet = try data.load(arena, .fulgora);
    const cl = &planet.closure;
    // fulgora_jitter is a plain constant
    const jit = try expr.evalRoot(cl, .{}, defaultControls, arena, "fulgora_jitter");
    try std.testing.expectApproxEqAbs(0.6, jit, 1e-6);
    // fulgora_ox = x + fulgora_grid / 2, controls at defaults -> grid 175
    const v = expr.evalRoot(cl, .{ .x = 100, .y = -40, .seed = 341 }, defaultControls, arena, "fulgora_ox") catch |e| {
        std.debug.print("ox fail: {s}\n", .{@errorName(e)});
        return error.TestUnexpectedError;
    };
    try std.testing.expectApproxEqAbs(100 + 87.5, v, 1e-6);
    _ = json;
    _ = Scalars;
}
