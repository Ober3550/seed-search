/// SE seed finder — batch runner for gen.zig.
///
/// Environment:
///   START_SEED          First seed (default 341)
///   COUNT               Seeds to generate (default 1)
///   SE_K2 / SE_ENABLE_K2  Enable Krastorio2 (1 or true)
///   MIN_NAQ_DV          Naquium field delta-v filter (0=off)
///   MIN_PROD_MODULES    Prod module filter (0=off)
///   NAQ_DV_LOW/HIGH     Naquium-field Δv extremity tails (0=off)
///   PLANETS_LOW/HIGH    Calidus planets+moons extremity tails (0=off)
///   WATER_PCT_LOW/HIGH  Water share of Calidus bodies, % (0=off)
///   ENEMY_PCT_LOW/HIGH  Hostile share of Calidus bodies, % (0=off)
///   METRICS_SCAN        Dump "seed,np,nw,ne,wp,ef,naqdv,fdv,ed", no JSONL
///   OUTPUT_DIR          Output directory (default "output")
///   MAX_LINES_PER_FILE  Lines per JSONL file before rotating (default 10000)
///
/// Output:
///   stderr → progress log (redirect to file in docker)
///   OUTPUT_DIR/seeds_N.jsonl → rotating JSONL, auto-resumes from last seed
const std = @import("std");
const gen = @import("gen.zig");
const data = @import("data.zig");
const filter_mod = @import("filter.zig");

fn getEnvU32(comptime name: [:0]const u8, default: u32) u32 {
    const val = std.c.getenv(name) orelse return default;
    return std.fmt.parseInt(u32, std.mem.sliceTo(val, 0), 10) catch default;
}
fn getEnvBool(comptime name: [:0]const u8) bool {
    const val = std.c.getenv(name) orelse return false;
    const s = std.mem.sliceTo(val, 0);
    return std.mem.eql(u8, s, "1") or std.mem.eql(u8, s, "true");
}

/// Stellar (solar-system) position of a zone: a field carries its own; a
/// planet/moon inherits its star's, found by walking parent_index up to the star.
fn starStellar(zones: []const gen.Zone, z: gen.Zone) struct { x: f64, y: f64 } {
    if (z.ztype == .@"asteroid-field") return .{ .x = z.stellar_x, .y = z.stellar_y };
    var p = z.parent_index;
    while (p >= 0 and zones[@intCast(p)].ztype != .star) p = zones[@intCast(p)].parent_index;
    if (p >= 0) return .{ .x = zones[@intCast(p)].stellar_x, .y = zones[@intCast(p)].stellar_y };
    return .{ .x = z.stellar_x, .y = z.stellar_y };
}

/// SE `Zone.get_travel_delta_v(Nauvis, z)` — the value the in-game navigation Δv
/// column shows (TRAVEL ONLY; the launch term 500+radius is a rocket-fuel add-on
/// the map column does not include). travel: same solar system → planet-gravity
/// diff (same planetary system) or star-gravity diff + both planet gravities;
/// else interstellar → stellar distance + both star & planet gravities. (cx,cy) =
/// the Calidus stellar pos = Nauvis's own. No space distortion in play. Caller
/// rounds to nearest (the game rounds, not ceils).
fn deltaVFromNauvis(zones: []const gen.Zone, z: gen.Zone, nauvis_sgw: f64, nauvis_pgw: f64, cx: f64, cy: f64) f64 {
    const sp = starStellar(zones, z);
    if (sp.x == cx and sp.y == cy) {
        return if (@abs(z.star_gravity_well - nauvis_sgw) < 0.01)
            100.0 * @abs(z.planet_gravity_well - nauvis_pgw)
        else
            500.0 * @abs(z.star_gravity_well - nauvis_sgw) + 100.0 * nauvis_pgw + 100.0 * z.planet_gravity_well;
    }
    const dx = sp.x - cx;
    const dy = sp.y - cy;
    const dist = @sqrt(dx * dx + dy * dy);
    return 400.0 * dist + 500.0 * (nauvis_sgw + z.star_gravity_well) + 100.0 * (nauvis_pgw + z.planet_gravity_well);
}

/// Parse "s":NNN from the start of a JSON line. Returns 0 on failure.
fn parseSeedFromJson(line: []const u8) u32 {
    const needle = "\"s\":";
    const idx = std.mem.indexOf(u8, line, needle) orelse return 0;
    var rest = line[idx + needle.len ..];
    const end = std.mem.indexOfScalar(u8, rest, ',') orelse std.mem.indexOfScalar(u8, rest, '}') orelse rest.len;
    return std.fmt.parseInt(u32, rest[0..end], 10) catch 0;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const a = arena.allocator();

    // Body prototypes are static (built from the data tables), so build the lookup
    // map ONCE on a persistent allocator instead of rebuilding it every seed on
    // the per-seed arena — that was ~200 string-hash inserts/seed for nothing.
    const bodyMap = try gen.buildBodyMap(std.heap.page_allocator);

    const end_seed = getEnvU32("END_SEED", 100000);
    const k2_enabled = getEnvBool("SE_K2") or getEnvBool("SE_ENABLE_K2");
    const start_seed = getEnvU32("START_SEED", 0);
    // ALL_ZONES=1 → serialize EVERY zone in the universe (all star systems +
    // deep-space asteroid fields), not just the Calidus home system. Used by the
    // GUI's per-seed "expand" job; bulk generation leaves it off to keep storage
    // to the Calidus system only.
    const all_zones = getEnvBool("ALL_ZONES");

    // DSL filter: the frontend ships a single JSON filter as FILTER. Parse it
    // ONCE on the page allocator — the Node tree must survive across arena
    // resets (per-seed loop). Leaked at process exit, fine for a batch runner.
    const filter: ?filter_mod.Filter = if (std.c.getenv("FILTER")) |fenv|
        filter_mod.Filter.parse(std.heap.page_allocator, std.mem.sliceTo(fenv, 0)) catch null
    else
        null;

    std.debug.print("# Generating seeds {d} to {d} (K2={})\n", .{ start_seed, end_seed, k2_enabled });

    var seed = start_seed;
    var passed: u32 = 0;
    const t_start = std.Io.Clock.awake.now(io).nanoseconds;
    var last_t = t_start;
    var last_seed = start_seed;
    var last_passed: u32 = 0;

    // Single stdout writer for the whole run (creating one per seed resets the
    // file offset to 0 and clobbers previous seeds when stdout is a regular file).
    var stdout_buf: [1 << 16]u8 = undefined;
    var stdout_fw = std.Io.File.stdout().writer(io, &stdout_buf);
    const stdout_w = &stdout_fw.interface;

    while (seed <= end_seed) : (seed += 2) {
        if (seed != start_seed) _ = arena.reset(.retain_capacity);

        // A degenerate RNG draw (gen.zig, Rng.int1) is a point where SE's own
        // arithmetic yields an out-of-range index. Tags reproduce SE exactly
        // (the tag stays unset); the shuffle/index sites cannot, because SE
        // corrupts or errors there. Either way the seed is worth naming so it
        // can be excluded from conformance work. The defer runs per iteration,
        // including on `continue`.
        gen.degen_draws = 0;
        defer if (gen.degen_draws > 0) std.debug.print(
            "# DEGENERATE seed {d}: {d} out-of-range RNG draw(s), universe not conformance-verified\n",
            .{ seed, gen.degen_draws },
        );

        if (seed > start_seed and (seed - start_seed) % 2000 == 0) {
            const now = std.Io.Clock.awake.now(io).nanoseconds;
            const elapsed_s: f64 = @as(f64, @floatFromInt(now - t_start)) / 1_000_000_000.0;
            const delta_s: f64 = @as(f64, @floatFromInt(now - last_t)) / 1_000_000_000.0;
            const delta_seeds = seed - last_seed;
            const rate: u32 = if (delta_s > 0) @intFromFloat(@round(@as(f64, @floatFromInt(delta_seeds)) / delta_s)) else 0;
            const worker_id = getEnvU32("WORKER_ID", 0);
            std.debug.print("worker {d}, [{d:>3.0}s] seed {d} rate {d}/s, passed {d}\n", .{ worker_id, elapsed_s, seed, rate, passed });
            last_t = now;
            last_seed = seed;
            last_passed = passed;
        }

        var universe = gen.generateUniverse(a, seed, k2_enabled) catch |err| {
            std.debug.print("# ERROR seed {d}: {}\n", .{ seed, err });
            // loop advances seed
            continue;
        };

        const primaries = gen.resolvePrimaries(a, universe.zones, bodyMap, k2_enabled) catch unreachable;
        const field_primaries = gen.resolveFieldPrimaries(a, universe.zones, k2_enabled) catch unreachable;
        gen.computeGravityWells(&universe);

        if (getEnvBool("DUMP_TREE")) {
            // Special (Phase-6) moons live at/after the last asteroid-field and sort
            // to the FRONT of their planet (add_special_moon inserts at index 1) —
            // the same order computeGravityWells uses and the game shows.
            var ts: usize = universe.zones.items.len;
            var ti = universe.zones.items.len;
            while (ti > 0) {
                ti -= 1;
                if (universe.zones.items[ti].ztype == .@"asteroid-field") {
                    ts = ti + 1;
                    break;
                }
            }
            for (universe.zones.items, 0..) |pz, pi| {
                if (pz.ztype != .planet) continue;
                const pidx: i32 = @intCast(pi);
                var line: [512]u8 = undefined;
                const w = std.fmt.bufPrint(&line, "# {s}:", .{pz.name}) catch continue;
                var end = w.len;
                var mi = universe.zones.items.len;
                while (mi > ts) {
                    mi -= 1;
                    const cz = universe.zones.items[mi];
                    if (cz.ztype == .moon and cz.parent_index == pidx) {
                        const seg = std.fmt.bufPrint(line[end..], " {s}", .{cz.name}) catch break;
                        end += seg.len;
                    }
                }
                for (universe.zones.items[0..ts]) |cz| {
                    if (cz.ztype == .moon and cz.parent_index == pidx) {
                        const seg = std.fmt.bufPrint(line[end..], " {s}", .{cz.name}) catch break;
                        end += seg.len;
                    }
                }
                std.debug.print("{s}\n", .{line[0..end]});
            }
        }

        const nauvis_zi = universe.zoneByName.get("Nauvis") orelse @panic("Nauvis not found");
        const nauvis_sgw = universe.zones.items[nauvis_zi].star_gravity_well;
        const nauvis_pgw = universe.zones.items[nauvis_zi].planet_gravity_well;

        // Calidus home system membership. The zone list is laid out as:
        //   [ ...star systems (Calidus among them)... ][ asteroid-fields ][ tail ]
        // Calidus's Phase-5 bodies (Nauvis + planets/moons/belts) sit contiguously
        // right after the "Calidus" star zone, up to the next star (or the first
        // asteroid-field, if Calidus is the LAST star). BUT every special-resource
        // body (vulcanite/vitamelange/iridium/holmium/cryonite/beryllium/methane
        // planets & moons, haven, kr-imersite) is added in Phase 6 and appended to
        // the TAIL — after all asteroid-fields — and is ALSO a Calidus home-system
        // member. So the home system = [calidus_zi, zone_end) ∪ [tail_start, end).
        // (Everything after the last asteroid-field is Phase-6 Calidus-only.)
        const calidus_zi = universe.zoneByName.get("Calidus") orelse @panic("Calidus not found");
        var zone_end: usize = universe.zones.items.len;
        for (universe.zones.items[calidus_zi + 1 ..], calidus_zi + 1..) |z, si| {
            if (z.ztype == .star or z.ztype == .@"asteroid-field") {
                zone_end = si;
                break;
            }
        }
        var tail_start: usize = universe.zones.items.len;
        {
            var ti = universe.zones.items.len;
            while (ti > 0) {
                ti -= 1;
                if (universe.zones.items[ti].ztype == .@"asteroid-field") {
                    tail_start = ti + 1;
                    break;
                }
            }
        }
        // A zone index is a Calidus home-system member iff it's in either range.
        const inCalidus = struct {
            fn f(si: usize, czi: usize, zend: usize, tstart: usize) bool {
                return (si >= czi and si < zend) or si >= tstart;
            }
        }.f;

        // --- Per-seed metrics (drive the tail filters AND ride in the JSONL) ---
        // np: planets + moons in the Calidus home system (incl. Nauvis). Planet
        // counts across other stars are ~constant, so Calidus carries the signal.
        // ed: PROPORTIONAL enemy danger — mean enemy level (0..6) over the Calidus
        // planets+moons, scaled to 0..100%. Mean (not sum) so a few high-enemy
        // surfaces read as more dangerous than many surfaces that are mostly calm.
        // nw / ne: counts of Calidus planets+moons that HAVE water resp. carry
        // enemies; wp / ef: those counts NORMALISED to a 0..100 percentage of the
        // bodies they were drawn from. Both read the intuitive way round: 0% water
        // means no body has any, 100% means every body does. The filters use the percentages, not the
        // counts. Raw counts track system size almost perfectly (measured over
        // 50k seeds: corr(np, ne) = 0.94), so a raw-count tail just re-selects
        // the biggest systems that the PLANETS_HIGH tail already catches — it
        // measures how BIG a system is, not how dry or how hostile. Same reason
        // `ed` is a mean rather than a sum.
        // All four exclude Nauvis, as `ed` does: it carries no universe-assigned
        // tags, so counting it would add a constant to every seed and flatten
        // the very tails these drive.
        var npl: u32 = 0; // Calidus planets only (incl Nauvis)
        var np: u32 = 0; // Calidus planets + moons (incl Nauvis)
        var body_cnt: u32 = 0; // tagged bodies = Calidus planets+moons, less Nauvis
        var nw: u32 = 0; // ...of those, with water (water tag present and > none)
        var ne: u32 = 0; // ...of those, hostile (enemy tag present and > none)
        // ed: SIGNED enemy value in [-100, 100] with an ODD-POWER response so
        // EXTREME systems dominate. Each body's enemy level L (0=none..6=max;
        // untagged = none) is centred to x = 2·(L/6) − 1 ∈ [-1, 1] (peaceful = -1,
        // max = +1), passed through sign(x)·|x|^ENEMY_EXP (>1 flattens the calm
        // middle and steepens both ends, so a `max` or a `none` counts for more
        // than a `med`), then averaged over the bodies and scaled to ±100.
        // Negative = net peaceful, positive = net hostile. Mean (not sum) so it
        // measures how hostile the system is, not how big.
        const ENEMY_EXP: f64 = 3.0;
        var ev_sum: f64 = 0;
        for (universe.zones.items, 0..) |z, si| {
            if (!inCalidus(si, calidus_zi, zone_end, tail_start)) continue;
            if (z.ztype != .planet and z.ztype != .moon) continue;
            np += 1; // planet+moon, INCLUDING Nauvis (matches in-game)
            if (z.ztype == .planet) npl += 1;
            if (std.mem.eql(u8, z.name, "Nauvis")) continue; // Nauvis has no universe enemy tag
            body_cnt += 1;
            const tags = gen.computeTags(z.seed, z.name, bodyMap);
            // An unset tag reads as "none" everywhere else (the JSONL omits null
            // tags and the GUI renders the absence as "none"), so an absent water
            // tag counts as dry and an absent enemy tag as peaceful, rather than
            // as unknown.
            if (tags.water) |w| { if (w != .none) nw += 1; }
            const lvl: u32 = if (tags.enemy) |e| @intFromEnum(e) else 0;
            if (lvl > 0) ne += 1;
            const x: f64 = 2.0 * (@as(f64, @floatFromInt(lvl)) / 6.0) - 1.0;
            const gmag = std.math.pow(f64, @abs(x), ENEMY_EXP);
            ev_sum += if (x < 0) -gmag else gmag;
        }
        // Percentage of Calidus bodies that have water / are hostile (0..100).
        const wp: u32 = if (body_cnt > 0) (nw * 100) / body_cnt else 0;
        const ef: u32 = if (body_cnt > 0) (ne * 100) / body_cnt else 0;
        const ed: i32 = if (body_cnt > 0) @intFromFloat(@round(ev_sum / @as(f64, @floatFromInt(body_cnt)) * 100.0)) else 0;
        // Two field distances (NO_NAQ = 10,000,000 sentinel when none exist):
        //   naqdv = delta-v to the nearest naquium-PRIMARY field (a rich naq
        //           source — drives the CLOSEST/best tail).
        //   fdv   = delta-v to the nearest ANY asteroid field (every field yields
        //           some naquium — drives the FURTHEST/worst tail, so "even the
        //           closest field is a long haul").
        const NO_NAQ: u32 = 10_000_000;
        var naqdv: u32 = NO_NAQ;
        var fdv: u32 = NO_NAQ;
        {
            const cx = universe.zones.items[calidus_zi].stellar_x;
            const cy = universe.zones.items[calidus_zi].stellar_y;
            for (universe.zones.items) |z| {
                if (z.ztype != .@"asteroid-field") continue;
                const dv: u32 = @intFromFloat(@round(deltaVFromNauvis(universe.zones.items, z, nauvis_sgw, nauvis_pgw, cx, cy)));
                if (dv < fdv) fdv = dv; // any field
                const fp = field_primaries.get(z.name) orelse continue;
                if (!std.mem.eql(u8, fp, "se-naquium-ore")) continue;
                if (dv < naqdv) naqdv = dv; // naquium-primary field
            }
        }

        // --- Distribution scan (tuning aid) ---
        // One CSV row per seed, emitted BEFORE the tail filters so the cutoffs
        // below can be picked from the real population rather than guessed.
        // Skips JSONL entirely. Columns: seed,np,nw,ne,naqdv,fdv,ed
        if (getEnvBool("METRICS_SCAN")) {
            var mb: [160]u8 = undefined;
            const ms = std.fmt.bufPrint(&mb, "{d},{d},{d},{d},{d},{d},{d},{d},{d}\n", .{ seed, np, nw, ne, wp, ef, naqdv, fdv, ed }) catch unreachable;
            _ = stdout_w.writeAll(ms) catch {};
            continue;
        }

        // --- Tail filters ---
        // No FILTER env → legacy UNION of up to eight extremity tails (below),
        // unchanged fast path (no cutoffs set → keep everything). FILTER env →
        // the generic JSON filter evaluator decides keep/discard; it parses once
        // at startup and evaluates per seed with no allocation, computing each
        // surface's deltaV / resource-FSR lazily only when a predicate queries it.
        if (filter) |flt| {
            var cache: filter_mod.SurfaceCache = undefined;
            const ein = filter_mod.EvalInput{
                .zones = universe.zones.items,
                .body_map = bodyMap,
                .primaries = primaries,
                .field_primaries = field_primaries,
                .calidus_zi = calidus_zi,
                .zone_end = zone_end,
                .tail_start = tail_start,
                .nauvis_sgw = nauvis_sgw,
                .nauvis_pgw = nauvis_pgw,
                .cx = universe.zones.items[calidus_zi].stellar_x,
                .cy = universe.zones.items[calidus_zi].stellar_y,
            };
            if (!flt.eval(&ein, &cache)) continue;
        } else {
            // --- Tail filters: UNION of up to eight extremity tails ---
            // Each metric is roughly bell-shaped across seeds; these cutoffs keep the
            // two extremes and discard the middle. Keep a seed if it falls in ANY
            // enabled tail: naquium-PRIMARY field <= NAQ_DV_LOW (closest, rich naq)
            // or ANY field >= NAQ_DV_HIGH (furthest, even basic naq is a long haul);
            // Calidus planets+moons >= PLANETS_HIGH (most) or <= PLANETS_LOW
            // (fewest); water share <= WATER_PCT_LOW (a parched system) or >=
            // WATER_PCT_HIGH (a wet one); hostile share <= ENEMY_PCT_LOW (a quiet
            // system) or >= ENEMY_PCT_HIGH (a warzone). The last four are
            // PERCENTAGES (0..100), not counts — see wp/ef above.
            // Each cutoff of 0 disables that tail; no cutoffs set → keep everything.
            // Union (not AND). MIN_NAQ_DV is a back-compat alias for NAQ_DV_LOW.
            const naq_lo = getEnvU32("NAQ_DV_LOW", getEnvU32("MIN_NAQ_DV", 0));
            const naq_hi = getEnvU32("NAQ_DV_HIGH", 0);
            const pl_lo = getEnvU32("PLANETS_LOW", 0);
            const pl_hi = getEnvU32("PLANETS_HIGH", 0);
            const wp_lo = getEnvU32("WATER_PCT_LOW", 0);
            const wp_hi = getEnvU32("WATER_PCT_HIGH", 0);
            const ef_lo = getEnvU32("ENEMY_PCT_LOW", 0);
            const ef_hi = getEnvU32("ENEMY_PCT_HIGH", 0);
            const any_cut = naq_lo > 0 or naq_hi > 0 or pl_lo > 0 or pl_hi > 0 or
                wp_lo > 0 or wp_hi > 0 or ef_lo > 0 or ef_hi > 0;
            const keep = !any_cut or
                (naq_lo > 0 and naqdv <= naq_lo) or
                (naq_hi > 0 and fdv >= naq_hi) or
                (pl_hi > 0 and np >= pl_hi) or
                (pl_lo > 0 and np <= pl_lo) or
                (wp_hi > 0 and wp >= wp_hi) or
                (wp_lo > 0 and wp <= wp_lo) or
                (ef_hi > 0 and ef >= ef_hi) or
                (ef_lo > 0 and ef <= ef_lo);
            if (!keep) continue;
        }

        const min_prod = getEnvU32("MIN_PROD_MODULES", 0);
        if (min_prod > 0) {
            var p_count: u32 = 0;
            for (universe.vault_loot) |c| {
                if (c == 'P') p_count += 1;
            }
            if (p_count < min_prod) continue;
        }

        // --- Fast scan: nearest asteroid field where naquium is the #1 yield ---
        // Emits one "dv\n" per qualifying seed (nothing otherwise). Skips JSONL.
        // NOTE: uses the current (pre-quota-fix) null-primary yield ranking, so it
        // OVER-counts naquium-primary fields — treat as an upper bound.
        if (getEnvBool("NAQ_SCAN")) {
            const calidus_zi2 = universe.zoneByName.get("Calidus") orelse @panic("Calidus not found");
            const cx = universe.zones.items[calidus_zi2].stellar_x;
            const cy = universe.zones.items[calidus_zi2].stellar_y;
            const empty_tags: gen.Tags = .{ .temperature = null, .water = null, .moisture = null, .trees = null, .aux = null, .cliff = null, .enemy = null };
            _ = empty_tags;
            var best_dv: u32 = std.math.maxInt(u32);
            for (universe.zones.items) |z| {
                if (z.ztype != .@"asteroid-field") continue;
                // naquium is this field's quota-assigned PRIMARY
                const fp = field_primaries.get(z.name) orelse continue;
                if (!std.mem.eql(u8, fp, "se-naquium-ore")) continue;
                const dv: u32 = @intFromFloat(@round(deltaVFromNauvis(universe.zones.items, z, nauvis_sgw, nauvis_pgw, cx, cy)));
                if (dv < best_dv) best_dv = dv;
            }
            if (best_dv != std.math.maxInt(u32)) {
                var lb: [16]u8 = undefined;
                const ls = std.fmt.bufPrint(&lb, "{d}\n", .{best_dv}) catch unreachable;
                _ = stdout_w.writeAll(ls) catch {};
            }
            continue;
        }

        // --- Serialize JSONL ---
        // Default: the Calidus home system only. ALL_ZONES=1: every zone in the
        // universe (bigger output → allocate on the arena, not the stack).
        const buf = try a.alloc(u8, if (all_zones) 8 << 20 else 524288);
        var pos: usize = 0;
        // Per-seed metrics ride in the header: np (Calidus planets+moons) and
        // naqdv (nearest naquium-primary field Δv) — so both extremes are
        // sortable/filterable even though only Calidus zones are stored.
        const open = std.fmt.bufPrint(buf[pos..], "{{\"s\":{d},\"d\":{d},\"k\":{},\"l\":\"{s}\",\"npl\":{d},\"npm\":{d},\"nw\":{d},\"ne\":{d},\"wp\":{d},\"ef\":{d},\"naqdv\":{d},\"fdv\":{d},\"ed\":{d},\"z\":[", .{ seed, universe.draws, k2_enabled, universe.vault_loot, npl, np, nw, ne, wp, ef, naqdv, fdv, ed }) catch unreachable;
        pos += open.len;

        // calidus_zi / zone_end were computed above (for the metrics). The default
        // serializes only [calidus_zi, zone_end); ALL_ZONES serializes the whole
        // universe. Either way each planet/moon/asteroid-field gets full tags +
        // resources from the same emit code below.
        var zi: u32 = 0;
        for (universe.zones.items, 0..) |z, si| {
            if (!all_zones and !inCalidus(si, calidus_zi, zone_end, tail_start)) continue; // Calidus home system (Phase-5 slice + Phase-6 tail)
            // Nauvis uses map-gen UI settings, not universe generation
            if (std.mem.eql(u8, z.name, "Nauvis")) continue;
            // Orbits carry no resource data
            if (z.ztype == .orbit) continue;
            // Stars carry no resource data
            if (z.ztype == .star) continue;
            if (zi > 0) {
                buf[pos] = ',';
                pos += 1;
            }
            zi += 1;
            // "c": is this zone a Calidus home-system member? Only interesting
            // under ALL_ZONES (the default slice is Calidus by construction), but
            // emitted either way so consumers never have to infer it. Nothing
            // else in the zone object identifies its star, and the GUI drops the
            // stellar coords, so without this flag "hide other systems" would be
            // impossible downstream.
            const in_cal: u8 = if (inCalidus(si, calidus_zi, zone_end, tail_start)) 1 else 0;
            const ob = std.fmt.bufPrint(buf[pos..], "{{\"i\":{d},\"n\":\"{s}\",\"t\":\"{s}\",\"s\":{d},\"c\":{d}", .{ zi, z.name, z.ztype.asStr(), z.seed, in_cal }) catch unreachable;
            pos += ob.len;
            if (z.radius > 0) {
                // Emit the exact fractional radius: the surface gen derives the
                // noise frequency (fm = 5000/radius) from it, and rounding to an
                // integer shifts every temperature/moisture boundary slightly
                // (Grishord true radius 2926.3885 vs rounded 2926 → cold_freq
                // 1.708591 vs 1.708817). {d} on an f64 prints full precision.
                const rp = std.fmt.bufPrint(buf[pos..], ",\"r\":{d}", .{z.radius}) catch unreachable;
                pos += rp.len;
            }
            if (z.ztype == .@"asteroid-field" or z.ztype == .planet or z.ztype == .moon) {
                const tags = gen.computeTags(z.seed, z.name, bodyMap);
                if (tags.temperature) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"temperature\":\"{s}\"", .{@tagName(v)}) catch unreachable;
                    pos += t.len;
                }
                if (tags.water) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"water\":\"{s}\"", .{@tagName(v)}) catch unreachable;
                    pos += t.len;
                }
                if (tags.moisture) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"moisture\":\"{s}\"", .{@tagName(v)}) catch unreachable;
                    pos += t.len;
                }
                if (tags.trees) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"trees\":\"{s}\"", .{@tagName(v)}) catch unreachable;
                    pos += t.len;
                }
                if (tags.aux) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"aux\":\"{s}\"", .{@tagName(v)}) catch unreachable;
                    pos += t.len;
                }
                if (tags.cliff) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"cliff\":\"{s}\"", .{@tagName(v)}) catch unreachable;
                    pos += t.len;
                }
                if (tags.enemy) |v| {
                    const t = std.fmt.bufPrint(buf[pos..], ",\"enemy\":\"{s}\"", .{@tagName(v)}) catch unreachable;
                    pos += t.len;
                }
                // Primary resource + per-resource FSR scores. The primary is
                // emitted as "p"; the normalized FSR scores (freq*size*richness
                // / norm, indexed by resource_order) as an "rs" map keyed by
                // resource name. Only nonzero scores are emitted. The primary's
                // score is included and is the max (==1.0 on planets); this lets
                // consumers derive "primary" as the max-score resource and
                // filter on richness directly, instead of relying on a separate
                // boolean.
                const primary = primaries.get(z.name) orelse field_primaries.get(z.name);
                if (primary) |prim| {
                    const prim_out = gen.resourceOutputName(prim);
                    const pp = std.fmt.bufPrint(buf[pos..], ",\"p\":\"{s}\"", .{prim_out}) catch unreachable;
                    pos += pp.len;
                    const controls = gen.computeZoneResources(z.seed, z.ztype, prim, tags);
                    var first_res = true;
                    buf[pos] = ','; pos += 1;
                    const rsO = std.fmt.bufPrint(buf[pos..], "\"rs\":{{", .{}) catch unreachable;
                    pos += rsO.len;
                    for (gen.resource_name_output, controls) |rname, score| {
                        if (!first_res) { buf[pos] = ','; pos += 1; }
                        first_res = false;
                        // Missing resources (score <= 0) are emitted as 0.0, so
                        // "present" is testable with { ">": 0 }; present
                        // resources have scores in (0, 1].
                        if (score <= 0) {
                            const en = std.fmt.bufPrint(buf[pos..], "\"{s}\":0.0", .{rname}) catch unreachable;
                            pos += en.len;
                        } else {
                            const en = std.fmt.bufPrint(buf[pos..], "\"{s}\":{d}", .{ rname, score }) catch unreachable;
                            pos += en.len;
                        }
                    }
                    buf[pos] = '}'; pos += 1;
                }
                if (nauvis_sgw > 0) {
                    const cx = universe.zones.items[calidus_zi].stellar_x;
                    const cy = universe.zones.items[calidus_zi].stellar_y;
                    const dv: u32 = @intFromFloat(@round(deltaVFromNauvis(universe.zones.items, z, nauvis_sgw, nauvis_pgw, cx, cy)));
                    const dp = std.fmt.bufPrint(buf[pos..], ",\"dv\":{d}", .{dv}) catch unreachable;
                    pos += dp.len;
                }
            }
            if (z.ztype == .@"asteroid-field") {
                const cx = universe.zones.items[calidus_zi].stellar_x;
                const cy = universe.zones.items[calidus_zi].stellar_y;
                const dv: u32 = @intFromFloat(@round(deltaVFromNauvis(universe.zones.items, z, nauvis_sgw, nauvis_pgw, cx, cy)));
                const dp = std.fmt.bufPrint(buf[pos..], ",\"dv\":{d}", .{dv}) catch unreachable;
                pos += dp.len;
            }
            buf[pos] = '}';
            pos += 1;
        }
        buf[pos] = ']';
        pos += 1;
        buf[pos] = '}';
        pos += 1;
        buf[pos] = '\n';
        pos += 1;

        // writeAll loops until the whole slice is written. (writeSplat returns a
        // possibly-partial count; for writes larger than the writer buffer — e.g.
        // ~300 KB ALL_ZONES lines piped to the GUI — the unwritten tail was being
        // dropped.)
        try stdout_w.writeAll(buf[0..pos]);
        passed += 1;

        // loop advances seed
    }
    try stdout_w.flush();
}
