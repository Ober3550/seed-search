#!/usr/bin/env node
// Assemble the static site (the seed page + the surface page) into dist/.
//
//   node install.mjs --wasm-only      # build the three wasm modules first
//   node scripts/build-pages.mjs [--out dist] [--version <id>]
//
// Layout:
//   dist/index.html, dist/surface.html     the two pages
//   dist/assets-<version>/...              scripts, styles, wasm, shaders
//   dist/.nojekyll                         serve the folder as-is
//
// Everything but the two pages lives in a folder named after the build, so a
// new deploy can never be mixed with a browser's cached copy of the previous
// one (a page from build A loading a wasm from build B). shell.js resolves
// assets relative to itself and page links relative to the document, so the
// pages find both without knowing the folder name or the site's base path.
import fs from "node:fs";
import path from "node:path";
import { execSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const PUBLIC = path.join(ROOT, "space_explorer_gui", "public");
const arg = (name, fallback) => {
  const i = process.argv.indexOf(name);
  return i !== -1 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
};
const OUT = path.resolve(arg("--out", path.join(ROOT, "dist")));

function gitVersion() {
  try {
    return execSync("git rev-parse --short HEAD", { cwd: ROOT, encoding: "utf8" }).trim();
  } catch {
    return String(Date.now());
  }
}
const VERSION = arg("--version", process.env.GITHUB_SHA ? process.env.GITHUB_SHA.slice(0, 7) : gitVersion());
const ASSETS = "assets-" + VERSION;

const PAGES = ["index.html", "surface.html"];
// Everything the two pages load, directly or from a worker.
const FILES = [
  "style.css", "shell.js",
  "gen-bridge.js", "gen-worker.js", "universe-wasm.js", "surface-wasm.js", "sa-wasm.js",
  "estimate-core.js", "analyze.js", "surface.js",
  "gpu-surface.js", "gpu-worker.js", "ab-table.js",
  "ore-model.json", "featured-seeds.json",
  "universe.wasm", "surface.wasm", "sa.wasm",
  "shaders/elevation.wgsl", "shaders/nauvis.wgsl", "shaders/se_field.wgsl", "shaders/se_zone.wgsl",
];

const missing = FILES.concat(PAGES).filter((f) => !fs.existsSync(path.join(PUBLIC, f)));
if (missing.length) {
  console.error("missing in space_explorer_gui/public: " + missing.join(", ") +
    "\nBuild the wasm modules first: node install.mjs --wasm-only");
  process.exit(1);
}

fs.rmSync(OUT, { recursive: true, force: true });
fs.mkdirSync(path.join(OUT, ASSETS, "shaders"), { recursive: true });
let bytes = 0;
for (const f of FILES) {
  fs.copyFileSync(path.join(PUBLIC, f), path.join(OUT, ASSETS, f));
  bytes += fs.statSync(path.join(PUBLIC, f)).size;
}
for (const page of PAGES) {
  // point the page's own script / stylesheet references into the assets folder
  let html = fs.readFileSync(path.join(PUBLIC, page), "utf8");
  let refs = 0;
  html = html.replace(/(<script src="|<link rel="stylesheet" href=")([^"]+)"/g, (_, pre, file) => {
    if (!FILES.includes(file)) throw new Error(`${page} references ${file}, which is not in the published file list`);
    refs++;
    return `${pre}${ASSETS}/${file}"`;
  });
  if (!refs) throw new Error(`${page}: no asset references found`);
  fs.writeFileSync(path.join(OUT, page), html);
}
fs.writeFileSync(path.join(OUT, ".nojekyll"), "");
console.log(`dist: ${path.relative(ROOT, OUT) || "."}/ — ${PAGES.length} pages + ${FILES.length} assets in ${ASSETS}/ (${(bytes / 1048576).toFixed(1)} MB)`);
