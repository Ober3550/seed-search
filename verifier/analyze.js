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
    let startIdx = 0, endIdx = zones.length;
    if (calidusOnly) {
        for (let i = 0; i < zones.length; i++) {
            if (zones[i].n === "Calidus" && zones[i].t === "star") startIdx = i;
            else if (startIdx > 0 && zones[i].t === "star" && zones[i].n !== "Calidus") {
                endIdx = i; break;
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
            resource: z.rs || {},
            tags: {},
        };
        if (z.g) entry.tags.temperature = z.g;
        if (z.w) entry.tags.water = z.w;
        if (z.m) entry.tags.moisture = z.m;
        if (z.tr) entry.tags.trees = z.tr;
        if (z.a) entry.tags.aux = z.a;
        if (z.c) entry.tags.cliff = z.c;
        if (z.e) entry.tags.enemy = z.e;

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
    RED: "\u001b[31m",
    GREEN: "\u001b[32m",
    BLUE: "\u001b[34m",
    YELLOW: "\u001b[33m",
    CYAN: "\u001b[36m",
    MAGENTA: "\u001b[35m",
};

const nameMap = {
    "iron-ore": "iron", "copper-ore": "copper", "crude-oil": "oil",
    "uranium-ore": "uranium", "stone": "stone", "coal": "coal",
    "se-cryonite": `${COLOR.BLUE}cryonite${COLOR.RESET}`,
    "se-vulcanite": `${COLOR.RED}vulcanite${COLOR.RESET}`,
    "se-vitamelange": `${COLOR.GREEN}vitamelange${COLOR.RESET}`,
    "se-iridium-ore": `${COLOR.YELLOW}iridium${COLOR.RESET}`,
    "se-holmium-ore": `${COLOR.MAGENTA}holmium${COLOR.RESET}`,
    "se-beryllium-ore": `${COLOR.CYAN}beryl${COLOR.RESET}`,
};
function rename(n) { return nameMap[n] || n; }
function noColor(s) { return s.replace(/\x1b\[[0-9;]*m/g, ""); }
function noColorLen(s) { return noColor(s).length; }

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
    const enemy = (s.tags.enemy || "enemy_none").replace("enemy_", "e ").replace("very_", "v");
    const water = (s.tags.water || "water_none").replace("water_", "w ");
    return [
        s.name, s.zone_type[0], "dv", s.delta_v, "r", s.radius || 0,
        enemy, water,
        ...r.map(x => rename(x)),
    ];
}

function printTable(table) {
    const widths = [];
    for (const row of table)
        for (let j = 0; j < row.length; j++)
            widths[j] = Math.max(widths[j] || 0, noColorLen(String(row[j])));
    for (const row of table) {
        console.log(row.map((c, j) =>
            String(c).padEnd(widths[j] + String(c).length - noColorLen(String(c)))
        ).join(" "));
    }
}

function printPlanetsAndMoons(items) {
    printTable(items.map(surfaceInfo));
}

const resourceNames = {
    "se-vulcanite": true, "se-cryonite": true, "se-holmium-ore": true,
    "se-beryllium-ore": true, "se-iridium-ore": true, "se-vitamelange": true,
};

// ── evaluation modes ────────────────────────────────────────────────

const SPECIAL = ["se-vulcanite", "se-cryonite", "se-holmium-ore", "se-beryllium-ore", "se-iridium-ore", "se-vitamelange", "kr-rare-metal-ore"];

function viableBodies(seedOld) {
    const planets = seedOld.planets.sort((a, b) => a.delta_v - b.delta_v);
    const moons = seedOld.moons.sort((a, b) => a.delta_v - b.delta_v);
    const bodies = [...planets, ...moons].sort((a, b) => a.delta_v - b.delta_v);
    return bodies.filter(s => {
        const r = resourcesArray(s.resource);
        return s.tags.water !== "water_none"
            && resourceNames[noColor(r[0])]
            && s.radius > 2000;
    });
}

function primaryResource(s) {
    const r = resourcesArray(s.resource);
    return r.length > 0 ? noColor(r[0]) : null;
}

function evalCore(seedOld) {
    // Seed has every special resource as primary on some viable body
    const bodies = viableBodies(seedOld);
    const covered = new Set();
    for (const b of bodies) {
        const p = primaryResource(b);
        if (p && SPECIAL.includes(p)) covered.add(p);
    }
    if (covered.size >= 6) {
        console.log(`\n=== CORE: seed ${seedOld.seed} loot: ${seedOld.loot.join("")} ===`);
        console.log(`  All 6 specials covered across ${bodies.length} viable bodies`);
        for (const res of SPECIAL) {
            const b = bodies.find(x => primaryResource(x) === res);
            if (b) console.log(`    ${rename(res)}: ${b.name} (${b.zone_type[0]}) dv=${b.delta_v} r=${b.radius}`);
        }
        console.log();
        return true;
    }
    return false;
}

function evalPairs(seedOld) {
    // Production-chain-aware resource pairings.
    // Each combo can be on the same body (ideal) or different bodies (good).
    const combos = [
        { name: "vulc+irid", want: ["se-vulcanite", "se-iridium-ore"] },
        { name: "beryl+cryo", want: ["se-beryllium-ore", "se-cryonite"] },
        { name: "holm", want: ["se-holmium-ore"] },
        { name: "vita+stone", want: ["se-vitamelange", "stone"] },
        { name: "K2:rare+H2O", want: ["kr-rare-metal-ore", "kr-mineral-water"], primary: "kr-rare-metal-ore" },
    ];

    const bodies = viableBodies(seedOld);
    const results = [];
    for (const c of combos) {
        const match = bodies.find(b => {
            const rs = b.resource || {};
            if (!c.want.every(r => (rs[r] || 0) > 0)) return false;
            // If primary is specified, ensure it's the highest-scoring resource
            if (c.primary) {
                const sorted = Object.keys(rs).sort((a,b) => rs[b] - rs[a]);
                if (sorted[0] !== c.primary) return false;
            }
            return true;
        });
        if (match) results.push({ ...c, body: match });
    }

    // Only show seeds with all combos found
    if (results.length >= combos.length) {
        // Sort by delta-v (closest first)
        results.sort((a, b) => a.body.delta_v - b.body.delta_v);
        console.log(`\n=== PAIRS: seed ${seedOld.seed} loot: ${seedOld.loot.join("")} ===`);
        for (const r of results) {
            const b = r.body;
            // Sort resources by score (highest first)
            const parts = [...r.want].sort((a, b2) => (b.resource[b2]||0) - (b.resource[a]||0))
                .map(w => `${rename(w)}:${((b.resource||{})[w]||0).toFixed(4)}`);
            console.log(`  ${r.name}: ${b.name} (${b.zone_type[0]}) dv=${b.delta_v} r=${b.radius}  ${parts.join(" ")}`);
        }
        console.log();
        return true;
    }
    return false;
}

// ── main ─────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const mode = args.includes("--core") ? "core" : args.includes("--pairs") ? "pairs" : "show";
const allMode = args.includes("--all");
const files = args.filter(a => !a.startsWith("--"));

let fnames = [];
for (const arg of files) {
    if (fs.statSync(arg).isDirectory()) {
        const dirFiles = fs.readdirSync(arg).filter(f => f.startsWith("seeds_") && f.endsWith(".jsonl"));
        fnames.push(...dirFiles.map(f => arg + "/" + f));
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
            if (mode === "core" && evalCore(old)) matched++;
            else if (mode === "pairs" && evalPairs(old)) matched++;
            else if (mode === "show" && evalSeed(old)) matched++;
        } catch (e) {}
    }
}
console.log(`${matched} seeds matched (${fnames.length} files scanned)`);
