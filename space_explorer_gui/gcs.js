// Final surface/ore renders live in a PUBLIC Google Cloud Storage bucket, so the
// web page can <img src> them directly and no render tree is kept on disk.
//   upload:  gcs.uploadRender(localPng, seed, zone, file)
//   display: gcs.renderUrl(seed, zone, file)  ->  https://storage.googleapis.com/<bucket>/renders/<seed>/<zone>/<file>
const { spawn } = require("child_process");
const path = require("path");
const os = require("os");

const BUCKET = process.env.GCS_BUCKET || "space-exploration-explorer";
const BASE = process.env.GCS_RENDER_BASE || `https://storage.googleapis.com/${BUCKET}`;
const GCLOUD = process.env.GCLOUD_BIN ||
  (fsExists(path.join(os.homedir(), "google-cloud-sdk", "bin", "gcloud"))
    ? path.join(os.homedir(), "google-cloud-sdk", "bin", "gcloud")
    : "gcloud");

function fsExists(p) { try { return require("fs").existsSync(p); } catch (_) { return false; } }

// Object key inside the bucket. Seed-keyed (bucket/job labels are going away).
function renderKey(seed, zone, file) {
  return `renders/${seed}/${zone}/${file}`;
}

// Public URL for the web page (encode the path segments for the browser).
function renderUrl(seed, zone, file) {
  return `${BASE}/renders/${seed}/${encodeURIComponent(zone)}/${encodeURIComponent(file)}`;
}

// Upload one finished render. Resolves with the gs:// URI, rejects on failure.
// (No-op-friendly: callers should catch — a failed upload must not fail the job.)
function uploadRender(localPath, seed, zone, file) {
  return new Promise((resolve, reject) => {
    const dest = `gs://${BUCKET}/${renderKey(seed, zone, file)}`;
    const ch = spawn(GCLOUD, ["storage", "cp", "--quiet", localPath, dest],
      { stdio: ["ignore", "ignore", "pipe"] });
    let err = "";
    ch.stderr.on("data", (d) => (err += d));
    ch.on("error", reject);
    ch.on("close", (code) => code === 0 ? resolve(dest) : reject(new Error(`gcloud cp exit ${code}: ${err.slice(-200)}`)));
  });
}

module.exports = { BUCKET, BASE, renderKey, renderUrl, uploadRender };

// self-test: node gcs.js <localFile>  → uploads to renders/_selftest/... and prints the URL
if (require.main === module) {
  const f = process.argv[2];
  if (!f) { console.error("usage: node gcs.js <file>"); process.exit(1); }
  uploadRender(f, "_selftest", "zone", path.basename(f))
    .then((gs) => console.log("uploaded", gs, "\npublic:", renderUrl("_selftest", "zone", path.basename(f))))
    .catch((e) => { console.error("upload failed:", e.message); process.exit(1); });
}
