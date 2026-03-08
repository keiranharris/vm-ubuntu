#!/usr/bin/env bash
set -euo pipefail

HOST="10.1.5.50"
USER="keiran"
REMOTE_CMD="a-diu-n"

# -o BatchMode=yes prevents hanging on password prompts.
exec ssh -o BatchMode=yes -o ConnectTimeout=10 "${USER}@${HOST}" "bash -lic '${REMOTE_CMD}'"
