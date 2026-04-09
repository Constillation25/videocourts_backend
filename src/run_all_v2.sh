#!/data/data/com.termux/files/usr/bin/bash
# C25 FULL BUILD v2 — 10s TIMEOUT PER SCRIPT
# No script can hang the build
HOME="${HOME:-/data/data/com.termux/files/home}"
export PATH="/data/data/com.termux/files/usr/bin:$PATH"
OUT="/sdcard/C25_FULL_REBUILD"
LOG="$OUT/BUILD_v2.log"
TRUTH="/sdcard/TERMUX_TRUTH"
mkdir -p "$OUT/ran" "$OUT/failed"
PASS=0; FAIL=0; SKIP=0; TOUT=0
TLIMIT=10
echo "================================================" | tee "$LOG"
echo "C25 FULL BUILD v2 — $(date)" | tee -a "$LOG"
echo "Timeout: ${TLIMIT}s per script" | tee -a "$LOG"
echo "================================================" | tee -a "$LOG"
run_it() {
  local S="$1" T="$2"
  [ -f "$S" ] || return
  echo "$S" | grep -qE "node_modules|site-packages|venv|nvm\.sh|flutter|thrift|pnpm|cassandra|pip/_vendor" && { ((SKIP++)); return; }
  echo "▶ [${T}] $(basename $S)" | tee -a "$LOG"
  timeout $TLIMIT $T "$S" >> "$OUT/ran/$(basename $S).out" 2>&1
  C=$?
  if [ $C -eq 0 ]; then echo "  ✓" | tee -a "$LOG"; ((PASS++))
  elif [ $C -eq 124 ]; then echo "  ⏱ TIMEOUT" | tee -a "$LOG"; ((TOUT++))
  else echo "  ✗ ($C)" | tee -a "$LOG"; ((FAIL++))
  fi
}
echo "[1/3] Confirmed executed..." | tee -a "$LOG"
while IFS= read -r line; do
  S=$(echo "$line" | awk '{print $2}')
  [ -z "$S" ] && continue
  echo "$S" | grep -q "\.py$" && run_it "$S" "python3" || run_it "$S" "bash"
done < "$TRUTH/CONFIRMED_EXECUTED.txt"
echo "Checkpoint: PASS=$PASS FAIL=$FAIL TOUT=$TOUT SKIP=$SKIP" | tee -a "$LOG"
echo "[2/3] All bash scripts..." | tee -a "$LOG"
grep "^FILE:" "$TRUTH/ALL_BASH_SCRIPTS.txt" 2>/dev/null | sed 's/^FILE: //' | while IFS= read -r S; do
  run_it "$S" "bash"
done
echo "Checkpoint: PASS=$PASS FAIL=$FAIL TOUT=$TOUT SKIP=$SKIP" | tee -a "$LOG"
echo "[3/3] All python scripts..." | tee -a "$LOG"
grep "^FILE:" "$TRUTH/ALL_PYTHON_SCRIPTS.txt" 2>/dev/null | sed 's/^FILE: //' | while IFS= read -r S; do
  run_it "$S" "python3"
done
echo "================================================" | tee -a "$LOG"
echo "COMPLETE — $(date)" | tee -a "$LOG"
echo "PASS    : $PASS" | tee -a "$LOG"
echo "FAIL    : $FAIL" | tee -a "$LOG"
echo "TIMEOUT : $TOUT" | tee -a "$LOG"
echo "SKIP    : $SKIP" | tee -a "$LOG"
echo "================================================" | tee -a "$LOG"
pkill -f 'node server.js' 2>/dev/null || true
sleep 1
cd ~/pathos && node server.js >> "$LOG" 2>&1 &
sleep 2
curl -s http://localhost:3100/status | tee -a "$LOG"
echo "DONE. tail -f $LOG"
