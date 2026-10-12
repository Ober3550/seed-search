//! Space Exploration surfaces for the entities layer: the map-gen settings SE
//! gives a planet or moon, and the data-driven placement pass run with them.
//!
//! SE's planets and moons are not planet prototypes. Zone.create_surface
//! (scripts/zone.lua) builds each surface's map_gen_settings when a player
//! first reaches it: a copy of the map's defaults, the zone's seed, the
//! controls its climate tags stand for, and a fixed list of what may spawn.
//! This file rebuilds those settings from what the universe generator knows
//! (seed, radius, tags, resources) and hands them to sa_surface.World with the
//! "se-zone" planet of the SE data file (scripts/sa-build-data.py
//! --se-zone-lua). Checked against a live game, see docs/space-exploration-
//! entities.md.
//!
//! What the seed does not decide: SE fills every control a tag does not set
//! with math.random() at the moment the surface is created - the game's
//! shared generator, whose state depends on everything that happened in the
//! save before. On a planet or moon that is the "rocks" control (the rock
//! noise's scale) and the cliff control (cliff spacing and how continuous the
//! cliffs are). No two saves agree on them, so `Rolls` holds typical values:
//! rocks and cliffs come out in the right amounts and shapes, not at the
//! positions of any particular save. Trees and enemy nests depend only on the
//! tags and the seed.

const std = @import("std");
const sa_data = @import("sa_data.zig");
const prog = @import("sa_program.zig");
const sa_surface = @import("sa_surface.zig");
const terrain = @import("terrain.zig");
const universe = @import("universe_gen");
const data = universe.data;

pub const PLANET = "se-zone";
pub const HOME_PLANET = "nauvis";

pub const Control = struct { name: []const u8, frequency: f64 = 1, size: f64 = 1, richness: f64 = 1 };

/// The per-surface random controls, before the zone's frequency multiplier.
/// Zone.create_surface: frequency = 0.17 + random * random * 2 (cliffs: * 10),
/// size = 0.1 + random * 0.8. The defaults are the medians.
pub const Rolls = struct {
    rocks_frequency: f64 = 0.17 + MEDIAN_PRODUCT * 2,
    cliff_frequency: f64 = 0.17 + MEDIAN_PRODUCT * 10,
    cliff_size: f64 = 0.5,

    /// median of the product of two uniform draws: x - x ln x = 1/2
    const MEDIAN_PRODUCT = 0.1867;
};

pub const Settings = struct {
    seed: u32,
    homeworld: bool,
    /// map_gen_settings.starting_area (0.5 on every zone but the homeworld)
    starting_area: f64 = 1,
    /// cliff_settings as the engine applies them (null: the planet's own)
    cliff_interval: ?f64 = null,
    cliff_elevation_0: f64 = 10,
    cliff_richness: f64 = 1,
    n: usize = 0,
    controls: [MAX]Control = undefined,

    const MAX = 40;

    fn add(self: *Settings, c: Control) void {
        if (self.n < MAX) {
            self.controls[self.n] = c;
            self.n += 1;
        }
    }

    pub fn control(self: *const Settings, name: []const u8) ?Control {
        for (self.controls[0..self.n]) |c| {
            if (std.mem.eql(u8, c.name, name)) return c;
        }
        return null;
    }

    /// prog.Controls.lookup: control:<name>:<field>
    pub fn lookup(ctx: *const anyopaque, name: []const u8, field: []const u8) f64 {
        const self: *const Settings = @ptrCast(@alignCast(ctx));
        if (std.mem.eql(u8, name, "starting-area")) return self.starting_area;
        const c = self.control(name) orelse return if (std.mem.eql(u8, field, "bias")) 0.0 else 1.0;
        if (std.mem.eql(u8, field, "frequency")) return c.frequency;
        if (std.mem.eql(u8, field, "size")) return c.size;
        if (std.mem.eql(u8, field, "richness")) return c.richness;
        return 0.0;
    }

    pub fn eql(a: *const Settings, b: *const Settings) bool {
        if (a.seed != b.seed or a.homeworld != b.homeworld or a.starting_area != b.starting_area or a.n != b.n) return false;
        if (a.cliff_interval != b.cliff_interval or a.cliff_elevation_0 != b.cliff_elevation_0 or a.cliff_richness != b.cliff_richness) return false;
        for (a.controls[0..a.n], b.controls[0..b.n]) |x, y| {
            if (!std.mem.eql(u8, x.name, y.name) or x.frequency != y.frequency or x.size != y.size or x.richness != y.richness) return false;
        }
        return true;
    }
};

/// The homeworld: the map's own settings, which the page takes as the game's
/// defaults (every control 1).
pub fn homeSettings(seed: u32) Settings {
    return .{ .seed = seed, .homeworld = true };
}

/// A planet's or moon's settings (Universe.control_settings_from_tag,
/// Zone.apply_controls_to_mapgen, Zone.create_surface).
pub fn zoneSettings(seed: u32, ztype: data.ZoneType, primary: ?[]const u8, tags: universe.Tags, radius: f64, rolls: Rolls) Settings {
    var s = Settings{ .seed = seed, .homeworld = false, .starting_area = 0.5 };
    // every control but trees and enemy-base is scaled by 5000 / radius
    const fm = universe.zoneFrequencyMultiplier(radius);

    const tc = (tags.temperature orelse data.Temperature.midrange).controlSettings();
    s.add(.{ .name = "hot", .frequency = tc.hot_freq * fm, .size = tc.hot_size });
    s.add(.{ .name = "cold", .frequency = tc.cold_freq * fm, .size = tc.cold_size });

    const tr: [3]f64 = switch (tags.trees orelse .med) {
        .none => .{ 0.25, 0, 0 },
        .low => .{ 0.6, 0.35, 0.8 },
        .med => .{ 0.8, 0.66, 1 },
        .high => .{ 1, 1, 1 },
        .max => .{ 3, 1, 1 },
    };
    s.add(.{ .name = "trees", .frequency = tr[0], .size = tr[1], .richness = tr[2] });

    const en: [3]f64 = switch (tags.enemy orelse .none) {
        .none => .{ 0.000001, 0, 0 },
        .very_low => .{ 0.1, 0.1, 0.1 },
        .low => .{ 0.2, 0.2, 0.2 },
        .med => .{ 0.5, 0.5, 0.5 },
        .high => .{ 1, 1, 1 },
        .very_high => .{ 1.5, 2, 1.5 },
        .max => .{ 2, 6, 2 },
    };
    s.add(.{ .name = "enemy-base", .frequency = en[0], .size = en[1], .richness = en[2] });

    s.add(.{ .name = "rocks", .frequency = rolls.rocks_frequency * fm, .size = 0.5, .richness = 0.5 });
    // planet_frequency = 1 / 6 / 2 ^ (radius * 6 / 10000 - 6)
    s.add(.{ .name = "planet-size", .frequency = 1.0 / 6.0 / std.math.pow(f64, 2.0, radius * 6.0 / 10000.0 - 6.0) });

    // Resources: a control of size 0 keeps its resource off the surface.
    const rc = universe.computeZoneMapgenControls(seed, ztype, primary, tags, radius, false);
    for (universe.resource_order, 0..) |name, i| {
        const c = rc[i];
        s.add(if (c.present and c.size > 0)
            .{ .name = name, .frequency = c.frequency, .size = c.size, .richness = c.richness }
        else
            .{ .name = name, .size = 0, .richness = 0 });
    }

    // Cliffs. The tag gives cliff_settings (interval = 40 / frequency, first
    // level a quarter of it, richness); the engine then divides the interval
    // by the cliff control's frequency and multiplies the richness by its
    // size (CliffPlacementSettings::getModifiedElevationInterval / Richness).
    const cl: [2]f64 = switch (tags.cliff orelse .med) {
        .none => .{ 0.01, 0 },
        .low => .{ 0.3, 0.3 },
        .med => .{ 1, 1 },
        .high => .{ 2, 2 },
        .max => .{ 6, 2 },
    };
    const interval = 40.0 / cl[0];
    s.cliff_interval = interval / (rolls.cliff_frequency * fm);
    s.cliff_elevation_0 = interval / 4.0;
    s.cliff_richness = cl[1] * rolls.cliff_size;
    return s;
}

/// One surface, ready to place entities chunk by chunk on tiles it is given.
pub const Zone = struct {
    settings: Settings,
    planet: *sa_data.Planet,
    world: sa_surface.World,
    /// tile map colour (0xRRGGBB) -> index into planet.tiles
    by_color: std.AutoHashMapUnmanaged(u32, u16),
    /// the tile beyond the surface's edge
    out_of_map: u16,

    /// `arena` must outlive the zone; `d` is the SE data file. `entities`
    /// false: the resources only (the entities before them in placement
    /// order still take their draws, so the ore is the same either way).
    pub fn init(arena: std.mem.Allocator, d: *const sa_data.Data, settings: Settings, entities: bool) !*Zone {
        const base = d.planet(if (settings.homeworld) HOME_PLANET else PLANET) orelse return error.NoZoneData;
        const z = try arena.create(Zone);
        z.settings = settings;
        const s = &z.settings;

        const p = try arena.create(sa_data.Planet);
        p.* = base.*;
        if (s.cliff_interval) |iv| {
            p.cliff_elevation_interval = iv;
            p.cliff_elevation_0 = s.cliff_elevation_0;
            p.cliff_richness = s.cliff_richness;
        }
        // an entity of a control whose size is 0 is not placed (and SE lists
        // the enemies only when the zone has any)
        var kept: std.ArrayList(sa_data.Entity) = .empty;
        for (base.placed) |e| {
            if (e.control.len > 0) {
                if (s.control(e.control)) |c| {
                    if (c.size == 0) continue;
                }
            }
            try kept.append(arena, e);
        }
        p.placed = kept.items;
        z.planet = p;

        z.by_color = .empty;
        z.out_of_map = 0;
        for (p.tiles, 0..) |t, i| {
            try z.by_color.put(arena, rgb(t.color), @intCast(i));
            if (std.mem.eql(u8, t.name, "out-of-map")) z.out_of_map = @intCast(i);
        }
        // every surface has a starting lake, placed from its own seed
        z.world = try sa_surface.World.initWith(arena, d, p, s.seed, .{
            .starting_lake = terrain.startingLakeCenter(s.seed),
            .ctx = s,
            .lookup = Settings.lookup,
        }, .{ .external_tiles = true, .entities = entities, .resources = true }, null);
        return z;
    }

    pub fn tileOf(self: *const Zone, color: [3]u8) ?u16 {
        return self.by_color.get(rgb(color));
    }

    fn rgb(c: [3]u8) u32 {
        return @as(u32, c[0]) << 16 | @as(u32, c[1]) << 8 | c[2];
    }
};
