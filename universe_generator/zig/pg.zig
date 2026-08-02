//! Direct Postgres writer for the universe generator (libpq via @cImport).
//! Enabled when DATABASE_URL is set; otherwise the generator keeps its JSONL
//! stdout path. Rows are streamed with COPY, batched per N seeds inside a
//! transaction. Schema: db/schema.sql (seeds / zone / zone_resource + dicts).
const std = @import("std");
const c = @cImport({
    @cInclude("libpq-fe.h");
});

const Alloc = std.mem.Allocator;
fn List(comptime T: type) type {
    return std.array_list.AlignedManaged(T, null);
}

/// Format into a small stack buffer and append (avoids the 0.16 writer churn).
fn appFmt(buf: *List(u8), comptime fmt: []const u8, args: anytype) !void {
    var tmp: [64]u8 = undefined;
    const s = std.fmt.bufPrint(&tmp, fmt, args) catch return error.Overflow;
    try buf.appendSlice(s);
}

/// COPY text-format escaping for a single field (tab/newline/backslash).
fn appendText(buf: *List(u8), s: []const u8) !void {
    for (s) |ch| switch (ch) {
        '\\' => try buf.appendSlice("\\\\"),
        '\t' => try buf.appendSlice("\\t"),
        '\n' => try buf.appendSlice("\\n"),
        '\r' => try buf.appendSlice("\\r"),
        else => try buf.append(ch),
    };
}

/// u32 → INT4 encoding: Postgres has no unsigned int4, so seed/zone_seed are
/// stored as (value − 2^31). The offset preserves sort order (monotonic), and
/// readers add it back. Applied here (the DB layer); callers pass raw u32.
const SEED_OFFSET: i64 = 2147483648;

pub const Db = struct {
    conn: ?*c.PGconn,
    alloc: Alloc,
    seeds: List(u8),
    zone: List(u8),
    zres: List(u8),
    names: std.StringHashMapUnmanaged(u32) = .{},
    batch: u32 = 0,
    batch_size: u32 = 2000,

    pub fn connect(alloc: Alloc, url: [*c]const u8) !Db {
        const conn = c.PQconnectdb(url);
        if (c.PQstatus(conn) != c.CONNECTION_OK) {
            std.debug.print("# pg connect failed: {s}\n", .{c.PQerrorMessage(conn)});
            return error.PgConnect;
        }
        return .{
            .conn = conn,
            .alloc = alloc,
            .seeds = List(u8).init(alloc),
            .zone = List(u8).init(alloc),
            .zres = List(u8).init(alloc),
        };
    }

    pub fn exec(self: *Db, sql: [*c]const u8) !void {
        const res = c.PQexec(self.conn, sql);
        defer c.PQclear(res);
        const st = c.PQresultStatus(res);
        if (st != c.PGRES_COMMAND_OK and st != c.PGRES_TUPLES_OK) {
            std.debug.print("# pg exec failed: {s}\n", .{c.PQerrorMessage(self.conn)});
            return error.PgExec;
        }
    }

    /// COPY a whole text buffer into `table (cols)`.
    fn copyIn(self: *Db, table_cols: [*c]const u8, buf: []const u8) !void {
        if (buf.len == 0) return;
        var sql: [256]u8 = undefined;
        const cmd = std.fmt.bufPrintZ(&sql, "COPY {s} FROM STDIN", .{table_cols}) catch return error.PgExec;
        const res = c.PQexec(self.conn, cmd.ptr);
        defer c.PQclear(res);
        if (c.PQresultStatus(res) != c.PGRES_COPY_IN) {
            std.debug.print("# pg COPY start failed: {s}\n", .{c.PQerrorMessage(self.conn)});
            return error.PgExec;
        }
        if (c.PQputCopyData(self.conn, buf.ptr, @intCast(buf.len)) != 1) return error.PgExec;
        if (c.PQputCopyEnd(self.conn, null) != 1) return error.PgExec;
        const done = c.PQgetResult(self.conn);
        defer c.PQclear(done);
        if (c.PQresultStatus(done) != c.PGRES_COMMAND_OK) {
            std.debug.print("# pg COPY end failed: {s}\n", .{c.PQerrorMessage(self.conn)});
            return error.PgExec;
        }
    }

    /// Load the fixed name→id map (id = index) into memory. NO db writes: the
    /// zone_name dictionary is seeded once, out of band (db/dictionary.sql).
    pub fn loadNames(self: *Db, names: []const []const u8) !void {
        for (names, 0..) |name, i| {
            try self.names.put(self.alloc, try self.alloc.dupe(u8, name), @intCast(i));
        }
    }

    /// Zone name → its stable id (pure in-memory lookup, no db round-trip). The
    /// static list is exhaustive, so a miss is a bug (must add it to data.zig).
    pub fn internName(self: *Db, name: []const u8) !u32 {
        return self.names.get(name) orelse {
            std.debug.print("# FATAL: zone name not in static dictionary: {s}\n", .{name});
            return error.UnknownZoneName;
        };
    }

    // ── row append (COPY text: tab-separated, \N = null) ──────────────────
    fn tab(buf: *List(u8), first: *bool) !void {
        if (first.*) first.* = false else try buf.append('\t');
    }
    fn iField(buf: *List(u8), first: *bool, v: i64) !void {
        try tab(buf, first);
        try appFmt(buf, "{d}", .{v});
    }
    fn optI(buf: *List(u8), first: *bool, v: ?i64) !void {
        try tab(buf, first);
        if (v) |x| try appFmt(buf, "{d}", .{x}) else try buf.appendSlice("\\N");
    }
    fn optF(buf: *List(u8), first: *bool, v: ?f64) !void {
        try tab(buf, first);
        if (v) |x| try appFmt(buf, "{d}", .{x}) else try buf.appendSlice("\\N");
    }
    fn boolField(buf: *List(u8), first: *bool, v: bool) !void {
        try tab(buf, first);
        try buf.append(if (v) 't' else 'f');
    }
    fn optText(buf: *List(u8), first: *bool, v: ?[]const u8) !void {
        try tab(buf, first);
        if (v) |s| try appendText(buf, s) else try buf.appendSlice("\\N");
    }

    pub const SeedRow = struct {
        seed: i64, // raw u32; stored as seed − 2^31
        k2: bool,
        vault_loot: ?[]const u8,
        naquium_dv: ?i64,
        field_dv: ?i64,
        planets: ?i64,
        bodies: ?i64,
        water_bodies: ?i64,
        enemy_bodies: ?i64,
        water_pct: ?i64,
        hostility_pct: ?i64,
        enemy_danger: ?i64,
        score: i32,
    };

    pub fn addSeed(self: *Db, r: SeedRow) !void {
        var f = true;
        const b = &self.seeds;
        try iField(b, &f, r.seed - SEED_OFFSET);
        try boolField(b, &f, r.k2);
        try optText(b, &f, r.vault_loot);
        try optI(b, &f, r.naquium_dv);
        try optI(b, &f, r.field_dv);
        try optI(b, &f, r.planets);
        try optI(b, &f, r.bodies);
        try optI(b, &f, r.water_bodies);
        try optI(b, &f, r.enemy_bodies);
        try optI(b, &f, r.water_pct);
        try optI(b, &f, r.hostility_pct);
        try optI(b, &f, r.enemy_danger);
        try iField(b, &f, r.score);
        try b.append('\n');
    }

    pub const ZoneRow = struct {
        seed: i64, // raw u32; stored as seed − 2^31
        zone_seed: i64, // raw u32; stored as zone_seed − 2^31
        delta_v: ?i64,
        radius: ?f64,
        stellar_x: ?f64,
        stellar_y: ?f64,
        kind: i64,
        star_name_id: ?i64,
        parent_name_id: ?i64,
        zone_name_id: i64,
        primary_id: ?i64,
        temperature_idx: ?i64,
        water_idx: ?i64,
        moisture_idx: ?i64,
        trees_idx: ?i64,
        aux_idx: ?i64,
        cliff_idx: ?i64,
        enemy_idx: ?i64,
        resource_mask: ?i64,
    };

    pub fn addZone(self: *Db, r: ZoneRow) !void {
        var f = true;
        const b = &self.zone;
        try iField(b, &f, r.seed - SEED_OFFSET);
        try iField(b, &f, r.zone_seed - SEED_OFFSET);
        try optI(b, &f, r.delta_v);
        try optF(b, &f, r.radius);
        try optF(b, &f, r.stellar_x);
        try optF(b, &f, r.stellar_y);
        try iField(b, &f, r.kind);
        try optI(b, &f, r.star_name_id);
        try optI(b, &f, r.parent_name_id);
        try iField(b, &f, r.zone_name_id);
        try optI(b, &f, r.primary_id);
        try optI(b, &f, r.temperature_idx);
        try optI(b, &f, r.water_idx);
        try optI(b, &f, r.moisture_idx);
        try optI(b, &f, r.trees_idx);
        try optI(b, &f, r.aux_idx);
        try optI(b, &f, r.cliff_idx);
        try optI(b, &f, r.enemy_idx);
        try optI(b, &f, r.resource_mask);
        try b.append('\n');
    }

    pub fn addZoneResource(self: *Db, seed: i64, zone_name_id: i64, resource_id: i64, present: bool, frequency: f64, size: f64, richness: f64) !void {
        var f = true;
        const b = &self.zres;
        try iField(b, &f, seed - SEED_OFFSET);
        try iField(b, &f, zone_name_id);
        try iField(b, &f, resource_id);
        try boolField(b, &f, present);
        try optF(b, &f, frequency);
        try optF(b, &f, size);
        try optF(b, &f, richness);
        try b.append('\n');
    }

    pub fn endSeed(self: *Db) !void {
        self.batch += 1;
        if (self.batch >= self.batch_size) try self.flush();
    }

    pub fn flush(self: *Db) !void {
        if (self.batch == 0) return;
        // Pure integer/float COPY — no name strings written (the dictionaries are
        // pre-seeded from db/dictionary.sql; ids come from the in-memory maps).
        try self.exec("BEGIN");
        try self.copyIn("seeds(seed,k2,vault_loot,naquium_dv,field_dv,planets,bodies,water_bodies,enemy_bodies,water_pct,hostility_pct,enemy_danger,score)", self.seeds.items);
        try self.copyIn("zone(seed,zone_seed,delta_v,radius,stellar_x,stellar_y,kind,star_name_id,parent_name_id,zone_name_id,primary_id,temperature_idx,water_idx,moisture_idx,trees_idx,aux_idx,cliff_idx,enemy_idx,resource_mask)", self.zone.items);
        try self.copyIn("zone_resource(seed,zone_name_id,resource_id,present,frequency,size,richness)", self.zres.items);
        try self.exec("COMMIT");
        self.seeds.clearRetainingCapacity();
        self.zone.clearRetainingCapacity();
        self.zres.clearRetainingCapacity();
        self.batch = 0;
    }

    pub fn finish(self: *Db) void {
        self.flush() catch |e| std.debug.print("# pg FINAL flush FAILED ({}) — {d} rows lost\n", .{ e, self.batch });
        c.PQfinish(self.conn);
    }
};
