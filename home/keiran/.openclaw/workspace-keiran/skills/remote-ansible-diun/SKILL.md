---
name: remote-ansible-diun
description: SSH to keiran@10.1.5.50 and run the remote alias `a-diu-n` (ansible docker image update on Synology NAS). Use when user asks to run docker image update, ansible update on NAS, or explicitly says a-diu-n.
---

# Remote Ansible DIU-N

Run one fixed remote operation: connect over SSH and execute alias `a-diu-n` on host `10.1.5.50` as user `keiran`.

## Workflow

1. Execute the helper script: `scripts/run-remote-ansible-diun.sh`.
2. Report success/failure and include the key error line on failure.

## Command

```bash
/home/keiran/.openclaw/workspace-keiran/skills/remote-ansible-diun/scripts/run-remote-ansible-diun.sh
```

## Guardrails

- Keep host/user hardcoded to avoid accidental target drift.
- Use `bash -lic` remotely so aliases load in an interactive login shell.
- Do not attempt password prompts in chat workflows.
- If SSH auth fails, tell user to finish key-based/password-less setup.
