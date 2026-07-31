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

pub const Db = struct {
    conn: ?*c.PGconn,
    alloc: Alloc,
    seeds: List(u8),
    zone: List(u8),
    zres: List(u8),
    names: std.StringHashMapUnmanaged(u32) = .{},
    pending: List(NameRow),
    next_name_id: u32 = 0,
    batch: u32 = 0,
    batch_size: u32 = 2000,

    const NameRow = struct { id: u32, name: []const u8 };

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
            .pending = List(NameRow).init(alloc),
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

    /// Intern a zone name → stable id (queues a dict INSERT for new names).
    pub fn internName(self: *Db, name: []const u8) !u32 {
        if (self.names.get(name)) |id| return id;
        const id = self.next_name_id;
        self.next_name_id += 1;
        const owned = try self.alloc.dupe(u8, name);
        try self.names.put(self.alloc, owned, id);
        try self.pending.append(.{ .id = id, .name = owned });
        return id;
    }

    /// Seed all fixed dictionary entries (resources, zone kinds, tag enums).
    pub fn upsertStaticDicts(self: *Db, resources: []const []const u8) !void {
        var q = List(u8).init(self.alloc);
        defer q.deinit();
        try q.appendSlice("INSERT INTO resource(id,name) VALUES ");
        for (resources, 0..) |name, i| {
            if (i != 0) try q.append(',');
            try appFmt(&q, "({d},'{s}')", .{ i, name });
        }
        try q.appendSlice(" ON CONFLICT DO NOTHING;");
        try q.append(0);
        try self.exec(@ptrCast(q.items.ptr));
    }

    /// Seed enum_value(domain, code, name) from a Zig enum's fields.
    pub fn upsertEnum(self: *Db, domain: []const u8, comptime E: type) !void {
        var q = List(u8).init(self.alloc);
        defer q.deinit();
        try q.appendSlice("INSERT INTO enum_value(domain,code,name) VALUES ");
        inline for (@typeInfo(E).@"enum".fields, 0..) |fld, i| {
            if (i != 0) try q.append(',');
            try appFmt(&q, "('{s}',{d},'{s}')", .{ domain, fld.value, fld.name });
        }
        try q.appendSlice(" ON CONFLICT DO NOTHING;");
        try q.append(0);
        try self.exec(@ptrCast(q.items.ptr));
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
        seed: i64,
        k2: bool,
        draws: ?i64,
        vault_loot: ?[]const u8,
        npl: ?i64,
        npm: ?i64,
        nw: ?i64,
        ne: ?i64,
        wp: ?i64,
        ef: ?i64,
        naqdv: ?i64,
        fdv: ?i64,
        ed: ?i64,
    };

    pub fn addSeed(self: *Db, r: SeedRow) !void {
        var f = true;
        const b = &self.seeds;
        try iField(b, &f, r.seed);
        try boolField(b, &f, r.k2);
        try optI(b, &f, r.draws);
        try optText(b, &f, r.vault_loot);
        try optI(b, &f, r.npl);
        try optI(b, &f, r.npm);
        try optI(b, &f, r.nw);
        try optI(b, &f, r.ne);
        try optI(b, &f, r.wp);
        try optI(b, &f, r.ef);
        try optI(b, &f, r.naqdv);
        try optI(b, &f, r.fdv);
        try optI(b, &f, r.ed);
        try b.append('\n');
    }

    pub const ZoneRow = struct {
        seed: i64,
        zone_name_id: i64,
        kind: i64,
        star_name_id: ?i64,
        parent_name_id: ?i64,
        zone_seed: i64,
        radius: ?f64,
        primary_id: ?i64,
        dv: ?i64,
        temperature: ?i64,
        water: ?i64,
        moisture: ?i64,
        trees: ?i64,
        aux: ?i64,
        cliff: ?i64,
        enemy: ?i64,
        stellar_x: ?f64,
        stellar_y: ?f64,
        present_mask: ?i64,
    };

    pub fn addZone(self: *Db, r: ZoneRow) !void {
        var f = true;
        const b = &self.zone;
        try iField(b, &f, r.seed);
        try iField(b, &f, r.zone_name_id);
        try iField(b, &f, r.kind);
        try optI(b, &f, r.star_name_id);
        try optI(b, &f, r.parent_name_id);
        try iField(b, &f, r.zone_seed);
        try optF(b, &f, r.radius);
        try optI(b, &f, r.primary_id);
        try optI(b, &f, r.dv);
        try optI(b, &f, r.temperature);
        try optI(b, &f, r.water);
        try optI(b, &f, r.moisture);
        try optI(b, &f, r.trees);
        try optI(b, &f, r.aux);
        try optI(b, &f, r.cliff);
        try optI(b, &f, r.enemy);
        try optF(b, &f, r.stellar_x);
        try optF(b, &f, r.stellar_y);
        try optI(b, &f, r.present_mask);
        try b.append('\n');
    }

    pub fn addZoneResource(self: *Db, seed: i64, zone_name_id: i64, resource_id: i64, present: bool, frequency: f64, size: f64, richness: f64) !void {
        var f = true;
        const b = &self.zres;
        try iField(b, &f, seed);
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
        try self.exec("BEGIN");
        // new dictionary names first (FK targets), one multi-row INSERT
        if (self.pending.items.len != 0) {
            var q = List(u8).init(self.alloc);
            defer q.deinit();
            try q.appendSlice("INSERT INTO zone_name(id,name) VALUES ");
            for (self.pending.items, 0..) |nr, i| {
                if (i != 0) try q.append(',');
                try appFmt(&q, "({d},'", .{nr.id});
                for (nr.name) |ch| { // escape single quotes for SQL literal
                    if (ch == '\'') try q.append('\'');
                    try q.append(ch);
                }
                try q.appendSlice("')");
            }
            try q.appendSlice(" ON CONFLICT DO NOTHING;");
            try q.append(0);
            try self.exec(@ptrCast(q.items.ptr));
            self.pending.clearRetainingCapacity();
        }
        try self.copyIn("seeds(seed,k2,draws,vault_loot,npl,npm,nw,ne,wp,ef,naqdv,fdv,ed)", self.seeds.items);
        try self.copyIn("zone(seed,zone_name_id,kind,star_name_id,parent_name_id,zone_seed,radius,primary_id,dv,temperature,water,moisture,trees,aux,cliff,enemy,stellar_x,stellar_y,present_mask)", self.zone.items);
        try self.copyIn("zone_resource(seed,zone_name_id,resource_id,present,frequency,size,richness)", self.zres.items);
        try self.exec("COMMIT");
        self.seeds.clearRetainingCapacity();
        self.zone.clearRetainingCapacity();
        self.zres.clearRetainingCapacity();
        self.batch = 0;
    }

    pub fn finish(self: *Db) void {
        self.flush() catch {};
        c.PQfinish(self.conn);
    }
};
