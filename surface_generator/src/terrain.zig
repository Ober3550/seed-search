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

/// quick_multioctave_noise. `gen` must be BasisNoiseGen.init(seed0, seed1)
/// (octave_seed0_shift defaults to 0, so every octave uses the same generator;
/// octaves decorrelate purely through their differing input_scale).
pub fn quickMultioctave(
    gen: *const noise.BasisNoiseGen,
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
        result += gen.evalOffset(x, y, inscale, outscale, offset_x, offset_y);
        inscale *= oism;
        outscale *= oosm;
    }
    return result;
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
    cold_size: f64,
    hot_size: f64,
    cold_frequency: f64,
    hot_frequency: f64,

    // Cached basis generators (one per property; seed1 differs per property).
    gen5: noise.BasisNoiseGen, // temperature (seed1=5)
    gen6: noise.BasisNoiseGen, // moisture    (seed1=6)
    gen7: noise.BasisNoiseGen, // aux         (seed1=7)

    pub fn init(cfg: Config) ZoneTerrain {
        return .{
            .map_seed = cfg.map_seed,
            .moisture_frequency = cfg.moisture_frequency,
            .moisture_bias = cfg.moisture_bias,
            .aux_frequency = cfg.aux_frequency,
            .aux_bias = cfg.aux_bias,
            .cold_size = cfg.cold_size,
            .hot_size = cfg.hot_size,
            .cold_frequency = cfg.cold_frequency,
            .hot_frequency = cfg.hot_frequency,
            .gen5 = noise.BasisNoiseGen.init(cfg.map_seed, 5),
            .gen6 = noise.BasisNoiseGen.init(cfg.map_seed, 6),
            .gen7 = noise.BasisNoiseGen.init(cfg.map_seed, 7),
        };
    }

    pub const Config = struct {
        map_seed: u32,
        moisture_frequency: f64,
        moisture_bias: f64,
        aux_frequency: f64,
        aux_bias: f64,
        cold_size: f64,
        hot_size: f64,
        cold_frequency: f64,
        hot_frequency: f64,
    };

    /// moisture = clamp(0.5 + 2.2*bias + 2.5*qmn{...}, 0, 1)
    pub fn moisture(self: *const ZoneTerrain, x: f64, y: f64) f64 {
        return self.moistureF(x, y, self.moisture_frequency);
    }
    pub fn moistureF(self: *const ZoneTerrain, x: f64, y: f64, freq: f64) f64 {
        const q = quickMultioctave(&self.gen6, x * freq, y * freq, 8, 1.0 / 2000.0, 1.0 / 8.0, 3.0, 0.5, 30000.0, 0.0);
        return clamp(0.5 + 2.2 * self.moisture_bias + 2.5 * q, 0.0, 1.0);
    }

    /// aux = clamp(0.45 + 2.2*bias + 2.2*qmn{...}, 0, 1)
    pub fn aux(self: *const ZoneTerrain, x: f64, y: f64) f64 {
        const q = quickMultioctave(&self.gen7, x * self.aux_frequency, y * self.aux_frequency, 8, 1.0 / 5000.0, 1.0 / 4.0, 3.0, 0.5, 20000.0, 0.0);
        return clamp(0.45 + 2.2 * self.aux_bias + 2.2 * q, 0.0, 1.0);
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
            .slake_gens = .{
                noise.BasisNoiseGen.init(map_seed, 14),
                noise.BasisNoiseGen.init(map_seed, 15),
                noise.BasisNoiseGen.init(map_seed, 16),
                noise.BasisNoiseGen.init(map_seed, 17),
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
    pub fn nauvisPersistancePub(self: *const Elevation, x: f64, y: f64) f64 {
        return self.nauvisPersistance(x, y);
    }

    pub fn at(self: *const Elevation, x0: f64, y0: f64) f64 {
        // Factorio evaluates map-gen noise at the TILE CENTER, not the corner.
        const x = x0 + 0.5;
        const y = y0 + 0.5;
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
};
