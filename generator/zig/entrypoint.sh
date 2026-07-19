#!/bin/sh
for i in $(seq 1 30); do mkdir -p /workspace/output 2>/dev/null && break; sleep 0.1; done
cd /workspace/output 2>/dev/null || { echo "ERROR: /workspace/output not available"; exit 1; }

PREV=$(ls seeds_*.jsonl 2>/dev/null | sort -t_ -k2 -n | tail -1)
if [ -n "$PREV" ] && [ -s "$PREV" ]; then
  FIRST=$(head -c 50 "$PREV" | sed 's/{"s":\([0-9]*\).*/\1/')
  LINES=$(grep -c '^{' "$PREV" 2>/dev/null || echo 0)
  if [ -n "$FIRST" ] && [ "$FIRST" -gt 0 ] && [ "$LINES" -gt 0 ]; then
    export START_SEED=$((FIRST + 2 * LINES))
  fi
fi
echo "[seedgen] $(date -Iseconds) starting at seed ${START_SEED:-341}"
exec /usr/local/bin/seedgen 2>> progress.log | while IFS= read -r line; do
  case "$line" in
    "{"*)
      S=$(echo "$line" | sed 's/{"s":\([0-9]*\).*/\1/')
      B=$(( S / 100000 * 100000 ))
      echo "$line" >> "seeds_${B}.jsonl"
      ;;
  esac
done
