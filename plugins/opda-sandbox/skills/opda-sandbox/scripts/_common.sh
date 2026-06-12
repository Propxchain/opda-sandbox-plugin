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
# Optional signing key for private_key_jwt (only some endpoints require it — see SKILL.md).
SK="$OPDA_CERT_DIR/${SIGNING_KEY:-__none__}"

_b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

# build_assertion -> a signed RS256 client-assertion JWT for private_key_jwt.
# iss/sub = client_id, aud = token URL, jti + short exp. Needs SIGNING_KEY + SIGNING_KID.
build_assertion() {
  local now hdr pay sig jti
  now=$(date +%s)
  jti=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "$now$RANDOM")
  hdr=$(printf '{"alg":"RS256","typ":"JWT","kid":"%s"}' "$SIGNING_KID" | _b64url)
  pay=$(printf '{"iss":"%s","sub":"%s","aud":"%s","jti":"%s","iat":%d,"exp":%d}' \
    "$CLIENT_ID" "$CLIENT_ID" "$TOKEN_URL" "$jti" "$now" $((now+300)) | _b64url)
  sig=$(printf '%s.%s' "$hdr" "$pay" | openssl dgst -sha256 -sign "$SK" -binary | _b64url)
  printf '%s.%s.%s' "$hdr" "$pay" "$sig"
}

_extract_token() { python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("access_token",""))
except Exception: print("")'; }

# mint_token <scope> -> prints access_token (empty on failure).
# Dual-mode: if a SIGNING_KEY is configured it tries private_key_jwt first (required by
# some endpoints — e.g. OPDA government-data), then falls back to tls_client_auth so it
# works whichever token_endpoint_auth_method your app is registered with.
mint_token() {
  local tok
  if [ -f "$SK" ] && [ -n "$SIGNING_KID" ]; then
    tok=$(curl -s -k --max-time 15 --cert "$TC" --key "$TK" -X POST "$TOKEN_URL" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "grant_type=client_credentials" \
      --data-urlencode "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" \
      --data-urlencode "client_assertion=$(build_assertion)" \
      --data-urlencode "scope=$1" | _extract_token)
    [ -n "$tok" ] && { echo "$tok"; return 0; }
  fi
  curl -s -k --max-time 15 --cert "$TC" --key "$TK" -X POST "$TOKEN_URL" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "client_id=$CLIENT_ID" \
    --data-urlencode "scope=$1" | _extract_token
}
