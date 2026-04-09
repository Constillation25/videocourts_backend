#!/data/data/com.termux/files/usr/bin/bash
# C25 TOTAL RECALL FORENSIC ENGINE v2.0
# Cygel White / FacePrintPay / #MrGGTP
# Integrates Remote-Evidence-Collector methodology
# Prior Art: 2023-03-21

set -e

DATE=$(date +%Y%m%d_%H%M%S)
BASE="/sdcard/TOTALRECALL_$DATE"
mkdir -p $BASE

echo "🌌 C25 TOTAL RECALL FORENSIC ENGINE" | tee $BASE/REPORT.txt
echo "Owner: Cygel White / FacePrintPay / #MrGGTP" | tee -a $BASE/REPORT.txt
echo "Date: $(date)" | tee -a $BASE/REPORT.txt
echo "Prior Art: 2023-03-21" | tee -a $BASE/REPORT.txt
echo "CCPA Complaint: #215473345478779" | tee -a $BASE/REPORT.txt
echo "================================================" | tee -a $BASE/REPORT.txt

# PHASE 1: SYSTEM FINGERPRINT
echo "" | tee -a $BASE/REPORT.txt
echo "PHASE 1: SYSTEM FINGERPRINT" | tee -a $BASE/REPORT.txt
uname -a >> $BASE/REPORT.txt
whoami >> $BASE/REPORT.txt
date >> $BASE/REPORT.txt
uptime >> $BASE/REPORT.txt

# PHASE 2: COMPLETE FILE INVENTORY
echo "" | tee -a $BASE/REPORT.txt
echo "PHASE 2: FILE INVENTORY" | tee -a $BASE/REPORT.txt
find ~ -type f 2>/dev/null | grep -v node_modules | grep -v ".git" | sort > $BASE/ALL_FILES.txt
wc -l $BASE/ALL_FILES.txt | tee -a $BASE/REPORT.txt

# PHASE 3: ALL SCRIPTS INVENTORY + SYNTAX CHECK
echo "" | tee -a $BASE/REPORT.txt
echo "PHASE 3: SCRIPT AUDIT" | tee -a $BASE/REPORT.txt
find ~ -name "*.sh" 2>/dev/null | grep -v node_modules | grep -v ".git" > $BASE/ALL_SCRIPTS.txt
TOTAL=$(wc -l < $BASE/ALL_SCRIPTS.txt)
echo "Total scripts: $TOTAL" | tee -a $BASE/REPORT.txt

> $BASE/SYNTAX_CLEAN.txt
> $BASE/SYNTAX_FAILED.txt

while read SCRIPT; do
  if bash -n "$SCRIPT" 2>/dev/null; then
    echo "✅ $SCRIPT" >> $BASE/SYNTAX_CLEAN.txt
  else
    echo "❌ $SCRIPT" >> $BASE/SYNTAX_FAILED.txt
  fi
done < $BASE/ALL_SCRIPTS.txt

echo "Syntax clean: $(wc -l < $BASE/SYNTAX_CLEAN.txt)" | tee -a $BASE/REPORT.txt
echo "Syntax failed: $(wc -l < $BASE/SYNTAX_FAILED.txt)" | tee -a $BASE/REPORT.txt

# PHASE 4: HASH ALL SCRIPTS (evidence integrity)
echo "" | tee -a $BASE/REPORT.txt
echo "PHASE 4: EVIDENCE HASHING" | tee -a $BASE/REPORT.txt
while read SCRIPT; do
  sha256sum "$SCRIPT" 2>/dev/null >> $BASE/SCRIPT_HASHES.txt
done < $BASE/ALL_SCRIPTS.txt
echo "Hashed: $(wc -l < $BASE/SCRIPT_HASHES.txt) files" | tee -a $BASE/REPORT.txt

# PHASE 5: GIT HISTORY (prior art documentation)
echo "" | tee -a $BASE/REPORT.txt
echo "PHASE 5: GIT COMMIT HISTORY" | tee -a $BASE/REPORT.txt
find ~ -name ".git" -type d 2>/dev/null | grep -v node_modules | while read GITDIR; do
  REPO=$(dirname $GITDIR)
  echo "--- REPO: $REPO" >> $BASE/GIT_HISTORY.txt
  git -C "$REPO" log --oneline 2>/dev/null | head -20 >> $BASE/GIT_HISTORY.txt
done
echo "Git repos documented" | tee -a $BASE/REPORT.txt

# PHASE 6: EXISTING SDCARD EVIDENCE
echo "" | tee -a $BASE/REPORT.txt
echo "PHASE 6: EXISTING EVIDENCE FILES" | tee -a $BASE/REPORT.txt
ls /sdcard/*.txt 2>/dev/null >> $BASE/REPORT.txt
cp /sdcard/TERMUX_COMPLETE_HISTORY.txt $BASE/ 2>/dev/null || true
cp /sdcard/C25_BUILD_RECORD.txt $BASE/ 2>/dev/null || true
cp /sdcard/C25_ALL_SCRIPTS_NUMBERED.txt $BASE/ 2>/dev/null || true
cp /sdcard/CYGEL_WHITE_FULL_COMMIT_HISTORY_20260124.txt $BASE/ 2>/dev/null || true
cp /sdcard/evidence.txt $BASE/ 2>/dev/null || true

# PHASE 7: NETWORK STATE
echo "" | tee -a $BASE/REPORT.txt
echo "PHASE 7: NETWORK STATE" | tee -a $BASE/REPORT.txt
netstat -tlnp 2>/dev/null >> $BASE/NETWORK.txt || ss -tlnp >> $BASE/NETWORK.txt 2>/dev/null || true

# PHASE 8: RUN ALL SCRIPTS + LOG RESULTS
echo "" | tee -a $BASE/REPORT.txt
echo "PHASE 8: FULL SCRIPT EXECUTION" | tee -a $BASE/REPORT.txt
> $BASE/EXECUTION_CLEAN.txt
> $BASE/EXECUTION_FAILED.txt

while read SCRIPT; do
  if timeout 30 bash "$SCRIPT" >> $BASE/EXECUTION_OUTPUT.log 2>&1; then
    echo "✅ $SCRIPT" >> $BASE/EXECUTION_CLEAN.txt
  else
    echo "❌ $SCRIPT" >> $BASE/EXECUTION_FAILED.txt
  fi
done < $BASE/SYNTAX_CLEAN.txt

echo "Executed clean: $(wc -l < $BASE/EXECUTION_CLEAN.txt)" | tee -a $BASE/REPORT.txt
echo "Executed failed: $(wc -l < $BASE/EXECUTION_FAILED.txt)" | tee -a $BASE/REPORT.txt

# PHASE 9: MASTER HASH OF ENTIRE EVIDENCE PACKAGE
echo "" | tee -a $BASE/REPORT.txt
echo "PHASE 9: MASTER EVIDENCE HASH" | tee -a $BASE/REPORT.txt
find $BASE -type f | sort | xargs sha256sum 2>/dev/null > $BASE/MASTER_HASH.txt
echo "Master hash generated" | tee -a $BASE/REPORT.txt

# FINAL SUMMARY
echo "" | tee -a $BASE/REPORT.txt
echo "================================================" | tee -a $BASE/REPORT.txt
echo "TOTAL RECALL COMPLETE" | tee -a $BASE/REPORT.txt
echo "Evidence package: $BASE" | tee -a $BASE/REPORT.txt
echo "Owner: Cygel White / FacePrintPay / #MrGGTP" | tee -a $BASE/REPORT.txt
echo "Prior Art: 2023-03-21" | tee -a $BASE/REPORT.txt
echo "CCPA: #215473345478779" | tee -a $BASE/REPORT.txt
echo "================================================" | tee -a $BASE/REPORT.txt

cat $BASE/REPORT.txt
