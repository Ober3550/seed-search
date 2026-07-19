#!/bin/sh
mkdir -p /workspace/output 2>/dev/null
cd /workspace/output 2>/dev/null || exit 1
B=$(( ${START_SEED:-0} + ${END_SEED:-100000} - ${START_SEED:-0} ))
echo "[seedgen] $(date -Iseconds) seeds_${END_SEED:-100000}.jsonl (${START_SEED:-0} → ${END_SEED:-100000})"
exec /usr/local/bin/seedgen 1>> "seeds_${END_SEED:-100000}.jsonl" 2>> progress.log
