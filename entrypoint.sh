#!/bin/sh
mkdir -p /workspace/output 2>/dev/null
cd /workspace/output 2>/dev/null || exit 1
END=$(( ${START_SEED:-341} + ${COUNT:-100000} ))
NAME=$(( END / 100000 * 100000 ))
echo "[seedgen] $(date -Iseconds) seeds_${NAME}.jsonl (${START_SEED:-341} → $END)"
exec /usr/local/bin/seedgen 1>> "seeds_${NAME}.jsonl" 2>> progress.log
