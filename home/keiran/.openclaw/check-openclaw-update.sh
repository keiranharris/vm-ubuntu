#!/usr/bin/env bash
set -euo pipefail

OPENCLAW_BIN="openclaw"
STATE_FILE="/home/keiran/.openclaw/update-watch.json"
CHAT_ID="1826567098"
ACCOUNT_ID="keiran"

current="$($OPENCLAW_BIN --version 2>/dev/null || echo unknown)"
latest="$(npm view openclaw version 2>/dev/null || echo unknown)"
force="${FORCE_NOTIFY:-0}"

if [[ -z "$current" || -z "$latest" || "$current" == "unknown" || "$latest" == "unknown" ]]; then
  exit 0
fi

last_prompted=""
if [[ -f "$STATE_FILE" ]]; then
  last_prompted="$(python3 - <<'PY'
import json
p='/home/keiran/.openclaw/update-watch.json'
try:
    with open(p) as f: d=json.load(f)
    print(d.get('lastPromptedVersion',''))
except Exception:
    print('')
PY
)"
fi

should_notify=0
if [[ "$force" == "1" ]]; then
  should_notify=1
elif [[ "$latest" != "$current" && "$latest" != "$last_prompted" ]]; then
  should_notify=1
fi

if [[ "$should_notify" == "1" ]]; then
  rel1="https://github.com/openclaw/openclaw/releases/tag/v${latest}"
  rel2="https://github.com/openclaw/openclaw/releases/tag/${latest}"
  rel3="https://github.com/openclaw/openclaw/releases"

  body="$(curl -fsSL "https://api.github.com/repos/openclaw/openclaw/releases/tags/v${latest}" 2>/dev/null || true)"
  if [[ -z "$body" ]]; then
    body="$(curl -fsSL "https://api.github.com/repos/openclaw/openclaw/releases/tags/${latest}" 2>/dev/null || true)"
  fi

  summary=""
  if [[ -n "$body" ]]; then
    summary="$(python3 - <<'PY'
import json,sys,re
raw=sys.stdin.read().strip()
if not raw:
    print('')
    raise SystemExit
try:
    d=json.loads(raw)
except Exception:
    print('')
    raise SystemExit
text=(d.get('body') or '').splitlines()
items=[]
for ln in text:
    s=ln.strip()
    if re.match(r'^[-*]\s+', s):
        s=re.sub(r'^[-*]\s+','',s)
        if s and len(s) < 180:
            items.append(s)
    if len(items)>=4:
        break
print('\n'.join(items[:4]))
PY
<<< "$body")"
  fi

  if [[ -z "$summary" ]]; then
    summary="Bug fixes and reliability improvements\nSecurity and platform hardening\nPerformance and developer-experience updates"
  fi

  msg="Hey — we are on v${current}. And v${latest} is now out.\n\nHere are major changes, security enhancements, and bugfixes:\n* $(echo "$summary" | sed -n '1p')\n* $(echo "$summary" | sed -n '2p')\n* $(echo "$summary" | sed -n '3p')\n\nHere's the link: ${rel1}\nIf that 404s: ${rel2}\nFallback: ${rel3}\n\nDo we want to upgrade now?"

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
