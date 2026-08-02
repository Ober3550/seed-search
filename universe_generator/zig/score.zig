//! Union-of-extremes capture — reads the SHARED config (score.config.json), the
//! single source of truth also used by space_explorer_gui/score.js and
//! scripts/plot_distributions.py. A seed is KEPT if it lands in ANY enabled
//! per-metric tail: value <= lo (low tail) OR value >= hi (high tail); a null
//! bound disables that tail. `tailCount` returns how many tails the seed hits —
//! the stored `score` column, used only for sorting ("how many dimensions is
//! this seed extreme in"). No composite/weighted score.
//!
//! The repo config is @embedFile'd as the default; SCORE_CONFIG=<path> overrides
//! it at runtime (retune thresholds without a rebuild). `moons` is derived
//! (npm − npl); the generator supplies it in Metrics.
const std = @import("std");

// Δv "none" is the 10M sentinel; it sits above any hi threshold, so a seed with
// no reachable naquium field naturally counts as the far (high) tail — correct.
const embedded = @embedFile("score.config.json");

pub const Filter = struct {
    key: []const u8,
    lo: ?f64, // keep if value <= lo (null = low tail disabled)
    hi: ?f64, // keep if value >= hi (null = high tail disabled)
};

pub const Config = struct {
    filters: []Filter,
};

/// Per-seed metrics, keyed to match Filter.key. `moons` = npm − npl.
pub const Metrics = struct {
    hostility_pct: u32,
    water_pct: u32,
    naquium_dv: u32,
    field_dv: u32,
    planets: u32,
    moons: u32,
};

/// Parse the config from SCORE_CONFIG (if set + readable) else the embedded copy.
pub fn load(alloc: std.mem.Allocator, io: std.Io) !std.json.Parsed(Config) {
    const opts = std.json.ParseOptions{ .ignore_unknown_fields = true, .allocate = .alloc_always };
    if (std.c.getenv("SCORE_CONFIG")) |p| {
        const path = std.mem.sliceTo(p, 0);
        if (std.Io.Dir.readFileAlloc(.cwd(), io, path, alloc, .unlimited)) |bytes| {
            defer alloc.free(bytes);
            return std.json.parseFromSlice(Config, alloc, bytes, opts);
        } else |_| {
            std.debug.print("# score: SCORE_CONFIG '{s}' unreadable — using embedded default\n", .{path});
        }
    }
    return std.json.parseFromSlice(Config, alloc, embedded, opts);
}

fn metricValue(key: []const u8, m: Metrics) f64 {
    const eql = std.mem.eql;
    if (eql(u8, key, "hostility_pct")) return @floatFromInt(m.hostility_pct);
    if (eql(u8, key, "water_pct")) return @floatFromInt(m.water_pct);
    if (eql(u8, key, "naquium_dv")) return @floatFromInt(m.naquium_dv);
    if (eql(u8, key, "field_dv")) return @floatFromInt(m.field_dv);
    if (eql(u8, key, "planets")) return @floatFromInt(m.planets);
    if (eql(u8, key, "moons")) return @floatFromInt(m.moons);
    return 0; // unknown key
}

/// How many enabled per-metric tails this seed lands in. 0 → discard the seed.
pub fn tailCount(cfg: Config, m: Metrics) i32 {
    var n: i32 = 0;
    for (cfg.filters) |f| {
        const v = metricValue(f.key, m);
        if (f.lo) |lo| {
            if (v <= lo) {
                n += 1;
                continue;
            }
        }
        if (f.hi) |hi| {
            if (v >= hi) n += 1;
        }
    }
    return n;
}
