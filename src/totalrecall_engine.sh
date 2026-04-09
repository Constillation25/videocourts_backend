#!/data/data/com.termux/files/usr/bin/bash
# TotalRecall™ Forensic Engine v1.0
# SHA256 hashing + blockchain-style manifest for evidence chain-of-custody

EVIDENCE_VAULT="${EVIDENCE_VAULT:-$HOME/TotalRecall/evidence_vault}"
MANIFEST="$EVIDENCE_VAULT/blockchain_manifest.txt"

mkdir -p "$EVIDENCE_VAULT"
[ ! -f "$MANIFEST" ] && echo "# TotalRecall™ Manifest\n# Genesis: $(date -Iseconds)" > "$MANIFEST"

ingest() {
  local file="$1" case_id="${2:-unknown}" desc="${3:-Evidence}"
  [ ! -f "$file" ] && { echo "❌ File not found: $file"; return 1; }
  
  local hash=$(sha256sum "$file" | cut -d' ' -f1)
  local ev_id="EVD_${case_id}_$(date +%s)_${hash:0:8}"
  local vault="$EVIDENCE_VAULT/$case_id"
  mkdir -p "$vault" && cp "$file" "$vault/"
  
  local chain=$(echo "$hash$(tail -1 "$MANIFEST")" | sha256sum | cut -d' ' -f1)
  echo -e "[EVIDENCE]\nID: $ev_id\nCase: $case_id\nHash: $hash\nChain: $chain\nPath: $vault\n---" >> "$MANIFEST"
  echo "✅ Ingested: $ev_id"
}

report() {
  local case_id="$1"
  echo "════ FORENSIC REPORT: $case_id ════"
  echo "Generated: $(date -Iseconds)"
  grep -A 6 "Case: $case_id" "$MANIFEST" || echo "No evidence found."
}

case "${1:-help}" in
  ingest) ingest "$2" "$3" "$4" ;;
  report) report "$2" ;;
  *) echo "Usage: $0 ingest <file> [case_id] [desc] | report <case_id>" ;;
esac
