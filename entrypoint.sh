#!/bin/sh
for i in $(seq 1 30); do
  mkdir -p /workspace/output 2>/dev/null && break
  sleep 0.1
done
cd /workspace/output 2>/dev/null || { echo "ERROR: /workspace/output not available"; exit 1; }

PREV=$(ls seeds_*.jsonl 2>/dev/null | sort -t_ -k2 -n | tail -1)
if [ -n "$PREV" ] && [ -s "$PREV" ]; then
  LAST_SEED=$(tail -1 "$PREV" | head -c 50 | sed 's/{"s":\([0-9]*\).*/\1/')
  if [ -n "$LAST_SEED" ] && [ "$LAST_SEED" -gt 0 ]; then
    export START_SEED=$((LAST_SEED + 2))
  fi
fi

BUCKET=$(( ${START_SEED:-341} / 100000 * 100000 ))
echo "[seedgen] $(date -Iseconds) seeds_${BUCKET}.jsonl (from ${START_SEED:-341})"
exec /usr/local/bin/seedgen 1>> "seeds_${BUCKET}.jsonl" 2>> progress.log
