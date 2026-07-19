#!/bin/sh
# Wait for the mounted volume to be available (Docker on macOS can be slow)
for i in $(seq 1 30); do
  mkdir -p /workspace/output 2>/dev/null && break
  sleep 0.1
done
cd /workspace/output 2>/dev/null || { echo "ERROR: /workspace/output not available after 3s"; exit 1; }

PREV=$(ls seeds_*.jsonl 2>/dev/null | sort -n | tail -1)
if [ -n "$PREV" ] && [ -s "$PREV" ]; then
  FIRST=$(head -c 50 "$PREV" | sed 's/{"s":\([0-9]*\).*/\1/')
  LINES=$(grep -c '^{' "$PREV" 2>/dev/null || echo 0)
  if [ -n "$FIRST" ] && [ "$FIRST" -gt 0 ] && [ "$LINES" -gt 0 ]; then
    export START_SEED=$((FIRST + 2 * LINES))
  fi
fi

N=$(ls seeds_*.jsonl 2>/dev/null | sed 's/seeds_\([0-9]*\)\.jsonl/\1/' | sort -n | tail -1)
N=$(( ${N:- -1} + 1 ))

echo "[seedgen] $(date -Iseconds) seeds_${N}.jsonl from seed ${START_SEED:-341}"
exec /usr/local/bin/seedgen 1>> "seeds_${N}.jsonl" 2>> progress.log
