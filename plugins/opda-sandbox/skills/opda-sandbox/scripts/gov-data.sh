#!/usr/bin/env bash
# gov-data.sh — consume the OPDA government-data endpoints (smartpropdata).
#
# These cost people hours because of TWO non-obvious things, both handled here:
#   1. The URL shape differs per endpoint. Calling the wrong shape never matches a
#      gateway route and you get a misleading "403 IncompleteSignatureException"
#      (an AWS API Gateway catch-all) — it is NOT a signature/server problem.
#   2. The token scope is "land-registry" for ALL of them (not coalfield-data /
#      government-data). Wrong scope -> wrong token aud -> 401 missing_authorization.
#   Plus: these endpoints require private_key_jwt auth (set SIGNING_KEY/SIGNING_KID).
#
# Each returns {data, provenance{alg:RS256, kid, signature, signedAt}} — signed PDTF
# provenance you can verify.
#
# Usage:
#   gov-data.sh coalfield <uprn>              GET  /v1/coalfield/{uprn}
#   gov-data.sh validate  <uprn>              GET  /v1/uprn/validate/{uprn}
#   gov-data.sh places    "<address|postcode>"  GET /v1/places/find?query=...
#   gov-data.sh register  <titleNumber> ['<titleKnownOfficialCopy-json>']
#                                             POST /opda/official-copies/v1/register-extract
#
# Override the host if OPDA gives you a different one:  GOV_DATA_BASE=... gov-data.sh ...
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
BASE="${GOV_DATA_BASE:-https://dev.api.smartpropdata.org.uk}"
SCOPE="${GOV_DATA_SCOPE:-land-registry}"
CMD="${1:?usage: gov-data.sh <coalfield|validate|places|register> <arg> [extra]}"
ARG="${2:-}"

T=$(mint_token "$SCOPE")
[ -z "$T" ] && { echo "no token for scope=$SCOPE (check SIGNING_KEY/SIGNING_KID, or throttled — retry)" >&2; exit 1; }
H=$(mktemp); B=$(mktemp); trap 'rm -f "$H" "$B"' EXIT
COMMON=(-s -k --max-time 35 -D "$H" -o "$B" --cert "$TC" --key "$TK" -H "Authorization: Bearer $T")

case "$CMD" in
  coalfield) curl "${COMMON[@]}" "$BASE/v1/coalfield/${ARG:?need uprn}" ;;
  validate)  curl "${COMMON[@]}" "$BASE/v1/uprn/validate/${ARG:?need uprn}" ;;
  places)    curl "${COMMON[@]}" -G --data-urlencode "query=${ARG:?need address/postcode}" "$BASE/v1/places/find" ;;
  register)
    MID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "msg-$RANDOM")
    TKOC="${3:-}"
    BODY="{\"messageId\":\"$MID\",\"titleNumber\":\"${ARG:?need titleNumber}\""
    [ -n "$TKOC" ] && BODY="$BODY,\"titleKnownOfficialCopy\":$TKOC"
    BODY="$BODY}"
    curl "${COMMON[@]}" -H "Content-Type: application/json" -X POST -d "$BODY" \
      "$BASE/opda/official-copies/v1/register-extract" ;;
  *) echo "unknown command: $CMD" >&2; exit 2 ;;
esac

echo "[$CMD] scope=$SCOPE  $(awk '/^HTTP/{print $1,$2}' "$H")  $(grep -i 'x-fapi-interaction-id' "$H" | tr -d '\r')"
python3 - "$B" <<'PY'
import json,sys
try:
    d=json.load(open(sys.argv[1]))
except Exception:
    print(open(sys.argv[1]).read()[:600]); sys.exit()
prov=d.pop("provenance",None)
print("data:", json.dumps(d.get("data",d), indent=2)[:2000])
if prov:
    print("provenance: alg=%s kid=%s signedAt=%s sig=%s…(%d chars)" % (
        prov.get("alg"), (prov.get("kid") or "").strip()[:16], prov.get("signedAt"),
        (prov.get("signature") or "")[:24], len(prov.get("signature") or "")))
PY
