#!/usr/bin/env bash
set -u

OPENCLAW_BIN="openclaw"
CHAT_ID="1826567098"
ACCOUNT_ID="keiran"

TMP_OUT="/tmp/openclaw-oauth-check.out"

# 1) Try a tiny model turn using Keiran's codex OAuth.
if "$OPENCLAW_BIN" agent --agent keiran --message "Reply with exactly: AUTH_OK" --timeout 45 --json >"$TMP_OUT" 2>&1; then
  if grep -q "AUTH_OK" "$TMP_OUT"; then
    exit 0
  fi
fi

# 2) If failed (or malformed), notify via Telegram (does not require model auth).
MSG="⚠️ Spark OAuth health-check failed at 5pm. Codex login likely expired; please re-auth on host before tomorrow morning cron runs."
"$OPENCLAW_BIN" message send --channel telegram --account "$ACCOUNT_ID" --target "$CHAT_ID" --message "$MSG" >/dev/null 2>&1 || true

exit 0
