//! SE surface generation calibration data, shared by the native segen CLI
//! (se_main.zig) and the browser surface generator (se_wasm.zig compiled to
//! WebAssembly) so spot positions, amounts and map colors never diverge.
//!
//! All of these values are reverse-engineered from the live game / mod dumps —
//! see the comments on each block. If a calibration changes, change it HERE.

const std = @import("std");
const se = @import("se_ore_placement.zig");

/// Factorio/SE/K2 map colors (RGB), matching the ground-truth renderer
/// calibration/mod-dump/convert_jsonl.py so generated images are directly
/// comparable to Horaerratum.png. Unknown -> grey; se-core-fragment-* inherits
/// its base resource's color.
pub const MapColors = struct {
    pub fn get(name: []const u8) [3]u8 {
        // Authoritative resource map_color (dumped live -> calibration/mod-dump/ore-colors.json).
        // Vanilla
        if (std.mem.eql(u8, name, "iron-ore")) return .{ 105, 133, 147 };
        if (std.mem.eql(u8, name, "copper-ore")) return .{ 204, 98, 54 };
        if (std.mem.eql(u8, name, "coal")) return .{ 0, 0, 0 };
        if (std.mem.eql(u8, name, "stone")) return .{ 175, 155, 108 };
        if (std.mem.eql(u8, name, "uranium-ore")) return .{ 0, 178, 0 };
        if (std.mem.eql(u8, name, "crude-oil")) return .{ 255, 153, 0 };
        // Krastorio 2
        if (std.mem.eql(u8, name, "kr-rare-metal-ore")) return .{ 153, 76, 255 };
        if (std.mem.eql(u8, name, "kr-imersite")) return .{ 255, 127, 255 };
        if (std.mem.eql(u8, name, "kr-mineral-water")) return .{ 89, 127, 191 };
        // Space Exploration
        if (std.mem.eql(u8, name, "se-water-ice")) return .{ 198, 241, 245 };
        if (std.mem.eql(u8, name, "se-methane-ice")) return .{ 245, 231, 198 };
        if (std.mem.eql(u8, name, "se-beryllium-ore")) return .{ 144, 222, 184 };
        if (std.mem.eql(u8, name, "se-cryonite")) return .{ 35, 164, 255 };
        if (std.mem.eql(u8, name, "se-holmium-ore")) return .{ 135, 96, 109 };
        if (std.mem.eql(u8, name, "se-iridium-ore")) return .{ 244, 202, 85 };
        if (std.mem.eql(u8, name, "se-naquium-ore")) return .{ 137, 113, 214 };
        if (std.mem.eql(u8, name, "se-vulcanite")) return .{ 224, 40, 10 };
        if (std.mem.eql(u8, name, "se-vitamelange")) return .{ 173, 206, 54 };
        // Core fragments inherit their base resource's color.
        const prefix = "se-core-fragment-";
        if (std.mem.startsWith(u8, name, prefix)) return get(name[prefix.len..]);
        return .{ 128, 128, 128 };
    }
};

/// Per-resource calibration: config (the SE autoplace parameters from
/// data.lua se_resources + phase-3 defaults) + ctrl (the ACTUAL post-zone-
/// modifier map-gen control values the game applied, from
/// output/target-horaerratum.json computeZoneResourceControls).
pub const Entry = struct {
    name: []const u8,
    cfg: se.SEResourceConfig,
    ctrl: se.Controls,
};

// Total number of placeable resource patch sets in the "default" autoplace set
// (base + K2 + SE). All resources share one metaset and stride across a common
// candidate-point list: skip_span = this count, skip_offset = per-resource index.
// Captured from the live game via calibration/mod-dump/patchset-dump.json
// (patchset-dump mod, data-final-fixes). This is what makes spot POSITIONS match.
pub const SE_REGULAR_PATCH_SET_COUNT: u32 = 18;

pub const SE_STARTING_PATCH_SET_COUNT: u32 = 14; // starting_patch_set_count (patchset-dump)

pub fn mkEntry(name: []const u8, idx: u32, bd: f64, bspk: f64, rqm: f64, rp: f64, add: f64, smin: f64, smax: f64, cf: f64, cs: f64, cr: f64, si: i32, srq: f64) Entry {
    // (name, regular_patch_set_index, base_density, base_spots_per_km2, rq_mult,
    //  random_probability, additional_richness, spot_size_min, spot_size_max,
    //  freq_control, size_control, richness_control,
    //  starting_patch_set_index (-1 = no starting patches), starting_rq_mult)
    return .{
        .name = name,
        .cfg = .{
            .base_density = bd,
            .base_spots_per_km2 = bspk,
            .regular_rq_factor_multiplier = rqm,
            .random_probability = rp,
            .additional_richness = add,
            .random_spot_size_minimum = smin,
            .random_spot_size_maximum = smax,
            .regular_patch_set_index = idx,
            .regular_patch_set_count = SE_REGULAR_PATCH_SET_COUNT,
            .has_starting_area_placement = si >= 0,
            .starting_patch_set_index = if (si >= 0) @intCast(si) else 0,
            .starting_patch_set_count = SE_STARTING_PATCH_SET_COUNT,
            .starting_rq_factor_multiplier = srq,
        },
        .ctrl = .{ .frequency = cf, .size = cs, .richness = cr },
    };
}

pub const N_BASE_RESOURCES = 9;
// Each resource strides the shared candidate list from its data-load index
// (regular_patch_set_index, from patchset-dump.json) by SE_REGULAR_PATCH_SET_COUNT.
// Controls (last 3 args) are the ACTUAL post-zone-modifier values the game
// applied (SE multiplies zone-control frequency by a per-moon factor ~4.8x).
// The last 3 (Krastorio 2) are gated behind --k2. K2 params from SE's K2 compat
// (prototypes/phase-1/compatibility/krastorio2/resource-gen.lua); controls dumped
// live from Horaerratum.
pub const RESOURCE_ENTRIES = [_]Entry{
    mkEntry("iron-ore", 0, 14, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 3.72599, 1.43847, 1.46655, 0, 1.5),
    mkEntry("copper-ore", 1, 12, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 2.08951, 0.58708, 0.65773, 1, 1.5),
    mkEntry("uranium-ore", 5, 1, 2.0, 1.1, 1.0, 0, 2.0, 4.0, 3.45809, 1.29909, 1.33414, -1, 1.0),
    mkEntry("coal", 2, 9, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 1.46945, 0.26449, 0.35127, 2, 1.5),
    mkEntry("crude-oil", 4, 8, 2.5, 1.2, 1.0 / 24.0, 220000, 1.0, 1.0, 2.50998, 0.80584, 0.86554, 4, 1.5),
    mkEntry("stone", 3, 12, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 3.04810, 1.08579, 1.13150, 3, 1.5),
    mkEntry("se-vulcanite", 16, 10, 5.0, 1.1, 1.0, 0, 0.25, 2.0, 4.36720, 1.77206, 1.78346, 12, 1.0),
    mkEntry("se-cryonite", 12, 10, 5.0, 1.1, 1.0, 0, 0.25, 2.0, 4.52532, 1.85433, 1.86161, 8, 1.0),
    mkEntry("se-vitamelange", 17, 10, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 8.02342, 3.67423, 3.59052, 13, 1.0),
    // --- Krastorio 2 (--k2) --- (has_starting_area_placement = false)
    mkEntry("kr-rare-metal-ore", 8, 8, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 3.97694, 1.56903, 1.59058, -1, 1.5),
    mkEntry("kr-mineral-water", 7, 8, 2.0, 1.0, 1.0 / 24.0, 120000, 1.0, 1.0, 3.33011, 1.23251, 1.27089, -1, 1.0),
    mkEntry("kr-imersite", 6, 1, 0.05, 1.0, 1.0 / 4.0, 250000, 0.01, 0.1, 3.59600, 1.37084, 1.40230, -1, 1.0),
    // --- remaining SE ores (live-dump params; controls come from the zone driver,
    //     size 0 here means "skipped unless a zone provides controls") ---
    mkEntry("se-water-ice", 9, 5, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 0, 0, 0, 5, 1.0),
    mkEntry("se-methane-ice", 10, 5, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 0, 0, 0, 6, 1.0),
    mkEntry("se-beryllium-ore", 11, 5, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 0, 0, 0, 7, 1.0),
    mkEntry("se-holmium-ore", 13, 5, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 0, 0, 0, 9, 1.0),
    mkEntry("se-iridium-ore", 14, 5, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 0, 0, 0, 10, 1.0),
    mkEntry("se-naquium-ore", 15, 1, 2.5, 1.1, 1.0, 0, 0.25, 2.0, 0, 0, 0, 11, 1.0),
};

pub const N_ALL_RESOURCES = RESOURCE_ENTRIES.len;

pub fn entries(k2: bool) []const Entry {
    return if (k2) RESOURCE_ENTRIES[0..] else RESOURCE_ENTRIES[0..N_BASE_RESOURCES];
}

/// Map a parsed resource name to the static RESOURCE_ENTRIES slice (stable
/// lifetime, and matches MapColors), or null if unknown.
pub fn staticResName(n: []const u8) ?[]const u8 {
    for (RESOURCE_ENTRIES) |e| {
        if (std.mem.eql(u8, e.name, n)) return e.name;
    }
    return null;
}

/// FSR test-bench override. The GUI may attach an optional per-resource control
/// object to a zone entry:  "fsr": { "iron-ore": [freq, size, rich], ... }.
/// Look one resource up; returns null when the zone carries no override for it
/// (the caller then keeps the game/universe-derived control). Absent / malformed
/// values fall back to the in-game default of 1.0 so a partial object is safe.
pub fn fsrOverride(z: std.json.ObjectMap, name: []const u8) ?[3]f64 {
    const fsr = z.get("fsr") orelse return null;
    if (fsr != .object) return null;
    const arr = fsr.object.get(name) orelse return null;
    if (arr != .array or arr.array.items.len < 3) return null;
    const num = struct {
        fn v(x: std.json.Value) f64 {
            return switch (x) {
                .float => |f| f,
                .integer => |i| @floatFromInt(i),
                else => 1.0,
            };
        }
    }.v;
    return .{ num(arr.array.items[0]), num(arr.array.items[1]), num(arr.array.items[2]) };
}
