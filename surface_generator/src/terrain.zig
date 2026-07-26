//! Space Exploration / Alien Biomes terrain noise port.
//!
//! Ports the named noise expressions Factorio evaluates for a moon surface:
//!   elevation (water = elevation < 0), temperature, moisture, aux.
//! These feed alien-biomes' biome selection -> tile -> resource gating
//! (cryonite=frozen, vulcanite=volcanic, vitamelange=grass/dirt; no ore on water).
//!
//! Source expressions: alien-biomes/prototypes/noise-programs.lua (temperature,
//! moisture, aux) using the engine op `quick_multioctave_noise`. The op is
//! decompiled in ghidra/export/terrain_noise.c (QuickMultioctaveNoise::run @
//! 0x1015edd54): per octave build a BasisNoise(input_scale, output_scale,
//! offset_x, offset_y, seed0, seed1), evaluate+accumulate, then
//!   input_scale  *= octave_input_scale_multiplier
//!   output_scale *= octave_output_scale_multiplier
//!   seed0        += octave_seed0_shift   (default 0 -> all octaves share seed)
//! offsets are constant across octaves. Validated against the live game via
//! surface.calculate_tile_properties (see se_main --terrain-probe).

const std = @import("std");
const noise = @import("noise.zig");

fn clamp(v: f64, lo: f64, hi: f64) f64 {
    return std.math.clamp(v, lo, hi);
}

/// quick_multioctave_noise (QuickMultioctaveNoise::run @0x1015edd54). Each octave
/// uses a FRESH generator: octave_seed0_shift defaults to 1, so octave k is seeded
/// (seed0+k, seed1). Offset is in tile space (evalOffset). Pass `gens[k]` =
/// BasisNoiseGen.init(seed0+k, seed1). input_scale *= oism, output_scale *= oosm
/// per octave; results accumulate. Verified exact vs moisture_noise/aux_noise/
/// temperature on vanilla Nauvis.
pub fn quickMultioctave(
    gens: []const noise.BasisNoiseGen,
    x: f64,
    y: f64,
    octaves: u32,
    input_scale: f64,
    output_scale: f64,
    oism: f64, // octave_input_scale_multiplier
    oosm: f64, // octave_output_scale_multiplier
    offset_x: f64,
    offset_y: f64,
) f64 {
    var result: f64 = 0.0;
    var inscale = input_scale;
    var outscale = output_scale;
    var i: u32 = 0;
    while (i < octaves) : (i += 1) {
        result += gens[i].evalOffset(x, y, inscale, outscale, offset_x, offset_y);
        inscale *= oism;
        outscale *= oosm;
    }
    return result;
}

/// Build `octaves` generators for a quick_multioctave call: (seed0+k, seed1).
pub fn qmoGens(comptime octaves: usize, seed0: u32, seed1: u32) [octaves]noise.BasisNoiseGen {
    var gens: [octaves]noise.BasisNoiseGen = undefined;
    var k: u32 = 0;
    while (k < octaves) : (k += 1) gens[k] = noise.BasisNoiseGen.init(seed0 +% k, seed1);
    return gens;
}

/// Per-zone control values that parameterize the terrain expressions. Dumped
/// from the live surface's map_gen_settings (autoplace_controls +
/// property_expression_names). Horaerratum defaults below.
pub const ZoneTerrain = struct {
    map_seed: u32,
    moisture_frequency: f64,
    moisture_bias: f64,
    aux_frequency: f64,
    aux_bias: f64,
    temperature_frequency: f64,
    temperature_bias: f64,
    cold_size: f64,
    hot_size: f64,
    cold_frequency: f64,
    hot_frequency: f64,
    // starting-area moisture bias (var control:starting_area_moisture:*)
    starting_moisture_bias: f64, // starting_bias, applied within starting_bias_region
    starting_moisture_frequency: f64,

    // 4 fresh generators per property (quick_multioctave octave_seed0_shift=1):
    // gens[k] = BasisNoiseGen.init(map_seed+k, seed1).
    temp_gens: [4]noise.BasisNoiseGen, // seed1=5
    moist_gens: [4]noise.BasisNoiseGen, // seed1=6
    aux_gens: [4]noise.BasisNoiseGen, // seed1=7
    // Elevation for nauvis_plateaus (aux_nauvis / moisture_nauvis depend on it).
    elev: Elevation,

    pub fn init(cfg: Config) ZoneTerrain {
        return .{
            .map_seed = cfg.map_seed,
            .moisture_frequency = cfg.moisture_frequency,
            .moisture_bias = cfg.moisture_bias,
            .aux_frequency = cfg.aux_frequency,
            .aux_bias = cfg.aux_bias,
            .temperature_frequency = cfg.temperature_frequency,
            .temperature_bias = cfg.temperature_bias,
            .cold_size = cfg.cold_size,
            .hot_size = cfg.hot_size,
            .cold_frequency = cfg.cold_frequency,
            .hot_frequency = cfg.hot_frequency,
            .starting_moisture_bias = cfg.starting_moisture_bias,
            .starting_moisture_frequency = cfg.starting_moisture_frequency,
            .temp_gens = qmoGens(4, cfg.map_seed, 5),
            .moist_gens = qmoGens(4, cfg.map_seed, 6),
            .aux_gens = qmoGens(4, cfg.map_seed, 7),
            .elev = Elevation.init(cfg.map_seed, cfg.water_frequency, cfg.water_size),
        };
    }

    pub const Config = struct {
        map_seed: u32,
        moisture_frequency: f64,
        moisture_bias: f64,
        aux_frequency: f64,
        aux_bias: f64,
        temperature_frequency: f64 = 1.0,
        temperature_bias: f64 = 0.0,
        cold_size: f64,
        hot_size: f64,
        cold_frequency: f64,
        hot_frequency: f64,
        water_frequency: f64 = 1.0,
        water_size: f64 = 1.0,
        starting_moisture_bias: f64 = 0.0,
        starting_moisture_frequency: f64 = 1.0,
    };

    /// temperature = clamp(15 + bias + quick_multioctave_noise{seed1=5, oct4,
    /// is=freq/32, os=1/20, offset_x=40000/freq, oosm=3, oism=1/3}, -20, 50).
    pub fn temperature(self: *const ZoneTerrain, x: f64, y: f64) f64 {
        const f = self.temperature_frequency;
        const q = quickMultioctave(&self.temp_gens, x, y, 4, f / 32.0, 1.0 / 20.0, 1.0 / 3.0, 3.0, 40000.0 / f, 0.0);
        return clamp(15.0 + self.temperature_bias + q, -20.0, 50.0);
    }

    /// aux_nauvis = clamp(0.5 + bias + 0.06*(nauvis_plateaus - 0.4) + aux_noise, 0, 1);
    /// aux_noise = quick_multioctave_noise{seed1=7, oct4, is=freq/2048, os=0.25,
    /// offset_x=20000/freq, oosm=0.5, oism=3}.
    pub fn aux(self: *const ZoneTerrain, x: f64, y: f64) f64 {
        const f = self.aux_frequency;
        const q = quickMultioctave(&self.aux_gens, x, y, 4, f / 2048.0, 0.25, 3.0, 0.5, 20000.0 / f, 0.0);
        const plateaus = self.elev.nauvisPlateaus(x, y);
        return clamp(0.5 + self.aux_bias + 0.06 * (plateaus - 0.4) + q, 0.0, 1.0);
    }

    /// moisture_noise = quick_multioctave_noise{seed1=6, oct4, is=freq/256,
    /// os=0.125, offset_x=30000/freq, oosm=1.5, oism=1/3}.
    pub fn moistureNoise(self: *const ZoneTerrain, x: f64, y: f64) f64 {
        const f = self.moisture_frequency;
        return quickMultioctave(&self.moist_gens, x, y, 4, f / 256.0, 0.125, 1.0 / 3.0, 1.5, 30000.0 / f, 0.0);
    }

    /// moisture_adjusted_bias = lerp(base_bias, starting_bias, starting_bias_region),
    /// starting_bias_region = clamp(2 - starting_area_moisture_freq/400 * distance, 0, 1).
    fn moistureAdjustedBias(self: *const ZoneTerrain, x: f64, y: f64) f64 {
        const dist = @sqrt(x * x + y * y);
        const region = clamp(2.0 - self.starting_moisture_frequency / 400.0 * dist, 0.0, 1.0);
        return lerp(self.moisture_bias, self.starting_moisture_bias, region);
    }

    /// moisture_main = clamp(0.4 + moisture_adjusted_bias + moisture_noise
    /// - 0.08*(nauvis_plateaus - 0.6), 0, 1).
    pub fn moistureMain(self: *const ZoneTerrain, x: f64, y: f64) f64 {
        const plateaus = self.elev.nauvisPlateaus(x, y);
        return clamp(0.4 + self.moistureAdjustedBias(x, y) + self.moistureNoise(x, y) - 0.08 * (plateaus - 0.6), 0.0, 1.0);
    }

    /// moisture = moisture_nauvis = max(min(moisture_main, 0.45),
    ///   moisture_main - 0.2 * max(0, 1 - trees_forest_path_cutout * 1.5)).
    /// The dirt-trail term only lowers moisture where moisture_main > 0.45.
    pub fn moisture(self: *const ZoneTerrain, x: f64, y: f64) f64 {
        const main = self.moistureMain(x, y);
        const cutout = self.elev.treesForestPathCutout(x, y);
        const factor = @max(0.0, 1.0 - cutout * 1.5);
        return @max(@min(main, 0.45), main - 0.2 * factor);
    }
};

fn lerp(a: f64, b: f64, t: f64) f64 {
    return a + (b - a) * t;
}

/// Nauvis elevation generator (SE moons use the default `elevation` =
/// `elevation_nauvis`). Ported from core/prototypes/noise-programs.lua.
/// water tile <=> elevation < 0.
pub const Elevation = struct {
    map_seed: u32,
    nsm: f64, // nauvis_segmentation_multiplier = 1.5 * control:water:frequency
    seg: f64, // segmentation_multiplier = control:water:frequency
    water_level: f64, // 10 * log2(control:water:size)
    gen500: noise.BasisNoiseGen, // nauvis_persistance
    gen600: noise.BasisNoiseGen, // nauvis_detail
    // starting_lake_noise = quick_multioctave_noise_persistence{seed1=14, oct4}.
    // quick_multioctave defaults octave_seed0_shift=1, so each octave uses a
    // FRESH generator seeded (map_seed, 14), (map_seed, 15), ... one per octave.
    slake_gens: [4]noise.BasisNoiseGen,
    // Engine-chosen starting_lake_positions (per seed; EMPTY for SE moons, which
    // is why moons have no starting lake). distance_from_nearest_point caps at 1024.
    slake_buf: [8][2]f64 = undefined,
    slake_n: usize = 0,

    pub fn init(map_seed: u32, water_frequency: f64, water_size: f64) Elevation {
        return .{
            .map_seed = map_seed,
            .nsm = 1.5 * water_frequency,
            .seg = water_frequency,
            .water_level = 10.0 * std.math.log2(water_size),
            .gen500 = noise.BasisNoiseGen.init(map_seed, 500),
            .gen600 = noise.BasisNoiseGen.init(map_seed, 600),
            // octave_seed0_shift=1 increments SEED0 (map_seed), keeping seed1=14.
            .slake_gens = .{
                noise.BasisNoiseGen.init(map_seed, 14),
                noise.BasisNoiseGen.init(map_seed +% 1, 14),
                noise.BasisNoiseGen.init(map_seed +% 2, 14),
                noise.BasisNoiseGen.init(map_seed +% 3, 14),
            },
        };
    }

    /// Register an engine-chosen starting-lake center. Vanilla Nauvis places one;
    /// SE moons place none (leave slake_n=0 → starting_lake never wins the min()).
    pub fn addStartingLake(self: *Elevation, x: f64, y: f64) void {
        if (self.slake_n >= self.slake_buf.len) return;
        self.slake_buf[self.slake_n] = .{ x, y };
        self.slake_n += 1;
    }

    /// starting_lake_noise = quick_multioctave_noise_persistence{seed1=14, is=1/8,
    /// os=0.8, oct=4, oism=0.5, persistence=0.68}. Expands to quick_multioctave_noise
    /// {is=1/64, os=6.4, oism=2, oosm=0.68, oct=4} with a fresh gen per octave.
    fn startingLakeNoise(self: *const Elevation, x: f64, y: f64) f64 {
        var result: f64 = 0.0;
        var inscale: f64 = 1.0 / 64.0;
        var outscale: f64 = 6.4;
        var k: usize = 0;
        while (k < 4) : (k += 1) {
            result += self.slake_gens[k].eval(x, y, inscale, outscale);
            inscale *= 2.0;
            outscale *= 0.68;
        }
        return result;
    }

    /// starting_lake = 20 * (-3 + (dist + noise) / 8) / 8, where dist is the
    /// Euclidean distance to the nearest starting_lake_position (capped at 1024).
    /// Returns a large value (never wins the min) when there are no lakes.
    fn startingLake(self: *const Elevation, x: f64, y: f64) f64 {
        if (self.slake_n == 0) return 1.0e30;
        var dist: f64 = 1024.0;
        var i: usize = 0;
        while (i < self.slake_n) : (i += 1) {
            const dx = x - self.slake_buf[i][0];
            const dy = y - self.slake_buf[i][1];
            const d = @sqrt(dx * dx + dy * dy);
            if (d < dist) dist = d;
        }
        const noisev = self.startingLakeNoise(x, y);
        return 20.0 * (-3.0 + (dist + noisev) / 8.0) / 8.0;
    }

    fn mo(self: *const Elevation, x: f64, y: f64, seed1: u32, octaves: u32, persistence: f64, input_scale: f64) f64 {
        return noise.multioctaveNoise(x, y, self.map_seed, seed1, octaves, persistence, input_scale, 1.0);
    }

    /// nauvis_persistance = clamp(amplitude_corrected_multioctave_noise{seed1=500,
    ///   oct5, is=nsm/2, offset_x=10000/nsm, persistence=0.7, amplitude=0.5} + 0.55,
    ///   0.5, 0.65). amplitude_corrected = variable_persistence with
    ///   output_scale = (1-p)/2^oct/(1-p^oct)*amplitude.
    fn nauvisPersistance(self: *const Elevation, x: f64, y: f64) f64 {
        const p = 0.7;
        const oct = 5;
        const os = (1.0 - p) / std.math.pow(f64, 2.0, oct) / (1.0 - std.math.pow(f64, p, oct)) * 0.5;
        const v = noise.variablePersistence(&self.gen500, x, y, oct, self.nsm / 2.0, os, 10000.0 / self.nsm, 0.0, p);
        return std.math.clamp(v + 0.55, 0.5, 0.65);
    }

    /// nauvis_detail = variable_persistence_multioctave_noise{seed1=600, oct5,
    ///   is=nsm/14, output_scale=0.03, offset_x=10000/nsm, persistence=nauvis_persistance}.
    fn nauvisDetail(self: *const Elevation, x: f64, y: f64) f64 {
        const persist = self.nauvisPersistance(x, y);
        return noise.variablePersistence(&self.gen600, x, y, 5, self.nsm / 14.0, 0.03, 10000.0 / self.nsm, 0.0, persist);
    }

    pub fn nauvisDetailPub(self: *const Elevation, x: f64, y: f64) f64 {
        return self.nauvisDetail(x, y);
    }
    pub fn startingLakePub(self: *const Elevation, x: f64, y: f64) f64 {
        return self.startingLake(x, y);
    }
    pub fn startingLakeNoisePub(self: *const Elevation, x: f64, y: f64) f64 {
        return self.startingLakeNoise(x, y);
    }

    /// trees_forest_path_cutout = min(nauvis_bridge_paths, nauvis_hills_paths,
    /// forest_paths), each = (abs(multioctave_noise{...}) - c) * k. Carves dirt
    /// trails; used by moisture_nauvis to lower moisture along forest paths.
    pub fn treesForestPathCutout(self: *const Elevation, x: f64, y: f64) f64 {
        const nsm = self.nsm;
        const bridge_billows = @abs(self.mo(x, y, 700, 4, 0.5, nsm / 150.0));
        const hills = @abs(self.mo(x, y, 900, 4, 0.5, nsm / 90.0));
        const fp_billows = @abs(self.mo(x, y, 1800, 4, 0.5, nsm / 100.0));
        const bridge_paths = (bridge_billows - 0.07) * 5.0;
        const hills_paths = (hills - 0.1) * 3.0;
        const forest_paths = (fp_billows - 0.07) * 3.0;
        return @min(bridge_paths, @min(hills_paths, forest_paths));
    }

    /// nauvis_plateaus = 0.5 + clamp((nauvis_hills - nauvis_hills_cliff_level)*10,
    /// -0.5, 0.5). Corner coords (matches the game). Used by aux_nauvis / moisture_nauvis.
    pub fn nauvisPlateaus(self: *const Elevation, x: f64, y: f64) f64 {
        const nsm = self.nsm;
        const hills = @abs(self.mo(x, y, 900, 4, 0.5, nsm / 90.0));
        const cliff_level = std.math.clamp(0.65 + noise.basisNoise(x, y, self.map_seed, 99584, nsm / 500.0, 0.6), 0.15, 1.15);
        return 0.5 + std.math.clamp((hills - cliff_level) * 10.0, -0.5, 0.5);
    }
    pub fn nauvisPersistancePub(self: *const Elevation, x: f64, y: f64) f64 {
        return self.nauvisPersistance(x, y);
    }

    pub fn at(self: *const Elevation, x0: f64, y0: f64) f64 {
        // Factorio determines a tile's water at the TILE CORNER (tx,ty): verified
        // vs real generated tiles (collides_with water_tile) — corner matches
        // 2099/2107, center only 2054/2107. So sample every term at (x0,y0).
        const x = x0;
        const y = y0;
        const nsm = self.nsm;
        // nauvis_hills / plateaus
        const nauvis_hills = @abs(self.mo(x, y, 900, 4, 0.5, nsm / 90.0));
        const cliff_level = std.math.clamp(0.65 + noise.basisNoise(x, y, self.map_seed, 99584, nsm / 500.0, 0.6), 0.15, 1.15);
        const plateaus = 0.5 + std.math.clamp((nauvis_hills - cliff_level) * 10.0, -0.5, 0.5);
        const hills_plateaus = 0.1 * nauvis_hills + 0.8 * plateaus;
        // nauvis_bridges
        const bb = @abs(self.mo(x, y, 700, 4, 0.5, nsm / 150.0));
        const bridges = 1.0 - 0.1 * bb - 0.9 * @max(0.0, -0.1 + bb);
        // nauvis_macro (continent-scale; dominates land/water via the x3 factor)
        const macro = self.mo(x, y, 1000, 2, 0.6, nsm / 1600.0) * @max(0.0, self.mo(x, y, 1100, 1, 0.6, nsm / 1600.0));
        const detail = self.nauvisDetail(x, y);

        const dist = @sqrt(x0 * x0 + y0 * y0); // distance uses tile coord, not center
        const smm = std.math.clamp(dist * nsm / 2000.0, 0.0, 1.0);
        const cliff = hills_plateaus;
        const nauvis_main = 20.0 * (lerp(0.5 * cliff - 0.6, 1.9 * cliff + 1.6, 0.1 + 0.5 * bridges) + 0.25 * detail + 3.0 * macro * smm);
        const starting_island = nauvis_main + 20.0 * (2.5 - dist * self.seg / 200.0);
        const wlc_elevation = @max(nauvis_main - self.water_level * 2.0, starting_island);
        // elevation_nauvis = min(wlc_elevation, starting_lake). starting_lake uses
        // the tile-center coords (same x,y as the noise terms). No lakes -> +1e30.
        return @min(wlc_elevation, self.startingLake(x, y));
    }

    pub fn isWater(self: *const Elevation, x: f64, y: f64) bool {
        return self.at(x, y) < 0.0;
    }

    pub const Sub = struct { macro: f64, hills: f64, hills_plateaus: f64, bridges: f64, cliff_level: f64 };
    pub fn subterms(self: *const Elevation, x0: f64, y0: f64) Sub {
        const x = x0 + 0.5;
        const y = y0 + 0.5;
        const nsm = self.nsm;
        const hills = @abs(self.mo(x, y, 900, 4, 0.5, nsm / 90.0));
        const cliff_level = std.math.clamp(0.65 + noise.basisNoise(x, y, self.map_seed, 99584, nsm / 500.0, 0.6), 0.15, 1.15);
        const plateaus = 0.5 + std.math.clamp((hills - cliff_level) * 10.0, -0.5, 0.5);
        const hp = 0.1 * hills + 0.8 * plateaus;
        const bb = @abs(self.mo(x, y, 700, 4, 0.5, nsm / 150.0));
        const bridges = 1.0 - 0.1 * bb - 0.9 * @max(0.0, -0.1 + bb);
        const macro = self.mo(x, y, 1000, 2, 0.6, nsm / 1600.0) * @max(0.0, self.mo(x, y, 1100, 1, 0.6, nsm / 1600.0));
        return .{ .macro = macro, .hills = hills, .hills_plateaus = hp, .bridges = bridges, .cliff_level = cliff_level };
    }
};

/// Horaerratum (world 57374) terrain controls.
pub const HORAERRATUM = ZoneTerrain.Config{
    .map_seed = 2035207183,
    // control-setting bias sliders read 0.5 (neutral); the noise var
    // `control:moisture:bias` is that slider re-centered to 0 at neutral.
    .moisture_frequency = 2.0,
    .moisture_bias = 0.0,
    .aux_frequency = 1.0,
    .aux_bias = 0.0,
    .cold_size = 6.0,
    .hot_size = 6.0,
    .cold_frequency = 4.8053212165833,
    .hot_frequency = 4.8053212165833,
    .water_frequency = 1.0,
    .water_size = 1.5,
};
