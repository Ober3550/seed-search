// Read-only Postgres access for the web app (new normalized schema).
// Connects as the least-privilege `explorer_ro` role. This is the read layer of
// the better-sqlite3 → pg migration; the job/write system is re-added later.
// Self-test:  node pgdb.js
const { Pool } = require("pg");
const fs = require("fs");
const path = require("path");

// u32 seed is stored as an INT4 = (seed − 2^31) (Postgres has no unsigned int4).
// Decode on read (seed + OFFSET), encode on query (param − OFFSET). The offset
// preserves sort order, so ORDER BY seed still works.
const SEED_OFFSET = 2147483648;

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
// Sort tokens are kept as stable UI identifiers; the SQL uses the renamed columns.
const ORDERS = {
  npl_desc: "planets DESC NULLS LAST", npl_asc: "planets ASC",
  npm_desc: "bodies DESC NULLS LAST", npm_asc: "bodies ASC",
  naqdv_asc: "naquium_dv ASC", naqdv_desc: "naquium_dv DESC",
  fdv_asc: "field_dv ASC", fdv_desc: "field_dv DESC",
  wp_desc: "water_pct DESC", wp_asc: "water_pct ASC",
  ef_desc: "hostility_pct DESC", ef_asc: "hostility_pct ASC",
  ed_desc: "enemy_danger DESC", ed_asc: "enemy_danger ASC",
  score_desc: "score DESC NULLS LAST", score_asc: "score ASC",
  seed: "seed ASC", seed_desc: "seed DESC",
};
const DEFAULT_ORDER = "score_desc"; // score is populated by the generator now

// Build the shared WHERE clause + params from a UI filter object. Filter keys are
// stable UI identifiers (npm_min…) mapped here onto the renamed columns.
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
  range("bodies", filter.npm_min, filter.npm_max);
  range("planets", filter.npl_min, filter.npl_max);
  range("naquium_dv", filter.naqdv_min, filter.naqdv_max);
  range("field_dv", filter.fdv_min, filter.fdv_max);
  range("water_pct", filter.wp_min, filter.wp_max);
  range("hostility_pct", filter.ef_min, filter.ef_max);
  if (filter.seed != null && String(filter.seed).trim() !== "") {
    const digits = String(filter.seed).replace(/[^\d]/g, "");
    // seed is stored offset → decode before the text match
    if (digits) clauses.push(`CAST(seed + ${SEED_OFFSET} AS TEXT) LIKE ${p("%" + digits + "%")}`);
  }
  return { where: clauses.length ? "WHERE " + clauses.join(" AND ") : "", params };
}

// Seed-list columns, seed decoded back to u32. New readable names flow straight
// through to the GUI + score.js.
const SEED_COLS =
  `seed + ${SEED_OFFSET} AS seed, k2, planets, bodies, water_bodies, enemy_bodies,
   water_pct, hostility_pct, naquium_dv, field_dv, enemy_danger, score`;

async function getSeeds(filter = {}) {
  const { where, params } = buildWhere(filter);
  const ord = ORDERS[filter.sort] || ORDERS[DEFAULT_ORDER];
  const pageSize = Math.min(Math.max(1, Number(filter.pageSize) || 200), 5000);
  const page = Math.max(0, Number(filter.page) || 0);
  // vault_loot AS loot + a placeholder bucket keep the existing GUI's renderer
  // (which references s.loot / s.bucket) happy without those columns existing.
  const sql =
    `SELECT ${SEED_COLS}, vault_loot AS loot, ''::text AS bucket
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
    `SELECT ${SEED_COLS}, vault_loot, vault_loot AS loot, ''::text AS bucket
       FROM seeds WHERE seed = $1`, [Number(seed) - SEED_OFFSET]);
  return rows[0] || null;
}

// Reconstruct one universe: flat scan + decode codes via the dictionaries.
async function getZones(seed) {
  const { rows } = await pool.query(
    `SELECT zn.name AS name, k.name AS kind, sn.name AS star, pn.name AS parent,
            r.name AS primary, z.radius, z.delta_v AS dv,
            tt.name AS temperature, wt.name AS water, mt.name AS moisture,
            trt.name AS trees, at.name AS aux, ct.name AS cliff, et.name AS enemy
       FROM zone z
       JOIN zone_name zn ON zn.id = z.zone_name_id
       JOIN enum_value k ON k.domain='kind' AND k.code = z.kind
       LEFT JOIN zone_name sn ON sn.id = z.star_name_id
       LEFT JOIN zone_name pn ON pn.id = z.parent_name_id
       LEFT JOIN resource  r  ON r.id  = z.primary_id
       LEFT JOIN enum_value tt  ON tt.domain='temperature' AND tt.code=z.temperature_idx
       LEFT JOIN enum_value wt  ON wt.domain='water'       AND wt.code=z.water_idx
       LEFT JOIN enum_value mt  ON mt.domain='moisture'    AND mt.code=z.moisture_idx
       LEFT JOIN enum_value trt ON trt.domain='trees'      AND trt.code=z.trees_idx
       LEFT JOIN enum_value at  ON at.domain='aux'         AND at.code=z.aux_idx
       LEFT JOIN enum_value ct  ON ct.domain='cliff'       AND ct.code=z.cliff_idx
       LEFT JOIN enum_value et  ON et.domain='enemy'       AND et.code=z.enemy_idx
      WHERE z.seed = $1
      ORDER BY z.kind, zn.name`, [Number(seed) - SEED_OFFSET]);
  return rows;
}

// Zones for a seed, shaped with the OLD column names the existing GUI's
// renderSeedDetail expects (zone_type, primary_resource, delta_v, in_calidus…).
// `id` is synthetic (the new schema keys zones by (seed, name), no integer id).
async function getZonesForSeed(seed) {
  const { rows } = await pool.query(
    `SELECT NULL::int AS id, zn.name AS name,
            k.name AS zone_type, r.name AS primary_resource,
            z.radius, z.delta_v AS delta_v,
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
       LEFT JOIN enum_value tt  ON tt.domain='temperature' AND tt.code=z.temperature_idx
       LEFT JOIN enum_value wt  ON wt.domain='water'       AND wt.code=z.water_idx
       LEFT JOIN enum_value mt  ON mt.domain='moisture'    AND mt.code=z.moisture_idx
       LEFT JOIN enum_value trt ON trt.domain='trees'      AND trt.code=z.trees_idx
       LEFT JOIN enum_value at  ON at.domain='aux'         AND at.code=z.aux_idx
       LEFT JOIN enum_value ct  ON ct.domain='cliff'       AND ct.code=z.cliff_idx
       LEFT JOIN enum_value et  ON et.domain='enemy'       AND et.code=z.enemy_idx
      WHERE z.seed = $1
      ORDER BY z.kind, zn.name`, [Number(seed) - SEED_OFFSET]);
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
      ORDER BY zn.name, r.name`, [Number(seed) - SEED_OFFSET]);
  return rows;
}

module.exports = { pool, getSeeds, countSeeds, getSeed, getZones, getZonesForSeed, getSeedResources, ORDERS, DEFAULT_ORDER };

// ── self-test ─────────────────────────────────────────────────────────────
if (require.main === module) {
  (async () => {
    try {
      console.log(`seeds: ${await countSeeds()}  (k2 only: ${await countSeeds({ k2: 1 })})`);
      const top = await getSeeds({ limit: 5, sort: "score_desc" });
      console.log("top by score:", top.slice(0, 5).map((s) => `#${s.seed}(score=${s.score},planets=${s.planets})`).join(" "));
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
