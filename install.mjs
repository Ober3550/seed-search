#!/usr/bin/env node
// Cross-platform installer for the SE seed-search project.
//
// Builds the three Zig components the web server depends on and installs the
// server's Node dependencies. Runs identically on macOS / Linux / Windows —
// the only hard prerequisites are Node (>=18, which you already have since it's
// running this) and Zig 0.16.x on PATH.
//
//   node install.mjs            # build everything + npm install the server
//   node install.mjs --build-only   # build the Zig components only (the web
//                                    #   server's deps are handled by npm when
//                                    #   installed as a package — see postinstall)
//   node install.mjs --help
//
// It is safe to re-run: each step is idempotent (Zig rebuilds are incremental,
// wgpu prebuilts are skipped if already present, npm install is a no-op when
// up to date).
//
// See install.sh / install.cmd for thin one-line bootstrappers.

import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import crypto from "node:crypto";
import zlib from "node:zlib";
import path from "node:path";
import fs from "node:fs";
import os from "node:os";

const ROOT = path.dirname(fileURLToPath(import.meta.url));
const WGPU_VERSION = process.env.WGPU_VERSION || "v29.0.1.1";

// ---------------------------------------------------------------------------
// Tiny logging helpers
// ---------------------------------------------------------------------------
const useColor = process.stdout.isTTY && !process.env.NO_COLOR;
const c = (code, s) => (useColor ? `\x1b[${code}m${s}\x1b[0m` : s);
const bold = (s) => c("1", s);
const green = (s) => c("32", s);
const red = (s) => c("31", s);
const dim = (s) => c("2", s);
let stepN = 0;
const step = (msg) => console.log("\n" + bold(`[${++stepN}] ${msg}`));
const ok = (msg) => console.log(green("  ✓ ") + msg);
const fail = (msg) => {
  console.error(red("\nInstall failed: ") + msg);
  process.exit(1);
};

// Windows ships npm as a .cmd shim, and since the fix for CVE-2024-27980 Node
// refuses to spawn .bat/.cmd files unless a shell is requested — spawnSync fails
// with EINVAL before the command ever runs, which looks identical to "npm isn't
// installed". Route those through cmd.exe. Every argument the installer passes is
// a hardcoded literal, so nothing user-controlled reaches the shell.
const IS_WIN = process.platform === "win32";
const needsShell = (cmd) => IS_WIN && /\.(cmd|bat)$/i.test(cmd);

// Run a command, streaming its output; abort the install on failure.
function run(cmd, args, cwd) {
  console.log(dim(`  $ ${cmd} ${args.join(" ")}  (in ${path.relative(ROOT, cwd) || "."})`));
  const r = spawnSync(cmd, args, { cwd, stdio: "inherit", shell: needsShell(cmd) });
  if (r.error) fail(`could not run '${cmd}': ${r.error.message}`);
  if (r.status !== 0) fail(`'${cmd} ${args.join(" ")}' exited with code ${r.status}`);
}

// ---------------------------------------------------------------------------
// Prerequisite checks
// ---------------------------------------------------------------------------
function checkNode() {
  const major = Number(process.versions.node.split(".")[0]);
  if (major < 18) fail(`Node 18+ required (found ${process.version}). Install from https://nodejs.org/`);
}

function checkZig() {
  const r = spawnSync("zig", ["version"], { encoding: "utf8" });
  if (r.error || r.status !== 0) {
    fail(
      "Zig 0.16.x not found on PATH.\n" +
        "  Install it from https://ziglang.org/download/ (pick 0.16.x) and\n" +
        "  make sure `zig version` works in a fresh shell, then re-run this installer."
    );
  }
  const ver = r.stdout.trim();
  if (!/^0\.16\./.test(ver)) {
    fail(
      `Zig 0.16.x required (found ${ver}).\n` +
        "  Get a 0.16.x build from https://ziglang.org/download/ and put it first on PATH."
    );
  }
  ok(`zig ${ver}`);
}

function checkNpm() {
  // npm ships with Node, but confirm it's callable (Windows resolves npm.cmd).
  const npm = IS_WIN ? "npm.cmd" : "npm";
  const r = spawnSync(npm, ["--version"], { encoding: "utf8", shell: needsShell(npm) });
  // Distinguish "couldn't launch it" from "it ran and failed" — reporting both as
  // "not on PATH" sent people hunting for a Node install that was already fine.
  if (r.error) fail(`could not run '${npm} --version': ${r.error.message}`);
  if (r.status !== 0) {
    fail(`'${npm} --version' exited with code ${r.status}.\n${(r.stderr || "").trim()}`);
  }
  ok(`npm ${r.stdout.trim()}`);
  return npm;
}

// ---------------------------------------------------------------------------
// wgpu-native prebuilts (pure-JS port of gpu_compute/fetch-wgpu.sh, so it works
// on Windows without bash/curl/unzip).
// ---------------------------------------------------------------------------
function wgpuTriple() {
  const arch = { arm64: "aarch64", x64: "x86_64" }[process.arch];
  if (!arch) fail(`unsupported CPU arch for wgpu: ${process.arch}`);
  const osName = { darwin: "macos", linux: "linux", win32: "windows" }[process.platform];
  if (!osName) fail(`unsupported OS for wgpu: ${process.platform}`);
  return osName === "windows" ? `wgpu-windows-${arch}-msvc` : `wgpu-${osName}-${arch}`;
}

function wgpuLibPresent(destDir) {
  const lib = path.join(destDir, "lib");
  if (!fs.existsSync(lib)) return false;
  return ["libwgpu_native.dylib", "libwgpu_native.so", "wgpu_native.dll"].some((f) =>
    fs.existsSync(path.join(lib, f))
  );
}

// Minimal ZIP extractor using the central directory + zlib.inflateRawSync.
// Handles stored (0) and deflate (8) — all wgpu-native release zips use these.
function extractZip(buf, destDir) {
  // Locate the End Of Central Directory record (scan back for its signature).
  let eocd = -1;
  for (let i = buf.length - 22; i >= 0; i--) {
    if (buf.readUInt32LE(i) === 0x06054b50) {
      eocd = i;
      break;
    }
  }
  if (eocd < 0) fail("wgpu zip is corrupt (no end-of-central-directory record).");
  const count = buf.readUInt16LE(eocd + 10);
  let ptr = buf.readUInt32LE(eocd + 16); // central directory offset

  for (let n = 0; n < count; n++) {
    if (buf.readUInt32LE(ptr) !== 0x02014b50) fail("wgpu zip is corrupt (bad central-directory entry).");
    const method = buf.readUInt16LE(ptr + 10);
    const compSize = buf.readUInt32LE(ptr + 20);
    const nameLen = buf.readUInt16LE(ptr + 28);
    const extraLen = buf.readUInt16LE(ptr + 30);
    const commentLen = buf.readUInt16LE(ptr + 32);
    const localOff = buf.readUInt32LE(ptr + 42);
    const name = buf.toString("utf8", ptr + 46, ptr + 46 + nameLen);
    ptr += 46 + nameLen + extraLen + commentLen;

    const outPath = path.join(destDir, name);
    // Guard against zip-slip (entries escaping destDir).
    if (!outPath.startsWith(destDir + path.sep) && outPath !== destDir) {
      fail(`wgpu zip contains an unsafe path: ${name}`);
    }
    if (name.endsWith("/")) {
      fs.mkdirSync(outPath, { recursive: true });
      continue;
    }
    // Read the local header to find where the file data actually starts
    // (its name/extra lengths can differ from the central-directory copy).
    const lNameLen = buf.readUInt16LE(localOff + 26);
    const lExtraLen = buf.readUInt16LE(localOff + 28);
    const dataStart = localOff + 30 + lNameLen + lExtraLen;
    const comp = buf.subarray(dataStart, dataStart + compSize);
    let data;
    if (method === 0) data = comp;
    else if (method === 8) data = zlib.inflateRawSync(comp);
    else fail(`wgpu zip uses unsupported compression method ${method} for ${name}`);

    fs.mkdirSync(path.dirname(outPath), { recursive: true });
    fs.writeFileSync(outPath, data);
  }
}

// Fetch a URL into a Buffer, aborting the install with a readable message on
// any network failure. `what` names the asset in error messages.
async function download(url, what, timeoutMs = 180_000) {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeoutMs);
  let res;
  try {
    res = await fetch(url, { signal: ctrl.signal, redirect: "follow" });
  } catch (e) {
    fail(`downloading ${what} failed: ${e.message}\n  (URL: ${url})`);
  } finally {
    clearTimeout(timer);
  }
  if (!res.ok) fail(`downloading ${what} failed: HTTP ${res.status} for ${url}`);
  return Buffer.from(await res.arrayBuffer());
}

async function fetchWgpu() {
  const triple = wgpuTriple();
  const vendor = path.join(ROOT, "gpu_compute", "vendor");
  const dest = path.join(vendor, triple);
  if (wgpuLibPresent(dest)) {
    ok(`wgpu ${triple} already present (${WGPU_VERSION})`);
    return;
  }
  const url = `https://github.com/gfx-rs/wgpu-native/releases/download/${WGPU_VERSION}/${triple}-release.zip`;
  console.log(dim(`  ↓ ${triple} ${WGPU_VERSION}`));
  const buf = await download(url, "wgpu-native");
  fs.mkdirSync(dest, { recursive: true });
  extractZip(buf, dest);
  if (!wgpuLibPresent(dest)) fail(`wgpu extraction did not produce a library under ${path.relative(ROOT, dest)}/lib`);
  ok(`wgpu ${triple} ${WGPU_VERSION}`);
}

// ---------------------------------------------------------------------------
// htmx (the web GUI's only front-end dependency)
//
// The entire GUI is server-rendered HTML driven by hx-get/hx-post attributes,
// so with htmx missing the page still loads and *looks* fine while every button
// silently does nothing — including "queue job". It is not vendored in git, and
// the server used to paper over the gap by writing an 87-byte placeholder
// comment, which made the file look present to any exists() check. Fetch the
// real thing here, and treat a stub as missing.
// ---------------------------------------------------------------------------
const HTMX_VERSION = process.env.HTMX_VERSION || "2.0.4";
// sha256 of the pinned release, verified only when the version is not overridden.
const HTMX_SHA256 = "e209dda5c8235479f3166defc7750e1dbcd5a5c1808b7792fc2e6733768fb447";
const HTMX_MIN_BYTES = 10_000; // real builds are ~50 KB; anything smaller is a stub

function htmxPresent(dest) {
  try {
    return fs.statSync(dest).size >= HTMX_MIN_BYTES;
  } catch {
    return false;
  }
}

async function fetchHtmx() {
  const dest = path.join(ROOT, "space_explorer_gui", "public", "htmx.min.js");
  if (htmxPresent(dest)) {
    ok(`htmx already present (${(fs.statSync(dest).size / 1024).toFixed(0)} KB)`);
    return;
  }
  const url = `https://unpkg.com/htmx.org@${HTMX_VERSION}/dist/htmx.min.js`;
  console.log(dim(`  ↓ htmx ${HTMX_VERSION}`));
  const buf = await download(url, "htmx", 60_000);
  if (buf.length < HTMX_MIN_BYTES) {
    fail(`htmx download looks wrong: got ${buf.length} bytes from ${url}`);
  }
  if (!process.env.HTMX_VERSION) {
    const got = crypto.createHash("sha256").update(buf).digest("hex");
    if (got !== HTMX_SHA256) {
      fail(`htmx checksum mismatch for ${url}\n  expected ${HTMX_SHA256}\n  got      ${got}`);
    }
  }
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.writeFileSync(dest, buf);
  ok(`htmx ${HTMX_VERSION} → space_explorer_gui/public/htmx.min.js`);
}

// ---------------------------------------------------------------------------
// Build steps
// ---------------------------------------------------------------------------
function buildSeedgen() {
  // universe_generator has no build.zig — it's a single-file build-exe.
  //
  // The .exe suffix is REQUIRED on Windows. -femit-bin writes exactly the name
  // given, and while an extension-less PE file exists on disk happily, Windows
  // cannot launch one: libuv's spawn appends .com/.exe to any command without an
  // extension, so `spawn(".../seedgen")` fails with ENOENT even though
  // fs.existsSync() on that same path returns true. Every universe job then dies
  // with "spawn: ... ENOENT". `zig build` (segen, gpu_*) adds .exe on its own.
  const dir = path.join(ROOT, "universe_generator", "zig");
  const out = "seedgen" + (IS_WIN ? ".exe" : "");
  run("zig", ["build-exe", "main.zig", "-O", "ReleaseFast", `-femit-bin=${out}`, "-lc"], dir);
  ok(`seedgen → universe_generator/zig/${out}`);
}

function buildSegen() {
  const dir = path.join(ROOT, "surface_generator");
  run("zig", ["build", "-Doptimize=ReleaseFast"], dir);
  ok("segen → surface_generator/zig-out/bin/segen");
}

function buildGpu() {
  const dir = path.join(ROOT, "gpu_compute");
  run("zig", ["build", "-Doptimize=ReleaseFast"], dir);
  ok("gpu_terrain / gpu_biome / gpu_ore / gpu_stitch → gpu_compute/zig-out/bin/");
}

function installServer(npm) {
  const dir = path.join(ROOT, "space_explorer_gui");
  run(npm, ["install"], dir);
  ok("web server dependencies → space_explorer_gui/node_modules");
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
if (process.argv.includes("--help") || process.argv.includes("-h")) {
  console.log(`Usage: node install.mjs [--build-only] [--help]

Builds the Zig components and installs the web server's dependencies:
  1. seedgen   (universe_generator)
  2. segen     (surface_generator)
  3. gpu_*     (gpu_compute — downloads pinned wgpu-native ${WGPU_VERSION} first)
  4. htmx      (the web GUI's front-end dependency — always fetched)
  5. web server dependencies (space_explorer_gui)   [skipped with --build-only]

--build-only  Build the Zig components only; skip the server npm install. Used
              by the package postinstall hook (npm resolves the server's deps).
              htmx is still fetched — it is not an npm dependency.

Prerequisites: Node >=18 (running this) and Zig 0.16.x on PATH.
Env: WGPU_VERSION overrides the pinned wgpu-native release.
     HTMX_VERSION overrides the pinned htmx release (skips the checksum check).

Start the server afterwards with:
  npm start   # http://localhost:3456`);
  process.exit(0);
}

async function main() {
  // --build-only: build the Zig components but skip `npm install` for the web
  // server. Used by the package `postinstall` hook, where npm has already
  // resolved the server's dependencies from this package's own `dependencies`.
  const buildOnly = process.argv.includes("--build-only");
  console.log(bold("SE seed-search installer") + (buildOnly ? dim(" (build-only)") : ""));

  step("Checking prerequisites");
  checkNode();
  checkZig();
  const npm = buildOnly ? null : checkNpm();

  step("Building seedgen (universe generator)");
  buildSeedgen();

  step("Building segen (surface generator)");
  buildSegen();

  step(`Fetching wgpu-native (${WGPU_VERSION})`);
  await fetchWgpu();

  step("Building GPU compute binaries");
  buildGpu();

  // Not gated on --build-only: the GUI is unusable without htmx, and npm can't
  // supply it on the package-install path either (it isn't an npm dependency).
  step(`Fetching htmx (${HTMX_VERSION})`);
  await fetchHtmx();

  if (!buildOnly) {
    step("Installing web server dependencies");
    installServer(npm);
  }

  console.log(
    "\n" +
      green(bold("Install complete.")) +
      "\n\nStart the web server:\n  " +
      bold("npm start") +
      dim("   # → http://localhost:3456")
  );
}

main().catch((e) => fail(e.stack || e.message));
