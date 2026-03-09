#!/usr/bin/env bash
set -euo pipefail

OPENCLAW_BIN="openclaw"
STATE_FILE="/home/keiran/.openclaw/update-watch.json"
CHAT_ID="1826567098"
ACCOUNT_ID="keiran"

current="$($OPENCLAW_BIN --version 2>/dev/null || echo unknown)"
latest="$(npm view openclaw version 2>/dev/null || echo unknown)"

if [[ -z "$current" || -z "$latest" || "$current" == "unknown" || "$latest" == "unknown" ]]; then
  exit 0
fi

last_prompted=""
if [[ -f "$STATE_FILE" ]]; then
  last_prompted="$(python3 - <<'PY'
import json
p='/home/keiran/.openclaw/update-watch.json'
try:
    with open(p) as f:
        d=json.load(f)
    print(d.get('lastPromptedVersion',''))
except Exception:
    print('')
PY
)"
fi

if [[ "$latest" != "$current" && "$latest" != "$last_prompted" ]]; then
  rel1="https://github.com/openclaw/openclaw/releases/tag/v${latest}"
  rel2="https://github.com/openclaw/openclaw/releases/tag/${latest}"
  rel3="https://github.com/openclaw/openclaw/releases"

  msg="🆕 OpenClaw update available: ${current} → ${latest}\n\nRelease notes:\n${rel1}\nIf that tag URL 404s: ${rel2}\nFallback: ${rel3}\n\nReply 'yes upgrade' and I'll run the update + restart services, then send you a completion summary."

  $OPENCLAW_BIN message send --channel telegram --account "$ACCOUNT_ID" --target "$CHAT_ID" --message "$msg" >/dev/null 2>&1 || true

  python3 - <<'PY'
import json, os, subprocess
p='/home/keiran/.openclaw/update-watch.json'
d={}
if os.path.exists(p):
    try:
        with open(p) as f: d=json.load(f)
    except Exception:
        d={}
latest=subprocess.getoutput('npm view openclaw version 2>/dev/null').strip()
if latest:
    d['lastPromptedVersion']=latest
with open(p,'w') as f: json.dump(d,f,indent=2)
PY
fi

exit 0
