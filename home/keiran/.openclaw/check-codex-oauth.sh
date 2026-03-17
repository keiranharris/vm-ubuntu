#!/usr/bin/env bash
set -euo pipefail

PATH="/home/keiran/.npm-global/bin:/usr/local/bin:/usr/bin:/bin"
OPENCLAW_BIN="/home/keiran/.npm-global/bin/openclaw"
CHAT_ID="1826567098"
ACCOUNT_ID="keiran"
LOG_DIR="/home/keiran/.openclaw/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/oauth-check.log"
TMP_OUT="/tmp/openclaw-oauth-check.out"

stamp="$(date -Iseconds)"

if "$OPENCLAW_BIN" agent --agent keiran --message "Reply with exactly: AUTH_OK" --timeout 60 --json >"$TMP_OUT" 2>&1; then
  if grep -q "AUTH_OK" "$TMP_OUT"; then
    echo "$stamp ok" >> "$LOG_FILE"
    exit 0
  fi
fi

echo "$stamp fail" >> "$LOG_FILE"
MSG="⚠️ Spark OAuth preflight failed. Codex login likely expired; please re-auth on host before scheduled reports."
"$OPENCLAW_BIN" message send --channel telegram --account "$ACCOUNT_ID" --target "$CHAT_ID" --message "$MSG" >/dev/null 2>&1 || true
exit 0
