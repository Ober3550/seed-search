#!/usr/bin/env node
// Publish the static site by hand through the local clone of the GitHub Pages
// repo that sits next to this one:
//
//   node scripts/publish-pages.mjs [--site ../Ober3550.github.io] [--dir seed-search] [--no-build]
//
// Builds the three wasm modules, assembles the site (scripts/build-pages.mjs)
// and replaces <site>/<dir>/ with it. Nothing is committed or pushed: review
// the result in the site repo and push it yourself - that push is what makes
// it live at https://ober3550.github.io/<dir>/.
import fs from "node:fs";
import path from "node:path";
import { execFileSync, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const arg = (name, fallback) => {
  const i = process.argv.indexOf(name);
  return i !== -1 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
};
const SITE = path.resolve(ROOT, arg("--site", "../Ober3550.github.io"));
const DIR = arg("--dir", "seed-search");
const TARGET = path.join(SITE, DIR);

function git(cwd, ...args) {
  return execFileSync("git", args, { cwd, encoding: "utf8" }).trim();
}
function fail(msg) {
  console.error(msg);
  process.exit(1);
}

// only ever write into a sub-folder of a GitHub Pages site checkout
if (!/^[A-Za-z0-9._-]+$/.test(DIR) || DIR === "." || DIR === "..") fail(`--dir must be a plain folder name (got "${DIR}")`);
if (!fs.existsSync(path.join(SITE, ".git"))) fail(`no git checkout at ${SITE} (pass --site <path to the Pages repo>)`);
const remote = git(SITE, "remote", "get-url", "origin");
if (!/\.github\.io(\.git)?$/i.test(remote)) fail(`${SITE} does not look like a GitHub Pages site repo (origin: ${remote})`);

function run(cmd, args) {
  const r = spawnSync(cmd, args, { cwd: ROOT, stdio: "inherit" });
  if (r.status !== 0) fail(`${cmd} ${args.join(" ")} failed`);
}
if (!process.argv.includes("--no-build")) run("node", ["install.mjs", "--wasm-only"]);
// "-dirty" when the published sources differ from the commit (the rebuilt wasm
// binaries themselves are not sources)
const SOURCES = ["space_explorer_gui/public", "surface_generator/src", "universe_generator/zig", "scripts/build-pages.mjs", ":!*.wasm"];
const dirty = git(ROOT, "status", "--porcelain", "--", ...SOURCES) !== "";
const version = git(ROOT, "rev-parse", "--short", "HEAD") + (dirty ? "-dirty" : "");
run("node", ["scripts/build-pages.mjs", "--out", TARGET, "--version", version]);
// the site repo serves files as-is already; the marker belongs at its root
fs.rmSync(path.join(TARGET, ".nojekyll"), { force: true });

console.log(`\nSite written to ${TARGET} (build ${version}). Not committed, not pushed.`);
console.log("To publish:");
console.log(`  cd ${SITE}`);
console.log(`  git add ${DIR} && git commit -m "seed-search ${version}" && git push`);
