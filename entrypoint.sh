#!/bin/sh
# Docker on macOS sometimes mounts volumes after entrypoint starts.
# Create the mount point and wait until it's available.
mkdir -p /workspace/output 2>/dev/null
while [ ! -d /workspace/output ]; do sleep 0.1; done
cd /workspace/output || exit 1
exec /usr/local/bin/seedgen 2>> progress.log
