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

# Explicit label for interactive/trigger-driven pushes.
exec "$SCRIPT" "TRIGGER-DRIVEN push"
