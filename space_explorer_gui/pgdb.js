// Read-only Postgres access for the web app (new normalized schema).
// Connects as the least-privilege `explorer_ro` role. This is the read layer of
// the better-sqlite3 → pg migration; the job/write system is re-added later.
// Self-test:  node pgdb.js
const { Pool } = require("pg");
const fs = require("fs");
const path = require("path");

// Minimal .env loader (no dotenv dep). Values are taken LITERALLY (quotes
// stripped, no shell expansion) so a `$` in a password isn't corrupted.
function loadEnv() {
  const f = path.join(__dirname, "..", ".env");
  const out = {};
  try {
    for (const line of fs.readFileSync(f, "utf8").split("\n")) {
      const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);
      if (!m) continue;
      let v = m[2].trim();
      if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) v = v.slice(1, -1);
      out[m[1]] = v;
    }
  } catch (_) {}
  return out;
}

const env = loadEnv();
// pg ignores a separate `password` when a passwordless connectionString is set,
// so embed it via the URL object (the RO password is hex → URL-safe).
const url = new URL(
  env.DATABASE_URL_RO || process.env.DATABASE_URL_RO ||
    "postgres://explorer_ro@127.0.0.1:5433/space-exploration"
);
url.password = env.PGPASSWORD_RO || process.env.PGPASSWORD_RO || "";
const pool = new Pool({ connectionString: url.toString(), max: 8 });

// ── seeds list: filters / sort / pagination ────────────────────────────────
// Mirrors the UI's params (k2, *_min/_max ranges, seed search, sort, page).
const ORDERS = {
  npl_desc: "npl DESC NULLS LAST", npl_asc: "npl ASC",
  npm_desc: "npm DESC NULLS LAST", npm_asc: "npm ASC",
  naqdv_asc: "naqdv ASC", naqdv_desc: "naqdv DESC",
  fdv_asc: "fdv ASC", fdv_desc: "fdv DESC",
  wp_desc: "wp DESC", wp_asc: "wp ASC",
  ef_desc: "ef DESC", ef_asc: "ef ASC",
  ed_desc: "ed DESC", ed_asc: "ed ASC",
  score_desc: "score DESC NULLS LAST", score_asc: "score ASC",
  seed: "seed ASC", seed_desc: "seed DESC",
};
const DEFAULT_ORDER = "npl_desc"; // score is not populated yet

// Build the shared WHERE clause + params from a UI filter object.
function buildWhere(filter = {}) {
  const clauses = [];
  const params = [];
  const p = (v) => (params.push(v), `$${params.length}`);
  if (filter.k2 !== undefined && filter.k2 !== null && filter.k2 !== "") {
    clauses.push(`k2 = ${p(!!Number(filter.k2))}`);
  }
  const range = (col, min, max) => {
    if (min != null && min !== "") clauses.push(`${col} >= ${p(Number(min))}`);
    if (max != null && max !== "") clauses.push(`${col} <= ${p(Number(max))}`);
  };
  range("npm", filter.npm_min, filter.npm_max);
  range("npl", filter.npl_min, filter.npl_max);
  range("naqdv", filter.naqdv_min, filter.naqdv_max);
  range("fdv", filter.fdv_min, filter.fdv_max);
  range("wp", filter.wp_min, filter.wp_max);
  range("ef", filter.ef_min, filter.ef_max);
  if (filter.seed != null && String(filter.seed).trim() !== "") {
    const digits = String(filter.seed).replace(/[^\d]/g, "");
    if (digits) clauses.push(`CAST(seed AS TEXT) LIKE ${p("%" + digits + "%")}`);
  }
  return { where: clauses.length ? "WHERE " + clauses.join(" AND ") : "", params };
}

async function getSeeds(filter = {}) {
  const { where, params } = buildWhere(filter);
  const ord = ORDERS[filter.sort] || ORDERS[DEFAULT_ORDER];
  const pageSize = Math.min(Math.max(1, Number(filter.pageSize) || 200), 5000);
  const page = Math.max(0, Number(filter.page) || 0);
  // vault_loot AS loot + a placeholder bucket keep the existing GUI's renderer
  // (which references s.loot / s.bucket) happy without those columns existing.
  const sql =
    `SELECT seed, k2, npl, npm, nw, ne, wp, ef, naqdv, fdv, ed, score,
            vault_loot AS loot, ''::text AS bucket
       FROM seeds ${where}
      ORDER BY ${ord}, seed
      LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
  const { rows } = await pool.query(sql, [...params, pageSize, page * pageSize]);
  return rows;
}

async function countSeeds(filter = {}) {
  const { where, params } = buildWhere(filter);
  const { rows } = await pool.query(`SELECT count(*)::int n FROM seeds ${where}`, params);
  return rows[0].n;
}

async function getSeed(seed) {
  const { rows } = await pool.query(
    `SELECT seed, k2, draws, vault_loot, npl, npm, nw, ne, wp, ef, naqdv, fdv, ed, score
       FROM seeds WHERE seed = $1`, [seed]);
  return rows[0] || null;
}

// Reconstruct one universe: flat scan + decode codes via the dictionaries.
async function getZones(seed) {
  const { rows } = await pool.query(
    `SELECT zn.name AS name, k.name AS kind, sn.name AS star, pn.name AS parent,
            r.name AS primary, z.radius, z.dv,
            tt.name AS temperature, wt.name AS water, mt.name AS moisture,
            trt.name AS trees, at.name AS aux, ct.name AS cliff, et.name AS enemy
       FROM zone z
       JOIN zone_name zn ON zn.id = z.zone_name_id
       JOIN enum_value k ON k.domain='kind' AND k.code = z.kind
       LEFT JOIN zone_name sn ON sn.id = z.star_name_id
       LEFT JOIN zone_name pn ON pn.id = z.parent_name_id
       LEFT JOIN resource  r  ON r.id  = z.primary_id
       LEFT JOIN enum_value tt  ON tt.domain='temperature' AND tt.code=z.temperature
       LEFT JOIN enum_value wt  ON wt.domain='water'       AND wt.code=z.water
       LEFT JOIN enum_value mt  ON mt.domain='moisture'    AND mt.code=z.moisture
       LEFT JOIN enum_value trt ON trt.domain='trees'      AND trt.code=z.trees
       LEFT JOIN enum_value at  ON at.domain='aux'         AND at.code=z.aux
       LEFT JOIN enum_value ct  ON ct.domain='cliff'       AND ct.code=z.cliff
       LEFT JOIN enum_value et  ON et.domain='enemy'       AND et.code=z.enemy
      WHERE z.seed = $1
      ORDER BY z.kind, zn.name`, [seed]);
  return rows;
}

// Zones for a seed, shaped with the OLD column names the existing GUI's
// renderSeedDetail expects (zone_type, primary_resource, delta_v, in_calidus…).
// `id` is synthetic (the new schema keys zones by (seed, name), no integer id).
async function getZonesForSeed(seed) {
  const { rows } = await pool.query(
    `SELECT NULL::int AS id, zn.name AS name,
            k.name AS zone_type, r.name AS primary_resource,
            z.radius, z.dv AS delta_v,
            tt.name AS temperature, wt.name AS water, mt.name AS moisture,
            trt.name AS trees, at.name AS aux, ct.name AS cliff, et.name AS enemy,
            z.stellar_x, z.stellar_y,
            CASE WHEN sn.name = 'Calidus' THEN 1 ELSE 0 END AS in_calidus,
            NULL::text AS resource_yields, NULL::text AS resource_scores
       FROM zone z
       JOIN zone_name zn ON zn.id = z.zone_name_id
       JOIN enum_value k ON k.domain='kind' AND k.code = z.kind
       LEFT JOIN zone_name sn ON sn.id = z.star_name_id
       LEFT JOIN resource  r  ON r.id  = z.primary_id
       LEFT JOIN enum_value tt  ON tt.domain='temperature' AND tt.code=z.temperature
       LEFT JOIN enum_value wt  ON wt.domain='water'       AND wt.code=z.water
       LEFT JOIN enum_value mt  ON mt.domain='moisture'    AND mt.code=z.moisture
       LEFT JOIN enum_value trt ON trt.domain='trees'      AND trt.code=z.trees
       LEFT JOIN enum_value at  ON at.domain='aux'         AND at.code=z.aux
       LEFT JOIN enum_value ct  ON ct.domain='cliff'       AND ct.code=z.cliff
       LEFT JOIN enum_value et  ON et.domain='enemy'       AND et.code=z.enemy
      WHERE z.seed = $1
      ORDER BY z.kind, zn.name`, [seed]);
  return rows;
}

// Resources present on a seed's zones (fact table), decoded — for a seed's detail.
async function getSeedResources(seed) {
  const { rows } = await pool.query(
    `SELECT zn.name AS zone, r.name AS resource, zr.frequency, zr.size, zr.richness
       FROM zone_resource zr
       JOIN zone_name zn ON zn.id = zr.zone_name_id
       JOIN resource r  ON r.id  = zr.resource_id
      WHERE zr.seed = $1 AND zr.present
      ORDER BY zn.name, r.name`, [seed]);
  return rows;
}

module.exports = { pool, getSeeds, countSeeds, getSeed, getZones, getZonesForSeed, getSeedResources, ORDERS, DEFAULT_ORDER };

// ── self-test ─────────────────────────────────────────────────────────────
if (require.main === module) {
  (async () => {
    try {
      console.log(`seeds: ${await countSeeds()}  (k2 only: ${await countSeeds({ k2: 1 })})`);
      const top = await getSeeds({ limit: 5, sort: "npl_desc" });
      console.log("top by planets:", top.slice(0, 5).map((s) => `#${s.seed}(npl=${s.npl})`).join(" "));
      if (top[0]) {
        const z = await getZones(top[0].seed);
        console.log(`seed ${top[0].seed}: ${z.length} zones`);
      }
      console.log("OK");
    } catch (e) {
      console.error("self-test failed:", e.message);
      process.exitCode = 1;
    } finally {
      await pool.end();
    }
  })();
}
