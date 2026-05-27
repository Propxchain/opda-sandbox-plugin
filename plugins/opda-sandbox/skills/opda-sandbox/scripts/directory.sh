#!/usr/bin/env bash
# Query the OPDA / Raidiam directory.
#   directory.sh             -> list all onboarded organisations
#   directory.sh endpoints   -> sweep ALL orgs for live published endpoints
#   directory.sh <orgId>     -> list one org's published endpoints
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
TOKEN=$(mint_token "$DEFAULT_SCOPE")
[ -z "$TOKEN" ] && { echo "no directory token — run check-setup.sh" >&2; exit 1; }
GET() { curl -s -k --max-time 20 --cert "$TC" --key "$TK" -H "Authorization: Bearer $TOKEN" "$1"; }

case "$1" in
  ""|orgs)
    GET "$DIR_API/organisations" | python3 "$SKILL_DIR/scripts/lib_fmt.py" orgs ;;
  endpoints)
    GET "$DIR_API/organisations" \
      | python3 -c 'import json,sys;[print(o["OrganisationId"]+"|"+o.get("OrganisationName","")) for o in json.load(sys.stdin).get("content",[])]' \
      | while IFS="|" read -r OID NAME; do
          OUT=$(GET "$DIR_API/organisations/$OID/authorisationservers" | python3 "$SKILL_DIR/scripts/lib_fmt.py" endpoints 2>/dev/null)
          [ -n "$(echo "$OUT" | tr -d '[:space:]')" ] && ! echo "$OUT" | grep -q "no published" && { echo "### $NAME"; echo "$OUT"; }
        done ;;
  *)
    GET "$DIR_API/organisations/$1/authorisationservers" | python3 "$SKILL_DIR/scripts/lib_fmt.py" endpoints ;;
esac
