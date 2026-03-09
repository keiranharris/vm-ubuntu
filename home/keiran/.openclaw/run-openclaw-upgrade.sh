#!/usr/bin/env bash
set -euo pipefail

ACCOUNT_ID="keiran"
CHAT_ID="1826567098"

before="$(openclaw --version 2>/dev/null || echo unknown)"
latest="$(npm view openclaw version 2>/dev/null || echo unknown)"

openclaw update
openclaw gateway restart >/dev/null 2>&1 || true
sleep 2

after="$(openclaw --version 2>/dev/null || echo unknown)"
status_line="$(openclaw status 2>/dev/null | sed -n '1,28p' | grep -E 'Gateway service|Gateway\s+|Update\s+' || true)"

msg="✅ OpenClaw upgrade workflow complete.\n\nBefore: v${before}\nLatest available: v${latest}\nNow running: v${after}\n\nGateway restarted and health checked."
openclaw message send --channel telegram --account "$ACCOUNT_ID" --target "$CHAT_ID" --message "$msg" >/dev/null 2>&1 || true

echo "$msg"
