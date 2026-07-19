#!/bin/sh
mkdir -p /workspace/output
cd /workspace/output
N=$(ls seeds_*.jsonl 2>/dev/null | sed 's/seeds_\([0-9]*\)\.jsonl/\1/' | sort -n | tail -1)
N=$(( ${N:-0} + 1 ))
echo "[seedgen] $(date -Iseconds) Writing to seeds_${N}.jsonl"
exec /usr/local/bin/seedgen 1>> "seeds_${N}.jsonl" 2>> progress.log
