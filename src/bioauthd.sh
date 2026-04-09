#!/data/data/com.termux/files/usr/bin/bash
SOCK="$HOME/.bioauth.sock"
SECRET="$HOME/.bioauth.key"

# Generate persistent secret if absent
[[ -f "$SECRET" ]] || head -c 64 /dev/urandom | sha256sum | cut -d' ' -f1 > "$SECRET"
chmod 600 "$SECRET"

# Clean socket state
rm -f "$SOCK"
mkfifo "$SOCK"

echo "[bioauthd] Running on $SOCK"
echo "[bioauthd] Secret anchor: $(head -c 8 $SECRET)"

while true; do
  read -r REQUEST < "$SOCK" || continue
  TS=$(date +%s)
  SIG=$(printf "%s:%s:%s" "$REQUEST" "$TS" "$(cat $SECRET)" | sha256sum | cut -d' ' -f1)
  printf "OK %s %s\n" "$TS" "$SIG" > "$SOCK"
  echo "[bioauthd] Authenticated: ${REQUEST:0:40}... → $SIG"
done
