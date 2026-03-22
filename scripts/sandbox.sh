#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sandbox.sh [-f settings.json] <command> [args...]

Runs a command inside Anthropic Sandbox Runtime (`srt`).

If `-f` is not provided, settings are loaded from:
  1. ~/.sandbox/default.json
  2. ./.sandbox/default.json

If both files exist, the project-local file overrides the home file with
section-aware merging.
EOF
}

SETTINGS_FILE=""

while getopts ":f:h" opt; do
  case "$opt" in
    f) SETTINGS_FILE="$OPTARG" ;;
    h)
      usage
      exit 0
      ;;
    :)
      echo "Error: -$OPTARG requires an argument." >&2
      usage >&2
      exit 1
      ;;
    \?)
      echo "Error: invalid option -$OPTARG" >&2
      usage >&2
      exit 1
      ;;
  esac
done
shift "$((OPTIND - 1))"

if [[ $# -eq 0 ]]; then
  echo "Error: command is required." >&2
  usage >&2
  exit 1
fi

if ! command -v srt >/dev/null 2>&1; then
  echo "Error: srt is not installed or not in PATH." >&2
  echo "Install it with: npm install -g @anthropic-ai/sandbox-runtime" >&2
  exit 1
fi

cleanup() {
  if [[ -n "${MERGED_SETTINGS_FILE:-}" && -f "$MERGED_SETTINGS_FILE" ]]; then
    rm -f "$MERGED_SETTINGS_FILE"
  fi
}

trap cleanup EXIT

if [[ -n "$SETTINGS_FILE" ]]; then
  if [[ ! -f "$SETTINGS_FILE" ]]; then
    echo "Error: settings file not found: $SETTINGS_FILE" >&2
    exit 1
  fi
else
  HOME_SETTINGS="$HOME/.sandbox/default.json"
  LOCAL_SETTINGS="$PWD/.sandbox/default.json"
  FOUND_SETTINGS=()

  [[ -f "$HOME_SETTINGS" ]] && FOUND_SETTINGS+=("$HOME_SETTINGS")
  [[ -f "$LOCAL_SETTINGS" ]] && FOUND_SETTINGS+=("$LOCAL_SETTINGS")

  if [[ ${#FOUND_SETTINGS[@]} -eq 0 ]]; then
    echo "Error: no sandbox settings file found." >&2
    echo "Checked: $HOME_SETTINGS and $LOCAL_SETTINGS" >&2
    exit 1
  fi

  if [[ ${#FOUND_SETTINGS[@]} -eq 1 ]]; then
    SETTINGS_FILE="${FOUND_SETTINGS[0]}"
  else
    if ! command -v python3 >/dev/null 2>&1; then
      echo "Error: python3 is required to merge sandbox settings files." >&2
      exit 1
    fi

    MERGED_SETTINGS_FILE="$(mktemp)"
    python3 - "$HOME_SETTINGS" "$LOCAL_SETTINGS" "$MERGED_SETTINGS_FILE" <<'PY'
import json
import sys

home_path, local_path, out_path = sys.argv[1:]

with open(home_path, "r", encoding="utf-8") as f:
    home_data = json.load(f)

with open(local_path, "r", encoding="utf-8") as f:
    local_data = json.load(f)

merged = dict(home_data)

if "enabled" in local_data and local_data["enabled"] is not None:
    merged["enabled"] = local_data["enabled"]

if isinstance(local_data.get("network"), dict):
    merged["network"] = {
        **(home_data.get("network") if isinstance(home_data.get("network"), dict) else {}),
        **local_data["network"],
    }

if isinstance(local_data.get("filesystem"), dict):
    merged["filesystem"] = {
        **(home_data.get("filesystem") if isinstance(home_data.get("filesystem"), dict) else {}),
        **local_data["filesystem"],
    }

if isinstance(local_data.get("ignoreViolations"), dict):
    merged["ignoreViolations"] = local_data["ignoreViolations"]

if "enableWeakerNestedSandbox" in local_data and local_data["enableWeakerNestedSandbox"] is not None:
    merged["enableWeakerNestedSandbox"] = local_data["enableWeakerNestedSandbox"]

with open(out_path, "w", encoding="utf-8") as f:
    json.dump(merged, f)
PY
    SETTINGS_FILE="$MERGED_SETTINGS_FILE"
  fi
fi

exec srt --settings "$SETTINGS_FILE" "$@"
