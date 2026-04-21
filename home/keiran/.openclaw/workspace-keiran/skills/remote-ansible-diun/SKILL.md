---
name: remote-ansible-diun
description: SSH to keiran@10.1.5.50 and run the remote alias `a-diu-n` (ansible docker image update on Synology NAS). Use when user asks naturally for things like "update docker images on the NAS", "run NAS docker updates", "run a-diu-n", or ansible image updates on Synology.
---

# Remote Ansible DIU-N

Run one fixed remote operation: connect over SSH and execute alias `a-diu-n` on host `10.1.5.50` as user `keiran`.

## Workflow

1. Execute the helper script: `scripts/run-remote-ansible-diun.sh`.
2. This run can take ~10 minutes; allow a long timeout and avoid rapid polling loops.
3. On success, send a clean recap in this exact shape:
   - `TASK [COMPARE initial and final outputs]`
   - Bullet list, one updated image per line, formatted as `- image: old_id -> new_id`
   - `PLAY RECAP`
4. On failure, report the key SSH/Ansible error and next action.

## Command

```bash
/home/keiran/.openclaw/workspace-keiran/skills/remote-ansible-diun/scripts/run-remote-ansible-diun.sh
```

## Guardrails

- Keep host/user hardcoded to avoid accidental target drift.
- Use `bash -lic` remotely so aliases load in an interactive login shell.
- Do not attempt password prompts in chat workflows.
- If SSH auth fails, tell user to finish key-based/password-less setup.
