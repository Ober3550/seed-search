#!/bin/sh
mkdir -p /workspace/output 2>/dev/null
cd /workspace/output 2>/dev/null || { echo "ERROR: /workspace/output not available"; exit 1; }

PREV=$(ls seeds_*.jsonl 2>/dev/null | sort -n | tail -1)
if [ -n "$PREV" ] && [ -s "$PREV" ]; then
  # Extract the FIRST "s": field (top-level seed, not zone seeds)
  LAST_SEED=$(head -c 50 "$PREV" | sed 's/{"s":\([0-9]*\).*/\1/')
  if [ -n "$LAST_SEED" ] && [ "$LAST_SEED" -gt 0 ]; then
    # Count lines to get actual last seed
    LINES=$(grep -c '^{' "$PREV" 2>/dev/null || echo 0)
    export START_SEED=$((LAST_SEED + 2 * LINES))
  fi
fi

N=$(ls seeds_*.jsonl 2>/dev/null | sed 's/seeds_\([0-9]*\)\.jsonl/\1/' | sort -n | tail -1)
N=$(( ${N:- -1} + 1 ))

echo "[seedgen] $(date -Iseconds) Writing to seeds_${N}.jsonl (from seed ${START_SEED:-341})"
exec /usr/local/bin/seedgen 1>> "seeds_${N}.jsonl" 2>> progress.log
