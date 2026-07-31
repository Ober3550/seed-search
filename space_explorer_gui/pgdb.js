// Read-only Postgres access for the web app (new normalized schema).
// Connects as the least-privilege `explorer_ro` role. This is the first slice of
// the better-sqlite3 → pg migration: it proves the frontend can read the bucket
// straight from Cloud SQL. Run directly for a self-test:  node pgdb.js
const { Pool } = require("pg");
const fs = require("fs");
const path = require("path");

// Minimal .env loader (no dotenv dep) — only what we need for the RO connection.
function loadEnv() {
  const f = path.join(__dirname, "..", ".env");
  const out = {};
  try {
    for (const line of fs.readFileSync(f, "utf8").split("\n")) {
      const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);
      if (!m) continue;
      let v = m[2].trim();
      // strip matching surrounding quotes WITHOUT shell expansion
      if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) v = v.slice(1, -1);
      out[m[1]] = v;
    }
  } catch (_) {}
  return out;
}

const env = loadEnv();
// pg ignores a separate `password` when a passwordless connectionString is given,
// so embed it via the URL object (the RO password is hex → URL-safe).
const url = new URL(
  env.DATABASE_URL_RO || process.env.DATABASE_URL_RO ||
    "postgres://explorer_ro@127.0.0.1:5433/space-exploration"
);
url.password = env.PGPASSWORD_RO || process.env.PGPASSWORD_RO || "";
const pool = new Pool({ connectionString: url.toString(), max: 8 });

// Sorts allowed on the seeds list (join-free, index-backed).
const ORDERS = {
  score_desc: "score DESC NULLS LAST, seed",
  npl_desc: "npl DESC, seed",
  naqdv_asc: "naqdv ASC, seed",
  fdv_desc: "fdv DESC, seed",
  seed_asc: "seed ASC",
};

async function getSeeds({ limit = 200, offset = 0, order = "score_desc" } = {}) {
  const ord = ORDERS[order] || ORDERS.score_desc;
  const { rows } = await pool.query(
    `SELECT seed, k2, npl, npm, nw, ne, wp, ef, naqdv, fdv, ed, score
       FROM seeds ORDER BY ${ord} LIMIT $1 OFFSET $2`,
    [limit, offset]
  );
  return rows;
}

async function countSeeds() {
  const { rows } = await pool.query("SELECT count(*)::int n FROM seeds");
  return rows[0].n;
}

// Reconstruct one universe: flat scan + decode codes via the dictionaries.
async function getZones(seed) {
  const { rows } = await pool.query(
    `SELECT zn.name AS name, k.name AS kind, sn.name AS star, pn.name AS parent,
            r.name AS primary, z.radius, z.dv
       FROM zone z
       JOIN zone_name zn ON zn.id = z.zone_name_id
       JOIN enum_value k ON k.domain='kind' AND k.code = z.kind
       LEFT JOIN zone_name sn ON sn.id = z.star_name_id
       LEFT JOIN zone_name pn ON pn.id = z.parent_name_id
       LEFT JOIN resource r ON r.id = z.primary_id
      WHERE z.seed = $1
      ORDER BY z.kind, zn.name`,
    [seed]
  );
  return rows;
}

module.exports = { pool, getSeeds, countSeeds, getZones };

// ── self-test ─────────────────────────────────────────────────────────────
if (require.main === module) {
  (async () => {
    try {
      const n = await countSeeds();
      console.log(`seeds in DB: ${n}`);
      const top = await getSeeds({ limit: 5, order: "npl_desc" });
      console.log("top 5 by planets:", top.map((s) => `#${s.seed}(npl=${s.npl},naqdv=${s.naqdv})`).join(" "));
      if (top[0]) {
        const zones = await getZones(top[0].seed);
        const byKind = zones.reduce((a, z) => ((a[z.kind] = (a[z.kind] || 0) + 1), a), {});
        console.log(`zones for seed ${top[0].seed}:`, byKind);
      }
      // prove read-only
      try {
        await pool.query("INSERT INTO meta(key,value) VALUES('x','y')");
        console.log("WARNING: write succeeded — role is NOT read-only!");
      } catch (e) {
        console.log("write correctly denied:", e.message.split("\n")[0]);
      }
      console.log("OK — frontend can read the bucket from Cloud SQL.");
    } catch (e) {
      console.error("pgdb self-test failed:", e.message);
      process.exitCode = 1;
    } finally {
      await pool.end();
    }
  })();
}
