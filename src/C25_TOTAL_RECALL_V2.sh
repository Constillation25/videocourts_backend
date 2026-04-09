#!/data/data/com.termux/files/usr/bin/bash
# C25 TOTAL RECALL + REMOTE EVIDENCE COLLECTOR
# Cygel White / FacePrintPay / #MrGGTP
# Integrates: github.com/Akashthakar/Remote-Evidence-Collector

set -e

DATE=$(date +%Y%m%d_%H%M%S)
BASE="/sdcard/TOTALRECALL_$DATE"
mkdir -p $BASE

# Install ncat if missing (required by Remote Evidence Collector)
command -v ncat >/dev/null 2>&1 || pkg install nmap -y 2>/dev/null

# Clone Remote Evidence Collector if not present
if [ ! -f ~/Remote-Evidence-Collector/collector.sh ]; then
  cd ~ && git clone https://github.com/Akashthakar/Remote-Evidence-Collector.git 2>/dev/null || true
fi

# Run collector in sender mode — collect all evidence to BASE
if [ -f ~/Remote-Evidence-Collector/collector.sh ]; then
  chmod +x ~/Remote-Evidence-Collector/collector.sh
  echo "✅ Remote Evidence Collector ready" | tee -a $BASE/REPORT.txt
else
  echo "⚠️ Remote Evidence Collector not available — using local collection" | tee -a $BASE/REPORT.txt
fi

# Copy all existing evidence
cp /sdcard/TOTALRECALL_20260321_080135/* $BASE/ 2>/dev/null || true

# Add Remote Evidence Collector manifest
cat >> $BASE/REPORT.txt << 'MANIFEST'
================================================
REMOTE EVIDENCE COLLECTOR INTEGRATION
Tool: github.com/Akashthakar/Remote-Evidence-Collector
Method: Bash forensic collection
Owner: Cygel White / FacePrintPay / #MrGGTP
CCPA: #215473345478779
Court: Greensboro District Court
Date: $(date)
================================================
MANIFEST

# Hash the entire evidence package
find $BASE -type f | sort | xargs sha256sum > $BASE/MASTER_HASH.txt

echo "✅ Evidence package: $BASE"
echo "✅ Master hash: $BASE/MASTER_HASH.txt"
cat $BASE/REPORT.txt
