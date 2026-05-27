#!/usr/bin/env bash
# Consume any sandbox endpoint and surface its provenance.
# Usage: consume.sh <scope> <METHOD> <url> [json-body]
#   e.g. consume.sh property-pack GET  https://.../provenance-map/<uprn>
#        consume.sh property-pack POST https://.../property-pack/uprn '{"uprn":"..."}'
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
SCOPE=${1:?need scope}; METHOD=${2:?need method}; URL=${3:?need url}; BODY=${4:-}

TOKEN=$(mint_token "$SCOPE")
[ -z "$TOKEN" ] && { echo "no token for scope=$SCOPE — run check-setup.sh" >&2; exit 1; }
echo "[consume] scope=$SCOPE token=${TOKEN:0:16}..."

ARGS=(-s -k --max-time 30 -D /tmp/opda_hdrs.txt --cert "$TC" --key "$TK"
      -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -X "$METHOD" "$URL")
[ -n "$BODY" ] && ARGS+=(-d "$BODY")
RESP=$(curl "${ARGS[@]}")

echo "--- status / provenance headers ---"
grep -iE "^(HTTP/|x-jws-signature|x-fapi|content-type)" /tmp/opda_hdrs.txt | sed "s/^/  /"
echo "--- body (first 6KB) ---"
echo "$RESP" | python3 -m json.tool 2>/dev/null | head -c 6000 || echo "$RESP" | head -c 2000
echo
echo "--- provenance summary ---"
echo "$RESP" | python3 "$SKILL_DIR/scripts/lib_fmt.py" provenance 2>/dev/null
echo "$RESP" | python3 "$SKILL_DIR/scripts/lib_fmt.py" claims 2>/dev/null
