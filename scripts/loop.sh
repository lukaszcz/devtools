#!/usr/bin/env bash
set -u

if [ $# -ne 1 ]; then
  echo "Usage: $0 <prompt-file>" >&2
  exit 1
fi

PROMPT_FILE="$1"

trap 'echo "Interrupted"; exit 130' INT

LOG_FILE="loop-$(date +%Y%m%d-%H%M%S).log"
echo "Logging to $LOG_FILE"

CNT=1
while true; do
  echo
  echo "-------------------------------------------------------------"
  echo "                        Step $CNT"
  echo "-------------------------------------------------------------"
  echo
  CNT=$((CNT + 1))
  OUTPUT=$(claude -p "@$PROMPT_FILE" 2>&1 | tee -a "$LOG_FILE") || true
  if [[ "$(echo "$OUTPUT" | tr -d '[:space:]')" == "COMPLETE" ]]; then
    echo "Completed."
    break
  else
    echo "$OUTPUT"
  fi
done
