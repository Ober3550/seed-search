//! gpu_stitch — compose a surface's per-cell PNGs into one full-disk PNG.
//!
//! Reads <dir>/<prefix>_<n>_<cell>.png for every grid cell, blits each into a
//! full R*2 square canvas at its grid slot, and writes <dir>/<prefix>.png. The
//! write is ATOMIC (temp file + rename) so the GUI never sees a half-written
//! image — it keeps showing the live cell grid until the finished file appears,
//! then swaps in one step.
//!
//!   gpu_stitch --dir <zoneDir> --prefix <terrain|oremap> --grid N --radius R
//!
//! Cell geometry matches gpu_ore/gpu_terrain: R = floor(radius), full = R*2,
//! cellW = ceil(full/N), cell (gx,gy) at pixel (gx*cellW, gy*cellW). Missing
//! cells are skipped. Background: oremap → transparent, terrain → grey 20.
const std = @import("std");
const surfgen = @import("surfgen");
const png = surfgen.png;
const c = @cImport(@cInclude("stdio.h")); // rename() — atomic on POSIX

fn getStr(args: []const [:0]const u8, flag: []const u8) ?[]const u8 {
    var i: usize = 0;
    while (i + 1 < args.len) : (i += 1) if (std.mem.eql(u8, args[i], flag)) return args[i + 1];
    return null;
}
fn err(msg: []const u8) error{Usage} {
    std.debug.print("gpu_stitch error: {s}\n  usage: gpu_stitch --dir <zoneDir> --prefix <terrain|oremap> --grid N --radius R\n", .{msg});
    return error.Usage;
}

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const args = try init.minimal.args.toSlice(a);

    const dir = getStr(args, "--dir") orelse return err("missing --dir");
    const prefix = getStr(args, "--prefix") orelse return err("missing --prefix");
    const n: usize = @intCast(try std.fmt.parseInt(i32, getStr(args, "--grid") orelse return err("missing --grid"), 10));
    const radius = try std.fmt.parseFloat(f64, getStr(args, "--radius") orelse return err("missing --radius"));
    if (n <= 1) return err("--grid must be > 1 (whole render already writes <prefix>.png)");

    const R: usize = @intFromFloat(radius);
    const full: usize = R * 2;
    const cellW: usize = (full + n - 1) / n; // ceil, matches gpu_ore cellList
    const is_ore = std.mem.eql(u8, prefix, "oremap");

    // Full canvas, RGBA, filled with the layer background.
    const canvas = try a.alloc(u8, full * full * 4);
    if (is_ore) {
        @memset(canvas, 0); // transparent
    } else {
        var i: usize = 0;
        while (i < canvas.len) : (i += 4) {
            canvas[i] = 20;
            canvas[i + 1] = 20;
            canvas[i + 2] = 20;
            canvas[i + 3] = 255;
        }
    }

    var count: usize = 0;
    var cell: usize = 0;
    while (cell < n * n) : (cell += 1) {
        var cellArena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer cellArena.deinit();
        const ca = cellArena.allocator();
        var pb: [1024]u8 = undefined;
        const p = try std.fmt.bufPrint(&pb, "{s}/{s}_{d}_{d}.png", .{ dir, prefix, n, cell });
        const bytes = std.Io.Dir.readFileAlloc(.cwd(), init.io, p, ca, .unlimited) catch continue; // missing → skip
        const dec = png.decodeRgba(ca, bytes) catch continue;
        const gx = cell % n;
        const gy = cell / n;
        const left = gx * cellW;
        const top = gy * cellW;
        if (left >= full or top >= full) continue;
        var row: usize = 0;
        while (row < dec.height and top + row < full) : (row += 1) {
            const w = @min(dec.width, full - left);
            const src = dec.rgba[row * dec.width * 4 ..][0 .. w * 4];
            const dst = canvas[((top + row) * full + left) * 4 ..][0 .. w * 4];
            @memcpy(dst, src);
        }
        count += 1;
    }

    const out = try png.encodeRgba(a, @intCast(full), @intCast(full), canvas);

    // Atomic write: <prefix>.png.tmp then rename → <prefix>.png.
    var tb: [1024]u8 = undefined;
    const tmp = try std.fmt.bufPrint(&tb, "{s}/{s}.png.tmp", .{ dir, prefix });
    const f = try std.Io.Dir.createFile(.cwd(), init.io, tmp, .{});
    try f.writePositionalAll(init.io, out, 0);
    f.close(init.io);

    var tzb: [1024]u8 = undefined;
    var fzb: [1024]u8 = undefined;
    const tmp_z = try std.fmt.bufPrintZ(&tzb, "{s}/{s}.png.tmp", .{ dir, prefix });
    const fin_z = try std.fmt.bufPrintZ(&fzb, "{s}/{s}.png", .{ dir, prefix });
    if (c.rename(tmp_z.ptr, fin_z.ptr) != 0) return error.RenameFailed;

    std.debug.print("gpu_stitch: {s} — {d} cells → {d}x{d}\n", .{ prefix, count, full, full });
}
