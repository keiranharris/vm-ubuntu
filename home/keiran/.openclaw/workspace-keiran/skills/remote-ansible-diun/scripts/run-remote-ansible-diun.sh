#!/usr/bin/env bash
set -euo pipefail

HOST="10.1.5.50"
USER="keiran"
REMOTE_CMD="a-diu-n"

OUT_FILE="${1:-/tmp/remote-ansible-diun.out}"

# -o BatchMode=yes prevents hanging on password prompts.
ssh -o BatchMode=yes -o ConnectTimeout=10 "${USER}@${HOST}" "bash -lic '${REMOTE_CMD}'" | tee "$OUT_FILE"
