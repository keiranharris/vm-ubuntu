#!/usr/bin/env bash
set -euo pipefail

ACCOUNT_ID="keiran"
CHAT_ID="1826567098"
LOG_DIR="/home/keiran/.openclaw/logs"
STATE_FILE="/home/keiran/.openclaw/upgrade-last.json"
PENDING_FILE="/home/keiran/.openclaw/upgrade-pending.json"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/upgrade-$(date +%Y%m%d-%H%M%S).log"

send_msg() {
  local text="$1"
  openclaw message send --channel telegram --account "$ACCOUNT_ID" --target "$CHAT_ID" --message "$text" >/dev/null 2>&1
}

before="$(openclaw --version 2>/dev/null || echo unknown)"
latest="$(npm view openclaw version 2>/dev/null || echo unknown)"
start_ts="$(date -Iseconds)"

python3 - <<PY
import json
p='$PENDING_FILE'
d={
  'startedAt':'$start_ts',
  'before':'$before',
  'latest':'$latest',
  'status':'running',
  'health':'unknown',
  'error':'',
  'log':'$LOG_FILE'
}
with open(p,'w') as f: json.dump(d,f,indent=2)
PY

send_msg "🔧 Starting OpenClaw upgrade now…\nBefore: v${before}\nTarget latest: v${latest}" || true

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

python3 - <<PY
import json
p='$PENDING_FILE'
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
PY

if [[ "$status" == "ok" ]]; then
  if send_msg "✅ OpenClaw upgrade complete.\nBefore: v${before}\nNow running: v${after}\nHealth: ${health}\nLog: ${LOG_FILE}"; then
    rm -f "$PENDING_FILE"
  fi
  echo "ok"
else
  send_msg "⚠️ OpenClaw upgrade encountered an error.\nBefore: v${before}\nCurrent: v${after}\nHealth: ${health}\nError: ${err}\nLog: ${LOG_FILE}" || true
  echo "error"
  exit 1
fi
