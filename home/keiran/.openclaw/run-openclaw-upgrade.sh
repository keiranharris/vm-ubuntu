#!/usr/bin/env bash
set -euo pipefail

ACCOUNT_ID="keiran"
CHAT_ID="1826567098"
LOG_DIR="/home/keiran/.openclaw/logs"
STATE_FILE="/home/keiran/.openclaw/upgrade-last.json"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/upgrade-$(date +%Y%m%d-%H%M%S).log"

send_msg() {
  local text="$1"
  openclaw message send --channel telegram --account "$ACCOUNT_ID" --target "$CHAT_ID" --message "$text" >/dev/null 2>&1 || true
}

before="$(openclaw --version 2>/dev/null || echo unknown)"
latest="$(npm view openclaw version 2>/dev/null || echo unknown)"
start_ts="$(date -Iseconds)"

send_msg "🔧 Starting OpenClaw upgrade now…\nBefore: v${before}\nTarget latest: v${latest}"

status="ok"
err=""
{
  echo "[start] $start_ts"
  echo "before=$before latest=$latest"
  openclaw update
  openclaw gateway restart >/dev/null 2>&1 || true
} >>"$LOG_FILE" 2>&1 || {
  status="error"
  err="upgrade or restart command failed"
}

# Wait for CLI/gateway to settle.
for _ in $(seq 1 30); do
  if openclaw --version >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

after="$(openclaw --version 2>/dev/null || echo unknown)"
health="unknown"
if openclaw status >/dev/null 2>&1; then
  health="ok"
else
  health="degraded"
fi

end_ts="$(date -Iseconds)"
python3 - <<PY
import json
p='$STATE_FILE'
d={
  'startedAt':'$start_ts',
  'endedAt':'$end_ts',
  'before':'$before',
  'latest':'$latest',
  'after':'$after',
  'status':'$status',
  'health':'$health',
  'error':'$err',
  'log':'$LOG_FILE'
}
with open(p,'w') as f: json.dump(d,f,indent=2)
print(p)
PY

if [[ "$status" == "ok" ]]; then
  send_msg "✅ OpenClaw upgrade complete.\nBefore: v${before}\nNow running: v${after}\nHealth: ${health}\nLog: ${LOG_FILE}"
  echo "ok"
else
  send_msg "⚠️ OpenClaw upgrade encountered an error.\nBefore: v${before}\nCurrent: v${after}\nHealth: ${health}\nError: ${err}\nLog: ${LOG_FILE}"
  echo "error"
  exit 1
fi
