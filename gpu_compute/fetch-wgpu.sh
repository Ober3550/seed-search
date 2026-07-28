#!/usr/bin/env bash
# Download + extract the pinned wgpu-native prebuilt(s) into vendor/.
# The binaries are large (~14–34 MB each) and gitignored — run this after clone.
#
#   ./fetch-wgpu.sh                # host platform (auto-detected)
#   ./fetch-wgpu.sh all            # every platform (for cross-checking)
#   WGPU_VERSION=v29.0.1.1 ./fetch-wgpu.sh
set -euo pipefail
cd "$(dirname "$0")"

VERSION="${WGPU_VERSION:-v29.0.1.1}"
BASE="https://github.com/gfx-rs/wgpu-native/releases/download/${VERSION}"

detect() {
  local os arch
  case "$(uname -s)" in
    Darwin) os="macos" ;;
    Linux)  os="linux" ;;
    MINGW*|MSYS*|CYGWIN*) os="windows" ;;
    *) echo "unknown OS $(uname -s)" >&2; exit 1 ;;
  esac
  case "$(uname -m)" in
    arm64|aarch64) arch="aarch64" ;;
    x86_64|amd64)  arch="x86_64" ;;
    *) echo "unknown arch $(uname -m)" >&2; exit 1 ;;
  esac
  if [ "$os" = "windows" ]; then echo "wgpu-${os}-${arch}-msvc"; else echo "wgpu-${os}-${arch}"; fi
}

fetch() {
  local triple="$1"
  local dir="vendor/${triple}"
  if [ -f "${dir}/lib/libwgpu_native.dylib" ] || [ -f "${dir}/lib/libwgpu_native.so" ] || [ -f "${dir}/lib/wgpu_native.dll" ]; then
    echo "✓ ${triple} already present"; return
  fi
  echo "↓ ${triple} (${VERSION})"
  mkdir -p "${dir}"
  curl -sSL -m 180 -o "vendor/${triple}.zip" "${BASE}/${triple}-release.zip"
  unzip -q -o "vendor/${triple}.zip" -d "${dir}"
  rm -f "vendor/${triple}.zip"
}

mkdir -p vendor
if [ "${1:-}" = "all" ]; then
  for t in wgpu-macos-aarch64 wgpu-macos-x86_64 wgpu-linux-aarch64 wgpu-linux-x86_64 wgpu-windows-x86_64-msvc wgpu-windows-aarch64-msvc; do
    fetch "$t"
  done
else
  fetch "$(detect)"
fi
echo "done — pinned ${VERSION}"
