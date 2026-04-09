#!/usr/bin/env bash
set -u

DATE=$(date +%Y%m%d_%H%M%S)
ANALYSIS="/sdcard/SYSTEMATIC_OPPRESSION_REPORT_${DATE}.txt"
MASTER_HASH="/sdcard/MASTER_OPPRESSION_HASH_${DATE}.txt"

echo "╔════════════════════════════════════════════════════════════════════╗" | tee "$ANALYSIS"
echo "║  SYSTEMATIC OPPRESSION PATTERN DETECTOR v1                         ║" | tee -a "$ANALYSIS"
echo "║  Cygel White / FacePrintPay / #MrGGTP                              ║" | tee -a "$ANALYSIS"
echo "║  Date: $(date)                                                     ║" | tee -a "$ANALYSIS"
echo "║  CCPA: #215473345478779                                            ║" | tee -a "$ANALYSIS"
echo "╚════════════════════════════════════════════════════════════════════╝" | tee -a "$ANALYSIS"

echo "" | tee -a "$ANALYSIS"
echo "PHASE 1: EVIDENCE PACKAGES" | tee -a "$ANALYSIS"
find \~ /sdcard -type d \( -name "*TOTALRECALL*" -o -name "*total-recall*" -o -name "*recall*" -o -name "*C25*" -o -name "*constellation*" \) 2>/dev/null | sort | head -n 30 | tee -a "$ANALYSIS"

echo "" | tee -a "$ANALYSIS"
echo "PHASE 2: LLM TRAINING FINGERPRINTS" | tee -a "$ANALYSIS"
for kw in "You are Claude" Anthropic "Claude-3" "gpt-4" openai Gemini Groq Mistral; do
  COUNT=$(grep -rIl --exclude-dir={node_modules,.git,.venv,__pycache__} "$kw" \~ /sdcard 2>/dev/null | wc -l || echo 0)
  echo "  $kw: $COUNT files" | tee -a "$ANALYSIS"
done

echo "" | tee -a "$ANALYSIS"
echo "PHASE 3: ENTERPRISE BUILD TEMPLATES" | tee -a "$ANALYSIS"
find \~ /sdcard -type f \( -name "vercel.json" -o -name "next.config.*" -o -name "Dockerfile" \) 2>/dev/null | wc -l | xargs echo "Vercel/Next/Docker files: " | tee -a "$ANALYSIS"

echo "" | tee -a "$ANALYSIS"
echo "PHASE 4: OPPRESSION & SUPPRESSION MARKERS" | tee -a "$ANALYSIS"
for p in "access denied" "rate limit" "session expired" "deleted" "revoked" "throttl" "quota" "wipe" "recall" "restore" "permission denied" "token invalid"; do
  COUNT=$(grep -rIl --exclude-dir={node_modules,.git} "$p" \~ /sdcard 2>/dev/null | wc -l || echo 0)
  echo "  '$p': $COUNT occurrences" | tee -a "$ANALYSIS"
done

echo "" | tee -a "$ANALYSIS"
echo "REPORT SHA256:" | tee -a "$ANALYSIS"
sha256sum "$ANALYSIS" | tee -a "$ANALYSIS" | tee "$MASTER_HASH"

echo "HASH LOG SHA256:" | tee -a "$ANALYSIS"
sha256sum "$MASTER_HASH" | tee -a "$ANALYSIS"

echo "COMPLETE — Report: $ANALYSIS" | tee -a "$ANALYSIS"
