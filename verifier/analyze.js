#!/usr/bin/env node
// SE seed analyzer — reads new-format JSONL, converts to old format,
// applies the original evalSeed / specialHolm filter logic.
//
// Usage:
//   node analyze.js < seeds.jsonl
//   node analyze.js seeds_0.jsonl seeds_1.jsonl
//   ./seedgen ... 2>&1 | grep '^{' | node analyze.js

const fs = require("fs");
const readline = require("readline");

// ── new → old format converter ──────────────────────────────────────

// Parse yield string ("150M", "2.3B") to numeric millions
function parseYield(y) {
  if (typeof y === "number") return y;
  if (y === "0" || !y) return 0;
  if (y.endsWith("B")) return parseFloat(y) * 1000;
  if (y.endsWith("M")) return parseFloat(y);
  return parseFloat(y) || 0;
}

function convertNewToOld(seed, calidusOnly) {
  const zones = seed.z || [];
  const out = {
    seed: seed.s,
    loot: (seed.l || "").split(""),
    planets: [],
    moons: [],
    fields: [],
  };

  // If calidusOnly, find the Calidus star and only use zones until next star
  let startIdx = 0,
    endIdx = zones.length;
  if (calidusOnly) {
    for (let i = 0; i < zones.length; i++) {
      if (zones[i].n === "Calidus" && zones[i].t === "star") startIdx = i;
      else if (
        startIdx > 0 &&
        zones[i].t === "star" &&
        zones[i].n !== "Calidus"
      ) {
        endIdx = i;
        break;
      }
    }
  }

  for (let i = startIdx; i < endIdx; i++) {
    const z = zones[i];
    const t = z.t;
    const entry = {
      name: z.n,
      zone_type: [t],
      delta_v: z.dv || 0,
      radius: z.r || 0,
      resource: z.y
        ? Object.fromEntries(
            Object.entries(z.y).map(function (kv) {
              return [kv[0], parseYield(kv[1])];
            }),
          )
        : z.rs || {},
      primary: z.p || null,
      tags: {},
    };
    if (z.temperature) entry.tags.temperature = "temperature_" + z.temperature;
    if (z.water) entry.tags.water = "water_" + z.water;
    if (z.moisture) entry.tags.moisture = "moisture_" + z.moisture;
    if (z.trees) entry.tags.trees = "trees_" + z.trees;
    if (z.aux) entry.tags.aux = "aux_" + z.aux;
    if (z.cliff) entry.tags.cliff = "cliff_" + z.cliff;
    if (z.enemy) entry.tags.enemy = "enemy_" + z.enemy;

    if (t === "planet") out.planets.push(entry);
    else if (t === "moon") out.moons.push(entry);
    else if (t === "asteroid-field") {
      entry.cannonable = (z.dv || 0) <= 20000;
      out.fields.push(entry);
    }
  }
  return out;
}

// ── original display / filter logic ─────────────────────────────────

const COLOR = {
  RESET: "\u001b[0m",
  WHITE: "\u001b[37m",
  GREY: "\u001b[90m",
  RED: "\u001b[31m",
  GREEN: "\u001b[32m",
  BLUE: "\u001b[34m",
  YELLOW: "\u001b[33m",
  CYAN: "\u001b[36m",
  MAGENTA: "\u001b[35m",
};

const nameMap = {
  "iron-ore": "iron",
  "copper-ore": "copper",
  "crude-oil": "oil",
  "uranium-ore": "uranium",
  stone: `${COLOR.GREY}stone${COLOR.RESET}`,
  coal: "coal",
  "se-cryonite": `${COLOR.BLUE}cryonite${COLOR.RESET}`,
  "se-vulcanite": `${COLOR.RED}vulcanite${COLOR.RESET}`,
  "se-vitamelange": `${COLOR.GREEN}vitamelange${COLOR.RESET}`,
  "se-iridium-ore": `${COLOR.YELLOW}iridium${COLOR.RESET}`,
  "se-holmium-ore": `${COLOR.MAGENTA}holmium${COLOR.RESET}`,
  "se-beryllium-ore": `${COLOR.CYAN}beryl${COLOR.RESET}`,
  "kr-imersite": `${COLOR.MAGENTA}imersite${COLOR.RESET}`,
  "kr-mineral-water": `${COLOR.BLUE}mineral-water${COLOR.RESET}`,
};
function rename(n) {
  return nameMap[n] || n;
}
function noColor(s) {
  return s.replace(/\x1b\[[0-9;]*m/g, "");
}
function noColorLen(s) {
  return noColor(s).length;
}

function resourcesArray(res) {
  const keys = Object.keys(res).sort((a, b) => res[b] - res[a]);
  const r = [];
  for (let i = 0; i < Math.min(6, keys.length); i++) {
    r.push(keys[i]);
    r.push(Math.floor(res[keys[i]] * 10000) / 10000);
  }
  return r;
}

function surfaceInfo(s) {
  const r = resourcesArray(s.resource || {});
  const enemy = (s.tags.enemy || "enemy_none")
    .replace("enemy_", "e ")
    .replace("very_", "v");
  const water = (s.tags.water || "water_none").replace("water_", "w ");
  return [
    s.name,
    s.zone_type[0],
    "dv",
    s.delta_v,
    "r",
    s.radius || 0,
    enemy,
    water,
    ...r.map((x) => rename(x)),
  ];
}

function printTable(table) {
  const widths = [];
  for (const row of table)
    for (let j = 0; j < row.length; j++)
      widths[j] = Math.max(widths[j] || 0, noColorLen(String(row[j])));
  for (const row of table) {
    console.log(
      row
        .map((c, j) =>
          String(c).padEnd(
            widths[j] + String(c).length - noColorLen(String(c)),
          ),
        )
        .join(" "),
    );
  }
}

function printPlanetsAndMoons(items) {
  printTable(items.map(surfaceInfo));
}

const resourceNames = {
  "se-vulcanite": true,
  "se-cryonite": true,
  "se-holmium-ore": true,
  "se-beryllium-ore": true,
  "se-iridium-ore": true,
  "se-vitamelange": true,
  "kr-imersite": true,
};

// ── generated-surface metadata (segen zone driver output) ───────────
// If output/<seed>/report.json exists (produced by
// `segen --zones ... --world-seed <seed>`), present its MEASURED ore amounts
// instead of the default proportion estimates.

function loadGeneratedWorld(seed) {
  try {
    const p = `${genDir}/${seed}/report.json`;
    const rep = JSON.parse(fs.readFileSync(p, "utf8"));
    const map = {};
    for (const z of rep.zones || []) map[z.zone] = z.resources || {};
    return map;
  } catch (e) {
    return null;
  }
}

function genAmount(gen, zoneName, res) {
  const zr = gen && gen[zoneName];
  const entry = zr && zr[res];
  if (!entry) return null;
  return entry.display || String(entry.amount);
}

// ── evaluation modes ────────────────────────────────────────────────

const SPECIAL = [
  "se-vulcanite",
  "se-cryonite",
  "se-holmium-ore",
  "se-beryllium-ore",
  "se-iridium-ore",
  "se-vitamelange",
];

function viableBodies(seedOld) {
  const planets = seedOld.planets.sort((a, b) => a.delta_v - b.delta_v);
  const moons = seedOld.moons.sort((a, b) => a.delta_v - b.delta_v);
  const bodies = [...planets, ...moons].sort((a, b) => a.delta_v - b.delta_v);
  return bodies.filter((s) => {
    const r = resourcesArray(s.resource);
    const enemy = s.tags.enemy || "enemy_none";
    return (
      s.tags.water !== "water_none" &&
      r.length > 0 &&
      resourceNames[noColor(r[0])] &&
      s.radius > 2000 &&
      enemy !== "enemy_very_high" &&
      enemy !== "enemy_max"
    );
  });
}

function primaryResource(s) {
  const r = resourcesArray(s.resource);
  return r.length > 0 ? noColor(r[0]) : null;
}

function formatVal(v) {
  if (v >= 1000) return (v / 1000).toFixed(1) + "B";
  if (v >= 1) return Math.round(v) + "M";
  if (v > 0) return v.toFixed(4);
  return "0";
}

function isPrimaryResource(body, res) {
  // Check the primary field first (new format)
  if (body.primary) return body.primary === res;
  // Fallback: check normalized scores (old format)
  const rs = body.resource || {};
  return (rs[res] || 0) >= 0.9999;
}

function bestNaqField(seedOld) {
  const fields = (seedOld.fields || []).filter(
    (f) =>
      f.primary === "se-naquium-ore" &&
      (f.delta_v || 0) > 0 &&
      (f.delta_v || 0) <= 20000,
  );
  fields.sort((a, b) => a.delta_v - b.delta_v);
  return fields[0] || null;
}

function evalCore(seedOld, selected) {
  // Seed has >= minSpecials special resources as primary on some viable body
  const bodies = viableBodies(seedOld);
  const covered = new Set();
  for (const b of bodies) {
    for (const r of SPECIAL) {
      if (isPrimaryResource(b, r)) covered.add(r);
    }
  }
  if (covered.size >= minSpecials) {
    const gen = loadGeneratedWorld(seedOld.seed);
    console.log(
      `\n=== CORE: seed ${seedOld.seed} loot: ${seedOld.loot.join("")}${gen ? " [generated]" : ""} ===`,
    );
    console.log(
      `  ${covered.size}/${SPECIAL.length} specials as primary across ${bodies.length} viable bodies`,
    );
    for (const res of SPECIAL) {
      const b = bodies.find((x) => isPrimaryResource(x, res));
      if (b) {
        if (selected) selected.add(b.name);
        const e = (b.tags.enemy || "enemy_none")
          .replace("enemy_", "")
          .replace("very_", "v");
        const w =
          (b.tags.water || "water_none").replace("water_", "") === "none"
            ? "dry"
            : (b.tags.water || "").replace("water_", "");
        const g = genAmount(gen, b.name, res);
        console.log(
          `    ${rename(res)}: ${b.name} (${b.zone_type[0]}) dv=${b.delta_v} r=${b.radius} e=${e} w=${w}${g ? ` ${g} ore` : ""}`,
        );
      }
    }
    // Bonus: best imersite body
    for (const extra of ["kr-imersite"]) {
      const best = bodies.reduce(
        (a, b) =>
          ((a?.resource || {})[extra] || 0) > ((b?.resource || {})[extra] || 0)
            ? a
            : b,
        null,
      );
      if (best && (best.resource || {})[extra] > 0) {
        if (selected) selected.add(best.name);
        const e = (best.tags.enemy || "enemy_none")
          .replace("enemy_", "")
          .replace("very_", "v");
        const w =
          (best.tags.water || "water_none").replace("water_", "") === "none"
            ? "dry"
            : (best.tags.water || "").replace("water_", "");
        const score = formatVal((best.resource || {})[extra]);
        console.log(
          `    ${rename(extra)}: ${best.name} (${best.zone_type[0]}) dv=${best.delta_v} r=${best.radius} e=${e} w=${w} (${score})`,
        );
      }
    }
    // Naquium field
    const nf = bestNaqField(seedOld);
    if (nf) {
      const naq = formatVal(nf.resource["se-naquium-ore"] || 0);
      console.log(`    naq: ${nf.name} dv=${nf.delta_v} (${naq})`);
    }
    console.log();
    return true;
  }
  return false;
}

function evalPairs(seedOld, selected) {
  // Production-chain-aware resource pairings.
  // Each combo can be on the same body (ideal) or different bodies (good).
  const combos = [
    { name: "vulc+irid", want: ["se-iridium-ore", "se-vulcanite"] },
    { name: "beryl+cryo", want: ["se-beryllium-ore", "se-cryonite"] },
    { name: "holm+h2o", want: ["se-holmium-ore", "kr-mineral-water"] },
    {
      name: "vita+h2o+stone",
      want: ["se-vitamelange", "kr-mineral-water", "stone"],
    },
    { name: "K2:imer+h2o", want: ["kr-imersite", "kr-mineral-water"] },
  ];

  const bodies = viableBodies(seedOld);
  const results = [];
  for (const c of combos) {
    // First try: find body where the first resource is primary
    let match = bodies.find((b) => {
      const rs = b.resource || {};
      return (
        isPrimaryResource(b, c.want[0]) &&
        c.want.every((r) => (rs[r] || 0) > 0)
      );
    });
    // Fallback: any body with all resources present
    if (!match) {
      match = bodies.find((b) => {
        const rs = b.resource || {};
        return c.want.every((r) => (rs[r] || 0) > 0);
      });
    }
    if (match) results.push({ ...c, body: match });
  }

  // Only show seeds with enough combos found (--min-pairs, default: all)
  if (results.length >= Math.min(minPairs, combos.length)) {
    // Sort by delta-v (closest first)
    results.sort((a, b) => a.body.delta_v - b.body.delta_v);
    const gen = loadGeneratedWorld(seedOld.seed);
    console.log(
      `=== PAIRS: seed ${seedOld.seed} loot: ${seedOld.loot.join("")}${gen ? " [generated]" : ""} ===`,
    );
    for (const r of results) {
      const b = r.body;
      if (selected) selected.add(b.name);
      // Sort resources by score (highest first)
      const parts = [...r.want]
        .sort((a, b2) => (b.resource[b2] || 0) - (b.resource[a] || 0))
        .map((w) => {
          const g = genAmount(gen, b.name, w);
          return `${rename(w)}:${g ?? formatVal((b.resource || {})[w] || 0)}`;
        });
      const enemy = (b.tags.enemy || "enemy_none")
        .replace("enemy_", "")
        .replace("very_", "v");
      const water =
        (b.tags.water || "water_none").replace("water_", "") === "none"
          ? "dry"
          : (b.tags.water || "").replace("water_", "");
      console.log(
        `  ${r.name}: ${b.name} (${b.zone_type[0]}) dv=${b.delta_v} r=${b.radius} e=${enemy} w=${water}  ${parts.join(" ")}`,
      );
    }
    // Naquium field
    const nf = bestNaqField(seedOld);
    if (nf) {
      const naq = formatVal(nf.resource["se-naquium-ore"] || 0);
      console.log(`  naq: ${nf.name} dv=${nf.delta_v} (${naq})`);
    }
    console.log();
    return true;
  }
  return false;
}

// ── programmatic API (used by space_explorer_gui) ────────────────────

// Evaluate a raw new-format world line. Returns criteria info + the zone names
// each criterion selected (for zone-level filtering downstream).
function evaluateWorld(seedRaw) {
  const old = convertNewToOld(seedRaw, true);
  const bodies = viableBodies(old);
  const specials = {};
  for (const b of bodies) {
    for (const r of SPECIAL) {
      if (isPrimaryResource(b, r) && !specials[r]) specials[r] = b.name;
    }
  }
  // pair combos (same set as evalPairs)
  const combos = [
    { name: "vulc+irid", want: ["se-iridium-ore", "se-vulcanite"] },
    { name: "beryl+cryo", want: ["se-beryllium-ore", "se-cryonite"] },
    { name: "holm+h2o", want: ["se-holmium-ore", "kr-mineral-water"] },
    { name: "vita+h2o+stone", want: ["se-vitamelange", "kr-mineral-water", "stone"] },
    { name: "K2:imer+h2o", want: ["kr-imersite", "kr-mineral-water"] },
  ];
  const pairs = {};
  for (const c of combos) {
    let match = bodies.find(
      (b) => isPrimaryResource(b, c.want[0]) && c.want.every((r) => ((b.resource || {})[r] || 0) > 0),
    );
    if (!match) match = bodies.find((b) => c.want.every((r) => ((b.resource || {})[r] || 0) > 0));
    if (match) pairs[c.name] = match.name;
  }
  const selected = new Set([...Object.values(specials), ...Object.values(pairs)]);
  const nf = bestNaqField(old);
  // Per-viable-body detail so tag/rule filters can query primary + present
  // (secondary) resources. present = resources with a nonzero score.
  const bodyInfo = bodies.map((b) => ({
    name: b.name,
    type: (b.zone_type && b.zone_type[0]) || "?",
    radius: Math.round(b.radius || 0),
    dv: Math.round(b.delta_v || 0),
    primary: primaryResource(b),
    enemy: enemyOrd(b.tags && b.tags.enemy),  // 0..6 danger ordinal (0 = none)
    water: waterOrd(b.tags && b.tags.water),  // 0..4 amount ordinal (0 = none)
    present: Object.entries(b.resource || {})
      .filter(([, v]) => v > 0)
      .map(([k]) => noColor(k)),
  }));
  return {
    seed: seedRaw.s,
    loot: (seedRaw.l || ""),
    k2: !!seedRaw.k,
    zoneCount: (seedRaw.z || []).length,
    viableBodies: bodies.map((b) => b.name),
    bodies: bodyInfo,   // [{name,type,radius,dv,primary,present:[...]}]
    specials,          // resource -> zone name
    numSpecials: Object.keys(specials).length,
    pairs,             // combo -> zone name
    numPairs: Object.keys(pairs).length,
    naqField: nf ? nf.name : null,
    selectedZones: [...selected],
  };
}

// ── Rule-based filters ───────────────────────────────────────────────────
// A filter is a list of rules, ALL of which must hold (AND). Each rule:
//   { kind: "primary",   res }            — a body has `res` as primary
//   { kind: "present",   res }            — a body has `res` present (secondary ok)
//   { kind: "combo",     res, res2 }      — one body: `res` primary AND `res2` present
//   { kind: "both",      res, res2 }      — one body has BOTH present (production pair)
//   { kind: "specials",  n }              — >= n distinct special primaries
//   { kind: "pairs",     n }              — >= n production pairs matched
// matchFilter returns { match, zones:[names] } — zones are the bodies that
// satisfied the resource rules (for downstream zone selection); specials/pairs
// rules contribute their preset selectedZones.
// Canonical rule shape: { primary: bool, res: [r1, r2, ...] } — a body has all
// of `res` present, and (if primary) its PRIMARY is res[0]. Legacy kind-based
// rules (primary/present/combo/both) map onto it; count rules (specials/pairs)
// have no resource form and return null (handled separately in matchFilter).
// Enemy danger ordinal: none=0 … max=6 (matches data.zig Enemy enum). Accepts
// the "enemy_high" tag or a bare "high"; unknown/empty → 0 (none).
const ENEMY_LEVELS = ["none", "very_low", "low", "med", "high", "very_high", "max"];
function enemyOrd(tag) {
  if (tag == null || tag === "") return 0;
  const s = String(tag).replace("enemy_", "");
  const i = ENEMY_LEVELS.indexOf(s);
  return i < 0 ? 0 : i;
}
// Parse a rule's optional enemy-max into an ordinal (0..6) or null (no limit).
function enemyMaxOrd(rule) {
  const v = rule.enemyMax;
  if (v == null || v === "") return null;
  if (typeof v === "number") return v;
  const s = String(v);
  return /^\d+$/.test(s) ? Number(s) : (ENEMY_LEVELS.includes(s.replace("enemy_", "")) ? enemyOrd(s) : null);
}

// Water amount ordinal: none=0 … max=4 (matches data.zig Water enum).
const WATER_LEVELS = ["none", "low", "med", "high", "max"];
function waterOrd(tag) {
  if (tag == null || tag === "") return 0;
  const i = WATER_LEVELS.indexOf(String(tag).replace("water_", ""));
  return i < 0 ? 0 : i;
}
// Parse a rule's optional water-min into an ordinal (0..4) or null (no floor).
function waterMinOrd(rule) {
  const v = rule.waterMin;
  if (v == null || v === "") return null;
  if (typeof v === "number") return v;
  const s = String(v);
  return /^\d+$/.test(s) ? Number(s) : (WATER_LEVELS.includes(s.replace("water_", "")) ? waterOrd(s) : null);
}

function normalizeRule(rule) {
  if (!rule || typeof rule !== "object") return null;
  const em = enemyMaxOrd(rule);
  const wm = waterMinOrd(rule);
  switch (rule.kind) {
    case "primary": return { primary: true, res: [rule.res].filter(Boolean), enemyMax: em, waterMin: wm };
    case "present": return { primary: false, res: [rule.res].filter(Boolean), enemyMax: em, waterMin: wm };
    case "combo": return { primary: true, res: [rule.res, rule.res2].filter(Boolean), enemyMax: em, waterMin: wm };
    case "both": return { primary: false, res: [rule.res, rule.res2].filter(Boolean), enemyMax: em, waterMin: wm };
    case "specials":
    case "pairs": return null;
    default: {
      const res = Array.isArray(rule.res) ? rule.res.filter(Boolean) : (rule.res ? [rule.res] : []);
      return { primary: !!rule.primary, res, enemyMax: em, waterMin: wm };
    }
  }
}

function matchFilter(crit, rules) {
  if (!rules || rules.length === 0) return { match: true, zones: crit.selectedZones || [] };
  const bodies = crit.bodies || [];
  const used = new Set();          // each resource rule claims a DISTINCT body,
  const zones = new Set();          // so N copies of a rule require N bodies
  const pick = (pred) => bodies.find((x) => !used.has(x.name) && pred(x));
  for (const rule of rules) {
    if (rule.kind === "specials") { // legacy count rule
      if ((crit.numSpecials || 0) < (rule.n || 0)) return { match: false, zones: [] };
      for (const z of Object.values(crit.specials || {})) zones.add(z);
      continue;
    }
    if (rule.kind === "pairs") {
      if ((crit.numPairs || 0) < (rule.n || 0)) return { match: false, zones: [] };
      for (const z of Object.values(crit.pairs || {})) zones.add(z);
      continue;
    }
    const nr = normalizeRule(rule);
    if (!nr || nr.res.length === 0) continue;
    // naquium lives on asteroid fields, not planet/moon bodies — match the
    // nearest naq-primary field (crit.naqField, already sorted by deltav).
    if (isNaqPrimary(nr)) {
      if (!crit.naqField) return { match: false, zones: [] };
      zones.add(crit.naqField);
      continue;
    }
    const b = pick((x) =>
      nr.res.every((r) => (x.present || []).includes(r)) &&
      (!nr.primary || x.primary === nr.res[0]) &&
      (nr.enemyMax == null || (x.enemy || 0) <= nr.enemyMax) &&
      (nr.waterMin == null || (x.water || 0) >= nr.waterMin));
    if (!b) return { match: false, zones: [] };
    used.add(b.name);
    zones.add(b.name);
  }
  return { match: true, zones: [...zones] };
}

// The nearest naq-primary asteroid field is tracked separately (crit.naqField),
// not in crit.bodies (planets/moons), so a naquium-primary rule matches it.
function isNaqPrimary(nr) {
  return nr.primary && nr.res.length === 1 && nr.res[0] === "se-naquium-ore";
}

// Like matchFilter, but instead of an all-or-nothing verdict, returns how many
// of the rules are satisfied (0..rules.length). Uses the same greedy
// distinct-body allocation as matchFilter, minus the short-circuit — so a
// partially-matching seed can be counted and ranked instead of dropped.
function countMatches(crit, rules) {
  if (!rules || rules.length === 0) return 0;
  const bodies = crit.bodies || [];
  const used = new Set();
  let n = 0;
  for (const rule of rules) {
    if (rule.kind === "specials") {
      if ((crit.numSpecials || 0) >= (rule.n || 0)) n++;
      continue;
    }
    if (rule.kind === "pairs") {
      if ((crit.numPairs || 0) >= (rule.n || 0)) n++;
      continue;
    }
    const nr = normalizeRule(rule);
    if (!nr || nr.res.length === 0) continue;
    if (isNaqPrimary(nr)) {
      if (crit.naqField) n++;
      continue;
    }
    const b = bodies.find((x) =>
      !used.has(x.name) &&
      nr.res.every((r) => (x.present || []).includes(r)) &&
      (!nr.primary || x.primary === nr.res[0]) &&
      (nr.enemyMax == null || (x.enemy || 0) <= nr.enemyMax) &&
      (nr.waterMin == null || (x.water || 0) >= nr.waterMin));
    if (b) { used.add(b.name); n++; }
  }
  return n;
}

// A short human label for a rule (UI + preset descriptions).
function ruleLabel(rule) {
  const nm = (r) => (r || "").replace("se-", "").replace("kr-", "").replace("-ore", "");
  if (rule.kind === "specials") return `≥${rule.n} specials`;
  if (rule.kind === "pairs") return `≥${rule.n} pairs`;
  const nr = normalizeRule(rule);
  if (!nr || nr.res.length === 0) return "—";
  const names = nr.res.map(nm);
  const em = nr.enemyMax == null ? "" : ` · enemy ≤ ${ENEMY_LEVELS[nr.enemyMax] || nr.enemyMax}`;
  const wm = nr.waterMin == null ? "" : ` · water ≥ ${WATER_LEVELS[nr.waterMin] || nr.waterMin}`;
  if (nr.primary) {
    return (names.length === 1 ? `${names[0]} primary` : `${names[0]} primary + ${names.slice(1).join(" + ")}`) + em + wm;
  }
  return (names.length === 1 ? `has ${names[0]}` : `${names.join(" + ")} together`) + em + wm;
}

module.exports = { convertNewToOld, viableBodies, isPrimaryResource, SPECIAL, bestNaqField, evaluateWorld, matchFilter, countMatches, ruleLabel, normalizeRule, ENEMY_LEVELS, WATER_LEVELS };

if (require.main !== module) {
  // imported as a library — skip the CLI main below
  return;
}

// ── main ─────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const mode = args.includes("--core")
  ? "core"
  : args.includes("--pairs")
    ? "pairs"
    : "show";
const allMode = args.includes("--all");
const msIdx = args.indexOf("--min-specials");
const minSpecials = msIdx >= 0 ? parseInt(args[msIdx + 1]) : SPECIAL.length;
const mpIdx = args.indexOf("--min-pairs");
const minPairs = mpIdx >= 0 ? parseInt(args[mpIdx + 1]) : 99;
const gdIdx = args.indexOf("--gen-dir");
const genDir = gdIdx >= 0 ? args[gdIdx + 1] : "output";
const emitIdx = args.indexOf("--emit");
const emitPath = emitIdx >= 0 ? args[emitIdx + 1] : null;
const emitLines = [];
const files = args.filter(
  (a, i) =>
    !a.startsWith("--") &&
    (emitIdx < 0 || i !== emitIdx + 1) &&
    (msIdx < 0 || i !== msIdx + 1) &&
    (mpIdx < 0 || i !== mpIdx + 1) &&
    (gdIdx < 0 || i !== gdIdx + 1),
);

let fnames = [];
for (const arg of files) {
  if (fs.statSync(arg).isDirectory()) {
    const dirFiles = fs
      .readdirSync(arg)
      .filter((f) => f.startsWith("seeds_") && f.endsWith(".jsonl"));
    fnames.push(...dirFiles.map((f) => arg + "/" + f));
  } else {
    fnames.push(arg);
  }
}
fnames.sort((a, b) => {
  const na = parseInt(a.match(/seeds_(\d+)/)?.[1] || "0");
  const nb = parseInt(b.match(/seeds_(\d+)/)?.[1] || "0");
  return na - nb;
});

let matched = 0;
for (const fname of fnames) {
  const content = fs.readFileSync(fname, "utf8");
  for (const line of content.split("\n")) {
    if (!line.startsWith("{")) continue;
    try {
      const seed = JSON.parse(line);
      const old = convertNewToOld(seed, true); // always Calidus only
      const loot = old.loot.join("");
      if (!allMode && !loot.match(/^PPSS/)) continue;
      const selected = new Set();
      let ok = false;
      if (mode === "core") ok = evalCore(old, selected);
      else if (mode === "pairs") ok = evalPairs(old, selected);
      if (ok) {
        matched++;
        if (emitPath && selected.size > 0) {
          // Emit the world in the ORIGINAL universe-generator format, with z
          // filtered to only the zones the criteria selected — downstream
          // (segen --zones ... --zone all) then generates exactly these.
          const filtered = { ...seed, z: (seed.z || []).filter((z) => selected.has(z.n)) };
          emitLines.push(JSON.stringify(filtered));
        }
      }
    } catch (e) {}
  }
}
console.log(`${matched} seeds matched (${fnames.length} files scanned)`);
if (emitPath) {
  fs.writeFileSync(emitPath, emitLines.join("\n") + (emitLines.length ? "\n" : ""));
  console.log(`emitted ${emitLines.length} filtered worlds -> ${emitPath}`);
}
