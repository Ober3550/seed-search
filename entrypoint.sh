#!/bin/sh
mkdir -p /workspace/output 2>/dev/null
cd /workspace/output 2>/dev/null || { echo "ERROR: /workspace/output not available"; exit 1; }

# Resume: find the last file and extract its end seed
PREV=$(ls seeds_*.jsonl 2>/dev/null | sort -t_ -k2 -n | tail -1)
if [ -n "$PREV" ] && [ -s "$PREV" ]; then
  FIRST=$(head -c 50 "$PREV" | sed 's/{"s":\([0-9]*\).*/\1/')
  LINES=$(grep -c '^{' "$PREV" 2>/dev/null || echo 0)
  if [ -n "$FIRST" ] && [ "$FIRST" -gt 0 ] && [ "$LINES" -gt 0 ]; then
    export START_SEED=$((FIRST + 2 * LINES))
  fi
fi

# Bucket by 100k: seeds_0.jsonl, seeds_100000.jsonl, etc.
BUCKET=$(( ${START_SEED:-341} / 100000 * 100000 ))
echo "[seedgen] $(date -Iseconds) seeds_${BUCKET}.jsonl (from seed ${START_SEED:-341})"
exec /usr/local/bin/seedgen 1>> "seeds_${BUCKET}.jsonl" 2>> progress.log
