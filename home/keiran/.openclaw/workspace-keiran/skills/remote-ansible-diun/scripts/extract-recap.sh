#!/usr/bin/env bash
set -euo pipefail

IN_FILE="${1:-/tmp/remote-ansible-diun.out}"

if [[ ! -f "$IN_FILE" ]]; then
  echo "ERROR: input file not found: $IN_FILE" >&2
  exit 2
fi

awk '
BEGIN {inblock=0; saw_compare=0; saw_recap=0}
/^TASK \[COMPARE initial and final outputs\]/ {inblock=1; saw_compare=1}
inblock {print}
/^PLAY RECAP/ {saw_recap=1}
END {
  if (!saw_compare) {
    exit 10
  }
}
' "$IN_FILE"
