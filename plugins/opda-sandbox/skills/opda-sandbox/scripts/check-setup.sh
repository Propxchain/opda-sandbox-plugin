#!/usr/bin/env bash
# Onboarding self-test: verifies certs + config, then mints a test token.
# Run this FIRST. It tells you exactly what's wrong if you're not connected yet.
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
FAIL=

echo "OPDA sandbox setup check"
echo "  config   : ${OPDA_ACTIVE_CONFIG:-<none>}"
echo "  cert dir : $OPDA_CERT_DIR"

if [ -f "$TC" ]; then echo "  [ok] transport cert: $TC"; else echo "  [X]  MISSING transport cert: $TC"; FAIL=1; fi
if [ -f "$TK" ]; then echo "  [ok] transport key : $TK"; else echo "  [X]  MISSING transport key: $TK"; FAIL=1; fi

case "$CLIENT_ID" in
  *REPLACE*)
    echo "  [X]  CLIENT_ID is still a placeholder — set it in your config (~/.opda-sandbox/config.env)"; FAIL=1 ;;
  https://rp.directory.*/openid_relying_party/*)
    echo "  [ok] client_id looks like a full RP URL" ;;
  *)
    echo "  [X]  CLIENT_ID must be the FULL RP URL, not the bare UUID (causes 401 invalid_client)"; FAIL=1 ;;
esac

if [ -n "$FAIL" ]; then
  echo
  echo "Fix the items marked [X] above, then re-run. See ONBOARDING.md."
  exit 1
fi

echo "  ...minting a test token (scope=$DEFAULT_SCOPE)"
T=$(mint_token "$DEFAULT_SCOPE")
if [ -n "$T" ]; then
  echo "  [ok] token minted (${T:0:16}...) — you're connected!"
  echo
  echo "Next: bash scripts/directory.sh endpoints"
else
  echo "  [X]  token mint FAILED — check cert/key paths and that your client_id + cert are active in the directory."
  exit 1
fi
