#!/bin/sh
# Minimal entrypoint — binary handles everything internally.
# Docker just mounts output/ and redirects stderr to progress.log.
cd /workspace/output
exec /usr/local/bin/seedgen 2>> progress.log
