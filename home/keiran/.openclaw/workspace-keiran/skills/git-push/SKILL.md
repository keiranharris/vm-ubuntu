---
name: git-push
description: Run Keiran's host-level git sync script to add, commit, and push filesystem-backed changes. Use when the user asks to sync/commit/push, after meaningful file edits, and automatically after major state changes (skills, agent config/routing, cron, heartbeat, identity/workspace setup).
---

# Git Push

Run a deterministic host script for git add/commit/push rather than ad-hoc git command chains.

## Workflow

1. Confirm the script exists and is executable: `/home/keiran/_K/_CODE/k-git-push.sh`.
2. Run the script directly.
3. Report outcome clearly:
   - success: confirm push completed
   - failure: include the key error and next action

## Commands

```bash
# Existence + permissions
ls -l /home/keiran/_K/_CODE/k-git-push.sh

# Execute
/home/keiran/_K/_CODE/k-git-push.sh
```

## Guardrails

- Do not rewrite this workflow into custom git commands unless explicitly requested.
- If the script fails, do not retry in a loop. Surface the error and ask whether to debug.
- If user asks for "dry run", run only non-mutating checks (for example `git status`) unless the script itself supports dry-run flags.

## Quick trigger phrases

- "run git push skill"
- "sync filesystem git"
- "run k-git-push"
- "commit and push now"
