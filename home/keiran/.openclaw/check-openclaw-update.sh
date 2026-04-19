#!/usr/bin/env bash
set -euo pipefail

PATH="/home/keiran/.npm-global/bin:/usr/local/bin:/usr/bin:/bin"
OPENCLAW_BIN="/home/keiran/.npm-global/bin/openclaw"
NPM_BIN="/usr/bin/npm"
STATE_FILE="/home/keiran/.openclaw/update-watch.json"
CHAT_ID="1826567098"
ACCOUNT_ID="keiran"

current="$($OPENCLAW_BIN --version 2>/dev/null | awk '{print $2}' || echo unknown)"
latest="$($NPM_BIN view openclaw version 2>/dev/null || echo unknown)"
force="${FORCE_NOTIFY:-0}"

if [[ -z "$current" || -z "$latest" || "$current" == "unknown" || "$latest" == "unknown" ]]; then
  exit 0
fi

# Hard safety guard: never send upgrade prompts when already on latest.
if [[ "$current" == "$latest" ]]; then
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

  summary="$(CURRENT="$current" LATEST="$latest" python3 - <<'PY'
import json, os, re, urllib.request
from collections import Counter, defaultdict

current=os.environ.get('CURRENT','').strip()
latest=os.environ.get('LATEST','').strip()

def parse_ver(v):
    try:
        return tuple(int(x) for x in v.strip().lstrip('v').split('.'))
    except Exception:
        return None

cv=parse_ver(current)
lv=parse_ver(latest)
if not cv or not lv:
    print('')
    raise SystemExit

releases=[]
for page in range(1,5):
    url=f'https://api.github.com/repos/openclaw/openclaw/releases?per_page=100&page={page}'
    try:
        req=urllib.request.Request(url, headers={'Accept':'application/vnd.github+json','User-Agent':'openclaw-update-check'})
        with urllib.request.urlopen(req, timeout=10) as r:
            arr=json.loads(r.read().decode('utf-8','ignore'))
    except Exception:
        break
    if not arr:
        break
    releases.extend(arr)

selected=[]
for rel in releases:
    tag=(rel.get('tag_name') or '').strip().lstrip('v')
    pv=parse_ver(tag)
    if not pv:
        continue
    if cv < pv <= lv:
        selected.append((pv, tag, rel.get('body') or ''))

selected.sort(key=lambda x:x[0])
if not selected:
    print('')
    raise SystemExit

items=[]
for _,tag,body in selected:
    section=''
    for ln in body.splitlines():
        s=ln.strip()
        low=s.lower()
        if low=='changes':
            section='changes'; continue
        if low=='fixes':
            section='fixes'; continue
        if re.match(r'^[-*]\s+', s):
            item=re.sub(r'^[-*]\s+','',s)
            item=re.sub(r'\s+Thanks\s+@.*$','',item,flags=re.I).strip()
            if not item or len(item)>220:
                continue
            items.append((tag, section or 'other', item))

if not items:
    print(f"Covers {len(selected)} release(s): " + ', '.join('v'+t for _,t,_ in selected))
    print('Theme 1: Release notes available but bullets were sparse, open the links for full detail.')
    raise SystemExit

# Theme by prefix before ':' (e.g. Auth/OpenAI Codex OAuth)
def theme_of(text):
    m=re.match(r'^([^:]{2,70}):\s*(.*)$', text)
    if m:
        return m.group(1).strip(), m.group(2).strip() or text
    return 'General', text

bucket=defaultdict(list)
for tag,section,text in items:
    th,rest=theme_of(text)
    bucket[th].append((tag,section,rest,text))

counts=Counter({k:len(v) for k,v in bucket.items()})
ordered=[k for k,_ in counts.most_common()]

overview=f"Covers {len(selected)} release(s): " + ', '.join('v'+t for _,t,_ in selected)
print(overview)

# Emit top 6 themes with one concrete example each
for i,th in enumerate(ordered[:6],1):
    sample=bucket[th][0][3]
    sample=sample[:160].rstrip()
    print(f"Theme {i}: {th} ({counts[th]} changes). e.g. {sample}")
PY
)"

  if [[ -z "$summary" ]]; then
    summary="Covers 1+ releases between current and latest, but detailed parsing was unavailable."
  fi

  msg="OpenClaw update available: v${current} → v${latest}\n\nAccumulative delta summary (current → latest):\n• $(echo "$summary" | sed -n '1p')\n• $(echo "$summary" | sed -n '2p')\n• $(echo "$summary" | sed -n '3p')\n• $(echo "$summary" | sed -n '4p')\n• $(echo "$summary" | sed -n '5p')\n• $(echo "$summary" | sed -n '6p')\n\nRelease notes:\n${rel1}\nIf 404: ${rel2}\nAll releases: ${rel3}\n\nReply 'yes upgrade' and I’ll run upgrade + post-restart verification."

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
latest=subprocess.getoutput('/usr/bin/npm view openclaw version 2>/dev/null').strip()
if latest:
    d['lastPromptedVersion']=latest
with open(p,'w') as f: json.dump(d,f,indent=2)
PY
fi

exit 0
