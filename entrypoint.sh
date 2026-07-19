#!/bin/sh
mkdir -p /workspace/output
cd /workspace/output

N=$(ls seeds_*.jsonl 2>/dev/null | sed 's/seeds_\([0-9]*\)\.jsonl/\1/' | sort -n | tail -1)
N=$(( ${N:-0} + 1 ))

echo "[seedgen] Writing JSONL to seeds_${N}.jsonl" | tee progress.log
echo "[seedgen] $(date -Iseconds) Starting" | tee -a progress.log

# stderr (JSONL + progress) → seeds_N.jsonl, filter progress to progress.log on the side
exec /usr/local/bin/seedgen 2>&1 | tee "seeds_${N}.jsonl" | grep '^#' >> progress.log
