#!/usr/bin/env bash
set -euo pipefail

# Default length
N="${1:-12}"

# Validate input (positive integer)
if ! [[ "$N" =~ ^[0-9]+$ ]] || [ "$N" -le 0 ]; then
  echo "Usage: $0 [positive integer length]" >&2
  exit 1
fi

# Generate enough entropy:
# base64 expands ~4/3, and we filter characters,
# so oversample to ensure enough output.
BYTES=$(( (N * 3 / 2) + 8 ))

# Generate string
openssl rand -base64 "$BYTES" \
  | LC_ALL=C tr -dc 'A-Za-z0-9' \
  | head -c "$N"

echo
