#!/usr/bin/env bash
set -euo pipefail

PATH="/home/keiran/.npm-global/bin:/usr/local/bin:/usr/bin:/bin"
OPENCLAW_BIN="/home/keiran/.npm-global/bin/openclaw"
PENDING_FILE="/home/keiran/.openclaw/upgrade-pending.json"
LOCK_FILE="/home/keiran/.openclaw/upgrade-pending.lock"
ACCOUNT_ID="keiran"
CHAT_ID="1826567098"

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  exit 0
fi

[[ -f "$PENDING_FILE" ]] || exit 0

status="$(python3 - <<'PY'
import json
p='/home/keiran/.openclaw/upgrade-pending.json'
try:
    with open(p) as f: d=json.load(f)
    print(d.get('status','running'))
except Exception:
    print('running')
PY
)"

# Do not report while update is still running.
if [[ "$status" == "running" ]]; then
  exit 0
fi

before="$(python3 - <<'PY'
import json
p='/home/keiran/.openclaw/upgrade-pending.json'
try:
    with open(p) as f: d=json.load(f)
    print(d.get('before','unknown'))
except Exception:
    print('unknown')
PY
)"

target="$(python3 - <<'PY'
import json
p='/home/keiran/.openclaw/upgrade-pending.json'
try:
    with open(p) as f: d=json.load(f)
    print(d.get('latest','unknown'))
except Exception:
    print('unknown')
PY
)"

result="$(python3 - <<'PY'
import json
p='/home/keiran/.openclaw/upgrade-pending.json'
try:
    with open(p) as f: d=json.load(f)
    print(d.get('status','unknown'))
except Exception:
    print('unknown')
PY
)"

err="$(python3 - <<'PY'
import json
p='/home/keiran/.openclaw/upgrade-pending.json'
try:
    with open(p) as f: d=json.load(f)
    print((d.get('error') or '').strip())
except Exception:
    print('')
PY
)"

logp="$(python3 - <<'PY'
import json
p='/home/keiran/.openclaw/upgrade-pending.json'
try:
    with open(p) as f: d=json.load(f)
    print(d.get('log',''))
except Exception:
    print('')
PY
)"

after="$($OPENCLAW_BIN --version 2>/dev/null | awk '{print $2}' || echo unknown)"
health="degraded"
if $OPENCLAW_BIN status >/dev/null 2>&1; then
  health="ok"
fi

if [[ "$result" == "ok" ]]; then
  msg="✅ Post-restart upgrade report\nBefore: v${before}\nTarget: v${target}\nNow running: v${after}\nHealth: ${health}\n(Recovered from disk flag after restart)"
else
  msg="⚠️ Post-restart upgrade report\nBefore: v${before}\nTarget: v${target}\nCurrent: v${after}\nHealth: ${health}\nError: ${err:-unknown}\nLog: ${logp}"
fi

if $OPENCLAW_BIN message send --channel telegram --account "$ACCOUNT_ID" --target "$CHAT_ID" --message "$msg" >/dev/null 2>&1; then
  rm -f "$PENDING_FILE"
fi

exit 0
