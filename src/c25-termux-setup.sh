#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  C25 TERMUX HOME SETUP
#  Cygel White / Kre8tive Konceptz LTD / FacePrintPay
#  Constellation25 Sovereign AI OS — Repo Bootstrap
# ============================================================
# Usage:
#   chmod +x c25-termux-setup.sh
#   ./c25-termux-setup.sh YOUR_GITHUB_USERNAME
# ============================================================

set -e

# ── CONFIG ───────────────────────────────────────────────────
GITHUB_USER="${1:-FacePrintPay}"
HOME_DIR="/data/data/com.termux/files/home"
REPOS_DIR="$HOME_DIR/github-repos"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

# Repos to scaffold: name:org
REPOS=(
  "constellation25:Constillation25"
  "videocourts:VideoCourts"
  "digital-dollar:FacePrintPay"
  "c25-monorepo:Constillation25"
  "sovereign-gtp:FacePrintPay"
  "aimetaverse:AiMetaverse"
)

# ── COLORS ───────────────────────────────────────────────────
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

log()  { echo -e "${CYAN}[C25]${RESET} $1"; }
ok()   { echo -e "${GREEN}[OK]${RESET}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
fail() { echo -e "${RED}[ERR]${RESET}  $1"; }

# ── PREFLIGHT ────────────────────────────────────────────────
log "Verifying Termux environment..."

if [ ! -d "$HOME_DIR" ]; then
  fail "Termux HOME not found at $HOME_DIR — aborting."
  exit 1
fi

# Ensure git is installed
if ! command -v git &>/dev/null; then
  warn "git not found — installing..."
  pkg install git -y
fi

# Ensure gh CLI or curl for API calls (gh preferred)
if ! command -v gh &>/dev/null; then
  warn "GitHub CLI (gh) not found. Remotes will use HTTPS. Install with: pkg install gh"
fi

ok "Preflight passed. HOME=$HOME_DIR"

# ── CREATE REPOS DIR ─────────────────────────────────────────
mkdir -p "$REPOS_DIR"
log "Repos base dir: $REPOS_DIR"

# ── SCAFFOLD EACH REPO ───────────────────────────────────────
for entry in "${REPOS[@]}"; do
  REPO_NAME="${entry%%:*}"
  ORG="${entry##*:}"
  REPO_DIR="$REPOS_DIR/$REPO_NAME"
  REMOTE_URL="https://github.com/${ORG}/${REPO_NAME}.git"

  echo ""
  log "─── Scaffolding: $REPO_NAME (org: $ORG) ───"

  # Init or skip if already a git repo
  if [ -d "$REPO_DIR/.git" ]; then
    warn "$REPO_NAME already initialised — skipping init."
  else
    mkdir -p "$REPO_DIR"
    cd "$REPO_DIR"
    git init
    git checkout -b main 2>/dev/null || true
    ok "git init done → $REPO_DIR"
  fi

  cd "$REPO_DIR"

  # Set remote (replace if wrong)
  if git remote get-url origin &>/dev/null; then
    CURRENT=$(git remote get-url origin)
    if [ "$CURRENT" != "$REMOTE_URL" ]; then
      git remote set-url origin "$REMOTE_URL"
      warn "Remote updated: $REMOTE_URL"
    else
      ok "Remote already correct."
    fi
  else
    git remote add origin "$REMOTE_URL"
    ok "Remote set: $REMOTE_URL"
  fi

  # Create README if repo is empty (prevents push refspec error)
  if [ ! -f README.md ]; then
    cat > README.md << EOF
# ${REPO_NAME}
> Part of the Constellation25 Sovereign AI OS Ecosystem
> Kre8tive Konceptz LTD | FacePrintPay | @MrGGTP

Initialised: ${TIMESTAMP}
Org: https://github.com/${ORG}
EOF
    git add README.md
    git commit -m "🚀 C25 init: ${REPO_NAME} — ${TIMESTAMP}"
    ok "Initial commit created."
  else
    warn "README.md already exists — no commit needed."
  fi

  # Configure git user if not set
  if [ -z "$(git config user.email)" ]; then
    git config user.email "kre8tivekonceptz@gmail.com"
    git config user.name "Cygel White"
    ok "Git user configured."
  fi

done

# ── SESSION RESTORE MARKER ───────────────────────────────────
RESTORE_FILE="$HOME_DIR/.c25-session-restore"
cat > "$RESTORE_FILE" << EOF
# C25 SESSION RESTORE POINT
# Generated: ${TIMESTAMP}
# GitHub User: ${GITHUB_USER}
# Repos Dir: ${REPOS_DIR}

REPOS_INITIALIZED=(
$(for entry in "${REPOS[@]}"; do
  REPO_NAME="${entry%%:*}"
  ORG="${entry##*:}"
  echo "  \"${REPO_NAME}\" # org: ${ORG} → https://github.com/${ORG}/${REPO_NAME}"
done)
)

# To push all repos after GitHub remote repos are created:
# cd ~/github-repos/<repo> && git push -u origin main
EOF

ok "Session restore marker saved → $RESTORE_FILE"

# ── SUMMARY ──────────────────────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════${RESET}"
echo -e "${GREEN}  C25 TERMUX SETUP COMPLETE${RESET}"
echo -e "${GREEN}════════════════════════════════════════${RESET}"
echo ""
echo "  Repos scaffolded in: $REPOS_DIR"
echo ""
for entry in "${REPOS[@]}"; do
  REPO_NAME="${entry%%:*}"
  ORG="${entry##*:}"
  echo -e "  ${CYAN}▸${RESET} $REPO_NAME  →  github.com/${ORG}/${REPO_NAME}"
done
echo ""
echo -e "${YELLOW}NEXT STEP:${RESET} Create the repos on GitHub first, then run:"
echo ""
echo "  cd ~/github-repos/<repo-name>"
echo "  git push -u origin main"
echo ""
echo -e "${YELLOW}OR bulk-push all at once:${RESET}"
echo ""
cat << 'PUSHALL'
  for d in ~/github-repos/*/; do
    echo "→ Pushing $(basename $d)..."
    cd "$d" && git push -u origin main 2>&1 || echo "  [SKIP] push failed — check remote exists"
    cd -
  done
PUSHALL
echo ""
echo -e "${CYAN}Session restore file:${RESET} ~/.c25-session-restore"
echo ""
