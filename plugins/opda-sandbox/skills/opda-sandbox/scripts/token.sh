#!/usr/bin/env bash
# Mint a scoped access token. Usage: token.sh [scope]   (default from config)
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
SCOPE="${1:-$DEFAULT_SCOPE}"
T=$(mint_token "$SCOPE")
[ -z "$T" ] && { echo "FAILED to mint token for scope=$SCOPE — run check-setup.sh" >&2; exit 1; }
echo "$T"
