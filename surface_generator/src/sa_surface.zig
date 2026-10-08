//! Planet surface driver: the tile competition, straight from the data.
//!
//! For each position the game evaluates the probability expression of every
//! tile in the planet's autoplace_settings and places the tile with the
//! highest value. That is all this does: compile every
//! "tile:<name>:probability" of the planet into one program (shared
//! sub-expressions evaluated once) and take the argmax per position.

const std = @import("std");
const sa_data = @import("sa_data.zig");
const prog = @import("sa_program.zig");

/// The game evaluates a tile's expressions at the tile's integer coordinate
/// (its top-left corner), not its centre - verified against live tile dumps.
pub const SAMPLE_OFFSET: f32 = 0.0;

pub const Surface = struct {
    planet: *const sa_data.Planet,
    program: prog.Program,
    ws: prog.Program.Workspace,

    /// `err_out` receives a description when compilation fails.
    pub fn init(a: std.mem.Allocator, data: *const sa_data.Data, planet: *const sa_data.Planet, map_seed: u32, controls: prog.Controls, err_out: ?*[]const u8) !Surface {
        if (planet.tiles.len == 0) return error.NoTiles;
        const names = try a.alloc([]const u8, planet.tiles.len);
        for (planet.tiles, 0..) |t, i| names[i] = try std.fmt.allocPrint(a, "tile:{s}:probability", .{t.name});
        const program = try prog.compile(a, data, planet, map_seed, controls, names, err_out);
        return .{ .planet = planet, .program = program, .ws = try program.workspace(a) };
    }

    /// Winning tile index (into planet.tiles) for the `out.len` tiles of row
    /// `y` starting at tile `x0`.
    pub fn tileRow(self: *Surface, x0: i32, y: i32, out: []u16) void {
        const B = prog.Program.BATCH;
        var xs: [B]f32 = undefined;
        var ys: [B]f32 = undefined;
        var done: usize = 0;
        while (done < out.len) {
            const n = @min(B, out.len - done);
            for (0..n) |j| {
                xs[j] = @as(f32, @floatFromInt(x0 + @as(i32, @intCast(done + j)))) + SAMPLE_OFFSET;
                ys[j] = @as(f32, @floatFromInt(y)) + SAMPLE_OFFSET;
            }
            self.program.eval(&self.ws, xs[0..n], ys[0..n]);
            var best: [B]f32 = undefined;
            @memset(best[0..n], -std.math.inf(f32));
            @memset(out[done..][0..n], 0);
            for (0..self.planet.tiles.len) |t| {
                const p = self.program.out(&self.ws, t);
                for (0..n) |j| {
                    // on a tie the earlier tile (prototype order) wins
                    if (p[j] > best[j]) {
                        best[j] = p[j];
                        out[done + j] = @intCast(t);
                    }
                }
            }
            done += n;
        }
    }

    /// RGBA8 colours for a width x height rectangle whose top-left tile is
    /// (x0, y0), one tile per pixel.
    pub fn renderRgba(self: *Surface, a: std.mem.Allocator, x0: i32, y0: i32, width: usize, height: usize, pixels: []u8) !void {
        std.debug.assert(pixels.len == width * height * 4);
        const row = try a.alloc(u16, width);
        defer a.free(row);
        for (0..height) |r| {
            self.tileRow(x0, y0 + @as(i32, @intCast(r)), row);
            for (row, 0..) |t, cidx| {
                const col = self.planet.tiles[t].color;
                const px = pixels[(r * width + cidx) * 4 ..][0..4];
                px.* = .{ col[0], col[1], col[2], 255 };
            }
        }
    }
};
