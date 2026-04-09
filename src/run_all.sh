#!/data/data/com.termux/files/usr/bin/bash
# C25 TERMUX FULL RUN — ALL SCRIPTS
# Reads Truth manifest, runs everything, tail -f the log live

set -eo pipefail
HOME="${HOME:-/data/data/com.termux/files/home}"
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

OUT="/sdcard/C25_FULL_REBUILD"
LOG="$OUT/BUILD.log"
TRUTH="/sdcard/TERMUX_TRUTH"

mkdir -p "$OUT/ran" "$OUT/failed" "$OUT/fixed"

echo "================================================" | tee -a "$LOG"
echo "C25 FULL BUILD — $(date)" | tee -a "$LOG"
echo "================================================" | tee -a "$LOG"

PASS=0
FAIL=0
SKIP=0

# ── RUN ALL CONFIRMED EXECUTED SCRIPTS ────────────────────────
echo "[1] Running all confirmed-executed scripts..." | tee -a "$LOG"

while IFS= read -r line; do
  # Extract script path from "  NNNx  /path/to/script"
  SCRIPT=$(echo "$line" | awk '{print $2}')
  [ -z "$SCRIPT" ] && continue
  [ ! -f "$SCRIPT" ] && continue

  # Skip vendor/library scripts
  echo "$SCRIPT" | grep -qE "node_modules|site-packages|venv|\.git|nvm\.sh|flutter|thrift|pnpm" && {
    ((SKIP++))
    continue
  }

  echo "▶ $SCRIPT" | tee -a "$LOG"

  if bash "$SCRIPT" >> "$OUT/ran/$(basename $SCRIPT).out" 2>&1; then
    echo "  ✓ PASS" | tee -a "$LOG"
    ((PASS++))
  else
    echo "  ✗ FAIL" | tee -a "$LOG"
    ((FAIL++))
    cp "$SCRIPT" "$OUT/failed/" 2>/dev/null || true
  fi

done < "$TRUTH/CONFIRMED_EXECUTED.txt"

# ── RUN ALL BASH SCRIPTS ───────────────────────────────────────
echo "" | tee -a "$LOG"
echo "[2] Running all bash scripts from ALL_BASH_SCRIPTS.txt..." | tee -a "$LOG"

grep "^FILE:" "$TRUTH/ALL_BASH_SCRIPTS.txt" 2>/dev/null | sed 's/^FILE: //' | while IFS= read -r SCRIPT; do
  [ -z "$SCRIPT" ] && continue
  [ ! -f "$SCRIPT" ] && continue
  echo "$SCRIPT" | grep -qE "node_modules|site-packages|venv|nvm\.sh|flutter|pnpm" && continue

  echo "▶ $SCRIPT" | tee -a "$LOG"
  bash "$SCRIPT" >> "$OUT/ran/$(basename $SCRIPT).out" 2>&1 && {
    echo "  ✓" | tee -a "$LOG"
    ((PASS++))
  } || {
    echo "  ✗" | tee -a "$LOG"
    ((FAIL++))
  }
done

# ── RUN ALL PYTHON SCRIPTS ────────────────────────────────────
echo "" | tee -a "$LOG"
echo "[3] Running all python scripts..." | tee -a "$LOG"

grep "^FILE:" "$TRUTH/ALL_PYTHON_SCRIPTS.txt" 2>/dev/null | sed 's/^FILE: //' | while IFS= read -r SCRIPT; do
  [ -z "$SCRIPT" ] && continue
  [ ! -f "$SCRIPT" ] && continue
  echo "$SCRIPT" | grep -qE "node_modules|site-packages|venv|pip/_vendor|cassandra|thrift" && continue

  echo "▶ $SCRIPT" | tee -a "$LOG"
  python3 "$SCRIPT" >> "$OUT/ran/$(basename $SCRIPT).out" 2>&1 && {
    echo "  ✓" | tee -a "$LOG"
    ((PASS++))
  } || {
    echo "  ✗" | tee -a "$LOG"
    ((FAIL++))
  }
done

# ── SUMMARY ───────────────────────────────────────────────────
echo "" | tee -a "$LOG"
echo "================================================" | tee -a "$LOG"
echo "BUILD COMPLETE — $(date)" | tee -a "$LOG"
echo "PASS : $PASS" | tee -a "$LOG"
echo "FAIL : $FAIL" | tee -a "$LOG"
echo "SKIP : $SKIP" | tee -a "$LOG"
echo "LOG  : $LOG" | tee -a "$LOG"
echo "================================================" | tee -a "$LOG"

# Boot Pathos
echo "Booting Pathos..." | tee -a "$LOG"
pkill -f 'node server.js' 2>/dev/null || true
sleep 1
cd ~/pathos && node server.js &
sleep 2
curl -s http://localhost:3100/status | tee -a "$LOG"
echo ""
echo "DONE. tail -f $LOG to watch."
