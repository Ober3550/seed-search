//! Seed desirability score — reads the SHARED config (score.config.json), the
//! single source of truth also used by space_explorer_gui/score.js and
//! scripts/plot_distributions.py. SIGNED scale [-100, 100], 0 = par: the score is
//! a weighted sum of per-metric components, so negative qualifiers (hostile
//! system, no naquium access) pull below 0. Recover 0..100 as (score + 100) / 2.
//!
//! The repo config is @embedFile'd as the default; SCORE_CONFIG=<path> overrides
//! it at runtime (so weights can be retuned without a rebuild). Metric keys must
//! match the columns fed to `seedScore`.
const std = @import("std");

const NAQ_NONE = 10_000_000; // Δv sentinel: no reachable field
const embedded = @embedFile("score.config.json");

pub const Component = struct {
    key: []const u8,
    weight: f64,
    lo: f64,
    hi: f64,
    higher_better: bool,
    kind: []const u8, // "signed" | "bonus"
};

pub const Config = struct {
    exp: f64,
    pos_cut: i32,
    neg_cut: i32,
    many_planets: u32,
    components: []Component,
};

/// Per-seed metrics, keyed to match Component.key.
pub const Metrics = struct {
    ef: u32,
    wp: u32,
    naqdv: u32,
    fdv: u32,
    npl: u32,
    npm: u32,
};

/// Parse the config from SCORE_CONFIG (if set + readable) else the embedded copy.
/// The returned std.json.Parsed owns the Config; keep it alive for the run.
pub fn load(alloc: std.mem.Allocator, io: std.Io) !std.json.Parsed(Config) {
    const opts = std.json.ParseOptions{ .ignore_unknown_fields = true };
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

fn clamp01(x: f64) f64 {
    return @max(0.0, @min(1.0, x));
}
fn oddPow(v: f64, p: f64) f64 {
    const x = v / 100.0;
    return std.math.sign(x) * std.math.pow(f64, @abs(x), p) * 100.0;
}

fn metricValue(key: []const u8, m: Metrics) f64 {
    const eql = std.mem.eql;
    if (eql(u8, key, "ef")) return @floatFromInt(m.ef);
    if (eql(u8, key, "wp")) return @floatFromInt(m.wp);
    if (eql(u8, key, "naqdv")) return @floatFromInt(m.naqdv);
    if (eql(u8, key, "fdv")) return @floatFromInt(m.fdv);
    if (eql(u8, key, "npl")) return @floatFromInt(m.npl);
    if (eql(u8, key, "npm")) return @floatFromInt(m.npm);
    return 0; // unknown key -> par
}

fn component(v_in: f64, c: Component, exp: f64) f64 {
    const v = if (v_in >= NAQ_NONE) c.hi else v_in; // 'none' Δv -> far end
    const t = clamp01((v - c.lo) / (c.hi - c.lo));
    const good = if (c.higher_better) t else 1.0 - t;
    if (std.mem.eql(u8, c.kind, "bonus")) return oddPow(good * 100.0, exp);
    return oddPow(good * 200.0 - 100.0, exp);
}

/// Signed desirability in [-100, 100], rounded.
pub fn seedScore(cfg: Config, m: Metrics) i32 {
    var sum: f64 = 0;
    for (cfg.components) |c| sum += c.weight * component(metricValue(c.key, m), c, cfg.exp);
    return @intFromFloat(@round(sum));
}
