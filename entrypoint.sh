#!/bin/sh
# Entrypoint for seedgen Docker container.
# - Auto-resumes from the last seed in the most recent seeds_*.jsonl file.
# - Rolls to a new file every MAX_LINES_PER_FILE lines (default 10000).
# - Progress lines (stdout) → progress.log.
# - JSONL lines (stderr) → seeds_N.jsonl with rotation.
# - Monitor logs total rate every 30s.

set -e
cd /workspace/output
MAX_LINES=${MAX_LINES_PER_FILE:-10000}

# Find the most recent seeds_N.jsonl
CUR_N=$(ls seeds_*.jsonl 2>/dev/null | sed 's/seeds_\([0-9]*\)\.jsonl/\1/' | sort -n | tail -1)
if [ -z "$CUR_N" ]; then
  CUR_N=0
  START=${START_SEED:-341}
else
  CUR_LINES=$(wc -l < "seeds_${CUR_N}.jsonl" 2>/dev/null || echo 0)
  if [ "$CUR_LINES" -ge "$MAX_LINES" ]; then
    CUR_N=$((CUR_N + 1))
  fi
  LAST_LINE=$(tail -1 "seeds_${CUR_N}.jsonl" 2>/dev/null)
  if [ -n "$LAST_LINE" ]; then
    START=$(echo "$LAST_LINE" | sed 's/.*"s":\([0-9]*\).*/\1/')
    START=$((START + 2))
  else
    START=${START_SEED:-341}
  fi
fi

echo "[seedgen] Starting at $(date -Iseconds)  seed=$START  file=seeds_${CUR_N}.jsonl  max_lines=$MAX_LINES" | tee -a progress.log
echo "[seedgen] Config: K2=${SE_K2:-0} MIN_NAQ_DV=${MIN_NAQ_DV:-0} MIN_PROD_MODULES=${MIN_PROD_MODULES:-0} COUNT=${COUNT:-0}" | tee -a progress.log

# Background monitor: log total lines every 30s
(
  LAST=0
  while true; do
    sleep 30
    TOTAL=$(wc -l < progress.log 2>/dev/null || echo 0)
    PASSED=$(wc -l < "seeds_${CUR_N}.jsonl" 2>/dev/null || echo 0)
    echo "[seedgen] $(date +%H:%M:%S)  progress_lines=$TOTAL  passed=$PASSED  file=$CUR_N" | tee -a progress.log
  done
) &
MONITOR_PID=$!

# Run seedgen: stdout (progress) → progress.log, stderr (JSONL) → rotating file
START_SEED=$START /usr/local/bin/seedgen 2>&1 > progress.log | (
  COUNT=0
  while IFS= read -r line; do
    case "$line" in
      "{"*)
        echo "$line" >> "seeds_${CUR_N}.jsonl"
        COUNT=$((COUNT + 1))
        if [ "$COUNT" -ge "$MAX_LINES" ]; then
          CUR_N=$((CUR_N + 1))
          COUNT=0
          echo "[seedgen] $(date +%H:%M:%S)  rolled over to seeds_${CUR_N}.jsonl" | tee -a progress.log
        fi
        ;;
    esac
  done
)

kill $MONITOR_PID 2>/dev/null || true
wait $MONITOR_PID 2>/dev/null || true
echo "[seedgen] Done at $(date -Iseconds)  lines=$(wc -l < "seeds_${CUR_N}.jsonl")" | tee -a progress.log
