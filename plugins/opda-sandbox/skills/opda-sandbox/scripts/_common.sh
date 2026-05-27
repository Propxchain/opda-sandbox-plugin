#!/usr/bin/env bash
# Shared config + token minting. Source this from the other scripts.
COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$COMMON_DIR/.." && pwd)"

# Config search order (first found wins). Your real config lives OUTSIDE this
# skill folder so it survives plugin updates (the plugin dir is replaced on update):
#   1. $OPDA_SANDBOX_CONFIG          (explicit override)
#   2. ~/.opda-sandbox/config.env    (recommended — sits with your certs)
#   3. <skill>/config.local.env      (if you cloned the skill directly)
CONFIG=
for c in "$OPDA_SANDBOX_CONFIG" "$HOME/.opda-sandbox/config.env" "$SKILL_DIR/config.local.env"; do
  if [ -n "$c" ] && [ -f "$c" ]; then CONFIG="$c"; break; fi
done
if [ -z "$CONFIG" ]; then
  echo "WARNING: no config found. Create your config from the template:" >&2
  echo "  mkdir -p ~/.opda-sandbox && cp \"$SKILL_DIR/config.example.env\" ~/.opda-sandbox/config.env" >&2
  echo "  ...then edit ~/.opda-sandbox/config.env" >&2
  CONFIG="$SKILL_DIR/config.example.env"
fi
# shellcheck disable=SC1091
source "$CONFIG"
export OPDA_ACTIVE_CONFIG="$CONFIG"

: "${OPDA_CERT_DIR:?set OPDA_CERT_DIR in your config}"
TC="$OPDA_CERT_DIR/$TRANSPORT_CERT"
TK="$OPDA_CERT_DIR/$TRANSPORT_KEY"

# mint_token <scope> -> prints access_token (empty on failure)
# -k skips server-cert verification (fine for the sandbox CA).
mint_token() {
  curl -s -k --max-time 15 --cert "$TC" --key "$TK" \
    -X POST "$TOKEN_URL" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "client_id=$CLIENT_ID" \
    --data-urlencode "scope=$1" \
    | python3 -c 'import json,sys;print(json.load(sys.stdin).get("access_token",""))'
}
