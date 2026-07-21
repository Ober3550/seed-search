const std = @import("std");
const surfacegen = @import("surface_generator");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;

    const args = try init.minimal.args.toSlice(arena);
    if (args.len < 2) {
        std.debug.print(
            \\surfacegen — Factorio surface generator
            \\
            \\Usage: surfacegen <seed> [--preset default|rich|scarce]
            \\       surfacegen verify --against <test_data_dir>
            \\
        , .{});
        return;
    }

    const seed = std.fmt.parseInt(u32, args[1], 10) catch {
        std.debug.print("Invalid seed: {s}\n", .{args[1]});
        return;
    };

    _ = io;

    // TODO: Implement surface generation pipeline
    // 1. Initialize RNG with seed
    // 2. Load map gen settings (default / preset)
    // 3. Generate tiles for target chunks
    // 4. Run autoplace for each resource
    // 5. Output serialized chunk data

    std.debug.print("Seed: {d} — surface generation not yet implemented.\n", .{seed});
}
