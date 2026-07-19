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

function evalSeed(seedObject) {
    const planets = seedObject.planets.sort((a, b) => a.delta_v - b.delta_v);
    const moons = seedObject.moons.sort((a, b) => a.delta_v - b.delta_v);
    let bodies = [...planets, ...moons].sort((a, b) => a.delta_v - b.delta_v);

    bodies = bodies.filter(s => {
        const r = resourcesArray(s.resource);
        return s.tags.water !== "water_none"
            && resourceNames[noColor(r[0])]
            && s.radius > 2000;
    });

    const specialHolm = bodies.filter(s => {
        const r = resourcesArray(s.resource);
        return r.includes("se-cryonite")
            && r.includes("se-vulcanite")
            && r.includes("se-holmium-ore");
    });

    if (specialHolm.length > 0) {
        console.log(`seed: ${seedObject.seed} loot: ${seedObject.loot.join("")}`);
        printPlanetsAndMoons(bodies);
        console.log();
        return true;
    }
    return false;
}

// ── main ─────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const allMode = args.includes("--all");
const calidusOnly = args.includes("--calidus");
const files = args.filter(a => a !== "--all" && a !== "--calidus");

// Collect file names (expand directories to seeds_*.jsonl)
let fnames = [];
for (const arg of files) {
    if (fs.statSync(arg).isDirectory()) {
        const dirFiles = fs.readdirSync(arg).filter(f => f.startsWith("seeds_") && f.endsWith(".jsonl"));
        fnames.push(...dirFiles.map(f => arg + "/" + f));
    } else {
        fnames.push(arg);
    }
}
// Sort numerically
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
            const old = convertNewToOld(seed, calidusOnly);
            const loot = old.loot.join("");
            if (allMode || loot.match(/^PPSS/)) {
                if (evalSeed(old)) matched++;
            }
        } catch (e) {}
    }
}
console.log(`${matched} seeds matched (${fnames.length} files scanned)`);
