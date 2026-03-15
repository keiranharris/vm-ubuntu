#!/usr/bin/env bash
set -euo pipefail

SCRIPT="/home/keiran/_K/_CODE/k-git-push.sh"

if [[ ! -f "$SCRIPT" ]]; then
  echo "ERROR: script not found: $SCRIPT" >&2
  exit 2
fi

if [[ ! -x "$SCRIPT" ]]; then
  echo "ERROR: script is not executable: $SCRIPT" >&2
  exit 3
fi

# Optional short reason from CLI args (max 10 words for inbox readability).
RAW_REASON="${*:-general config updates}"
SHORT_REASON="$(echo "$RAW_REASON" | awk '{for(i=1;i<=NF && i<=10;i++) printf "%s%s",$i,(i<10&&i<NF?" ":"")}')"
LABEL="TRIGGER-DRIVEN (${SHORT_REASON})"

exec "$SCRIPT" "$LABEL"
